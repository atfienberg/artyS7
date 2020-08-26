###################################################
# Aaron Fienberg
#
# reset all waveform buffers, trigger all 24 channels,
# verify the results are correct
#

from artyS7 import artyS7, read_dev_path
import sys
import numpy as np
from sw_trig_all import *

pre_conf = 9
post_conf = 12
thresh_val = 97


def check_wfm(wfm, ltcs):
    chan = wfm["chan_num"]
    evt_len = wfm["evt_len"]

    ltc_ind = 1 if chan > 15 else 0

    assert wfm["trig_type"] == "thresh"

    assert ltcs[ltc_ind] == wfm["ltc"]

    assert evt_len == len(wfm["adc_samples"]) == pre_conf + post_conf + 1

    assert wfm["adc_samples"][pre_conf] == thresh_val

    # check that this is the channel we think it is...
    assert ((wfm["adc_samples"][0] & 0xFF) + chan) % 0x100 == wfm["discr_samples"][0]

    assert check_ramp(wfm)


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    print("Resetting waveform buffers...")
    arty.fpga_write(0xEF9, 0xFFFF)
    arty.fpga_write(0xEF0, 0xFFFF)
    arty.fpga_write(0xEF9, 0x0)
    arty.fpga_write(0xEF0, 0x0)

    print("Configuring trigger settings")
    arty.fpga_write("pre_conf", pre_conf)
    arty.fpga_write("post_conf", post_conf)
    arty.fpga_write("trig_mode", 1)
    arty.fpga_write("trig_threshold", 97)

    print("Arming triggers")
    arty.fpga_write(0xFFA, 0xFFFF)
    arty.fpga_write(0xEF3, 0xFFFF)
    print("Armed readback:")
    print(hex(arty.fpga_read(0xFF9)))
    print(hex(arty.fpga_read(0xEF2)))
    print_wfm_count(arty)

    print("Enabling triggers")
    arty.fpga_write("trig_settings", 0x21)
    print("Armed readback:")
    print(hex(arty.fpga_read(0xFF9)))
    print(hex(arty.fpga_read(0xEF2)))
    print_wfm_count(arty)

    print("Enabling reader")
    arty.fpga_write("buf_reader_dpram_mode", 1)

    ltcs = [None, None]
    arty.fpga_write("buf_reader_enable", 0x1)

    while True:
        wfm = arty.read_waveform()
        if wfm is None:
            break

        chan = wfm["chan_num"]
        evt_len = wfm["evt_len"]
        ltc = wfm["ltc"]

        ltc_ind = 1 if chan > 15 else 0
        if ltcs[ltc_ind] is None:
            ltcs[ltc_ind] = ltc

        try:
            check_wfm(wfm, ltcs)
        except:
            print("Failed wfm!")
            print(wfm)
            raise

        print(f'chan {chan} discr_samples: {wfm["discr_samples"][:5]}')

        print_wfm_count(arty)

    print("disabling triggers...")
    arty.fpga_write("trig_settings", 0x0)
    arty.fpga_write("trig_mode", 0x0)
    arty.fpga_write("trig_threshold", 0x0)

    print("disabling reader...")
    arty.fpga_write("buf_reader_enable", 0x0)


if __name__ == "__main__":
    main()
