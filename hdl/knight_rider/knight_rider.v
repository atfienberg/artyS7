// Aaron Fienberg
// Sept 2019
//
// module to generate a knight rider LED pattern

module knight_rider (
	input clk,
	input rst,
	input[1:0] period_sel,
	output reg[3:0] y=0
	);

// period select mux
reg[31:0] ticks_per_state;
always @(*) begin
  case (period_sel)
    0: begin
      ticks_per_state = 32'd5_000_000;	
    end
    1: begin
      ticks_per_state = 32'd10_000_000;	
    end
    2: begin
      ticks_per_state = 32'd20_000_000;	
    end
    3: begin
      ticks_per_state = 32'd40_000_000;	
    end
    default: begin
      ticks_per_state = 32'd10_000_000;
    end
  endcase
end

// counter
reg[31:0] cnt=0;

localparam 
S_LEFT = 1'd0,
S_RIGHT = 1'd1;
reg fsm=S_LEFT;

always @(posedge clk) begin
	if (rst || y == 0) begin
		cnt <= 0;
		y <= 1;
		fsm <= S_LEFT;
	end

	else begin
		cnt <= cnt + 1;
		if (cnt >= ticks_per_state - 1) begin
			cnt <= 0;
			case (fsm) 
				S_LEFT: begin
					y <= y << 1;
					if (y == 4'h4) begin
						fsm <= S_RIGHT;
					end
				end
				S_RIGHT: begin
					y <= y >> 1;
					if (y == 4'h2) begin
						fsm <= S_LEFT;
					end
				end
				default: begin
					cnt <= 0;
					y <= 1;
					fsm <= S_LEFT;
				end
			endcase
		end
	end
end

endmodule