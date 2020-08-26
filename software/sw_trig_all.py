###################################################
# Aaron Fienberg
#
# reset all waveform buffers, trigger all 24 channels,
# verify the results are correct
#

from artyS7 import artyS7, read_dev_path
import sys
import numpy as np

test_conf = 1022


def check_ramp(wfm):
    samples = wfm["adc_samples"]

    diff = np.remainder((samples[1:] - samples[:-1]), (1 << 12))

    return np.all(diff == 1)


def print_wfm_count(arty):
    count = []
    for chan in range(24):
        arty.fpga_write("buf_stat_chan_sel", chan)
        count.append(arty.fpga_read("n_wfms_in_buf"))
    print(f"wfms in buf: {count}")


def check_wfm(wfm, ltcs):
    chan = wfm["chan_num"]
    evt_len = wfm["evt_len"]

    ltc_ind = 1 if chan > 15 else 0

    assert wfm["trig_type"] == "sw"

    assert ltcs[ltc_ind] == wfm["ltc"]

    assert evt_len == len(wfm["adc_samples"]) == test_conf

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

    print("Configuring test conf")
    arty.fpga_write("test_conf", test_conf)

    arty.fpga_write("buf_reader_dpram_mode", 1)

    print_wfm_count(arty)

    print("Sending software triggers")
    arty.fpga_write(0xFFC, 0xFFFF)
    arty.fpga_write(0xEF4, 0xFFFF)
    print_wfm_count(arty)

    print("Enabling reader")

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

    print("disabling reader...")
    arty.fpga_write("buf_reader_enable", 0x0)


if __name__ == "__main__":
    main()
