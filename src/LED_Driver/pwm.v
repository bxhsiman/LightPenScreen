module pwm_generator(
    input wire clk,            // 时钟输入
    input wire rst_n,          // 异步复位（低电平有效）
    input wire [7:0] duty,     // 占空比，8位输入 (0-255)
    output reg pwm_out         // PWM 输出信号
);

    parameter MAX_COUNT = 255;  // 最大计数器值，对应占空比 100%
    
    reg [7:0] counter;          // 8 位计数器

    // 计数器和 PWM 信号生成
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 8'd0;    // 复位时计数器清零
            pwm_out <= 1'b0;    // 复位时输出低电平
        end else begin
            if (counter < MAX_COUNT)
                counter <= counter + 1;  // 计数器自增
            else
                counter <= 8'd0;         // 达到最大值后清零
            
            // PWM 输出逻辑
            if (counter < duty)
                pwm_out <= 1'b1;    // 占空比范围内输出高电平
            else
                pwm_out <= 1'b0;    // 超过占空比时输出低电平
        end
    end

endmodule
