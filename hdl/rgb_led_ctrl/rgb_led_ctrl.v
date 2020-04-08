// Aaron Fienberg
// April 2020
//
// Takes rgb brightness settings and 
// outputs signals to drive rgb LEDs
//


module rgb_led_ctrl
(
  input clk,
  input rst,
  input[14:0] red,
  input[14:0] green,
  input[14:0] blue,
  output[2:0] rgb_out
);

pwm red_0
(
  .clk(clk),
  .rst(rst),
  .n_high(red),
  .y(rgb_out[2])
);

pwm green_0
(
  .clk(clk),
  .rst(rst),
  .n_high(green),
  .y(rgb_out[1])
);

pwm blue_0
(
  .clk(clk),
  .rst(rst),
  .n_high(blue),
  .y(rgb_out[0])
);

endmodule