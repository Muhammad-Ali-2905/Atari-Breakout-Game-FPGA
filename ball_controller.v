`timescale 1ns / 1ps
module ball_controller(
    input  wire        clk,
    input  wire        rst,
    input  wire        game_active,
    input  wire [9:0]  paddle_x,
    input  wire [9:0]  paddle_y,
    input  wire [49:0] brick_map,
    output reg  [9:0]  ball_x,
    output reg  [9:0]  ball_y,
    output reg         game_over,
    output reg         win
);

    // ---------------- CONSTANTS ----------------
    parameter SCREEN_WIDTH  = 640;
    parameter SCREEN_HEIGHT = 480;
    parameter BALL_SIZE     = 10;
    parameter PADDLE_WIDTH  = 80;
    parameter PADDLE_HEIGHT = 20;

    parameter BRICK_ROWS    = 5;
    parameter BRICK_COLS    = 10;
    parameter BRICK_WIDTH   = 60;
    parameter BRICK_HEIGHT  = 20;
    parameter BRICK_HGAP    = 4;
    parameter BRICK_VGAP    = 8;
    parameter BRICK_START_Y = 40;
    parameter BRICK_START_X =
        (SCREEN_WIDTH - (BRICK_COLS*BRICK_WIDTH + (BRICK_COLS-1)*BRICK_HGAP)) / 2;

    // ---------------- INTERNAL STATE ----------------
    // Signed positions to avoid unsigned wrap with negative velocity
    reg signed [10:0] ball_x_s;
    reg signed [10:0] ball_y_s;

    // Velocity (NEGATIVE dy = UP)
    reg signed [3:0] dx;
    reg signed [3:0] dy;

    // ---------------- SLOW TICK (NOW 4x ORIGINAL SPEED) ----------------
    // Original was [21:0], then 2x speed was [20:0], now another 2x => [19:0]
    reg [18:0] clk_div;
    wire ball_tick = (clk_div == 18'd0);

    always @(posedge clk or posedge rst) begin
        if (rst) clk_div <= 18'd0;
        else     clk_div <= clk_div + 1'b1;
    end

    // ---------------- NEXT-STATE ----------------
    reg signed [10:0] nx, ny;
    reg signed [3:0]  ndx, ndy;
    reg               ngame_over, nwin;

    integer i, r, c;
    integer brick_x, brick_y;

    reg brick_hit;

    // For better brick reflection:
    reg hit_lr;
    reg hit_tb;

    // Combinational next-state logic
    always @* begin
        brick_hit = 1'b0;
        hit_lr    = 1'b0;
        hit_tb    = 1'b0;

        // Defaults: hold state
        nx = ball_x_s;
        ny = ball_y_s;
        ndx = dx;
        ndy = dy;
        ngame_over = game_over;
        nwin       = win;

        // Pre-start: lock ball on paddle
        if (!game_active) begin
            nx = $signed({1'b0, paddle_x}) + (PADDLE_WIDTH/2) - (BALL_SIZE/2);
            ny = $signed({1'b0, paddle_y}) - BALL_SIZE;
            ndx = 4'sd1;
            ndy = -4'sd1; // start upward
            ngame_over = 1'b0;
            nwin       = 1'b0;
        end
        else if (!game_over && !win) begin
            if (ball_tick) begin
                // Predict next position
                nx = ball_x_s + $signed(dx);
                ny = ball_y_s + $signed(dy);

                // ---------------- SIDE WALLS ----------------
                if (nx <= 0) begin
                    nx  = 0;
                    ndx = (dx < 0) ? -dx : dx;
                end
                else if (nx >= (SCREEN_WIDTH - BALL_SIZE)) begin
                    nx  = SCREEN_WIDTH - BALL_SIZE;
                    ndx = (dx > 0) ? -dx : dx;
                end

                // ---------------- TOP WALL ----------------
                if (ny <= 0) begin
                    ny  = 0;
                    ndy = (dy < 0) ? -dy : dy;
                end

                // ---------------- PADDLE COLLISION ----------------
                if (dy > 0) begin
                    if ( (ny + BALL_SIZE) >= $signed({1'b0,paddle_y}) &&
                         (ball_y_s + BALL_SIZE) <= $signed({1'b0,paddle_y}) + 1 &&
                         (nx + BALL_SIZE) >  $signed({1'b0,paddle_x}) &&
                         (nx)           <  $signed({1'b0,paddle_x}) + PADDLE_WIDTH ) begin
                        ndy = -((dy < 0) ? -dy : dy); // bounce up
                        ny  = $signed({1'b0,paddle_y}) - BALL_SIZE - 1;
                    end
                end

                // ---------------- BOTTOM (MISS) ----------------
                if ((ny + BALL_SIZE) >= SCREEN_HEIGHT) begin
                    ny = SCREEN_HEIGHT - BALL_SIZE;
                    ngame_over = 1'b1;
                end

                // ---------------- BRICK COLLISION (WITH REFLECTION) ----------------
                // Decide whether to flip dx or dy based on which face was crossed.
                brick_hit = 1'b0;
                hit_lr    = 1'b0;
                hit_tb    = 1'b0;

                for (i = 0; i < 50; i = i + 1) begin
                    if (brick_map[i] && !brick_hit) begin
                        r = i / BRICK_COLS;
                        c = i % BRICK_COLS;
                        brick_x = BRICK_START_X + c*(BRICK_WIDTH + BRICK_HGAP);
                        brick_y = BRICK_START_Y + r*(BRICK_HEIGHT + BRICK_VGAP);

                        // overlap at next position?
                        if ( (nx + BALL_SIZE) > brick_x &&
                             (nx)           < (brick_x + BRICK_WIDTH) &&
                             (ny + BALL_SIZE) > brick_y &&
                             (ny)           < (brick_y + BRICK_HEIGHT) ) begin

                            // Previous edges
                            // prev_left   = ball_x_s
                            // prev_right  = ball_x_s + BALL_SIZE
                            // prev_top    = ball_y_s
                            // prev_bottom = ball_y_s + BALL_SIZE

                            // Next edges
                            // next_left   = nx
                            // next_right  = nx + BALL_SIZE
                            // next_top    = ny
                            // next_bottom = ny + BALL_SIZE

                            // Check which face we crossed
                            hit_lr = 1'b0;
                            hit_tb = 1'b0;

                            // Hit left face of brick (came from left to right)
                            if ( (ball_x_s + BALL_SIZE) <= brick_x &&
                                 (nx + BALL_SIZE)        >  brick_x ) begin
                                hit_lr = 1'b1;
                            end
                            // Hit right face of brick (came from right to left)
                            else if ( ball_x_s >= (brick_x + BRICK_WIDTH) &&
                                      nx       < (brick_x + BRICK_WIDTH) ) begin
                                hit_lr = 1'b1;
                            end

                            // Hit top face of brick (came from above going down)
                            if ( (ball_y_s + BALL_SIZE) <= brick_y &&
                                 (ny + BALL_SIZE)        >  brick_y ) begin
                                hit_tb = 1'b1;
                            end
                            // Hit bottom face of brick (came from below going up)
                            else if ( ball_y_s >= (brick_y + BRICK_HEIGHT) &&
                                      ny       < (brick_y + BRICK_HEIGHT) ) begin
                                hit_tb = 1'b1;
                            end

                            // Apply reflection
                            if (hit_lr && !hit_tb) begin
                                ndx = -ndx;
                            end
                            else if (hit_tb && !hit_lr) begin
                                ndy = -ndy;
                            end
                            else begin
                                // corner/ambiguous -> flip vertical (most common breakout feel)
                                ndy = -ndy;
                            end

                            brick_hit = 1'b1;
                        end
                    end
                end

                // ---------------- WIN ----------------
                if (brick_map == 50'b0) begin
                    nwin = 1'b1;
                end
            end
        end
    end

    // Sequential state update
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            ball_x_s   <= SCREEN_WIDTH/2;
            ball_y_s   <= SCREEN_HEIGHT - 80;
            dx         <= 4'sd1;
            dy         <= -4'sd1;
            game_over  <= 1'b0;
            win        <= 1'b0;

            ball_x     <= SCREEN_WIDTH/2;
            ball_y     <= SCREEN_HEIGHT - 80;
        end
        else begin
            ball_x_s  <= nx;
            ball_y_s  <= ny;
            dx        <= ndx;
            dy        <= ndy;
            game_over <= ngame_over;
            win       <= nwin;

            ball_x <= nx[9:0];
            ball_y <= ny[9:0];
        end
    end

endmodule