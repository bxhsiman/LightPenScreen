
`include "st_state.v"
`include "system_para.v"

module seg_driver(
    input wire clk,

    input wire [2:0] state,
    input wire [2:0] state_deep,

    input wire [2:0] row_d,
    input wire [2:0] col_d,

    output wire [7:0] cat,        // 阴极选择      
    output wire [7:0] seg         // 段码输出   
);

	// 内部寄存器
	reg [31:0] seg_value; //段码显示
	reg [7:0] seg_en;      //段码使能


	//数码管组合逻辑
	always @(*) begin
        //默认值
        seg_value = 32'h0000_0000;
        seg_en = 8'b1111_1111;

		case (state)
			`RST: begin
                case(state_deep) 
                    `STATE_0, `STATE_2: begin
                        seg_value = 32'h8888_8888;
                        seg_en = 8'b1111_1111;
                    end
                    `STATE_1, `STATE_3: begin
                        seg_value = 32'h8888_8888;
                        seg_en = 8'b0000_0000;
                    end 
                endcase
			end
			`SLEEP: begin
                seg_value = 32'hAAA0_0000;
                seg_en = 8'b1110_0000;
			end
			`LIGHT: begin
				seg_value = {1'h1, 5'b0000_0,row_d, 5'b0000_0,col_d, 5'h0_0000};
                seg_en = 8'b1110_0000;
			end
			`DRAW: begin
				seg_value = 32'h2000_0000;
                seg_en = 8'b1000_0000;
			end
			`WRITE: begin
				seg_value = 32'h3000_0000;
                seg_en = 8'b1000_0000;
			end
			`ERASE: begin
				seg_value = 32'h4000_0000;
                seg_en = 8'b1111_1111;
			end
            `REVERSE: begin
                seg_value = 32'h5000_0000;
                seg_en = 8'b1000_0000;
            end
			`COLOR: begin
				seg_value = 32'h6000_0000;
                seg_en = 8'b1000_0000;
			end
			`STOP: begin
				seg_value = 32'h8000_0000;
                seg_en = 8'b1111_1111;
			end
			default: begin
				seg_value = 32'hFFFF_FFFF;
                seg_en = 8'b1111_1111;
			end

		endcase
	end

    // 实例化hex驱动
    hex_display hex_display_inst (
        .clk(clk),
        .data(seg_value),
        .cat(cat),
        .seg(seg),
        .enable(seg_en)
	);

endmodule