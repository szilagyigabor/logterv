module conv_filt (
   input       clk,
   input       rst,

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
   output       tx_vs,
);

// coming out from BRAM,
// into shift reg
reg dv;
reg hs;
reg vs;

wire [7:0] red_v;
wire [7:0] green_v;
wire [7:0] blue_v;

assign red_v   = (rx_red   & {8{rx_dv}});
assign green_v = (rx_green & {8{rx_dv}});
assign blue_v  = (rx_blue  & {8{rx_dv}});

reg [23:0] bram_pa;
reg [23:0] bram_pb;
reg [23:0] bram_pc;
reg [23:0] bram_pd;
reg [23:0] bram_pe;

bram_delay bram_delay_0(
   .clk(clk),
   .rst(rst),
   .data_in({red_v, green_v, blue_v}),
   .cntr_in({rx_dv, rx_hs, rx_vs}),
   .pa(bram_pa),
   .pb(bram_pb),
   .pc(bram_pc),
   .pd(bram_pd),
   .pe(bram_pe),
   .cntr_out({dv, hs, vs})
);

dsp_cascade dsp0(
   .clk(clk),
   .rst(rst),
   .pa(bram_pa[7:0]),
   .pb(bram_pb[7:0]),
   .pc(bram_pc[7:0]),
   .pd(bram_pd[7:0]),
   .pe(bram_pe[7:0]),

   .p_out(tx_blue)
);
dsp_cascade dsp1(
   .clk(clk),
   .rst(rst),
   .pa(bram_pa[15:8]),
   .pb(bram_pb[15:8]),
   .pc(bram_pc[15:8]),
   .pd(bram_pd[15:8]),
   .pe(bram_pe[15:8]),

   .p_out(tx_green)
);

dsp_cascade dsp2(
   .clk(clk),
   .rst(rst),
   .pa(bram_pa[23:16]),
   .pb(bram_pb[23:16]),
   .pc(bram_pc[23:16]),
   .pd(bram_pd[23:16]),
   .pe(bram_pe[23:16]),

   .p_out(tx_red)
);

// TODO: exact length to be determined
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
