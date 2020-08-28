// Aaron Fienberg
// Aug 2020
//
// Transfers data between FPGA DPRAMs and DDR3 memory pages
//

module DDR3_DPRAM_transfer
(
	// signals for the memory interface
	inout [15:0]ddr3_dq,
  inout [1:0]ddr3_dqs_n,
  inout [1:0]ddr3_dqs_p,
  output [13:0]ddr3_addr,
  output [2:0]ddr3_ba,
  output ddr3_ras_n,
  output ddr3_cas_n,
  output ddr3_we_n,
  output ddr3_reset_n,
  output [0:0]ddr3_ck_p,
  output [0:0]ddr3_ck_n,
  output [0:0]ddr3_cke,
  output [0:0]ddr3_cs_n,
  output [1:0]ddr3_dm,
  output [0:0]ddr3_odt,
  input sys_clk_i,
  input clk_ref_i,
  
  output ui_clk,

  // XDOM interface
  input sys_rst,
  input pg_req,
  input pg_optype,
  input[27:0] pg_req_addr,
  
  output pg_ack,
  output init_calib_complete,
  output ui_clk_sync_rst,
  output[11:0] device_temp,

  // DPRAM interface
  input[127:0] dpram_dout,

  output[127:0] dpram_din,
  output[7:0] dpram_addr,
  output dpram_wren
);

// page transfer controller
// synchronize req into ui_clk domain
wire pg_req_s;
sync REQSYNC(.clk(ui_clk), .rst_n(!ui_clk_sync_rst), .a(pg_req), .y(pg_req_s));

wire app_rdy;
wire app_wdf_rdy;
wire app_rd_data_valid;
wire[127:0] app_rd_data;
wire[27:0] app_addr;
wire app_en;
wire[127:0] app_wdf_data;
wire app_wdf_wren;
wire app_wdf_end;
wire[2:0] app_cmd;
DDR3_pg_transfer_ctrl PG_TRANS_CTRL
(
  .clk(ui_clk),
  .rst(ui_clk_sync_rst),

  .pg_req(pg_req_s),
  .pg_optype(pg_optype),
  .pg_req_addr(pg_req_addr),
  .pg_ack(pg_ack),

  .app_rdy(app_rdy),
  .app_wdf_rdy(app_wdf_rdy),
  .app_rd_data_valid(app_rd_data_valid),
  .app_rd_data(app_rd_data),

  .dpram_dout(dpram_dout),

  .app_addr(app_addr),
  .app_en(app_en),
  .app_wdf_data(app_wdf_data),
  .app_wdf_wren(app_wdf_wren),
  .app_wdf_end(app_wdf_end),
  .app_cmd(app_cmd),

  .dpram_din(dpram_din),
  .dpram_addr(dpram_addr),
  .dpram_wren(dpram_wren)
);

//
// instantiate the memory interface / memory controller
//

// unused outputs
wire app_rd_data_end;
wire app_sr_active;
wire app_ref_ack;
wire app_zq_ack;

mig_7series_0 MIG_7_SERIES
(
 	// active low sys rst
 	.sys_rst(sys_rst),

  // DDR3 chip interface
  .ddr3_addr(ddr3_addr),
  .ddr3_ba(ddr3_ba),
  .ddr3_cas_n(ddr3_cas_n),
  .ddr3_ck_n(ddr3_ck_n),
  .ddr3_ck_p(ddr3_ck_p),
  .ddr3_cke(ddr3_cke),
  .ddr3_ras_n(ddr3_ras_n),
  .ddr3_we_n(ddr3_we_n),
  .ddr3_dq(ddr3_dq),
  .ddr3_dqs_n(ddr3_dqs_n),
  .ddr3_dqs_p(ddr3_dqs_p),
  .ddr3_reset_n(ddr3_reset_n),
  .ddr3_cs_n(ddr3_cs_n),
  .ddr3_dm(ddr3_dm),
  .ddr3_odt(ddr3_odt),
 
 	// status signals
  .init_calib_complete(init_calib_complete),
  .device_temp(device_temp), 

  // UI interface
  .app_addr(app_addr),
  .app_cmd(app_cmd),
  .app_en(app_en),
  .app_wdf_data(app_wdf_data),
  .app_wdf_end(app_wdf_end),
  .app_wdf_wren(app_wdf_wren),
  .app_rd_data(app_rd_data),
  .app_rd_data_end(app_rd_data_end),
  .app_rd_data_valid(app_rd_data_valid),
  .app_rdy(app_rdy),
  .app_wdf_rdy(app_wdf_rdy),
  .app_sr_req(1'b0),
  .app_ref_req(1'b0),
  .app_zq_req(1'b0),
  .app_sr_active(app_sr_active),
  .app_ref_ack(app_ref_ack),
  .app_zq_ack(app_zq_ack),
  .app_wdf_mask(16'b0),

  // ui clock and rst
  .ui_clk(ui_clk),
  .ui_clk_sync_rst(ui_clk_sync_rst),

  // input clocks
  .sys_clk_i(sys_clk_i), // 100 MHz
  .clk_ref_i(clk_ref_i)  // 200 MHz
);

endmodule