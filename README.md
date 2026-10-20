# FPGA Atari Breakout Game

An FPGA-based implementation of the classic Atari Breakout game using **Verilog HDL**. Developed as a Digital System Design project, the game demonstrates real-time hardware game logic, VGA graphics generation, collision detection, and physical button inputs.

## Overview

The game recreates the core Breakout experience on an FPGA. The player controls a paddle at the bottom of the screen, bouncing a ball to destroy bricks arranged in a grid.

The design generates a 640 × 480 VGA display and uses dedicated Verilog modules for paddle movement, ball physics, brick management, clock division, and video generation.

## Features

- **VGA graphics:** Generates a 640 × 480 display with horizontal and vertical synchronization signals.
- **Real-time paddle control:** Move the paddle left or right using FPGA board buttons.
- **Ball physics:** Updates the ball position and direction, including reflections from the screen boundaries.
- **Collision detection:** Detects collisions with the paddle, walls, and bricks.
- **Brick destruction:** Removes bricks when hit by the ball.
- **Win and game-over states:** Detects when all bricks are cleared or the ball reaches the bottom of the screen.
- **Clock division:** Derives a 25 MHz VGA pixel clock from a 100 MHz input clock.
- **Modular RTL design:** Separates game logic and display generation into independent Verilog modules.
- **FPGA integration:** Uses a UCF constraints file to map clock, buttons, VGA signals, and status outputs to physical FPGA pins.

## Game Design

### Game Objects

| Object | Configuration |
|---|---|
| Display resolution | 640 × 480 |
| Ball | 10 × 10 pixels |
| Paddle | 80 × 20 pixels |
| Brick layout | 5 rows × 10 columns |
| Brick dimensions | 60 × 20 pixels |
| Brick spacing | 4 pixels horizontally and 8 pixels vertically |
| VGA pixel clock | 25 MHz |
| Video color output | RGB 3:3:2 |

### Controls

| Input | Function |
|---|---|
| `left_btn` | Moves the paddle left |
| `right_btn` | Moves the paddle right |
| `start_btn` | Starts the game |
| `rst` | Resets the game state |

The paddle is constrained to the visible screen area. The ball bounces off the side and top boundaries, the paddle, and the bricks. Losing the ball sets the game-over signal, while clearing all bricks sets the win signal.

## Hardware Architecture

The design is divided into the following modules:

| Module | Responsibility |
|---|---|
| `breakout_game.v` | Top-level module connecting the game logic, controllers, clock divider, and VGA output |
| `ball_controller.v` | Ball movement, velocity updates, collision detection, and game-state flags |
| `paddle_controller.v` | Paddle positioning and left/right movement |
| `brick_controller.v` | Maintains the brick map and removes hit bricks |
| `vga_controller.v` | Generates VGA synchronization signals and RGB pixel data |
| `clk_div_25mhz.v` | Generates the pixel clock from the 100 MHz input clock |
| `constraints.ucf` | Assigns FPGA pins to the clock, buttons, VGA signals, and status outputs |

## VGA Display Generation

The VGA controller generates horizontal and vertical synchronization signals and determines the color of each pixel based on the positions of the game objects.

The display uses an 8-bit RGB interface:

- **Red:** 3 bits
- **Green:** 3 bits
- **Blue:** 2 bits

The game objects are rendered as follows:

- Ball: Blue
- Paddle: Red
- Bricks: Green
- Background: Black

The horizontal and vertical counters track the current display position, allowing the controller to determine whether each pixel belongs to the ball, paddle, a remaining brick, or the background.

## Technologies

- Verilog HDL
- FPGA-based digital system design
- VGA timing and graphics generation
- Clock division and timing logic
- Collision detection and finite game-state control
- Xilinx FPGA development tools

## Repository Structure

```text
FPGA-Atari-Breakout/
├── README.md
├── breakout_game.v
├── ball_controller.v
├── paddle_controller.v
├── brick_controller.v
├── paddle_controller.v
├── vga_controller.v
├── clk_div_25mhz.v
├── constraints.ucf
└── Project.mp4
```

`Project.mp4` contains a demonstration of the game running on a display.

## Getting Started

1. Extract the source files from the project archive.
2. Add the Verilog modules to a compatible FPGA development project.
3. Add the UCF constraints file and verify that the pin assignments match your FPGA development board.
4. Set `breakout_game` as the top-level module.
5. Synthesize and implement the design using a compatible FPGA toolchain.
6. Connect a VGA display and use the mapped board buttons to play the game.

For simulation, add a testbench that generates the input clock and exercises reset, start, paddle movement, collisions, and game-state transitions.

## Project Objectives

This project explores the practical application of digital logic design and hardware description languages to build an interactive system. It demonstrates how independent hardware modules can work together to implement motion, collision handling, timing, and display generation on an FPGA.

