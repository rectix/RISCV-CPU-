`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2025 07:30:01 PM
// Design Name: 
// Module Name: register_file
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



module register_file(

    input logic clock_i,
    
    input logic du_stall_i,
    input logic du_r_enable_i,
    
    input logic [4:0] rs0_i,
    output logic [`XLEN-1 : 0]  rs0_rdata_o,
    
    input logic [4:0] rs1_i,
    output logic [`XLEN-1 : 0]  rs1_rdata_o,
    
    
    input logic wbu_w_enable_i,
    input logic [`ILEN-1 : 0] rdt_addr_i ,
    input logic [`XLEN-1 : 0]  wbu_wdata_i
    
    
    
    
    );
    
//===========================================================================
//   INTERNAL SIGNALS
//===========================================================================
logic  [`XLEN-1 : 0]  reg_file[32];
logic  [`XLEN-1 : 0]  rs0_data;
logic  [`XLEN-1 : 0]  rs1_data;


//===========================================================================
//   READ RS0  
//===========================================================================

always_ff @(posedge clock_i )
begin
 if( du_r_enable_i) begin
 if (~| rs0_data ) begin  rs0_data <= `XLEN'b000_000;; end 
 else begin rs0_data <= reg_file[rs0_i];  ;end 
 
 
 end 

 end //always 
 
 
 //===========================================================================
//   READ RS1  
//===========================================================================

 always_ff @(posedge clock_i )
begin
 if( du_r_enable_i) begin
 if (~| rs1_data ) begin  rs1_data <= `XLEN'b000_000;; end 
 else begin rs1_data <= reg_file[rs1_i];  ;end 
 
 
 end 

 end //always    
    

//===========================================================================
//   STALL
//===========================================================================
/*
always_ff @(posedge clock_i or negedge nreset_i)
begin

if(!du_stall_i) begin
        rs0_data <= `XLEN'b000_000;
        rs1_data <= `XLEN'b000_000;
end 


end //always    
*/

//===========================================================================
//  WRITE DATA
//===========================================================================  

always_ff @(posedge clock_i )
begin
 if( wbu_w_enable_i) begin
 if (~| rdt_addr_i) begin reg_file[rdt_addr_i] <=  `XLEN'b000_000; end 
 else begin reg_file[rdt_addr_i] = wbu_wdata_i   ;end 
 
 
 end 

 end //always  
    
 //===========================================================================
//  OUTPUT ASSIGNEMENT 
//===========================================================================     
    
 assign    rs1_rdata_o = rs1_data;
 assign    rs0_rdata_o = rs0_data;
  
    
    
    
    
endmodule
