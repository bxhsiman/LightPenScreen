module HandWriteScreen (
	input clk,
	output wire [7:0] cat_o,
	output wire [7:0] seg_0
	);

	// 定义内部寄存器
	reg [31:0] data_value = 32'h23456789;

	// 实例化 hex_display 模块，并连接信号
	hex_display hex_display_inst (
		.clk(clk),
		.data(data_value),
		.cat(cat_o),
		.seg(seg_0)
	);

endmodule
