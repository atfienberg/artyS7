###################################################
# Aaron Fienberg
#
# set an LED color
# takes 15 bit values for red, green blue

from artyS7 import artyS7, read_dev_path
import time
import sys


def main():
    if len(sys.argv) != 4:
        print('Usage: set_led_color <red> <green> <blue> (15 bit values)')
    
    arty = artyS7(dev_path=read_dev_path('./conf/uart_path.txt'))

    try:    
        rgb_tuple = tuple(int(arg) for arg in sys.argv[1:])
    except ValueError:
        rgb_tuple = tuple(int(arg, 16) for arg in sys.argv[1:])

    arty.enable_led(0)

    arty.set_rgb_led_color(rgb_tuple)


if __name__ == '__main__':
    main()
