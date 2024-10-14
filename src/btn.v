module btn (
    input wire clk,        
    input wire rst_n, 
    input wire button_in,  
    output reg button_out
);

    parameter MAX_COUNT = 80;

    reg [19:0] counter; 
    reg button_sync0, button_sync1;

    // 移位器消除亚稳态
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            button_sync0 <= 1'b1;
            button_sync1 <= 1'b1;
        end
        else begin
            button_sync0 <= button_in;
            button_sync1 <= button_sync0;
        end
    end

    // 按键消抖
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= 0;
            button_out <= 1'b1;
        end
        else begin
            if (button_sync1 == 1'b1) begin
                if (counter < MAX_COUNT) begin
                    counter <= counter + 1;
                end
                else begin
                    button_out <= 1'b1; 
                end
            end
            else begin
                counter <= 0;
                button_out <= 1'b0;
            end
        end
    end

endmodule
