// LED 显存
// 每个LED 4bit [是否存储][G][R][]

module led_ram (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）
    
    input wire [3:0] data,     // LED 数据输入
    input wire [2:0] addr_row, // 地址输入row (3 bit to index 8 rows)
    input wire [2:0] addr_col, // 地址输入col (3 bit to index 8 cols)
    input wire we,             // 写使能

    output reg [3:0] led_data  // LED 数据输出
);

    // 定义内部寄存器
    reg [3:0] ram [7:0][7:0];   // 8x8x4bit RAM

    integer i, j; 

    // 读写逻辑
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            led_data <= 4'b0;
            // 初始化 RAM
            for (i = 0; i < 8; i = i + 1) begin
                for (j = 0; j < 8; j = j + 1) begin
                    ram[i][j] <= 4'b0000;  // 初始化为 0 for test
                end
            end
        end
        else begin
            if (we) begin
                ram[addr_row][addr_col] <= data;
            end
            led_data <= ram[addr_row][addr_col];  // 读取 RAM 的数据到输出
        end
    end

endmodule
