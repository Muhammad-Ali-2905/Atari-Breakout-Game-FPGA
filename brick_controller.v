`timescale 1ns / 1ps
module brick_controller(
    input clk,
    input rst,
    input [9:0] ball_x,
    input [9:0] ball_y,
    output reg [49:0] brick_map
);

    parameter BRICK_ROWS    = 5;
    parameter BRICK_COLS    = 10;
    parameter BRICK_WIDTH   = 60;
    parameter BRICK_HEIGHT  = 20;
    parameter BRICK_HGAP    = 4;
    parameter BRICK_VGAP    = 8;
    parameter BRICK_START_Y = 40;
    parameter BALL_SIZE     = 10;

    integer i, r, c;
    integer bx, by;

    initial brick_map = 50'b11111111111111111111111111111111111111111111111111;

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            brick_map <= 50'b11111111111111111111111111111111111111111111111111;
        end else begin
            for (i = 0; i < BRICK_ROWS*BRICK_COLS; i = i + 1) begin
                if (brick_map[i]) begin
                    r = i / BRICK_COLS;
                    c = i % BRICK_COLS;
                    bx = ((640 - (BRICK_COLS*BRICK_WIDTH + (BRICK_COLS-1)*BRICK_HGAP))/2)
                          + c*(BRICK_WIDTH + BRICK_HGAP);
                    by = BRICK_START_Y + r*(BRICK_HEIGHT + BRICK_VGAP);

                    if (ball_x + BALL_SIZE >= bx &&
                        ball_x <= bx + BRICK_WIDTH &&
                        ball_y + BALL_SIZE >= by &&
                        ball_y <= by + BRICK_HEIGHT) begin
                        brick_map[i] <= 1'b0;
                    end
                end
            end
        end
    end
endmodule