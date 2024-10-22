module led_ram (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）
    
    input wire [3:0] data,     // LED 数据输入
    input wire [7:0] addr_row, // one-hot 编码的 row 地址输入
    input wire [7:0] addr_col, // one-hot 编码的 col 地址输入
    input wire we,             // 写使能

    output reg [3:0] led_data  // LED 数据输出
);

    // 定义内部 RAM
    reg [3:0] ram [7:0][7:0];   // 8x8x4bit RAM

    // 延迟we信号
    reg we_d;

    // 将 one-hot 编码转换为二进制编码的函数
    function [2:0] onehot_to_bin;
        input [7:0] onehot;
        integer k;
        begin
            onehot_to_bin = 3'd0;  // 默认为 0
            for (k = 0; k < 8; k = k + 1) begin
                if (onehot[k]) begin
                    onehot_to_bin = k[2:0];
                end
            end
        end
    endfunction

    // 延迟 we 信号，用于检测上升沿
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            we_d <= 1'b0;
        end else begin
            we_d <= we;
        end
    end

    // 读写逻辑
    always @(posedge clk or negedge rst_n) begin
        integer i, j; 
        if (~rst_n) begin
            led_data <= 4'b0;
            // 初始化 RAM
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    ram[i][j] <= 4'b0000;  // 初始化为 0
                end
            end
        end else begin
            // 检测 we 的上升沿
            if (we & ~we_d) begin
                ram[onehot_to_bin(addr_row)][onehot_to_bin(addr_col)] <= data;      // 在 we 上升沿写入数据
            end else begin
                led_data <= ram[onehot_to_bin(addr_row)][onehot_to_bin(addr_col)];  // 读出数据
            end
        end
    end

endmodule
