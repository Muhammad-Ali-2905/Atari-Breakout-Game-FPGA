`timescale 1ns / 1ps
module clk_div_25mhz (
    input clk_100mhz,
    output reg clk_25mhz = 0
);
    reg [1:0] count = 0;

    always @(posedge clk_100mhz) begin
        count <= count + 1;
        clk_25mhz <= count[1];
    end
endmodule