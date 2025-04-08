
//===========================================================================
 import cpu_core_pkg :: *;
`include "cpu_core_macros.svh"
//===========================================================================



module load_store_unit #(parameter PC_INIT = `PC_INIT)
    (
    input logic               clock_i,
    input logic               nreset_i,
    
    

    input logic [6:0]          opcode_i,


    input logic [2:0]        func3_i,
    input logic [`XLEN-1:0]  reg_file_rs0_i,
    input logic [`XLEN-1:0]  reg_file_rs1_i,

    input logic              is_S_type_i,


    input logic [11:0]       immI_i,
    input logic [11:0]       immS_i,
    

    output  logic                 bubble_o,
    input   logic                 bubble_i,
    input   logic                 stall_i,

    output logic [`XLEN-1:0]      mem_addr_o,
    output logic                  mem_cmd_o,
    output logic [`XLEN-1:0]      mem_data_o,
    output logic [1:0]            mem_size_o

 
    );

    localparam LOAD = 1'b0;
    localparam STORE = 1'b1;
    
//===========================================================================
//        logical signal 
//===========================================================================    


logic                  bubble, bubble_rg;

logic [`XLEN-1:0]      mem_addr_rg;
logic                  mem_cmd_rg;
logic [`XLEN-1:0]      mem_data_rg; 
logic [1:0]            mem_size_rg;



logic [`XLEN-1:0]      immI, immS;

logic                  is_op_store, is_op_load;
logic [`XLEN-1:0]      load_addr, store_addr;
logic [`XLEN-1:0]      store_data;



//===========================================================================
//       SYNCING 
//===========================================================================   

always_ff @(posedge clock_i or negedge nreset_i) begin
    if (!nreset_i) begin
        bubble_rg <= 1'b1;
        mem_addr_rg <= '0;
        mem_cmd_rg <= LOAD;
        mem_data_rg <= '0;
        mem_size_rg <= BYTE;
    end else if(! stall_i )begin
        bubble_rg <= bubble;
        mem_addr_rg <= is_op_store ? store_addr: load_addr;
        mem_cmd_rg <= is_op_store ;
        mem_data_rg <= is_op_store ? store_data : '0 ;
        mem_size_rg <=  func3_i[1:0] ;
    end
end
//===========================================================================
//     STORE DATA
//=========================================================================== 
 always_comb  begin
    case(func3_i[1:0])

    BYTE    : store_data = ((reg_file_rs1_i[7:0])  <<  (8 * store_addr[`XLSB]));  
    HWORD   : store_data = (reg_file_rs1_i[15:0])  <<  (8 * store_addr[`XLSB]);
    WORD    : store_data = reg_file_rs1_i;

    default : store_data = reg_file_rs1_i;

    endcase


 end
    







//===========================================================================
//      ASSIGNEMENTS
//===========================================================================  


assign immS = {{ (`XLEN-12){immS_i[11]  }}, immS_i };
assign immI = {{(`XLEN-12) {immI_i[11]  }}, immI_i };

assign is_op_store = is_S_type_i;
assign is_op_load   = (opcode_i == OP_LOAD);
assign bubble  = (is_op_load || is_op_store) ? bubble_i : 1'b1;

assign load_addr   = reg_file_rs0_i + immI;
assign store_addr  = reg_file_rs0_i + immS;


assign mem_addr_o = mem_addr_rg;
assign mem_cmd_o  = mem_cmd_rg;
assign mem_data_o = mem_data_rg;
assign mem_size_o = mem_size_rg;
assign bubble_o   = bubble_rg;




endmodule
