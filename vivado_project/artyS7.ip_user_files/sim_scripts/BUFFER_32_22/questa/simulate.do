onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib BUFFER_32_22_opt

do {wave.do}

view wave
view structure
view signals

do {BUFFER_32_22.udo}

run -all

quit -force
