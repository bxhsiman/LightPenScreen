`include "led_para.v"

module scan_driver (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）
    
    output reg [7:0] led_row,  // LED 行扫描输出
    output reg [7:0] led_col   // LED 列扫描输出 
);

    // 定义内部寄存器
    reg [31:0] timer;          // 时间计数器
    reg [2:0] current_row;     // 当前扫描行
    reg [2:0] current_col;     // 当前扫描列
    
    reg [2:0] row_order [0:7];
    reg [2:0] col_order [0:7];
    
    integer i;

    initial begin // 仿真用初始化
        timer <= 32'd0;
        led_row <= 8'd1;   
        led_col <= 8'd1; 
        current_row <= 3'd0;
        current_col <= 3'd0;
        
        // 定义跳跃扫描顺序
        row_order[0] = 3'd0;
        row_order[1] = 3'd1;
        row_order[2] = 3'd3;
        row_order[3] = 3'd2;
        row_order[4] = 3'd6;
        row_order[5] = 3'd7;
        row_order[6] = 3'd5;
        row_order[7] = 3'd4;
        
        col_order[0] = 3'd0;
        col_order[1] = 3'd1;
        col_order[2] = 3'd3;
        col_order[3] = 3'd2;
        col_order[4] = 3'd6;
        col_order[5] = 3'd7;
        col_order[6] = 3'd5;
        col_order[7] = 3'd4;
    end

    // 扫描逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            timer <= 32'd0;
            led_row <= 8'b0000_0001;   // 默认选中第1行
            led_col <= 8'b0000_0001;   // 默认选中第1列
            current_row <= 3'd0;
            current_col <= 3'd0;
        end
        else begin
            if (timer < `SCAN_TIME) begin
                timer <= timer + 1;
            end
            else begin
                timer <= 32'd0;
                
                if (current_col < 3'd7) begin
                    current_col <= current_col + 1;
                end
                else begin
                    current_col <= 3'd0;  // 列扫描完成后重置列
                    // 切换到下一行
                    if (current_row < 3'd7) begin
                        current_row <= current_row + 1;
                    end
                    else begin
                        current_row <= 3'd0;  // 当所有行扫描完毕后重置行
                    end
                end
                
                // 设置行和列的输出
                led_row <= 8'b0000_0001 << row_order[current_row]; // 固定行
                led_col <= 8'b0000_0001 << col_order[current_col]; // 列逐个扫描
            end
        end
    end

endmodule
