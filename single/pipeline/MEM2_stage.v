`include "../mycpu.h"
`define DATA_BUF_SIZE 3

module mem2_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          ws_allowin    ,
    output                         m2s_allowin    ,
    //from m1s
    input                          m1s_to_m2s_valid,
    input  [`M1S_TO_M2S_BUS_WD -1:0]m1s_to_m2s_bus  ,
    //to ws
    output                         m2s_to_ws_valid,
    output [`M2S_TO_WS_BUS_WD -1:0]m2s_to_ws_bus  ,
    //from data-sram
    input                          data_sram_data_ok,
    input    [31:0]                data_sram_rdata  ,
    //to forwarding
    output reg [`M2S_FWD_BUS-1 :0] m2s_fwd_bus_1  ,
    output reg [`M2S_FWD_BUS-1 :0] m2s_fwd_bus_2  ,
    output [4                  :0] m2s_rd         ,
    output [31                 :0] m2s_alu_result ,
    output                         m2s_reg_write  ,
    //from hazard
    input                          ws_flush,
    input                          m2s_stall,
    //to hazard
    output                         m2s_res_from_mem,
    output      reg                m2s_valid,
    output                         m2s_res_from_mem_ok,
    output                         m2s_res_from_cp0,

    output                         m2s_ready_go,
    //cp0
    output [31:0]                  m2s_cp0_wdata,
    output [7:0]                   m2s_cp0_addr,
    input  [31:0]                  m2s_cp0_rdata,
    output [31:0]                  m2s_pc,
    output [ 4:0]                  m2s_excode,
    output                         m2s_mtc0_we,
    output                         m2s_ex,
    output                         m2s_bd,
    output                         m2s_eret_flush,
    output [31:0]                  m2s_badvaddr
);


reg [`M1S_TO_M2S_BUS_WD -1:0] m1s_to_m2s_bus_r;
wire        m2s_gr_we;
wire [ 4:0] m2s_dest;
wire        m2s_l_is_lw      ;
wire        m2s_l_is_lb      ;
wire        m2s_l_is_lbu     ;
wire        m2s_l_is_lh      ;
wire        m2s_l_is_lhu     ;
wire        m2s_l_is_lwl     ;
wire        m2s_l_is_lwr     ;
wire [1:0]  m2s_low_addr     ;
wire [31:0] lb_rdata        ;
wire [31:0] lbu_rdata       ;
wire [31:0] lh_rdata        ;
wire [31:0] lhu_rdata       ;
wire [3: 0] m2s_rf_wen       ;

//================================ INST QUENE ================================
// reg [31:0] data_buffer [0:`DATA_BUF_SIZE-1];
// reg [1:0] head;
// reg [1:0] tail;
// reg [1:0] i;
// wire empty;

// always@(posedge clk)begin
//     if(reset)
//         head <= 0;
//     else if(ws_allowin && m2s_ready_go)
//         head <= head + 1'b1;
// end

// always@(posedge clk)begin
//     if(reset)
//         tail <= 0;
//     else if(ws_allowin && m2s_ready_go)
//         tail <= tail + 1'b1;
// end

// always@(posedge clk)begin
//     if(reset)begin
//         for(i=0;i<`DATA_BUF_SIZE;i=i+1)
//             data_buffer[i] <= 0;
//     end
//     else if(data_sram_data_ok)
//             data_buffer[tail] <= data_sram_rdata;
// end


assign {//-----exception---------
        m2s_cp0_addr    ,  //166:159
        m2s_bd          ,  //158
        m2s_eret_flush  ,  //157
        m2s_mtc0_we     ,  //156
        m2s_res_from_cp0,  //155
        m2s_cp0_wdata   ,  //154:123
        m2s_badvaddr    ,  //122:91
        m2s_excode      ,  //90:86
        m2s_ex          ,  //85
        //-----exception---------
        m2s_data_sram_req,  //84
        m2s_l_is_lwl    ,  //83
        m2s_l_is_lwr    ,  //82
        m2s_rf_wen      ,  //81:78
        m2s_low_addr    ,  //77:76
        m2s_l_is_lw     ,  //75
        m2s_l_is_lb     ,  //74
        m2s_l_is_lbu    ,  //73
        m2s_l_is_lh     ,  //72
        m2s_l_is_lhu    ,  //71
        m2s_res_from_mem,  //70:70
        m2s_gr_we       ,  //69:69
        m2s_dest        ,  //68:64
        m2s_alu_result  ,  //63:32
        m2s_pc             //31:0
       } = m1s_to_m2s_bus_r;
assign m2s_rd = m2s_dest;
assign m2s_reg_write = m2s_gr_we;

wire [31:0] mem_result;
wire [31:0] final_mem_result;
wire [31:0] m2s_final_result;

assign m2s_res_from_mem_ok = m2s_valid && m2s_res_from_mem && data_sram_data_ok;

assign m2s_to_ws_bus = {
                       m2s_rf_wen      ,  //73:70
                       m2s_gr_we       ,  //69:69
                       m2s_dest        ,  //68:64
                       m2s_final_result,  //63:32
                       m2s_pc             //31:0
                      };

assign m2s_ready_go    = !m2s_valid || !m2s_stall&& (!m2s_data_sram_req || data_sram_data_ok);
assign m2s_allowin     = !m2s_valid || m2s_ready_go && ws_allowin;
assign m2s_to_ws_valid = m2s_valid && m2s_ready_go && !ws_flush;

always @(posedge clk) begin
    if (reset) begin
        m2s_valid <= 1'b0;
    end
    else if (m2s_allowin) begin
        m2s_valid <= m1s_to_m2s_valid;
    end

    if (m1s_to_m2s_valid && m2s_allowin) begin
        m1s_to_m2s_bus_r  = m1s_to_m2s_bus;
        m2s_fwd_bus_1    <= {1'b1,m1s_to_m2s_bus[69:32]};
        m2s_fwd_bus_2    <= {1'b1,m1s_to_m2s_bus[69:32]};
    end
    else if(m2s_allowin)begin
        m1s_to_m2s_bus_r <= 0;
        m2s_fwd_bus_1    <= 0;
        m2s_fwd_bus_2    <= 0;
    end
end

assign lb_rdata = {32{m2s_low_addr == 2'b00}} & {{24{data_sram_rdata[7]}},data_sram_rdata[7:0]}
                | {32{m2s_low_addr == 2'b01}} & {{24{data_sram_rdata[15]}},data_sram_rdata[15:8]}
                | {32{m2s_low_addr == 2'b10}} & {{24{data_sram_rdata[23]}},data_sram_rdata[23:16]}
                | {32{m2s_low_addr == 2'b11}} & {{24{data_sram_rdata[31]}},data_sram_rdata[31:24]};               
assign lbu_rdata ={32{m2s_low_addr == 2'b00}} & {{24{1'b0}},data_sram_rdata[7:0]}
                | {32{m2s_low_addr == 2'b01}} & {{24{1'b0}},data_sram_rdata[15:8]}
                | {32{m2s_low_addr == 2'b10}} & {{24{1'b0}},data_sram_rdata[23:16]}
                | {32{m2s_low_addr == 2'b11}} & {{24{1'b0}},data_sram_rdata[31:24]};
assign lh_rdata = {32{m2s_low_addr == 2'b00}} & {{16{data_sram_rdata[15]}},data_sram_rdata[15:0]}
                | {32{m2s_low_addr == 2'b10}} & {{16{data_sram_rdata[31]}},data_sram_rdata[31:16]};
assign lhu_rdata ={32{m2s_low_addr == 2'b00}} & {{16{1'b0}},data_sram_rdata[15:0]}
                | {32{m2s_low_addr == 2'b10}} & {{16{1'b0}},data_sram_rdata[31:16]};


assign mem_result =  {32{m2s_l_is_lb}}  & lb_rdata
                   | {32{m2s_l_is_lbu}} & lbu_rdata
                   | {32{m2s_l_is_lh}}  & lh_rdata
                   | {32{m2s_l_is_lhu}} & lhu_rdata
                   | {32{m2s_l_is_lw | m2s_l_is_lwl | m2s_l_is_lwr}}  & data_sram_rdata;

assign final_mem_result = m2s_l_is_lwl ? (mem_result << (8*(2'd3 - m2s_low_addr)))
                        : m2s_l_is_lwr ? (mem_result >> (8*m2s_low_addr))
                        : mem_result;

assign m2s_final_result = m2s_res_from_cp0 ? m2s_cp0_rdata
                       : m2s_res_from_mem ? final_mem_result
                       : m2s_alu_result;
                                         


endmodule
