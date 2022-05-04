`timescale 1ns / 1ps

module bram_delay (
  input         clk,
  input         rst,
  input  [7:0]  data_in,
  input         stat_in,
  input  [11:0] addr,

  output [7:0]  pa,
  output [7:0]  pb,
  output [7:0]  pc,
  output [7:0]  pd,
  output [7:0]  pe,
  output        stat_o
);

wire [8:0] del0_out;
sp_ram bram_delay0(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr),
  .din({stat_in, data_in}),
  .dout(del0_out)
);

wire [8:0] del1_out;
sp_ram bram_delay1(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr),
  .din(del0_out),
  .dout(del1_out)
);

wire [8:0] del2_out;
sp_ram bram_delay2(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr),
  .din(del1_out),
  .dout(del2_out)
);
wire [8:0] del3_out;
sp_ram bram_delay3(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr),
  .din(del2_out),
  .dout(del3_out)
);

assign pa = data_in;
assign pb = del0_out[7:0];
assign pc = del1_out[7:0];
assign pd = del2_out[7:0];
assign pe = del3_out[7:0];
assign stat_o = del3_out[8];

endmodule
