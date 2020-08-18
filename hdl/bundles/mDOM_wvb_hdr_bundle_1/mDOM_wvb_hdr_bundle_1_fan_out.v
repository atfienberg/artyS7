module mDOM_wvb_hdr_bundle_1_fan_out
  (
   bundle,
   evt_ltc,
   start_addr,
   stop_addr,
   trig_src,
   cnst_run
  );

`include "mDOM_wvb_hdr_bundle_1_inc.v"

   input [70:0] bundle;
   output [47:0] evt_ltc;
   output [9:0] start_addr;
   output [9:0] stop_addr;
   output [1:0] trig_src;
   output [0:0] cnst_run;

assign evt_ltc = bundle[47:0];
assign start_addr = bundle[57:48];
assign stop_addr = bundle[67:58];
assign trig_src = bundle[69:68];
assign cnst_run = bundle[70:70];

endmodule
