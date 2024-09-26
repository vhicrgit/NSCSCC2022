`include    "../mycpu.h"

module exe_stage(
    input                           clk,
    input                           reset,
    //from ds
    input  [1:0]                    ds_to_es_valid,
    input  [`COMPLEX_ES_BUS_WD-1:0] ds_to_es_bus_0,
    input  [`SIMPLE_ES_BUS_WD-1 :0] ds_to_es_bus_1,
    //to ds
    output                          es_allowin ,
    //from m1s
    input                           m1s_allowin,
    input                           m1s_ex,
    //to m1s
    output [1:0]                     es_to_m1s_valid,
    output [`ES_TO_M1S_BUS0_WD -1:0] es_to_m1s_bus_0,
    output [`ES_TO_M1S_BUS1_WD -1:0] es_to_m1s_bus_1,
    //from m2s
    input                           ex_taken,
    //from cp0
    input                           config_kseg0,
    //from hazard
    input                           es_flush,
    input                           es_stall,
    input                           exc_flush,

    input                           m1s_flush,
    //to hazard
    output                          es_res_from_cp0,
    output                          es_res_from_mem,
    output reg [1:0]                es_valid,
    output                          div_block,
    //to forwarding
    output [`ES_FWD_BUS-1 :0]       es_fwd_bus_0,
    output [`ES_FWD_BUS-1 :0]       es_fwd_bus_1,
    
    //to bht
    output [`BR_BUS_WD-1:0]         es_br_bus,
    output [31:0]                   es_pc_bht,
    output                          es_b_or_j
);

wire es_ready_go;

reg  [`COMPLEX_ES_BUS_WD-1:0] ds_to_es_bus_0_r;
reg  [`SIMPLE_ES_BUS_WD-1 :0] ds_to_es_bus_1_r;

assign es_ready_go     = (!es_valid[0])&(!es_valid[1]) || !es_stall;
assign es_allowin      = (!es_valid[0])&(!es_valid[1]) || es_ready_go && m1s_allowin;
assign es_to_m1s_valid[0] =  es_valid[0] && es_ready_go && !m1s_flush;
assign es_to_m1s_valid[1] =  es_valid[1] && es_ready_go && !m1s_flush;


always@(posedge clk)begin
    if(reset)begin
        es_valid <= 2'b00;
    end
    else if(es_allowin)begin
        es_valid <= ds_to_es_valid;
    end
    if(ds_to_es_valid[0] & es_allowin)begin
        ds_to_es_bus_0_r <= ds_to_es_bus_0;
    end
    else if(es_allowin)begin
        ds_to_es_bus_0_r <= 0;
    end
    if(ds_to_es_valid[1] & es_allowin)begin
        ds_to_es_bus_1_r <= ds_to_es_bus_1;
    end
    else if(es_allowin)begin
        ds_to_es_bus_1_r <= 0;
    end
end



ex_sub0  ex_sub0_t(
    .clk(clk),
    .reset(reset),
    .es_valid(es_valid[0]),
    .ex_taken(ex_taken),
    .exc_flush(exc_flush),
    .m1s_ex(m1s_ex),
    .m1s_allowin(m1s_allowin),
    .config_kseg0(config_kseg0),
    .ds_to_es_bus(ds_to_es_bus_0_r),
    .es_to_m1s_bus(es_to_m1s_bus_0),
    .es_fwd_bus(es_fwd_bus_0),
    .es_res_from_cp0(es_res_from_cp0),
    .es_res_from_mem(es_res_from_mem),
    .div_block(div_block)
);


ex_sub1  ex_sub1_t(
    .clk(clk),
    .reset(reset),
    .es_valid(es_valid[1]),
    .ds_to_es_bus(ds_to_es_bus_1_r),
    .es_to_m1s_bus(es_to_m1s_bus_1),
    .es_fwd_bus(es_fwd_bus_1),

    .es_br_bus(es_br_bus),
    .es_pc(es_pc_bht),
    .es_b_or_j(es_b_or_j)
);


endmodule