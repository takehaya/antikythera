`timescale 1ns/1ps
module ZeroExtender(
    input  [15:0] in,
    output [31:0] out
);
    assign out = {16'h0000, in};
endmodule
