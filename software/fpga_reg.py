###################################################
# Aaron Fienberg
#
# read or write an xdom register

from artyS7 import artyS7, read_dev_path
import sys


def print_register_map():
    print("FPGA register map:")

    for key, value in artyS7.fpga_adrs.items():
        try:
            value = hex(value)
        except TypeError:
            value = repr([hex(v) for v in value]).replace("'", "")

        print(f"{key} : {value}")


def main():
    if len(sys.argv) == 1:
        print_register_map()
        return 0

    adr = sys.argv[1]

    if len(sys.argv) >= 3:
        data = sys.argv[2]
    else:
        data = None

    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    if data is not None:
        arty.fpga_write(adr, data)

    print(hex(arty.fpga_read(adr)))


if __name__ == "__main__":
    main()
