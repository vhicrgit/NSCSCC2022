`include "../mycpu.h"

module mem1_sub0(
    input                               m1s_stall,
    input                               ex_taken,
    input                               eret_taken,
    input                               m1s_valid,
    input                               m2s_allowin,
    input  [`ES_TO_M1S_BUS0_WD -1:0]    es_to_m1s_bus,
    output [`M1S_TO_M2S_BUS0_WD -1:0]   m1s_to_m2s_bus,
    output [4:0]                        m1s_rd,
    output [31:0]                       m1s_alu_result,
    output                              m1s_reg_write,
    output                              m1s_ex,
    output                              m1s_res_from_mem,
    output                              m1s_res_from_cp0, 
    output                              data_sram_req    ,
    output                              data_sram_wr     ,
    output   [1:0]                      data_sram_size   ,
    output   [3:0]                      data_sram_wstrb  ,
    output   [31:0]                     data_sram_addr   ,
    output   [31:0]                     data_sram_wdata  ,
    output                              data_uncache                                                 
);


wire                        m1s_gr_we;
wire [ 4:0]                 m1s_dest;
wire                        m1s_l_is_lw      ;
wire                        m1s_l_is_lb      ;
wire                        m1s_l_is_lbu     ;
wire                        m1s_l_is_lh      ;
wire                        m1s_l_is_lhu     ;
wire                        m1s_l_is_lwl     ;
wire                        m1s_l_is_lwr     ;
wire [1:0]                  m1s_low_addr     ;
wire [3: 0]                 m1s_rf_wen       ;
wire                        es_data_sram_req ;

//exception
wire [31:0]                 m1s_cp0_wdata;
wire [7:0]                  m1s_cp0_addr;
wire [31:0]                 m1s_pc;
wire [ 4:0]                 m1s_excode;
wire                        m1s_mtc0_we;
wire                        m1s_bd;
wire                        m1s_eret_flush;
wire [31:0]                 m1s_badvaddr;

wire                        m1s_first;

assign {
        m1s_first        , // 239
        //-----to data sram------
        data_sram_wr     , //238
        data_sram_size   , //237:236
        data_sram_wstrb  , //235:232
        data_sram_addr   , //231:200
        data_sram_wdata  , //199:168
        data_uncache     , //167
        //-----exception---------
        m1s_cp0_addr    ,  //166:159
        m1s_bd          ,  //158
        m1s_eret_flush  ,  //157
        m1s_mtc0_we     ,  //156
        m1s_res_from_cp0,  //155
        m1s_cp0_wdata   ,  //154:123
        m1s_badvaddr    ,  //122:91
        m1s_excode      ,  //90:86
        m1s_ex          ,  //85
        //-----exception---------
        es_data_sram_req,  //84
        m1s_l_is_lwl    ,  //83
        m1s_l_is_lwr    ,  //82
        m1s_rf_wen      ,  //81:78
        m1s_low_addr    ,  //77:76
        m1s_l_is_lw     ,  //75
        m1s_l_is_lb     ,  //74
        m1s_l_is_lbu    ,  //73
        m1s_l_is_lh     ,  //72
        m1s_l_is_lhu    ,  //71
        m1s_res_from_mem,  //70:70
        m1s_gr_we       ,  //69:69
        m1s_dest        ,  //68:64
        m1s_alu_result  ,  //63:32
        m1s_pc             //31:0
       } = es_to_m1s_bus;

assign m1s_rd           = m1s_dest;
assign m1s_reg_write    = m1s_gr_we;
assign m1s_mem_read     = m1s_res_from_mem;
assign data_sram_req    = es_data_sram_req && !m1s_stall && !ex_taken && !eret_taken && m1s_valid && m2s_allowin;

assign m1s_to_m2s_bus = {
                        m1s_first        , //167
                        //-----exception---------
                        m1s_cp0_addr    ,  //166:159
                        m1s_bd          ,  //158
                        m1s_eret_flush  ,  //157
                        m1s_mtc0_we     ,  //156
                        m1s_res_from_cp0,  //155
                        m1s_cp0_wdata   ,  //154:123
                        m1s_badvaddr    ,  //122:91
                        m1s_excode      ,  //90:86
                        m1s_ex          ,  //85
                        //-----exception---------
                        data_sram_req   ,  //84
                        m1s_l_is_lwl    ,  //83
                        m1s_l_is_lwr    ,  //82
                        m1s_rf_wen      ,  //81:78
                        m1s_low_addr    ,  //77:76
                        m1s_l_is_lw     ,  //75
                        m1s_l_is_lb     ,  //74
                        m1s_l_is_lbu    ,  //73
                        m1s_l_is_lh     ,  //72
                        m1s_l_is_lhu    ,  //71
                        m1s_res_from_mem,  //70:70
                        m1s_gr_we       ,  //69:69
                        m1s_dest        ,  //68:64
                        m1s_alu_result  ,  //63:32
                        m1s_pc             //31:0
                      };

endmodule