`include "../mycpu.h"

module mem1_stage(
    input                               clk,
    input                               reset,

    //from es
    input  [1:0]                        es_to_m1s_valid,
    input  [`ES_TO_M1S_BUS0_WD -1:0]    es_to_m1s_bus_0,
    input  [`ES_TO_M1S_BUS1_WD -1:0]    es_to_m1s_bus_1,
    //to es
    output                              m1s_allowin,
    output                              m1s_ex,
    //from m2s
    input                               m2s_allowin,
    input                               ex_taken,
    input                               eret_taken,
    //to m2s
    output [1:0]                        m1s_to_m2s_valid,
    output [`M1S_TO_M2S_BUS0_WD -1:0]   m1s_to_m2s_bus_0,
    output [`M1S_TO_M2S_BUS1_WD -1:0]   m1s_to_m2s_bus_1,
    //to forwarding
    output reg [`M1S_FWD_BUS-1 :0]      m1s_fwd_bus_0,
    output reg [`M1S_FWD_BUS-1 :0]      m1s_fwd_bus_1,
    output [4:0]                        m1s_rd_0,
    output [31:0]                       m1s_alu_result_0,
    output                              m1s_reg_write_0,
    output [4:0]                        m1s_rd_1,
    output [31:0]                       m1s_alu_result_1,
    output                              m1s_reg_write_1,
    //from hazard
    input                               m2s_flush,
    input                               m1s_stall,
    //to hazard
    output                              m1s_res_from_mem,
    output                              m1s_res_from_cp0,
    
    output reg [1:0]                    m1s_valid,
    output                              m1s_ready_go,

    //data sram interface
    output                              data_sram_req    ,
    output                              data_sram_wr     ,
    output   [1:0]                      data_sram_size   ,
    output   [3:0]                      data_sram_wstrb  ,
    output   [31:0]                     data_sram_addr   ,
    output   [31:0]                     data_sram_wdata  ,
    input                               data_sram_addr_ok,
    output                              data_uncache 
);

reg [`ES_TO_M1S_BUS0_WD -1:0] es_to_m1s_bus_r_0;
reg [`ES_TO_M1S_BUS1_WD -1:0] es_to_m1s_bus_r_1;

assign m1s_ready_go         = !m1s_valid[0] & !m1s_valid[1] || !m1s_stall && (!data_sram_req || data_sram_req && data_sram_addr_ok);
assign m1s_allowin          = !m1s_valid[0] & !m1s_valid[1] || m1s_ready_go && m2s_allowin;
assign m1s_to_m2s_valid[0]     = m1s_valid[0] && m1s_ready_go && !m2s_flush;
assign m1s_to_m2s_valid[1]     = m1s_valid[1] && m1s_ready_go && !m2s_flush;


always @(posedge clk) begin
    if (reset) begin
        m1s_valid <= 2'b0;
    end
    else if (m1s_allowin) begin
        m1s_valid <= es_to_m1s_valid;
    end
    if (es_to_m1s_valid[0] && m1s_allowin) begin
        es_to_m1s_bus_r_0   <= es_to_m1s_bus_0;
        m1s_fwd_bus_0       <= {1'b1,es_to_m1s_bus_0[69:32]};
    end
    else if(m1s_allowin)begin
        es_to_m1s_bus_r_0   <= 0;
        m1s_fwd_bus_0       <= 0;
    end
    if (es_to_m1s_valid[1] && m1s_allowin) begin
        es_to_m1s_bus_r_1   <= es_to_m1s_bus_1;
        m1s_fwd_bus_1       <= {1'b1,es_to_m1s_bus_1[69:32]};
    end
    else if(m1s_allowin)begin
        es_to_m1s_bus_r_1   <= 0;
        m1s_fwd_bus_1       <= 0;
    end
end

mem1_sub0 mem1_sub0_t(
    .m1s_stall(m1s_stall),
    .ex_taken(ex_taken),
    .eret_taken(eret_taken),
    .m1s_valid(m1s_valid[0]),
    .m2s_allowin(m2s_allowin),
    .es_to_m1s_bus(es_to_m1s_bus_r_0),
    .m1s_to_m2s_bus(m1s_to_m2s_bus_0),
    .m1s_rd(m1s_rd_0),
    .m1s_alu_result(m1s_alu_result_0),
    .m1s_reg_write(m1s_reg_write_0),
    .m1s_ex(m1s_ex),
    .m1s_res_from_mem(m1s_res_from_mem),
    .m1s_res_from_cp0(m1s_res_from_cp0),
    .data_sram_req(data_sram_req),
    .data_sram_wr(data_sram_wr),
    .data_sram_size(data_sram_size),
    .data_sram_wstrb(data_sram_wstrb),
    .data_sram_addr(data_sram_addr),
    .data_sram_wdata(data_sram_wdata),
    .data_uncache(data_uncache)
);



mem1_sub1 mem1_sub1_t(
    .es_to_m1s_bus(es_to_m1s_bus_r_1),
    .m1s_to_m2s_bus(m1s_to_m2s_bus_1),
    .m1s_rd(m1s_rd_1),
    .m1s_alu_result(m1s_alu_result_1),
    .m1s_reg_write(m1s_reg_write_1)
);

endmodule