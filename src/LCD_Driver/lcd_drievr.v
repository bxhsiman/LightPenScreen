`timescale 1ns / 1ps

module test_lcd(
    input clk,          // System clock
    input reset,        // System reset
    
    input [7:0] addr_row, // one-hot 
    input [7:0] addr_col, //one-hot 
    input [3:0] led_data, // LED data output 

    output lcd_ok,      // LCD ready signal
    output [7:0] data,  // Data output to LCD
    output reset_n,     // LCD reset
    output cs_n,        // Chip select
    output wr_n,        // Write control
    output rd_n,        // Read control
    output a0           // Register select
);
    // one-hot 二进制转换
    function [2:0] onehot_to_bin;
        input [7:0] onehot;
        begin
            case (onehot)
                8'b0000_0001: onehot_to_bin = 3'd0;
                8'b0000_0010: onehot_to_bin = 3'd1;
                8'b0000_0100: onehot_to_bin = 3'd2;
                8'b0000_1000: onehot_to_bin = 3'd3;
                8'b0001_0000: onehot_to_bin = 3'd4;
                8'b0010_0000: onehot_to_bin = 3'd5;
                8'b0100_0000: onehot_to_bin = 3'd6;
                8'b1000_0000: onehot_to_bin = 3'd7;
                default:       onehot_to_bin = 3'd0;
            endcase
        end
    endfunction

    //row反转func
    function [2:0] reverse_row;
        input [2:0] row;
        begin
            case(row)
                3'd7: reverse_row = 3'd0;
                3'd6: reverse_row = 3'd1;
                3'd5: reverse_row = 3'd2;
                3'd4: reverse_row = 3'd3;
                3'd3: reverse_row = 3'd4;
                3'd2: reverse_row = 3'd5;
                3'd1: reverse_row = 3'd6;
                3'd0: reverse_row = 3'd7;    
            endcase
        end
    endfunction

    wire [2:0] bin_row, bin_col;
    assign bin_row = onehot_to_bin(addr_row);
    assign bin_col = onehot_to_bin(addr_col);

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

    reg [3:0] x_pos = 0;
    reg [3:0] y_pos = 0;
    reg [3:0] current_char = 1;

    assign pos_x = x_pos;
    assign pos_y = y_pos;
    assign char_index = current_char;

    reg [2:0] state = 0;

    reg [0:63] data_d;

    // 0-clean screen 1-scan
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
                        x_pos <= 4;
                        y_pos <= 0;
                        current_char <= 1;
                        char_show <= 1;
                        state <= 1;
                    end
                end 
                1: begin
                    if(led_data[3] == 1'b1) begin
                        x_pos <= onehot_to_bin(addr_col) + 4;
                        y_pos <= reverse_row(onehot_to_bin(addr_row));
                        current_char <= 1; 
                        char_show <= 1;
                    end
                    else begin
                        x_pos <= onehot_to_bin(addr_col) + 4;
                        y_pos <= reverse_row(onehot_to_bin(addr_row));
                        current_char <= 2;
                        char_show <= 1;
                    end
                end
                default: state <= 2;
            endcase
        end
    end

endmodule