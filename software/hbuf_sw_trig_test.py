###################################################
# Aaron Fienberg
#
# Test the DDR3 hit buffer with software triggers
#

from artyS7 import artyS7, read_dev_path, unpack_wfm
from ddr3_test import read_DDR3_pg
from sw_trig_all import *
import time
import sys
import numpy as np

test_conf = 1021

START_PG = 550
STOP_PG = 650


def print_hbuf_status(arty):
    stat = arty.fpga_read("hbuf_stat")
    empty = stat & 0x1
    full = (stat >> 1) & 0x1
    buffered_data = (stat >> 2) & 0x1
    n_used_pgs = arty.fpga_read("hbuf_n_pgs_used")
    print(f"hbuf status: empty-{empty}, full-{full}, buffered_data-{buffered_data}")
    print(f"hbuf n pages used: {n_used_pgs}")


def pop_hbuf_pg(arty):
    is_empty = arty.fpga_read("hbuf_stat") & 0x1
    if is_empty:
        return None

    pg_num = arty.fpga_read("hbuf_rd_pg_num")
    print(f"popping pg {pg_num}")
    pg_data = read_DDR3_pg(arty, pg_num)

    # clear the page
    arty.fpga_write("hbuf_pg_clr_count", 1)
    arty.fpga_write("hbuf_task_reg", 0x2)

    # check header and footer
    hdr = np.array([0xA000, 0x5555, 0xAAAA, 0x5555], dtype=np.uint16)
    ftr = np.array([0xAAAA, 0x5555, 0xAAAA, 0xBEEF], dtype=np.uint16)

    if not np.array_equal(pg_data[:4], hdr):
        failed_hdr = [f"0x{v:04x}" for v in pg_data[:4]]
        print(f"failed header: {failed_hdr}")
        raise RuntimeError(f"Header mismatch on pg {pg_num}!")

    if not np.array_equal(pg_data[-4:], ftr):
        failed_ftr = [f"0x{v:04x}" for v in pg_data[-4:]]
        print(f"failed footer: {failed_ftr}")
        raise RuntimeError(f"Footer mismatch on pg {pg_num}!")

    return pg_data


def unpack_and_check_wfms(pages):
    raw_array = np.concatenate([pg[4:-4] for pg in pages])

    wfms = []
    while len(raw_array) > 0:
        wfm_len = raw_array[1]
        wfm_payload = raw_array[: 2 * wfm_len + 8]

        wfms.append(unpack_wfm.unpack_wfm(wfm_payload))
        wfm = wfms[-1]
        chan = wfm["chan_num"]
        print(f"wfm from channel {chan} with len {wfm_len}")
        assert ((wfm["adc_samples"][0] & 0xFF) + chan) % 0x100 == wfm["discr_samples"][
            0
        ]
        assert check_ramp(wfm)
        assert wfm["trig_type"] == "sw"

        raw_array = raw_array[2 * wfm_len + 8 :]
        # drop filler zeros
        n_dropped = 0
        while len(raw_array) > 0 and raw_array[0] == 0:
            n_dropped += 1
            raw_array = raw_array[1:]
        # print(f'dropped {n_dropped} zeros')


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

    print("Enabling memory controller and hbuf controller")
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

    print("Sending software triggers")
    arty.fpga_write(0xFFC, 0xFFFF)
    arty.fpga_write(0xEF4, 0xFFFF)
    print_wfm_count(arty)

    print("Enabling reader")
    arty.fpga_write("buf_reader_enable", 0x1)
    print_wfm_count(arty)
    print_hbuf_status(arty)

    print("Sending more software triggers")
    arty.fpga_write(0xFFC, 0xFFFF)
    arty.fpga_write(0xEF4, 0xFFFF)
    print_wfm_count(arty)
    print_hbuf_status(arty)

    print("Flushing hbuf")
    arty.fpga_write("hbuf_task_reg", 0x1)
    print_hbuf_status(arty)

    print("Draining hit buffer")
    pages = []
    while True:
        pg = pop_hbuf_pg(arty)
        if pg is None:
            break
        pages.append(pg)

    print_hbuf_status(arty)

    print("disabling reader...")
    arty.fpga_write("buf_reader_enable", 0x0)

    print("Unpacking waveforms...")
    unpack_and_check_wfms(pages)


if __name__ == "__main__":
    main()
