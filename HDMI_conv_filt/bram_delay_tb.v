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

     .pa(pa)
     .pb(pb)
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
  // A pixelek késleltetését letesztelni elég egyszerű,
  // egy számlálót kell beadni neki
  // és összehasonlítani a kimenet eltolódását a bemenethez képest
    din = 0;
    #2
    forever #2 din = din + 1;
  end


  integer i;
  initial begin
  // A status jelek késleltetését jellegzetes impulzusszélességekkel
  // lehet jól ellenőrizni
    st_i[0]=0;
    for (i=2; i<500; i=i+2) begin
      #i
      st_i[0]=1;
      #i
      st_i[0]=0;
    end
  end

  integer j;
  initial begin
  // A status jelek késleltetését jellegzetes impulzusszélességekkel
  // lehet jól ellenőrizni
    st_i[1]=0;
    for (j=2; j<500; j=j+2) begin
      #j
      st_i[1]=1;
      #j
      st_i[1]=0;
    end
  end

  integer k;
  initial begin
  // A status jelek késleltetését jellegzetes impulzusszélességekkel
  // lehet jól ellenőrizni
    st_i[2]=0;
    #2
    for (k=2; k<500; k=k+2) begin
      #k
      st_i[2]=1;
      #k
      st_i[2]=0;
    end
  end

endmodule
