// Aaron Fienberg
//
// Test bench for the DDR3 pg transfer logic
//

`timescale 1ns/1ns

module ddr3_pg_transfer_tb();

parameter CLK_PERIOD = 10;
reg clk;
reg rst;
initial begin
  // clock initialization        
  clk = 1'b0;    
  rst = 1'b1;
end

// clock driver
always @(clk)
  #(CLK_PERIOD / 2.0) clk <= !clk;

// DDR3 pg dpram
reg xdom_wren = 0; 
reg[10:0] xdom_addr = 0;
reg[15:0] xdom_din = 0;
wire[15:0] xdom_dout;  
wire ddr3_dpram_wren;
wire[7:0] ddr3_dpram_addr;
wire[127:0] ddr3_dpram_din;
wire[127:0] ddr3_dpram_dout;
XDOM_DDR3_PG PG_DPRAM
(
  .clka(clk),
  .wea(xdom_wren),
  .addra(xdom_addr),
  .dina(xdom_din),
  .douta(xdom_dout),
  .clkb(clk),
  .web(ddr3_dpram_wren),
  .addrb(ddr3_dpram_addr),
  .dinb(ddr3_dpram_din),
  .doutb(ddr3_dpram_dout)
);

// fake memory interface UI handshake signals
reg app_rdy = 1;
reg app_wdf_rdy = 1;
reg app_rd_data_valid = 0;

// memory interface inputs
wire[27:0] app_addr;
wire app_en;
wire[127:0] app_wdf_data;
reg[127:0] app_rd_data = 0;
wire app_wdf_wren;
wire app_wdf_end;
wire[2:0] app_cmd;

reg pg_req = 0;
wire pg_ack;
reg pg_optype = OPREAD;
reg[27:0] pg_req_addr;

// instantiate pg_transfer_ctrl
DDR3_pg_transfer_ctrl PG_TRANS_CTRL
(
  .clk(clk),
  .rst(rst),

  .pg_req(pg_req),
  .pg_optype(pg_optype),
  .pg_req_addr(pg_req_addr),
  .pg_ack(pg_ack),

  .app_rdy(app_rdy),
  .app_wdf_rdy(app_wdf_rdy),
  .app_rd_data_valid(app_rd_data_valid),
  .app_rd_data(app_rd_data),

  .dpram_dout(ddr3_dpram_dout),

  .app_addr(app_addr),
  .app_en(app_en),
  .app_wdf_data(app_wdf_data),
  .app_wdf_wren(app_wdf_wren),
  .app_wdf_end(app_wdf_end),
  .app_cmd(app_cmd),

  .dpram_din(ddr3_dpram_din),
  .dpram_addr(ddr3_dpram_addr),
  .dpram_wren(ddr3_dpram_wren)
);

// test control signals
localparam OPREAD = 0,
           OPWRITE = 1;           
reg xdom_fill_dpram = 0;

reg [47:0] ltc = 0;
always @(posedge clk) begin
  ltc <= ltc + 1;

  xdom_fill_dpram <= 0;

  if (ltc == 4) begin
    rst <= 0;
  end

  if (ltc == 9) begin
    xdom_fill_dpram <= 1;
    xdom_addr <= -1;
  end

  if (ltc == 5000) begin
    pg_optype <= OPWRITE;
    pg_req <= 1;
    pg_req_addr <= 0;
  end

  if (pg_req && pg_ack) begin
    pg_req <= 0;
  end

  // drop app_wdf_rdy for 10 cycles at 5050
  if (ltc == 5049) begin
    app_wdf_rdy <= 0;
  end

  if (ltc == 5059) begin
    app_wdf_rdy <= 1;
  end

  // drop for one more cycle at 5064
  if (ltc == 5063) begin
    app_wdf_rdy <= 0;
  end

  if (ltc == 5064) begin
    app_wdf_rdy <= 1;
  end

  // drop app_rdy for 10 cyces at ltc == 5100
  if (ltc == 5099) begin
    app_rdy <= 0;
  end

  if (ltc == 5109) begin
    app_rdy <= 1;
  end

  // test condition where final write fifo req is initially rejected
  if (ltc == 5278) begin
    app_wdf_rdy <= 0;
  end

  if (ltc == 5291) begin
    app_wdf_rdy <= 1;
  end

  // send pg rd req
  if (ltc == 5304) begin
    pg_req <= 1;
    pg_optype <= OPREAD;
  end

  // drop app_rdy for a few clock cycles
  if (ltc == 5544) begin
    app_rdy <= 0;
  end

  if (ltc == 5549) begin
    app_rdy <= 1;
  end

  // check an xdom value to see if the data was written back correctly
  if (ltc == 5599) begin
    xdom_addr <= 1974;
  end
end

// fill DPRAM from xdom side 
reg xdom_writing = 0;
always @(posedge clk) begin
  xdom_wren <= 0;

  if (xdom_fill_dpram) begin
    xdom_writing <= 1;
    xdom_wren <= 1;
    xdom_addr <= xdom_addr + 1;
  end

  if (xdom_writing) begin
    xdom_wren <= 1;
    xdom_din <= xdom_din + 1;
    xdom_addr <= xdom_addr + 1;
    if (xdom_addr == 2047) begin
      xdom_writing <= 0;
      xdom_wren <= 0;
    end
  end
end

// break 128 bit write data into 16 bit words
wire[15:0] ddr3_write_words[0:7];
assign ddr3_write_words[0] = app_wdf_data[15:0]; 
assign ddr3_write_words[1] = app_wdf_data[31:16]; 
assign ddr3_write_words[2] = app_wdf_data[47:32]; 
assign ddr3_write_words[3] = app_wdf_data[63:48]; 
assign ddr3_write_words[4] = app_wdf_data[79:64]; 
assign ddr3_write_words[5] = app_wdf_data[95:80]; 
assign ddr3_write_words[6] = app_wdf_data[111:96]; 
assign ddr3_write_words[7] = app_wdf_data[127:112]; 

//
// need to simulate reading as well; use another DDR3_XDOM_PG dpram to simulate the DDR3 memory
//
wire fake_ddr3_wren = app_wdf_wren && app_wdf_rdy && app_wdf_end;
wire fake_ddr3_rdreq = app_en && (app_cmd == 1'b1) && (app_rdy);
reg[7:0] fake_ddr3_addr = 0;

wire[7:0] trunc_app_addr = app_addr >> 4;

always @(posedge clk) begin
  // advance the addr whenever there is a successful write or read
  if (fake_ddr3_wren) begin
    fake_ddr3_addr <= fake_ddr3_addr + 1;
  end

  else if (fake_ddr3_rdreq) begin
    fake_ddr3_addr <= trunc_app_addr;
  end
end

wire[127:0] fake_ddr3_dout;

XDOM_DDR3_PG FAKE_DDR3
(
  .clka(clk),
  .wea(),
  .addra(),
  .dina(),
  .douta(),
  .clkb(clk),
  .web(fake_ddr3_wren),
  .addrb(fake_ddr3_addr),
  .dinb(app_wdf_data),
  .doutb(fake_ddr3_dout)
);

// simulate UI presenting DDR3 data
reg[2:0] rd_req_pline = 0;
always @(posedge clk) begin
  rd_req_pline <= {rd_req_pline[1:0], fake_ddr3_rdreq};

  app_rd_data_valid <= 0;
  if (rd_req_pline[2]) begin
    app_rd_data_valid <= 1;
    app_rd_data <= fake_ddr3_dout;
  end
end 

endmodule