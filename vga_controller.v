`timescale 1ns / 1ps
module vga_controller(
    input clk_25mhz,
    input [9:0] ball_x,
    input [9:0] ball_y,
    input [9:0] paddle_x,
    input [9:0] paddle_y,
    input [49:0] brick_map,
    output reg vga_hsync,
    output reg vga_vsync,
    output reg [2:0] red,
    output reg [2:0] green,
    output reg [1:0] blue
);

    parameter H_SYNC   = 96;
    parameter H_BP     = 48;
    parameter H_ACTIVE = 640;
    parameter H_FP     = 16;
    parameter V_SYNC   = 2;
    parameter V_BP     = 33;
    parameter V_ACTIVE = 480;
    parameter V_FP     = 10;

    parameter PADDLE_WIDTH  = 80;
    parameter PADDLE_HEIGHT = 20;
    parameter BALL_SIZE     = 10;

    parameter BRICK_ROWS    = 5;
    parameter BRICK_COLS    = 10;
    parameter BRICK_WIDTH   = 60;
    parameter BRICK_HEIGHT  = 20;
    parameter BRICK_HGAP    = 4;
    parameter BRICK_VGAP    = 8;
    parameter BRICK_START_Y = 40;
    parameter BRICK_START_X = (H_ACTIVE - (BRICK_COLS*BRICK_WIDTH + (BRICK_COLS-1)*BRICK_HGAP))/2;

    reg [9:0] h_count;
    reg [9:0] v_count;
    integer r, c;
    reg brick_pixel;

    wire [9:0] pixel_x = (h_count >= H_SYNC + H_BP) ? h_count - (H_SYNC + H_BP) : 10'd0;
    wire [9:0] pixel_y = (v_count >= V_SYNC + V_BP) ? v_count - (V_SYNC + V_BP) : 10'd0;

    always @(posedge clk_25mhz) begin
        if (h_count == H_SYNC + H_BP + H_ACTIVE + H_FP - 1) begin
            h_count <= 0;
            if (v_count == V_SYNC + V_BP + V_ACTIVE + V_FP - 1)
                v_count <= 0;
            else
                v_count <= v_count + 1;
        end else begin
            h_count <= h_count + 1;
        end
    end

    always @(posedge clk_25mhz) begin
        vga_hsync <= (h_count < H_SYNC) ? 0 : 1;
        vga_vsync <= (v_count < V_SYNC) ? 0 : 1;
    end

    always @(posedge clk_25mhz) begin
        red   <= 3'b000;
        green <= 3'b000;
        blue  <= 2'b00;

        if (pixel_x < H_ACTIVE && pixel_y < V_ACTIVE) begin
            if (ball_x <= pixel_x && pixel_x < ball_x + BALL_SIZE &&
                ball_y <= pixel_y && pixel_y < ball_y + BALL_SIZE) begin
                red   <= 3'b000;
                green <= 3'b000;
                blue  <= 2'b11;   // Ball: blue
            end
            else if (paddle_x <= pixel_x && pixel_x < paddle_x + PADDLE_WIDTH &&
                     paddle_y <= pixel_y && pixel_y < paddle_y + PADDLE_HEIGHT) begin
                red   <= 3'b111;   // Paddle: red
                green <= 3'b000;
                blue  <= 2'b00;
            end
            else begin
                brick_pixel = 0;
                for (r = 0; r < BRICK_ROWS; r = r + 1) begin
                    for (c = 0; c < BRICK_COLS; c = c + 1) begin
                        if (brick_map[r*BRICK_COLS + c]) begin
                            if (BRICK_START_X + c*(BRICK_WIDTH + BRICK_HGAP) <= pixel_x &&
                                pixel_x < BRICK_START_X + c*(BRICK_WIDTH + BRICK_HGAP) + BRICK_WIDTH &&
                                BRICK_START_Y + r*(BRICK_HEIGHT + BRICK_VGAP) <= pixel_y &&
                                pixel_y < BRICK_START_Y + r*(BRICK_HEIGHT + BRICK_VGAP) + BRICK_HEIGHT)
                                brick_pixel = 1;
                        end
                    end
                end
                if (brick_pixel) begin
                    red   <= 3'b000;
                    green <= 3'b111; // Bricks: green
                    blue  <= 2'b00;
                end
            end
        end
    end

endmodule