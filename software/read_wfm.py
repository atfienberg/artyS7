###################################################
# Aaron Fienberg
#
# read a waveform and print it out

from artyS7 import artyS7, read_dev_path
import sys
import numpy as np


def check_ramp(wfm):
    samples = wfm["adc_samples"]

    diff = np.remainder((samples[1:] - samples[:-1]), (1 << 12))

    return np.all(diff == 1)


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"))

    wfm = arty.read_waveform()

    print(wfm)

    print(f'n samples: {len(wfm["adc_samples"])}')

    # check ramp
    print(f"ramping adc samples: {check_ramp(wfm)}")


if __name__ == "__main__":
    main()
