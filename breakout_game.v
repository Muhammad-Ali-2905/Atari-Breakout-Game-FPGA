`timescale 1ns / 1ps
module breakout_game(
    input  wire       clk,
    input  wire       rst,
    input  wire       left_btn,
    input  wire       right_btn,
    input  wire       start_btn,
    output wire       vga_hsync,
    output wire       vga_vsync,
    output wire [2:0] red,
    output wire [2:0] green,
    output wire [1:0] blue,
    output wire       game_over,
    output wire       win
);

    wire [9:0] paddle_x, paddle_y;
    wire [9:0] ball_x, ball_y;
    wire [49:0] brick_map;
    wire clk_25mhz;

    reg game_active;

    always @(posedge clk or posedge rst) begin
        if (rst)
            game_active <= 1'b0;
        else if (start_btn)
            game_active <= 1'b1;
    end

    paddle_controller paddle_inst (
        .clk(clk),
        .rst(rst),
        .left_btn(left_btn),
        .right_btn(right_btn),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y)
    );

    brick_controller brick_inst (
        .clk(clk),
        .rst(rst | ~game_active),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .brick_map(brick_map)
    );

    ball_controller ball_inst (
        .clk(clk),
        .rst(rst),
        .game_active(game_active),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y),
        .brick_map(brick_map),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .game_over(game_over),
        .win(win)
    );

    vga_controller vga_inst (
        .clk_25mhz(clk_25mhz),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .paddle_x(paddle_x),
        .paddle_y(paddle_y),
        .brick_map(brick_map),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .red(red),
        .green(green),
        .blue(blue)
    );

    clk_div_25mhz clkdiv (
        .clk_100mhz(clk),
        .clk_25mhz(clk_25mhz)
    );

endmodule