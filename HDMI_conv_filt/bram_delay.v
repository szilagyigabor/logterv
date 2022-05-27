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
  .en(1'b1),
  .we(1'b1),
  .addr(addr),
  .din({stat_in, data_in}),
  .dout(del0_out)
);

wire [8:0] del1_out;
sp_ram bram_delay1(
  .clk(clk),
  .en(1'b1),
  .we(1'b1),
  .addr(addr),
  .din(del0_out),
  .dout(del1_out)
);

wire [8:0] del2_out;
sp_ram bram_delay2(
  .clk(clk),
  .en(1'b1),
  .we(1'b1),
  .addr(addr),
  .din(del1_out),
  .dout(del2_out)
);
wire [8:0] del3_out;
sp_ram bram_delay3(
  .clk(clk),
  .en(1'b1),
  .we(1'b1),
  .addr(addr),
  .din(del2_out),
  .dout(del3_out)
);

// ossze lehet vonni a kovetkezo modul
// keslelteteseivel

// eltolodas javitasa
reg [4*9-1:0] pashr;
reg [3*9-1:0] pbshr;
reg [2*9-1:0] pcshr;
reg [1*9-1:0] pdshr;
always @(posedge clk) begin
    if (rst) begin
        pashr <= 0;
        pbshr <= 0;
        pcshr <= 0;
        pdshr <= 0;
    end
    else begin
        pashr <= { pashr[3*9-1:0], {stat_in, data_in}};
        pbshr <= { pbshr[2*9-1:0], del0_out};
        pcshr <= { pcshr[1*9-1:0], del1_out};
        pdshr <= {                 del2_out};
    end
end

assign pa = pashr[4*9-2:3*9];
assign pb = pbshr[3*9-2:2*9];
assign pc = pcshr[2*9-2:1*9];
assign pd = pdshr[7:0];
assign pe = del3_out[7:0];
assign stat_o = del1_out[8];
endmodule
