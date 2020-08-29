###################################################
# Aaron Fienberg
#
# Test the hit buffer with threshold triggers
# 12 bits at 125 MHz cycles through values once every 33 us
#
# So, this test verifies that the hitbuffer controller
# and waveform buffer reader can handle events from 24
# channels each triggering at 30 KHz
#

from artyS7 import artyS7, read_dev_path, unpack_wfm
from ddr3_test import read_DDR3_pg
from sw_trig_all import *
from hbuf_sw_trig_test import *
import time
import sys
import numpy as np

PRE_CONF = 20
POST_CONF = 50
TRIG_THRESH = 101

START_PG = 0
STOP_PG = 30000

PGS_TO_READ = 20

from collections import defaultdict


def unpack_and_sort_wfms(pages):
    raw_array = np.concatenate([pg[4:-4] for pg in pages])

    wfms = defaultdict(list)
    while len(raw_array) > 0:
        wfm_len = raw_array[1]
        wfm_payload = raw_array[: 2 * wfm_len + 8]

        # don't read last partial waveform
        if len(wfm_payload) < wfm_len:
            break

        wfm = unpack_wfm.unpack_wfm(wfm_payload)
        chan = wfm["chan_num"]
        wfms[chan].append(wfm)

        # check that ramp pattern is correct
        assert ((wfm["adc_samples"][0] & 0xFF) + chan) % 0x100 == wfm["discr_samples"][
            0
        ]
        assert check_ramp(wfm)
        assert wfm["trig_type"] == "thresh"
        assert wfm["adc_samples"][PRE_CONF] == TRIG_THRESH
        assert len(wfm["adc_samples"]) == PRE_CONF + POST_CONF + 1

        raw_array = raw_array[2 * wfm_len + 8 :]

        # drop filler zeros
        n_dropped = 0
        while len(raw_array) > 0 and raw_array[0] == 0:
            n_dropped += 1
            raw_array = raw_array[1:]

    return wfms


def analyze_wfms(wfms):
    for chan, wfm_list in wfms.items():
        n_wfms = len(wfm_list)
        ltcs = np.array([wfm["ltc"] for wfm in wfm_list])
        # calculate trigger rate in KHz
        trig_rate = 1.0 / (np.average(ltcs[1:] - ltcs[:-1]) * 8e-6)

        print(f"Chan {chan}, {len(wfm_list)} wfms, {trig_rate:.2f} kHz trigger rate")


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    print("Resetting waveform buffers...")
    arty.fpga_write(0xEF9, 0xFFFF)
    arty.fpga_write(0xEF0, 0xFFFF)
    arty.fpga_write(0xEF9, 0x0)
    arty.fpga_write(0xEF0, 0x0)

    print("Configuring pre/post conf")
    arty.fpga_write("pre_conf", PRE_CONF)
    arty.fpga_write("post_conf", POST_CONF)

    arty.fpga_write("buf_reader_dpram_mode", 1)

    print_wfm_count(arty)

    print("Enabling memory controller and hbuf controller")
    arty.fpga_write("hbuf_enable", 0)
    arty.fpga_write("ddr3_enable", 1)
    arty.fpga_write("hbuf_start_pg", START_PG)
    arty.fpga_write("hbuf_stop_pg", STOP_PG)
    arty.fpga_write("hbuf_enable", 1)
    print(f'hbuf first pg: {arty.fpga_read("hbuf_first_pg")}')
    print(f'hbuf last pg: {arty.fpga_read("hbuf_last_pg")}')
    print_hbuf_status(arty)

    time.sleep(0.1)
    cal_done = arty.fpga_read("ddr3_cal_complete")
    print(f"cal complete: {cal_done}")

    print("Enabling reader")
    arty.fpga_write("buf_reader_enable", 0x1)

    print("Setting trigger threshold and enabling triggers")
    arty.fpga_write("trig_threshold", TRIG_THRESH)
    arty.fpga_write("trig_settings", 0x21)
    time.sleep(0.5)
    print("Disabling triggers")
    arty.fpga_write("trig_settings", 0x0)
    print_hbuf_status(arty)
    print("Overflow status")
    low_overflow = arty.fpga_read(0xEFA)
    high_overflow = arty.fpga_read(0xEF1)
    overflow = (high_overflow << 16) | low_overflow
    print(f"overflow status: 0x{overflow:06x}")

    print("Flushing hbuf")
    arty.fpga_write("hbuf_task_reg", 0x1)
    print_hbuf_status(arty)

    # check waveforms, verify trigger rates, etc
    print("Reading the first 200 pages")
    pgs = [pop_hbuf_pg(arty) for i in range(PGS_TO_READ)]
    print_hbuf_status(arty)

    wfms = unpack_and_sort_wfms(pgs)

    analyze_wfms(wfms)

    # clear the hit buffer
    print("Clearing the hit buffer")
    arty.fpga_write("hbuf_pg_clr_count", 0xFFFF)
    arty.fpga_write("hbuf_task_reg", 0x2)
    print_hbuf_status(arty)


if __name__ == "__main__":
    main()
