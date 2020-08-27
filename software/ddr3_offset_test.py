###################################################
# Aaron Fienberg
#
#
# Test writing to arbitrary DDR3 addresses
#

from artyS7 import artyS7, read_dev_path
import time
import sys
import numpy as np

PGS_TO_TEST = 500
START_PG = np.random.randint(0, (65536-PGS_TO_TEST))


def set_pg_num(arty, pg):
    # only test low addresses for now
    byte_addr = pg * 4096
    set_DDR3_addr(arty, byte_addr)


def set_DDR3_addr(arty, byte_addr):    
    addr_low = byte_addr & 0xFFFF
    addr_high = (byte_addr >> 16) & 0xFFFF
    arty.fpga_write("ddr3_pg_addr_low", addr_low)
    arty.fpga_write("ddr3_pg_addr_high", addr_high)


def send_DPRAM_to_pg(arty, pg):
    set_pg_num(arty, pg)
    arty.fpga_write("dpram_sel", 0)
    arty.fpga_write("ddr3_pg_optype", 1)
    arty.fpga_write("ddr3_pg_req", 1)


def read_DDR3_pg(arty, pg):
    set_pg_num(arty, pg)
    arty.fpga_write("dpram_sel", 0)
    arty.fpga_write("ddr3_pg_optype", 0)
    arty.fpga_write("ddr3_pg_req", 1)

    return arty.fpga_read(0, 2048)


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    print("Enable DDR3 interface")
    arty.fpga_write("ddr3_enable", 1)

    cal_done = arty.fpga_read("ddr3_cal_complete")

    print(f"cal complete: {cal_done}")

    print(f"selecting ddr3 page transfer dpram...")
    arty.fpga_write("dpram_sel", 0)

    pg = 0

    # test writing random patterns to the memory chip
    print(f"writing ramp to page {pg}")

    data = np.arange(2048)

    hdata = "".join(f"{val:04x}" for val in data)
    arty.fpga_burst_write(0, hdata)

    time.sleep(0.05)

    readback = arty.fpga_read(0, 2048)

    if not np.array_equal(data, readback):
        raise RuntimeError(
            "Could not successfully read data back from page transfer DPRAM"
        )

    # pages.append(data)

    # ship to DDR3 memory
    send_DPRAM_to_pg(arty, pg)

    print("clearing dpram...")
    arty.fpga_burst_write(0, "0" * 8192)
    assert np.array_equal(np.zeros(2048, dtype=np.int16), arty.fpga_read(0, 2048))

    print("Reading page 0 back")
    pg_data = read_DDR3_pg(arty, pg)
    if np.array_equal(pg_data, data):
        print("Match!")
    else:
        print("Mismatch!")

    # ship to addr 2
    print('shipping page to DDR3 addr 16...')
    set_DDR3_addr(arty, 16)
    arty.fpga_write("dpram_sel", 0)
    arty.fpga_write("ddr3_pg_optype", 1)
    arty.fpga_write("ddr3_pg_req", 1)

    # read back page 0
    print('reading back page 0')
    set_DDR3_addr(arty, 0)
    arty.fpga_write("ddr3_pg_optype", 0)
    arty.fpga_write("ddr3_pg_req", 1)


if __name__ == "__main__":
    main()
