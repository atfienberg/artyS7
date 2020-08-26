onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib REFCLK_MMCM_opt

do {wave.do}

view wave
view structure
view signals

do {REFCLK_MMCM.udo}

run -all

quit -force
