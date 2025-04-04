`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/02/2025 12:25:00 PM
// Design Name: 
// Module Name: cpu_core_pkg
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


//-------------------------------------------------------------------------------
`include "cpu_core_macros.svh"
//-------------------------------------------------------------------------------
package cpu_core_pkg;

localparam int RSIZE  = `XLEN ;  // Register size
localparam int ISIZE  = `ILEN ;  // Register size

//===================================================================================================================================================
// Opcodes - Localparams
//===================================================================================================================================================
localparam [6:0] OP_LUI     = 7'b011_0111 ;  // 0x37
localparam [6:0] OP_AUIPC   = 7'b001_0111 ;  // 0x17
localparam [6:0] OP_JAL     = 7'b110_1111 ;  // 0x6F
localparam [6:0] OP_JALR    = 7'b110_0111 ;  // 0x67
localparam [6:0] OP_BRANCH  = 7'b110_0011 ;  // 0x63
localparam [6:0] OP_LOAD    = 7'b000_0011 ;  // 0x03
localparam [6:0] OP_STORE   = 7'b010_0011 ;  // 0x23
localparam [6:0] OP_ALU     = 7'b011_0011 ;  // 0x33
localparam [6:0] OP_ALUI    = 7'b001_0011 ;  // 0x13

//===================================================================================================================================================
// funct3 - Localparams
//===================================================================================================================================================
localparam [2:0] F3_ADDX  = 3'b000 ;
localparam [2:0] F3_SUB   = 3'b000 ;
localparam [2:0] F3_SLTX  = 3'b010 ;
localparam [2:0] F3_SLTUX = 3'b011 ;
localparam [2:0] F3_XORX  = 3'b100 ;
localparam [2:0] F3_ORX   = 3'b110 ;
localparam [2:0] F3_ANDX  = 3'b111 ;
localparam [2:0] F3_SLLX  = 3'b001 ;
localparam [2:0] F3_SRXX  = 3'b101 ;

localparam [2:0] F3_JALR = 3'b000 ;
localparam [2:0] F3_BEQ  = 3'b000 ;
localparam [2:0] F3_BNE  = 3'b001 ;
localparam [2:0] F3_BLT  = 3'b100 ;
localparam [2:0] F3_BGE  = 3'b101 ;  
localparam [2:0] F3_BLTU = 3'b110 ;
localparam [2:0] F3_BGEU = 3'b111 ;

localparam [2:0] F3_LB   = 3'b000 ;
localparam [2:0] F3_LH   = 3'b001 ;
localparam [2:0] F3_LW   = 3'b010 ;
localparam [2:0] F3_LBU  = 3'b100 ;
localparam [2:0] F3_LHU  = 3'b101 ;
localparam [2:0] F3_SB   = 3'b000 ;
localparam [2:0] F3_SH   = 3'b001 ;
localparam [2:0] F3_SW   = 3'b010 ;

//===================================================================================================================================================
// ALU Opcodes - Localparams
//===================================================================================================================================================
localparam [3:0] ALU_ADD  = 4'b0000 ;
localparam [3:0] ALU_SUB  = 4'b0001 ;
localparam [3:0] ALU_SLT  = 4'b0100 ;
localparam [3:0] ALU_SLTU = 4'b0110 ;
localparam [3:0] ALU_XOR  = 4'b1000 ;
localparam [3:0] ALU_OR   = 4'b1100 ;
localparam [3:0] ALU_AND  = 4'b1110 ;
localparam [3:0] ALU_SLL  = 4'b0010 ;
localparam [3:0] ALU_SRL  = 4'b1010 ;
localparam [3:0] ALU_SRA  = 4'b1011 ;
localparam [3:0] ALU_ILLG = 4'b1111 ;  // Illegal opcode

endpackage
