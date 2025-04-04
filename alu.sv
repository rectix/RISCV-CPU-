`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/04/2025 12:02:28 PM
// Design Name: 
// Module Name: alu
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

//===========================================================================

 import cpu_core_pkg :: *;
`include "cpu_core_macros.svh"

//===========================================================================


module alu(
    input   logic [3:0]             alu_opcode_i,
    input   logic [`XLEN-1:0]       rs0_data_i,
    input   logic [`XLEN-1:0]       rs1_data_i,
    input   logic                   du_bubble_i,
    input   logic                   stall_i,
    output  logic [`XLEN-1:0]       alu_result_o,
    output  logic                   alu_bubble_o,
    input   logic                   clock_i,
    input   logic                   nreset_i
    );
    
    
//===========================================================================
//        logical signal 
//===========================================================================    
    
logic [`XLEN-1:0]       alu_result,      alu_result_reg;
logic                    alu_bubble,      alu_bubble_reg;



//===========================================================================
//       ALU OPS
//===========================================================================   

always_comb  begin

alu_bubble <=  du_bubble_i;
case (alu_opcode_i) 

ALU_ADD  : alu_result <=  rs0_data_i + rs1_data_i; 
ALU_SUB  : alu_result <=  rs0_data_i - rs1_data_i; 
ALU_SLT  : alu_result <=  {{`XLEN-1{1'b0}} ,(signed'(rs0_data_i) < signed'(rs1_data_i))} ;
ALU_SLTU : alu_result <=  {{`XLEN-1{1'b0}} ,(signed'(rs0_data_i) < signed'(rs1_data_i))} ;
ALU_XOR  : alu_result <=   rs0_data_i ^ rs1_data_i;
ALU_OR   : alu_result <=   rs0_data_i | rs1_data_i;
ALU_AND  : alu_result <=   rs0_data_i & rs1_data_i;
ALU_SLL  : alu_result <=   rs0_data_i << (rs1_data_i[4:0]);
ALU_SRL  : alu_result <=   rs0_data_i >> (rs1_data_i[4:0]);
ALU_SRA  : alu_result <=   signed'(rs0_data_i) >>> (rs1_data_i[4:0]);

default: begin alu_result <= `XLEN'h0; alu_bubble <= 1'b1;  end 

endcase
end //always 

    
//===========================================================================
//       RESULT SELECTION
//===========================================================================     
    
assign alu_result_o =  alu_result_reg; 
assign alu_bubble_o =  alu_bubble_reg;    
    
always_ff @(posedge clock_i or negedge nreset_i)  begin
if        (!nreset_i)  begin   alu_result_reg <= `XLEN'h0;      alu_bubble_reg <= 1'b1;          end
else if   (!stall_i)   begin   alu_result_reg <=   alu_result ;  alu_bubble_reg <= alu_bubble ;  end 



end //always
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
    
endmodule
