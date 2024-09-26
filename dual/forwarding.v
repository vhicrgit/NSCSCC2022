`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/06 18:33:11
// Design Name: 
// Module Name: forwarding
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "mycpu.h"

module forwarding(
    //from es
    input [4:0] es_rs1,
    input [4:0] es_rs2,
    //from m1s
    input [4:0] m1s_rd,
    input       m1s_reg_write,
    //from m2s
    input [4:0] m2s_rd,
    input       m2s_reg_write,
    //from ws
    input [4:0] ws_rd,
    input       ws_reg_write,
    input [3:0] ws_rf_wen,
    //to es
    output [1:0] alu_src1_fwd,
    output [1:0] alu_src2_fwd,
    output [3:0] alu1_fwd_wen,
    output [3:0] alu2_fwd_wen,
    //from ds
    input [4:0] ds_rs1,
    input [4:0] ds_rs2,
    //to ds
    output [1:0] fwd1,
    output [1:0] fwd2,
    output [3:0] fwd1_wen,
    output [3:0] fwd2_wen,

    input ds_valid,
    input es_valid,
    input m1s_valid,
    input m2s_valid,
    input ws_valid
    );

assign fwd1_wen = (fwd1 == `WB) ? ws_rf_wen : 4'b1111;
assign fwd2_wen = (fwd2 == `WB) ? ws_rf_wen : 4'b1111;
assign alu1_fwd_wen = (alu_src1_fwd == `WB) ? ws_rf_wen : 4'b1111;
assign alu2_fwd_wen = (alu_src2_fwd == `WB) ? ws_rf_wen : 4'b1111;

// assign alu_src1_fwd = !(es_valid) ? 0
//                      : ((es_rs1 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S
//                      : ((es_rs1 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S
//                      : ((es_rs1 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB 
//                      : 0;

// assign alu_src2_fwd = !(es_valid) ? 0
//                      : ((es_rs2 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S 
//                      : ((es_rs2 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S 
//                      : ((es_rs2 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB
//                      : 0;


// assign fwd1 = !(ds_valid) ? 0
//             : ((ds_rs1 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S
//             : ((ds_rs1 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S
//             : ((ds_rs1 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB
//             : 0;

// assign fwd2 = !(ds_valid) ? 0
//             : ((ds_rs2 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S
//             : ((ds_rs2 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S
//             : ((ds_rs2 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB
//             : 0;

endmodule
