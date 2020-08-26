###################################################
# Aaron Fienberg
#
# overflow all buffers, then drain them

from artyS7 import artyS7, read_dev_path
import sys
import numpy as np
from sw_trig_all import *


test_conf = 500


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    print("Resetting waveform buffers...")
    arty.fpga_write(0xEF9, 0xFFFF)
    arty.fpga_write(0xEF0, 0xFFFF)
    arty.fpga_write(0xEF9, 0x0)
    arty.fpga_write(0xEF0, 0x0)

    print("Configuring test conf")
    arty.fpga_write("test_conf", test_conf)

    print("Causing buffer overflow...")
    while arty.fpga_read(0xEFA) != 0xFFFF or arty.fpga_read(0xEF1) != 0xFF:
        arty.fpga_write(0xFFC, 0xFFFF)
        arty.fpga_write(0xEF4, 0xFFFF)
    print_wfm_count(arty)

    print("Enabling reader")
    arty.fpga_write("buf_reader_enable", 0x1)

    print("draining buffers...")
    counter = 0
    while True:
        wfm = arty.read_waveform()
        if wfm is None:
            break

        counter = counter + 1
        if counter % 100 == 0:
            print_wfm_count(arty)

    print(counter)

    print_wfm_count(arty)

    print("disabling reader...")
    arty.fpga_write("buf_reader_enable", 0x0)


if __name__ == "__main__":
    main()
