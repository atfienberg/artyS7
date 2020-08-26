onbreak {quit -f}
onerror {quit -f}

vsim -t 1ps -lib xil_defaultlib XDOM_DDR3_PG_opt

do {wave.do}

view wave
view structure
view signals

do {XDOM_DDR3_PG.udo}

run -all

quit -force
