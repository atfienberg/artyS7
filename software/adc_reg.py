###################################################
# Aaron Fienberg
#
# test serial interface with ADC0
# read or write an adc register

from artyS7 import artyS7, read_dev_path
import sys
import time

ADC_RESET = 0xEE5
ADC_SEL = 0xEE4
ADC_TASK = 0xEE3
ADC_WR_DATA_HIGH = 0xEE2
ADC_WR_DATA_LOW = 0xEE1
ADC_RD_DATA = 0xEE0


def adc_hw_reset(arty):
    arty.fpga_write(ADC_RESET, 0x1)
    arty.fpga_write(ADC_RESET, 0x0)


def check_spi_task(arty):
    if arty.fpga_read(ADC_TASK) & 0x1 != 0:
        raise RuntimeError("ADC SPI task did not complete")


def adc_write(arty, adc_nums, adr, data):
    adr = arty.parse_int_arg(adr)
    data = arty.parse_int_arg(data)

    adc_sel_val = 0
    for adc_num in adc_nums:
        adc_sel_val |= 1 << adc_num

    arty.fpga_write(ADC_SEL, adc_sel_val)

    adc_wr_data_high = 0x40 | (adr >> 8)
    adc_wr_data_low = ((adr & 0xFF) << 8) | data

    arty.fpga_write(ADC_WR_DATA_HIGH, adc_wr_data_high)
    arty.fpga_write(ADC_WR_DATA_LOW, adc_wr_data_low)
    arty.fpga_write(ADC_TASK, 0x1)

    time.sleep(0.001)

    check_spi_task(arty)


def adc_read(arty, adr):
    adr = arty.parse_int_arg(adr)

    # only ADC0 has its SDOUT connected
    arty.fpga_write(ADC_SEL, 0x1)

    adc_wr_data_high = 0xC0 | (adr >> 8)
    adc_wr_data_low = (adr & 0xFF) << 8

    arty.fpga_write(ADC_WR_DATA_HIGH, adc_wr_data_high)
    arty.fpga_write(ADC_WR_DATA_LOW, adc_wr_data_low)
    arty.fpga_write(ADC_TASK, 0x1)

    time.sleep(0.001)

    check_spi_task(arty)

    return arty.fpga_read(ADC_RD_DATA)


def main():
    if len(sys.argv) < 2:
        print("Usage: adc_reg.py <adr> <data (optional)>")
        sys.exit(0)

    adr = sys.argv[1]

    if len(sys.argv) >= 3:
        data = sys.argv[2]
    else:
        data = None

    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    if data is not None:
        adc_write(arty, [0], adr, data)

    print(f"0x{adc_read(arty, adr):02x}")


if __name__ == "__main__":
    main()
