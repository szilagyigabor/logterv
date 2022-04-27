`timescale 1ns / 1ps

module dsp_cascade_tb ();

  reg clk;
  reg rst;

  reg [7:0] in0;
  reg [7:0] in1;
  reg [7:0] in2;
  reg [7:0] in3;
  reg [7:0] in4;

  reg [7:0] out;

  dsp_cascade dsp(
     .clk(clk),
     .rst(rst),
     .pa(in0),
     .pb(in1),
     .pc(in2),
     .pd(in3),
     .pe(in4),

     .p_out(out)
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
