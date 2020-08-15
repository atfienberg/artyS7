module mDOM_trig_bundle_fan_in
  (
   bundle,
   trig_et,
   trig_gt,
   trig_lt,
   trig_run,
   discr_trig_pol,
   trig_thresh,
   disc_trig_en,
   thresh_trig_en,
   ext_trig_en
  );

`include "mDOM_trig_bundle_inc.v"

   output [19:0] bundle;
   input [0:0] trig_et;
   input [0:0] trig_gt;
   input [0:0] trig_lt;
   input [0:0] trig_run;
   input [0:0] discr_trig_pol;
   input [11:0] trig_thresh;
   input [0:0] disc_trig_en;
   input [0:0] thresh_trig_en;
   input [0:0] ext_trig_en;

assign bundle[0:0] = trig_et;
assign bundle[1:1] = trig_gt;
assign bundle[2:2] = trig_lt;
assign bundle[3:3] = trig_run;
assign bundle[4:4] = discr_trig_pol;
assign bundle[16:5] = trig_thresh;
assign bundle[17:17] = disc_trig_en;
assign bundle[18:18] = thresh_trig_en;
assign bundle[19:19] = ext_trig_en;


endmodule
