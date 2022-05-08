`timescale 1ns / 1ps
module sp_ram (
  input         clk,
  input         we,
  input         en,
  input  [11:0] addr, // log2 4096
  input  [8:0]  din,
  output [8:0]  dout
);

// 8 bit pixel value + 1 status bit
reg [8:0] memory[4095:0];
reg [8:0] dout_reg;

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
