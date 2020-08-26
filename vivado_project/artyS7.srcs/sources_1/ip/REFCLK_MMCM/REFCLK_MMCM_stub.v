// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Wed Aug 26 13:56:18 2020
// Host        : LAPTOP-GBOUD091 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/atfie/IceCube/artyS7/vivado_project/artyS7.srcs/sources_1/ip/REFCLK_MMCM/REFCLK_MMCM_stub.v
// Design      : REFCLK_MMCM
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s50csga324-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
module REFCLK_MMCM(clk_200MHZ, reset, locked, clk_in1)
/* synthesis syn_black_box black_box_pad_pin="clk_200MHZ,reset,locked,clk_in1" */;
  output clk_200MHZ;
  input reset;
  output locked;
  input clk_in1;
endmodule
