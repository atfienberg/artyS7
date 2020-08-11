// Aaron Fienberg
//
// Test bench for the mDOM pretrigger_buffer 
//

`timescale 1ns/1ns

module tb();
   
   parameter CLK_PERIOD = 10;
   reg clk;
   initial begin
     // clock initialization        
     clk = 1'b0;  	
   end

   // clock driver
   always @(clk)
     #(CLK_PERIOD / 2.0) clk <= !clk;

   // PTB signals and instantiation
   reg rst = 1;
   reg[11:0] adc_in = 0;
   reg[7:0] discr_in = 5;
   reg tot = 0;

   reg[4:0] pre_conf = 4;

   wire[21:0] ptb_out;
   wire[7:0] discr_out = ptb_out[21:14];
   wire[11:0] adc_out = ptb_out[13:2];
   wire tot_out = ptb_out[1];
   wire ptb_rdy;
   pretrigger_buffer #(.P_PRE_CONF_WIDTH(5), 
	               .P_DATA_WIDTH(22))
    PTB
     (
      .clk(clk),
      .rst(rst),
      .adc_in(adc_in),
      .discr_in(discr_in),
      .tot_in(tot),
      .rdy(ptb_rdy),
      .ptb_out(ptb_out),
      .size_config(pre_conf)
     );

   integer cnt = 0;
   always @(posedge clk) begin
     cnt <= cnt + 1;

     if (!rst) begin
	adc_in <= adc_in + 1;
	discr_in <= discr_in + 1;
     end

     if (cnt == 4) begin
       rst <= 0;
     end

     if (cnt == 45) begin
       pre_conf <= 3;
     end

     if (cnt == 47) begin
       pre_conf <= 1;
     end

     if (cnt == 50) begin
       pre_conf <= 16;
     end

     if (cnt == 65) begin
       pre_conf <= 31; 
     end

   end
      
endmodule