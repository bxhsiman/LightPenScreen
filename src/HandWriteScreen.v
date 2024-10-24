`include "st_state.v"
module HandWriteScreen (
	input clk,
	input rst,

	input btn0, // 系统初始化用
	input btn1, // 系统状态切换

	input wire we, // 光笔输入信号

	output wire [7:0] cat_o,
	output wire [7:0] seg_o,

	output wire [7:0] output_row,
	output wire [7:0] output_col_r,
	output wire [7:0] output_col_g

	//for test
	, output wire [15:0] test_led
	
	);

	assign rst_n = ~rst;
	assign we_n = we; //三极管信号需要反转

	wire we_n_o;
	// 光笔消抖模块
	btn we_inst (
		.clk(clk),
		.rst_n(rst_n),
		.button_in(we_n),
		.button_out(we_n_o)
	);


	wire btn0_o, btn1_o; 
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

	// st 模块信号
	wire [2:0] state;      //表层状态机
	wire [2:0] state_deep; //深层状态机

	// 实例化 st 模块，并连接信号
	st st_inst (
		.clk(clk),
		.rst(btn0_o),
		.state_change(btn1_o),
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
		
    	.cat(cat_o),        
    	.seg(seg_o)        
	);
	
	// 实例化 led_driver 模块
	wire [2:0] row_d, col_d;
	led_driver led (
		.clk(clk),
		.rst_n(rst_n),
		.state(state),
		.state_deep(state_deep),
		.we(we_n_o),
		.output_row(output_row),
		.output_col_r(output_col_r),
		.output_col_g(output_col_g),

		.row_d(row_d),
		.col_d(col_d)

		,.ram_data_o(test_led[4:1])
	);

	assign test_led[0] = we_n;
endmodule
