`include "st_state.v"
`include "system_para.v"

module led_ram (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）

    input wire [3:0] state,    // 状态机状态

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

    // 辅助变量
    reg [7:0] col_buffer;        // 列地址缓冲区
    reg [2:0] row_buffer;        // 行地址缓冲区
    reg [3:0] data_buffer;       // 数据缓冲区
    reg [31:0] draw_timer;       // DRAW 状态计时器
    reg buffer_empty;            // 缓冲区是否为空
    reg buffer_full;             // 缓冲区是否已满

    // we 边沿检测
    reg we_d;
    wire we_edge;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            we_d <= 1'b0;
        else
            we_d <= we;
    end
    assign we_edge = ~we_d && we;  // 检测 we 上升沿

    // 将 one-hot 编码转换为二进制编码
    function [2:0] onehot_to_bin;
        input [7:0] onehot;
        integer k;
        begin
            onehot_to_bin = 3'd0;  // 默认为 0
            for (k = 0; k < 8; k = k + 1) begin
                if (onehot[k] == 1'b1)
                    onehot_to_bin = k[2:0];
            end
        end
    endfunction

    wire [2:0] bin_row, bin_col;
    assign bin_row = onehot_to_bin(addr_row);
    assign bin_col = onehot_to_bin(addr_col);

    // 状态寄存器，用于检测状态变化
    reg [3:0] state_d;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state_d <= 4'd0;
        else
            state_d <= state;
    end

    // RAM操作
    always @(posedge clk or negedge rst_n) begin
        integer i, j;
        if (~rst_n) begin
            // 异步复位，清空 RAM 和其他变量
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    ram[i][j] <= 4'b0;
                end
            end
            col_d <= 3'd0;
            row_d <= 3'd0;
            // 清空缓冲区和计时器
            col_buffer   <= 8'd0;
            row_buffer   <= 3'd0;
            data_buffer  <= 4'd0;
            draw_timer   <= 32'd0;
            buffer_empty <= 1'b1;
            buffer_full  <= 1'b0;
        end else begin
            // 首先处理状态变化
            if (state_d != state) begin
                // 状态变化
                if (state != `DRAW) begin
                    // 如果状态变化到非 DRAW 状态，清空 RAM（根据需要）
                    for (i = 0; i < 8; i = i + 1) begin
                        for (j = 0; j < 8; j = j + 1) begin
                            ram[i][j] <= 4'b0;
                        end
                    end
                end
                col_d <= 3'd0;
                row_d <= 3'd0;
                // 状态切换时，清空缓冲区和计时器
                col_buffer   <= 8'd0;
                row_buffer   <= 3'd0;
                data_buffer  <= 4'd0;
                draw_timer   <= 32'd0;
                buffer_empty <= 1'b1;
                buffer_full  <= 1'b0;
            end else begin
                // 状态未变化
                if (state == `DRAW) begin
                    // DRAW 状态下
                    if (we_edge) begin
                        // 检测到 we 上升沿
                        if (buffer_empty) begin
                            // 缓冲区为空，记录行地址和数据
                            row_buffer   <= bin_row;
                            data_buffer  <= data;
                            col_buffer[bin_col] <= 1'b1;
                            buffer_empty <= 1'b0;
                            buffer_full  <= &col_buffer;  // 检查缓冲区是否已满
                            draw_timer   <= 32'd0;
                        end else begin
                            if (bin_row == row_buffer) begin
                                // 行地址相同，继续记录列地址
                                col_buffer[bin_col] <= 1'b1;
                                buffer_full  <= &col_buffer;  // 更新缓冲区满标志
                                draw_timer   <= 32'd0;
                            end else begin
                                // 行地址不同，忽略
                            end
                        end
                    end else begin
                        // 未检测到 we 上升沿
                        if (!buffer_empty) begin
                            draw_timer <= draw_timer + 1;
                            if (draw_timer >= `CLOCK_FREQ - 1) begin
                                // 超过 1 秒未检测到新的 we 上升沿，执行写入操作
                                integer col;
                                for (col = 0; col < 8; col = col + 1) begin
                                    if (col_buffer[col]) begin
                                        ram[row_buffer][col] <= data_buffer;
                                        // 更新 col_d 和 row_d
                                        col_d <= col[2:0];
                                        row_d <= row_buffer;
                                    end
                                end
                                // 清空缓冲区和计时器
                                col_buffer   <= 8'd0;
                                data_buffer  <= 4'd0;
                                buffer_empty <= 1'b1;
                                buffer_full  <= 1'b0;
                                draw_timer   <= 32'd0;
                            end
                        end
                    end

                    // 缓冲区已满，立即写入
                    if (buffer_full && !buffer_empty) begin
                        integer col;
                        for (col = 0; col < 8; col = col + 1) begin
                            if (col_buffer[col]) begin
                                ram[row_buffer][col] <= data_buffer;
                                // 更新 col_d 和 row_d
                                col_d <= col[2:0];
                                row_d <= row_buffer;
                            end
                        end
                        // 清空缓冲区和计时器
                        col_buffer   <= 8'd0;
                        data_buffer  <= 4'd0;
                        buffer_empty <= 1'b1;
                        buffer_full  <= 1'b0;
                        draw_timer   <= 32'd0;
                    end
                end else begin
                    // 非 DRAW 状态下
                    if (we_d && ~we) begin
                        // 检测到 we 下降沿（非 DRAW 状态下写入 RAM）
                        ram[bin_row][bin_col] <= data;
                        col_d <= bin_col;
                        row_d <= bin_row;
                    end
                end
            end
        end
    end

    // 显存读取
    always @(*) begin
        led_data = ram[onehot_to_bin(addr_row)][onehot_to_bin(addr_col)];
    end

endmodule