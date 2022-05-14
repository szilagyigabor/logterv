`timescale 1ns / 1ps

module dsp_cascade (
  input         clk,
  input         rst,
  input  [7:0]  pa, // a bemenetek a még nem késleltetett jelek
  input  [7:0]  pb,
  input  [7:0]  pc,
  input  [7:0]  pd,
  input  [7:0]  pe,
  input  [17:0]  coeff[24:0],

  output [7:0]  p_out
);

// a 25 mély tömb a 25 kaszkád DSP ki- és bemenetei között
wire [47:0] pcascout[24:0];

// dummy 48 bites kimeneti wire az utolsó DSP kimenetén.
// Ebből csak a megfelelő 8 bit az értelmes pixelérték,
// ezek kiválasztandók
wire [47:0] fullsum;
assign p_out = fullsum[23:16];

// késleltető shiftregisterek a bemeneti pixelértékeknek
reg [8:0] pbshr[4:0];
reg [8:0] pcshr[9:0];
reg [8:0] pdshr[14:0];
reg [8:0] peshr[19:0];
always @(posedge clk) begin
    if (rst) begin
        pbshr <= 0;
        pcshr <= 0;
        pdshr <= 0;
        peshr <= 0;
    end
    else begin
        pbshr <= {pb, pbshr[4:1]}; 
        pcshr <= {pc, pcshr[9:1]}; 
        pdshr <= {pd, pdshr[14:1]}; 
        peshr <= {pe, peshr[19:1]}; 
    end
end

// a megfelelően késleltetett pixel világosság-
// -értékek bemenetekhez rendelése, 5-ös csoportokban
wire [7:0] pixelvalues[24:0];
genvar k;
generate;
    for (k=0;k<5;k=k+1)
    begin: gen_pval
        assign pixelvalues[k] = pa;
        assign pixelvalues[k+5] = pb;
        assign pixelvalues[k+10] = pc;
        assign pixelvalues[k+15] = pd;
        assign pixelvalues[k+20] = pe;
    end
endgenerate

//// az első DSP a sorban külön ////
DSP48E1 #(
  // Feature Control Attributes: Data Path Selection
  .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
  .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
  // Pattern Detector Attributes: Pattern Detection Configuration
  .AUTORESET_PATDET("NO_RESET"),    // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  .MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
  .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
  .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
  .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
  // Register Control Attributes: Pipeline Register Configuration
  .ACASCREG(0),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  .ADREG(0),                        // Number of pipeline stages for pre-adder (0 or 1)
  .ALUMODEREG(0),                   // Number of pipeline stages for ALUMODE (0 or 1)
  .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
  .BCASCREG(0),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
  .CARRYINREG(0),                   // Number of pipeline stages for CARRYIN (0 or 1)
  .CARRYINSELREG(0),                // Number of pipeline stages for CARRYINSEL (0 or 1)
  .CREG(0),                         // Number of pipeline stages for C (0 or 1)
  .DREG(0),                         // Number of pipeline stages for D (0 or 1)
  .INMODEREG(0),                    // Number of pipeline stages for INMODE (0 or 1)
  .MREG(1),                         // Number of multiplier pipeline stages (0 or 1)
  .OPMODEREG(0),                    // Number of pipeline stages for OPMODE (0 or 1)
  .PREG(1)                          // Number of pipeline stages for P (0 or 1)
)
DSP48E1_inst (
  // Cascade: 30-bit (each) output: Cascade Ports
  .ACOUT(),                   // 30-bit output: A port cascade output
  .BCOUT(),                   // 18-bit output: B port cascade output
  .CARRYCASCOUT(),     // 1-bit output: Cascade carry output
  .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade output
  .PCOUT(pcascout[0]),                   // 48-bit output: Cascade output
  // Control: 1-bit (each) output: Control Inputs/Status Bits
  .OVERFLOW(),             // 1-bit output: Overflow in add/acc output
  .PATTERNBDETECT(), // 1-bit output: Pattern bar detect output
  .PATTERNDETECT(),   // 1-bit output: Pattern detect output
  .UNDERFLOW(),           // 1-bit output: Underflow in add/acc output
  // Data: 4-bit (each) output: Data Ports
  .CARRYOUT(),             // 4-bit output: Carry output
  .P(),                           // 48-bit output: Primary data output
  // Cascade: 30-bit (each) input: Cascade Ports
  .ACIN(30'b1),                     // 30-bit input: A cascade data input
  .BCIN(18'b1),                     // 18-bit input: B cascade input
  .CARRYCASCIN(1'b1),       // 1-bit input: Cascade carry input
  .MULTSIGNIN(1'b1),         // 1-bit input: Multiplier sign input
  .PCIN(48'b1),                     // 48-bit input: P cascade input
  // Control: 4-bit (each) input: Control Inputs/Status Bits
  .ALUMODE(4'b0000),               // 4-bit input: ALU control input
  .CARRYINSEL(3'b000),         // 3-bit input: Carry select input
  .CLK(clk),                       // 1-bit input: Clock input
  .INMODE(5'b00000),                 // 5-bit input: INMODE control input
  .OPMODE(7'b0000101),                 // 7-bit input: Operation mode input
  // Data: 30-bit (each) input: Data Ports
  .A({22'h000000, pixelvalues[0]}),                           // 30-bit input: A data input
  .B(coeff[0]),                           // 18-bit input: B data input
  .C(48'b1),                           // 48-bit input: C data input
  .CARRYIN(1'b0),               // 1-bit input: Carry input signal
  .D(25'h1),                           // 25-bit input: D data input
  // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  .CEA1(1'b0),                     // 1-bit input: Clock enable input for 1st stage AREG
  .CEA2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage AREG
  .CEAD(1'b0),                     // 1-bit input: Clock enable input for ADREG
  .CEALUMODE(1'b0),           // 1-bit input: Clock enable input for ALUMODE
  .CEB1(1'b0),                     // 1-bit input: Clock enable input for 1st stage BREG
  .CEB2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage BREG
  .CEC(1'b0),                       // 1-bit input: Clock enable input for CREG
  .CECARRYIN(1'b0),           // 1-bit input: Clock enable input for CARRYINREG
  .CECTRL(1'b1),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  .CED(1'b0),                       // 1-bit input: Clock enable input for DREG
  .CEINMODE(1'b1),             // 1-bit input: Clock enable input for INMODEREG
  .CEM(1'b1),                       // 1-bit input: Clock enable input for MREG
  .CEP(1'b1),                       // 1-bit input: Clock enable input for PREG
  .RSTA(rst),                     // 1-bit input: Reset input for AREG
  .RSTALLCARRYIN(1'b0),   // 1-bit input: Reset input for CARRYINREG
  .RSTALUMODE(1'b0),         // 1-bit input: Reset input for ALUMODEREG
  .RSTB(rst),                     // 1-bit input: Reset input for BREG
  .RSTC(1'b0),                     // 1-bit input: Reset input for CREG
  .RSTCTRL(1'b0),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  .RSTD(rst),                     // 1-bit input: Reset input for DREG and ADREG
  .RSTINMODE(1'b0),           // 1-bit input: Reset input for INMODEREG
  .RSTM(rst),                     // 1-bit input: Reset input for MREG
  .RSTP(rst)                      // 1-bit input: Reset input for PREG
);
// End of DSP48E1_inst instantiation


// A 2.-tól a 24.-ig példányosítás:
genvar i;
generate
    for (i=1; i<25; i=i+1)
    begin: gen_dsp

DSP48E1 #(
  // Feature Control Attributes: Data Path Selection
  .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
  .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
  // Pattern Detector Attributes: Pattern Detection Configuration
  .AUTORESET_PATDET("NO_RESET"),    // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  .MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
  .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
  .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
  .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
  // Register Control Attributes: Pipeline Register Configuration
  .ACASCREG(0),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  .ADREG(0),                        // Number of pipeline stages for pre-adder (0 or 1)
  .ALUMODEREG(0),                   // Number of pipeline stages for ALUMODE (0 or 1)
  .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
  .BCASCREG(0),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
  .CARRYINREG(0),                   // Number of pipeline stages for CARRYIN (0 or 1)
  .CARRYINSELREG(0),                // Number of pipeline stages for CARRYINSEL (0 or 1)
  .CREG(0),                         // Number of pipeline stages for C (0 or 1)
  .DREG(0),                         // Number of pipeline stages for D (0 or 1)
  .INMODEREG(0),                    // Number of pipeline stages for INMODE (0 or 1)
  .MREG(1),                         // Number of multiplier pipeline stages (0 or 1)
  .OPMODEREG(0),                    // Number of pipeline stages for OPMODE (0 or 1)
  .PREG(1)                          // Number of pipeline stages for P (0 or 1)
)
DSP48E1_inst (
  // Cascade: 30-bit (each) output: Cascade Ports
  .ACOUT(),                   // 30-bit output: A port cascade output
  .BCOUT(),                   // 18-bit output: B port cascade output
  .CARRYCASCOUT(),     // 1-bit output: Cascade carry output
  .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade output
  .PCOUT(pcascout[i]),                   // 48-bit output: Cascade output
  // Control: 1-bit (each) output: Control Inputs/Status Bits
  .OVERFLOW(),             // 1-bit output: Overflow in add/acc output
  .PATTERNBDETECT(), // 1-bit output: Pattern bar detect output
  .PATTERNDETECT(),   // 1-bit output: Pattern detect output
  .UNDERFLOW(),           // 1-bit output: Underflow in add/acc output
  // Data: 4-bit (each) output: Data Ports
  .CARRYOUT(),             // 4-bit output: Carry output
  .P(),                           // 48-bit output: Primary data output
  // Cascade: 30-bit (each) input: Cascade Ports
  .ACIN(30'b1),                     // 30-bit input: A cascade data input
  .BCIN(18'b1),                     // 18-bit input: B cascade input
  .CARRYCASCIN(1'b1),       // 1-bit input: Cascade carry input
  .MULTSIGNIN(1'b1),         // 1-bit input: Multiplier sign input
  .PCIN(pcascout[i-1]),                     // 48-bit input: P cascade input
  // Control: 4-bit (each) input: Control Inputs/Status Bits
  .ALUMODE(4'b0000),               // 4-bit input: ALU control input
  .CARRYINSEL(3'b000),         // 3-bit input: Carry select input
  .CLK(clk),                       // 1-bit input: Clock input
  .INMODE(5'b00000),                 // 5-bit input: INMODE control input
  .OPMODE(7'b0010101),                 // 7-bit input: Operation mode input
  // Data: 30-bit (each) input: Data Ports
  .A({22'h000000, pixelvalues[i]}),                           // 30-bit input: A data input
  .B(coeff[i]),                           // 18-bit input: B data input
  .C(48'b1),                           // 48-bit input: C data input
  .CARRYIN(1'b0),               // 1-bit input: Carry input signal
  .D(25'h1),                           // 25-bit input: D data input
  // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  .CEA1(1'b0),                     // 1-bit input: Clock enable input for 1st stage AREG
  .CEA2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage AREG
  .CEAD(1'b0),                     // 1-bit input: Clock enable input for ADREG
  .CEALUMODE(1'b0),           // 1-bit input: Clock enable input for ALUMODE
  .CEB1(1'b0),                     // 1-bit input: Clock enable input for 1st stage BREG
  .CEB2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage BREG
  .CEC(1'b0),                       // 1-bit input: Clock enable input for CREG
  .CECARRYIN(1'b0),           // 1-bit input: Clock enable input for CARRYINREG
  .CECTRL(1'b1),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  .CED(1'b0),                       // 1-bit input: Clock enable input for DREG
  .CEINMODE(1'b1),             // 1-bit input: Clock enable input for INMODEREG
  .CEM(1'b1),                       // 1-bit input: Clock enable input for MREG
  .CEP(1'b1),                       // 1-bit input: Clock enable input for PREG
  .RSTA(rst),                     // 1-bit input: Reset input for AREG
  .RSTALLCARRYIN(1'b0),   // 1-bit input: Reset input for CARRYINREG
  .RSTALUMODE(1'b0),         // 1-bit input: Reset input for ALUMODEREG
  .RSTB(rst),                     // 1-bit input: Reset input for BREG
  .RSTC(1'b0),                     // 1-bit input: Reset input for CREG
  .RSTCTRL(1'b0),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  .RSTD(rst),                     // 1-bit input: Reset input for DREG and ADREG
  .RSTINMODE(1'b0),           // 1-bit input: Reset input for INMODEREG
  .RSTM(rst),                     // 1-bit input: Reset input for MREG
  .RSTP(rst)                      // 1-bit input: Reset input for PREG
);
// End of DSP48E1_inst instantiation		
    end
endgenerate

//// a legutolsó DSP külön ////
DSP48E1 #(
  // Feature Control Attributes: Data Path Selection
  .A_INPUT("DIRECT"),               // Selects A input source, "DIRECT" (A port) or "CASCADE" (ACIN port)
  .B_INPUT("DIRECT"),               // Selects B input source, "DIRECT" (B port) or "CASCADE" (BCIN port)
  .USE_DPORT("FALSE"),              // Select D port usage (TRUE or FALSE)
  .USE_MULT("MULTIPLY"),            // Select multiplier usage ("MULTIPLY", "DYNAMIC", or "NONE")
  .USE_SIMD("ONE48"),               // SIMD selection ("ONE48", "TWO24", "FOUR12")
  // Pattern Detector Attributes: Pattern Detection Configuration
  .AUTORESET_PATDET("NO_RESET"),    // "NO_RESET", "RESET_MATCH", "RESET_NOT_MATCH" 
  .MASK(48'h3fffffffffff),          // 48-bit mask value for pattern detect (1=ignore)
  .PATTERN(48'h000000000000),       // 48-bit pattern match for pattern detect
  .SEL_MASK("MASK"),                // "C", "MASK", "ROUNDING_MODE1", "ROUNDING_MODE2" 
  .SEL_PATTERN("PATTERN"),          // Select pattern value ("PATTERN" or "C")
  .USE_PATTERN_DETECT("NO_PATDET"), // Enable pattern detect ("PATDET" or "NO_PATDET")
  // Register Control Attributes: Pipeline Register Configuration
  .ACASCREG(0),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  .ADREG(0),                        // Number of pipeline stages for pre-adder (0 or 1)
  .ALUMODEREG(0),                   // Number of pipeline stages for ALUMODE (0 or 1)
  .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
  .BCASCREG(0),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
  .CARRYINREG(0),                   // Number of pipeline stages for CARRYIN (0 or 1)
  .CARRYINSELREG(0),                // Number of pipeline stages for CARRYINSEL (0 or 1)
  .CREG(0),                         // Number of pipeline stages for C (0 or 1)
  .DREG(0),                         // Number of pipeline stages for D (0 or 1)
  .INMODEREG(0),                    // Number of pipeline stages for INMODE (0 or 1)
  .MREG(1),                         // Number of multiplier pipeline stages (0 or 1)
  .OPMODEREG(0),                    // Number of pipeline stages for OPMODE (0 or 1)
  .PREG(1)                          // Number of pipeline stages for P (0 or 1)
)
DSP48E1_inst (
  // Cascade: 30-bit (each) output: Cascade Ports
  .ACOUT(),                   // 30-bit output: A port cascade output
  .BCOUT(),                   // 18-bit output: B port cascade output
  .CARRYCASCOUT(),     // 1-bit output: Cascade carry output
  .MULTSIGNOUT(),       // 1-bit output: Multiplier sign cascade output
  .PCOUT(),                   // 48-bit output: Cascade output
  // Control: 1-bit (each) output: Control Inputs/Status Bits
  .OVERFLOW(),             // 1-bit output: Overflow in add/acc output
  .PATTERNBDETECT(), // 1-bit output: Pattern bar detect output
  .PATTERNDETECT(),   // 1-bit output: Pattern detect output
  .UNDERFLOW(),           // 1-bit output: Underflow in add/acc output
  // Data: 4-bit (each) output: Data Ports
  .CARRYOUT(),             // 4-bit output: Carry output
  .P(fullsum),                           // 48-bit output: Primary data output
  // Cascade: 30-bit (each) input: Cascade Ports
  .ACIN(30'b1),                     // 30-bit input: A cascade data input
  .BCIN(18'b1),                     // 18-bit input: B cascade input
  .CARRYCASCIN(1'b1),       // 1-bit input: Cascade carry input
  .MULTSIGNIN(1'b1),         // 1-bit input: Multiplier sign input
  .PCIN(48'b1),                     // 48-bit input: P cascade input
  // Control: 4-bit (each) input: Control Inputs/Status Bits
  .ALUMODE(4'b0000),               // 4-bit input: ALU control input
  .CARRYINSEL(3'b000),         // 3-bit input: Carry select input
  .CLK(clk),                       // 1-bit input: Clock input
  .INMODE(5'b00000),                 // 5-bit input: INMODE control input
  .OPMODE(7'b0010101),                 // 7-bit input: Operation mode input
  // Data: 30-bit (each) input: Data Ports
  .A({22'h000000, pixelvalues[24]}),                           // 30-bit input: A data input
  .B(coeff[24]),                           // 18-bit input: B data input
  .C(48'b1),                           // 48-bit input: C data input
  .CARRYIN(1'b0),               // 1-bit input: Carry input signal
  .D(25'h1),                           // 25-bit input: D data input
  // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  .CEA1(1'b0),                     // 1-bit input: Clock enable input for 1st stage AREG
  .CEA2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage AREG
  .CEAD(1'b0),                     // 1-bit input: Clock enable input for ADREG
  .CEALUMODE(1'b0),           // 1-bit input: Clock enable input for ALUMODE
  .CEB1(1'b0),                     // 1-bit input: Clock enable input for 1st stage BREG
  .CEB2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage BREG
  .CEC(1'b0),                       // 1-bit input: Clock enable input for CREG
  .CECARRYIN(1'b0),           // 1-bit input: Clock enable input for CARRYINREG
  .CECTRL(1'b1),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  .CED(1'b0),                       // 1-bit input: Clock enable input for DREG
  .CEINMODE(1'b1),             // 1-bit input: Clock enable input for INMODEREG
  .CEM(1'b1),                       // 1-bit input: Clock enable input for MREG
  .CEP(1'b1),                       // 1-bit input: Clock enable input for PREG
  .RSTA(rst),                     // 1-bit input: Reset input for AREG
  .RSTALLCARRYIN(1'b0),   // 1-bit input: Reset input for CARRYINREG
  .RSTALUMODE(1'b0),         // 1-bit input: Reset input for ALUMODEREG
  .RSTB(rst),                     // 1-bit input: Reset input for BREG
  .RSTC(1'b0),                     // 1-bit input: Reset input for CREG
  .RSTCTRL(1'b0),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  .RSTD(rst),                     // 1-bit input: Reset input for DREG and ADREG
  .RSTINMODE(1'b0),           // 1-bit input: Reset input for INMODEREG
  .RSTM(rst),                     // 1-bit input: Reset input for MREG
  .RSTP(rst)                      // 1-bit input: Reset input for PREG
);
// End of DSP48E1_inst instantiation

endmodule
