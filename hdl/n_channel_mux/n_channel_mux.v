// Aaron Fienberg
// August 2020
//
// Parameters: N inputs, input-width, selector width 
//
// Inputs: N input-width width signals 
//         output selector
// Output: One input-width wide signal 
//         equal to the selected input channel
//
// Purely combinational logic

module n_channel_mux #(parameter N_INPUTS = 8,
	                     parameter INPUT_WIDTH = 22,
	                     parameter SEL_WIDTH = 5)

(
	input[N_INPUTS*INPUT_WIDTH-1:0] in,
	input[SEL_WIDTH-1:0] sel,
	output[INPUT_WIDTH-1:0] out
);

assign out = in >> INPUT_WIDTH*sel;

endmodule