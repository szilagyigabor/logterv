`timescale 1ns / 1ps

module conv_filt (
   input       clk,
   input       rst,
   input [7:0] sw,


   input [7:0] rx_red,
   input [7:0] rx_green,
   input [7:0] rx_blue,
   input       rx_dv,
   input       rx_hs,
   input       rx_vs,

   output [7:0] tx_red,
   output [7:0] tx_green,
   output [7:0] tx_blue,
   output       tx_dv,
   output       tx_hs,
   output       tx_vs
);

// coming out from BRAM,
// into shift reg
wire dv;
wire hs;
wire vs;

wire [7:0] red_v;
wire [7:0] green_v;
wire [7:0] blue_v;

assign red_v   = (rx_red   & {8{rx_dv}});
assign green_v = (rx_green & {8{rx_dv}});
assign blue_v  = (rx_blue  & {8{rx_dv}});


// counter to set picture line length
// current line is delayed according to
// the length of the previous line
reg [11:0] pic_width;
always @(posedge clk) begin
   pic_width <= 1599;
end

// calculate address for single port blockrams
// to work cyclically
reg [11:0] addr_reg;
always @(posedge clk) begin
  if (rst) begin
    addr_reg <= 0;
  end else if ( addr_reg == pic_width ) begin
    addr_reg <= 0;
  end else begin
    addr_reg <= addr_reg + 1;
  end
end

///////////////////// red
wire [7:0] bram_pa_red;
wire [7:0] bram_pb_red;
wire [7:0] bram_pc_red;
wire [7:0] bram_pd_red;
wire [7:0] bram_pe_red;

bram_delay bram_delay_0(
   .clk(clk),
   .rst(rst),
   .data_in(red_v),
   .stat_in(rx_dv),
   .addr(addr_reg),

   .pa(bram_pa_red),
   .pb(bram_pb_red),
   .pc(bram_pc_red),
   .pd(bram_pd_red),
   .pe(bram_pe_red),
   .stat_o(dv)
);
dsp_cascade dsp0(
   .clk(clk),
   .rst(rst),
   .sw(sw),

   .pa(bram_pa_red),
   .pb(bram_pb_red),
   .pc(bram_pc_red),
   .pd(bram_pd_red),
   .pe(bram_pe_red),

   .p_out(tx_red)
);

///////////////////// green
wire [7:0] bram_pa_green;
wire [7:0] bram_pb_green;
wire [7:0] bram_pc_green;
wire [7:0] bram_pd_green;
wire [7:0] bram_pe_green;

bram_delay bram_delay_1(
   .clk(clk),
   .rst(rst),
   .data_in(green_v),
   .stat_in(rx_hs),
   .addr(addr_reg),

   .pa(bram_pa_green),
   .pb(bram_pb_green),
   .pc(bram_pc_green),
   .pd(bram_pd_green),
   .pe(bram_pe_green),
   .stat_o(hs)
);
dsp_cascade dsp1(
   .clk(clk),
   .rst(rst),
   .sw(sw),

   .pa(bram_pa_green),
   .pb(bram_pb_green),
   .pc(bram_pc_green),
   .pd(bram_pd_green),
   .pe(bram_pe_green),

   .p_out(tx_green)
);

///////////////////// blue
wire [7:0] bram_pa_blue;
wire [7:0] bram_pb_blue;
wire [7:0] bram_pc_blue;
wire [7:0] bram_pd_blue;
wire [7:0] bram_pe_blue;

bram_delay bram_delay_2(
   .clk(clk),
   .rst(rst),
   .data_in(blue_v),
   .stat_in(rx_vs),
   .addr(addr_reg),

   .pa(bram_pa_blue),
   .pb(bram_pb_blue),
   .pc(bram_pc_blue),
   .pd(bram_pd_blue),
   .pe(bram_pe_blue),
   .stat_o(vs)
);
dsp_cascade dsp2(
   .clk(clk),
   .rst(rst),
   .sw(sw),

   .pa(bram_pa_blue),
   .pb(bram_pb_blue),
   .pc(bram_pc_blue),
   .pd(bram_pd_blue),
   .pe(bram_pe_blue),

   .p_out(tx_blue)
);

// TODO: exact length to be determined
// eggyel jobbra kéne csússzon a kép
reg [25:0] dv_shr;
reg [25:0] hs_shr;
reg [25:0] vs_shr;
always @(posedge clk) begin
   if (rst) begin
      dv_shr <= 0;
      hs_shr <= 0;
      vs_shr <= 0;
   end else begin
      dv_shr <= {dv_shr[24:0],dv};
      hs_shr <= {hs_shr[24:0],hs};
      vs_shr <= {vs_shr[24:0],vs};
   end
end
assign tx_dv = dv_shr[25];
assign tx_hs = hs_shr[25];
assign tx_vs = vs_shr[25];
endmodule
