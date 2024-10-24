`include "st_state.v"
`include "system_para.v"
module st (
    input clk,
    input rst,          // BTN0
    input state_change, // BTN1

    output wire [2:0] state,
    output wire [2:0] state_deep // 深层状态机
);

    // 状态寄存器
    reg [2:0] state_reg, state_next;
    reg [2:0] state_deep_reg, state_deep_next;

    // 计数器
    reg [31:0] time_counter, time_counter_next;

    // 边沿检测寄存器
    reg state_change_sync0, state_change_sync1;
    reg state_change_edge;

    // 同步并检测state_change的上升沿
    always @(posedge clk) begin
        state_change_sync0 <= state_change;
        state_change_sync1 <= state_change_sync0;
        state_change_edge <= state_change_sync0 && !state_change_sync1;
    end

    // 状态机状态转换
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // STOP RST 状态切换
            state_reg <= (state_reg == `STOP) ? `RST : `STOP;
            state_deep_reg <= `STATE_0;
            time_counter <= 0;
        end else begin
            // 更新状态
            state_reg <= state_next;
            state_deep_reg <= state_deep_next;
            time_counter <= time_counter_next;
        end
    end

    // 状态机状态判定 组合逻辑
    always @(*) begin
        // 默认赋值
        state_next = state_reg;
        state_deep_next = state_deep_reg;
        time_counter_next = time_counter;

        case (state_reg)
            `RST: begin
                // 2HZ闪烁
                if (time_counter == (`CLOCK_FREQ/2 - 1)) begin
                    time_counter_next = 0;
                    if (state_deep_reg == `STATE_3) begin
                        state_deep_next = `STATE_0;
                        state_next = `SLEEP;
                    end else begin
                        state_deep_next = state_deep_reg + 1;
                    end
                end else begin
                    time_counter_next = time_counter + 1;
                end
            end
            `SLEEP: begin
                if (state_change_edge) state_next = `LIGHT;
            end
            `LIGHT: begin
                if (state_change_edge) state_next = `DRAW;
            end
            `DRAW: begin
                if (state_change_edge) state_next = `WRITE;
            end
            `WRITE: begin
                if (state_change_edge) state_next = `ERASE;
            end
            `ERASE: begin
                if (state_change_edge) state_next = `COLOR;
            end
            `COLOR: begin
                if (state_change_edge) state_next = `LIGHT;
            end
            `STOP: begin
                // 保持STOP状态
                state_next = `STOP;
            end
            default: begin
                state_next = `STOP;
            end
        endcase
    end

    assign state = state_reg;
    assign state_deep = state_deep_reg;

endmodule
