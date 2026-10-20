`timescale 1ns / 1ps
module paddle_controller(
    input  wire       clk,
    input  wire       rst,
    input  wire       left_btn,
    input  wire       right_btn,
    output reg  [9:0] paddle_x,
    output reg  [9:0] paddle_y
);
    parameter PADDLE_WIDTH  = 80;
    parameter PADDLE_HEIGHT = 20;
    parameter SCREEN_WIDTH  = 640;
    parameter SCREEN_HEIGHT = 480;

    localparam [9:0] PADDLE_X_START = (SCREEN_WIDTH/2) - (PADDLE_WIDTH/2);
    localparam [9:0] PADDLE_Y_START = SCREEN_HEIGHT - 40;

    reg [19:0] clk_div;
    wire frame_tick = (clk_div == 20'd0);

    always @(posedge clk or posedge rst) begin
        if (rst)
            clk_div <= 20'd0;
        else
            clk_div <= clk_div + 1'b1;
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            paddle_x <= PADDLE_X_START;
            paddle_y <= PADDLE_Y_START;
        end
        else if (frame_tick) begin
            if (left_btn && paddle_x > 0)
                paddle_x <= paddle_x - 10'd5;
            if (right_btn && paddle_x < (SCREEN_WIDTH - PADDLE_WIDTH))
                paddle_x <= paddle_x + 10'd5;
        end
    end
endmodule