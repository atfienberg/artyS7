onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+HBUF_DDR3_PG -L xil_defaultlib -L xpm -L blk_mem_gen_v8_4_3 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.HBUF_DDR3_PG xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {HBUF_DDR3_PG.udo}

run -all

endsim

quit -force
