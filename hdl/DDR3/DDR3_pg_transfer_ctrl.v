// Aaron Fienberg
//
// Controller to transfer pages 
// from/to external DDR3 memory to/from FPGA DPRAM
//

module DDR3_pg_transfer_ctrl
(
  input clk,
  input rst,

  // controls
  input pg_req,
  input pg_optype,
  input[27:0] pg_req_addr,
  output reg pg_ack = 0,

  // memory interface UI inputs
  input app_rdy,  
  input app_wdf_rdy,
  input app_rd_data_valid,
  input[127:0] app_rd_data,

  // DPRAM inputs
  input[127:0] dpram_dout,

  // memory interface UI outputs
  output reg[27:0] app_addr,
  output reg app_en = 0,
  output reg[127:0] app_wdf_data = 0,
  output reg app_wdf_wren = 0,
  output reg app_wdf_end = 0,
  output reg[2:0] app_cmd = 0,

 // DPRAM outputs
 output reg[127:0] dpram_din = 0,
 output reg[7:0] dpram_addr = 0,
 output reg dpram_wren = 0
);

localparam APP_CMD_WRITE = 0,
           APP_CMD_RD = 1;

localparam DPRAM_RD_LATENCY = 2; 
localparam REQS_PER_PG = 256;
localparam N_APP_REQS_MAX = 255;
localparam N_DPRAM_OPS_MAX = 255;

localparam OPREAD = 0,
           OPWRITE = 1;   

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
  if (rst) begin
    n_app_reqs <= 0;
    dpram_start <= 0;
    i_optype <= 0;
    next_app_addr <= 0;
    app_en <= 0;
    app_cmd <= 0;
    pg_ack <= 0;
    app_addr <= 0;
    app_fsm <= S_IDLE;
  end

  else begin 
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
end

// dpram fsm
reg[31:0] dpram_cnt = 0;
reg[7:0] dpram_hold_addr = 0; 
always @(posedge clk) begin
  if (rst) begin
    n_writes <= 0;
    dpram_wren <= 0;
    dpram_addr <= 0;
    dpram_din <= 0;
    app_wdf_wren <= 0;
    app_wdf_end <= 0;
    dpram_cnt <= 0;
    dpram_hold_addr <= 0;
    dpram_fsm <= S_IDLE;
  end

  else begin 
    dpram_wren <= 0;
    app_wdf_wren <= 0;
    app_wdf_end <= 0;

    case (dpram_fsm)
      S_IDLE: begin
        dpram_hold_addr <= 0;

        if (dpram_start) begin
          
          if (i_optype == OPREAD) begin
            dpram_addr <= -1;

            dpram_fsm <= S_RD_STREAM;
          end

          else if (i_optype == OPWRITE) begin
            dpram_addr <= 0;          
            
            n_writes <= 0;

            dpram_cnt <= 0;
            dpram_fsm <= S_START_WR_STREAM;  
          end
        end

      end

      S_START_WR_STREAM: begin
        dpram_addr <= dpram_addr + 1;
        
        dpram_cnt <= dpram_cnt + 1;

        if (dpram_cnt >= DPRAM_RD_LATENCY - 1) begin
          dpram_fsm <= S_WR_STREAM;
        end
      end

      S_WR_STREAM: begin
        dpram_addr <= dpram_addr + 1;
        
        app_wdf_wren <= 1;
        app_wdf_end <= 1;
        app_wdf_data <= dpram_dout;

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

          dpram_hold_addr <= dpram_addr - (DPRAM_RD_LATENCY + 1);

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
            dpram_addr <= dpram_hold_addr + 1;

            dpram_cnt <= 0;
            dpram_fsm <= S_START_WR_STREAM;
          end
        end
      end

      S_RD_STREAM: begin
        dpram_wren <= 0;

        if (app_rd_data_valid) begin
          dpram_wren <= 1;
          dpram_din <= app_rd_data;

          dpram_addr <= dpram_addr + 1;

          if (dpram_addr + 1 == N_DPRAM_OPS_MAX) begin
            dpram_fsm <= S_IDLE;
          end
        end
      end

      default: begin
        dpram_fsm <= S_IDLE;
      end
    endcase
  end
end

endmodule