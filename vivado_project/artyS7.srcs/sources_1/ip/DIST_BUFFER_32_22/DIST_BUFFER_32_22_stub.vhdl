-- Copyright 1986-2019 Xilinx, Inc. All Rights Reserved.
-- --------------------------------------------------------------------------------
-- Tool Version: Vivado v.2019.1 (win64) Build 2552052 Fri May 24 14:49:42 MDT 2019
-- Date        : Thu Aug 27 09:21:03 2020
-- Host        : LAPTOP-GBOUD091 running 64-bit major release  (build 9200)
-- Command     : write_vhdl -force -mode synth_stub
--               c:/Users/atfie/IceCube/artyS7/vivado_project/artyS7.srcs/sources_1/ip/DIST_BUFFER_32_22/DIST_BUFFER_32_22_stub.vhdl
-- Design      : DIST_BUFFER_32_22
-- Purpose     : Stub declaration of top-level module interface
-- Device      : xc7s50csga324-2
-- --------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity DIST_BUFFER_32_22 is
  Port ( 
    a : in STD_LOGIC_VECTOR ( 4 downto 0 );
    d : in STD_LOGIC_VECTOR ( 21 downto 0 );
    dpra : in STD_LOGIC_VECTOR ( 4 downto 0 );
    clk : in STD_LOGIC;
    we : in STD_LOGIC;
    qdpo : out STD_LOGIC_VECTOR ( 21 downto 0 )
  );

end DIST_BUFFER_32_22;

architecture stub of DIST_BUFFER_32_22 is
attribute syn_black_box : boolean;
attribute black_box_pad_pin : string;
attribute syn_black_box of stub : architecture is true;
attribute black_box_pad_pin of stub : architecture is "a[4:0],d[21:0],dpra[4:0],clk,we,qdpo[21:0]";
attribute x_core_info : string;
attribute x_core_info of stub : architecture is "dist_mem_gen_v8_0_13,Vivado 2019.1";
begin
end;
