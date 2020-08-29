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
	input UART_TXD,

  // signals for the DDR3 memory interface
  inout[15:0] ddr3_dq,
  inout[1:0] ddr3_dqs_n,
  inout[1:0] ddr3_dqs_p,
  output[13:0] ddr3_addr,
  output[2:0] ddr3_ba,
  output ddr3_ras_n,
  output ddr3_cas_n,
  output ddr3_we_n,
  output ddr3_reset_n,
  output[0:0] ddr3_ck_p,
  output[0:0] ddr3_ck_n,
  output[0:0] ddr3_cke,
  output[0:0] ddr3_cs_n,
  output[1:0] ddr3_dm,
  output[0:0] ddr3_odt,
  input sys_clk_i
	);
`include "mDOM_trig_bundle_inc.v"
`include "mDOM_wvb_conf_bundle_inc.v"

localparam[15:0] FW_VNUM = 16'h10;

// number of fake ADC channels
localparam N_CHANNELS = 24;

// determines waveform buffer depths
// can get to 16 channels with adr widths of 11 or 12, 
// but need to decrease width to 10 to reach 24 channels
// on the xc7s50 
// deeper buffers will be possible on the xc7s100
localparam P_WVB_ADR_WIDTH = 10;

localparam P_HDR_WIDTH = P_WVB_ADR_WIDTH == 10 ? 71 : 80;

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

//
// 200 MHz ref clock generation
//

wire ref_clk;
wire ref_clk_mmcm_locked;
REFCLK_MMCM refclk_mmcm_0
(
  .clk_200MHZ(ref_clk),
  .reset(1'b0),
  .locked(ref_clk_mmcm_locked),
  .clk_in1(OSC_12MHZ)
);

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
//             [i] sw_trig (channel i, up to 15)
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
//             [0] dpram_sel (0: ddr3 transfer dpram, 1: direct rdout (rd only))       
//     12'hefc: n_waveforms in waveform buffer
//     12'hefb: words used in waveform buffer
//     12'hefa: waveform buffer overflow [15:0]
//     12'hef9: waveform buffer reset [15:0]
//     12'hef8: wvb_reader enable 
//     12'hef7: wvb_reader dpram mode 
//     12'hef6: wvb header full ([i] for channel i, up to 15)
//     12'hef5: chan select for waveform buffer n_words/n_wfms
//              (efa and ef9)
//     12'hef4: sw_trig[23:16]
//     12'hef3: trig_arm[23:16]
//     12'hef2: trig_armed[23:16]
//     12'hef1: waveform buffer overflow [23:16]
//     12'hef0: waveform buffer reset [23:16]
//     12'heef: wvb header full [23:16]
//      
//     DDR3 test signals
//     12'hdff: page transfer addr[27:16]
//     12'hdfe: page transger addr[15:0]
//     12'hdfd: [0] pg transfer optype (0 read, 1 write)
//     12'hdfc: [0] pg transfer task reg 
//     12'hdfb: DDR3 sys rst (active low)
//     12'hdfa: DDR3 cal complete
//     12'hdf9: [11:0] mem interface device temp
//     12'hdf8: [0] ddr3 ui sync rst
//
//     hit buffer controller
//     12'hcff: [0] enable
//     12'hcfe: [15:0] start_pg
//     12'hcfd: [15:0] stop_pg
//     12'hcfc: [15:0] first_pg (readback)
//     12'hcfb: [15:0] last_pg (readback)
//     12'hcfa: [15:0] pg_clr_count
//     12'hcf9: [0] flush_task
//              [1] pg_clr_task
//     12'hcf8: [15:0] rd_pg_num
//     12'hcf7: [15:0] wr_pg_num
//     12'hcf6: [15:0] n_used_pgs
//     12'hcf5: [0] empty
//              [1] full
//              [2] buffered_data
//
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
wire[N_CHANNELS-1:0] xdom_wvb_rst;
wire[N_CHANNELS-1:0] xdom_arm;
wire[N_CHANNELS-1:0] xdom_trig_run;

// waveform buffer status
wire[N_CHANNELS-1:0] wvb_armed;
wire[N_CHANNELS-1:0] wvb_overflow;
wire[N_CHANNELS*16-1:0] wfms_in_buf;
wire[N_CHANNELS*16-1:0] buf_wds_used;
wire[N_CHANNELS-1:0] wvb_hdr_full;

// wvb reader
wire[15:0] rdout_dpram_len;
wire rdout_dpram_run;
wire xdom_rdout_dpram_busy;
wire rdout_dpram_wren;
wire[9:0] rdout_dpram_wr_addr;
wire[31:0] rdout_dpram_data;
wire wvb_reader_enable;
wire wvb_reader_dpram_mode;

// DDR3 interface
wire ddr3_ui_clk;
wire[27:0] xdom_pg_req_addr;
wire xdom_pg_optype;
wire xdom_pg_req;
wire xdom_pg_ack;
wire ddr3_sys_rst;
wire ddr3_cal_complete;
wire ddr3_ui_sync_rst;
wire[11:0] ddr3_device_temp;
wire[7:0] ddr3_dpram_addr;
wire xdom_ddr3_dpram_wren;
wire[127:0] ddr3_dpram_din;
wire[127:0] xdom_ddr3_dpram_dout;

// hit buffer controller
wire hbuf_enable;
wire[15:0] hbuf_start_pg;
wire[15:0] hbuf_stop_pg;
wire[15:0] hbuf_first_pg;
wire[15:0] hbuf_last_pg;
wire[15:0] hbuf_pg_clr_count;
wire hbuf_pg_clr_req;
wire hbuf_pg_clr_ack;
wire hbuf_flush_req;
wire hbuf_flush_ack;
wire[15:0] hbuf_rd_pg_num;
wire[15:0] hbuf_wr_pg_num;
wire[15:0] hbuf_n_used_pgs;
wire hbuf_empty;
wire hbuf_full;
wire hbuf_buffered_data;

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
  .rdout_dpram_run(rdout_dpram_run && !hbuf_enable),
  .dpram_busy(xdom_rdout_dpram_busy),
  .rdout_dpram_wren(rdout_dpram_wren && !hbuf_enable),
  .rdout_dpram_wr_addr(rdout_dpram_wr_addr),
  .rdout_dpram_data(rdout_dpram_data),
  .wvb_reader_enable(wvb_reader_enable),
  .wvb_reader_dpram_mode(wvb_reader_dpram_mode),

  // DDR3 interface
  .ddr3_ui_clk(ddr3_ui_clk),
  .pg_req_addr(xdom_pg_req_addr),
  .pg_optype(xdom_pg_optype),
  .pg_req(xdom_pg_req),
  .pg_ack(xdom_pg_ack),
  .ddr3_sys_rst(ddr3_sys_rst),
  .ddr3_cal_complete(ddr3_cal_complete),
  .ddr3_ui_sync_rst(ddr3_ui_sync_rst),
  .ddr3_device_temp(ddr3_device_temp),
  .ddr3_dpram_addr(ddr3_dpram_addr),
  .ddr3_dpram_wren(xdom_ddr3_dpram_wren),
  .ddr3_dpram_din(ddr3_dpram_din),
  .ddr3_dpram_dout(xdom_ddr3_dpram_dout),

  // hit buffer controller
  .hbuf_enable(hbuf_enable),
  .hbuf_start_pg(hbuf_start_pg),
  .hbuf_stop_pg(hbuf_stop_pg),
  .hbuf_first_pg(hbuf_first_pg),
  .hbuf_last_pg(hbuf_last_pg),
  .hbuf_pg_clr_count(hbuf_pg_clr_count),
  .hbuf_pg_clr_req(hbuf_pg_clr_req),
  .hbuf_pg_clr_ack(hbuf_pg_clr_ack),
  .hbuf_flush_req(hbuf_flush_req),
  .hbuf_flush_ack(hbuf_flush_ack),
  .hbuf_rd_pg_num(hbuf_rd_pg_num),
  .hbuf_wr_pg_num(hbuf_wr_pg_num),
  .hbuf_n_used_pgs(hbuf_n_used_pgs),
  .hbuf_empty(hbuf_empty),
  .hbuf_full(hbuf_full),
  .hbuf_buffered_data(hbuf_buffered_data),

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
wire[N_CHANNELS*P_HDR_WIDTH-1:0] wvb_hdr_data;

// register the xdom trigger/wvb configuration
(* max_fanout = 5 *) reg[L_WIDTH_MDOM_TRIG_BUNDLE-1:0] xdom_trig_bundle_reg;
(* max_fanout = 5 *) reg[L_WIDTH_MDOM_WVB_CONF_BUNDLE-1:0] xdom_wvb_conf_bundle_reg;
always @(posedge lclk) begin
  xdom_trig_bundle_reg <= xdom_trig_bundle;
  xdom_wvb_conf_bundle_reg <= xdom_wvb_conf_bundle;
end

generate
  genvar i;

  for (i = 0; i < N_CHANNELS; i = i + 1) begin : waveform_acq_gen
    // distinguish channels by discr-adc diff
    waveform_acquisition #(.P_DISCR_RAMP_START(i),
                           .P_ADR_WIDTH(P_WVB_ADR_WIDTH),
                           .P_HDR_WIDTH(P_HDR_WIDTH)) 
    WFM_ACQ
    (
      .clk(lclk),
      .rst(lclk_rst || xdom_wvb_rst[i]),
      
      // WVB reader interface
      .wvb_data_out(wvb_data_out[22*(i+1)-1:22*i]),
      .wvb_hdr_data_out(wvb_hdr_data[P_HDR_WIDTH*(i+1)-1:P_HDR_WIDTH*i]),  
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
      .xdom_wvb_trig_bundle(xdom_trig_bundle_reg),
      .xdom_wvb_config_bundle(xdom_wvb_conf_bundle_reg),  
      .xdom_wvb_armed(wvb_armed[i]), 
      .xdom_wvb_overflow(wvb_overflow[i])
    );
  end
endgenerate

//
// hit buffer controller
//
wire hbuf_dpram_busy;
wire[127:0] hbuf_dpram_dout;
wire[7:0] hbuf_dpram_addr;
wire hbuf_pg_req;
wire hbuf_pg_ack;
wire hbuf_pg_optype;
wire[27:0] hbuf_pg_req_addr;

hbuf_ctrl HBUF_CTRL_0
(
 .clk(lclk),
 .rst(lclk_rst),
 .en(hbuf_enable),

 .start_pg(hbuf_start_pg),
 .stop_pg(hbuf_stop_pg),
 .first_pg(hbuf_first_pg),
 .last_pg(hbuf_last_pg),

 .flush_req(hbuf_flush_req),
 .flush_ack(hbuf_flush_ack),

 .empty(hbuf_empty),
 .full(hbuf_full),
 .rd_pg_num(hbuf_rd_pg_num),
 .wr_pg_num(hbuf_wr_pg_num),
 .n_used_pgs(hbuf_n_used_pgs),
 
 .pg_clr_cnt(hbuf_pg_clr_count),
 .pg_clr_req(hbuf_pg_clr_req),
 .pg_clr_ack(hbuf_pg_clr_ack),
 
 .buffered_data(hbuf_buffered_data),
 
 .dpram_len_in(rdout_dpram_len),
 .rdout_dpram_run(rdout_dpram_run && hbuf_enable),
 .dpram_busy(hbuf_dpram_busy),
 .rdout_dpram_wren(rdout_dpram_wren && hbuf_enable),

 .rdout_dpram_wr_addr(rdout_dpram_wr_addr),
 .rdout_dpram_data(rdout_dpram_data),
 
 .ddr3_ui_clk(ddr3_ui_clk),
 .ddr3_dpram_dout(hbuf_dpram_dout),
 .ddr3_dpram_rd_addr(ddr3_dpram_addr),

 .pg_ack(hbuf_pg_ack),
 .pg_req(hbuf_pg_req),
 .pg_optype(hbuf_pg_optype),
 .pg_addr(hbuf_pg_req_addr)
);

//
// Waveform buffer reader
// 

wire rdout_dpram_busy = hbuf_enable ? hbuf_dpram_busy : xdom_rdout_dpram_busy;

wvb_reader #(.N_CHANNELS(N_CHANNELS),
             .P_WVB_ADR_WIDTH(P_WVB_ADR_WIDTH),
             .P_HDR_WIDTH(P_HDR_WIDTH))
WVB_READER 
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
// DDR3 pg transfer mux
// runs in DDR3 UI clock domain
//

wire ddr3_pg_req;
wire ddr3_pg_optype;
wire ddr3_pg_ack;
wire[27:0] ddr3_pg_req_addr;
wire[127:0] ddr3_dpram_dout;
wire ddr3_dpram_wren;

DDR3_pg_transfer_mux DDR3_MUX
(
 .clk(ddr3_ui_clk),
 .rst(ddr3_ui_sync_rst),

 .hbuf_pg_req(hbuf_pg_req),
 .hbuf_pg_optype(hbuf_pg_optype),
 .hbuf_pg_ack(hbuf_pg_ack),
 .hbuf_pg_req_addr(hbuf_pg_req_addr),
 .hbuf_dpram_dout(hbuf_dpram_dout),

 .xdom_pg_req(xdom_pg_req),
 .xdom_pg_optype(xdom_pg_optype),
 .xdom_pg_ack(xdom_pg_ack),
 .xdom_pg_req_addr(xdom_pg_req_addr),
 .xdom_dpram_dout(xdom_ddr3_dpram_dout),
 .xdom_dpram_wren(xdom_ddr3_dpram_wren),

 .ddr3_pg_req(ddr3_pg_req),
 .ddr3_pg_optype(ddr3_pg_optype),
 .ddr3_pg_ack(ddr3_pg_ack),
 .ddr3_pg_req_addr(ddr3_pg_req_addr),
 .ddr3_dpram_dout(ddr3_dpram_dout),
 .ddr3_dpram_wren(ddr3_dpram_wren)
);

//
// DDR3 page transter
//

DDR3_DPRAM_transfer DDR3_TRANSFER_0 
(
 .ddr3_dq(ddr3_dq),
 .ddr3_dqs_n(ddr3_dqs_n),
 .ddr3_dqs_p(ddr3_dqs_p),
 .ddr3_addr(ddr3_addr),
 .ddr3_ba(ddr3_ba),
 .ddr3_ras_n(ddr3_ras_n),
 .ddr3_cas_n(ddr3_cas_n),
 .ddr3_we_n(ddr3_we_n),
 .ddr3_reset_n(ddr3_reset_n),
 .ddr3_ck_p(ddr3_ck_p),
 .ddr3_ck_n(ddr3_ck_n),
 .ddr3_cke(ddr3_cke),
 .ddr3_cs_n(ddr3_cs_n),
 .ddr3_dm(ddr3_dm),
 .ddr3_odt(ddr3_odt),
 .sys_clk_i(sys_clk_i),
 .clk_ref_i(ref_clk),

 .ui_clk(ddr3_ui_clk),

 .sys_rst(ddr3_sys_rst),
 
 .pg_req(ddr3_pg_req),
 .pg_optype(ddr3_pg_optype),
 .pg_req_addr(ddr3_pg_req_addr),
 .pg_ack(ddr3_pg_ack),

 .init_calib_complete(ddr3_cal_complete),
 .ui_clk_sync_rst(ddr3_ui_sync_rst),
 .device_temp(ddr3_device_temp),

 .dpram_dout(ddr3_dpram_dout),
 .dpram_din(ddr3_dpram_din),
 .dpram_addr(ddr3_dpram_addr),
 .dpram_wren(ddr3_dpram_wren)
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
  .rst(lclk_rst),
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
  .rst(lclk_rst),
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