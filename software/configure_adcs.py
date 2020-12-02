#
# Configure ADCs:
# pulse ADC_RESET
# enable SP mode
# disable dither
# disable chopper
from artyS7 import artyS7, read_dev_path
from adc_reg import adc_data, adc_adrs, adc_hw_reset, adc_write


def main():
    arty = artyS7(dev_path=read_dev_path("./conf/uart_path.txt"), uart_sleep=1)

    adc_hw_reset(arty)

    adc_nums = list(range(6))

    # enable SP mode
    for chan in range(4):
        adc_write(arty, adc_nums, adc_adrs["sp_mode"][chan], adc_data["enable_sp"])

    # disable dither
    adc_write(arty, adc_nums, adc_adrs["dither_low"], adc_data["disable_dither_low"])
    for chan in range(4):
        adc_write(
            arty,
            adc_nums,
            adc_adrs["dither_high"][chan],
            adc_data["disable_dither_high"],
        )

    # disable chopper
    for chan in range(4):
        adc_write(
            arty, adc_nums, adc_adrs["chopper"][chan], adc_data["disable_chopper"]
        )


if __name__ == "__main__":
    main()
