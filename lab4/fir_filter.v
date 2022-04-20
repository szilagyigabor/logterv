`timescale 1ns / 1ps

module fir_filter(
      input clk,
      input rst,

      input [1:0] din_valid,
      input [23:0] din,

      output [1:0] dout_valid,
      output [23:0] dout
);

// vezérlõ állapot (-> memória címek érvényesek):
//  0: nincs szûrés
//  1: aktív szûrés
//TODO state
reg state;
reg [8:0] state_cntr;
always @(posedge clk) begin
   if (|din_valid) begin
      state <= 1;
      state_cntr <= 0;
   end else begin
      state_cntr <= state_cntr + 1;
      if (state_cntr[8]) begin
         state <= 0;
      end
   end
end
// együttható címszámláló
//  255...0 között számol, konvolúció kezdetekor 255-re állítjuk
reg [7:0] coeff_addr_reg;
always @(posedge clk) begin
   if (state==1 and state_dl==0) begin
      coeff_addr_reg <= 255;
   end else begin
      coeff_addr_reg <= coeff_addr_reg - 1;
   end
end

if

// feldolgozás alatt álló csatorna
// konvolúció kezdetekor elmentjük, hogy melyik bemenet volt érvényes
reg ch_act;
always @(posedge clk) begin
   if (state==1 and state_dl==0) begin
      ch_act <= (din_valid==2'b1) ? 0 : 1;
   end
end


// aktív szûrés (state) késleltetése
reg state_dl;// eredeti: reg [7:0] state_dl;
//TODO: ez miért 8 bit?
always @(posedge clk) begin
   state_dl <= state;
end


// együttható ROM cím:
//   {aktív csatorna, együttható címszámláló}
wire [8:0] coeff_addr;
assign coeff_addr = {ch_act, coeff_addr_reg};


// minta írási címszámláló
//   din_valid[1]-re inkrementál
//   TODO itt szerintem hiányzik egy reszet
reg [7:0] smpl_wr_addr_reg;
always @(posedge clk) begin
   if (din_valid[1]) begin
      smpl_wr_addr_reg <= smpl_wr_addr_reg + 1;
   end
end


// minta írási cím
//   {input valid, címszámláló}
wire [8:0] smpl_wr_addr;
assign smpl_wr_addr = {din_valid[1], smpl_wr_addr_reg};


// olvasási címszámláló
// smpl_wr_addr_reg_rõl indul új minta érkezésekor, dekrementálódik
reg [7:0] smpl_rd_addr_reg;
always @(posedge clk) begin
  if (|din_valid) begin
      smpl_rd_addr_reg <= smpl_wr_addr_reg;
   end else begin
      smpl_rd_addr_reg <= smpl_rd_addr_reg - 1;
   end
end


// olvasási cím: {aktív csatorna, címszámláló}
wire [8:0] smpl_rd_addr;
assign smpl_rd_addr = {ch_act, smpl_rd_addr_reg};



// bementi minták: s.23
wire [23:0] smpl_ram_dout;
ram #(
   .DATA_W(24),
   .ADDR_W(9)
)
smpl_ram(
   .clk_a  (clk),
   .we_a   ((din_valid!=0)),
   .addr_a (smpl_wr_addr),
   .din_a  (din),
   .dout_a (),
   .clk_b  (clk),
   .we_b   (1'b0),
   .addr_b (smpl_rd_addr),
   .din_b  (36'b0),
   .dout_b (smpl_ram_dout)
);

// Együttható ROM
// együtthatók: s.3.31
wire [34:0] coeff_rom_dout;
rom_512x35 coeff_rom(
   .clk  (clk),
   .addr (coeff_addr),
   .dout (coeff_rom_dout)
);


// részszorzat érdekes része:
// minta: 24 bit
// coeff: 35 bit
//    azaz:  59 bit
//  s.23*s.3.31 = s.4.54
wire signed [58:0] mul_res;
mul_24x35 mul_fir(
      .clk  (clk),
      .a    (smpl_ram_dout),
      .b    (coeff_rom_dout),
      .m    (mul_res)
);


// Accu reset: az első érvényes bemenet alatt
// Engedélyezés: amikor érvényes a bemenete (state[1] késleltetve pipeline latency-vel)
wire accu_rst;
wire accu_en;
//TODO
assign accu_rst = din_valid[0] || din_valid[1];

always @(posedge clk) begin
	if (din_valid[0] || din_valid[1]) begin
		accu_en <= 1;
	end
	else
		if (coeff_addr_reg) begin
			
		end
	end
end


// Reset: az érvényes bemenetet írjuk be akkumulálás nélkül
// 256 db s.4.54 összege --> s.12.54 --> 67 bit
reg signed [66:0] accu;
always @(posedge clk) begin
   if (accu_rst) begin
      accu <= mul_res;
   end else if (accu_en) begin
      accu <= accu + mul_res;
   end
end





// kimeneti formátum: s.23,
//  accu eredmény-bõl levágjuk az alsó 31 bitet, az ezt követõ 24 bit az érvényes kimenet
//  kivéve ha túlcsordulás van, ekkor szaturáció:
//    - pozitív: +0.999999 --> h7fffff
//    - negatív: -1        --> h800000

//  Kimenet érvényes: csatorna + accu_en lefutó él
reg [23:0] dout_reg; //=accu[31+24:31];
always @(posedge clk) begin
   if (accu[66]==1 and accu[65:54] != 12'hfff) begin
      dout_reg <= 24'h800000;
   end else if (accu[66] == 0 and accu[65:54] != 12'h0) begin
      dout_reg <= 24'h7fffff;
   end else begin
      dout_reg <= accu[53:31]
   end
end

reg  [1:0] dout_valid_reg;
always @(negedge accu_en) begin
  if (ch_act) begin
      dout_valid <= 2'h2;
   end else begin
      dout_valid <= 2'h1;
   end
end



assign dout = dout_reg;
assign dout_valid = dout_valid_reg;


endmodule
