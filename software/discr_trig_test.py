###################################################
# Aaron Fienberg
#
# Fire the AFE pulser
# readout a discriminator trigger for ADC0 channel 0
#

from artyS7 import artyS7, read_dev_path
from pulser_trig_test import (
    build_discr_wfm,
    PULSER_WIDTH_REG,
    PULSER_IO_RESET,
    PULSER_TRIG_MASK,
    PULSER_FIRE,
    DISCR_IO_RESET,
)

from io_scan import reset_wfm_buffers

import sys
import time

import numpy as np

TRIG_ARM_MASK = [0xBF9, 0xBFA]
TRIG_ARM = 0xBF8

pre_conf = 16
post_conf = 32


def arm_discr_trigger(arty):
    # single trigger mode
    arty.fpga_write("trig_mode", 1)

    # enable positive polarity discriminator trigger
    arty.fpga_write("trig_settings", 0x18)

    # arm the trigger for channel 0
    arty.fpga_write(TRIG_ARM_MASK[0], 0x1)
    arty.fpga_write(TRIG_ARM_MASK[1], 0x0)
    arty.fpga_write(TRIG_ARM, 0x2)


def main():
    if len(sys.argv) < 2:
        print("Usage: discr_trig_test.py <pulse_width>")
        sys.exit(0)
    pulser_width = int(sys.argv[1])

    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    # reset waveform buffers
    reset_wfm_buffers(arty)

    # configure fpga regs
    arty.fpga_write("pre_conf", pre_conf)
    arty.fpga_write("post_conf", post_conf)
    arty.fpga_write(PULSER_WIDTH_REG, pulser_width)
    arty.fpga_write(PULSER_IO_RESET, 0x3E)
    arty.fpga_write("buf_reader_dpram_mode", 1)
    for i in range(2):
        arty.fpga_write(PULSER_TRIG_MASK[i], 0x0)
    arty.fpga_write(DISCR_IO_RESET[0], 0xFFFE)

    arm_discr_trigger(arty)

    # fire pulser
    arty.fpga_write(PULSER_FIRE, 0x1)

    time.sleep(0.001)

    arty.fpga_write("buf_reader_enable", 0x1)

    try:
        wfm = arty.read_waveform()
        if wfm is None:
            raise RuntimeError("Failed to read a waveform!")

        extra_wfm = arty.read_waveform()
        if extra_wfm is not None:
            raise RuntimeError("Read more than one waveform!")
    finally:
        arty.fpga_write("buf_reader_enable", 0x0)
        # disable triggers
        arty.fpga_write("trig_settings", 0x0)
        arty.fpga_write("trig_mode", 0x0)

    print(f'Waveform from channel {wfm["chan_num"]}')
    print(f'Trig type: {wfm["trig_type"]}')
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
