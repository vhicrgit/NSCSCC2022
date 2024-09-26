`include "../mycpu.h"

module mem1_sub1(
    input  [`ES_TO_M1S_BUS1_WD -1:0]    es_to_m1s_bus,
    output [`M1S_TO_M2S_BUS1_WD -1:0]   m1s_to_m2s_bus,
    output [4:0]                        m1s_rd,
    output [31:0]                       m1s_alu_result,
    output                              m1s_reg_write                                              
);


wire                        m1s_gr_we;
wire [ 4:0]                 m1s_dest;

wire [3: 0]                 m1s_rf_wen   ;

wire [31:0]                 m1s_pc;

wire                        m1s_first;

wire                        m1s_res_from_mem;
    


assign {
        m1s_first       ,  //75
        m1s_rf_wen      ,  //74:71
        m1s_res_from_mem,  //70:70
        m1s_gr_we       ,  //69:69
        m1s_dest        ,  //68:64
        m1s_alu_result  ,  //63:32
        m1s_pc             //31:0
       } = es_to_m1s_bus;

assign m1s_rd           = m1s_dest;
assign m1s_reg_write    = m1s_gr_we;
assign m1s_to_m2s_bus = {
                        m1s_first       ,  //74
                        m1s_rf_wen      ,  //73:70
                        m1s_gr_we       ,  //69:69
                        m1s_dest        ,  //68:64
                        m1s_alu_result  ,  //63:32
                        m1s_pc             //31:0
                      };

endmodule