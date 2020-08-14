// Aaron Fienberg
// August 2020
//
// mDOM waveform buffer reader
//
// will start by reading a single buffer and then extend to handle 
// multiple input channels
//
// the WVB reader transfers data from the waveform buffers to DPRAMs
// in 32-bit words
//

module wvb_reader #(parameter P_DATA_WIDTH = 22,
                    parameter P_WVB_ADR_WIDTH = 12,
                    parameter P_DPRAM_ADR_WIDTH = 10,
                    parameter P_HDR_WIDTH = 80,
                    parameter P_FMT = 0
                   )
(
  input clk,
  input rst,
  input en, //enable

  // DPRAM interface

  // Outputs
  output[31:0] dpram_data,
  output[P_DPRAM_ADR_WIDTH-1:0] dpram_addr,
  output dpram_wren,
  output reg[15:0] dpram_len = 0,
  output reg dpram_run = 0,

  // Inputs
  input dpram_busy,
  input dpram_mode,

  // WVB interface

  // Outputs
  output reg hdr_rdreq = 0,
  output wvb_rdreq,
  output wvb_rddone,

  // Inputs
  input[P_DATA_WIDTH-1:0] wvb_data,
  input[P_HDR_WIDTH-1:0] hdr_data,
  input hdr_empty
);

reg rd_ctrl_req = 0;
wire rd_ctrl_ack;
wire rd_ctrl_more; // indicates that there is more data to write in the next DPRAM
wire[7:0] index = 11; // placeholder 
wire[15:0] rd_ctrl_dpram_len;

// read controller
wvb_rd_ctrl_fmt_0 RD_CTRL
  (
   .clk(clk),
   .rst(rst),
   .req(rd_ctrl_req),
   .idx(index),
   .dpram_mode(dpram_mode),
   .ack(rd_ctrl_ack),
   .rd_ctrl_more(rd_ctrl_more),
   .wvb_data(wvb_data),
   .hdr_data(hdr_data),
   .wvb_rdreq(wvb_rdreq),
   .wvb_rddone(wvb_rddone),
   .dpram_a(dpram_addr),
   .dpram_data(dpram_data),
   .dpram_wren(dpram_wren),
   .dpram_len(rd_ctrl_dpram_len)
  );

// FSM logic
reg[3:0] fsm = 0;
localparam
  S_IDLE = 0,
  S_HDR_WAIT = 1,
  S_RD_CTRL_REQ = 2,
  S_DPRAM_RUN = 3,
  S_DPRAM_BUSY = 4,
  S_DPRAM_DONE = 5;


reg[31:0] cnt = 0;
localparam HDR_WT_CNT = 1;

always @(posedge clk) begin
  if (rst || !en) begin
    fsm <= S_IDLE;

    cnt <= 0;
    rd_ctrl_req <= 0;
    hdr_rdreq <= 0;
    dpram_run <= 0;
    dpram_len <= 0;
  end

  else begin
    hdr_rdreq <= 0;
    dpram_run <= 0;

    case (fsm) 
      S_IDLE: begin
        rd_ctrl_req <= 0;
        cnt <= 0;

        if (!hdr_empty && !dpram_busy && !rd_ctrl_ack) begin
          hdr_rdreq <= 1;
          fsm <= S_HDR_WAIT;
        end

        // continue to next buffer...
      end

      S_HDR_WAIT: begin
        // wait for HDR to become available
        cnt <= cnt + 1;
        if (cnt == HDR_WT_CNT - 1) begin
          cnt <= 0;
          fsm <= S_RD_CTRL_REQ;
        end
      end 
    
      S_RD_CTRL_REQ: begin
        rd_ctrl_req <= 1;
        // wait for ack
        if (rd_ctrl_ack) begin
          rd_ctrl_req <= 0;
          dpram_len <= rd_ctrl_dpram_len;
          fsm <= S_DPRAM_RUN;
        end
      end

      S_DPRAM_RUN: begin
        if (!dpram_busy) begin
          dpram_run <= 1;
          fsm <= S_DPRAM_BUSY;
        end
      end

      S_DPRAM_BUSY: begin
        // wait for DPRAM to become busy
        if (dpram_busy) begin
          fsm <= S_DPRAM_DONE;
        end
      end

      S_DPRAM_DONE: begin
        // wait for DPRAM to be done (no longer busy)
        if (!dpram_busy) begin
          if (dpram_mode == 1 && rd_ctrl_more) begin
            // more data to read
            if (!rd_ctrl_ack) begin
              fsm <= S_RD_CTRL_REQ;
            end
          end

          else begin
            // continue to next buffer ...
            fsm <= S_IDLE;
          end
        end
      end

      default: begin
        fsm <= S_IDLE;
      end
    
    endcase
  end
end

endmodule