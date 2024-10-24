`include "st_state.v"
`include "system_para.v"

`include "st_state.v"
`include "system_para.v"

module led_ram (
    input wire clk,            // Clock input
    input wire rst_n,          // Active low reset

    input wire [3:0] state,    // State machine state

    input wire [3:0] data,     // LED data input
    input wire [7:0] addr_row, // One-hot encoded row address input
    input wire [7:0] addr_col, // One-hot encoded col address input
    input wire we,             // Write enable

    output reg [3:0] led_data, // LED data output 

    output reg [2:0] col_d,    // Last written column address
    output reg [2:0] row_d     // Last written row address

);

    // Define RAM as a single array (64x4 bits)
    reg [3:0] ram [0:63];

    // Helper variables
    reg [7:0] col_buffer;      // Column address buffer
    reg [2:0] row_buffer;      // Row address buffer
    reg [3:0] data_buffer;     // Data buffer
    reg [25:0] draw_timer;     // DRAW state timer (adjust width as needed)
    reg buffer_empty;          // Buffer empty flag
    reg buffer_full;           // Buffer full flag

    // Edge detection for 'we'
    reg we_d;
    wire we_edge;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            we_d <= 1'b0;
        else
            we_d <= we;
    end
    assign we_edge = ~we_d && we; // Detect rising edge of 'we'

    // Convert one-hot to binary using a case statement
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

    wire [2:0] bin_row, bin_col;
    assign bin_row = onehot_to_bin(addr_row);
    assign bin_col = onehot_to_bin(addr_col);

    // State register to detect state changes
    reg [3:0] state_d;
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n)
            state_d <= 4'd0;
        else
            state_d <= state;
    end

    // RAM operations
    always @(posedge clk or negedge rst_n) begin
        if (~rst_n) begin
            // Asynchronous reset
            col_d <= 3'd0;
            row_d <= 3'd0;
            // Clear buffers and timer
            col_buffer   <= 8'd0;
            row_buffer   <= 3'd0;
            data_buffer  <= 4'd0;
            draw_timer   <= 26'd0; 
            buffer_empty <= 1'b1;
            buffer_full  <= 1'b0;
        end else begin
            // Handle state changes
            if (state_d != state) begin
                col_d <= 3'd0;
                row_d <= 3'd0;
                // Clear buffers and timer
                col_buffer   <= 8'd0;
                row_buffer   <= 3'd0;
                data_buffer  <= 4'd0;
                draw_timer   <= 26'd0;
                buffer_empty <= 1'b1;
                buffer_full  <= 1'b0;
            end else begin
                // State unchanged
                if (state == `DRAW) begin
                    // DRAW state
                    if (we_edge) begin
                        // Detected we rising edge
                        if (buffer_empty) begin
                            // Buffer is empty
                            row_buffer   <= bin_row;
                            data_buffer  <= data;
                            col_buffer[bin_col] <= 1'b1;
                            buffer_empty <= 1'b0;
                            buffer_full  <= &col_buffer;
                            draw_timer   <= 26'd0;
                        end else begin
                            if (bin_row == row_buffer) begin
                                // Same row, update col_buffer
                                col_buffer[bin_col] <= 1'b1;
                                buffer_full  <= &col_buffer;
                                draw_timer   <= 26'd0;
                            end
                        end
                    end else begin
                        // No we edge
                        if (!buffer_empty) begin
                            draw_timer <= draw_timer + 1;
                            if (draw_timer >= `CLOCK_FREQ - 1) begin
                                // Timeout, write to RAM
                                integer col;
                                for (col = 0; col < 8; col = col + 1) begin
                                    if (col_buffer[col]) begin
                                        ram[{row_buffer, col[2:0]}] <= data_buffer;
                                        // Update col_d and row_d
                                        col_d <= col[2:0];
                                        row_d <= row_buffer;
                                    end
                                end
                                // Clear buffers and timer
                                col_buffer   <= 8'd0;
                                data_buffer  <= 4'd0;
                                buffer_empty <= 1'b1;
                                buffer_full  <= 1'b0;
                                draw_timer   <= 26'd0;
                            end
                        end
                    end

                    // If buffer is full, write to RAM immediately
                    if (buffer_full && !buffer_empty) begin
                        integer col;
                        for (col = 0; col < 8; col = col + 1) begin
                            if (col_buffer[col]) begin
                                ram[{row_buffer, col[2:0]}] <= data_buffer;
                                // Update col_d and row_d
                                col_d <= col[2:0];
                                row_d <= row_buffer;
                            end
                        end
                        // Clear buffers and timer
                        col_buffer   <= 8'd0;
                        data_buffer  <= 4'd0;
                        buffer_empty <= 1'b1;
                        buffer_full  <= 1'b0;
                        draw_timer   <= 26'd0;
                    end
                end else begin
                    // Non-DRAW state
                    if (we_d && ~we) begin
                        // Detected we falling edge
                        ram[{bin_row, bin_col}] <= data;
                        col_d <= bin_col;
                        row_d <= bin_row;
                    end
                end
            end
        end
    end

    // Read data from RAM (synchronous read)
    always @(posedge clk) begin
        led_data <= ram[{bin_row, bin_col}];
    end

endmodule
