// Seg Driver for 32bit 7-segment display
module hex_display(
    input wire clk,
    input wire [31:0] data,       // 8 hexadecimal digits
    output reg [7:0] cat,         // Common cathodes
    output reg [7:0] seg          // Segment control (AA, AB, AC, etc.)
);

// Internal variables
reg [2:0] digit_index;            // Keeps track of which digit to scan
reg [3:0] current_digit;          // Current 4-bit hex value for display
wire [7:0] segments;              // Encoded segment output

// Hex to 7-segment decoder
function [7:0] hex_to_7seg;
    input [3:0] hex;
    begin
        case (hex)
            4'h0: hex_to_7seg = 8'b00000011; // 0
            4'h1: hex_to_7seg = 8'b10011111; // 1
            4'h2: hex_to_7seg = 8'b00100101; // 2
            4'h3: hex_to_7seg = 8'b00001101; // 3
            4'h4: hex_to_7seg = 8'b10011001; // 4
            4'h5: hex_to_7seg = 8'b01001001; // 5
            4'h6: hex_to_7seg = 8'b01000001; // 6
            4'h7: hex_to_7seg = 8'b00011111; // 7
            4'h8: hex_to_7seg = 8'b00000001; // 8
            4'h9: hex_to_7seg = 8'b00001001; // 9
            4'hA: hex_to_7seg = 8'b00010001; // A
            4'hB: hex_to_7seg = 8'b11000001; // B
            4'hC: hex_to_7seg = 8'b01100011; // C
            4'hD: hex_to_7seg = 8'b10000101; // D
            4'hE: hex_to_7seg = 8'b01100001; // E
            4'hF: hex_to_7seg = 8'b01110001; // F
            default: hex_to_7seg = 8'b11111111; // Blank
        endcase
    end
endfunction

// Scanning logic: Update the display every clock cycle
always @(posedge clk) begin
    // Select the current digit to display based on digit_index
    case (digit_index)
        3'b000: current_digit = data[3:0];
        3'b001: current_digit = data[7:4];
        3'b010: current_digit = data[11:8];
        3'b011: current_digit = data[15:12];
        3'b100: current_digit = data[19:16];
        3'b101: current_digit = data[23:20];
        3'b110: current_digit = data[27:24];
        3'b111: current_digit = data[31:28];
    endcase
    
    // Convert hex value to 7-segment display code
    seg = hex_to_7seg(current_digit);
    
    // Activate only the current digit's cathode
    cat = ~(8'b00000001 << digit_index);
    
    // Move to the next digit on the next clock cycle
    digit_index <= digit_index + 1;
end

endmodule
