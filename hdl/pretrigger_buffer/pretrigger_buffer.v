// Aaron Fienberg
// August 2020
//
// mDOM waveform/discriminator pretrigger buffer 
//
// size_config must be >= 3. values < 3 will be interpreted as 3

module pretrigger_buffer #(parameter P_PRE_CONF_WIDTH = 5, 
                           parameter P_DATA_WIDTH = 22,
                           parameter P_USE_DISTRIBUTED_RAM = 0)
(
  input clk,
  input rst,

  input[11:0] adc_in,
  input[7:0] discr_in,
  input tot_in,

  output rdy,
  output[P_DATA_WIDTH-1:0] ptb_out,

  input[P_PRE_CONF_WIDTH-1:0] size_config 
);

wire[P_DATA_WIDTH-1:0] ptb_in = {discr_in, adc_in, tot_in, 1'b0};

localparam[31:0] RDY_CNT = (1<<P_PRE_CONF_WIDTH); 

// determined from simulation
localparam[31:0] RD_ADDR_OFFSET = 2; 

// clip size_conf at RD_ADDR_OFFSET + 1
wire[P_PRE_CONF_WIDTH-1:0] adj_size_conf = 
   (size_config > RD_ADDR_OFFSET) ? size_config : RD_ADDR_OFFSET + 1;


reg[P_PRE_CONF_WIDTH-1:0] wr_addr = 0;
wire[P_PRE_CONF_WIDTH-1:0] rd_addr = wr_addr - (adj_size_conf - RD_ADDR_OFFSET);

generate
  if (P_USE_DISTRIBUTED_RAM == 0) begin
    // use block RAM
    BUFFER_32_22 PTB
      (
       .clka(clk),
       .wea(1'b1),
       .addra(wr_addr),
       .dina(ptb_in),
       .clkb(clk),
       .addrb(rd_addr),
       .doutb(ptb_out)  
      );  
  end
  else begin
    // Use LUT distributed RAM 
    DIST_BUFFER_32_22 DIST_PTB
      (
       .clk(clk),
       .a(wr_addr),
       .d(ptb_in),       
       .we(1'b1),
       .dpra(rd_addr),
       .qdpo(ptb_out)  
      ); 
  end
endgenerate

reg[31:0] cnt = 0;
always @(posedge clk) begin
  if (rst) begin
    cnt <= 0;
    wr_addr <= 0;    
  end

  else begin
   wr_addr <= wr_addr + 1;   

   if (cnt < RDY_CNT) begin
     cnt <= cnt + 1;
   end
  end
end

assign rdy = cnt >= RDY_CNT;

endmodule