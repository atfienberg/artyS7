// Aaron Fienberg
// August 2020
//
// trigger logic for mDOM waveform acquisition
//

module mdom_trigger
(
  input clk,
  input rst,
  
  // data stream in and out
  input[11:0] adc_stream_in,
  output reg[11:0] adc_stream_out = 0,
  input[7:0] discr_stream_in,
  output reg[7:0] discr_stream_out = 0,
  
  // threshold trigger settings 
  input gt,
  input et,
  input lt,
  input[11:0] thr,
  input thresh_trig_en,
  // sw trig
  input run,
  
  // ext trig
  input ext_trig_en,
  input ext_run,
    
  // discr trig
  input discr_trig_en,
  input discr_trig_pol,
  
  // trigger outputs
  output reg[1:0] trig_src = 0,
  output reg trig = 0,
  output reg thresh_tot = 0,
  output reg discr_tot = 0
);
`include "trigger_src_inc.v"

// register synchronous reset
(* DONT_TOUCH = "true" *) reg i_rst = 0;
always @(posedge clk) begin
  i_rst <= rst;
end

// posedge detector on ext_run and run
wire ext_run_p;
posedge_detector PEDGE_EXTRUN(.clk(clk), .rst_n(!i_rst), .a(ext_run), .y(ext_run_p));
wire run_p;
posedge_detector PEDGE_RUN(.clk(clk), .rst_n(!i_rst), .a(run), .y(run_p));

// comparator for threshold triggering
wire i_thresh_tot;
cmp CMP(.a(adc_stream_in), .b(thr), .y(i_thresh_tot), .gt(gt), .et(et), .lt(lt));

// discrimainator trigger check
wire i_discr_tot = (discr_trig_pol == 0 && (&discr_stream_in == 1'b0)) || 
                   (discr_trig_pol == 1 && (|discr_stream_in == 1'b1));

always @(posedge clk) begin
  if (i_rst) begin
    adc_stream_out <= 0;
    discr_stream_out <= 0;

    thresh_tot <= 0;
    discr_tot <= 0;

    trig_src <= 0;
    trig <= 0;
  end
 
  else begin
    adc_stream_out <= adc_stream_in;
    discr_stream_out <= discr_stream_in;

    thresh_tot <= i_thresh_tot;
    discr_tot <= i_discr_tot;
    
    if (ext_trig_en && ext_run_p) begin
      trig_src <= TRIG_SRC_EXT;
      trig <= 1;
    end

    else if (discr_trig_en && i_discr_tot) begin
      trig_src <= TRIG_SRC_DISCR;
      trig <= 1;
    end

    else if (thresh_trig_en && i_thresh_tot) begin
      trig_src <= TRIG_SRC_THRESH;
      trig <= 1;
    end

    else if (run_p) begin
      trig_src <= TRIG_SRC_SW;
      trig <= 1;
    end

    else begin
      trig_src <= 0;
      trig <= 0;
    end
  end
end


endmodule