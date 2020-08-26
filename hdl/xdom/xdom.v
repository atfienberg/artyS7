/////////////////////////////////////////////////////////////////////////////////
// Tyler Anderson Tue 06/18/2019_ 8:48:46.46
//
// Adapted by Aaron Fienberg from MDOT project
// for use with the ARTY S7
//
// xdom.v
//
// currently contains:
//    1.) Debug UART
//    2.) Command, response, status
/////////////////////////////////////////////////////////////////////////////////
module xdom #(parameter N_CHANNELS = 24)
(
 input             clk,
 input             rst,
 
 // Version number
 input [15:0]      vnum, 
 
 // LED controls
 output reg[2:0] led_toggle = 0,
 output reg[14:0] red_led_lvl = 0,
 output reg[14:0] green_led_lvl = 0,
 output reg[14:0] blue_led_lvl = 0,
 output reg[1:0] rgb_cycle_speed_sel = 0,
 output reg[1:0] kr_speed_sel = 0,
 
 // trigger/wvb conf
 output[19:0] xdom_trig_bundle,
 output[39:0] xdom_wvb_conf_bundle,
 output reg[N_CHANNELS-1:0] xdom_wvb_arm = 0,
 output reg[N_CHANNELS-1:0] xdom_trig_run = 0,
 output reg[N_CHANNELS-1:0] wvb_rst = 0,

 // waveform buffer status
 input[N_CHANNELS-1:0] wvb_armed,
 input[N_CHANNELS-1:0] wvb_overflow,
 input[N_CHANNELS-1:0] wvb_hdr_full,
 input[N_CHANNELS*16 - 1:0] wfms_in_buf,
 input[N_CHANNELS*16 - 1:0] buf_wds_used,

 // wvb reader
 input[15:0] dpram_len_in,
 input rdout_dpram_run,
 output reg dpram_busy = 0,
 input rdout_dpram_wren,
 input[9:0] rdout_dpram_wr_addr,
 input[31:0] rdout_dpram_data,
 output reg wvb_reader_enable = 0,
 output reg wvb_reader_dpram_mode = 0,

 // DDR3 interface
 input ddr3_ui_clk,
 output reg[27:0] pg_req_addr = 0,
 output reg pg_optype = 0,
 output reg pg_req = 0,
 input pg_ack,
 output reg ddr3_sys_rst = 0,
 input ddr3_cal_complete,
 input ddr3_ui_sync_rst,
 input[11:0] ddr3_device_temp,
 input[7:0] ddr3_dpram_addr,
 input ddr3_dpram_wren,
 input[127:0] ddr3_dpram_din,
 output[127:0] ddr3_dpram_dout,

 // Debug FT232R I/O
 input             debug_txd,
 output            debug_rxd,
 input             debug_rts_n,
 output            debug_cts_n   
);

///////////////////////////////////////////////////////////////////////////////
// 1.) Debug UART
wire [11:0] debug_logic_adr;
wire [15:0] debug_logic_wr_data;
wire        debug_logic_wr_req;
wire        debug_logic_rd_req;
wire        debug_err_req;
wire [31:0] debug_err_data;
wire [15:0] debug_logic_rd_data;
wire        debug_logic_ack;
wire        debug_err_ack; 
ft232r_proc_buffered UART_DEBUG_0
 (
  // Outputs
  .rxd              (debug_rxd),
  .cts_n            (debug_cts_n),
  .logic_adr        (debug_logic_adr[11:0]),
  .logic_wr_data    (debug_logic_wr_data[15:0]),
  .logic_wr_req     (debug_logic_wr_req),
  .logic_rd_req     (debug_logic_rd_req),
  .err_req          (debug_err_req),
  .err_data         (debug_err_data[31:0]),
  // Inputs
  .clk              (clk),
  .rst              (rst),
  .txd              (debug_txd),
  .rts_n            (debug_rts_n),
  .logic_rd_data    (debug_logic_rd_data[15:0]),
  .logic_ack        (debug_logic_ack),
  .err_ack          (debug_err_ack)
  ); 


//////////////////////////////////////////////////////////////////////////////
// 2.) Command, repsonse, status
wire [11:0] y_adr;
wire [15:0] y_wr_data;
wire        y_wr; 
reg [15:0] y_rd_data; 
crs_master CRSM_0
 (
  // Outputs
  .y_adr            (y_adr[11:0]),
  .y_wr_data        (y_wr_data[15:0]),
  .y_wr             (y_wr),
  .a0_ack           (debug_logic_ack),
  .a0_rd_data       (debug_logic_rd_data[15:0]),
  .a0_buf_rd        (),
  .a1_ack           (),
  .a1_rd_data       (),
  .a1_buf_rd        (),
  .a2_ack           (),
  .a2_rd_data       (),
  .a2_buf_rd        (),
  .a3_ack           (),
  .a3_rd_data       (),
  .a3_buf_rd        (),
  // Inputs
  .clk              (clk),
  .rst              (rst),
  .y_rd_data        (y_rd_data[15:0]),
  .a0_wr_req        (debug_logic_wr_req),
  .a0_bwr_req       (1'b0),
  .a0_rd_req        (debug_logic_rd_req),
  .a0_wr_data       (debug_logic_wr_data[15:0]),
  .a0_adr           (debug_logic_adr[11:0]),
  .a0_buf_empty     (1'b1),
  .a0_buf_wr_data   (),
  .a1_wr_req        (),
  .a1_bwr_req       (),
  .a1_rd_req        (),
  .a1_wr_data       (),
  .a1_adr           (),
  .a1_buf_empty     (),
  .a1_buf_wr_data   (),
  .a2_wr_req        (),
  .a2_bwr_req       (),
  .a2_rd_req        (),
  .a2_wr_data       (),
  .a2_adr           (),
  .a2_buf_empty     (),
  .a2_buf_wr_data   (),
  .a3_wr_req        (),
  .a3_bwr_req       (),
  .a3_rd_req        (),
  .a3_wr_data       (),
  .a3_adr           (),
  .a3_buf_empty     (),
  .a3_buf_wr_data   ()
  ); 
 
// trig bundle
reg wvb_trig_et = 0;
reg wvb_trig_gt = 0;    
reg wvb_trig_lt = 0;   
reg wvb_trig_run = 0;
reg wvb_trig_discr_trig_pol = 0;
reg [11:0] wvb_trig_thr = 0;   
reg wvb_trig_discr_trig_en = 0;
reg wvb_trig_thresh_trig_en = 0; 
reg wvb_trig_ext_trig_en = 0; 
mDOM_trig_bundle_fan_in TRIG_FAN_IN
  (
   .bundle(xdom_trig_bundle),
   .trig_et(wvb_trig_et),
   .trig_gt(wvb_trig_gt),
   .trig_lt(wvb_trig_lt),
   .trig_run(wvb_trig_run),
   .discr_trig_pol(wvb_trig_discr_trig_pol),
   .trig_thresh(wvb_trig_thr),
   .disc_trig_en(wvb_trig_discr_trig_en),
   .thresh_trig_en(wvb_trig_thresh_trig_en),
   .ext_trig_en(wvb_trig_ext_trig_en)
  );

// wvb conf bundle
reg[11:0] wvb_cnst_config = 0;
reg[7:0] wvb_post_config = 0;
reg[4:0] wvb_pre_config = 0;
reg[11:0] wvb_test_config = 0;
reg wvb_arm = 0;
reg wvb_trig_mode = 0;
reg wvb_cnst_run = 0;
mDOM_wvb_conf_bundle_fan_in WVB_CONF_FAN_IN
  (
   .bundle(xdom_wvb_conf_bundle),
   .cnst_conf(wvb_cnst_config),
   .test_conf(wvb_test_config),
   .post_conf(wvb_post_config),
   .pre_conf(wvb_pre_config),
   .arm(wvb_arm),
   .trig_mode(wvb_trig_mode),
   .cnst_run(wvb_cnst_run)
  );

reg[4:0] buf_status_sel;
// buffer status mux
wire[15:0] wds_used_mux_out;
reg[15:0] wds_used_mux_out_reg = 0;
n_channel_mux #(.N_INPUTS(N_CHANNELS), 
                .INPUT_WIDTH(16)) BUF_WDS_USED_MUX
  (
   .in(buf_wds_used),
   .sel(buf_status_sel),
   .out(wds_used_mux_out)  
  );

wire[15:0] buf_n_wfms_mux_out;
reg[15:0] buf_n_wfms_mux_out_reg = 0;
n_channel_mux #(.N_INPUTS(N_CHANNELS), 
                .INPUT_WIDTH(16)) BUF_N_WFMS_MUX
  (
   .in(wfms_in_buf),
   .sel(buf_status_sel),
   .out(buf_n_wfms_mux_out)  
  );
// register mux outputs 
always @(posedge clk) begin
  wds_used_mux_out_reg <= wds_used_mux_out;
  buf_n_wfms_mux_out_reg <= buf_n_wfms_mux_out;
end 

//////////////////////////////////////////////////////////////////////////////
// Read registers
reg[15:0] dpram_len;

wire [15:0] dpram_rd_data_a;
wire [15:0] dpram_rd_data_b;
wire [15:0] direct_rdout_dpram_data;
reg[15:0] xdom_dpram_rd_data;

// dpram rd mux sel
reg dpram_sel = 0;
reg[15:0] test_ctrl_reg = 16'b0;
reg dpram_done = 0;

// pg op task reg
reg pg_req_start = 0;
// synchronize ack
wire pg_ack_s;
sync PGACKSYNC(.clk(clk), .rst_n(!rst), .a(pg_ack), .y(pg_ack_s));
always @(posedge clk) begin
  pg_req <= pg_req;

  // also drop req if memory interface is reset
  // (rst is active low, so it's really an enable)
  if (pg_ack_s || !ddr3_sys_rst) begin
    pg_req <= 0;
  end

  else if (pg_req_start) begin
    pg_req <= 1;
  end

end
wire pg_task_val = pg_ack_s || pg_req;

always @(*)
 begin
    case(y_adr)
      12'hfff: begin y_rd_data =       vnum;                                                   end
      12'hffe: begin y_rd_data =       {9'b0, 
                                        wvb_trig_ext_trig_en,
                                        wvb_trig_thresh_trig_en,
                                        wvb_trig_discr_trig_en,
                                        wvb_trig_discr_trig_pol,
                                        wvb_trig_lt,
                                        wvb_trig_gt,
                                        wvb_trig_et};                                          end
      12'hffd: begin y_rd_data =       {4'b0, wvb_trig_thr};                                   end
      12'hffc: begin y_rd_data =       xdom_trig_run[15:0];                                    end
      12'hffb: begin y_rd_data =       {15'b0, wvb_trig_mode};                                 end
      12'hffa: begin y_rd_data =       xdom_wvb_arm[15:0];                                     end
      12'hff9: begin y_rd_data =       wvb_armed[15:0];                                        end
      12'hff8: begin y_rd_data =       {15'b0, wvb_cnst_run};                                  end
      12'hff7: begin y_rd_data =       {4'b0, wvb_cnst_config};                                end
      12'hff6: begin y_rd_data =       {4'b0, wvb_test_config};                                end
      12'hff5: begin y_rd_data =       {8'b0, wvb_post_config};                                end
      12'hff4: begin y_rd_data =       {11'b0, wvb_pre_config};                                end
      12'heff: begin y_rd_data =       dpram_len;                                              end
      12'hefe: begin y_rd_data =       {15'b0, dpram_done};                                    end
      12'hefd: begin y_rd_data =       {15'b0, dpram_sel};                                     end
      12'hefc: begin y_rd_data =       buf_n_wfms_mux_out_reg;                                 end
      12'hefb: begin y_rd_data =       wds_used_mux_out_reg;                                   end
      12'hefa: begin y_rd_data =       wvb_overflow[15:0];                                     end
      12'hef9: begin y_rd_data =       wvb_rst[15:0];                                          end
      12'hef8: begin y_rd_data =       {15'b0, wvb_reader_enable};                             end
      12'hef7: begin y_rd_data =       {15'b0, wvb_reader_dpram_mode};                         end
      12'hef6: begin y_rd_data =       wvb_hdr_full[15:0];                                     end
      12'hef5: begin y_rd_data =       {11'b0, buf_status_sel};                                end
      12'hef4: begin y_rd_data =       {8'b0, xdom_trig_run[N_CHANNELS-1:16]};                 end
      12'hef3: begin y_rd_data =       {8'b0, xdom_wvb_arm[N_CHANNELS-1:16]};                  end
      12'hef2: begin y_rd_data =       {8'b0, wvb_armed[N_CHANNELS-1:16]};                     end
      12'hef1: begin y_rd_data =       {8'b0, wvb_overflow[N_CHANNELS-1:16]};                  end
      12'hef0: begin y_rd_data =       {8'b0, wvb_rst[N_CHANNELS-1:16]};                       end
      12'heef: begin y_rd_data =       {8'b0, wvb_hdr_full[N_CHANNELS-1:16]};                  end
      12'hdff: begin y_rd_data =       pg_req_addr[27:16];                                     end
      12'hdfe: begin y_rd_data =       pg_req_addr[15:0];                                      end
      12'hdfd: begin y_rd_data =       {15'b0, pg_optype};                                     end
      12'hdfc: begin y_rd_data =       {15'b0, pg_task_val};                                   end
      12'hdfb: begin y_rd_data =       {15'b0, ddr3_sys_rst};                                  end
      12'hdfa: begin y_rd_data =       {15'b0, ddr3_cal_complete};                             end
      12'hdf9: begin y_rd_data =       {5'b0, ddr3_device_temp};                               end
      12'hdf8: begin y_rd_data =       {15'b0, ddr3_ui_sync_rst};                              end
      12'h8ff: begin y_rd_data =       {13'h0, led_toggle};                                    end
      12'h8fe: begin y_rd_data =       {1'h0, red_led_lvl};                                    end
      12'h8fd: begin y_rd_data =       {1'h0, green_led_lvl};                                  end
      12'h8fc: begin y_rd_data =       {1'h0, blue_led_lvl};                                   end
      12'h8fb: begin y_rd_data =       {14'h0, rgb_cycle_speed_sel};                           end
      12'h8fa: begin y_rd_data =       {14'h0, kr_speed_sel};                                  end
      default: 
        begin
           y_rd_data = xdom_dpram_rd_data; 
        end
      
    endcase   
 end

///////////////////////////////////////////////////////////////////////////////
// Write registers (not task regs)
always @(posedge clk)
 begin
    // clear registers that automatically reset (e.g. one shots)  
    xdom_trig_run <= 0;
    dpram_done <= 0;
    xdom_wvb_arm <= 0;

    pg_req_start <= 0;

    if(y_wr) 
      case(y_adr)       
        12'hffe: begin
           wvb_trig_et <= y_wr_data[0];
           wvb_trig_gt <= y_wr_data[1];
           wvb_trig_lt <= y_wr_data[2];
           wvb_trig_discr_trig_pol <= y_wr_data[3];
           wvb_trig_discr_trig_en <= y_wr_data[4];
           wvb_trig_thresh_trig_en <= y_wr_data[5];
           wvb_trig_ext_trig_en <= y_wr_data[6];
        end
        12'hffd: begin wvb_trig_thr <= y_wr_data[11:0];                                        end
        12'hffc: begin xdom_trig_run[15:0] <= y_wr_data;                                       end
        12'hffb: begin wvb_trig_mode <= y_wr_data[0];                                          end
        12'hffa: begin xdom_wvb_arm[15:0]  <= y_wr_data;                                       end
        12'hff8: begin wvb_cnst_run <= y_wr_data[0];                                           end
        12'hff7: begin wvb_cnst_config <= y_wr_data[11:0];                                     end
        12'hff6: begin wvb_test_config <= y_wr_data[11:0];                                     end
        12'hff5: begin wvb_post_config <= y_wr_data[7:0];                                      end
        12'hff4: begin wvb_pre_config <= y_wr_data[4:0];                                       end
        12'hefe: begin dpram_done <= y_wr_data[0];                                             end
        12'hefd: begin dpram_sel <= y_wr_data[0];                                              end
        12'hef9: begin wvb_rst[15:0] <= y_wr_data;                                             end
        12'hef8: begin wvb_reader_enable <= y_wr_data[0];                                      end
        12'hef7: begin wvb_reader_dpram_mode <= y_wr_data[0];                                  end            
        12'hef5: begin buf_status_sel <= y_wr_data[4:0];                                       end
        12'hef4: begin xdom_trig_run[N_CHANNELS-1:16] <= y_wr_data[7:0];                       end
        12'hef3: begin xdom_wvb_arm[N_CHANNELS-1:16] <= y_wr_data[7:0];                        end
        12'hef0: begin wvb_rst[N_CHANNELS-1:16] <= y_wr_data[7:0];                             end
        12'hdff: begin pg_req_addr[27:16] <= y_wr_data[11:0];                                  end
        12'hdfe: begin pg_req_addr[15:0] <= y_wr_data[15:0];                                   end
        12'hdfd: begin pg_optype <= y_wr_data[0];                                              end
        12'hdfc: begin pg_req_start <= y_wr_data[0];                                           end
        12'hdfb: begin ddr3_sys_rst <= y_wr_data[0];                                           end        
        12'h8ff: begin led_toggle <= y_wr_data[2:0];                                           end
        12'h8fe: begin red_led_lvl <= y_wr_data[14:0];                                         end
        12'h8fd: begin green_led_lvl <= y_wr_data[14:0];                                       end
        12'h8fc: begin blue_led_lvl <= y_wr_data[14:0];                                        end
        12'h8fb: begin rgb_cycle_speed_sel <= y_wr_data[1:0];                                  end
        12'h8fa: begin kr_speed_sel <= y_wr_data[1:0];                                         end
        default: begin                                                                         end
      endcase
 end // always @ (posedge clk)

// wire [15:0] dpram_wr_data_a = 16'b0;
// wire        dpram_wr_a = 1'b0;
// wire [11:0] dpram_addr_a = 12'b0;

// // scratch DPRAM
// DPRAM_2048_16 DPRAM_2048_16_0
//  (
//    // Outputs
//    .douta(dpram_rd_data_a),
//    .doutb(dpram_rd_data_b),
//    // Inputs
//    .ena(1'b1),
//    .enb(1'b1),
//    .addra(dpram_addr_a),
//    .addrb(y_adr[10:0]),
//    .clka(clk),
//    .clkb(clk),
//    .dina(dpram_wr_data_a),
//    .dinb(y_wr_data),
//    .wea(dpram_wr_a),
//    .web(y_wr && (y_adr[11]==0) && (dpram_sel == 0))
//   ); 

// DDR3 transfer dpram
wire[15:0] ddr3_dpram_xdom_out;
XDOM_DDR3_PG PG_DPRAM
(
  .clka(clk),
  .wea(y_wr && (y_adr[11]==0) && (dpram_sel == 0)),
  .addra(y_adr[10:0]),
  .dina(y_wr_data),
  .douta(ddr3_dpram_xdom_out),
  .clkb(ddr3_ui_clk),
  .web(ddr3_dpram_wren),
  .addrb(ddr3_dpram_addr),
  .dinb(ddr3_dpram_din),
  .doutb(ddr3_dpram_dout)
);

// direct readout DPRAM (rd only from xdom)
DIRECT_RDOUT_DPRAM RDOUT_DPRAM
(
  .clka(clk),
  .wea(rdout_dpram_wren),
  .addra(rdout_dpram_wr_addr),
  .dina(rdout_dpram_data),
  .clkb(clk),
  .addrb(y_adr[10:0]),
  .doutb(direct_rdout_dpram_data)
);

//
// place rbd logic here for now
//
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
// DPRAM read mux
//
always @(*) begin
  case (dpram_sel) 
    // 0: xdom_dpram_rd_data = dpram_rd_data_b;
    0: xdom_dpram_rd_data = ddr3_dpram_xdom_out;
    1: xdom_dpram_rd_data = direct_rdout_dpram_data;
    default: xdom_dpram_rd_data = dpram_rd_data_b;
  endcase
end
 
endmodule

// For emacs verilog-mode
// Local Variables:
// verilog-library-directories:("." "../ft232r_proc_buffered/" "../crs_master/" "../../ipcores/DPRAM_2048_16/")
// End:
