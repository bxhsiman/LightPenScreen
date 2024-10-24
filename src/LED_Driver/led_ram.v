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

    // 用于锁存的寄存器
    reg [3:0] data_reg;
    reg [2:0] bin_row_reg;
    reg [2:0] bin_col_reg;

    // 延迟的we信号，用于检测上升沿和下降沿
    reg we_d; 

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

    // 延迟we信号，用于检测上升沿和下降沿
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            we_d <= 1'b0;
        end else begin
            we_d <= we;
        end
    end

    // 在we的上升沿锁存地址和数据
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            data_reg <= 4'd0;
            bin_row_reg <= 3'd0;
            bin_col_reg <= 3'd0;
        end else if (~we_d && we) begin  // 检测we的上升沿
            data_reg <= data;
            bin_row_reg <= onehot_to_bin(addr_row);
            bin_col_reg <= onehot_to_bin(addr_col);
        end
    end

    // 在we的下降沿写入数据
    always @(posedge clk or negedge rst_n) begin
        integer i, j;  // 将变量声明移动到这里
        if (~rst_n) begin
            led_data <= 4'b0;
            // 初始化 RAM
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    ram[i][j] <= 4'b0000;  // 初始化为 0
                end
            end
        end else begin
            if (we_d && ~we) begin  // 检测we的下降沿
                ram[bin_row_reg][bin_col_reg] <= data_reg;  // 写入锁存的数据和地址
            end
            // 读取当前地址的数据
            led_data <= ram[bin_row_reg][bin_col_reg];
        end
    end

endmodule
