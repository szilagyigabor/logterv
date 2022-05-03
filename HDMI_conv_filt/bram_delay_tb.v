`timescale 1ns / 1ps

module bram_delay_tb ();

  // inputs
  reg clk;
  reg rst;

  reg [23:0] din;
  reg [2:0]  st_in;

  // outputs
  reg [23:0] pa;
  reg [23:0] pb;
  reg [23:0] pc;
  reg [23:0] pd;
  reg [23:0] pe;
  reg [2:0]  st_o;

  bram_delay bram(
     .clk(clk),
     .rst(rst),
     .data_in(din),
     .stat_in(st_in),

     .pa(pa),
     .pb(pb),
     .pc(pc),
     .pd(pd),
     .pe(pe),
     .stat_o(st_o)
  );

  initial begin
    clk = 0;
    forever #1 clk = ~clk;
  end

  initial begin
    rst = 1;
    #10
    rst = 0;
  end

  initial begin
  // add stimulus here
  end



endmodule
