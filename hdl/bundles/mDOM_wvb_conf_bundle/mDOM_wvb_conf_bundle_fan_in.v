module mDOM_wvb_conf_bundle_fan_in
  (
   bundle,
   cnst_conf,
   test_conf,
   post_conf,
   pre_conf,
   arm,
   trig_mode,
   cnst_run
  );

`include "mDOM_wvb_conf_bundle_inc.v"

   output [39:0] bundle;
   input [11:0] cnst_conf;
   input [11:0] test_conf;
   input [7:0] post_conf;
   input [4:0] pre_conf;
   input [0:0] arm;
   input [0:0] trig_mode;
   input [0:0] cnst_run;

assign bundle[11:0] = cnst_conf;
assign bundle[23:12] = test_conf;
assign bundle[31:24] = post_conf;
assign bundle[36:32] = pre_conf;
assign bundle[37:37] = arm;
assign bundle[38:38] = trig_mode;
assign bundle[39:39] = cnst_run;


endmodule
