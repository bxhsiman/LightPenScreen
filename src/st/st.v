// 状态机文件
// 对输入信号边沿检测 切换状态

`include "include/st_state.v"

module st (
    input state_change,
    input clk,
    input rst, //BTN0
    output [2:0] state
);

    reg [2:0] state;
    reg rst_ok;

    reg is_start; // 启动过标记

    // 对 rst 进行边沿检测 切换状态
    always @(posedge clk or posedge rst or posedge rst_ok) begin
        if (rst) begin
            if (is_start) begin
                state <= `RST;
                is_start <= 1'b1;
            end
            else begin
                state <= `STOP;
                is_start <= 1'b0;
            end
        end
        else begin
            case (state)
                `RST: begin
                    if (rst_ok) begin
                        state <= `SLEEP;
                    end
                    else begin
                        state <= `RST;
                    end
                end
                `SLEEP: begin
                    if (state_change) begin
                        state <= `LIGHT;
                    end
                end
                `LIGHT: begin
                    if (state_change) begin
                        state <= `DRAW;
                    end
                end
                `DRAW: begin
                    if (state_change) begin
                        state <= `WRITE;
                    end
                end
                `WRITE: begin
                    if (state_change) begin
                        state <= `ERASE;
                    end
                end
                `ERASE: begin
                    if (state_change) begin
                        state <= `COLOR;
                    end
                end
                `COLOR: begin
                    if (state_change) begin
                        state <= `LIGHT;
                    end
                end
                `STOP: begin
                    state <= `STOP;
                end
                default: begin
                    state <= `RST;
                end
            endcase
        end

    end

endmodule