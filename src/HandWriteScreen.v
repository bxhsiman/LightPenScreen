module HandWriteScreen (
	input clk,
	input rst,

	output wire [7:0] cat_o,
	output wire [7:0] seg_0,

	output wire [7:0] output_row,
	output wire [7:0] output_col_r,
	output wire [7:0] output_col_g
	);

	assign rst_n = ~rst;

	// 定义内部寄存器
	reg [31:0] data_value = 32'h0000_0001;

	// 实例化 hex_display 模块，并连接信号
	hex_display hex_display_inst (
		.clk(clk),
		.data(data_value),
		.cat(cat_o),
		.seg(seg_0)
	);

	// 实例化 led_driver 模块，并连接信号
	led_driver led (
		.clk(clk),
		.rst_n(rst_n),
		.output_row(output_row),
		.output_col_r(output_col_r),
		.output_col_g(output_col_g)
	);

endmodule
