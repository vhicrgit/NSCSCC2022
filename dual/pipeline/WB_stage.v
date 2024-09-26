`include "../mycpu.h"


module wb_stage(
    input                               clk,
    input                               reset,

    //from m2s
    input  [1:0]                        m2s_to_ws_valid,
    input  [`M2S_TO_WS_BUS_WD -1:0]     m2s_to_ws_bus_0, 
    input  [`M2S_TO_WS_BUS_WD -1:0]     m2s_to_ws_bus_1, 
    //to m2s
    output                              ws_allowin    ,
    //from hazard
    input                               ws_stall      ,
    //to hazard
    output reg [1:0]                    ws_valid        ,

    //to forwarding
    output [4:0]                        ws_rd_0         ,
    output [31:0]                       ws_final_result_0,
    output [3:0]                        ws_rf_wen_0     ,
    output                              ws_reg_write_0  ,
    output [4:0]                        ws_rd_1         ,
    output [31:0]                       ws_final_result_1,
    output [3:0]                        ws_rf_wen_1     ,
    output                              ws_reg_write_1  ,

    //to rf
    output [`WS_TO_RF_BUS_WD -1:0]      ws_to_rf_bus_0 ,
    output [`WS_TO_RF_BUS_WD -1:0]      ws_to_rf_bus_1 ,

    output                              ws_ready_go     ,
    //debug for trace
    output [31:0]                       debug_wb_pc_0     ,
    output [ 3:0]                       debug_wb_rf_wen_0 ,
    output [ 4:0]                       debug_wb_rf_wnum_0,
    output [31:0]                       debug_wb_rf_wdata_0,
    output [31:0]                       debug_wb_pc_1     ,
    output [ 3:0]                       debug_wb_rf_wen_1 ,
    output [ 4:0]                       debug_wb_rf_wnum_1,
    output [31:0]                       debug_wb_rf_wdata_1,

    output                              ws_first_0,
    output                              ws_first_1


);

reg [`M2S_TO_WS_BUS_WD -1:0] m2s_to_ws_bus_0_r;
reg [`M2S_TO_WS_BUS_WD -1:0] m2s_to_ws_bus_1_r;


assign ws_ready_go = !ws_valid[0] & !ws_valid[1] || !ws_stall;
assign ws_allowin  = !ws_valid[0] & !ws_valid[1] || ws_ready_go;


always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= m2s_to_ws_valid;
    end

    if (m2s_to_ws_valid[0] && ws_allowin) begin
        m2s_to_ws_bus_0_r <= m2s_to_ws_bus_0;
    end
    else if(ws_allowin)begin
        m2s_to_ws_bus_0_r <= 0;
    end

    if (m2s_to_ws_valid[1] && ws_allowin) begin
        m2s_to_ws_bus_1_r <= m2s_to_ws_bus_1;
    end
    else if(ws_allowin)begin
        m2s_to_ws_bus_1_r <= 0;
    end
end

wire [31:0] ws_pc_0;
wire [31:0] ws_pc_1;
wire [3:0]  rf_we_0;
wire [3:0]  rf_we_1;


wb_sub wb_sub0_t(
    .m2s_to_ws_bus(m2s_to_ws_bus_0_r),
    .ws_valid(ws_valid[0]),
    .ws_to_rf_bus(ws_to_rf_bus_0),
    .ws_rd(ws_rd_0),
    .ws_pc(ws_pc_0),
    .rf_we(rf_we_0),
    .ws_final_result(ws_final_result_0),
    .ws_rf_wen(ws_rf_wen_0),
    .ws_reg_write(ws_reg_write_0),
    .ws_first(ws_first_0)
);


wb_sub wb_sub1_t(
    .m2s_to_ws_bus(m2s_to_ws_bus_1_r),
    .ws_valid(ws_valid[1]),
    .ws_to_rf_bus(ws_to_rf_bus_1),
    .ws_rd(ws_rd_1),
    .ws_pc(ws_pc_1),
    .rf_we(rf_we_1),
    .ws_final_result(ws_final_result_1),
    .ws_rf_wen(ws_rf_wen_1),
    .ws_reg_write(ws_reg_write_1),
    .ws_first(ws_first_1)
);

// debug info generate
assign debug_wb_pc_0       = ws_pc_0 & {32{ws_valid[0]}};
assign debug_wb_rf_wen_0   = rf_we_0 & {4{ws_valid[0]}} ;
assign debug_wb_rf_wnum_0  = ws_rd_0;
assign debug_wb_rf_wdata_0 = ws_final_result_0;

assign debug_wb_pc_1       = ws_pc_1 & {32{ws_valid[1]}};
assign debug_wb_rf_wen_1   = rf_we_1 & {4{ws_valid[1]}} ;
assign debug_wb_rf_wnum_1  = ws_rd_1;
assign debug_wb_rf_wdata_1 = ws_final_result_1;


endmodule