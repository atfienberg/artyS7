// Aaron Fienberg
// April 2020
//
// Cycle through RGB on an Arty S7 LED
//

module light_show #(parameter[31:0] INCREMENT = 4,
	            parameter[31:0] INCS_PER_STATE = 2000)
(
  input clk,
  input rst,
  input[1:0] period_sel,
  output reg[14:0] red = 0,
  output reg[14:0] green = 0,
  output reg[14:0] blue = 0
);

localparam[14:0] MAX_BRIGHNESS = INCREMENT*INCS_PER_STATE;

// period select mux 
reg[31:0] ticks_per_increment;
always @(*) begin
  case (period_sel)
    0: begin
      ticks_per_increment = 32'd25_000;	
    end
    1: begin
      ticks_per_increment = 32'd75_000;	
    end
    2: begin
      ticks_per_increment = 32'd500_000;	
    end
    3: begin
      ticks_per_increment = 32'd1_000_000;	
    end
    default: begin
      ticks_per_increment = 32'd500_000;
    end
  endcase
end

reg[31:0] cnt = 0;
// n increments
reg[31:0] incs = 0;

localparam[2:0] S_IDLE = 0,
                S_INCRED_DECBLUE = 1,
                S_INCGREEN_DECRED = 2,
                S_INCBLUE_DECGREEN = 3;

reg[2:0] fsm = S_IDLE; 

always @(posedge clk) begin
  if (rst) begin
    cnt <= 32'd0;
    incs <= 32'd0;
    red <= 15'd0;
    green <= 15'd0;
    blue <= 15'd0;
    fsm <= S_IDLE;
  end

  else begin
    cnt <= cnt + 32'b1;
    
    case(fsm)
      S_IDLE: begin
      	// start the pattern 
      	cnt <= 32'd0;
      	incs <= 32'd0;
      	red <= 15'd0;
      	green <= 15'd0;
      	blue <= MAX_BRIGHNESS;
      	fsm <= S_INCRED_DECBLUE;
      end

      S_INCRED_DECBLUE: begin
        if (cnt >= ticks_per_increment - 1) begin
          red <= red + INCREMENT;
	  green <= 15'b0;
          blue <= blue - INCREMENT;

	  cnt <= 32'b0;          
          incs <= incs + 32'b1;          
          if (incs >= INCS_PER_STATE - 1) begin
            incs <= 32'b0;
            fsm <= S_INCGREEN_DECRED;
          end        
        end
      end

      S_INCGREEN_DECRED: begin
        if (cnt >= ticks_per_increment - 1) begin
          red <= red - INCREMENT;
          green <= green + INCREMENT;
          blue <= 15'b0;
	
	  cnt <= 32'b0;          
          incs <= incs + 32'b1;          
          if (incs >= INCS_PER_STATE - 1) begin
            incs <= 32'b0;
            fsm <= S_INCBLUE_DECGREEN;
          end        
        end
      end 

      S_INCBLUE_DECGREEN: begin
        if (cnt >= ticks_per_increment - 1) begin
          red <= 15'b0;
          green <= green - INCREMENT;
          blue <= blue + INCREMENT;
	
	  cnt <= 32'b0;          
          incs <= incs + 32'b1;          
          if (incs >= INCS_PER_STATE - 1) begin
            incs <= 32'b0;
            fsm <= S_INCRED_DECBLUE;
          end        
        end
      end

      default: begin
      	fsm <= S_IDLE;
      	cnt <= 32'b0;
      	incs <= 32'b0;
      	red <= 15'b0;
      	green <= 15'b0;
      	blue <= 15'b0;
      end

    endcase
  end
end

 
endmodule

