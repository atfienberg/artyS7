# artyS7.py
#
# Aaron Fienberg
# August 2020
#
# Functions for unpacking waveforms from the
# Arty S7/mDOM prototype project
#

import numpy as np

trig_type_map = {0: "sw", 1: "thresh", 2: "discr", 3: "sw"}


def unpack_wfm(payload):
    if payload[0] >> 8 != 0x90:
        raise RuntimeError(f"Invalid header word! Got 0x{payload[0]:04x}")

    wfm = {}

    wfm["chan_num"] = payload[0] & 0xFF
    wfm["evt_len"] = payload[1]

    wfm["pre_conf"] = payload[2] >> 11
    wfm["const_run"] = ((payload[2] >> 10) & 0x1) == 1
    wfm["trig_type"] = trig_type_map[payload[2] & 0x3]
    wfm["ltc"] = (payload[3] << 32) + (payload[4] << 16) + payload[5]

    wfm["adc_samples"] = payload[6:-2:2]

    discr_words = payload[7:-2:2]
    wfm["discr_samples"] = discr_words >> 8
    wfm["tot"] = (discr_words >> 1) & 0x1
    wfm["eoe"] = (discr_words) & 0x1

    return wfm


def wfm_n_words(payload):
    if payload[0] >> 8 != 0x90:
        raise RuntimeError(f"Invalid header word! Got 0x{payload[0]:04x}")
    # format 1
    return 8 + 2 * payload[1]
