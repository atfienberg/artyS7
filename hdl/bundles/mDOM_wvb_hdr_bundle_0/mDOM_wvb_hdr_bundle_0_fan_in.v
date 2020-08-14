module mDOM_wvb_hdr_bundle_0_fan_in
  (
   bundle,
   evt_ltc,
   start_addr,
   stop_addr,
   trig_src,
   cnst_run,
   pre_conf
  );

`include "mDOM_wvb_hdr_bundle_0_inc.v"

   output [79:0] bundle;
   input [47:0] evt_ltc;
   input [11:0] start_addr;
   input [11:0] stop_addr;
   input [1:0] trig_src;
   input [0:0] cnst_run;
   input [4:0] pre_conf;

assign bundle[47:0] = evt_ltc;
assign bundle[59:48] = start_addr;
assign bundle[71:60] = stop_addr;
assign bundle[73:72] = trig_src;
assign bundle[74:74] = cnst_run;
assign bundle[79:75] = pre_conf;


endmodule
