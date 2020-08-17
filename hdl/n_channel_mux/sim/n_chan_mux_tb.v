// Aaron Fienberg
//
// Test bench for the n channel mux
//

`timescale 1ns/1ns

module n_chan_mux_tb();
   
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
   wire[7:0] inputs[0:7];
   assign inputs[0] = 5;
   assign inputs[1] = 6;
   assign inputs[2] = 7;
   assign inputs[3] = 8;
   assign inputs[4] = 9;
   assign inputs[5] = 10;
   assign inputs[6] = 11;
   assign inputs[7] = 12;
   
   wire[8*8-1:0] mux_in;
   generate 
     genvar i;
     for (i = 0; i < 8; i = i + 1) begin
     	assign mux_in[8*(i+1) - 1:8*i] = inputs[i];
     end
   endgenerate

   reg[4:0] sel = 0;
   wire[7:0] mux_out;

   n_channel_mux #(.INPUT_WIDTH(8)) N_CHAN_MUX
    (
    	.in(mux_in), 
      .sel(sel), 
   	  .out(mux_out)
   	);

   integer cnt = 0;
   always @(posedge clk) begin
     cnt <= cnt + 1;

     sel <= ((cnt + 2) % 8); 
   end
      
endmodule