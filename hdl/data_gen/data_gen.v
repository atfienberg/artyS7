// Aaron Fienberg
// August 2020
//
// Generate fake ADC data and discriminator data
// both will be ramp patterns 
//
// for mDOM waveform acquisition firmware development 
//
// 12-bit ADC data
// 8-bit discrimiantor data
//

module data_gen #(parameter[11:0] P_ADC_RAMP_START = 0,
                  parameter[7:0]  P_DISCR_RAMP_START = 0)
(
  input clk,
  input rst,
  output reg[11:0] adc_stream = P_ADC_RAMP_START,
  output reg[7:0] discr_stream = P_DISCR_RAMP_START
);

// register synchronous reset
(* DONT_TOUCH = "true" *) reg i_rst = 0;
always @(posedge clk) begin
  i_rst <= rst;
end

always @(posedge clk) begin
  if (i_rst) begin
    adc_stream <= P_ADC_RAMP_START;
    discr_stream <= P_DISCR_RAMP_START;
  end

  else begin
    adc_stream <= adc_stream + 1;
    discr_stream <= discr_stream + 1;
  end
end

endmodule
