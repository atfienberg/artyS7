###################################################
# Aaron Fienberg
#
# quickly configure pre/post/const/test conf after reloading firmware

from artyS7 import artyS7, read_dev_path
import sys


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    # enable DDR3
    arty.fpga_write("ddr3_enable", 1)
    # allocate 10 pages
    arty.fpga_write("hbuf_stop_pg", 10)
    # enable the reader
    arty.fpga_write("buf_reader_enable", 1)
    # start the controller
    arty.fpga_write("hbuf_enable", 1)

    print(f'Reader status: {arty.fpga_read("hbuf_stat")}')
    print(f'Reader last page: {arty.fpga_read("hbuf_last_pg")}')


if __name__ == "__main__":
    main()
