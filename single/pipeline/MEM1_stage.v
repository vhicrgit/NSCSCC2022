`include "../mycpu.h"

module mem1_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          m2s_allowin    ,
    output                         m1s_allowin    ,
    //from es
    input                          es_to_m1s_valid,
    input  [`ES_TO_M1S_BUS_WD -1:0] es_to_m1s_bus  ,
    //to m1s
    output                          m1s_ex,
    //to m2s
    output                           m1s_to_m2s_valid,
    output [`M1S_TO_M2S_BUS_WD -1:0] m1s_to_m2s_bus  ,
    //from m2s
    input                           ex_taken        ,
    input                           eret_taken      ,
   
    //to forwarding
    output reg [`M1S_FWD_BUS-1 :0] m1s_fwd_bus_1  ,
    output reg [`M1S_FWD_BUS-1 :0] m1s_fwd_bus_2  ,
    output [4                  :0] m1s_rd         ,
    output [31                 :0] m1s_alu_result ,
    output                         m1s_reg_write  ,
    //from hazard
    input                          m2s_flush,
    input                          m1s_stall,
    //to hazard
    output                         m1s_res_from_mem,
    output                         m1s_res_from_cp0,
    output      reg                m1s_valid, 

    output                         m1s_ready_go,

    // data sram interface
    output                         data_sram_req    ,
    output                         data_sram_wr     ,
    output   [1:0]                 data_sram_size   ,
    output   [3:0]                 data_sram_wstrb  ,
    output   [31:0]                data_sram_addr   ,
    output   [31:0]                data_sram_wdata  ,
    input                          data_sram_addr_ok,
    output                         data_uncache     
);


reg [`ES_TO_M1S_BUS_WD -1:0] es_to_m1s_bus_r;
wire        m1s_gr_we;
wire [ 4:0] m1s_dest;
wire        m1s_l_is_lw      ;
wire        m1s_l_is_lb      ;
wire        m1s_l_is_lbu     ;
wire        m1s_l_is_lh      ;
wire        m1s_l_is_lhu     ;
wire        m1s_l_is_lwl     ;
wire        m1s_l_is_lwr     ;
wire [1:0]  m1s_low_addr     ;
wire [3: 0] m1s_rf_wen       ;
wire        es_data_sram_req ;

//exception
wire [31:0]                  m1s_cp0_wdata;
wire [7:0]                   m1s_cp0_addr;
wire [31:0]                  m1s_pc;
wire [ 4:0]                  m1s_excode;
wire                         m1s_mtc0_we;
wire                         m1s_bd;
wire                         m1s_eret_flush;
wire [31:0]                  m1s_badvaddr;


assign {//-----to data sram------
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
       } = es_to_m1s_bus_r;

assign m1s_rd           = m1s_dest;
assign m1s_reg_write    = m1s_gr_we;
assign m1s_mem_read     = m1s_res_from_mem;
assign data_sram_req    = es_data_sram_req && !m1s_stall && !ex_taken && !eret_taken && m1s_valid && m2s_allowin;


assign m1s_ready_go    = !m1s_valid || !m1s_stall && (!data_sram_req || data_sram_req && data_sram_addr_ok);
assign m1s_allowin     = !m1s_valid || m1s_ready_go && m2s_allowin;
assign m1s_to_m2s_valid= m1s_valid && m1s_ready_go && !m2s_flush;

always @(posedge clk) begin
    if (reset) begin
        m1s_valid <= 1'b0;
    end
    else if (m1s_allowin) begin
        m1s_valid <= es_to_m1s_valid;
    end

    if (es_to_m1s_valid && m1s_allowin) begin
        es_to_m1s_bus_r  <= es_to_m1s_bus;
        m1s_fwd_bus_1    <= {1'b1,es_to_m1s_bus[69:32]};
        m1s_fwd_bus_2    <= {1'b1,es_to_m1s_bus[69:32]};
    end
    else if(m1s_allowin)begin
        es_to_m1s_bus_r <= 0;
        m1s_fwd_bus_1   <= 0;
        m1s_fwd_bus_2   <= 0;
    end
end





                                         
assign m1s_to_m2s_bus = {
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
