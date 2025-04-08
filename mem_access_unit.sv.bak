module mem_acces_unit #(
    parameter PC_INIT = `PC_INIT
)(




    input logic               clock_i,
    input logic               nreset_i,


    input logic                xu_stall_o,
    output logic               xu_bubble_i,

    input logic [`XLEN-1:0]    xu_pc_i,
    input logic [ 5:0]         xu_instruct_type_i,
    input logic [`ILEN-1:0]    xu_instruct_i,



    input logic [`XLEN-1:0]      xu_mem_addr_i,
    input logic                  xu_mem_cmd_i,
    input logic [`XLEN-1:0]      xu_mem_data_i, 
    input logic [1:0]            xu_mem_size_i,

    input logic                  xu_is_mem_op_i,

    input logic [4:0]            xu_rdt_addr_i,
    input logic [`XLEN-1:0]      xu_rdt_data_i,


    //DATA MEMORY | CACHE

    output logic [`XLEN-1:0]     dmem_addr_o,
    output logic [`XLEN-1:0]     dmem_wdata_o,
    output logic [1:0]           dmem_size_o,
    output logic                 dmem_req_o,
    output logic                 wen_o,

    output logic                 dmem_flush_o,
    output logic                 dmem_stall_i,

    //WRITE BACK


    output logic                 wb_instruct_type_o,
    output logic [`XLEN-1:0]     wb_instruct_o,
    output logic [`XLEN-1:0]     wb_pc_o,
    output logic [`XLEN-1:0]     wb_mem_addr_o,


   
    output logic [ 4:0]          wb_rdt_addr_o,
    output logic [`XLEN-1:0]     wb_rdt_wdata_o,

    output logic                 wb_stall_i,
    output logic                 wb_bubble_o,   
 
    output logic                 wb_is_mem_op_o,
    output logic                 wb_mem_op_type_o


    
);



//===========================================================================
//    PARAMS
//===========================================================================

localparam LOAD  = 1'b0;
localparam STORE = 1'b1;

//===========================================================================
//    SIGNALS
//===========================================================================

logic                 stall, mem_stall;

logic                 is_mem_op;
logic                 mem_op_type;

logic [4:0]           rdt_addr_rg;
logic [`XLEN-1:0]     rdt_data_rg;

logic [`XLEN-1:0]     mem_pc_rg;
logic [`ILEN-1:0]     mem_instruct_rg;
logic [5:0]           mem_instruct_type_rg;
logic [`XLEN-1:0]     mem_bubble_rg;

logic [`XLEN-1:0]     mem_addr_rg;


//===========================================================================
//   SYNCING
//===========================================================================
always_ff @(posedge clock_i or negedge nreset_i) begin
    if (!nreset_i) begin
        mem_bubble_rg <= 1'b1;

       

        mem_instruct_rg <= `NOP_INSTRUCT;
        mem_instruct_type_rg <= '0;
        mem_pc_rg <= PC_INIT;

        is_mem_op <= 1'b0;
        mem_op_type <= LOAD;
        mem_addr_rg <= '0;


        rdt_addr_rg <= '0;
        rdt_data_rg <= '0;

    end else if(!stall)begin


        mem_bubble_rg <= xu_bubble_i;

        mem_instruct_rg <= xu_instruct_i;
        mem_instruct_type_rg <= xu_instruct_type_i;
        mem_pc_rg <= xu_pc_i;

        is_mem_op <= xu_is_mem_op_i;
        mem_op_type <= xu_mem_cmd_i;
        mem_addr_rg <= xu_mem_addr_i;

        rdt_addr_rg <= xu_rdt_addr_i;
        rdt_data_rg <= xu_rdt_data_i;


    end //else


end //always 


//===========================================================================
//   STALL
//===========================================================================


assign stall        = wb_stall_i | mem_stall;
assign mem_stall    = stall;
assign xu_stall_o   = mem_stall;



//===========================================================================
//      MEM  & WB s CONTROL
//===========================================================================
    
assign dmem_addr_o  = mem_addr_rg;          
assign dmem_wdata_o = xu_mem_data_i;        
assign dmem_size_o  = xu_mem_size_i;       
assign dmem_req_o   = (is_mem_op && !xu_bubble_i);            
assign wen_o        = !xu_bubble_i && xu_is_mem_op_i && (xu_mem_cmd_i == STORE); 
assign dmem_flush_o = 1'b0; 


assign wb_bubble_o = mem_bubble_rg;

assign wb_instruct_o = mem_instruct_rg;
assign wb_instruct_type_o = mem_instruct_type_rg;
assign wb_pc_o = mem_pc_rg;
assign wb_mem_addr_o = mem_addr_rg;

assign wb_rdt_addr_o = rdt_addr_rg;
assign wb_rdt_wdata_o = rdt_data_rg;

assign wb_is_mem_op_o = is_mem_op;
assign wb_mem_op_type_o = mem_op_type;


endmodule