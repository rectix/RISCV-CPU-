//===========================================================================
     import cpu_core_pkg :: *;
    `include "cpu_core_macros.svh"
//===========================================================================




module branch_unit #(
    parameter PC_INIT = `PC_INIT
)(
    // Clock and reset
    input  logic              clock_i,
    input  logic              nreset_i,
    
    // Program counter and instruction inputs
    input  logic [`XLEN-1:0]       pc_i,
    input  logic [6:0]        opcode_i,
    input  logic [2:0]        func3_i,
    
    // Register file inputs
    input  logic [`XLEN-1:0]       reg_file_rs0_i,
    input  logic [`XLEN-1:0]       reg_file_rs1_i,
    
    // Instruction type flags
    input  logic              is_B_type_i,
    input  logic              is_J_type_i,
    
    // Immediate values
    input  logic [11:0]       immI_i,
    input  logic [11:0]       immB_i,
    input  logic [19:0]       immJ_i,
    
    // Branch control signals
    output logic [`XLEN-1:0]       next_instruct_pc_o,
    output logic [`XLEN-1:0]       branch_pc_o,
    input  logic              branch_taken_i,
    output logic              branch_taken_o,
    output logic              flush_o,
    output logic              bubble_o,
    
    // Pipeline control
    


    input  logic              bubble_i,
    input  logic              stall_i
);



//===========================================================================
// SIGNALS 
//===========================================================================


logic [`XLEN-1:0] next_instruct_pc;
logic [`XLEN-1:0] next_instruct_pc_rg;


logic [`XLEN-1:0] branch_pc;
logic [`XLEN-1:0] branch_pc_rg;


logic branch_taken;
logic branch_taken_rg;

logic flush;
logic flush_rg;


logic bubble;
logic bubble_rg;


logic [`XLEN-1:0] immI, immB, immJ;
logic [`XLEN-1:0] pc_inc, pc_plus_immB, pc_plus_immJ;
logic [`XLEN-1:0] rs0_plus_immI;

logic             is_jal_type, is_jalr_type;


logic             is_rs0_eq_rs1, is_rs0_lt_rs1;
logic             is_signed_rs0_lt_rs1;

logic             is_branch_taken_diff;




//===========================================================================
// SYNCHRONOUS LOGIC
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i) begin
    if (!nreset_i) begin
        next_instruct_pc_rg <= PC_INIT;
        branch_pc_rg       <= PC_INIT;
        branch_taken_rg    <= 1'b0;
        flush_rg           <= 1'b0;
        bubble_rg          <= 1'b1;
    end else if (!stall_i) begin
            next_instruct_pc_rg <= next_instruct_pc;
            branch_pc_rg       <= branch_pc;
            branch_taken_rg    <= branch_taken;
            flush_rg           <= flush;
            bubble_rg          <= bubble;
        end
    end



//===========================================================================
// BRANCH PC CALCULATION
//===========================================================================

assign immB        = {20{immB_i[11]}, immB_i[10:0], 1'b0};
assign immI        = {20{immI_i[11]}, immI_i};
assign immJ        = {12{immJ_i[19]}, immJ_i[18:0], 1'b0};

assign pc_inc         = pc_i + `XLEN'(4);
assign pc_plus_immB  = pc_inc + immB;
assign pc_plus_immJ  = pc_inc + immJ;
assign rs0_plus_immI = reg_file_rs0_i + immI;

assign is_rs0_eq_rs1 = (reg_file_rs0_i == reg_file_rs1_i);
assign is_rs0_lt_rs1 = (reg_file_rs0_i < reg_file_rs1_i);
assign is_signed_rs0_lt_rs1 = (signed'(reg_file_rs0_i) < signed'(reg_file_rs1_i));
assign is_branch_taken_diff = branch_taken_i ^ branch_taken;


assign is_jal_type = (opcode_i == `OP_JALR);
assign bubble  = (is_jal_type || is_jalr_type) ? bubble_i : 1'b1;
 //JAL & JALR need to propagate and do a writeback

//===========================================================================
// BRANCH CONTROL LOGIC
//===========================================================================

always_comb begin
if(is_jalr_type && !bubble_i) begin 
    branch_taken = 1'b1;
    branch_pc = rs0_plus_immI & {`XLEN-1{1'b1}, 1'b0};
    flush = 1'b1;

end else if(is_J_type_i && !bubble_i) begin 
    branch_taken = 1'b1;
    branch_pc = pc_plus_immJ ;
    flush = 1'b0;

end else if(is_B_type_i && !bubble_i) begin
    case (func3_i)
        F3_BEQ: begin
            branch_taken = is_rs0_eq_rs1;
            branch_pc    = pc_plus_immB;
            flush        = is_branch_taken_diff
        end
        F3_BNE: begin
            branch_taken = ~is_rs0_eq_rs1;
            branch_pc    = pc_plus_immB;
            flush        = is_branch_taken_diff
        end
        F3_BLT: begin
            branch_taken = is_signed_rs0_lt_rs1;
            branch_pc    = pc_plus_immB;
            flush        = is_branch_taken_diff
        end
        F3_BGE: begin
            branch_taken = ~is_signed_rs0_lt_rs1;
            branch_pc    = pc_plus_immB;
            flush        = is_branch_taken_diff
        end
        F3_BLTU: begin
            branch_taken = is_rs0_lt_rs1;
            branch_pc    = pc_plus_immB;
            flush        = is_branch_taken_diff
        end
        F3_BGEU: begin
            branch_taken = ~is_rs0_lt_rs1;
            branch_pc    = pc_plus_immB;
            flush        = is_branch_taken_diff
        end
        default: begin
            branch_taken = 1'b0;
            branch_pc    = pc_inc;
            flush        = is_branch_taken_diff
        end
    endcase

end else begin
    bubble = 1'b0;
    branch_taken = 1'b0;
    branch_pc = pc_inc;
end 

end //always

//===========================================================================
// OUTPUTS      
//===========================================================================
assign next_instruct_pc_o = next_instruct_pc_rg;
assign branch_pc_o       = branch_pc_rg;
assign branch_taken_o    = branch_taken_rg;
assign flush_o           = flush_rg;
assign bubble_o          = bubble_rg;


endmodule