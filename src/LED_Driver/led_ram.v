module led_ram (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）

    input wire state,          // 状态机状态
    
    input wire [3:0] data,     // LED 数据输入
    input wire [7:0] addr_row, // one-hot 编码的 row 地址输入
    input wire [7:0] addr_col, // one-hot 编码的 col 地址输入
    input wire we,             // 写使能

    output reg [3:0] led_data,  // LED 数据输出 

    output reg [2:0] col_d,     // 刚写入的列地址
    output reg [2:0] row_d      // 刚写入的行地址

);

    // 定义内RAM
    reg [3:0] ram [7:0][7:0];   // 8x8x4bit RAM

    // 用于锁存的寄存器
    reg [3:0] data_reg;
    reg [2:0] bin_row_reg;
    reg [2:0] bin_col_reg;

    // 编码转换
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

    // state 切换检测
    reg [3:0] state_d;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            state_d <= 1'b0;
        end else begin
            state_d <= state;
        end
    end

    // we 上升沿检测
    reg we_d;
    always @(posedge clk) begin
        if (state_d != state) begin
            we_d <= 1'b0;
        end else
            we_d <= we;
    end

    // 在we的上升沿锁存地址和数据
    always @(posedge clk) begin
        if (state_d != state) begin
            data_reg <= 4'd0;
            bin_row_reg <= 3'd0;
            bin_col_reg <= 3'd0;
        end else if (~we_d && we) begin  // 检测we的上升沿
            data_reg <= data;
            bin_row_reg <= onehot_to_bin(addr_row);
            bin_col_reg <= onehot_to_bin(addr_col);
        end
    end

    // RAM操作
    always @(posedge clk) begin
        integer i, j;
        // STATE 变化的时候清空显存
        if (state_d != state) begin
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    ram[i][j] <= 4'b0;  // 初始化为 0
                end
            end
            col_d <= 3'd0;
            row_d <= 3'd0;
        end
        // WE下降沿写入数据
        else if (we_d && ~we) begin                  
            ram[bin_row_reg][bin_col_reg] <= data_reg; 
            col_d <= bin_col_reg;
            row_d <= bin_row_reg; 
        end
    end

    // 显存读取
    always @(*) begin
        led_data = ram[onehot_to_bin(addr_row)][onehot_to_bin(addr_col)];
    end


endmodule
