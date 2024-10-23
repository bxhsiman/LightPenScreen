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
        case (state_reg) 
            `RST: begin
                if (rst_ok) begin
                    state_reg <= `SLEEP;
                end
                else begin
                    state_reg <= `RST;
                end
            end
            `SLEEP: begin
                if (rst_edge) begin
                    state_reg <= `STOP;
                end
                else if (state_change_edge) begin
                    state_reg <= `LIGHT;
                end 
                else begin
                    state_reg <= `SLEEP;
                end
            end
            `LIGHT: begin
                if (rst_edge) begin
                    state_reg <= `STOP;
                end
                else if (state_change_edge) begin
                    state_reg <= `DRAW;
                end
                else begin
                    state_reg <= `LIGHT;
                end
            end
            `DRAW: begin
                if (rst_edge) begin
                    state_reg <= `STOP;
                end
                else if (state_change_edge) begin
                    state_reg <= `WRITE;
                end
                else begin
                    state_reg <= `DRAW;
                end
            end
            `WRITE: begin
                if (rst_edge) begin
                    state_reg <= `STOP;
                end
                else if (state_change_edge) begin
                    state_reg <= `ERASE;
                end
                else begin
                    state_reg <= `WRITE;
                end
            end
            `ERASE: begin
                if (rst_edge) begin
                    state_reg <= `STOP;
                end
                else if (state_change_edge) begin
                    state_reg <= `COLOR;
                end
                else begin
                    state_reg <= `ERASE;
                end
            end
            `COLOR: begin
                if (rst_edge) begin
                    state_reg <= `STOP;
                end
                else if (state_change_edge) begin
                    state_reg <= `LIGHT;
                end
                else begin
                    state_reg <= `COLOR;
                end
            end
            `STOP: begin
                if (rst_edge) begin
                    state_reg <= `RST;
                end
                else begin
                    state_reg <= `STOP;
                end
            end
            default: begin
                state_reg <= `RST;
            end
        endcase
    end

    assign state = state_reg;

endmodule
