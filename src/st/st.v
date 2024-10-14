`include "st_state.v"
`include "system_para.v"

module st (
    input clk,
    input rst,          // BTN0
    input state_change, // BTN1
    input rst_ok,       // 复位完毕信号

    output [2:0] state
);
    reg [2:0] state_reg;
    reg is_start; // 启动过标记

    // 边沿检测和去抖处理
    reg state_change_prev;
    reg state_change_edge; // 检测到上升沿标记

    always @(posedge clk) begin
        state_change_edge <= (state_change && !state_change_prev);
        state_change_prev <= state_change;
    end

    // 对 rst 进行边沿检测
    reg rst_prev;
    reg rst_edge; // 检测到上升沿标记

    always @(posedge clk) begin
        rst_edge <= (rst && !rst_prev);
        rst_prev <= rst;
    end

    // 状态机
    always @(posedge clk) begin
        if (rst_edge) begin
            if (~is_start) begin
                state_reg <= `RST;
                is_start <= 1'b1;
            end
            else begin
                state_reg <= `STOP;
                is_start <= 1'b0;
            end
        end
        else begin
            case (state_reg) // 修改为 state_reg
                `RST: begin
                    if (rst_ok) begin
                        state_reg <= `SLEEP;
                    end
                    else begin
                        state_reg <= `RST;
                    end
                end
                `SLEEP: begin
                    if (state_change_edge) begin
                        state_reg <= `LIGHT;
                    end
                end
                `LIGHT: begin
                    if (state_change_edge) begin
                        state_reg <= `DRAW;
                    end
                end
                `DRAW: begin
                    if (state_change_edge) begin
                        state_reg <= `WRITE;
                    end
                end
                `WRITE: begin
                    if (state_change_edge) begin
                        state_reg <= `ERASE;
                    end
                end
                `ERASE: begin
                    if (state_change_edge) begin
                        state_reg <= `COLOR;
                    end
                end
                `COLOR: begin
                    if (state_change_edge) begin
                        state_reg <= `LIGHT;
                    end
                end
                `STOP: begin
                    state_reg <= `STOP;
                end
                default: begin
                    state_reg <= `RST;
                end
            endcase
        end
    end

    assign state = state_reg;

endmodule
