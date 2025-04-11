

//===========================================================================
 import cpu_core_pkg :: *;
`include "cpu_core_macros.svh"
//===========================================================================


module wbu#(parameter PC_INIT = `PC_INIT)(

    input logic                 clock_i,
    input logic                 nreset_i,

    //memory interface     


    input logic [`XLEN-1:0]     mem_pc_i,
    input logic [`ILEN-1:0]     mem_instruct_i,
    input logic [5:0]           mem_instruct_type_i,

    input logic [4:0]           mem_rdt_addr_i,
    input logic [`XLEN-1:0]     mem_rdt_data_i,

    input logic [`XLEN-1:0]     mem_addr_i,
    input logic [`XLEN-1:0]     mem_data_i,
    input logic                 is_mem_op_i,
    input logic                 mem_op_type_i,

    input logic                 mem_bubble_i,
    output logic                 mem_stall_o,


    //register file interface
    output logic                 regfile_w_enable_o,
    output logic [4:0]           regfile_rdt_addr_o,
    output logic [`XLEN-1:0]     regfile_rdt_data_o,



    //instructions  interface     

    output logic [`XLEN-1:0]     wbu_pc_o,
    output logic [`ILEN-1:0]     wbu_instruct_o,
    output logic [5:0]           wbu_instruct_type_o,

    output logic [4:0]           wbu_rdt_addr_o,
    output logic [`XLEN-1:0]     wbu_rdt_data_o,

    output logic                 wbu_bubble_o,
    input  logic                 wbu_stall_i,

    //DATA MEMORY | CACHE
    
    input logic [`XLEN-1:0]    dmem_rdata_i,
    input logic                dmem_ACK_i,
    output logic               dmem_stall_o,

    //operand forwarding

    output logic [`XLEN-1:0]    load_data_o




    
    );
    




//===========================================================================
//   INTERNAL SIGNALS
//===========================================================================


 logic [`XLEN-1:0]     wbu_pc_rg;
 logic [`ILEN-1:0]     wbu_instruct_rg;
 logic [5:0]           wbu_instruct_type_rg;

 logic [2:0]           func3;

 logic                 wbu_bubble;


logic is_dmem_op;
logic is_dir_writeback;
logic is_dmem_load;
logic is_mem_unsigned;


logic [1:0]         mem_size;
logic [`XLEN-1:0]   mem_addr;

logic [`XLEN-1:0]   load_data;
logic [`XLEN-1:0]   load_word;
logic [15:0]        load_half;
logic [7:0]         load_byte;


logic [`XLEN-1:0]    rdt_wdata, rdt_wdata_rg;
logic [4:0]          rdt_addr, rdt_addr_rg;
logic                wen, wen_rg;


logic                out_stall;
logic                wbu_stall;
logic                dmem_if_stall;
logic                dmem_acc_stall; 
logic                pipe_stall;



//===========================================================================
//    PC INSTRUCTIONS
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i)
begin
    if (!nreset_i) begin
        wbu_pc_rg              <=  PC_INIT;
        wbu_instruct_rg        <= `NOP_INSTRUCT;
        wbu_instruct_type_rg   <= '0;
        wbu_bubble             <=  1'b1;
        
    end else if(!pipe_stall) begin

        wbu_pc_rg              <=   mem_pc_i;
        wbu_instruct_rg        <=   mem_instruct_i;
        wbu_instruct_type_rg   <=   mem_instruct_type_i;
        wbu_bubble             <=   mem_bubble_i;

    end
end

//===========================================================================
//    WRITE BACK UNIT
//===========================================================================

always_ff @(posedge clock_i or negedge nreset_i)
begin
    if (!nreset_i) begin
        rdt_wdata_rg          <= '0;
        rdt_addr_rg           <= '0;
        wen_rg                <= 1'b0;
    end else if(!pipe_stall) begin

        if (is_dmem_load && is_dmem_op) begin

            rdt_wdata_rg          <=   load_data;
            rdt_addr_rg           <=   mem_rdt_addr_i;
            wen_rg                <=  1'b1;

        end else if(is_dir_writeback) begin
            rdt_wdata_rg          <=   mem_rdt_data_i;
            rdt_addr_rg           <=   mem_rdt_addr_i;
            wen_rg                <=  1'b1;
        end

        else  begin

            rdt_wdata_rg          <=   '0;
            rdt_addr_rg           <=   '0;
            wen_rg                <=    1'b0;


        end   

    end // else 
end // always


//===========================================================================

always_comb begin 
    rdt_wdata = '0;
    rdt_addr  = '0;
    wen       =  1'b0;

    if (is_dmem_load && is_dmem_op) begin

        rdt_wdata = load_data;
        rdt_addr  = mem_rdt_addr_i;
        wen       = 1'b1;

    end else if(is_dir_writeback) begin

        rdt_wdata = mem_rdt_data_i;
        rdt_addr  = mem_rdt_addr_i;
        wen       = 1'b1;
    end

    else  begin

        rdt_wdata = '0;
        rdt_addr  = '0;
        wen       =  1'b0;
    
    end

end // always

//===========================================================================

always_comb begin 
    case({is_mem_unsigned, mem_size})

    {1'b0, BYTE} : begin load_data = {{(`XLEN-8){load_byte[7]}}, load_byte[7:0]}; end 
    {1'b0, HWORD}: begin load_data = {{(`XLEN-16){load_half[15]}}, load_half[15:0]}; end 
    {1'b0, WORD} : begin load_data = load_word; end 
    {1'b1, BYTE} : begin load_data = {{(`XLEN-8){1'b0}} , load_byte[7:0]}; end 
    {1'b1, HWORD}: begin load_data = {{(`XLEN-16){1'b0}}, load_word[15:0]}; end
    default: begin load_data = load_word ; end

    endcase
end


assign func3 = mem_instruct_i[14:12];
assign is_mem_unsigned = func3[2];
assign mem_size  = func3[1:0];
assign mem_addr  = mem_addr_i;

assign load_byte  = dmem_rdata_i >> (mem_addr[`XLSB] * 8);
assign load_half = dmem_rdata_i >> (mem_addr[`XLSB] * 8);
assign load_word  = dmem_rdata_i;

assign load_data_o = load_data;


//===========================================================================
//   ASSIGN OUTPUTS
//===========================================================================
assign wbu_pc_o              = wbu_pc_rg;
assign wbu_instruct_o        = wbu_instruct_rg; 
assign wbu_instruct_type_o   = wbu_instruct_type_rg;
assign wbu_rdt_addr_o       = rdt_addr_rg;
assign wbu_rdt_data_o       = rdt_wdata_rg;
assign wbu_bubble_o         = wbu_bubble;





assign regfile_w_enable_o = wen;
assign regfile_rdt_addr_o = rdt_addr;
assign regfile_rdt_data_o = rdt_wdata;


assign is_dmem_op = ~mem_bubble_i && is_mem_op_i;
assign is_dmem_load = ~mem_op_type_i;
assign is_dir_writeback = ~mem_bubble_i && ~is_mem_op_i;

//===========================================================================

assign out_stall  = wbu_stall_i;
assign dmem_if_stall = ~dmem_ACK_i & is_dmem_op;
assign dmem_acc_stall = out_stall;
assign dmem_stall_o = dmem_acc_stall;
assign pipe_stall = out_stall | dmem_if_stall;
assign wbu_stall = (out_stall & ~mem_bubble_i) | dmem_if_stall;




endmodule









