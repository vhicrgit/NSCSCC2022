`include "../mycpu.h"

module mem2_sub1(
    input                               m2s_valid,
    input  [`M1S_TO_M2S_BUS1_WD -1:0]   m1s_to_m2s_bus,
    output [`M2S_TO_WS_BUS_WD -1:0]     m2s_to_ws_bus,
    output [`M2S_FWD_BUS-1 :0 ]         m2s_fwd_bus     ,
    output [31:0]                       m2s_alu_result
);


wire [31:0] m2s_pc;
wire        m2s_gr_we;
wire [ 4:0] m2s_dest;

wire [3: 0] m2s_rf_wen       ;

wire        m2s_first;

wire [4:0]  m2s_rd           ;
wire        m2s_reg_write    ;

assign {
        m2s_first       , //74
        m2s_rf_wen,     //73:70
        m2s_gr_we       ,  //69:69
        m2s_dest        ,  //68:64
        m2s_alu_result  ,  //63:32
        m2s_pc             //31:0
       } = m1s_to_m2s_bus;

assign m2s_rd = m2s_dest;
assign m2s_reg_write = m2s_gr_we;


assign m2s_fwd_bus = {
            m2s_valid,
            m2s_reg_write,
            m2s_rd,
            m2s_alu_result
            };

assign m2s_to_ws_bus = {
                       m2s_first       ,   //74
                       m2s_rf_wen      ,  //73:70
                       m2s_gr_we       ,  //69:69
                       m2s_dest        ,  //68:64
                       m2s_alu_result ,  //63:32
                       m2s_pc             //31:0
                      };

endmodule
