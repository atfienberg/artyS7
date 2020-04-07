// Aaron Fienberg
// April 2020
//
// Top level module for a Digilent Arty S7 project

module top(
	input OSC_12MHZ,
	output[3:0] GREEN_LED,
	output[5:0] TRICOLOR_LED,
	// USB UART signals
	output UART_RXD,
	input UART_TXD
	);

localparam[15:0] FW_VNUM = 16'h1;

//
// 100 MHz logic clock generation
//

wire lclk;
wire lclk_mmcm_locked;
LCLK_MMCM lclk_mmcm_0
(
  .clk_100MHZ(lclk),
  .reset(1'b0),
  .locked(lclk_mmcm_locked),
  .clk_in1(OSC_12MHZ)
);
wire lclk_rst = !lclk_mmcm_locked;


/////////////////////////////////////////////////////////////////////////
// xDOM interface
// Addressing:
//     12'hfff: Version/build number
//     12'8ff: LED toggle
//             [0] configurable RGB LED toggle
//             [1] color cycling RGB LED toggle
//             [2] knight rider (green) LED toggle
//     12'8fe: RGB red intensity [14:0]
//     12'8fd: RGB green intensity [14:0]
//     12'8fc: RGB blue intensity [14:0]
//     12'8fb: RGB color cycle speed select [1:0]
//     12'8fa: knight rider speed select [1:0] 

// LED control signals
wire[2:0] led_toggle_xdom;
wire[14:0] red_led_lvl_xdom;
wire[14:0] green_led_lvl_xdom;
wire[14:0] blue_led_lvl_xdom;
wire[1:0]  rgb_cycle_speed_sel_xdom;
wire[1:0]  kr_speed_sel_xdom;

xdom XDOM_0
(
  .clk(lclk),
  .rst(lclk_rst),
  .vnum(FW_VNUM),
  // LED controls
  .led_toggle(led_toggle_xdom),
  .red_led_lvl(red_led_lvl_xdom),
  .green_led_lvl(green_led_lvl_xdom),
  .blue_led_lvl(blue_led_lvl_xdom),
  .rgb_cycle_speed_sel(rgb_cycle_speed_sel_xdom),
  .kr_speed_sel(kr_speed_sel_xdom),
  // debug UART
  .debug_txd(UART_TXD),
  .debug_rxd(UART_RXD),
  .debug_rts_n(1'b0),
  .debug_cts_n()
);

//
// LED controls
//

wire[2:0] led_toggle = led_toggle_xdom;

// Output fixed color for the first RGB LED 

wire[14:0] red_led_lvl_0 = red_led_lvl_xdom;
wire[14:0] green_led_lvl_0 = green_led_lvl_xdom;
wire[14:0] blue_led_lvl_0 = blue_led_lvl_xdom;

wire[2:0] rgb_0_out;
assign TRICOLOR_LED[2:0] = rgb_0_out & {3{led_toggle[0]}};

rgb_led_ctrl rgb_0
(
  .clk(lclk),
  .rst(lck_rst),
  .red(red_led_lvl_0),
  .green(green_led_lvl_0),
  .blue(blue_led_lvl_0),
  .rgb_out(rgb_0_out)
);

// Output changing colors for the second RGB LED

wire[14:0] red_led_lvl_1;
wire[14:0] green_led_lvl_1;
wire[14:0] blue_led_lvl_1;

wire[2:0] rgb_1_out;
assign TRICOLOR_LED[5:3] = rgb_1_out & {3{led_toggle[1]}};

rgb_led_ctrl rgb_1
(
  .clk(lclk),
  .rst(lck_rst),
  .red(red_led_lvl_1),
  .green(green_led_lvl_1),
  .blue(blue_led_lvl_1),
  .rgb_out(rgb_1_out)
);

light_show rgb_lightshow_0 (
  .clk(lclk),
  .rst(lclk_rst),
  .period_sel(rgb_cycle_speed_sel_xdom),
  .red(red_led_lvl_1),
  .green(green_led_lvl_1),
  .blue(blue_led_lvl_1)
);

// display knight rider pattern on the four green LEDs

wire[3:0] led_kr_out; 
assign GREEN_LED = led_kr_out & {4{led_toggle[2]}};
knight_rider led_kr 
(
  .clk(lclk),
  .rst(lclk_rst),
  .period_sel(kr_speed_sel_xdom),
  .y(led_kr_out)
);

endmodule