// LED点阵驱动模块

`include "include/st_state.v"
`include "include/system_para.v"

module led_driver (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）

    input wire [2:0] state,    // 状态机状态 //TBD
    output reg rst_ok,         // 复位完成信号 //回传状态机 TBD

    output reg [7:0] output_row,
    output reg [7:0] output_col_r,
    output reg [7:0] output_col_g

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

    reg [31:0] rst_cnt; //重启计数器
    reg [1:0] rst_led_state; //led状态

    // 输出-状态选择器
    always @(posedge clk) begin
        case (state)
            `STOP: begin
                output_row <= 8'h00;
                output_col_r <= 8'h00;
                output_col_g <= 8'h00;
            end
            `RST: begin
                // 全红 全绿 两次闪烁
                output_row <= 8'hff;
                if (rst_cnt > (`CLOCK_FREQ >> 1)) begin
                    rst_cnt <= 0;
                    rst_led_state = rst_led_state + 1;
                end
                rst_cnt <= rst_cnt + 1;

                case (rst_led_state)
                    2'b00, 2'b10: begin
                        output_col_r <= 8'hff;
                        output_col_g <= 8'h00;
                    end
                    2'b01: begin
                        output_col_r <= 8'h00;
                        output_col_g <= 8'hff;
                    end
                    2'b11: begin
                        output_col_r <= 8'h00;
                        output_col_g <= 8'h00;
                        rst_ok <= 1'b1;
                    end
                    default: begin
                        output_col_r <= 8'h00;
                        output_col_g <= 8'hff;
                    end
                endcase
            end
            default begin
                //TBD 当前仅一个状态 检查是否其他状态只需要操作显存即可
                output_row <= led_row;
                output_col_r <= led_col & {8{col_r_en & pwm_out}};
                output_col_g <= led_col & {8{col_g_en & pwm_out}};
            end
        
        endcase         
    end
endmodule