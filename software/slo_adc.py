# Aaron Fienberg
#
# Test ADS8332
# Adapted from D-Egg test
#

from artyS7 import artyS7, read_dev_path

NCONVST = 0xDF5
SLO_WR_HIGH = 0xDF8
SLO_WR_LOW = 0xDE4
SLO_RD_HIGH = 0xDF7
SLO_RD_LOW = 0xDE3
SLO_TASK = 0xEFF
SLO_SEL = 0xDF6


def pulse_nconvst(arty):
    arty.fpga_write(NCONVST, 0x1)


def split_read_data(data):
    """ split read data into 16 bit data
    and 3 bit channel tag """
    tag = data & 0x7
    data = data >> 3

    return data, tag


def slo_cmd(arty, data):
    high_write = (data >> 13) & 0x7
    low_write = (data & 0x1FFF) << 3

    arty.fpga_write(SLO_WR_HIGH, high_write)
    arty.fpga_write(SLO_WR_LOW, low_write)
    arty.fpga_write(SLO_TASK, 0x4)

    high_read = arty.fpga_read(SLO_RD_HIGH)
    low_read = arty.fpga_read(SLO_RD_LOW)

    return split_read_data((high_read << 16) | low_read)


def run_test():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    for chip_num in [0, 1]:
        print(f"chip {chip_num}")
        arty.fpga_write(SLO_SEL, chip_num)

        # test write and read to CFR
        slo_cmd(arty, 0xEAA5)
        data, tag = slo_cmd(arty, 0xC000)
        print(hex(data))
        slo_cmd(arty, 0xE555)
        data, tag = slo_cmd(arty, 0xC000)
        print(hex(data))
        slo_cmd(arty, 0xEDE7)
        data, tag = slo_cmd(arty, 0xC000)
        print(hex(data))

        # reset
        slo_cmd(arty, 0xE000)
        data, tag = slo_cmd(arty, 0xC000)
        print(hex(data))

        # read a conversion from each channel
    for chip_num in [0, 1]:
        arty.fpga_write(SLO_SEL, chip_num)

        vals = []
        for i in range(8):
            pulse_nconvst(arty)
            data, tag = slo_cmd(arty, 0xD000)

            vals.append((hex(data), tag))

        print(f"chip {chip_num}: {vals}")


def main():
    run_test()


if __name__ == "__main__":
    main()
