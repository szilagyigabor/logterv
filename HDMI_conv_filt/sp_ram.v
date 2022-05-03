`timescale 1ns / 1ps
//TODO: parameters for depth, and width
module sp_ram (
  input         clk,
  input         we,
  input         en,
  input  [10:0] addr,
  input  [7:0]  din,
  output [7:0]  dout
);

reg [7:0] memory[2047:0];
reg [7:0] dout_reg;

always @(posedge clk) begin
  if (en) begin
    if (we) begin
      memory[addr] <= din;
    end
    dout_reg <= memory[addr];
  end
end

assign dout = dout_reg;

endmodule
