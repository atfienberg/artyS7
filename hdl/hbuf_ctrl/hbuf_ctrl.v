// Aaron Fienberg
// Aug 2020
// 
// mDOM hit buffer controller
//
// Transfers data from rdout DPRAM into DDR3 page DPRAM
// Sends full pages to DDR3 memory
//
// Reports rd page num and write pg num,
// rd pg is updated externally to free pages
// 
// Page format replicates that of the D-Egg:
// 0:      0xA000 - Start of Memory Page Format 0
// 1:      0x5555 - Synchronization pattern
// 2:      0xAAAA - Synchronization pattern
// 3:      0x5555 - Synchronization pattern
// 4:      Waveform Packet Word 0
// 5:      Waveform Packet Word 1
// ...
// 2043:   Waveform Packet Word 2039
// 2044:   0xAAAA - Synchronization pattern
// 2045:   0x5555 - Synchronization pattern
// 2046:   0xAAAA - Synchronization pattern
// 2047:   CRC16  - CRC16 calculated on words 4-2043
//                  Checksum = 0x8005
//                  Polynomial = x^16 + x^15 + x^2 + 1
//                  Initial value = 0xFFFF
//
// 2 filler words of 0x0000 may 
// appear between discrete waveform packets

module hbuf_ctrl
(
  input clk,
  input rst,
  input en, // enable

  // DDR3 pages to use for the hit buffer
  // hbuf_controller reads these values once when first enabled
  input[15:0] start_pg,
  input[15:0] stop_pg,
  // readback of internal first page and last page
  // when controller is running
  output[15:0] first_pg,
  output[15:0] last_pg,

  input flush_req,
  output reg flush_ack = 0,

  // "FIFO" status signals
  output empty,
  output full,
  output reg[15:0] rd_pg_num = 0,
  output reg[15:0] wr_pg_num = 0, 
  output reg[15:0] n_used_pgs = 0,  
  
  // interface to update the rd_pg
  input[15:0] pg_clr_cnt,
  input pg_clr_req,
  output reg pg_clr_ack = 0,

  // whether the controller has buffered data
  // that has not been sent to DDR3 memory
  output reg buffered_data = 0,

  // wvb reader DPRAM interface
  input[15:0] dpram_len_in,
  input rdout_dpram_run,
  output reg dpram_busy = 0,
  input rdout_dpram_wren,
  input[9:0] rdout_dpram_wr_addr,
  input[31:0] rdout_dpram_data,

  // DDR3 DPRAM interface
  input ddr3_ui_clk,
  output[127:0] ddr3_dpram_dout,
  input[7:0] ddr3_dpram_rd_addr,

  // page transfer request
  input pg_ack,
  output reg pg_req = 0,
  output reg pg_optype = 0,
  output reg[27:0] pg_addr = 0
);

// instantiate the reader DPRAM and the DDR3 DPRAM

//
// wvb_reader DPRAM
//

reg[8:0] rdout_dpram_rd_addr = 0;
wire[63:0] rdout_dpram_dout;
HBUF_RDOUT_DPRAM READER_DPRAM_0
(
  .clka(clk),
  .wea(rdout_dpram_wren),
  .addra(rdout_dpram_wr_addr),
  .dina(rdout_dpram_data),
  .clkb(clk),
  .addrb(rdout_dpram_rd_addr),
  .doutb(rdout_dpram_dout)
);

//
// DDR3 dpram
//

reg pg_dpram_wren = 0;
reg[8:0] pg_dpram_wr_addr = 0;
reg[63:0] pg_dpram_din = 0;
HBUF_DDR3_PG DDR3_PG_DPRAM_0
(
  .clka(clk),
  .wea(pg_dpram_wren),
  .addra(pg_dpram_wr_addr),
  .dina(pg_dpram_din),
  .clkb(ddr3_ui_clk),
  .addrb(ddr3_dpram_rd_addr),
  .doutb(ddr3_dpram_dout)
);

//
// rbd signal process
//

reg[15:0] dpram_len = 0;
reg dpram_done = 0;
always @(posedge clk) begin
  if (rst) begin
    dpram_busy <= 0;
    dpram_len <= 0;
  end

  else begin
    if (rdout_dpram_run) begin
      dpram_len <= dpram_len_in;
      dpram_busy <= 1;      
    end

    else if (dpram_done) begin
      dpram_busy <= 0;
      dpram_len <= 0;
    end
  end
end

//
// logic and processes to handle n_pgs_used, start_pg, stop_pg, 
// and rd_pg update requests 
//

// calculate n_used_pages
reg[15:0] n_allocated_pgs = 0;
reg[15:0] i_n_used_pgs = 0;
always @(*) begin
  if (empty) begin
    i_n_used_pgs = 0;
  end

  else if (rd_pg_num == wr_pg_num) begin
    i_n_used_pgs = n_allocated_pgs;
  end
  
  else if (rd_pg_num > wr_pg_num) begin
    i_n_used_pgs = n_allocated_pgs + wr_pg_num - rd_pg_num; 
  end

  else begin
    i_n_used_pgs = wr_pg_num - rd_pg_num;
  end
end

always @(posedge clk) begin
  n_used_pgs <= i_n_used_pgs;
end

// clip clear count at n_used_pgs
wire[15:0] clipped_clr_cnt = pg_clr_cnt > n_used_pgs ? n_used_pgs : pg_clr_cnt;

// register next_rd_pg, pg_clr_req, clipped_clr_cnt 
reg pg_clr_req_pl = 0;
reg[15:0] next_rd_pg = 0;
reg full_clear_req = 0;
always @(posedge clk) begin
  full_clear_req <= 0;
  next_rd_pg <= rd_pg_num + clipped_clr_cnt;
  pg_clr_req_pl <= pg_clr_req;

  if (clipped_clr_cnt == n_allocated_pgs) begin
    // special case for a full clear (turn a full buffer into an empty one)
    full_clear_req <= 1;
  end
end

wire pg_clr_req_pe;
posedge_detector P_CLR_REQ_PE(.clk(clk), .rst_n(1'b1), 
                              .a(pg_clr_req_pl), .y(pg_clr_req_pe));

wire en_pe;
posedge_detector EN_PE(.clk(clk), .rst_n(1'b1), .a(en), .y(en_pe));


reg[15:0] i_start_pg;
reg[15:0] i_stop_pg;
assign first_pg = i_start_pg;
assign last_pg = i_stop_pg;
// signal a full clear to the hbuf_ctrl FSM
reg full_clear = 0;

// register n_allocated pages, full_clear, i_start_pg, i_stop_pg
// and handle pg_clr requests
always @(posedge clk) begin
  full_clear <= 0;

  if (rst || !en) begin
    rd_pg_num <= 0;
    i_start_pg <= 0;
    i_stop_pg <= 0;
    pg_clr_ack <= 0;
    n_allocated_pgs <= 0;
  end
  
  else if (en_pe) begin
    rd_pg_num <= start_pg;
    i_start_pg <= start_pg;
    i_stop_pg <= stop_pg;
    n_allocated_pgs <= stop_pg - start_pg + 16'b1;
    if (pg_clr_req) begin
      // clear any requests sent while controller wasn't enabled
      pg_clr_ack <= 1;
    end
  end

  else if (pg_clr_req_pe && !pg_clr_ack) begin
    // update the read pg num
    if (full_clear_req) begin
      rd_pg_num <= rd_pg_num;
      full_clear <= 1;
    end

    else if (next_rd_pg > i_stop_pg) begin
      rd_pg_num <= next_rd_pg - n_allocated_pgs;
    end

    else begin
      rd_pg_num <= next_rd_pg;
    end

    pg_clr_ack <= 1;
  end 

  else if (pg_clr_ack && !pg_clr_req) begin
    pg_clr_ack <= 0;
  end
end

//
// hbuf controller fsm
//

localparam S_IDLE = 0,
           S_WR_HDR = 1,
           S_START_STREAM = 2,
           S_WR_DATA = 3,
           S_DPRAM_DONE_WAIT = 4,
           S_WR_FTR = 5,
           S_SEND_PG = 6,
           S_INC_WR_PG = 7,
           S_FLUSH = 8,
           S_FLUSH_ACK = 9,
           S_FULL = 10;
assign full = fsm == S_FULL;
assign empty = (!en) || ((rd_pg_num == wr_pg_num) && !full);
reg[3:0] fsm = S_IDLE;

localparam DPRAM_RD_LATENCY = 2;
localparam LAST_PG_DPRAM_ADDR = 511;
// the address of the data currently presented 
// during a stream
wire[8:0] stream_rd_addr = rdout_dpram_rd_addr - DPRAM_RD_LATENCY;
// whether the DPRAM len is odd; if so, we will need to zero-pad the last word
wire odd_dpram_len = dpram_len[0] == 1'b1;
wire[8:0] shifted_dpram_len = dpram_len >> 1'b1;
// dpram_len on the 64-bit read side
wire[8:0] rd_side_dpram_len = odd_dpram_len ? shifted_dpram_len + 9'b1 : shifted_dpram_len; 
reg[8:0] final_dpram_rd_addr = 0;
always @(posedge clk) begin
  final_dpram_rd_addr <= rd_side_dpram_len - 9'b1; 
end

wire[15:0] next_wr_pg_num = wr_pg_num == i_stop_pg ? i_start_pg : wr_pg_num + 1;

localparam HDR = {16'h5555, 16'hAAAA, 16'h5555, 16'hA000};
// leave out FTR CRC until I get everything else working
localparam FTR = {16'hAAAA, 16'h5555, 16'hAAAA, 16'hBEEF};

reg[31:0] cnt = 0;
// state to return to after writing the header
reg[3:0] ret = S_IDLE;
always @(posedge clk) begin
  if (rst || !en) begin
    wr_pg_num <= 0;
    dpram_done <= 0;
    flush_ack <= 0;
    rdout_dpram_rd_addr <= 0;

    pg_req <= 0;
    pg_optype <= 0;
    pg_addr <= 0;
    pg_dpram_wr_addr <= LAST_PG_DPRAM_ADDR;
    pg_dpram_din <= 0;
    pg_dpram_wren <= 0;

    buffered_data <= 0;   

    cnt <= 0;
    ret <= S_IDLE;
    fsm <= S_IDLE;
  end

  else begin
    pg_dpram_wren <= 0;
    dpram_done <= 0;  
    pg_req <= 0;
    flush_ack <= 0;

    case (fsm)
      S_IDLE: begin
        ret <= S_IDLE;
        
        if (en_pe) begin
          wr_pg_num <= start_pg;
        end

        if (pg_dpram_wr_addr == LAST_PG_DPRAM_ADDR) begin
          ret <= S_IDLE;
          fsm <= S_WR_HDR;
        end

        else if (dpram_len != 0) begin
          cnt <= 0;
          rdout_dpram_rd_addr <= 0;
          fsm <= S_START_STREAM;
        end

        else if (flush_req) begin
          fsm <= S_FLUSH;
        end

      end

      S_WR_HDR: begin
        pg_dpram_wr_addr <= pg_dpram_wr_addr + 1;
        pg_dpram_wren <= 1;
        pg_dpram_din <= HDR;

        fsm <= ret;
      end

      S_START_STREAM: begin
        rdout_dpram_rd_addr <= rdout_dpram_rd_addr + 1;
        cnt <= cnt + 1;

        if (cnt >= DPRAM_RD_LATENCY - 1) begin
          fsm <= S_WR_DATA;
        end
      end

      S_WR_DATA: begin
        buffered_data <= 1;

        rdout_dpram_rd_addr <= rdout_dpram_rd_addr + 1;

        pg_dpram_wr_addr <= pg_dpram_wr_addr + 1;
        pg_dpram_wren <= 1;

        pg_dpram_din <= rdout_dpram_dout;

        if (stream_rd_addr == final_dpram_rd_addr) begin
          dpram_done <= 1;

          if (odd_dpram_len) begin
            pg_dpram_din <= {32'b0, rdout_dpram_dout[31:0]};
          end

          fsm <= S_DPRAM_DONE_WAIT;
        end

        else if (pg_dpram_wr_addr == LAST_PG_DPRAM_ADDR - 2) begin
          // after this page is shipped,
          // restart the stream at the correct addr
          rdout_dpram_rd_addr <= stream_rd_addr + 1;
          cnt <= 0;
          ret <= S_START_STREAM;
          fsm <= S_WR_FTR;
        end
      end

      S_DPRAM_DONE_WAIT: begin
        if (!dpram_busy) begin
          if (pg_dpram_wr_addr == LAST_PG_DPRAM_ADDR - 1) begin
            ret <= S_IDLE;
            fsm <= S_WR_FTR;
          end

          else begin
            fsm <= S_IDLE;
          end
        end
      end

      S_WR_FTR: begin
        pg_dpram_wr_addr <= pg_dpram_wr_addr + 1;
        pg_dpram_wren <= 1;
        pg_dpram_din <= FTR;

        fsm <= S_SEND_PG;
      end

      S_SEND_PG: begin
        pg_addr <= (wr_pg_num << 27'd12);
        pg_optype <= 1'b1;
        pg_req <= 1;

        if (pg_ack) begin
          pg_req <= 0;
          fsm <= S_INC_WR_PG;         
        end
      end

      S_INC_WR_PG: begin
        if (!pg_ack) begin
          buffered_data <= 0;         

          wr_pg_num <= next_wr_pg_num;
          if (next_wr_pg_num == rd_pg_num) begin            
            fsm <= S_FULL;            
          end

          else begin            
            fsm <= S_WR_HDR;
          end
        end
      end

      S_FULL: begin
        if ((rd_pg_num != wr_pg_num) || full_clear) begin
          fsm <= S_WR_HDR;
        end
      end

      S_FLUSH: begin
        pg_dpram_wr_addr <= pg_dpram_wr_addr + 1;
        pg_dpram_wren <= 1;
        pg_dpram_din <= 64'b0;

        if (pg_dpram_wr_addr == LAST_PG_DPRAM_ADDR - 2) begin
          ret <= S_FLUSH_ACK;
          fsm <= S_WR_FTR;
        end
      end

      S_FLUSH_ACK: begin
        flush_ack <= 1;
        if (!flush_req) begin
          flush_ack <= 0;
          fsm <= S_IDLE;
        end
      end

      default: begin
        fsm <= S_IDLE;
      end
    endcase
  end
end
 
endmodule