`timescale 1ns / 1ps

module bram_delay_tb ();

  // inputs
  reg clk;
  reg rst;

  reg [7:0] din;
  reg       st_i;

  // outputs
  wire [7:0] pa;
  wire [7:0] pb;
  wire [7:0] pc;
  wire [7:0] pd;
  wire [7:0] pe;
  wire       st_o;

  reg [11:0] addr_reg;
always @(posedge clk) begin
  if (rst) begin
    addr_reg <= 0;
  end else if ( addr_reg == 19 ) begin
    addr_reg <= 0;
  end else begin
    addr_reg <= addr_reg + 1;
  end
end

  bram_delay bram(
     .clk(clk),
     .rst(rst),
     .data_in(din),
     .stat_in(st_i),
     .addr(addr_reg),

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
    #2
    rst = 0;
  end

  initial begin
  // A pixelek késleltetését letesztelni elég egyszerű,
  // egy számlálót kell beadni neki
  // és összehasonlítani a kimenet eltolódását a bemenethez képest
    din = 0;
    #1
    forever #2 din = din + 1;
  end


  integer i;
  initial begin
  // A status jelek késleltetését jellegzetes impulzusszélességekkel
  // lehet jól ellenőrizni
    st_i=0;
    for (i=2; i<500; i=i+2) begin
      #i
      st_i=1;
      #i
      st_i=0;
    end
  end

endmodule
