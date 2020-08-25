// Aaron Fienberg
//
// Test bench for the DDR3 pg transfer logic
//

`timescale 1ns/1ns

module ddr3_pg_transfer_tb();

parameter CLK_PERIOD = 10;
reg clk;
initial begin
  // clock initialization        
  clk = 1'b0;    
end

// clock driver
always @(clk)
  #(CLK_PERIOD / 2.0) clk <= !clk;

// DDR3 pg dpram
reg xdom_wren = 0; 
reg[10:0] xdom_addr = 0;
reg[15:0] xdom_din = 0;
wire[15:0] xdom_dout;  
reg ddr3_dpram_wren = 0;
reg[7:0] ddr3_dpram_addr = -1;
reg[127:0] ddr3_dpram_din = 0;
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
reg[27:0] app_addr = 0;
reg app_en = 0;
reg[127:0] app_wdf_data = 0;
reg[127:0] app_rd_data = 0;
reg app_wdf_wren = 0;
reg app_wdf_end = 0;
reg[2:0] app_cmd = 0;
localparam APP_CMD_WRITE = 0,
           APP_CMD_RD = 1;

localparam DPRAM_RD_LATENCY = 2; 
localparam REQS_PER_PG = 256;
localparam N_APP_REQS_MAX = 255;
localparam N_DPRAM_OPS_MAX = 255;

// test control signals
localparam OPREAD = 0,
           OPWRITE = 1;           
reg xdom_fill_dpram = 0;
reg pg_req = 0;
reg pg_ack = 0;
reg pg_optype = OPREAD;
reg[27:0] pg_req_addr;

reg [47:0] ltc = 0;
always @(posedge clk) begin
  ltc <= ltc + 1;

  xdom_fill_dpram <= 0;

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

// DDR3 page transfer logic
// app FSM states
localparam S_IDLE = 0,
           S_WR_PG_BEGIN = 1,
           S_APP_REQ_WR = 2,
           S_RD_PG_BEGIN = 3,
           S_APP_REQ_RD = 4,
           S_DPRAM_FSM_CHECK = 5,
           S_ACK = 6;
reg[2:0] app_fsm = S_IDLE;

// dpram FSM states
localparam S_START_WR_STREAM = 1,
           S_WR_STREAM = 2,
           S_WR_HOLD = 3,
           S_RD_STREAM = 4;
reg[2:0] dpram_fsm = S_IDLE;

// app FSM
reg[31:0] n_app_reqs = 0;
reg[31:0] n_writes = 0;
reg dpram_start = 0;
reg i_optype = 0;
reg[27:0] next_app_addr = 0;
always @(posedge clk) begin
  dpram_start <= 0;
  app_en <= 0;

  case (app_fsm) 
    S_IDLE: begin
      next_app_addr <= 0;
      pg_ack <= 0;

      if (pg_req) begin
        i_optype <= pg_optype;
        next_app_addr <= pg_req_addr;

        if (pg_optype == OPREAD) begin
          app_fsm <= S_RD_PG_BEGIN; 
        end
        
        else if (pg_optype == OPWRITE) begin
          app_fsm <= S_WR_PG_BEGIN;  
        end
      end

      else begin
        app_fsm <= S_IDLE;
      end
    end

    S_WR_PG_BEGIN: begin
      dpram_start <= 1;
      n_app_reqs <= 0;

      if (n_writes >= 3) begin
        app_cmd = APP_CMD_WRITE;
        app_en <= 1;
        app_addr <= next_app_addr;
        // memory interface bursts 8 16-bit words at a time
        next_app_addr <= next_app_addr + 16; 
        
        app_fsm <= S_APP_REQ_WR;
      end
    end

    S_APP_REQ_WR: begin      
      app_cmd = APP_CMD_WRITE;

      // don't send app_en reqs if the DPRAM fsm has stalled
      if ((n_app_reqs + 1 < n_writes) || 
          (n_writes == REQS_PER_PG)) begin
        app_en <= 1;
      end

      if (app_rdy && app_en) begin
        // current command will be accepted
        app_addr <= next_app_addr;
        next_app_addr <= next_app_addr + 16;

        n_app_reqs <= n_app_reqs + 1;
        if (n_app_reqs == N_APP_REQS_MAX) begin
          app_en <= 0;        
          app_fsm <= S_DPRAM_FSM_CHECK;          
        end
    
      end
    
    end

    S_RD_PG_BEGIN: begin
      dpram_start <= 1;
      n_app_reqs <= 0;

      app_cmd = APP_CMD_RD;
      app_en <= 1;
      app_addr <= next_app_addr;
      next_app_addr <= next_app_addr + 16;

      app_fsm <= S_APP_REQ_RD;
    end

    S_APP_REQ_RD: begin
      app_cmd = APP_CMD_RD;

      app_en <= 1;
 
      if (app_rdy && app_en) begin
        // current command will be accepted
        app_addr <= next_app_addr;
        next_app_addr <= next_app_addr + 16;

        n_app_reqs <= n_app_reqs + 1;
        if (n_app_reqs == N_APP_REQS_MAX) begin
          app_en <= 0;
          app_fsm <= S_DPRAM_FSM_CHECK;
        end
      end
    end

    S_DPRAM_FSM_CHECK: begin
      if (dpram_fsm == S_IDLE) begin
        app_fsm <= S_ACK;
        pg_ack <= 1;
      end
    end

    S_ACK: begin
      pg_ack <= 1;
      if (pg_req == 0) begin
        pg_ack <= 0;
        app_fsm <= S_IDLE;
      end
    end

    default: begin
      app_fsm <= S_IDLE;
    end
  endcase 
end

// dpram fsm
reg[31:0] dpram_cnt = 0;
reg[7:0] dpram_hold_addr = 0; 
always @(posedge clk) begin
  ddr3_dpram_wren <= 0;
  app_wdf_wren <= 0;
  app_wdf_end <= 0;

  case (dpram_fsm)
    S_IDLE: begin
      dpram_hold_addr <= 0;

      if (dpram_start) begin
        
        if (i_optype == OPREAD) begin
          ddr3_dpram_addr <= -1;

          dpram_fsm <= S_RD_STREAM;
        end

        else if (i_optype == OPWRITE) begin
          ddr3_dpram_addr <= 0;          
          
          n_writes <= 0;

          dpram_cnt <= 0;
          dpram_fsm <= S_START_WR_STREAM;  
        end
      end

    end

    S_START_WR_STREAM: begin
      ddr3_dpram_addr <= ddr3_dpram_addr + 1;
      
      dpram_cnt <= dpram_cnt + 1;

      if (dpram_cnt >= DPRAM_RD_LATENCY - 1) begin
        dpram_fsm <= S_WR_STREAM;
      end
    end

    S_WR_STREAM: begin
      ddr3_dpram_addr <= ddr3_dpram_addr + 1;
      
      app_wdf_wren <= 1;
      app_wdf_end <= 1;
      app_wdf_data <= ddr3_dpram_dout;

      if (app_wdf_wren && app_wdf_rdy) begin
        n_writes <= n_writes + 1;

        if (n_writes == N_DPRAM_OPS_MAX) begin
          app_wdf_wren <= 0;
          app_wdf_end <= 0;
          dpram_fsm <= S_IDLE;
        end
      end

      else if (app_wdf_wren && !app_wdf_rdy) begin
        // UI write fifo has rejected this write req.
        // we must hold wdf_wren/end until rdy is high again
        app_wdf_data <= app_wdf_data;

        dpram_hold_addr <= ddr3_dpram_addr - (DPRAM_RD_LATENCY + 1);

        dpram_fsm <= S_WR_HOLD;
      end
    end

    S_WR_HOLD: begin
      app_wdf_wren <= 1;
      app_wdf_end <= 1;
      app_wdf_data <= app_wdf_data;

      if (app_wdf_wren && app_wdf_rdy) begin
        n_writes <= n_writes + 1;

        app_wdf_wren <= 0;
        app_wdf_end <= 0;
        
        if (n_writes == N_DPRAM_OPS_MAX) begin
          dpram_fsm <= S_IDLE;
        end
        
        else begin
          // restart data stream
          ddr3_dpram_addr <= dpram_hold_addr + 1;

          dpram_cnt <= 0;
          dpram_fsm <= S_START_WR_STREAM;
        end
      end
    end

    S_RD_STREAM: begin
      ddr3_dpram_wren <= 0;

      if (app_rd_data_valid) begin
        ddr3_dpram_wren <= 1;
        ddr3_dpram_din <= app_rd_data;

        ddr3_dpram_addr <= ddr3_dpram_addr + 1;

        if (ddr3_dpram_addr + 1 == N_DPRAM_OPS_MAX) begin
          dpram_fsm <= S_IDLE;
        end
      end
    end

    default: begin
      dpram_fsm <= S_IDLE;
    end
  endcase
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
wire fake_ddr3_rdreq = app_en && (app_cmd == APP_CMD_RD) && (app_rdy);
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