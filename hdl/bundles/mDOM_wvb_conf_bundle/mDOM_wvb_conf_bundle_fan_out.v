module mDOM_wvb_conf_bundle_fan_out
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

   input [39:0] bundle;
   output [11:0] cnst_conf;
   output [11:0] test_conf;
   output [7:0] post_conf;
   output [4:0] pre_conf;
   output [0:0] arm;
   output [0:0] trig_mode;
   output [0:0] cnst_run;

assign cnst_conf = bundle[11:0];
assign test_conf = bundle[23:12];
assign post_conf = bundle[31:24];
assign pre_conf = bundle[36:32];
assign arm = bundle[37:37];
assign trig_mode = bundle[38:38];
assign cnst_run = bundle[39:39];

endmodule
