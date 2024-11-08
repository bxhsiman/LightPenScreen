// LED点阵驱动模块
// col高 row低驱动

`include "st_state.v"
`include "system_para.v"
`include "led_para.v"

module led_driver (
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）

    input wire clean,          // 清屏信号

    input wire [3:0] state,      // 状态机状态
    input wire [3:0] state_deep, //二层状态机
    
    input wire we,               //光笔输入信号

    output wire [7:0] addr_row, //扫描行
    output wire [7:0] addr_col, //扫描列
    output wire [3:0] led_data_o, //LED数据

    output reg [7:0] output_row,
    output reg [7:0] output_col_r,
    output reg [7:0] output_col_g,

    output wire [2:0] row_d,     // 刚写入的行地址
    output wire [2:0] col_d,     // 刚写入的列地址

    output reg [1:0] color      // 当前选中颜色

    //for test
    , output wire [3:0] ram_data_o

);

    reg [15:0] duty;
    wire [7:0] led_row;
    wire [7:0] led_col;
    wire pwm_out;

    assign addr_row = led_row; //输出用
    assign addr_col = led_col; 
    assign led_data_o = ram_data;

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
   always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            color <= `RED;
        end else begin
            case(state) 
                `COLOR: begin
                    if(we) begin
                        if (led_row == `RED_ROW && led_col == `RED_COL) begin
                            color <= `RED;
                        end
                        else if (led_row == `GREEN_ROW && led_col == `GREEN_COL) begin
                            color <= `GREEN;
                        end
                        else if (led_row == `YELLOW_ROW && led_col == `YELLOW_COL) begin
                            color <= `YELLOW;
                        end
                        else begin
                            color <= color;
                        end
                    end else begin
                        color <= color;
                    end
                end
                `RST: begin
                    color <= `RED;
                end
                default: begin
                    color <= color;
                end
            endcase
        end
    end


    //RAM写入
    reg [3:0] ram_write_data;  //待写入
    always @(*) begin
        case(state)
            `LIGHT, `DRAW, `WRITE: begin
                ram_write_data = { 1'b1 , color , 1'b0 }; //变亮
            end
            `ERASE: begin
                ram_write_data = { 1'b0 , 1'b0 , 1'b0 , 1'b0 }; //变暗
            end
        default: begin
            ram_write_data = ram_data; // RST SLEEP 等模式 保留原始值
        end
        endcase
    end

    // RAM 读取
    wire [3:0] ram_data;       //读出
    led_ram led_ram_inst (
        .clk(clk),
        .rst_n(rst_n),
        .clean(clean),
        .state(state),
        .data(ram_write_data),
        .addr_row(led_row),
        .addr_col(led_col),
        .we(we),
        .led_data(ram_data),
        
        .col_d(col_d),
        .row_d(row_d)
    );

    //根据状态解析显存内容
    reg col_r_en;
    reg col_g_en;
    always @(*) begin
        if (ram_data[3] == 1'b1) begin
            duty = (state == `REVERSE) ? `PWM_LOW_COUNT : `PWM_HIGH_COUNT;
            col_r_en = ram_data[1];
            col_g_en = ram_data[2];
        end
        else begin
            duty = (state == `REVERSE) ? `PWM_HIGH_COUNT : `PWM_LOW_COUNT;
            col_g_en = 1'b0;
            col_r_en = 1'b1;
        end
    end

    //点阵屏组合逻辑
    always @(*) begin
        // 默认值
        output_row = 8'hFF;
        output_col_r = 8'h00;
        output_col_g = 8'h00;
        case (state)
            `STOP: begin
                //暂停状态
                output_row = 8'hFF;
                output_col_r = 8'h00;
                output_col_g = 8'h00;
            end
            `RST: begin
                case(state_deep)
                    `STATE_0, `STATE_2: begin
                        output_row = 8'h00;
                        output_col_r = 8'hFF;
                        output_col_g = 8'h00;
                    end 
                    `STATE_1, `STATE_3: begin
                        output_row = 8'h00;
                        output_col_r = 8'h00;
                        output_col_g = 8'hFF;
                    end
                endcase
            end
            `COLOR: begin
                output_row = ~led_row; // ROW低电平驱动
                if (led_row == `RED_ROW && led_col == `RED_COL) begin
                    output_col_r = led_col; //直接点亮
                    output_col_g = 8'h00;   //熄灭
                end
                else if (led_row == `GREEN_ROW && led_col == `GREEN_COL) begin
                    output_col_r = led_col & {8{col_r_en & pwm_out}};   //扫描
                    output_col_g = led_col; //直接点亮
                end
                else if (led_row == `YELLOW_ROW && led_col == `YELLOW_COL)begin
                    output_col_r = led_col;   //点亮
                    output_col_g = led_col;   //点亮
                end
                else begin
                    output_col_r = led_col & {8{col_r_en & pwm_out}};
                    output_col_g = led_col & {8{col_g_en & pwm_out}};
                end
                
            end
            default: begin
                output_row = ~led_row; // ROW低电平驱动
                output_col_r = led_col & {8{col_r_en & pwm_out}};
                output_col_g = led_col & {8{col_g_en & pwm_out}};

            end
        
        endcase         
    end

    assign ram_data_o = ram_data; //for test

endmodule