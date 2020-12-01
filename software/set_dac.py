###################################################
# Aaron Fienberg
#
# Set an AD5668 DAC output
#

from artyS7 import artyS7, read_dev_path
import sys
import time

SPI_SEL = 0xEDF
DAC_SEL = 0xEDE
DAC_TASK = 0xEDD
DAC_DATA_HIGH = 0xEDC
DAC_DATA_LOW = 0xEDB


def check_spi_task(arty):
    if arty.fpga_read(DAC_TASK) & 0x1 != 0:
        raise RuntimeError("DAC SPI task did not complete")


def set_dac(arty, spi_nums, dac_nums, chan, val):
    val = arty.parse_int_arg(val)

    spi_sel_val = 0
    for spi_num in spi_nums:
        spi_sel_val |= 1 << spi_num

    arty.fpga_write(SPI_SEL, spi_sel_val)

    dac_sel_val = 0
    for dac_num in dac_nums:
        dac_sel_val |= 1 << dac_num

    arty.fpga_write(DAC_SEL, dac_sel_val)

    # set internal reference
    arty.fpga_write(DAC_DATA_HIGH, 0x0800)
    arty.fpga_write(DAC_DATA_LOW, 0x0001)
    arty.fpga_write(DAC_TASK, 0x1)
    time.sleep(0.001)
    check_spi_task(arty)

    # set output value
    high_data = (0x02 << 8) | ((chan & 0xFF) << 4) | (val >> 12)
    arty.fpga_write(DAC_DATA_HIGH, high_data)
    low_data = (val & 0xFFF) << 4
    arty.fpga_write(DAC_DATA_LOW, low_data)
    arty.fpga_write(DAC_TASK, 0x1)
    time.sleep(0.001)
    check_spi_task(arty)


def main():
    if len(sys.argv) < 5:
        print("Usage: set_dac.py <spi_num> <dac_num> <chan> <val>")
        sys.exit(0)

    spi_num = int(sys.argv[1])
    dac_num = int(sys.argv[2])
    chan = int(sys.argv[3])
    val = sys.argv[4]

    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    set_dac(arty, [spi_num], [dac_num], chan, val)


if __name__ == "__main__":
    main()
