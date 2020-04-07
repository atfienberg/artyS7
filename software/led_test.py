###################################################
# Aaron Fienberg
#
# tests/exercises the LED controls

from artyS7 import artyS7, read_dev_path
import time
import sys


def main():
    arty = artyS7(dev_path=read_dev_path('./conf/uart_path.txt'))

    for i in range(3):
        arty.disable_led(i)


    arty.set_rgb_led_color((4000, 0, 0))
    arty.enable_led(0)
    
    time.sleep(1)
    arty.set_rgb_led_color((0, 4000, 0))
    time.sleep(1)
    arty.set_rgb_led_color((0, 0, 4000))
    time.sleep(1)
    arty.set_rgb_led_color((1000, 5000, 3000))

    arty.disable_led(0)
    arty.enable_led(1)
    time.sleep(5)
    arty.fpga_write('rgb_cycle_speed_sel', 2)
    time.sleep(10)

    arty.enable_led(2)

    for i in range(4):
        time.sleep(2)
        arty.fpga_write('kr_speed_sel', i)

    for i in range(3):
        arty.disable_led(i)


if __name__ == '__main__':
    main()
