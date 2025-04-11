`include "cpu_core_macros.svh"
import cpu_core_pkg::*;




module op_forward#(parameter
    PC_INIT = `PC_INIT


) (


input logic [`XLEN-1:0]   rf_rs0_i,
input logic [`XLEN-1:0]   rf_rs1_i,


input logic [4:0]         du_rs0_i,
input logic [4:0]         du_rs1_i,
input logic [5:0]         du_instruct_type_i, 
input logic               du_instruct_valid_i, 


input logic [5:0]         xu_instruct_type_i,
input logic               xu_instruct_valid_i,
input logic [4:0]         xu_rdt_i,
input logic [`XLEN-1:0]   xu_result_i,


input logic [5:0]         mem_instruct_type_i,
input logic               mem_instruct_valid_i,
input logic [4:0]         mem_rdt_i,
input logic [`XLEN-1:0]   mem_result_i,


input logic [5:0]         wbu_instruct_type_i,
input logic               wbu_instruct_valid_i,
input logic [4:0]         wbu_rdt_i,
input logic [`XLEN-1:0]   wbu_result_i,



output logic   [`XLEN-1:0]   fwd_rs0_o,
output logic   [`XLEN-1:0]   fwd_rs1_o


);



//===========================================================================
//        LOCAL PARAMS
//===========================================================================

localparam R = 5 ;
localparam I = 4;
localparam S = 3;
localparam B = 2;
localparam U = 1;
localparam J = 0;

//===========================================================================
//        SIGNALS
//===========================================================================


logic   [`XLEN-1:0]   wbu_fwd_rs1;
logic   [`XLEN-1:0]   wbu_fwd_rs0;

logic   [`XLEN-1:0]   mem_fwd_rs1;
logic   [`XLEN-1:0]   mem_fwd_rs0;

logic   [`XLEN-1:0]   xu_fwd_rs1;
logic   [`XLEN-1:0]   xu_fwd_rs0;


logic                 is_xu_rdt_not_x0;
logic                 is_mem_rdt_not_x0;
logic                 is_wbu_rdt_not_x0;

logic                is_du_xu_rs0_raw;
logic                is_du_xu_rs1_raw;
logic                is_du_mem_rs0_raw;
logic                is_du_mem_rs1_raw;
logic                is_du_wbu_rs0_raw;
logic                is_du_wbu_rs1_raw;

logic                is_du_instruct_risb;
logic                is_wbu_instruct_riuj;
logic                is_mem_instruct_riuj;
logic                is_xu_instruct_riuj;

logic  [2:0]         is_rs0_raw,is_rs1_raw;

//===========================================================================
//          XU FWD CONTROL
//===========================================================================


always_comb begin 
    if(is_du_instruct_risb && is_xu_instruct_riuj && xu_instruct_valid_i && du_instruct_valid_i)
    begin 
        if((du_rs0_i == xu_rdt_i)&& is_xu_rdt_not_x0) begin
            xu_fwd_rs0 = xu_result_i;
            is_du_xu_rs0_raw = 1'b1;
        end else begin
            xu_fwd_rs0 = rf_rs0_i;
            is_du_xu_rs0_raw = 1'b0;
        end


        if((du_rs1_i == xu_rdt_i)&& is_xu_rdt_not_x0) begin
            xu_fwd_rs1 = xu_result_i;
            is_du_xu_rs1_raw = 1'b1;
        end else begin
            xu_fwd_rs1 = rf_rs1_i;
            is_du_xu_rs1_raw = 1'b0;
        end


    end else  begin
        xu_fwd_rs0 = rf_rs0_i;
        xu_fwd_rs1 = rf_rs1_i;
        is_du_xu_rs0_raw = 1'b0;
        is_du_xu_rs1_raw = 1'b0;
        
    end

end


//===========================================================================
//          MEM FWD CONTROL
//===========================================================================


always_comb begin 
    if(is_du_instruct_risb && is_mem_instruct_riuj && mem_instruct_valid_i && du_instruct_valid_i)
    begin 
        if((du_rs0_i == mem_rdt_i)&& is_mem_rdt_not_x0) begin
            mem_fwd_rs0 = mem_result_i;
            is_du_mem_rs0_raw = 1'b1;
        end else begin
            mem_fwd_rs0 = rf_rs0_i;
            is_du_mem_rs0_raw = 1'b0;
        end


        if((du_rs1_i == mem_rdt_i)&& is_mem_rdt_not_x0) begin
            mem_fwd_rs1 = mem_result_i;
            is_du_mem_rs1_raw = 1'b1;
        end else begin
            xu_fwd_rs1 = rf_rs1_i;
            is_du_mem_rs1_raw = 1'b0;
        end


    end else  begin
        mem_fwd_rs0 = rf_rs0_i;
        mem_fwd_rs1 = rf_rs1_i;
        is_du_mem_rs0_raw = 1'b0;
        is_du_mem_rs1_raw = 1'b0;
        
    end

end





//===========================================================================
//          WBU FWD CONTROL
//===========================================================================


always_comb begin 
    if(is_du_instruct_risb && is_wbu_instruct_riuj && wbu_instruct_valid_i && du_instruct_valid_i)
    begin 
        if((du_rs0_i == wbu_rdt_i)&& is_wbu_rdt_not_x0) begin
            wbu_fwd_rs0 = wbu_result_i;
            is_du_wbu_rs0_raw = 1'b1;
        end else begin
            wbu_fwd_rs0 = rf_rs0_i;
            is_du_wbu_rs0_raw = 1'b0;
        end


        if((du_rs1_i == wbu_rdt_i)&& is_wbu_rdt_not_x0) begin
            wbu_fwd_rs1 = wbu_result_i;
            is_du_wbu_rs1_raw = 1'b1;
        end else begin
            xu_fwd_rs1 = rf_rs1_i;
            is_du_wbu_rs1_raw = 1'b0;
        end


    end else  begin
        wbu_fwd_rs0 = rf_rs0_i;
        wbu_fwd_rs1 = rf_rs1_i;
        is_du_wbu_rs0_raw = 1'b0;
        is_du_wbu_rs1_raw = 1'b0;
        
    end

end

//===========================================================================
//         GLOBAL FWD CONTROL
//===========================================================================

assign is_rs0_raw = {is_du_xu_rs0_raw,is_du_mem_rs0_raw,is_du_wbu_rs0_raw};
assign is_rs1_raw = {is_du_xu_rs1_raw,is_du_mem_rs1_raw,is_du_wbu_rs1_raw};

always_comb begin 
    casez (is_rs0_raw)
        3'b1??: begin  fwd_rs0_o  = xu_fwd_rs0; end 
        3'b01?: begin  fwd_rs0_o  = mem_fwd_rs0; end
        3'b001: begin  fwd_rs0_o  = wbu_fwd_rs0; end  
        default :  begin  fwd_rs0_o  = rf_rs0_i; end 
    endcase
    
end


always_comb begin 
    casez (is_rs0_raw)
        3'b1??:     begin  fwd_rs1_o  = xu_fwd_rs1; end 
        3'b01?:     begin  fwd_rs1_o  = mem_fwd_rs1; end
        3'b001:     begin  fwd_rs1_o  = wbu_fwd_rs1; end  
        default :   begin  fwd_rs1_o  = rf_rs1_i; end 
    endcase
    
end

//===========================================================================
//      SIGNAL ASSIGNMENT
//===========================================================================

assign is_xu_rdt_not_x0  = (|xu_rdt_i);
assign is_mem_rdt_not_x0 = (|mem_rdt_i);
assign is_wbu_rdt_not_x0 = (|wbu_rdt_i);

assign is_du_instruct_risb  = du_instruct_type_i[R]  | du_instruct_type_i[I]  | du_instruct_type_i[S]  | du_instruct_type_i[B];
assign is_wbu_instruct_riuj = wbu_instruct_type_i[R] | wbu_instruct_type_i[I] | wbu_instruct_type_i[U] | wbu_instruct_type_i[J];
assign is_mem_instruct_riuj = mem_instruct_type_i[R] | mem_instruct_type_i[I] | mem_instruct_type_i[U] | mem_instruct_type_i[J];
assign is_xu_instruct_riuj = xu_instruct_type_i[R]   | xu_instruct_type_i[I]  | xu_instruct_type_i[U]  | xu_instruct_type_i[J];






endmodule