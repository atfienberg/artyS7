###################################################
# Aaron Fienberg
#
#
# Test DDR3 page transfer
#

from artyS7 import artyS7, read_dev_path
import time
import sys
import numpy as np

PGS_TO_TEST = 1000
START_PG = np.random.randint(0, (65536 - PGS_TO_TEST))


def set_DDR3_pg_addr(arty, pg):
    # only test low addresses for now
    byte_addr = pg * 4096
    addr_low = byte_addr & 0xFFFF
    addr_high = (byte_addr >> 16) & 0xFFFF
    arty.fpga_write("ddr3_pg_addr_low", addr_low)
    arty.fpga_write("ddr3_pg_addr_high", addr_high)


def send_DPRAM_to_pg(arty, pg):
    set_DDR3_pg_addr(arty, pg)
    arty.fpga_write("dpram_sel", 0)
    arty.fpga_write("ddr3_pg_optype", 1)
    arty.fpga_write("ddr3_pg_req", 1)


def read_DDR3_pg(arty, pg):
    set_DDR3_pg_addr(arty, pg)
    arty.fpga_write("dpram_sel", 0)
    arty.fpga_write("ddr3_pg_optype", 0)
    arty.fpga_write("ddr3_pg_req", 1)

    return arty.fpga_read(0, 2048)


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    print("Enable DDR3 interface")
    arty.fpga_write("ddr3_enable", 1)

    time.sleep(0.1)
    cal_done = arty.fpga_read("ddr3_cal_complete")

    print(f"cal complete: {cal_done}")

    print(f"selecting ddr3 page transfer dpram...")
    arty.fpga_write("dpram_sel", 0)

    pages = []

    # test writing random patterns to the memory chip
    for pg in range(START_PG, START_PG + PGS_TO_TEST):
        print(f"writing to page {pg}")

        data = np.random.randint(0, 0x10000, size=2048)

        hdata = "".join(f"{val:04x}" for val in data)
        arty.fpga_burst_write(0, hdata)

        time.sleep(0.05)

        readback = arty.fpga_read(0, 2048)

        if not np.array_equal(data, readback):
            raise RuntimeError(
                "Could not successfully read data back from page transfer DPRAM"
            )

        pages.append(data)

        # ship to DDR3 memory
        send_DPRAM_to_pg(arty, pg)

    print("clearing dpram...")
    arty.fpga_burst_write(0, "0" * 8192)
    assert np.array_equal(np.zeros(2048, dtype=np.int16), arty.fpga_read(0, 2048))

    print("Reading pages back")
    all_good = True
    for i, pg in enumerate(range(START_PG, START_PG + PGS_TO_TEST)):
        print(f"checking page {pg}")

        pg_data = read_DDR3_pg(arty, pg)
        if np.array_equal(pg_data, pages[i]):
            print("Match!")
        else:
            print("Mismatch!")
            all_good = False

    if all_good:
        print("Success!")
    else:
        print("Failure!")


if __name__ == "__main__":
    main()
