module HandWriteScreen (
	input clk,
	input [31:0] data,
	output reg [7:0] cat,
	output reg [7:0] seg 
	);
	
	hex_display hex_display_inst (
		.clk(clk),
		.data(data),
		.cat(cat),
		.seg(seg)
	);

endmodule
	