// Aaron Fienberg
//
// Test bench for some hbuf_ctrl features 
//

module hbuf_tb();

parameter CLK_PERIOD = 10;
reg clk;

initial begin
 // clock initialization        
 clk = 1'b0;    
end

// clock driver
always @(clk) #(CLK_PERIOD / 2.0) clk <= !clk;

localparam RAMP_LEN = 21;

reg en = 0;
reg[15:0] start_pg = 0;
wire[15:0] first_pg;
wire[15:0] last_pg;
reg[15:0] stop_pg = 0;
reg flush_req = 0;
wire flush_ack;
wire buffered_data;

wire[15:0] rd_pg_num;
wire[15:0] wr_pg_num;
wire[15:0] n_used_pgs;

reg[15:0] dpram_len_in = 0;
reg dpram_run = 0;
wire dpram_busy;
reg rdout_dpram_wren = 0;
reg[9:0] rdout_dpram_wr_addr = 0;
reg[31:0] rdout_dpram_wr_data = 0;

wire pg_req;
reg pg_ack = 0;
wire[27:0] pg_addr;

reg[15:0] pg_clr_cnt = 0;
reg pg_clr_req = 0;
wire pg_clr_ack;
wire empty;
wire full;
hbuf_ctrl HBUF_CTRL_0
(
 .clk(clk),
 .rst(1'b0),
 .en(en),
 .start_pg(start_pg),
 .stop_pg(stop_pg),
 .first_pg(first_pg),
 .last_pg(last_pg),
 .flush_req(flush_req),
 .flush_ack(flush_ack),
 .empty(empty),
 .full(full),
 .rd_pg_num(rd_pg_num),
 .wr_pg_num(wr_pg_num),
 .n_used_pgs(n_used_pgs),
 .pg_clr_cnt(pg_clr_cnt),
 .pg_clr_req(pg_clr_req),
 .pg_clr_ack(pg_clr_ack),
 
 .buffered_data(buffered_data),
 
 .dpram_len_in(dpram_len_in),
 .rdout_dpram_run(dpram_run),
 .dpram_busy(dpram_busy),
 .rdout_dpram_wren(rdout_dpram_wren),
 .rdout_dpram_wr_addr(rdout_dpram_wr_addr),
 .rdout_dpram_data(rdout_dpram_wr_data),
 .ddr3_ui_clk(clk),
 .ddr3_dpram_dout(),
 .ddr3_dpram_rd_addr(),

 .pg_ack(pg_ack),
 .pg_req(pg_req),
 .pg_optype(),
 .pg_addr(pg_addr)
);

reg[47:0] ltc = 0;
reg start_writing =0;
reg stop_writing =0;
always @(posedge clk) begin
  ltc <= ltc + 1;
  start_writing <= 0;

  if (ltc == 2) begin
    start_writing <= 1;
  end

  if (pg_clr_req && pg_clr_ack) begin
    pg_clr_req <= 0;
  end

  if (ltc == 5) begin
    start_pg <= 5;
    stop_pg <= 10;
  end

  if (ltc == 6) begin
    en <= 1;
  end

  // stop the writer to test a flush req
  if (ltc == 16929) begin
    stop_writing <= 1;
  end
end

// simple state machine to repeatedly write ramp patterns into the rdout dpram
localparam S_IDLE = 0,
           S_WR = 1,
           S_RUN = 2,
           S_BUSY = 3,
           S_START = 4;
reg[3:0] fsm = S_IDLE;

wire[9:0] next_dpram_wr_addr = rdout_dpram_wr_addr + 1;

always @(posedge clk) begin
  rdout_dpram_wren <= 0;
  dpram_run <= 0;

  case (fsm) 
    S_IDLE: begin
      if (start_writing) begin
        fsm <= S_START;
      end
    end
    
    S_WR: begin
      rdout_dpram_wr_addr <= next_dpram_wr_addr;
      rdout_dpram_wren <= 1;
      rdout_dpram_wr_data <= {{6'd1, next_dpram_wr_addr},
                              {6'd0, next_dpram_wr_addr}};
      if (rdout_dpram_wr_addr == RAMP_LEN - 2) begin
        fsm <= S_RUN;
      end
    end

    S_RUN: begin
      if (!dpram_busy) begin
        dpram_run <= 1;
        dpram_len_in <= RAMP_LEN;
        fsm <= S_BUSY;
      end
    end

    S_BUSY: begin
      if (dpram_busy == 1) begin
        fsm <= S_START;
      end
    end

    S_START: begin
      rdout_dpram_wr_addr <= -1;
      
      if (!dpram_busy) begin
        if (stop_writing) begin
          fsm <= S_IDLE;
        end

        else begin
          fsm <= S_WR;
        end
      end
    end
  endcase
end

// handle pg transfer handshakes
reg[31:0] handshake_cnt = 0;
localparam MAX_SHAKE_CNT = 9;
always @(posedge clk) begin
  pg_ack <= 0;
  handshake_cnt <= 0;

  if (pg_req) begin
    handshake_cnt <= handshake_cnt + 1;
  end

  if ((handshake_cnt >= MAX_SHAKE_CNT) && pg_req) begin
    pg_ack <= 1;    
  end  
end

// pg clear reqs
always @(posedge clk) begin
  if (pg_clr_req && pg_clr_ack) begin
    pg_clr_req <= 0;
  end

  if (ltc == 11347) begin
    pg_clr_cnt <= 1;
    pg_clr_req <= 1;
  end

  if (ltc == 13244) begin
    pg_clr_cnt <= 1000;
    pg_clr_req <= 1;
  end
end

// flush reqs
always @(posedge clk) begin
  if (flush_req && flush_ack) begin
    flush_req <= 0;
  end

  if (ltc == 16969) begin
    flush_req <= 1;    
  end
end

endmodule