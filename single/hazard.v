`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/06 21:23:38
// Design Name: 
// Module Name: hazard
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


module hazard(
    //from ds
    input [4:0] ds_rs1,
    input [4:0] ds_rs2,
    input       br,
    input       br_prd_err,
    //from es 
    input [4:0] es_rd,
    input       es_mem_read,
    input       es_reg_write,
    input       es_res_from_cp0,
    input       div_block,
    input [4:0] es_rs,
    input [4:0] es_rt,
    //from m1s
    input       m1s_reg_write,
    input       m1s_mem_read,
    input [4:0] m1s_rd,
    input       m1s_res_from_cp0,
    //from m2s
    input       m2s_reg_write,
    input       m2s_mem_read,
    input [4:0] m2s_rd,
    input       m2s_res_from_mem_ok,
    input       m2s_res_from_cp0,
    input       m2s_eret_flush,
    input       m2s_ex,

    //to f1s
    output      f1s_stall,
    output      f1s_flush,
    //to f2s
    output      f2s_stall,
    output      f2s_flush,
    //to ds
    output      ds_stall,
    output      ds_flush,
    //to es
    output      es_flush,
    output      es_stall,
    output      exc_flush,
    //to m1s
    output      m1s_flush,
    output      m1s_stall,
    //to m2s
    output      m2s_flush,
    output      m2s_stall,
    //to ws
    output      ws_flush,
    output      ws_stall,

    //valid
    input       ds_valid,
    input       es_valid,
    input       m1s_valid,
    input       m2s_valid,
    input       ws_valid

);
   
    wire [4:0]  ds_rs1_v;
    wire [4:0]  ds_rs2_v;
    wire        br_v;

    wire [4:0] es_rs_v;
    wire [4:0] es_rt_v;
    wire [4:0] es_rd_v;
    wire es_mem_read_v;

    wire        m1s_mem_read_v;
    wire [4:0]  m1s_rd_v;
    wire        m2s_mem_read_v;
    wire [4:0]  m2s_rd_v;


    assign es_rs_v          = {5{es_valid}} & es_rs;
    assign es_rt_v          = {5{es_valid}} & es_rt;
    assign es_rd_v          = {5{es_valid  && es_reg_write }} & es_rd;
    assign es_mem_read_v    = es_valid & es_mem_read; 

    assign ds_rs1_v         = {5{ds_valid}} & ds_rs1;
    assign ds_rs2_v         = {5{ds_valid}} & ds_rs2;
    assign br_v             = ds_valid & br;
    

    assign m1s_rd_v         = {5{m1s_valid && m1s_reg_write}} & m1s_rd;
    assign m2s_rd_v         = {5{m2s_valid && m2s_reg_write}} & m2s_rd;
    assign m2s_mem_read_v   = m2s_valid & m2s_mem_read;
    assign m1s_mem_read_v   = m1s_valid & m1s_mem_read;
//===========================================================
wire es_rd_after_wr;
wire m1s_rd_after_wr;
wire m2s_rd_after_wr;

assign es_rd_after_wr  = (es_res_from_cp0  | es_mem_read_v  | br_v)    && (es_rd_v == ds_rs1_v || es_rd_v == ds_rs2_v) && es_rd_v != 0;
assign m1s_rd_after_wr = (m1s_res_from_cp0 | m1s_mem_read_v)    && (m1s_rd_v == ds_rs1_v || m1s_rd_v == ds_rs2_v) && m1s_rd_v != 0;
assign m2s_rd_after_wr = (m2s_res_from_cp0 || m2s_mem_read_v && (br_v || !m2s_res_from_mem_ok)) && (m2s_rd_v == ds_rs1_v || m2s_rd_v == ds_rs2_v) && m2s_rd_v != 0;

//===================================================================
    assign f1s_stall = ds_stall;
    assign f2s_stall = ds_stall;
    assign ds_stall = !m2s_eret_flush && !m2s_ex && (es_rd_after_wr || m1s_rd_after_wr || m2s_rd_after_wr || div_block);
    assign es_stall = div_block;
    assign m1s_stall = 0;
    assign m2s_stall = 0;
    assign ws_stall = 0;


    assign f1s_flush = m2s_eret_flush || m2s_ex;
    assign f2s_flush = m2s_eret_flush || m2s_ex;
    assign ds_flush = m2s_eret_flush || m2s_ex;
    assign es_flush = m2s_eret_flush || m2s_ex || es_rd_after_wr || m1s_rd_after_wr || m2s_rd_after_wr;
    assign m1s_flush = m2s_eret_flush || m2s_ex;
    assign m2s_flush = m2s_eret_flush || m2s_ex;
    assign exc_flush = m2s_eret_flush || m2s_ex;
    assign ws_flush = m2s_ex;
    assign fs_flush = 0;

    

endmodule
