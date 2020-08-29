// Aaron Fienberg
//
// Test bench for verifying 64 bit crc 

`timescale 1ns/1ns

module crc_tb();
parameter CLK_PERIOD = 10;
reg clk;
initial begin
 // clock initialization        
 clk = 1'b0;    
end

// clock driver
always @(clk)
 #(CLK_PERIOD / 2.0) clk <= !clk;

// crc module
reg crc_rst = 1;
reg crc_en = 0;
wire[15:0] crc_out;
reg[63:0] crc_din;
crc16_64b_parallel CRC
(
  .data_in(crc_din),
  .crc_en(crc_en),
  .crc_out(crc_out),
  .rst(crc_rst),
  .clk(clk)
);

reg[47:0] ltc = 0;

always @(posedge clk) begin
  crc_rst <= 0;
  crc_en <= 0;

  ltc <= ltc + 1;

  if (ltc == 2) begin
  	crc_rst <= 1;
  end

  if (ltc == 5) begin
  	crc_din <= 64'h123456789abcdef0;
  	crc_en <= 1;
  end

  if (ltc == 6) begin
  	crc_din <= 64'h1234000056780000;
  	crc_en <= 1;
  end 

end
  
// 8 bit crc
reg[7:0] crc_din_8bit = 0;
reg crc_en_8bit = 0;
reg crc_rst_8bit = 0;
wire[15:0] crc_out_8bit;
crc CRC_8b
(
  .data_in(crc_din_8bit),
  .crc_en(crc_en_8bit),
  .crc_out(crc_out_8bit),
  .rst(crc_rst_8bit),
  .clk(clk)
);

always @(posedge clk) begin
  crc_rst_8bit <= 0;
  crc_en_8bit <= 0;

  if (ltc == 2) begin
  	crc_rst_8bit <= 1;
  end

  if (ltc == 5) begin
  	crc_din_8bit <= 8'hf0;
  	crc_en_8bit <= 1;
  end

  if (ltc == 6) begin
  	crc_din_8bit <= 8'hde;
  	crc_en_8bit <= 1;
  end

  if (ltc == 7) begin
  	crc_din_8bit <= 8'hbc;
  	crc_en_8bit <= 1;
  end

  if (ltc == 8) begin
  	crc_din_8bit <= 8'h9a;
  	crc_en_8bit <= 1;
  end

  if (ltc == 9) begin
  	crc_din_8bit <= 8'h78;
  	crc_en_8bit <= 1;
  end

  if (ltc == 10) begin
  	crc_din_8bit <= 8'h56;
  	crc_en_8bit <= 1;
  end

  if (ltc == 11) begin
  	crc_din_8bit <= 8'h34;
  	crc_en_8bit <= 1;
  end

  if (ltc == 12) begin
  	crc_din_8bit <= 8'h12;
  	crc_en_8bit <= 1;
  end

 
end


endmodule
