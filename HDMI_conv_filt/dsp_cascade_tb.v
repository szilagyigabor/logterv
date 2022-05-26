`timescale 1ns / 1ps

module dsp_cascade_tb ();

  reg clk;
  reg rst;

  reg [7:0] in0;
  reg [7:0] in1;
  reg [7:0] in2;
  reg [7:0] in3;
  reg [7:0] in4;

  wire [7:0] out;

  dsp_cascade dsp(
     .clk(clk),
     .rst(rst),
     .sw(8'b10000000),
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
    in0={3'b000,5'b00001};
    //forever #2 in0[4:0]=in0[4:0]+1;
  end

  initial begin
    in1={3'b001,5'b00010};;
    //forever #2 in1[4:0]=in1[4:0]+1;
  end

  initial begin
    in2={3'b000,5'b00100};;
    //forever #2 in2[4:0]=in2[4:0]+1;
  end

  initial begin
    in3={3'b000,5'b01000};;
    //forever #2 in3[4:0]=in3[4:0]+1;
  end

  initial begin
    in4={3'b000,5'b10000};;
    forever #2 in4[4:0]=in4[4:0]+1;
  end



endmodule
