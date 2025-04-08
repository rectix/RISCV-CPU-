`timescale 1ns / 1ps

//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 04/01/2025 03:16:15 PM
// Design Name: cpu 
// Module Name: fetch
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

module fetch #(
    parameter PC_INIT = `PC_INIT
    )
    (
                
    input  logic              clock_i,
    input  logic              nreset_i,
    
    // Request interface  
    output logic [`XLEN-1:0]  fu_pc_o,
    output logic              fu_pc_valid_o,
    input  logic              mem_cpu_stall_i,
    
    // Response interface  
    output logic              mem_stall_o, 
    output logic              mem_flush_o,
    output logic              cpu_stall_i,
    input  logic              mem_pck_valid_i,
    input  logic [`ILEN:0]    mem_pck_i,         // packet = instruction + pc
    input  logic [`XLEN:0]    mem_pck_pc_i,  
    
    // Decode interface  
    input  logic              du_stall_i,  // inverse of ready 
    input  logic              du_flush_i,  // inverse of ready 
    output logic              fu_branch_taken_o,
    
    output logic [`ILEN -1:0] du_instruct_o,
    output logic              du_bubble_o,  // inverse of valid
    output logic              du_pc_o,     
    
    //exec unit signals 
    input  logic              xu_branch_flush_i,
    input  logic [`XLEN-1:0]  xu_branch_pc_i  
);


//===========================================================================

logic   [`ILEN-1 : 0] instruct_buff[2];
logic   [`XLEN-1 : 0] instruct_pc[2];
logic                 instruct_valid[2];

//===========================================================================
logic                  pc_valid;
logic                  pc_out_reset;
logic   [`XLEN-1 : 0]  pc_to_mem_next;
logic   [`XLEN-1 : 0]  pc_to_mem;
logic   [`XLEN-1 : 0]  pc_inc;
//===========================================================================
logic                  branch_taken;
logic                  last_branch_taken;
logic   [`XLEN-1 : 0]  branch_pc;


logic   [`ILEN-1 : 0] BF1_instruct; 
logic   [`XLEN-1 : 0] BF1_instruct_pc;        
logic                 BF1_instruct_valid;
logic   [6:0]       opcode; 


logic   [`XLEN-1 : 0] immB, immJ; 
logic                 is_op_jal;
logic                 is_op_branch;


//===========================================================================
logic                 flush;
logic                 fu_flush;
logic                 fu_stall;
logic                 stall;
//===========================================================================
//         PC LOGIC <==> RESET 
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i) begin
if(!nreset_i) begin
pc_out_reset <= 1'b1;
pc_valid     <= 1'b0;
pc_to_mem    <= 32'b0000_0000;

end else begin
 //PC
 if(xu_branch_flush_i)      begin pc_to_mem <= xu_branch_pc_i;  end 
  else if(branch_taken)     begin pc_to_mem <= branch_pc ;      end 
   else if(!cpu_stall_i)    begin pc_to_mem <= pc_to_mem_next;  end 
 
 
 //PC VALID
 
  if(xu_branch_flush_i)      begin pc_valid <= 1'b1;  end 
   else if(branch_taken)     begin pc_valid <= 1'b1;  end 
    else if(!cpu_stall_i)    begin pc_valid <= 1'b1;  end 
 
 //PC OUT REESET
 
  if(!cpu_stall_i)           begin pc_out_reset <= 1'b0 ;end 


end //else reset 

end //always

assign pc_inc = pc_to_mem + `XLEN'(4);
assign pc_to_mem_next = cpu_stall_i ? `PC_INIT : pc_inc;



//===========================================================================
//        BUFFER 1    
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i) begin

if(!nreset_i) begin
instruct_buff  [0]   <= `NOP_INSTRUCT;
instruct_pc    [0]   <= `PC_INIT;
instruct_valid [0]   <=  1'b0;

end else begin

//instruction buffer 1

if(xu_branch_flush_i)           begin instruct_buff[0] <= `NOP_INSTRUCT ; end
else if(branch_taken & !stall)  begin instruct_buff[0] <= `NOP_INSTRUCT ; end
else if(!stall)                 begin instruct_buff[0] <= mem_pck_valid_i ? mem_pck_i : `NOP_INSTRUCT ;end 

// buffer 1 instruct valid 

if(xu_branch_flush_i)           begin instruct_valid[0] <= 1'b0 ; end
else if(branch_taken & !stall)  begin instruct_valid[0] <= 1'b0  ; end
else if(!stall)                 begin instruct_valid[0] <=  mem_pck_valid_i ;end 



// PC buffer 1

if(xu_branch_flush_i)           begin instruct_pc[0] <= xu_branch_pc_i ; end
else if(branch_taken & !stall)  begin instruct_pc[0] <= branch_pc  ; end
else if(!stall)                 begin instruct_pc[0] <= mem_pck_valid_i ?  mem_pck_pc_i : instruct_pc[0] ;end 



end //else reset 
end  //always




//===========================================================================
//        BUFFER 2    
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i) begin

if(!nreset_i) begin
instruct_buff  [1]   <= `NOP_INSTRUCT;
instruct_pc    [1]   <= `PC_INIT;
instruct_valid [1]   <=  1'b0;

end else begin
//instruction buffer 2
if(flush)                  begin instruct_buff[1] <= `NOP_INSTRUCT ;      end
else if(!stall)            begin instruct_buff[1] <=  instruct_buff[0] ;  end 

// PC buffer 2

if(xu_branch_flush_i)      begin instruct_pc[1] <=  xu_branch_pc_i;      end
else if(!stall)            begin instruct_pc[1] <=  instruct_pc[0] ;     end 

// buffer 2 instruct valid 

if(flush)                  begin instruct_valid[1] <= 1'b0;              end
else if(!stall)            begin instruct_valid[1] <= 1'b1 ;             end 

end //else reset 
end  //always

//===========================================================================
//        BRANCH PREDICTION LOGIC    
//===========================================================================

always_comb  begin

if(is_op_jal)          begin  branch_pc <= BF1_instruct_pc  +  immJ;      end  
else if (is_op_branch) begin  branch_pc <= BF1_instruct_pc  +  immB;      end 
else                   begin  branch_pc <= BF1_instruct_pc  + `XLEN'(4);  end 


end //always


assign BF1_instruct  = instruct_buff[0];
assign BF1_instruct_pc  = instruct_pc[0];
assign BF1_instruct_valid  = instruct_valid[0];

assign opcode = BF1_instruct[6:0];

assign immJ   = {{(`XLEN-20){BF1_instruct[31]}}, BF1_instruct[19:12], BF1_instruct[20]    , BF1_instruct[30:21] , 1'b0} ;
assign immB   = {{(`XLEN-12){BF1_instruct[31]}}, BF1_instruct[7],     BF1_instruct[30:25] , BF1_instruct[11:8]  , 1'b0} ;


assign is_op_jal    = BF1_instruct_valid & (opcode == immJ );
assign is_op_branch = BF1_instruct_valid & (opcode == immB );

assign branch_taken = is_op_jal ||  (is_op_branch  &&  immB[31]);

// LAST BRANCH PREDICT

 
always_ff @(posedge clock_i or negedge nreset_i) begin
if(!nreset_i) begin

        last_branch_taken <= 1'b0;
end else begin
        last_branch_taken <= branch_taken;
end //else


end //always 

assign fu_branch_taken_o = last_branch_taken;


//===========================================================================
//        STALL LOGIC     
//===========================================================================
assign stall = du_stall_i; 
assign fu_stall = stall & mem_pck_valid_i; //valid packet needed first 
assign mem_stall_o = fu_stall;
   


//===========================================================================
//        FLUSH LOGIC     
//===========================================================================


assign flush = du_flush_i;
assign fu_flush = flush | branch_taken;
assign mem_flush_o = fu_flush;
    

//===========================================================================
//        INTERFACE ASSIGNEMENT     
//===========================================================================
//memory interface 
assign fu_pc_o = pc_to_mem; 
assign fu_pc_valid_o  = pc_valid;

//DECODE INTERFACE 

assign du_pc_o        = instruct_pc[1];
assign du_bubble_o    = ~instruct_valid[1];
assign du_instruct_o  = instruct_buff[1];



endmodule
