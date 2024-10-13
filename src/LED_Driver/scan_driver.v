module scan_driver (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）
    
    output reg [7:0] led_row,   // LED 行扫描输出
    output reg [7:0] led_col    // LED 列扫描输出 
);

parameter SCAN_TIME = 32'd2550;  // 扫描周期，clk计, 10个周期

// 定义内部寄存器
reg [31:0] timer;          //时间计数器
reg [7:0] col;
reg [7:0] row;

initial begin // 仿真用初始化
    timer <= 32'd0;
    led_row <= 8'd1;   
    led_col <= 8'd1; 
end

// 扫描逻辑
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        timer <= 32'd0;
        led_row <= 8'd1;   
        led_col <= 8'd1;    
    end
    else begin
        if (timer < SCAN_TIME) begin
            timer <= timer + 1;
        end
        else begin
            timer <= 32'd0;
            if (led_col >= 8'b1000_000) begin
                led_col <= 8'd1;
                if (led_row >= 8'b1000_000) begin
                    led_row <= 8'd1;
                end
                else begin
                    led_row <= led_row << 1;
                end
            end
            else begin
                led_col <= led_col << 1;
            end
        end
    end

end


endmodule
