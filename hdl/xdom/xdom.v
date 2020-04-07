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
module xdom
  (
   input 	     clk,
   input 	     rst,
   
    // Version number
   input [15:0]      vnum, 

   // LED controls
   output reg[2:0] led_toggle = 0,
   output reg[14:0] red_led_lvl = 0,
   output reg[14:0] green_led_lvl = 0,
   output reg[14:0] blue_led_lvl = 0,
   output reg[1:0] rgb_cycle_speed_sel = 0,
   output reg[1:0] kr_speed_sel = 0,
   
   // Debug FT232R I/O
   input 	     debug_txd,
   output 	     debug_rxd,
   input 	     debug_rts_n,
   output 	     debug_cts_n   
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
      .rxd		(debug_rxd),
      .cts_n		(debug_cts_n),
      .logic_adr	(debug_logic_adr[11:0]),
      .logic_wr_data	(debug_logic_wr_data[15:0]),
      .logic_wr_req	(debug_logic_wr_req),
      .logic_rd_req	(debug_logic_rd_req),
      .err_req		(debug_err_req),
      .err_data		(debug_err_data[31:0]),
      // Inputs
      .clk		(clk),
      .rst		(rst),
      .txd		(debug_txd),
      .rts_n		(debug_rts_n),
      .logic_rd_data	(debug_logic_rd_data[15:0]),
      .logic_ack	(debug_logic_ack),
      .err_ack		(debug_err_ack)
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
      .y_adr		(y_adr[11:0]),
      .y_wr_data	(y_wr_data[15:0]),
      .y_wr		(y_wr),
      .a0_ack		(debug_logic_ack),
      .a0_rd_data	(debug_logic_rd_data[15:0]),
      .a0_buf_rd	(),
      .a1_ack		(),
      .a1_rd_data	(),
      .a1_buf_rd	(),
      .a2_ack		(),
      .a2_rd_data	(),
      .a2_buf_rd	(),
      .a3_ack		(),
      .a3_rd_data	(),
      .a3_buf_rd	(),
      // Inputs
      .clk		(clk),
      .rst		(rst),
      .y_rd_data	(y_rd_data[15:0]),
      .a0_wr_req	(debug_logic_wr_req),
      .a0_bwr_req	(1'b0),
      .a0_rd_req	(debug_logic_rd_req),
      .a0_wr_data	(debug_logic_wr_data[15:0]),
      .a0_adr		(debug_logic_adr[11:0]),
      .a0_buf_empty	(1'b1),
      .a0_buf_wr_data	(),
      .a1_wr_req	(),
      .a1_bwr_req	(),
      .a1_rd_req	(),
      .a1_wr_data	(),
      .a1_adr		(),
      .a1_buf_empty	(),
      .a1_buf_wr_data	(),
      .a2_wr_req	(),
      .a2_bwr_req	(),
      .a2_rd_req	(),
      .a2_wr_data	(),
      .a2_adr		(),
      .a2_buf_empty	(),
      .a2_buf_wr_data	(),
      .a3_wr_req	(),
      .a3_bwr_req	(),
      .a3_rd_req	(),
      .a3_wr_data	(),
      .a3_adr		(),
      .a3_buf_empty	(),
      .a3_buf_wr_data	()
      ); 
     
   
   //////////////////////////////////////////////////////////////////////////////
   // Read registers
   wire [15:0] dpram_rd_data_a;
   wire [15:0] dpram_rd_data_b;

   reg[15:0] test_ctrl_reg = 16'b0;

   always @(*)
     begin
	case(y_adr)
	  12'hfff: begin y_rd_data =       vnum;                                                   end
	  12'h8ff: begin y_rd_data =       {13'h0, led_toggle};                                    end
	  12'h8fe: begin y_rd_data =       {1'h0, red_led_lvl};                                    end
	  12'h8fd: begin y_rd_data =       {1'h0, green_led_lvl};                                  end
	  12'h8fc: begin y_rd_data =       {1'h0, blue_led_lvl};                                   end
	  12'h8fb: begin y_rd_data =       {14'h0, rgb_cycle_speed_sel};                           end
	  12'h8fa: begin y_rd_data =       {14'h0, kr_speed_sel};                                  end
	  default: 
	    begin
	       y_rd_data = dpram_rd_data_b; 

	    end
	  
	endcase   
     end

   ///////////////////////////////////////////////////////////////////////////////
   // Write registers (not task regs)
   always @(posedge clk)
     begin
        // clear registers that automatically reset (e.g. one shots)  

	if(y_wr) 
	  case(y_adr)	    
	    12'h8ff: begin led_toggle <= y_wr_data[2:0];                                           end
	    12'h8fe: begin red_led_lvl <= y_wr_data[14:0];                                         end
	    12'h8fd: begin green_led_lvl <= y_wr_data[14:0];                                       end
	    12'h8fc: begin blue_led_lvl <= y_wr_data[14:0];                                        end
	    12'h8fb: begin rgb_cycle_speed_sel <= y_wr_data[1:0];                                  end
	    12'h8fa: begin kr_speed_sel <= y_wr_data[1:0];                                         end
	  endcase
     end // always @ (posedge clk)
   
   wire [15:0] dpram_wr_data_a = 16'b0;
   wire        dpram_wr_a = 1'b0;
   wire [11:0] dpram_addr_a = 12'b0;
   
   // DPRAM
   DPRAM_2048_16 DPRAM_2048_16_0
     (
      // Outputs
      .douta(dpram_rd_data_a),
      .doutb(dpram_rd_data_b),
      // Inputs
      .ena(1'b1),
      .enb(1'b1),
      .addra(dpram_addr_a),
      .addrb(y_adr[10:0]),
      .clka(clk),
      .clkb(clk),
      .dina(dpram_wr_data_a),
      .dinb(y_wr_data),
      .wea(dpram_wr_a),
      .web(y_wr & (y_adr[11]==0))
      ); 


endmodule

// For emacs verilog-mode
// Local Variables:
// verilog-library-directories:("." "../ft232r_proc_buffered/" "../crs_master/" "../../ipcores/DPRAM_2048_16/")
// End:
