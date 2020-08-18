// Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
// --------------------------------------------------------------------------------
// Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
// Date        : Mon Aug 17 20:43:56 2020
// Host        : LAPTOP-GBOUD091 running 64-bit major release  (build 9200)
// Command     : write_verilog -force -mode synth_stub
//               c:/Users/atfie/IceCube/artyS7/vivado_project/artyS7.srcs/sources_1/ip/BUFFER_2048_22/BUFFER_2048_22_stub.v
// Design      : BUFFER_2048_22
// Purpose     : Stub declaration of top-level module interface
// Device      : xc7s50csga324-2
// --------------------------------------------------------------------------------

// This empty module with port declaration file causes synthesis tools to infer a black box for IP.
// The synthesis directives are for Synopsys Synplify support to prevent IO buffer insertion.
// Please paste the declaration into a Verilog source file or add the file as an additional source.
(* x_core_info = "blk_mem_gen_v8_4_3,Vivado 2019.1" *)
module BUFFER_2048_22(clka, wea, addra, dina, clkb, addrb, doutb)
/* synthesis syn_black_box black_box_pad_pin="clka,wea[0:0],addra[10:0],dina[21:0],clkb,addrb[10:0],doutb[21:0]" */;
  input clka;
  input [0:0]wea;
  input [10:0]addra;
  input [21:0]dina;
  input clkb;
  input [10:0]addrb;
  output [21:0]doutb;
endmodule
