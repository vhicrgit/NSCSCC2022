`include "../mycpu.h"

module mem2_stage(
    input                               clk,
    input                               reset,
    //from m1s
    input  [1:0]                        m1s_to_m2s_valid,
    input  [`M1S_TO_M2S_BUS0_WD -1:0]   m1s_to_m2s_bus_0,
    input  [`M1S_TO_M2S_BUS1_WD -1:0]   m1s_to_m2s_bus_1,
    //to m1s
    output                              m2s_allowin,
    //from ws
    input                               ws_allowin,
    //to ws
    output [1:0]                        m2s_to_ws_valid,
    output [`M2S_TO_WS_BUS_WD -1:0]     m2s_to_ws_bus_0,
    output [`M2S_TO_WS_BUS_WD -1:0]     m2s_to_ws_bus_1,
    //from data sram
    input                               data_sram_data_ok,
    input  [31:0]                       data_sram_rdata  ,
    //from hazard
    input                               ws_flush,
    input                               m2s_stall,
    //to hazard
    output                              m2s_res_from_mem,
    output reg [1:0]                    m2s_valid,
    output                              m2s_res_from_mem_ok,
    output                              m2s_res_from_cp0,
    output                              m2s_ready_go,
    //to forwarding
    output [`M2S_FWD_BUS-1 :0]          m2s_fwd_bus_0  ,
    output [31:0]                       m2s_alu_result_0,
    output [`M2S_FWD_BUS-1 :0]          m2s_fwd_bus_1  ,
    output [31:0]                       m2s_alu_result_1,
    //cp0
    input  [31:0]                       m2s_cp0_rdata,
    output [31:0]                       m2s_cp0_wdata,
    output [7:0]                        m2s_cp0_addr,
    output [31:0]                       m2s_pc_cp0,
    output [ 4:0]                       m2s_excode,
    output                              m2s_mtc0_we,
    output                              m2s_ex,
    output                              m2s_bd,
    output                              m2s_eret_flush,
    output [31:0]                       m2s_badvaddr
);

reg [`M1S_TO_M2S_BUS0_WD -1:0]           m1s_to_m2s_bus_0_r;
reg [`M1S_TO_M2S_BUS1_WD -1:0]           m1s_to_m2s_bus_1_r;

wire  m2s_data_sram_req;

wire first_1;
assign first_1 = m1s_to_m2s_bus_1_r[`M1S_TO_M2S_BUS1_WD -1];

assign m2s_ready_go    = !m2s_valid[0] & !m2s_valid[1] || !m2s_stall&& (!m2s_data_sram_req || data_sram_data_ok);
assign m2s_allowin     = !m2s_valid[0] & !m2s_valid[1] || m2s_ready_go && ws_allowin;
assign m2s_to_ws_valid[0] = m2s_valid[0] && m2s_ready_go && !ws_flush;
assign m2s_to_ws_valid[1] = m2s_valid[1] && m2s_ready_go && !(ws_flush && !first_1);

always @(posedge clk) begin
    if (reset) begin
        m2s_valid <= 2'b0;
    end
    else if (m2s_allowin) begin
        m2s_valid <= m1s_to_m2s_valid;
    end
    if (m1s_to_m2s_valid[0] && m2s_allowin) begin
        m1s_to_m2s_bus_0_r  <= m1s_to_m2s_bus_0;
    end
    else if(m2s_allowin)begin
        m1s_to_m2s_bus_0_r  <= 0;
    end
    if (m1s_to_m2s_valid[1] && m2s_allowin) begin
        m1s_to_m2s_bus_1_r  <= m1s_to_m2s_bus_1;
    end
    else if(m2s_allowin)begin
        m1s_to_m2s_bus_1_r  <= 0;
    end
end

mem2_sub0 mem2_sub0_t(
    .m1s_to_m2s_bus(m1s_to_m2s_bus_0_r),
    .m2s_valid(m2s_valid[0]),
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata(data_sram_rdata),
    .m2s_cp0_rdata(m2s_cp0_rdata),
    .m2s_to_ws_bus(m2s_to_ws_bus_0),
    .m2s_res_from_mem(m2s_res_from_mem),
    .m2s_res_from_mem_ok(m2s_res_from_mem_ok),
    .m2s_res_from_cp0(m2s_res_from_cp0),
    .m2s_fwd_bus(m2s_fwd_bus_0),
    .m2s_alu_result(m2s_alu_result_0),
    .m2s_cp0_wdata(m2s_cp0_wdata),
    .m2s_cp0_addr(m2s_cp0_addr),
    .m2s_pc(m2s_pc_cp0),

    .m2s_excode(m2s_excode),
    .m2s_mtc0_we(m2s_mtc0_we),
    .m2s_ex(m2s_ex),
    .m2s_bd(m2s_bd),
    .m2s_eret_flush(m2s_eret_flush),
    .m2s_badvaddr(m2s_badvaddr),

    .m2s_data_sram_req(m2s_data_sram_req)
);


mem2_sub1 mem2_sub1_t(
    .m2s_valid(m2s_valid[1]),
    .m1s_to_m2s_bus(m1s_to_m2s_bus_1_r),
    .m2s_to_ws_bus(m2s_to_ws_bus_1),
    .m2s_fwd_bus(m2s_fwd_bus_1),
    .m2s_alu_result(m2s_alu_result_1)
);


endmodule