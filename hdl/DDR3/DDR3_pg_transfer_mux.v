// Aaron Fienberg
// Aug 2020
//
// Multiplexes requests for DDR3 page transfers
// from the hbuf controller and from xdom 
//
// runs in the DDR3 ui clock domain
//

module DDR3_pg_transfer_mux
(
  input clk,
  input rst,

  // hbuf connections
  input hbuf_pg_req,
  input hbuf_pg_optype,
  output hbuf_pg_ack,
  input[27:0] hbuf_pg_req_addr,
  input[127:0] hbuf_dpram_dout,
  
  // xdom connections
  input xdom_pg_req,
  input xdom_pg_optype,
  output xdom_pg_ack,
  input[27:0] xdom_pg_req_addr,
  input[127:0] xdom_dpram_dout,
  output xdom_dpram_wren,

  // DDR3 pg transfer connections
  output reg ddr3_pg_req = 0,
  output reg ddr3_pg_optype,
  input ddr3_pg_ack,
  output reg[27:0] ddr3_pg_req_addr,
  output reg[127:0] ddr3_dpram_dout,  
  input ddr3_dpram_wren  
);

// idx 0 for hbuf, 1 for xdom
reg[2:0] idx = 0;

// multiplex pg, optype, req addr, dpram dout
always @(*) begin
  case (idx)
    0: begin      
      ddr3_pg_optype = hbuf_pg_optype;
      ddr3_pg_req_addr = hbuf_pg_req_addr;
      ddr3_dpram_dout = hbuf_dpram_dout;  
    end

    1: begin      
      ddr3_pg_optype = xdom_pg_optype;
      ddr3_pg_req_addr = xdom_pg_req_addr;
      ddr3_dpram_dout = xdom_dpram_dout;  
    end

    default: begin
      ddr3_pg_optype = 0;
      ddr3_pg_req_addr = 0;
      ddr3_dpram_dout = 0;  
    end
    
  endcase
end

assign hbuf_pg_ack = ddr3_pg_ack && (idx == 0);
assign xdom_pg_ack = ddr3_pg_ack && (idx == 1);

assign xdom_dpram_wren = ddr3_dpram_wren && (idx == 1);

// synchronize pg reqs
wire hbuf_pg_req_s;
sync HREQSYNC(.clk(clk), .rst_n(!rst), .a(hbuf_pg_req), .y(hbuf_pg_req_s));

wire xdom_pg_req_s;
sync XREQSYNC(.clk(clk), .rst_n(!rst), .a(xdom_pg_req), .y(xdom_pg_req_s));

localparam S_REQ_WAIT = 0,
           S_PG_REQ = 1,
           S_CLEAR_WAIT = 2;

reg[3:0] fsm = S_REQ_WAIT;

wire i_req = idx == 0 ? hbuf_pg_req_s : xdom_pg_req_s;
wire next_idx = idx == 0 ? 1 : 0;
always @(posedge clk) begin
  ddr3_pg_req <= 0;

  if (rst) begin
    idx <= 0;
    fsm <= S_REQ_WAIT;
  end

  else begin    
    case (fsm) 

      S_REQ_WAIT: begin
        if (i_req) begin
          ddr3_pg_req <= 1;
          fsm <= S_PG_REQ;
        end

        else begin
          idx <= next_idx;
        end
      end

      S_PG_REQ: begin
        ddr3_pg_req <= 1;
        if (ddr3_pg_ack) begin
          fsm <= S_CLEAR_WAIT;
        end
      end

      S_CLEAR_WAIT: begin
        // follow hbuf/xdom_pg_req_s
        ddr3_pg_req <= i_req;
        if (!i_req && !ddr3_pg_req && !ddr3_pg_ack) begin
          // cycle index
          idx <= next_idx;
          fsm <= S_REQ_WAIT;
        end
      end

      default: begin
        fsm <= S_REQ_WAIT;
      end

    endcase
  end
end

endmodule