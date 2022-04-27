`timescale 1ns / 1ps

module bram_delay (
  input         clk,
  input         rst,
  input  [23:0] data_in,
  input  [2:0]  stat_in,

  output [23:0] pa,
  output [23:0] pb,
  output [23:0] pc,
  output [23:0] pd,
  output [23:0] pe,
  output [2:0]  stat_o
);

endmodule
