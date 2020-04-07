###################################################
# Aaron Fienberg
#
# burst read from xdom

import sys
from artyS7 import artyS7, read_dev_path


def main():
    if len(sys.argv) < 3:
        print('Usage: fpga_brd.py <start_adr> <read_len>')
        return 0

    start_adr = sys.argv[1]

    arty = artyS7(dev_path=read_dev_path('./conf/uart_path.txt'))

    n_to_read = int(sys.argv[2])
    read_data = arty.fpga_read(start_adr, read_len=n_to_read)

    if n_to_read == 1:
        read_data = [read_data]

    for word in read_data:
        print(hex(word))


if __name__ == '__main__':
    sys.exit(main())
