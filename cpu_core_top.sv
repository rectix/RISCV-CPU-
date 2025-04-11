`include "cpu_core_macros.svh"
import cpu_core_pkg::*;





module cpu_core_top #(
    parameter PC_INIT = `PC_INIT
) (


    input  logic               clock_i,
    input  logic               nreset_i,
    input logic               ext_stall_i,

    output logic               mem_stall_o,
    output logic               mem_flush_o,
    input  logic               mem_cpu_stall_i,

    input  logic               mem_pck_valid_i,
    input  logic [`ILEN-1:0]   mem_pck_i,
    input  logic [`XLEN-1:0]   mem_pck_pc_i,

    output logic [`XLEN-1:0]   mem_pc_o,
    output logic               mem_pc_valid_o,

    output logic [`XLEN-1:0]   dmem_addr_o,
    output logic [`XLEN-1:0]   dmem_wdata_o,
    output logic [1:0]         dmem_size_o,
    output logic               dmem_req_o,
    output logic               dmem_wen_o,
    output logic               dmem_flush_o,
    input logic               dmem_stall_i ,

    input  logic [`XLEN-1:0]   dmem_rdata_i,
    input  logic               dmem_ACK_i,
    output logic               dmem_stall_o // from write-back unit
);

//===========================================================================
//                        INTERNAL LOGIC
//===========================================================================

//-------------------------- Fetch Unit --------------------------
logic               fu_du_branch_taken;
logic [`XLEN-1:0]   fu_pc;
logic               fu_to_mem_pc_valid;
logic               fu_to_mem_stall;
logic               fu_to_mem_flush;
logic               fu_to_du_bubble;
logic [`XLEN-1:0]   fu_to_du_pc;
logic [`ILEN-1:0]   fu_to_du_instruct;

//-------------------------- Decode Unit --------------------------
logic               du_to_fu_stall;
logic               du_to_xu_bubble;
logic               xu_branch_taken;
logic [`ILEN-1:0]   du_to_xu_instruct;
logic [`XLEN-1:0]   du_to_xu_pc;

logic [4:0]         du_to_xu_rs0;
logic [4:0]         du_to_xu_rs1;
logic [4:0]         du_to_xu_rdt;
logic [6:0]         du_to_xu_opcode;
logic [3:0]         du_to_xu_alu_opcode;
logic [6:0]         du_to_xu_func7;
logic [2:0]         du_to_xu_func3;

logic               du_to_xu_is_R_type;
logic               du_to_xu_is_I_type;
logic               du_to_xu_is_S_type;
logic               du_to_xu_is_B_type;
logic               du_to_xu_is_U_type;
logic               du_to_xu_is_J_type;

logic [11:0]        du_to_xu_immI;
logic [11:0]        du_to_xu_immB;
logic [11:0]        du_to_xu_immS;
logic [19:0]        du_to_xu_immU;
logic [19:0]        du_to_xu_immJ;

logic [4:0]         du_to_rf_rs0;
logic [4:0]         du_to_rf_rs1;
logic               du_to_rf_ren;

//-------------------------- Execute Unit --------------------------
logic               xu_to_du_stall;
logic               xu_branch_flush;
logic [`XLEN-1:0]   xu_branch_pc;

logic               xu_to_mem_bubble;
logic               xu_to_mem_is_mem_op;
logic [5:0]         xu_to_mem_instruct_type;
logic [`ILEN-1:0]   xu_to_mem_instruct;
logic [`XLEN-1:0]   xu_to_mem_pc;

logic [4:0]         xu_to_mem_rdt_addr;
logic [`XLEN-1:0]   xu_to_mem_rdt_data;
logic [`XLEN-1:0]   xu_to_mem_addr;
logic               xu_to_mem_cmd;
logic [`XLEN-1:0]   xu_to_mem_data;
logic [1:0]         xu_to_mem_size;

//---------------------- Memory Access Unit ----------------------
logic               macc_to_xu_stall;

logic               macc_to_dmem_wen;
logic               macc_to_dmem_req;
logic               macc_to_dmem_flush;
logic [`XLEN-1:0]   macc_to_dmem_addr;
logic [`XLEN-1:0]   macc_to_dmem_wdata;
logic [1:0]         macc_to_dmem_size;

logic [5:0]         macc_to_wb_instruct_type;
logic [`XLEN-1:0]   macc_to_wb_instruct;
logic [`XLEN-1:0]   macc_to_wb_pc;
logic [`XLEN-1:0]   macc_to_wb_mem_addr;

logic [4:0]         macc_to_wb_rdt_addr;
logic [`XLEN-1:0]   macc_to_wb_rdt_data;

logic               macc_to_wb_bubble;
logic               macc_to_wb_is_mem_op;
logic               macc_to_wb_mem_op_type;

logic [`XLEN-1:0]   mem_result;

//---------------------- Operand forward Unit ----------------------

logic               fwd_rs0;
logic               fwd_rs1;
//--------------------------- Writeback ---------------------------
logic               wbu_to_macc_stall;
logic               wbu_to_rf_wen;
logic [`XLEN-1:0]   wbu_to_rf_wdata;
logic [4:0]         wbu_to_rf_waddr;

logic [4:0]         wbu_rdt_addr;
logic [`XLEN-1:0]   wbu_rdt_data;
logic [4:0]         wbu_load_data;

logic [`XLEN-1:0]   wbu_pc_rg;
logic [`ILEN-1:0]   wbu_instruct_rg;
logic [5:0]         wbu_instruct_type_rg;
logic               wbu_bubble;

//-------------------------- Register File --------------------------
logic [`XLEN-1:0]   rs0_data;
logic [`XLEN-1:0]   rs1_data;



//===========================================================================
// FETCH UNIT INSTANTIATION
//===========================================================================
fetch #(
    .PC_INIT(PC_INIT)
) fetch_inst (
 
    .clock_i(clock_i),
    .nreset_i(nreset_i),

    .fu_pc_o(mem_pc_o),
    .fu_pc_valid_o(mem_pc_valid_o),
    .mem_stall_o(mem_stall_o),
    .mem_flush_o(mem_flush_o),


    .mem_cpu_stall_i(mem_cpu_stall_i),
    .mem_pck_valid_i(mem_pck_valid_i),
    .mem_pck_i(mem_pck_i),
    .mem_pck_pc_i(mem_pck_pc_i),


    .du_stall_i(du_to_fu_stall),
    .du_flush_i(xu_branch_taken),


    .fu_branch_taken_o(fu_du_branch_taken),
    .du_instruct_o(fu_to_du_instruct),
    .du_bubble_o(fu_to_du_bubble),
    .du_pc_o(fu_to_du_pc),

    .xu_branch_flush_i(xu_branch_flush),
    .xu_branch_pc_i(xu_branch_pc)
);


//===========================================================================
// DECODE UNIT INSTANTIATION
//===========================================================================

decode_unit #(
    .PC_INIT(PC_INIT)
) decode_inst (
    .clock_i(clock_i),
    .nreset_i(nreset_i),

    .fu_instruct_i(fu_to_du_instruct),
    .fu_pc_i(fu_to_du_pc),
    .fu_stall_o(du_to_fu_stall),
    .fu_branch_taken_i(fu_du_branch_taken),
    .fu_bubble_i(fu_to_du_bubble),

    .xu_stall_i(xu_to_du_stall),
    .xu_bubble_o(du_to_xu_bubble),
    .xu_branch_flush_i(xu_branch_flush),
    .xu_branch_pc_i(xu_branch_pc),
    .xu_branch_taken_o(xu_branch_taken),

    .xu_instruct_o(du_to_xu_instruct),
    .xu_pc_o(du_to_xu_pc),

    .xu_rs0_o(du_to_xu_rs0),
    .xu_rs1_o(du_to_xu_rs1),
    .xu_rdt_o(du_to_xu_rdt),
    .xu_opcode_o(du_to_xu_opcode),
    .xu_alu_opcode_o(du_to_xu_alu_opcode),
    .xu_func7_o(du_to_xu_func7),
    .xu_func3_o(du_to_xu_func3),

    .xu_is_R_type_o(du_to_xu_is_R_type),
    .xu_is_I_type_o(du_to_xu_is_I_type),
    .xu_is_S_type_o(du_to_xu_is_S_type),
    .xu_is_B_type_o(du_to_xu_is_B_type),
    .xu_is_U_type_o(du_to_xu_is_U_type),
    .xu_is_J_type_o(du_to_xu_is_J_type),

    .xu_immI_o(du_to_xu_immI),
    .xu_immB_o(du_to_xu_immB),
    .xu_immS_o(du_to_xu_immS),
    .xu_immU_o(du_to_xu_immU),
    .xu_immJ_o(du_to_xu_immJ),

    .rf_rs0_o(du_to_rf_rs0),
    .rf_rs1_o(du_to_rf_rs1),
    .rf_read_en_o(du_to_rf_ren)
);

//===========================================================================
// REGISTER FILE INSTANTIATION
//===========================================================================


register_file register_file_inst (
    .clock_i(clock_i),

    
    .du_stall_i(du_to_rf_stall),
    .du_r_enable_i(du_to_rf_ren),

    .rs0_i(du_to_rf_rs0),
    .rs0_rdata_o(rs0_data),
    .rs1_i(du_to_rf_rs1),
    .rs1_rdata_o(rs1_data),

    .wbu_w_enable_i(wbu_to_rf_wen),
    .rdt_addr_i(wbu_rdt_addr),
    .wbu_wdata_i(wbu_rdt_data)
);


//===========================================================================
// EXECUTE UNIT INSTANTIATION
//===========================================================================

exec_unit #(
    .PC_INIT(PC_INIT)
) exec_inst (
    .clock_i(clock_i),
    .nreset_i(nreset_i),

    .reg_file_rs0_i(rs0_data),
    .reg_file_rs1_i(rs1_data),

    .du_branch_flush_o(xu_branch_flush),
    .du_branch_pc_o(xu_branch_pc),
    .du_branch_taken_i(xu_branch_taken),
    .du_stall_o(xu_to_du_stall),
    .du_bubble_i(du_to_xu_bubble),



    .du_instruct_i(du_to_xu_instruct),
    .du_pc_i(du_to_xu_pc),

    .du_rs0_i(du_to_xu_rs0),
    .du_rs1_i(du_to_xu_rs1),
    .du_rdt_i(du_to_xu_rdt),

    .du_opcode_i(du_to_xu_opcode),
    .du_alu_opcode_i(du_to_xu_alu_opcode),

    .du_func7_i(du_to_xu_func7),
    .du_func3_i(du_to_xu_func3),

    .du_is_R_type_i(du_to_xu_is_R_type),
    .du_is_I_type_i(du_to_xu_is_I_type),
    .du_is_S_type_i(du_to_xu_is_S_type),
    .du_is_B_type_i(du_to_xu_is_B_type),
    .du_is_U_type_i(du_to_xu_is_U_type),
    .du_is_J_type_i(du_to_xu_is_J_type),

    .du_immI_i(du_to_xu_immI),
    .du_immB_i(du_to_xu_immB),
    .du_immS_i(du_to_xu_immS),
    .du_immU_i(du_to_xu_immU),
    .du_immJ_i(du_to_xu_immJ),


    .mem_stall_i(macc_to_xu_stall),
    .mem_bubble_o(xu_to_mem_bubble),
    .is_mem_op_o(xu_to_mem_is_mem_op),
    .mem_instruct_type_o(xu_to_mem_instruct_type),
    .mem_instruct_o(xu_to_mem_instruct),
    .mem_pc_o(xu_to_mem_pc),

    .rdt_addr_o(xu_to_mem_rdt_addr),
    .rdt_data_o(xu_to_mem_rdt_data),


    .mem_addr_o(xu_to_mem_addr),
    .mem_cmd_o(xu_to_mem_cmd),
    .mem_data_o(xu_to_mem_data),
    .mem_size_o(xu_to_mem_size)
);


//===========================================================================
// MEM ACCESS UNIT INSTANTIATION
//===========================================================================



mem_acces_unit #(
    .PC_INIT(PC_INIT)
) mem_access_inst (
    .clock_i(clock_i),
    .nreset_i(nreset_i),

    .xu_stall_o(macc_to_xu_stall),
    .xu_bubble_i(xu_to_mem_bubble),
    .xu_pc_i(xu_to_mem_pc),
    .xu_instruct_type_i(xu_to_mem_instruct_type),
    .xu_instruct_i(xu_to_mem_instruct),
    .xu_mem_addr_i(xu_to_mem_addr),
    .xu_mem_cmd_i(xu_to_mem_cmd),
    .xu_mem_data_i(xu_to_mem_data),
    .xu_mem_size_i(xu_to_mem_size),
    .xu_is_mem_op_i(xu_to_mem_is_mem_op),
    .xu_rdt_addr_i(xu_to_mem_rdt_addr),
    .xu_rdt_data_i(xu_to_mem_rdt_data),


    .dmem_addr_o(dmem_addr_o),
    .dmem_wdata_o(dmem_wdata_o),
    .dmem_size_o(dmem_size_o),
    .dmem_req_o(dmem_req_o),
    .dmem_wen_o(dmem_wen_o),
    .dmem_flush_o(dmem_flush_o),
    .dmem_stall_i(dmem_stall_i),



    .wb_instruct_type_o(macc_to_wb_instruct_type),
    .wb_instruct_o(macc_to_wb_instruct),
    .wb_pc_o(macc_to_wb_pc),
    .wb_mem_addr_o(macc_to_wb_mem_addr),
    .wb_rdt_addr_o(macc_to_wb_rdt_addr),
    .wb_rdt_wdata_o(macc_to_wb_rdt_data),
    .wb_stall_i(wbu_to_macc_stall),
    .wb_bubble_o(macc_to_wb_bubble),
    .wb_is_mem_op_o(macc_to_wb_is_mem_op),
    .wb_mem_op_type_o(macc_to_wb_mem_op_type)
);
//=========================================================================
//                       OPERAND FORWARD INSTANTIATION
//=========================================================================

op_forward #(
    .PC_INIT(PC_INIT)
) op_forward_inst (

    .rf_rs0_i(rf_to_du_rs0_data),
    .rf_rs1_i(rf_to_du_rs1_data),

    .du_rs0_i(du_to_rf_rs0),
    .du_rs1_i(du_to_rf_rs1),

    .du_instruct_type_i(du_to_xu_instruct_type),
    .du_instruct_valid_i(~du_to_xu_bubble),

    .xu_instruct_type_i(xu_to_mem_instruct_type),
    .xu_instruct_valid_i(xu_to_mem_instruct_valid),
    .xu_rdt_i(xu_to_mem_rdt_addr),
    .xu_result_i(xu_to_mem_rdt_data),


    .mem_instruct_type_i(mem_to_wb_instruct_type),
    .mem_instruct_valid_i(~xu_to_mem_bubble),
    .mem_rdt_i(macc_to_wb_rdt_addr),
    .mem_result_i(mem_result),

    .wbu_instruct_type_i(wbu_instruct_type_rg),
    .wbu_instruct_valid_i(~wbu_bubble),

    .wbu_rdt_i(wbu_rdt_addr),
    .wbu_result_i(wbu_rdt_data),

    .fwd_rs0_o(fwd_rs0),
    .fwd_rs1_o(fwd_rs1)
);

assign mem_result = (macc_to_wb_is_mem_op && !macc_to_wb_mem_op_type) ? wbu_load_data : macc_to_wb_rdt_data;

//===========================================================================
// WRITE BACK UNIT INSTANTIATION
//===========================================================================

wbu #(
    .PC_INIT(PC_INIT)
) wbu_inst (
    .clock_i(clock_i),
    .nreset_i(nreset_i),


    .mem_pc_i(macc_to_wb_pc),
    .mem_instruct_i(macc_to_wb_instruct),
    .mem_instruct_type_i(macc_to_wb_instruct_type),

    .mem_rdt_addr_i(macc_to_wb_rdt_addr),
    .mem_rdt_data_i(macc_to_wb_rdt_data),


    .mem_addr_i(macc_to_wb_mem_addr),


    .is_mem_op_i(macc_to_wb_is_mem_op),
    .mem_op_type_i(macc_to_wb_mem_op_type),
    .mem_bubble_i(macc_to_wb_bubble),
    .mem_stall_o(wbu_to_macc_stall),


    .regfile_w_enable_o(wbu_to_rf_wen),
    .regfile_rdt_addr_o(wbu_rdt_addr),
    .regfile_rdt_data_o(wbu_rdt_data),


    .wbu_pc_o(wbu_pc_rg),
    .wbu_instruct_o(wbu_instruct_rg),
    .wbu_instruct_type_o(wbu_instruct_type_rg),
    .wbu_rdt_addr_o(wbu_rdt_addr),
    .wbu_rdt_data_o(wbu_rdt_data),
    .wbu_bubble_o(wbu_bubble),
    .wbu_stall_i(ext_stall_i),


    .dmem_rdata_i(dmem_rdata_i),
    .dmem_ACK_i(dmem_ACK_i),
    .dmem_stall_o(dmem_stall_o),
    .load_data_o(wbu_load_data)
);


















endmodule





