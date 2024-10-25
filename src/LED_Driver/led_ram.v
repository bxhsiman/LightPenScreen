`include "st_state.v"
`include "system_para.v"

`include "st_state.v"
`include "system_para.v"

module led_ram (
    input wire clk,            // Clock input
    input wire rst_n,          // Active low reset

    input wire clean,          // 清屏信号

    input wire [3:0] state,    // State machine state

    input wire [3:0] data,     // LED data input
    input wire [7:0] addr_row, // One-hot encoded row address input
    input wire [7:0] addr_col, // One-hot encoded col address input
    input wire we,             // Write enable

    output reg [3:0] led_data, // LED data output 

    output reg [2:0] col_d,    // Last written column address
    output reg [2:0] row_d     // Last written row address

);

    // LED RAM
    reg [3:0] ram [0:63];

    //划亮用寄存器
    reg [7:0] col_buffer;      
    reg [2:0] row_buffer;      
    reg [3:0] data_buffer;     
    reg [25:0] draw_timer;     // 延迟触发计时器
    reg buffer_empty;          
    reg buffer_full;           

    // we边沿检测
    reg we_d;
    wire we_edge;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            we_d <= 1'b0;
        else
            we_d <= we;
    end
    assign we_edge = ~we_d && we;

    //clean 边沿检测
    reg clean_d;
    wire clean_edge;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            clean_d <= 1'b0;
        else
            clean_d <= clean;
    end
    assign clean_edge = ~clean_d && clean;
    
    // one-hot 二进制转换
    function [2:0] onehot_to_bin;
        input [7:0] onehot;
        begin
            case (onehot)
                8'b0000_0001: onehot_to_bin = 3'd0;
                8'b0000_0010: onehot_to_bin = 3'd1;
                8'b0000_0100: onehot_to_bin = 3'd2;
                8'b0000_1000: onehot_to_bin = 3'd3;
                8'b0001_0000: onehot_to_bin = 3'd4;
                8'b0010_0000: onehot_to_bin = 3'd5;
                8'b0100_0000: onehot_to_bin = 3'd6;
                8'b1000_0000: onehot_to_bin = 3'd7;
                default:       onehot_to_bin = 3'd0;
            endcase
        end
    endfunction

    wire [2:0] bin_row, bin_col;
    assign bin_row = onehot_to_bin(addr_row);
    assign bin_col = onehot_to_bin(addr_col);

    // we上升沿地址锁存
    reg [2:0] bin_row_d, bin_col_d;
    always @(posedge clk) begin
        if (we_edge) begin
            bin_row_d <= bin_row;
            bin_col_d <= bin_col;
        end
    end

    // 状态切换检测
    reg [3:0] state_d;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state_d <= 4'd0;
        else
            state_d <= state;
    end

    // RAM 操作
    always @(posedge clk) begin
        // 清屏操作
        if (state == `ERASE && clean_edge) begin
            integer i;
            for(i=0;i<64;i=i+1) begin
                ram[i] <= 4'b0;
            end
        end 
        // 状态切换
        else if (state_d != state) begin
            col_d <= 3'd0;
            row_d <= 3'd0;

            col_buffer   <= 8'd0;
            row_buffer   <= 3'd0;
            data_buffer  <= 4'd0;
            draw_timer   <= 26'd0;
            buffer_empty <= 1'b1;
            buffer_full  <= 1'b0;

        end else begin
            if (state == `DRAW) begin
                if (we_edge) begin
                    if (buffer_empty) begin
                        row_buffer   <= bin_row;
                        data_buffer  <= data;
                        col_buffer[bin_col] <= 1'b1;
                        buffer_empty <= 1'b0;
                        buffer_full  <= &col_buffer;
                        draw_timer   <= 26'd0;
                    end else begin
                        if (bin_row == row_buffer) begin
                            col_buffer[bin_col] <= 1'b1;
                            buffer_full  <= &col_buffer;
                            draw_timer   <= 26'd0;
                        end
                    end
                end else begin
                    if (!buffer_empty) begin
                        draw_timer <= draw_timer + 1;
                        if (draw_timer >= `CLOCK_FREQ - 1) begin
                            integer col;
                            for (col = 0; col < 8; col = col + 1) begin
                                if (col_buffer[col]) begin
                                    ram[{row_buffer, col[2:0]}] <= data_buffer;
                                    col_d <= col[2:0];
                                    row_d <= row_buffer;
                                end
                            end
                            col_buffer   <= 8'd0;
                            data_buffer  <= 4'd0;
                            buffer_empty <= 1'b1;
                            buffer_full  <= 1'b0;
                            draw_timer   <= 26'd0;
                        end
                    end
                end
            end else begin
                // 其他状态下的写操作
                if (we_d && ~we) begin // We 下降沿写入
                    ram[{bin_row_d, bin_col_d}] <= data;
                    col_d <= bin_row_d;
                    row_d <= bin_col_d;
                end
            end
        end
    end


    // 读取RAM
    always @(posedge clk) begin
        led_data <= ram[{bin_row, bin_col}];
    end

endmodule
