###################################################
# Aaron Fienberg
#
# quickly configure pre/post/const/test conf after reloading firmware

from artyS7 import artyS7, read_dev_path
import sys


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    setting = 10
    for reg in ["const_conf", "test_conf", "pre_conf", "post_conf"]:
        arty.fpga_write(reg, setting)


if __name__ == "__main__":
    main()
