
c
Command: %s
53*	vivadotcl22
write_bitstream -force top.bit2default:defaultZ4-113h px� 
�
@Attempting to get a license for feature '%s' and/or device '%s'
308*common2"
Implementation2default:default2
xc7s502default:defaultZ17-347h px� 
�
0Got license for feature '%s' and/or device '%s'
310*common2"
Implementation2default:default2
xc7s502default:defaultZ17-349h px� 
x
,Running DRC as a precondition to command %s
1349*	planAhead2#
write_bitstream2default:defaultZ12-1349h px� 
>
IP Catalog is up to date.1232*coregenZ19-1839h px� 
P
Running DRC with %s threads
24*drc2
22default:defaultZ23-27h px� 
�
�Missing CFGBVS and CONFIG_VOLTAGE Design Properties: Neither the CFGBVS nor CONFIG_VOLTAGE voltage property is set in the current_design.  Configuration bank voltage select (CFGBVS) must be set to VCCO or GND, and CONFIG_VOLTAGE must be set to the correct configuration voltage, in order to determine the I/O voltage support for the pins in bank 0.  It is suggested to specify these either using the 'Edit Device Properties' function in the GUI or directly in the XDC file using the following syntax:

 set_property CFGBVS value1 [current_design]
 #where value1 is either VCCO or GND

 set_property CONFIG_VOLTAGE value2 [current_design]
 #where value2 is the voltage provided to configuration bank 0

Refer to the device configuration user guide for more information.%s*DRC2(
 DRC|Pin Planning2default:default8ZCFGBVS-1h px� 
�
�Clock output buffering: PLLE2_ADV connectivity violation. The signal %s on the %s pin of %s does not drive the same kind of BUFFER load as the other CLKOUT pins. Routing from the different buffer types will not be phase aligned.%s*DRC2�
 "�
SDDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/pll_clk3_outSDDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/pll_clk3_out2default:default2default:default2�
 "�
VDDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/plle2_i/CLKOUT3VDDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/plle2_i/CLKOUT32default:default2default:default2�
 "�
NDDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/plle2_i	NDDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/plle2_i2default:default2default:default2C
 +DRC|Netlist|Instance|Required Pin|PLLE2_ADV2default:default8Z	REQP-1709h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_53�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_532default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_53�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[0].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_532default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_54�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_542default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_54�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[1].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_542default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_55�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_552default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_55�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[2].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_552default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_56�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_562default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[10]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
�RAMB36 async control check: The RAMB36E1 %s has an input control pin %s (net: %s) which is driven by a register (%s) that has an active asychronous set or reset. This may cause corruption of the memory contents and/or read values when the set/reset is asserted and is not analyzed by the default static timing analysis. It is suggested to eliminate the use of a set/reset to registers driving this RAMB pin or else use a synchronous reset in which the assertion of the reset is timed by default.%s*DRC2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram	�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram/ENBWREN2default:default2default:default2�
 "�
�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_56�XDOM_0/PG_DPRAM/U0/inst_blk_mem_gen/gnbram.gnativebmg.native_blk_mem_gen/valid.cstr/ramloop[3].ram.r/prim_noinit.ram/DEVICE_7SERIES.NO_BMM_INFO.TRUE_DP.SIMPLE_PRIM36.ram_ENBWREN_cooolgate_en_sig_562default:default2default:default2�
 "�
]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]	]DDR3_TRANSFER_0/MIG_7_SERIES/u_mig_7series_0_mig/u_ddr3_infrastructure/rstdiv0_sync_r_reg[11]2default:default2default:default2B
 *DRC|Netlist|Instance|Required Pin|RAMB36E12default:default8Z	REQP-1839h px� 
�
aNo routable loads: 123 net(s) have no routable loads. The problem bus(es) and/or net(s) are %s.%s*DRC2�
 "�
8waveform_acq_gen[0].WFM_ACQ/i_xdom_wvb_config_bundle[37]8waveform_acq_gen[0].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[15].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[15].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[22].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[22].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
8waveform_acq_gen[1].WFM_ACQ/i_xdom_wvb_config_bundle[37]8waveform_acq_gen[1].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[23].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[23].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[16].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[16].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
8waveform_acq_gen[7].WFM_ACQ/i_xdom_wvb_config_bundle[37]8waveform_acq_gen[7].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[10].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[10].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
8waveform_acq_gen[2].WFM_ACQ/i_xdom_wvb_config_bundle[37]8waveform_acq_gen[2].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[19].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[19].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[17].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[17].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
8waveform_acq_gen[3].WFM_ACQ/i_xdom_wvb_config_bundle[37]8waveform_acq_gen[3].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[11].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[11].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[21].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[21].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:default"�
9waveform_acq_gen[18].WFM_ACQ/i_xdom_wvb_config_bundle[37]9waveform_acq_gen[18].WFM_ACQ/i_xdom_wvb_config_bundle[37]2default:..."0
(the first 15 of 123 listed)2default:default2default:default2=
 %DRC|Implementation|Routing|Chip Level2default:default8Z	RTSTAT-10h px� 
g
DRC finished with %s
1905*	planAhead2)
0 Errors, 11 Warnings2default:defaultZ12-3199h px� 
i
BPlease refer to the DRC report (report_drc) for more information.
1906*	planAheadZ12-3200h px� 
i
)Running write_bitstream with %s threads.
1750*designutils2
22default:defaultZ20-2272h px� 
?
Loading data files...
1271*designutilsZ12-1165h px� 
>
Loading site data...
1273*designutilsZ12-1167h px� 
?
Loading route data...
1272*designutilsZ12-1166h px� 
?
Processing options...
1362*designutilsZ12-1514h px� 
<
Creating bitmap...
1249*designutilsZ12-1141h px� 
7
Creating bitstream...
7*	bitstreamZ40-7h px� 
Z
Writing bitstream %s...
11*	bitstream2
	./top.bit2default:defaultZ40-11h px� 
F
Bitgen Completed Successfully.
1606*	planAheadZ12-1842h px� 
�
�WebTalk data collection is mandatory when using a WebPACK part without a full Vivado license. To see the specific WebTalk data collected for your design, open the usage_statistics_webtalk.html or usage_statistics_webtalk.xml file in the implementation directory.
120*projectZ1-120h px� 
Z
Releasing license: %s
83*common2"
Implementation2default:defaultZ17-83h px� 
�
G%s Infos, %s Warnings, %s Critical Warnings and %s Errors encountered.
28*	vivadotcl2
1462default:default2
202default:default2
12default:default2
02default:defaultZ4-41h px� 
a
%s completed successfully
29*	vivadotcl2#
write_bitstream2default:defaultZ4-42h px� 
�
I%sTime (s): cpu = %s ; elapsed = %s . Memory (MB): peak = %s ; gain = %s
268*common2%
write_bitstream: 2default:default2
00:01:022default:default2
00:00:422default:default2
2427.6372default:default2
343.5352default:defaultZ17-268h px� 


End Record