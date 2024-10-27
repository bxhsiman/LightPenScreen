`timescale 1ns / 1ps

module test_lcd(
    input clk,          // System clock
    input reset,        // System reset
    output lcd_ok,      // LCD ready signal
    output [7:0] data,  // Data output to LCD
    output reset_n,     // LCD reset
    output cs_n,        // Chip select
    output wr_n,        // Write control
    output rd_n,        // Read control
    output a0           // Register select
);

    wire [3:0] pos_x;      // Position X
    wire [3:0] pos_y;      // Position Y
    wire [3:0] char_index; // Character index
    reg char_show;         // Character show enable

    // Instantiate the lcd_12864 module
    lcd_12864 lcd_inst (
        .clk_i(clk),
        .reset_i(reset),
        .lcd_ok_o(lcd_ok),
        .pos_x_i(pos_x),
        .pos_y_i(pos_y),
        .char_index_i(char_index),
        .char_show_i(char_show),
        .data_o(data),
        .reset_n_o(reset_n),
        .cs_n_o(cs_n),
        .wr_n_o(wr_n),
        .rd_n_o(rd_n),
        .a0_o(a0)
    );

    // Generate position and character indices to display "1234567"
    reg [3:0] x_pos = 0;
    reg [3:0] y_pos = 0;
    reg [3:0] current_char = 1;

    assign pos_x = x_pos;
    assign pos_y = y_pos;
    assign char_index = current_char;

    reg [2:0] state = 0;

    // State machine to cycle through displaying "1234567"
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            x_pos <= 0;
            y_pos <= 0;
            current_char <= 0;
            char_show <= 1;  
        end else if (lcd_ok) begin
            case(state)
                0: begin
                     if (x_pos < 15) begin
                        x_pos <= x_pos + 1;
                        char_show <= 1;
                    end else if (y_pos < 15) begin
                        x_pos <= 0;
                        y_pos <= y_pos + 1;
                        char_show <= 1;
                    end
                    else begin
                        x_pos <= 2;
                        y_pos <= 2;
                        current_char <= 1;
                        char_show <= 1;
                        state <= 1;
                    end
                end 
                1: begin
                    if (current_char < 3) begin
                        current_char <= current_char + 1;
                        x_pos <= x_pos + 2;
                        char_show <= 1;
                    end
                    else begin
                        current_char <= 1;
                        char_show <= 0;
                        state <= 2;
                    end
                end
                default: state <= 2;
            endcase
        end
    end

endmodule