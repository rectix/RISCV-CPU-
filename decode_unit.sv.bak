`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/03/2025 09:29:25 AM
// Design Name: 
// Module Name: decode_unit
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


module decode_unit #(parameter  PC_INIT = `PC_INIT )(
    input logic               clock_i,
    input logic               nreset_i,

    // FETCH UNIT
    input  logic [`ILEN:0]    fu_instruct_i,
    input  logic [`XLEN:0]    fu_pc_i,
    output logic              fu_stall_o,
    input  logic              fu_branch_taken_i,
    input  logic              fu_bubble_i,

    // EXECUTION UNIT
    input  logic              xu_stall_i,
    output logic              xu_bubble_o,
    input  logic              xu_branch_flush_i,
    input  logic [`XLEN:0]    xu_branch_pc_i,
    input  logic              xu_branch_taken_o,

    output logic [`XLEN:0]    xu_instruct_o,
    output logic [`XLEN:0]    xu_pc_o,

    output logic [4:0]        xu_rs0_o,
    output logic [4:0]        xu_rs1_o,
    output logic [4:0]        xu_rdt_o,
    output logic [6:0]        xu_opcode_o,
    output logic [3:0]        xu_alu_opcode_o,
    output logic [6:0]        xu_func7_o,
    output logic [2:0]        xu_func3_o,

    output logic              xu_is_R_type_o,
    output logic              xu_is_I_type_o,
    output logic              xu_is_S_type_o,
    output logic              xu_is_B_type_o,
    output logic              xu_is_U_type_o,
    output logic              xu_is_J_type_o,

    output logic [11:0]       xu_immI_o,
    output logic [11:0]       xu_immB_o,
    output logic [11:0]       xu_immS_o,
    output logic [19:0]       xu_immU_o,
    output logic [19:0]       xu_immJ_o,

    // REGISTER FILE
    output logic [4:0]        rf_rs0_o,
    output logic [4:0]        rf_rs1_o,
    output logic              rf_read_en_o
);

//===========================================================================
//        logical signal 
//===========================================================================      
  
  logic   [6:0]      du_opcode ;
  logic   [3:0]      alu_opcode ;
  
  
  logic              is_alui_op ;
  logic              is_slli_srli_srai_op;
  
  logic  [`XLEN:0]   du_instruct;
  logic  [`XLEN:0]   du_pc;
  logic              du_branch_taken;
  logic              du_stall;
  logic              du_bubble;

  
  
  logic   [4:0]      rd , rs0, rs1;
  logic [2:0]       func3 ;  
  logic [6:0]       func7 ; 
  
  logic [6:0]       fu_opcode; 
  logic [5:0]       instruct_type;  //{R, I, S, B, U, J}  one-hot
  logic [4:0]       rf_rs0;
  logic [4:0]       rf_rs1;
  
  logic             is_r_type;
  logic             is_i_type;
  logic             is_s_type;
  logic             is_b_type;
  logic             is_u_type;
  logic             is_j_type;
  
  
    
//===========================================================================
//        INTRUCTION DECCODE
//===========================================================================      
  always_ff @(posedge clock_i or negedge nreset_i  )
  begin
  
  if(!nreset_i) begin
  instruct_type  <= 6'b000000;
  end else begin
  if(!stall)  begin
  case(fu_opcode) 
  OP_ALU    : instruct_type <= 6'b100000; 
  
  OP_LOAD,
  OP_JALR, 
  OP_ALUI   : instruct_type <= 6'b010000;
  
  OP_STORE  : instruct_type <= 6'b001000;
  
  OP_BRANCH : instruct_type <= 6'b000100;
  
  OP_LUI,
  OP_AUIPC: instruct_type   <= 6'b000010;
  
  OP_JAL: instruct_type      <= 6'b000001;
  
  default : instruct_type    <= 6'b000000;

  
  endcase
  
  end
  end //else nreset

  end ///always 

//===========================================================================
//        DECODE UNIT PC 
//===========================================================================  
  always_ff @(posedge clock_i or negedge nreset_i  )
  begin
  
  if        (!nreset_i)              begin   du_pc  <= `PC_INIT;      end 
  else if   (xu_branch_flush_i)      begin   du_pc <= xu_branch_pc_i; end
  else if   (!du_stall)              begin   du_pc <= fu_pc_i;        end

end ///always     
    

//===========================================================================
//        DECODE UNIT INSTRUCTION 
//===========================================================================     

always_ff @(posedge clock_i or negedge nreset_i  )
  begin
  
  if        (!nreset_i)         begin   du_instruct  <= `NOP_INSTRUCT;   end 
  else if   (xu_branch_flush_i) begin   du_instruct  <= `NOP_INSTRUCT;   end
  else if   (!du_stall)         begin   du_instruct  <=  fu_instruct_i;  end

end ///always  


//===========================================================================
//        BUBBLE INSERTION
//===========================================================================     

always_ff @(posedge clock_i or negedge nreset_i  )
  begin
  
  if       (!nreset_i)         begin   du_bubble  <= 1'b1; end
  else if  (xu_branch_flush_i) begin   du_bubble  <= 1'b1;   end
  else if  (!du_stall)         begin   du_bubble <=  fu_bubble_i;  end
            

end ///always  

//===========================================================================
//        BUBBLE INSERTION
//===========================================================================     

always_ff @(posedge clock_i or negedge nreset_i  )
  begin
  
  if       (!nreset_i)         begin   du_branch_taken  <= 1'b0; end
  else if  (fu_branch_taken_i) begin   du_branch_taken  <= 1'b1;   end

            

  end ///always       
        
//===========================================================================
//       ALU INSTRUCTION DECODE 
//===========================================================================  


always_comb
begin
if(is_r_type)        begin  alu_opcode <= {func3 , func7[5]}  ;                                      end 
else if (is_alui_op) begin  alu_opcode <= is_slli_srli_srai_op ? {func3 , func7[5]}:{func3 , 1'b0} ; end 
if(is_u_type)        begin  alu_opcode <= ALU_ADD  ;                                                 end 
else                 begin  alu_opcode <= ALU_ILLG;                                                  end 
    
 
    
end  //always   
    
    
  
    
//===========================================================================
//        IMMEDIATE GEN 
//===========================================================================  
    
assign xu_immI_o = {du_instruct[31:20]};
assign xu_immS_o = {du_instruct[31:25], du_instruct[11:7]};
assign xu_immB_o = {du_instruct[31],du_instruct[7], du_instruct[30:25], du_instruct[11:8]};
//assign xu_immU_o = {du_instruct[31],du_instruct[7], du_instruct[31:25], du_instruct[11:8], 1'b0};
assign xu_immU_o = {du_instruct[31:12]};
assign xu_immJ_o = {du_instruct[31], du_instruct[19:12], du_instruct[20], du_instruct[30:21]};

//assign xu_immJ_o = {{{du_instruct[31]}},du_instruct[19:12],du_instruct[20], du_instruct[31:25], du_instruct[24:21], 1'b0};
    

    
//===========================================================================
//       DECODE STALL
//=========================================================================== 

assign stall = xu_stall_i;
assign du_stall = stall & ~fu_bubble_i;
assign fu_stall_o  = du_stall;

     
    
//===========================================================================
//        SIGNALS VALUES 
//===========================================================================   

 assign fu_opcode   = fu_instruct_i[6:0];
 assign du_opcode   = du_instruct[6:0]   ; 
 
 assign func3       = du_instruct[14:12]   ;
 assign func7       = du_instruct[31:25]   ;
 
 assign rs1         = du_instruct[24:20]; 
 assign rs0         = du_instruct[19:15]; 
 assign rd          = du_instruct[11:7]; 
 
 
 assign is_r_type  = instruct_type[5];
 assign is_i_type  = instruct_type[4];
 assign is_s_type  = instruct_type[3];
 assign is_b_type  = instruct_type[2];
 assign is_u_type  = instruct_type[1];
 assign is_j_type  = instruct_type[0];
 
 
 assign  is_alui_op = (du_opcode ==OP_ALUI);
 assign  is_slli_srli_srai_op   = (func3 == F3_SLLX || func3 == F3_SRXX);
 
 
//===========================================================================
//       output assignement 
//===========================================================================   
 assign    xu_instruct_o=   du_instruct      ;
 assign     xu_pc_o=        du_pc      ;
    
assign    xu_rs0_o=         rs0      ;
assign    xu_rs1_o=         rs1     ;
assign    xu_rdt_o=         rd     ;
assign    xu_opcode_o=      du_opcode  ;
assign    xu_alu_opcode_o=  alu_opcode ;
assign    xu_func7_o=       func7    ;
assign    xu_func3_o=       func3    ;
    
assign    xu_is_R_type_o=   is_r_type     ;
assign    xu_is_I_type_o=   is_i_type     ;
assign    xu_is_S_type_o=   is_s_type     ;
assign    xu_is_B_type_o=   is_b_type     ;
assign    xu_is_U_type_o=   is_u_type     ;
assign    xu_is_J_type_o=   is_u_type     ; 
    
assign    xu_branch_taken_o = du_branch_taken;    
    
    
endmodule













