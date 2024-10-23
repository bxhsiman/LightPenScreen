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
	assign we_n = we; //信号需反转-fortest

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
	wire [2:0] state;
	wire rst_ok;

	// 实例化 st 模块，并连接信号
	st st_inst (
		.clk(clk),
		.rst(btn0_o),
		.state_change(btn1_o),
		.rst_ok(rst_ok),
		.state(state)
	);

	// 定义内部寄存器 fortest
	reg [31:0] data_value;
	reg [7:0] seg_en; 
	reg [31:0] rst_cnt; //重启计数器
    reg [1:0] rst_seg_state; //段码状态

	//数码管状态机 TBD 抽离到另一个部分
	always @(posedge clk) begin
		case (state)
			`RST: begin
				// 2HZ闪烁
				// 全红 全绿 两次闪烁
                rst_cnt <= rst_cnt + 1;
                if (rst_cnt >= `CLOCK_FREQ) begin
                    rst_cnt <= 0;
                    rst_seg_state <= rst_seg_state + 1;
                end
				case (rst_seg_state) 
					2'b00, 3'b01: begin
						data_value <= 32'h8888_8888;
						seg_en <= 8'b1111_1111;
					end
					2'b10,2'b11: begin
						data_value <= 32'h8888_8888;
						seg_en <= 8'b0000_0000;
					end
				endcase
				data_value <= 32'h8888_8888;
			end
			`SLEEP: begin
				rst_cnt <= 0;
				rst_seg_state <= 0;
				data_value <= 32'hAAA0_0000;
				seg_en <= 8'b1110_0000;
			end
			`LIGHT: begin
				data_value <= 32'h0000_0002;
			end
			`DRAW: begin
				data_value <= 32'h0000_0003;
			end
			`WRITE: begin
				data_value <= 32'h0000_0004;
			end
			`ERASE: begin
				data_value <= 32'h0000_0005;
			end
			`COLOR: begin
				data_value <= 32'h0000_0006;
			end
			`STOP: begin
				data_value <= 32'h0000_0007;
			end
			default: begin
				data_value <= 32'hFFFF_FFFF;
			end

		endcase
	end

	// 实例化 hex_display 模块，并连接信号
	hex_display hex_display_inst (
		.clk(clk),
		.data(data_value),
		.cat(cat_o),
		.seg(seg_o),
		.enable(seg_en)
	);
	
	// 实例化 led_driver 模块，并连接信号
	led_driver led (
		.clk(clk),
		.rst_n(rst_n),
		.state(state),
		.rst_ok(rst_ok),
		.we(we_n_o),
		.output_row(output_row),
		.output_col_r(output_col_r),
		.output_col_g(output_col_g)

		,.ram_data_o(test_led[4:1])
	);

	
	assign test_led[0] = we_n;
endmodule
