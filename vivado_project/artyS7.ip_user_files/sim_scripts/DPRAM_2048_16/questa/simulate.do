onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib DPRAM_2048_16_opt

do {wave.do}

view wave
view structure
view signals

do {DPRAM_2048_16.udo}

run -all

quit -force
