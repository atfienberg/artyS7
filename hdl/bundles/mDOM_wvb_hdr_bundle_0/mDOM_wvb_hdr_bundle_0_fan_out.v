module mDOM_wvb_hdr_bundle_0_fan_out
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

   input [79:0] bundle;
   output [47:0] evt_ltc;
   output [11:0] start_addr;
   output [11:0] stop_addr;
   output [1:0] trig_src;
   output [0:0] cnst_run;
   output [4:0] pre_conf;

assign evt_ltc = bundle[47:0];
assign start_addr = bundle[59:48];
assign stop_addr = bundle[71:60];
assign trig_src = bundle[73:72];
assign cnst_run = bundle[74:74];
assign pre_conf = bundle[79:75];

endmodule
