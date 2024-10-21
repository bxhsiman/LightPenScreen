// LED 显存
// 每个LED 4bit [是否存储][G][R][未用]
// TBD: 显存空间占用大，后续可加入译码器减少消耗
module led_ram (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）
    
    input wire [3:0] data,     // LED 数据输入
    input wire [7:0] addr_row, // one-hot 编码的 row 地址输入
    input wire [7:0] addr_col, // one-hot 编码的 col 地址输入
    input wire we,             // 写使能

    output reg [3:0] led_data  // LED 数据输出
);

    // 定义内部寄存器
    reg [3:0] ram [7:0][7:0];   // 8x8x4bit RAM

    integer i, j;

    // 将 one-hot 编码转换为二进制编码的函数
    function [2:0] onehot_to_bin;
        input [7:0] onehot;
        integer k;
        begin
            onehot_to_bin = 0;  // 默认为 0
            for (k = 0; k < 8; k = k + 1) begin
                if (onehot[k] == 1'b1)
                    onehot_to_bin = k[2:0];
            end
        end
    endfunction

    // 读写逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            led_data <= 4'b0;
            // 初始化 RAM
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    ram[i][j] <= 4'b0000;  // 初始化为 0
                end
            end
        end
        else begin
            // 将 one-hot 编码的地址转换为二进制索引
            reg [2:0] bin_row;
            reg [2:0] bin_col;
            bin_row = onehot_to_bin(addr_row);  // 转换 row 地址
            bin_col = onehot_to_bin(addr_col);  // 转换 col 地址

            if (we) begin
                ram[bin_row][bin_col] <= data;  // 写数据
            end
            led_data <= ram[bin_row][bin_col];  // 读取数据
        end
    end

endmodule
