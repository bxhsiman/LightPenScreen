// LED点阵驱动模块 TOP
module led_driver (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）

    output wire [7:0] output_row,
    output wire [7:0] output_col_r,
    output wire [7:0] output_col_g

    // for test
    , output reg [3:0] ram_data
    , input wire we
    , input wire [3:0] data
);

    parameter led_on = 255;
    parameter led_scan = 128;
    parameter led_off = 0;
    
    reg [7:0] duty;
    wire [7:0] led_row;
    wire [7:0] led_col;
    wire pwm_out;


    // PWM亮度调整模块
    pwm_generator pwm_generator_inst (
        .clk(clk),
        .rst_n(rst_n),
        .duty(duty),
        .pwm_out(pwm_out)
    );

    // LED扫描器
    scan_driver scan_driver_inst (
        .clk(clk),
        .rst_n(rst_n),
        .led_row(led_row),
        .led_col(led_col)
    );

    // 实例化 LED 显存
    // wire [3:0] ram_data;
    // wire we;
    // wire [3:0] data;

    led_ram led_ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data(4'b0),
        .addr_row(led_row),
        .addr_col(led_col),
        .we(1'b0),
        .led_data(ram_data)
    );

    //显存内容解析
    reg col_r_en;
    reg col_g_en;
    always @(led_row or led_col) begin
        if (ram_data[3] == 1'b1) begin
            duty <= led_on;
            col_r_en <= ram_data[1];
            col_g_en <= ram_data[2];
        end
        else begin
            duty <= led_scan;
            col_g_en <= 1'b0;
            col_r_en <= 1'b1;
        end
    end

    assign output_row = led_row;
    assign output_col_r = col_r_en & pwm_out;
    assign output_col_g = col_g_en & pwm_out;

endmodule