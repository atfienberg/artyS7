// Aaron Fienberg
// April 2020
//
// pulse-width modulated signal to drive the RGB LEDs 
// on the ARTY S7 board
//
// n_high input controls the duty cycle
// 


module pwm #(parameter[31:0] PERIOD=31'h10000)  
(
  input clk,
  input rst,
  input[14:0] n_high,
  output reg y = 0
);

wire[31:0] n_low = PERIOD - n_high;  

reg[31:0] cnt = 0;

always @(posedge clk) begin
  if (rst) begin
    y <= 0;
    cnt <= 0;    
  end

  else begin
    y <= 0;
    cnt <= cnt + 1;

    if (cnt >= PERIOD - 1) begin
      cnt <= 0;
    end

    else if (cnt >= n_low - 1) begin
      y <= 1;
    end
  end
end

endmodule