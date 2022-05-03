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
wire hs = stat_in[1];

// counter to set picture line length
// current line is delayed according to
// the length of the previous line
reg [11:0] pic_width;
reg [11:0] pic_w_cntr;
reg [11:0] pic_w_cntr_prev;
always @(posedge clk) begin
  if (rst) begin
    pic_w_cntr <= 0;
    pic_w_cntr_prev <= 0;
  end else if (hs) begin
    pic_width <= pic_w_cntr_prev;
    pic_w_cntr <= 0;
  end
  pic_w_cntr_prev <= pic_w_cntr;
end

// calculate address for single port blockrams
// to work cyclically
reg [10:0] addr_reg; //TODO: hossz = log2 sp_ram hossz
always @(posedge clk) begin
  if (rst) begin
    addr_reg <= 0;
  end else if ( addr_reg == pic_width ) begin
    addr_reg <= 0;
  end else begin
    addr_reg <= addr_reg + 1;
  end
end


wire [26:0] del0_out;
sp_ram bram_delay0(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr_reg),
  .din({stat_in, data_in}),
  .dout(del0_out)
);

wire [26:0] del1_out;
sp_ram bram_delay1(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr_reg),
  .din(del0_out),
  .dout(del1_out)
);

wire [26:0] del2_out;
sp_ram bram_delay2(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr_reg),
  .din(del1_out),
  .dout(del2_out)
);
wire [26:0] del3_out;
sp_ram bram_delay3(
  .clk(clk),
  .en(1),
  .we(1),
  .addr(addr_reg),
  .din(del2_out),
  .dout(del3_out)
);

assign pa = data_in;
assign pb = del0_out[23:0];
assign pc = del1_out[23:0];
assign pd = del2_out[23:0];
assign pe = del3_out[23:0];
assign stat_o = del3_out[26:24];

endmodule
