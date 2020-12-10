# artyS7.py
#
# Aaron Fienberg
# April 2020
#
# Class for interfacing with the Arty S7 FPGA via the USB UART interface
#

import logging
import time
import numpy as np
from .uartClass import uartClass
from .unpack_wfm import unpack_wfm, wfm_n_words


class artyS7:
    """ class for interfacing with the FPGA on the arty S7 board
    via the USB UART interface
    """

    # address and data maps
    fpga_adrs = {
        "fw_vnum": 0xFFF,
        "dpram_done": 0xDFF,
        "dpram_len": 0xDFE,
        "dpram_sel": 0xDF9,
        "buf_reader_enable": 0xDF4,
        "buf_reader_dpram_mode": 0xDF2,
        "trig_settings": 0xBFE,
        "trig_threshold": 0xBFD,
        "sw_trig_mask": 0xBFB,
        "trig_arm_mask": 0xBF9,
        "sw_trig_trig_arm": 0xBF8,
        "trig_mode": 0xBF7,
        "trig_armed": 0xBF5,
        "const_run": 0xBF4,
        "const_conf": 0xBF3,
        "test_conf": 0xBF2,
        "post_conf": 0xBF1,
        "pre_conf": 0xBF0,
        "buf_stat_chan_sel": 0xBEF,
        "n_wfms_in_buf": 0xBEE,
        "buf_wds_used": 0xBED,
        "buf_overflow": 0xBEB,
        "buf_rst": 0xBE9,
        "wvb_header_full": 0xBE7,
        "ddr3_pg_addr_high": 0xBCD,
        "ddr3_pg_addr_low": 0xBCC,
        "ddr3_pg_optype": 0xBCB,
        "ddr3_pg_req": 0xBCA,
        "ddr3_enable": 0xBC9,
        "ddr3_cal_complete": 0xBC8,
        "ddr3_device_temp": 0xBC7,
        "ddr3_ui_sync_rst": 0xBC6,
        "hbuf_enable": 0xBC5,
        "hbuf_start_pg": 0xBC4,
        "hbuf_stop_pg": 0xBC3,
        "hbuf_first_pg": 0xBC2,
        "hbuf_last_pg": 0xBC1,
        "hbuf_pg_clr_count": 0xBC0,
        "hbuf_task_reg": 0xBBF,
        "hbuf_rd_pg_num": 0xBBE,
        "hbuf_wr_pg_num": 0xBBD,
        "hbuf_n_pgs_used": 0xBBC,
        "hbuf_stat": 0xBBB,
        "led_toggle": 0x8FF,
        "rgb_red": 0x8FE,
        "rgb_green": 0x8FD,
        "rgb_blue": 0x8FC,
        "rgb_cycle_speed_sel": 0x8FB,
        "kr_speed_sel": 0x8FA,
        "event_data": 0x0,
    }

    fpga_data = {}

    #
    # Methods
    #

    def __init__(
        self, uart=None, dev_path=None, uart_sleep=0, uart_timeout=0.25, n_read_tries=3,
    ):
        """ Initializes the artyS7 object

        can pass in either an instance of uartClass or a device path,
        e.g. artyS7(dev_path='/dev/ttys3')
        or artyS7(uart)

        uart_sleep is the number of ms to sleep following each uart command

        uart_timeout is the timeout for the usb uart serial interface

        n_read_tries is how many times to attempt a read operation before throwing an error
        """

        if uart is not None and dev_path is not None:
            # must provide either a uart object or a dev path, not both
            raise RuntimeError(
                "Both uart and dev_path are not None (only one should be use)"
            )

        self.uart = uart

        if dev_path is not None:
            uart = uartClass()
            uart.rs232_setup(dev_path, timeout=uart_timeout)
            self.uart = uart

        if uart is None:
            raise RuntimeError("uart is unitialized")

        self.uart_sleep = uart_sleep / 1000  # convert from ms to s

        self.n_read_tries = n_read_tries

    @property
    def fw_vnum(self):
        return self.fpga_read("fw_vnum")

    def read_waveform(self):
        """ read a waveform from the board"""
        event_len = int(self.fpga_read("dpram_len"))

        if event_len == 0:
            return None

        self.fpga_write("dpram_sel", 1)

        dpram_mode = self.fpga_read("buf_reader_dpram_mode")

        fragments = [self.fpga_read("event_data", read_len=event_len)]

        if dpram_mode == 0:
            self.fpga_write("dpram_done", 1)
            return unpack_wfm(fragments[0])

        expected_total_words = wfm_n_words(fragments[0])

        n_read = event_len
        while n_read < expected_total_words:
            self.fpga_write("dpram_done", 1)

            next_len = self.fpga_read("dpram_len")

            if next_len == 0:
                break

            fragments.append(self.fpga_read("event_data", read_len=next_len))
            n_read += next_len

        wfm_payload = np.hstack(fragments)

        self.fpga_write("dpram_done", 1)

        return unpack_wfm(wfm_payload)

    def enable_led(self, led_num):
        """ enables an LED/LED group
        0 - configurable RGB
        1 - cycling RGB
        2 - knight rider LEDS """

        current = self.fpga_read("led_toggle")

        self.fpga_write("led_toggle", (1 << led_num) | current)

    def disable_led(self, led_num):
        """ disables an LED/LED group """
        current = self.fpga_read("led_toggle")

        self.fpga_write("led_toggle", (~(1 << led_num)) & current)

    def set_rgb_led_color(self, rgb_vals):
        """ takes a tuple of 15-bit rgb vals (red_val, green_val, blue_val)

        sets the configurable RGB LED intensities accordingly
        """

        if len(rgb_vals) != 3:
            raise ValueError("rgb_vals must be length 3!")

        h_data = "".join(f"{val:04x}" for val in rgb_vals[::-1])

        self.fpga_burst_write("rgb_blue", h_data)

    def register_dump(self):
        """ read all the FPGA DPRAM addresses.
        returns a list with one register value per entry, starting with address 0"""
        DPRAM_SIZE = 0x1000
        data = self.fpga_read(0, read_len=DPRAM_SIZE)

        hex_chars = hex(data).rstrip("L")[2:].zfill(4 * DPRAM_SIZE)

        return [hex_chars[4 * i : 4 * i + 4] for i in range(DPRAM_SIZE)]

    def fpga_write(self, adr, data):
        """ wrapper around uart write """
        adr = self.parse_fpga_adr(adr)

        data = self.parse_fpga_data(data)

        self.uart.exe_cmd(logging, s_act="swr", adr=adr, data=data)

        time.sleep(self.uart_sleep)

    def fpga_burst_write(self, adr, h_data):
        """ wrapper around uart burst write """
        adr = self.parse_fpga_adr(adr)

        self.uart.exe_cmd(logging, s_act="bwr", adr=adr, h_data=h_data)

        time.sleep(self.uart_sleep)

    def fpga_read(self, adr, read_len=1):
        """ wrapper around uart read """
        adr = self.parse_fpga_adr(adr)

        read_len = int(read_len)

        if read_len == 1:
            data, ok = self._fpga_srd(adr)
        elif read_len > 1:
            data, ok = self._fpga_brd(adr, read_len)

        else:
            raise ValueError(f"read_len ({read_len}) must be >= 1!")

        if not ok:
            raise RuntimeError("Incorrect checksum from uart read!")

        time.sleep(self.uart_sleep)

        return data

    def _fpga_srd(self, adr):
        """ fpga single read """
        for i in range(self.n_read_tries):
            try:
                data, ok = self.uart.exe_cmd(logging, s_act="srd", adr=adr)
                break
            except IOError:
                if i == self.n_read_tries - 1:
                    raise

        return data, ok

    def _fpga_brd(self, adr, read_len):
        """ fpga burst read """
        for i in range(self.n_read_tries):
            try:
                data, ok = self.uart.exe_cmd(
                    logging, s_act="brd", adr=adr, length=read_len
                )
                break
            except IOError:
                if i == self.n_read_tries - 1:
                    raise

        # interpret data as array of uint16s, ignoring the crc
        data_array = np.frombuffer(self.uart.cc.cmd["raw_rsp"][:-2], np.uint16)
        data_array = data_array.byteswap()

        return data_array, ok

    @staticmethod
    def parse_int_arg(arg):
        try:
            return int(arg)
        except ValueError:
            return int(arg, 16)

    @staticmethod
    def parse_str_arg(arg, table):
        return table[arg]

    @staticmethod
    def parse_indexed_arg(arg, table):
        start_ind = arg.index("[")
        end_ind = arg.index("]")

        key = arg[:start_ind]
        index = int(arg[start_ind + 1 : end_ind])

        return table[key][index]

    @staticmethod
    def parse_arg(arg, table):
        try:
            return artyS7.parse_int_arg(arg)
        except ValueError:
            pass

        try:
            return artyS7.parse_str_arg(arg, table)
        except (ValueError, KeyError):
            pass

        return artyS7.parse_indexed_arg(arg, table)

    @staticmethod
    def parse_fpga_adr(arg):
        return artyS7.parse_arg(arg, table=artyS7.fpga_adrs)

    @staticmethod
    def parse_fpga_data(arg):
        return artyS7.parse_arg(arg, table=artyS7.fpga_data)
