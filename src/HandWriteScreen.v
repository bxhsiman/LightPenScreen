`include "st_state.v"
module HandWriteScreen (
	input clk,
	input rst,  // 复位 待删除

	input btn0, // 系统初始化用
	input btn1, // 系统状态切换
	input btn2, // 系统颜色切换

	input btn7, // 清屏确认用

	input wire we, // 光笔输入信号

	// 数码管显示
	output wire [7:0] cat_o,
	output wire [7:0] seg_o,
	
	// LED显示
	output wire [7:0] output_row,
	output wire [7:0] output_col_r,
	output wire [7:0] output_col_g,

	// LCD显示
	output wire [7:0] data_o,
	output wire reset_n_o,
	output wire cs_n_o,
	output wire wr_n_o,
	output wire rd_n_o,
	output wire a0_o

	//for test
	, output wire [15:0] test_led
	
	);

	assign rst_n = ~rst;
	assign we_n = ~we; //三极管信号需要反转

	test_lcd test_lcd_inst (
		.clk(clk),
		.reset(rst),
		.data(data_o),
		.reset_n(reset_n_o),
		.cs_n(cs_n_o),
		.wr_n(wr_n_o),
		.rd_n(rd_n_o),
		.a0(a0_o)
	);

	wire btn0_o, btn1_o, btn2_o, btn7_o; 

	// 按钮消抖模块
	btn btn0_inst (
		.clk(clk),
		.rst_n(rst_n),
		.button_in(btn0),
		.button_out(btn0_o)
	);

	btn btn1_inst (
		.clk(clk),
		.rst_n(rst_n),
		.button_in(btn1),
		.button_out(btn1_o)
	);

	btn btn2_inst (
		.clk(clk),
		.rst_n(rst_n),
		.button_in(btn2),
		.button_out(btn2_o)
	);

	btn btn7_inst (
		.clk(clk),
		.rst_n(rst_n),
		.button_in(btn7),
		.button_out(btn7_o)
	);

	// st 模块信号
	wire [3:0] state;      //表层状态机
	wire [3:0] state_deep; //深层状态机

	// 实例化 st 模块，并连接信号
	st st_inst (
		.clk(clk),
		.rst(btn0_o),
		.state_change(btn1_o),
		.state_color(btn2_o),
		.state(state),
		.state_deep(state_deep)
	);

	// 实例化 seg_driver 模块
	seg_driver seg_inst (
		.clk(clk),
		.state(state),
    	.state_deep(state_deep),
		
		// 点亮mode功能所需信号
		.row_d(row_d),
		.col_d(col_d),
		// 颜色选择
		.color(color),
    	.cat(cat_o),        
    	.seg(seg_o)        
	);
	
	// 实例化 led_driver 模块
	wire [2:0] row_d, col_d;
	wire [1:0] color;
	led_driver led (
		.clk(clk),
		.rst_n(rst_n),
		.clean(btn7_o),
		.state(state),
		.state_deep(state_deep),
		.we(we_n),
		.output_row(output_row),
		.output_col_r(output_col_r),
		.output_col_g(output_col_g),

		.row_d(row_d),
		.col_d(col_d),

		.color(color)

		,.ram_data_o(test_led[4:1])
	);

	assign test_led[0] = we_n;
endmodule
