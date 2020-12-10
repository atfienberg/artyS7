###################################################
# Aaron Fienberg
#
# Read a SW triggered waveform from ADC0, channel 0
#

from artyS7 import artyS7, read_dev_path
import numpy as np

from io_scan import get_sw_wfm, reset_wfm_buffers

test_conf = 50
chan_num = 0


def print_wfm_count(arty):
    count = []
    for chan in range(24):
        arty.fpga_write("buf_stat_chan_sel", chan)
        count.append(arty.fpga_read("n_wfms_in_buf"))
    print(f"wfms in buf: {count}")


def build_signed_view(wfm):
    # interpret samples as signed 16-bit ints
    wfm["signed_samples"] = wfm["adc_samples"].view(np.int16)


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    print("Resetting waveform buffers...")
    reset_wfm_buffers(arty)

    print("Configuring test conf")
    arty.fpga_write("test_conf", test_conf)

    arty.fpga_write("buf_reader_dpram_mode", 1)

    print_wfm_count(arty)

    print("Sending software trigger")
    get_sw_wfm(chan_num)

    print_wfm_count(arty)

    print("Enabling reader")

    arty.fpga_write("buf_reader_enable", 0x1)

    wfm = arty.read_waveform()
    if wfm is None:
        raise RuntimeError("Failed to read waveform!")

    print("disabling reader...")
    arty.fpga_write("buf_reader_enable", 0x0)

    # convert to offset binary
    build_signed_view(wfm)
    print(wfm)

    # print low bits of first 10 samples
    low_bits = [hex(samp & 0x3F) for samp in wfm["adc_samples"][:10]]
    high_bits = [hex((samp >> 6) & 0x3F) for samp in wfm["adc_samples"][:10]]
    print(f"low bits: {low_bits}")
    print(f"high bits: {high_bits}")


if __name__ == "__main__":
    main()
