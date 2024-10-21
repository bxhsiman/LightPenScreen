// LED点阵驱动模块
// col高 row低驱动

`include "st_state.v"
`include "system_para.v"
`include "led_para.v"

module led_driver (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）

    input wire [2:0] state,    // 状态机状态 //TBD
    output reg rst_ok,         // 复位完成信号 //回传状态机 TBD

    input wire we,             //光笔输入信号

    output reg [7:0] output_row,
    output reg [7:0] output_col_r,
    output reg [7:0] output_col_g

    //for test
    , output wire [3:0] ram_data_o

);

    
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

    // 光笔选色器
    wire [1:0] color = 2'b0;          //当前选中的颜色 TBD

    //LED 显存 读写
    reg [3:0] ram_write_data;  //待写入
    wire [3:0] ram_data;       //读出

    // TEST 是否有错位可能？
    always @(posedge clk) begin
        if (we) begin
            case(state)
                `LIGHT, `DRAW, `WRITE: begin
                    ram_write_data <= {1'b1 , 1'b0 , 1'b1 , 1'b0}; //变亮
                end
                `ERASE: begin
                    ram_write_data <= {1'b1 , 1'b0 , 1'b0 , 1'b0}; //变暗
                end
                `COLOR: begin
                    ram_write_data <= { 1'b1, color, 1'b0 }; //选色
                end
            default: begin
                ram_write_data <= ram_data; // RST SLEEP 等模式 保留原始值
            end
            endcase
        end
    end

    // 检查这里的时序！
    led_ram led_ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .data(ram_write_data),
        .addr_row(led_row),
        .addr_col(led_col),
        .we(we),
        .led_data(ram_data)
    );

    //显存内容解析
    reg col_r_en;
    reg col_g_en;
    always @(posedge clk) begin
        if (ram_data[3] == 1'b1) begin
            duty <= `PWM_HIGH_COUNT;
            col_r_en <= ram_data[1];
            col_g_en <= ram_data[2];
        end
        else begin
            if (state == `DRAW) begin
                duty <= `PWM_HIGH_COUNT;
                col_g_en <= 1'b0;
                col_r_en <= 1'b1;
            end
            else begin
                duty <= `PWM_LOW_COUNT;
                col_g_en <= 1'b0;
                col_r_en <= 1'b1;
            end
        end
    end

    reg [31:0] rst_cnt; //重启计数器
    reg [2:0] rst_led_state; //led状态

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
                rst_cnt <= rst_cnt + 1;
                if (rst_cnt >= `CLOCK_FREQ) begin
                    rst_cnt <= 0;
                    rst_led_state <= rst_led_state + 1;
                end
                case (rst_led_state)
                    3'b000, 3'b010: begin
                        output_col_r <= 8'hff;
                        output_col_g <= 8'h00;
                        output_row <= 8'h00;

                    end
                    3'b001: begin
                        output_col_r <= 8'h00;
                        output_col_g <= 8'hff;
                        output_row <= 8'h00;
                    end
                    3'b011: begin
                        output_col_r <= 8'h00;
                        output_col_g <= 8'hff;
                        output_row <= 8'h00;
                        
                    end
                    3'b100: begin
                        output_col_r <= 8'h00;
                        output_col_g <= 8'h00;
                        output_row <= 8'hff;
                        rst_ok <= 1'b1;
                    end
                    default: begin
                        output_row <= 8'hff;
                    end
                endcase
            end

            default: begin
                rst_cnt <= 0;
                rst_led_state <= 2'b00;
                rst_ok <= 1'b0;
                //TBD 当前仅一个状态 检查是否其他状态只需要操作显存即可
                output_row <= ~led_row;
                output_col_r <= led_col & {8{col_r_en & pwm_out}};
                output_col_g <= led_col & {8{col_g_en & pwm_out}};
            end
        
        endcase         
    end

    assign ram_data_o = ram_data; //for test

endmodule