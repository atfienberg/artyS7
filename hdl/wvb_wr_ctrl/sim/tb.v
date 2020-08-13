// Aaron Fienberg
//
// Test bench for the mDOM wvb write controller
//

`timescale 1ns/1ns

module wvb_wr_ctrl_tb();

parameter CLK_PERIOD = 10;
reg clk;
initial begin
  // clock initialization        
  clk = 1'b0;    
end

// clock driver
always @(clk)
  #(CLK_PERIOD / 2.0) clk <= !clk;

// test configuration
wire[4:0] pre_conf = 4;
wire[7:0] post_conf = 4;
wire[11:0] test_conf = 10;
wire[11:0] cnst_conf = 10;
reg cnst_run = 0;
wire trig_mode = 0;

// PTB signals and instantiation
reg rst = 1;
reg[11:0] adc_in = 0;
reg[7:0] discr_in = 5;
reg trig = 0;

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
  .tot_in(trig),
  .rdy(ptb_rdy),
  .ptb_out(ptb_out),
  .size_config(pre_conf)
);

// wvb wr controller signals and instantiation
wire arm = 0;

wire armed;
wire eoe;
wire wvb_overflow;
wire[11:0] wvb_wr_addr;
wire wvb_wrreq;
wire[159:0] hdr_data_in;
wire hdr_wrreq;

reg[47:0] ltc = 0;

reg[1:0] trig_src = 0;

wvb_wr_ctrl
WR_CTRL
(
 .clk(clk),
 .rst(rst),

 // Outputs
 .overflow_out(wvb_overflow),
 .armed(armed),
 .eoe(eoe),
 .wvb_wr_addr(wvb_wr_addr),
 .wvb_wren(wvb_wrreq),
 .hdr_data(hdr_data_in),
 .hdr_wren(hdr_wrreq),

 // Inputs
 .ltc(ltc),
 .pre_config(pre_conf),
 .post_config(post_conf),
 .test_config(test_conf),
 .cnst_config(cnst_conf),
 .trig_mode(trig_mode),
 .cnst_run(cnst_run),
 .arm(arm),
 .trig(trig && ptb_rdy),
 .trig_src(trig_src),   
 .overflow_in(1'b0)   
);

always @(posedge clk) begin
  ltc <= ltc + 1;

  if (!rst) begin
    adc_in <= adc_in + 1;
    discr_in <= discr_in + 1;
  end

  trig <= 0;
  trig_src <= 0;

  if (ltc == 5) begin
    rst <= 0;
  end

  if (ltc == 45) begin
    trig <= 1;
    trig_src <= 2;
  end

  // double trigger at 60
  if (ltc == 60 || ltc == 61) begin
    trig <= 1;
    trig_src <= 1;
  end

  // trigger w/ gap at 72
  if (ltc == 72 || ltc == 74) begin
    trig <= 1;
    trig_src <= 1;
  end

  // trig on last pretrigger sample
  if (ltc == 86 || ltc == 89) begin
    trig <= 1;
    trig_src <= 1;
  end

  // trig during SOT state
  if (ltc == 100 || ltc == 104) begin
    trig <= 1;
    trig_src <= 1;
  end

  // trig right after previous waveform is finished
  if (ltc == 113) begin
    trig <= 1;
    trig_src <= 1;
  end

  // trig during post samples
  if (ltc == 124 || ltc == 132) begin
    trig <= 1;
    trig_src <= 1;
  end

  // sw trigger
  if (ltc == 144) begin
    trig <= 1;
    trig_src <= 0;
  end

  // ext trigger
  if (ltc == 160) begin
    trig <= 1;
    trig_src <= 3;
  end

  if (ltc == 178) begin
    cnst_run <= 1;
  end

  // const trigger
  if (ltc == 180) begin  
    trig <= 1;
    trig_src <= 1;
  end

end


endmodule