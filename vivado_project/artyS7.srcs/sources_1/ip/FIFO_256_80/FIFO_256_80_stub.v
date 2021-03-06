// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Tue Aug 25 18:57:43 2020
// Host        : LAPTOP-GBOUD091 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               C:/Users/atfie/IceCube/artyS7/vivado_project/artyS7.srcs/sources_1/ip/FIFO_256_80/FIFO_256_80_stub.v
// Design      : FIFO_256_80
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s50csga324-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "fifo_generator_v13_2_4,Vivado 2019.1" *)
module FIFO_256_80(clk, srst, din, wr_en, rd_en, dout, full, empty, 
  data_count)
/* synthesis syn_black_box black_box_pad_pin="clk,srst,din[79:0],wr_en,rd_en,dout[79:0],full,empty,data_count[7:0]" */;
  input clk;
  input srst;
  input [79:0]din;
  input wr_en;
  input rd_en;
  output [79:0]dout;
  output full;
  output empty;
  output [7:0]data_count;
endmodule
