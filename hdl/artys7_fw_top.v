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
`include "mDOM_trig_bundle_inc.v"
`include "mDOM_wvb_conf_bundle_inc.v"

localparam[15:0] FW_VNUM = 16'h5;

// number of fake ADC channels
localparam N_CHANNELS = 8;

//
// 125 MHz logic clock generation
//

wire lclk;
wire lclk_mmcm_locked;
LCLK_MMCM lclk_mmcm_0
(
  .clk_125MHZ(lclk),
  .reset(1'b0),
  .locked(lclk_mmcm_locked),
  .clk_in1(OSC_12MHZ)
);
wire lclk_rst = !lclk_mmcm_locked;

/////////////////////////////////////////////////////////////////////////
// xDOM interface
// Addressing:
//     12'hfff: Version/build number
//     12'hffe: trig settings
//             [0] et
//             [1] gt
//             [2] lt
//             [3] discr_trig_pol
//             [4] dicr_trig_en
//             [5] thresh_trig_en
//             [6] ext_trig_en
//     12'hffd: trig threshold [11:0]
//     12'hffc: 
//             [i] sw_trig (channel i)
//     12'hffb: 
//             [0] trig_mode
//     12'hffa: 
//             [i] trig_arm (channel i)
//     12'hff9: 
//             [i] trig_armed (channel i)
//     12'hff8:
//             [0] cnst_run
//     12'hff7: const config [11:0]
//     12'hff6: test config  [11:0]
//     12'hff5: post config [7:0] 
//     12'hff4: pre config [4:0]
//     12'heff: dpram_len [10:0]
//     12'hefe: 
//             [0] dpram_done  
//     12'hefd: 
//             [0] dpram_sel (0: scratch dpram, 1: direct rdout (rd only))       
//     12'hefc: n_waveforms in waveform buffer
//     12'hefb: words used in waveform buffer
//     12'hefa: waveform buffer overflow
//     12'hef9: waveform buffer reset 
//     12'hef8: wvb_reader enable 
//     12'hef7: wvb_reader dpram mode 
//     12'hef6: wvb header full ([i] for channel i)
//     12'hef5: chan select for waveform buffer n_words/n_wfms
//              (efa and ef9)
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

// trigger/wvb conf
wire[L_WIDTH_MDOM_TRIG_BUNDLE-1:0] xdom_trig_bundle;
wire[L_WIDTH_MDOM_WVB_CONF_BUNDLE-1:0] xdom_wvb_conf_bundle;
wire[15:0] xdom_wvb_rst;
wire[15:0] xdom_arm;
wire[15:0] xdom_trig_run;

// waveform buffer status
wire[15:0] wvb_armed;
wire[15:0] wvb_overflow;
wire[N_CHANNELS*16-1:0] wfms_in_buf;
wire[N_CHANNELS*16-1:0] buf_wds_used;
wire[15:0] wvb_hdr_full;

// wvb reader
wire[15:0] rdout_dpram_len;
wire rdout_dpram_run;
wire rdout_dpram_busy;
wire rdout_dpram_wren;
wire[9:0] rdout_dpram_wr_addr;
wire[31:0] rdout_dpram_data;
wire wvb_reader_enable;
wire wvb_reader_dpram_mode;

xdom #(.N_CHANNELS(N_CHANNELS)) XDOM_0
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

  // trigger/wvb conf
  .xdom_trig_bundle(xdom_trig_bundle),
  .xdom_wvb_conf_bundle(xdom_wvb_conf_bundle),
  .xdom_wvb_arm(xdom_arm),
  .xdom_trig_run(xdom_trig_run),
  .wvb_rst(xdom_wvb_rst),

  // waveform buffer status
  .wvb_armed(wvb_armed),
  .wvb_overflow(wvb_overflow),
  .wfms_in_buf(wfms_in_buf),
  .buf_wds_used(buf_wds_used),
  .wvb_hdr_full(wvb_hdr_full),

  // wvb reader
  .dpram_len_in(rdout_dpram_len),
  .rdout_dpram_run(rdout_dpram_run),
  .dpram_busy(rdout_dpram_busy),
  .rdout_dpram_wren(rdout_dpram_wren),
  .rdout_dpram_wr_addr(rdout_dpram_wr_addr),
  .rdout_dpram_data(rdout_dpram_data),
  .wvb_reader_enable(wvb_reader_enable),
  .wvb_reader_dpram_mode(wvb_reader_dpram_mode),

  // debug UART
  .debug_txd(UART_TXD),
  .debug_rxd(UART_RXD),
  .debug_rts_n(1'b0),
  .debug_cts_n()
);

//
// LTC counter
//
reg[47:0] ltc = 0;
always @(posedge lclk) begin
  if (lclk_rst) begin
    ltc <= 0;
  end

  else begin
    ltc <= ltc + 1;
  end
end

//
// Waveform acquisition modules
// for the Arty S7 test, 
// these module generate a ramp pattern internally
// 
// configuration currently shared between all channels

wire[N_CHANNELS-1:0] wvb_hdr_empty;
wire[N_CHANNELS-1:0] wvb_hdr_rdreq;
wire[N_CHANNELS-1:0] wvb_wvb_rdreq;
wire[N_CHANNELS-1:0] wvb_rddone;
wire[N_CHANNELS*22-1:0] wvb_data_out;
wire[N_CHANNELS*80-1:0] wvb_hdr_data;

generate
  genvar i;

  for (i = 0; i < N_CHANNELS; i = i + 1) begin : waveform_acq_gen
    // distinguish channels by discr-adc diff
    waveform_acquisition #(.P_DISCR_RAMP_START(i)) WFM_ACQ
    (
      .clk(lclk),
      .rst(lclk_rst || xdom_wvb_rst[i]),
      
      // WVB reader interface
      .wvb_data_out(wvb_data_out[22*(i+1)-1:22*i]),
      .wvb_hdr_data_out(wvb_hdr_data[80*(i+1)-1:80*i]),  
      .wvb_hdr_full(wvb_hdr_full[i]),
      .wvb_hdr_empty(wvb_hdr_empty[i]),
      .wvb_n_wvf_in_buf(wfms_in_buf[16*(i+1)-1:16*i]),
      .wvb_wused(buf_wds_used[16*(i+1)-1:16*i]), 
      .wvb_hdr_rdreq(wvb_hdr_rdreq[i]), 
      .wvb_wvb_rdreq(wvb_wvb_rdreq[i]), 
      .wvb_wvb_rddone(wvb_rddone[i]), 
      
      // Local time counter
      .ltc_in(ltc), 
      
      // External
      .ext_trig_in(1'b0),
      .wvb_trig_out(),
      .wvb_trig_test_out(),
    
      // XDOM interface
      .xdom_arm(xdom_arm[i]),
      .xdom_trig_run(xdom_trig_run[i]),
      .xdom_wvb_trig_bundle(xdom_trig_bundle),
      .xdom_wvb_config_bundle(xdom_wvb_conf_bundle),  
      .xdom_wvb_armed(wvb_armed[i]), 
      .xdom_wvb_overflow(wvb_overflow[i])
    );
  end
endgenerate


//
// Waveform buffer reader
// 

wvb_reader #(.N_CHANNELS(N_CHANNELS)) WVB_READER 
(
  .clk(lclk),
  .rst(lclk_rst),
  .en(wvb_reader_enable),

  // dpram interface 
  .dpram_data(rdout_dpram_data),
  .dpram_addr(rdout_dpram_wr_addr),
  .dpram_wren(rdout_dpram_wren),
  .dpram_len(rdout_dpram_len),
  .dpram_run(rdout_dpram_run),
  .dpram_busy(rdout_dpram_busy),
  .dpram_mode(wvb_reader_dpram_mode),

  // wvb interface
  .hdr_rdreq(wvb_hdr_rdreq),
  .wvb_rdreq(wvb_wvb_rdreq),
  .wvb_rddone(wvb_rddone),
  .wvb_data(wvb_data_out),
  .hdr_data(wvb_hdr_data),
  .hdr_empty(wvb_hdr_empty)
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