//===========================================================================
     import cpu_core_pkg :: *;
    `include "cpu_core_macros.svh"
//===========================================================================



module exec_unit #(parameter  PC_INIT = `PC_INIT )(
    input  logic              clock_i,
    input  logic              nreset_i,




    
  

    // register file 

    input logic [`XLEN-1:0]       reg_file_rs0_i,
    input logic [`XLEN-1:0]       reg_file_rs1_i,

    //branch unit 

    output  logic              du_branch_flush_o,
    output  logic [`XLEN-1:0]  du_branch_pc_o,
    input  logic              du_branch_taken_i,  //upstream branch taken status

    // DECODE  UNIT
    output  logic              du_stall_o, 
    input logic              du_bubble_i,

    input logic [`ILEN-1:0]    du_instruct_i,
    input logic [`XLEN-1:0]    du_pc_i,



    input logic [4:0]        du_rs0_i,
    input logic [4:0]        du_rs1_i,
    input logic [4:0]        du_rdt_i,

    input logic [6:0]        du_opcode_i,
    input logic [3:0]        du_alu_opcode_i,

    input logic [6:0]        du_func7_i,
    input logic [2:0]        du_func3_i,

    input logic              du_is_R_type_i,
    input logic              du_is_I_type_i,
    input logic              du_is_S_type_i,
    input logic              du_is_B_type_i,
    input logic              du_is_U_type_i,
    input logic              du_is_J_type_i,

    input logic [11:0]       du_immI_i,
    input logic [11:0]       du_immB_i,
    input logic [11:0]       du_immS_i,
    input logic [19:0]       du_immU_i,
    input logic [19:0]       du_immJ_i,


    // memory access 

    input  logic                          mem_stall_i,
    output logic                          mem_bubble_o,

    output  logic                          is_mem_op_o,
    output  logic [5:0]                    mem_instruct_type_o,
    output  logic [`ILEN-1:0]              mem_instruct_o,
    output  logic [`XLEN-1:0]              mem_pc_o,



    output  logic [4:0]                    rdt_addr_o,
    output  logic [`XLEN-1:0]              rdt_data_o,

    output logic [`XLEN-1:0]              mem_addr_o,
    output logic                          mem_cmd_o,
    output logic [`XLEN-1:0]              mem_data_o,
    output logic [1:0]                    mem_size_o

);


//===========================================================================
//     SIGNALS
//===========================================================================

logic                 lsu_bubble ;
logic [`XLEN-1:0]     lsu_mem_addr ;
logic                 lsu_mem_cmd ;
logic [`XLEN-1:0]     lsu_mem_data ;
logic [1:0]           lsu_mem_size ;


logic [`XLEN-1:0] branch_result; //branch_next_instruct_pc ;
logic [`XLEN-1:0] branch_pc ;
logic             branch_taken ;
logic             branch_flush ;
logic             branch_bubble ;




logic [3:0]             alu_opcode;
logic [`XLEN-1:0]       alu_rs0;
logic [`XLEN-1:0]       alu_rs1;
logic [`XLEN-1:0]       immI, immU;
logic [`XLEN-1:0]       alu_result;
logic                   alu_bubble;
logic                   is_LUI_op;

logic                   stall, xu_stall;


// mem 


logic                          is_mem_op_rg;
logic [5:0]                    instruct_type;
logic [5:0]                    xu_instruct_type_rg;

logic [`ILEN-1:0]              exu_instruct_rg;
logic [`XLEN-1:0]              exu_pc_rg;

logic [4:0]                    xu_rdt_rg;
logic [`XLEN:0]                xu_result_rg;

logic                          is_xu_WB;
logic                          is_xu_MEM;
logic                          xu_bubble;


//pipline interlock

logic                          is_xu_instuct_load;
logic                          is_xu_instuct_valid;
logic                          is_src_eq_dst;//RAW

logic                          is_du_rs0_eq_xu_rdt;
logic                          is_du_rs1_eq_xu_rdt;
logic                          is_xu_rdt_not_x0;


logic                          is_du_instuct_risb;
logic                          is_du_instuct_valid;
logic                          is_pipe_inlock;







//===========================================================================
//     LSU
//===========================================================================



load_store_unit #(.PC_INIT(`PC_INIT)) lsu_inst (
    .clock_i(clock_i),
    .nreset_i(nreset_i),
    .opcode_i(du_opcode_i),
    .func3_i(du_func3_i),
    .reg_file_rs0_i(reg_file_rs0_i),
    .reg_file_rs1_i(reg_file_rs1_i),
    .is_S_type_i(du_is_S_type_i),
    .immI_i(du_immI_i),
    .immS_i(du_immS_i),
    .bubble_i(du_bubble_i | is_pipe_inlock),
    .stall_i(stall),
    .bubble_o(lsu_bubble),
    .mem_addr_o(lsu_mem_addr),
    .mem_cmd_o(lsu_mem_cmd),
    .mem_data_o(lsu_mem_data),
    .mem_size_o(lsu_mem_size)
);



//===========================================================================
//     BU
//===========================================================================



branch_unit #(.PC_INIT(`PC_INIT)) branch_inst (
    .clock_i(clock_i),
    .nreset_i(nreset_i),
    .pc_i(du_pc_i),
    .opcode_i(du_opcode_i),
    .func3_i(du_func3_i),
    .reg_file_rs0_i(reg_file_rs0_i),
    .reg_file_rs1_i(reg_file_rs1_i),
    .is_B_type_i(du_is_B_type_i),
    .is_J_type_i(du_is_J_type_i),

    .immI_i(du_immI_i),
    .immB_i(du_immB_i),
    .immJ_i(du_immJ_i),

    .next_instruct_pc_o(branch_result),
    .branch_pc_o(branch_pc),
    .branch_taken_i(du_branch_taken_i),
    .branch_taken_o(branch_taken),
    .flush_o(branch_flush),

    .bubble_o(branch_bubble),
    .bubble_i(du_bubble_i | is_pipe_inlock),
    .stall_i(stall)
);



//===========================================================================
//    ALU
//===========================================================================



alu alu_inst (
    .alu_opcode_i(alu_opcode),
    .rs0_data_i(alu_rs0),
    .rs1_data_i(alu_rs1),
    .du_bubble_i(du_bubble_i | is_pipe_inlock),
    .stall_i(stall),
    .alu_result_o(alu_result),
    .alu_bubble_o(alu_bubble),
    .clock_i(clock_i),
    .nreset_i(nreset_i)
);


//===========================================================================
//   SELECT ALU OPERANDS
//===========================================================================

always_comb begin 

    case({du_is_I_type_i, du_is_R_type_i, du_is_U_type_i})
        3'b010: begin 
                alu_rs0 = reg_file_rs0_i;
                alu_rs1 = reg_file_rs1_i;
        end

        3'b100: begin 
                alu_rs0 = reg_file_rs0_i;
                alu_rs1 = immI;
        end

        3'b001: begin 
                alu_rs0 = is_LUI_op ? '0 : du_pc_i; // LUI:AUIPC
                alu_rs1 = immU;
        end

        default : begin 
                alu_rs0 = '0;
                alu_rs1 = '0;
        end


    endcase


    
end//always


assign is_LUI_op = (du_opcode_i == OP_LUI) ;
assign alu_opcode = du_alu_opcode_i;
assign immU = {{(`XLEN-20){1'b0}}, du_immU_i[19:0]};
assign immI = {{(`XLEN-12){du_immI_i[11]}}, du_immI_i};


//===========================================================================
//  PC
//===========================================================================


always_ff @(posedge clock_i or negedge nreset_i) begin
    if(!nreset_i) begin
        exu_pc_rg <= PC_INIT;
    end else if(!stall) begin
        exu_pc_rg <= du_pc_i;
    end
    
end

//===========================================================================
//  INSTRUCT FLOW
//===========================================================================
always_ff @(posedge clock_i or negedge nreset_i) begin
    if (!nreset_i) begin
        exu_instruct_rg <= `NOP_INSTRUCT ;
           end else if (!stall) begin
        exu_instruct_rg <= du_instruct_i; 
    end
end

//===========================================================================
//  INSTRUCTION TYPE 
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i) begin
    if (!nreset_i) begin
        xu_instruct_type_rg <= 6'b0; 

    end else if (!stall) begin
        xu_instruct_type_rg <= instruct_type; 
    end
end

assign instruct_type = {du_is_R_type_i, du_is_I_type_i, du_is_S_type_i, du_is_B_type_i, du_is_U_type_i, du_is_J_type_i};

//===========================================================================
//  RDT REGISTER
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i) begin
    if (!nreset_i) begin
        xu_rdt_rg <= 5'b0; 
    end else if (!stall) begin
        xu_rdt_rg <= du_rdt_i; 
    end
end

//===========================================================================
//  XU RESULT WRITE BACK
//===========================================================================
always_comb begin 
    case({branch_bubble, alu_bubble})

    2'b10:   begin xu_result_rg =   branch_result;      end
    2'b01:   begin xu_result_rg =   alu_result;         end
    
    default: begin xu_result_rg =   alu_result;         end
    

endcase

end  //always


assign is_xu_WB = ~branch_bubble | ~alu_bubble;   //ALU : LUI : JALR : JAL : AUIPC
assign is_xu_MEM = ~lsu_bubble;
assign xu_bubble = branch_bubble & alu_bubble & lsu_bubble;


    



//===========================================================================
//  RAW 
//===========================================================================
always_comb begin
case (is_du_instuct_risb)
    4'b0001: begin is_src_eq_dst =(is_du_rs0_eq_xu_rdt || is_du_rs1_eq_xu_rdt)&& is_xu_rdt_not_x0 ; end
    4'b0010: begin is_src_eq_dst =(is_du_rs0_eq_xu_rdt || is_du_rs1_eq_xu_rdt)&& is_xu_rdt_not_x0 ; end
    4'b0100: begin is_src_eq_dst =(is_du_rs0_eq_xu_rdt                     )&& is_xu_rdt_not_x0 ; end
    4'b1000: begin is_src_eq_dst =(is_du_rs0_eq_xu_rdt || is_du_rs1_eq_xu_rdt)&& is_xu_rdt_not_x0 ; end
    default: begin is_src_eq_dst = 1'b0; end
endcase 

end //always

assign is_du_instuct_risb = {du_is_R_type_i, du_is_I_type_i, du_is_S_type_i, du_is_B_type_i};
assign is_du_rs0_eq_xu_rdt = (du_rs0_i == xu_rdt_rg);
assign is_du_rs1_eq_xu_rdt = (du_rs1_i == xu_rdt_rg);
assign is_xu_rdt_not_x0 = (|xu_rdt_rg);  //or reduction 


assign is_xu_instuct_valid =  ~xu_bubble;
assign is_xu_instuct_load  =  ~lsu_mem_cmd;
assign is_du_instuct_valid =  ~du_bubble_i;

assign is_pipe_inlock = is_xu_MEM && is_src_eq_dst && is_xu_instuct_valid && is_xu_instuct_load ;   //RAW check




//===========================================================================
//  STALL 
//===========================================================================
assign stall  = mem_stall_i;
assign xu_stall =  ( stall & ~du_bubble_i) | is_pipe_inlock;
assign du_stall_o = xu_stall;


//===========================================================================
//  SIGNAL ASSIGNMENTS
//===========================================================================

// Load/Store Unit
assign lsu_mem_addr_o = lsu_mem_addr;
assign lsu_mem_cmd_o  = lsu_mem_cmd;
assign lsu_mem_data_o = lsu_mem_data;
assign lsu_mem_size_o = lsu_mem_size;

// Program Counter and Instruction
assign xu_pc_o       = exu_pc_rg;
assign xu_instruct_o = exu_instruct_rg;
assign xu_instruct_type_o = xu_instruct_type_rg;

assign xu_rdt_addr_o =  xu_rdt_rg;
assign xu_rdt_wdata_o = xu_result_rg;

assign xu_is_mem_op_o = is_xu_MEM;


assign xu_bubble_o = xu_bubble | mem_stall_i;


assign du_branch_flush_o = branch_flush;
assign du_branch_pc_o = branch_pc;

endmodule








