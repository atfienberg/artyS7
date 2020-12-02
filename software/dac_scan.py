#
# Coarse DAC scan for all 24 channels
#
# Before running this, the IO delay/bitslip scan should be
# completed and ADCs should be configured for data taking
# (by running the configure_adcs script, for example)

from artyS7 import artyS7, read_dev_path
from io_scan import get_sw_wfm
from set_dac import set_dac
import time
import numpy as np

test_conf = 500


def set_baseline_dac(arty, chan_idx, value):
    """ set the baseline DAC for the ADC channel given by chan_idx """
    spi_num = chan_idx // 8
    dac_chan = chan_idx % 8
    set_dac(arty, [spi_num], [1], dac_chan, value)


def dac_scan(arty, chan_idx, dac_vals):
    for val in dac_vals:
        set_baseline_dac(arty, chan_idx, val)

        # wait for DAC to settle
        time.sleep(0.1)

        wfm = get_sw_wfm(arty, chan_idx)

        samps = wfm["adc_samples"].view(np.int16)

        mean = np.average(samps)
        std = np.std(samps)

        print(f"dac_val {val}: mean: {mean:.3f}, std: {std:.3f}")


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=0.1)

    # reset waveform buffers
    arty.fpga_write(0xEF9, 0xFFFF)
    arty.fpga_write(0xEF0, 0xFFFF)
    arty.fpga_write(0xEF9, 0x0)
    arty.fpga_write(0xEF0, 0x0)

    # configure test conf and dpram mode
    arty.fpga_write("test_conf", test_conf)
    arty.fpga_write("buf_reader_dpram_mode", 1)

    # enable reader
    arty.fpga_write("buf_reader_enable", 0x1)

    dac_vals = np.arange(0, 15000, 1000)

    # start with 0
    try:
        for i in range(24):
            print(f"Chan {i}")
            dac_scan(arty, i, dac_vals)
            print()
    finally:
        print("disabling reader...")
        arty.fpga_write("buf_reader_enable", 0x0)

    # set all DACs back to 0
    print("Setting DACs back to 0")
    for i in range(24):
        set_baseline_dac(arty, i, 0)


if __name__ == "__main__":
    main()
