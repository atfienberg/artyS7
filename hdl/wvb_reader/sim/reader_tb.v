// Aaron Fienberg
//
// Test bench for the mDOM waveform buffer reader (fmt 0)
//

`timescale 1ns/1ns

module reader_tb();

parameter CLK_PERIOD = 10;
reg clk;
initial begin
  // clock initialization        
  clk = 1'b0;    
end

// clock driver
always @(clk)
  #(CLK_PERIOD / 2.0) clk <= !clk;

// dynamic inputs
reg rst = 1;
reg[11:0] adc_in = 0;
reg[7:0] discr_in = 5;
reg trig = 0;
reg[47:0] ltc = 0;
reg[1:0] trig_src = 0;

wire[11:0] wvb_wused;
wire[9:0] wvb_n_wvf_in_buf;
wire overflow_out;
wire[21:0] wvb_out;
wire[7:0] discr_out = wvb_out[21:14];
wire[11:0] adc_out = wvb_out[13:2];
wire tot_out = wvb_out[1];
wire eoe_out = wvb_out[0];

wire wvb_rdreq;
wire hdr_rdreq;
wire rddone;

wire[79:0] hdr_out;
wire hdr_full;
wire hdr_empty;

reg[11:0] test_conf = 10;

// instantiate the waveform buffer
waveform_buffer WVB 
  (
   // Outputs
   .wvb_wused(wvb_wused),
   .n_wvf_in_buf(wvb_n_wvf_in_buf),
   .wvb_overflow(overflow_out),
   .armed(),   
   .wvb_data_out(wvb_out),
   .hdr_data_out(hdr_out),
   .hdr_full(hdr_full),
   .hdr_empty(hdr_empty),

   // Inputs
   .clk(clk),
   .rst(rst),
   .ltc_in(ltc),
   .adc_in(adc_in),
   .discr_in(discr_in), 
   .tot(trig),
   .trig(trig),
   .trig_src(trig_src),
   .arm(1'b0),

   .wvb_rdreq(wvb_rdreq),
   .hdr_rdreq(hdr_rdreq),
   .wvb_rddone(rddone),

   // Config inputs
   .pre_conf(4),
   .post_conf(4),
   .test_conf(test_conf),
   .cnst_run(0),
   .cnst_conf(10),
   .trig_mode(0)
  );

// instantiate wvb reader 
wire[9:0] dpram_a;
wire[31:0] dpram_data;
wire[15:0] dpram_high = dpram_data[31:16];
wire[11:0] reader_adc_word = dpram_low[11:0];
wire[15:0] dpram_low = dpram_data[15:0];
wire dpram_wren;
wire[15:0] dpram_len;
wire dpram_run;
reg dpram_mode = 0;
reg dpram_busy = 0;
reg dpram_done = 0;

reg reader_enable = 0;
wvb_reader WVB_READER 
(
  .clk(clk),
  .rst(rst),
  .en(reader_enable),
  .dpram_data(dpram_data),
  .dpram_addr(dpram_a),
  .dpram_wren(dpram_wren),
  .dpram_len(dpram_len),
  .dpram_run(dpram_run),
  .dpram_busy(dpram_busy),
  .dpram_mode(dpram_mode),
  .hdr_rdreq(hdr_rdreq),
  .wvb_rdreq(wvb_rdreq),
  .wvb_rddone(wvb_rddone),
  .wvb_data(wvb_out),
  .hdr_data(hdr_out),
  .hdr_empty(hdr_empty)
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

  // external trigger at ltc == 45  
  if (ltc == 44) begin
    trig <= 1;
    trig_src <= 3;
  end

  // external trigger at ltc == 65 
  if (ltc == 64) begin
    trig <= 1;
    trig_src <= 3;
  end

  if (ltc == 100) begin
    reader_enable <= 1;
  end

  // test DPRAM abort case; increase waveform length
  // and fire the trigger
  if (ltc == 127) begin
    test_conf <= 1035;
  end

  if (ltc == 129) begin
    trig <= 1;
    trig_src <= 3;
  end

  // test DPRAM continue
  if (ltc == 2189) begin
    dpram_mode <= 1;
  end

  if (ltc == 2199) begin
    trig <= 1;
    trig_src <= 3;
  end

  // test ftr loop
  if (ltc == 4295) begin
    test_conf <= 1021;
  end

  if (ltc == 4299) begin
    trig <= 1;
    trig_src <= 3;
  end

end

// handle rbd signals
always @(posedge clk) begin
  if (dpram_run) begin
    dpram_busy <= 1;
  end

  else if (dpram_done && dpram_busy) begin
    dpram_busy <= 0;
  end
end

// fake DPRAM user
always @(posedge clk) begin
  if (dpram_busy) begin
    #110
    dpram_done <= 1;
    #10
    dpram_done <= 0;
  end
end

endmodule