###################################################
# Aaron Fienberg
#
# Tests the rate scaler
#

from artyS7 import artyS7, read_dev_path
from pulser_trig_test import (
    PULSER_WIDTH_REG,
    PULSER_IO_RESET,
    PULSER_TRIG_MASK,
    PULSER_FIRE,
    DISCR_IO_RESET,
)

import time

SCALER_PERIOD_HIGH = 0xBBA
SCALER_PERIOD_LOW = 0xBB9
SCALER_CHAN_SEL = 0xBB8
SCALER_CNT_HIGH = 0xBB7
SCALER_CNT_LOW = 0xBB6

CLK_FREQ = 125000000

pulser_width = 2
scaler_period = 1  # one second


def set_scaler_period(arty, period, clk_freq=CLK_FREQ):
    """ period shall be in seconds """
    period_in_cycles = int(period * clk_freq)

    arty.fpga_write(SCALER_PERIOD_HIGH, period_in_cycles >> 16)
    arty.fpga_write(SCALER_PERIOD_LOW, period_in_cycles & 0xFFFF)


def read_scaler(arty, channel):
    arty.fpga_write(SCALER_CHAN_SEL, channel)

    high = arty.fpga_read(SCALER_CNT_HIGH)
    low = arty.fpga_read(SCALER_CNT_LOW)

    return (high << 16) | low


def print_scaler_count(arty, channels):
    for chan in channels:
        print(f"Channel {chan} scaler count: {read_scaler(arty, chan)}")


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    # configure fpga regs
    arty.fpga_write(PULSER_WIDTH_REG, pulser_width)
    arty.fpga_write(PULSER_IO_RESET, 0x3E)
    for i in range(2):
        arty.fpga_write(PULSER_TRIG_MASK[i], 0x0)
    arty.fpga_write(DISCR_IO_RESET[0], 0xFFFE)

    # set scaler period, wait two periods
    set_scaler_period(arty, scaler_period)
    print("Waiting...")
    time.sleep(2 * scaler_period)
    print_scaler_count(arty, [0, 1])

    # fire pulser a few times
    for i in range(7):
        arty.fpga_write(PULSER_FIRE, 0x1)

    # read back the scaler
    for i in range(10):
        time.sleep(scaler_period / 5)
        print_scaler_count(arty, [0, 1])


if __name__ == "__main__":
    main()
