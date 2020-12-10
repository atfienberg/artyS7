###################################################
# Aaron Fienberg
#
# Fire the AFE pulser/sw trig for ADC0 channel 0
#

from artyS7 import artyS7, read_dev_path

import sys
import time
import numpy as np

from io_scan import reset_wfm_buffers

PULSER_WIDTH_REG = 0xBD2
PULSER_IO_RESET = 0xBD1
PULSER_TRIG_MASK = [0xBCF, 0xBD0]
PULSER_FIRE = 0xBCE
DISCR_IO_RESET = [0xBDE, 0xBDF]

test_conf = 100


def build_discr_wfm(wfm):
    discr_samps = []
    for samp in wfm["discr_samples"]:
        for i in range(8):
            discr_samps.append((samp >> i) & 0x1)

    return np.array(discr_samps)


def main():
    if len(sys.argv) < 2:
        print("Usage: pulser_trig_test.py <pulse_width>")
        sys.exit(0)
    pulser_width = int(sys.argv[1])

    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    # reset waveform buffers
    reset_wfm_buffers(arty)

    # configure fpga regs
    arty.fpga_write("test_conf", test_conf)
    arty.fpga_write(PULSER_WIDTH_REG, pulser_width)
    arty.fpga_write(PULSER_IO_RESET, 0x3E)
    arty.fpga_write("buf_reader_dpram_mode", 1)
    arty.fpga_write(PULSER_TRIG_MASK[0], 0x1)
    arty.fpga_write(DISCR_IO_RESET[0], 0xFFFE)

    # fire pulser
    arty.fpga_write(PULSER_FIRE, 0x1)

    time.sleep(0.001)

    arty.fpga_write("buf_reader_enable", 0x1)

    wfm = arty.read_waveform()
    if wfm is None:
        raise RuntimeError("Failed to read waveform!")

    extra_wfm = arty.read_waveform()
    if extra_wfm is not None:
        raise RuntimeError("Read more than one waveform!")

    arty.fpga_write("buf_reader_enable", 0x0)

    print(f'Waveform from channel {wfm["chan_num"]}')
    samps = wfm["adc_samples"].view(np.int16)
    discr_samps = build_discr_wfm(wfm)

    print(f"{len(samps)} samples")
    print(f"RMS: {samps.std()}")
    print(f"Max samp: {samps.max()}")
    print(f"Min samp: {samps.min()}")

    high_inds = np.argwhere(discr_samps == 1)
    if len(high_inds) > 0:
        first_high = high_inds[0][0]
        next_lows = np.argwhere(discr_samps[first_high:] == 0)
        if len(next_lows) == 0:
            high_len = len(discr_samps) - first_high
        else:
            high_len = next_lows[0][0]
    else:
        first_high = None
        high_len = 0

    print(f"first high discr sample: {first_high}")
    print(f"discr high len: {high_len}")

    np.savez("test.npz", a=samps, b=discr_samps)


if __name__ == "__main__":
    main()
