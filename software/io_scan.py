#
# mDOM ADC IO delay / bitslip test
#

import time

from artyS7 import artyS7, read_dev_path
from adc_reg import adc_data, adc_adrs, adc_hw_reset, adc_write, build_adc_wr_data


ADC_IO_CHAN_SEL = 0xEEE
ADC_IO_CTRL = 0xEED
ADC_DELAY_TAPOUT = 0xEEC
ADC_IO_RESET = [0xEEA, 0xEEB]
SW_TRIG = [0xFFC, 0xEF4]
BUF_RST = [0xEF9, 0xEF0]

test_conf = 200


def convert_channel_idx(channel):
    """ convert a channel index (0-23) to a chip num (0-5) and channel num (0-3)"""
    return channel // 4, channel % 4


def set_test_pattern(arty, chan_idx, pat_name):
    adc_num, chan_num = convert_channel_idx(chan_idx)

    wr_word = build_adc_wr_data(adc_data["test_pat_enbl"])
    adc_write(arty, [adc_num], adc_adrs["test_pat_enbl"], wr_word)

    wr_word = build_adc_wr_data(adc_data["test_pats"][pat_name][chan_num])
    adc_write(arty, [adc_num], adc_adrs["test_pat"][chan_num], wr_word)


def read_delays(arty, chan_idx):
    arty.fpga_write(ADC_IO_CHAN_SEL, chan_idx)

    tapout_val = arty.fpga_read(ADC_DELAY_TAPOUT)

    mask = 0x1F
    return tuple((tapout_val >> 5 * i) & mask for i in range(2))


def inc_delay(arty, chan_idx, line):
    arty.fpga_write(ADC_IO_CHAN_SEL, chan_idx)

    shift = 4 * line
    arty.fpga_write(ADC_IO_CTRL, 0x3 << shift)


def set_delay(arty, chan_idx, line, delay):
    start_delay = read_delays(arty, chan_idx)[line]
    current_delay = start_delay

    while current_delay != delay:
        inc_delay(arty, chan_idx, line)
        current_delay = read_delays(arty, chan_idx)[line]

        if current_delay == start_delay:
            raise RuntimeError(
                "Could not set delay for "
                f"channel {chan_idx} line D{line} "
                f"to {delay}!"
            )


def send_sw_trigger(arty, chan_idx):
    adr_idx = chan_idx // 16
    adr_bit = chan_idx % 16

    arty.fpga_write(SW_TRIG[adr_idx], 1 << adr_bit)


def get_sw_wfm(arty, chan_idx):
    send_sw_trigger(arty, chan_idx)
    time.sleep(0.001)

    wfm = arty.read_waveform()
    if wfm is None:
        raise RuntimeError("Failed to read waveform")
    elif wfm["chan_num"] != chan_idx:
        raise RuntimeError("Read a waveform from the wrong channel!")

    return wfm


def scan_delays(arty, chan_idx, line):
    set_test_pattern(arty, chan_idx, "deskew")

    bit_pos = 0 if line == 0 else 6
    mask = 0x3F

    start_delay = read_delays(arty, chan_idx)[line]
    last_checked = None

    output = []
    while last_checked != start_delay:
        inc_delay(arty, chan_idx, line)

        wfm = get_sw_wfm(arty, chan_idx)

        # check that all samples are 0xAAA
        valid = True
        for sample in wfm["adc_samples"]:
            line_sample = (sample >> bit_pos) & mask
            if line_sample != 0x2A and line_sample != 0x15:
                valid = False
                break

        last_checked = read_delays(arty, chan_idx)[line]
        output.append((last_checked, valid))

    return output


def bitslip(arty, chan_idx, line):
    arty.fpga_write(ADC_IO_CHAN_SEL, chan_idx)

    shift = 4 * line
    arty.fpga_write(ADC_IO_CTRL, 0x4 << shift)


def autoslip(arty, chan_idx, line):
    set_test_pattern(arty, chan_idx, "toggle")

    bit_pos = 0 if line == 0 else 6
    mask = 0x3F

    for i in range(6):
        wfm = get_sw_wfm(arty, chan_idx)

        first_samp = wfm["adc_samples"][0]
        line_bits = (first_samp >> bit_pos) & mask

        if line_bits == 0x15 or line_bits == 0x2A:
            return i

        bitslip(arty, chan_idx, line)

    return 6


def get_best_setting(scan_res, good_len=5):
    n_delays = len(scan_res)

    transitions = []
    for i, (delay, is_good) in enumerate(scan_res):
        # check whether this delay marks a transition from
        # a good region to a bad region
        # if so, record it
        if is_good != scan_res[i - 1][1]:
            transitions.append((delay, is_good))

    n_transitions = len(transitions)
    good_setting = None
    for i, transition in enumerate(transitions):
        if transition[1] == True:
            # found a transition to a good delay setting
            next_transition = transitions[(i + 1) % n_transitions]
            n_good_settings = (next_transition[0] - transition[0]) % n_delays

            if n_good_settings >= good_len:
                good_start = transition[0]
                good_end = next_transition[0]
                if good_end < good_start:
                    good_end += n_delays

                good_setting = ((good_start + good_end) // 2) % n_delays
                break

    return good_setting, n_good_settings


def print_delay_scan(scan_result, marker_pos=None, marker_char=None):
    """ print the result of a delay scan to the terminal """
    output_str = ""

    settings = sorted(scan_result, key=lambda x: x[0])

    # "O" denotes a good setting
    # "X" denotes a bad setting
    for setting in settings:
        if setting[1]:
            output_str += " O "
        else:
            output_str += " X "
    print(output_str)

    output_str = ""
    for setting in settings:
        if setting[0] == marker_pos:
            output_str += f" {marker_char} "
        else:
            next_out = f"{setting[0]} "
            if len(next_out) < 3:
                next_out = " " + next_out
            output_str += next_out

    print(output_str)


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=0.1)

    # reset ADC
    adc_hw_reset(arty)

    # reset ADC IO
    for i in range(2):
        arty.fpga_write(ADC_IO_RESET[i], 0xFFFF)
        time.sleep(0.001)
        arty.fpga_write(ADC_IO_RESET[i], 0x0)

    # reset waveform buffers
    arty.fpga_write(0xEF9, 0xFFFF)
    arty.fpga_write(0xEF0, 0xFFFF)
    arty.fpga_write(0xEF9, 0x0)
    arty.fpga_write(0xEF0, 0x0)

    # configure test conf and dpram mode
    arty.fpga_write("test_conf", test_conf)
    arty.fpga_write("buf_reader_dpram_mode", 1)

    # enable reader
    arty.fpga_write("buf_reader_enable", 0x1)

    # run the delay / bitslip scan for all 24 channels
    try:
        for chan in range(24):
            for line in range(2):
                result = scan_delays(arty, chan, line)
                print(f"Chan {chan} D{line}")
                best_setting, n_good = get_best_setting(result)
                print_delay_scan(result, marker_pos=best_setting, marker_char="|")
                print(f"{n_good} good settings; setting delay to {best_setting}")
                set_delay(arty, chan, line, best_setting)
                n_slips = autoslip(arty, chan, line)
                print(f"{n_slips} bitslips")
    finally:
        print("disabling reader...")
        arty.fpga_write("buf_reader_enable", 0x0)


if __name__ == "__main__":
    main()
