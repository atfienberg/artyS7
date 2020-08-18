onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib BUFFER_2048_22_opt

do {wave.do}

view wave
view structure
view signals

do {BUFFER_2048_22.udo}

run -all

quit -force
