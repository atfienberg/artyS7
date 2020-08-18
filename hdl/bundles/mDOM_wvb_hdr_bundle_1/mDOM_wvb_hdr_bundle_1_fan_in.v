module mDOM_wvb_hdr_bundle_1_fan_in
  (
   bundle,
   evt_ltc,
   start_addr,
   stop_addr,
   trig_src,
   cnst_run
  );

`include "mDOM_wvb_hdr_bundle_1_inc.v"

   output [70:0] bundle;
   input [47:0] evt_ltc;
   input [9:0] start_addr;
   input [9:0] stop_addr;
   input [1:0] trig_src;
   input [0:0] cnst_run;

assign bundle[47:0] = evt_ltc;
assign bundle[57:48] = start_addr;
assign bundle[67:58] = stop_addr;
assign bundle[69:68] = trig_src;
assign bundle[70:70] = cnst_run;


endmodule
