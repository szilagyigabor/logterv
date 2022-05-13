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

// a 25 mély tömb a 25 kaszkád DSP az aktuális színcsatornára
wire [3:0] carrycasc[24:0]; 
wire multsigncasc[24:0];
wire [47:0] pcasc[24:0];

reg [8:0] pbshr[4:0];
reg [8:0] pcshr[9:0];
reg [8:0] pdshr[14:0];
reg [8:0] peshr[19:0];

reg [8:0] pbshr;

always @(posedge clk) begin
    if (rst) begin
        pbshr <= 0;
        pbshr <= 0;
        pbshr <= 0;
        pbshr <= 0;
    end
    else begin
        pbshr <= {pb, pbshr[4:1]}; 
        pbshr <= {pc, pcshr[9:1]}; 
        pbshr <= {pd, pdshr[14:1]}; 
        pbshr <= {pe, peshr[19:1]}; 
    end
end

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
  .CARRYCASCOUT(carrycasc[0]),     // 1-bit output: Cascade carry output
  .MULTSIGNOUT(multsigncasc[0]),       // 1-bit output: Multiplier sign cascade output
  .PCOUT(pcasc[0]),                   // 48-bit output: Cascade output
  // Control: 1-bit (each) output: Control Inputs/Status Bits
  .OVERFLOW(),             // 1-bit output: Overflow in add/acc output
  .PATTERNBDETECT(), // 1-bit output: Pattern bar detect output
  .PATTERNDETECT(),   // 1-bit output: Pattern detect output
  .UNDERFLOW(),           // 1-bit output: Underflow in add/acc output
  // Data: 4-bit (each) output: Data Ports
  .CARRYOUT(#),             // 4-bit output: Carry output
  .P(),                           // 48-bit output: Primary data output
  // Cascade: 30-bit (each) input: Cascade Ports
  .ACIN(30'b0),                     // 30-bit input: A cascade data input
  .BCIN(18'b0),                     // 18-bit input: B cascade input
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
  .A({22'h000000, pa}),                           // 30-bit input: A data input
  .B(coeff[0]),                           // 18-bit input: B data input
  .C(48'b1),                           // 48-bit input: C data input
  .CARRYIN(1'b0),               // 1-bit input: Carry input signal
  .D(25'h1),                           // 25-bit input: D data input
  // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  .CEA1(1'b0),                     // 1-bit input: Clock enable input for 1st stage AREG
  .CEA2(1'b1),                     // 1-bit input: Clock enable input for 2nd stage AREG
  .CEAD(1'b0),                     // 1-bit input: Clock enable input for ADREG
  .CEALUMODE(),           // 1-bit input: Clock enable input for ALUMODE
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
  .RSTALLCARRYIN(#),   // 1-bit input: Reset input for CARRYINREG
  .RSTALUMODE(#),         // 1-bit input: Reset input for ALUMODEREG
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

// DSP48E1: 48-bit Multi-Functional Arithmetic Block
//          Kintex-7
// Xilinx HDL Language Template, version 2021.2

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
  .ACASCREG(1),                     // Number of pipeline stages between A/ACIN and ACOUT (0, 1 or 2)
  .ADREG(1),                        // Number of pipeline stages for pre-adder (0 or 1)
  .ALUMODEREG(1),                   // Number of pipeline stages for ALUMODE (0 or 1)
  .AREG(1),                         // Number of pipeline stages for A (0, 1 or 2)
  .BCASCREG(1),                     // Number of pipeline stages between B/BCIN and BCOUT (0, 1 or 2)
  .BREG(1),                         // Number of pipeline stages for B (0, 1 or 2)
  .CARRYINREG(1),                   // Number of pipeline stages for CARRYIN (0 or 1)
  .CARRYINSELREG(1),                // Number of pipeline stages for CARRYINSEL (0 or 1)
  .CREG(1),                         // Number of pipeline stages for C (0 or 1)
  .DREG(1),                         // Number of pipeline stages for D (0 or 1)
  .INMODEREG(1),                    // Number of pipeline stages for INMODE (0 or 1)
  .MREG(1),                         // Number of multiplier pipeline stages (0 or 1)
  .OPMODEREG(1),                    // Number of pipeline stages for OPMODE (0 or 1)
  .PREG(1)                          // Number of pipeline stages for P (0 or 1)
)
DSP48E1_inst (
  // Cascade: 30-bit (each) output: Cascade Ports
  .ACOUT(ACOUT),                   // 30-bit output: A port cascade output
  .BCOUT(BCOUT),                   // 18-bit output: B port cascade output
  .CARRYCASCOUT(CARRYCASCOUT),     // 1-bit output: Cascade carry output
  .MULTSIGNOUT(MULTSIGNOUT),       // 1-bit output: Multiplier sign cascade output
  .PCOUT(PCOUT),                   // 48-bit output: Cascade output
  // Control: 1-bit (each) output: Control Inputs/Status Bits
  .OVERFLOW(OVERFLOW),             // 1-bit output: Overflow in add/acc output
  .PATTERNBDETECT(PATTERNBDETECT), // 1-bit output: Pattern bar detect output
  .PATTERNDETECT(PATTERNDETECT),   // 1-bit output: Pattern detect output
  .UNDERFLOW(UNDERFLOW),           // 1-bit output: Underflow in add/acc output
  // Data: 4-bit (each) output: Data Ports
  .CARRYOUT(CARRYOUT),             // 4-bit output: Carry output
  .P(P),                           // 48-bit output: Primary data output
  // Cascade: 30-bit (each) input: Cascade Ports
  .ACIN(ACIN),                     // 30-bit input: A cascade data input
  .BCIN(BCIN),                     // 18-bit input: B cascade input
  .CARRYCASCIN(CARRYCASCIN),       // 1-bit input: Cascade carry input
  .MULTSIGNIN(MULTSIGNIN),         // 1-bit input: Multiplier sign input
  .PCIN(PCIN),                     // 48-bit input: P cascade input
  // Control: 4-bit (each) input: Control Inputs/Status Bits
  .ALUMODE(ALUMODE),               // 4-bit input: ALU control input
  .CARRYINSEL(CARRYINSEL),         // 3-bit input: Carry select input
  .CLK(CLK),                       // 1-bit input: Clock input
  .INMODE(INMODE),                 // 5-bit input: INMODE control input
  .OPMODE(OPMODE),                 // 7-bit input: Operation mode input
  // Data: 30-bit (each) input: Data Ports
  .A(A),                           // 30-bit input: A data input
  .B(B),                           // 18-bit input: B data input
  .C(C),                           // 48-bit input: C data input
  .CARRYIN(CARRYIN),               // 1-bit input: Carry input signal
  .D(D),                           // 25-bit input: D data input
  // Reset/Clock Enable: 1-bit (each) input: Reset/Clock Enable Inputs
  .CEA1(CEA1),                     // 1-bit input: Clock enable input for 1st stage AREG
  .CEA2(CEA2),                     // 1-bit input: Clock enable input for 2nd stage AREG
  .CEAD(CEAD),                     // 1-bit input: Clock enable input for ADREG
  .CEALUMODE(CEALUMODE),           // 1-bit input: Clock enable input for ALUMODE
  .CEB1(CEB1),                     // 1-bit input: Clock enable input for 1st stage BREG
  .CEB2(CEB2),                     // 1-bit input: Clock enable input for 2nd stage BREG
  .CEC(CEC),                       // 1-bit input: Clock enable input for CREG
  .CECARRYIN(CECARRYIN),           // 1-bit input: Clock enable input for CARRYINREG
  .CECTRL(CECTRL),                 // 1-bit input: Clock enable input for OPMODEREG and CARRYINSELREG
  .CED(CED),                       // 1-bit input: Clock enable input for DREG
  .CEINMODE(CEINMODE),             // 1-bit input: Clock enable input for INMODEREG
  .CEM(CEM),                       // 1-bit input: Clock enable input for MREG
  .CEP(CEP),                       // 1-bit input: Clock enable input for PREG
  .RSTA(RSTA),                     // 1-bit input: Reset input for AREG
  .RSTALLCARRYIN(RSTALLCARRYIN),   // 1-bit input: Reset input for CARRYINREG
  .RSTALUMODE(RSTALUMODE),         // 1-bit input: Reset input for ALUMODEREG
  .RSTB(RSTB),                     // 1-bit input: Reset input for BREG
  .RSTC(RSTC),                     // 1-bit input: Reset input for CREG
  .RSTCTRL(RSTCTRL),               // 1-bit input: Reset input for OPMODEREG and CARRYINSELREG
  .RSTD(RSTD),                     // 1-bit input: Reset input for DREG and ADREG
  .RSTINMODE(RSTINMODE),           // 1-bit input: Reset input for INMODEREG
  .RSTM(RSTM),                     // 1-bit input: Reset input for MREG
  .RSTP(RSTP)                      // 1-bit input: Reset input for PREG
);

			
// End of DSP48E1_inst instantiation
				
