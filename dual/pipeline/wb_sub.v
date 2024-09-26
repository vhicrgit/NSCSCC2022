`include "../mycpu.h"


module wb_sub(
    input   [`M2S_TO_WS_BUS_WD -1:0]    m2s_to_ws_bus  ,
    input                               ws_valid,
    output  [`WS_TO_RF_BUS_WD -1:0]     ws_to_rf_bus ,
    output  [4:0]                       ws_rd         ,
    output  [31:0]                      ws_pc,
    output  [3:0]                       rf_we,
    output  [31:0]                      ws_final_result,
    output  [3 :0]                      ws_rf_wen     ,
    output                              ws_reg_write   ,
    output                              ws_first                           
);


wire        ws_gr_we;
wire [4:0]  ws_dest;



assign ws_rd = ws_dest;

assign {
        ws_first       ,   //74
        ws_rf_wen      ,  //73:70
        ws_gr_we       ,  //69:69
        ws_dest        ,  //68:64
        ws_final_result,  //63:32
        ws_pc             //31:0
       } = m2s_to_ws_bus;

wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;

assign rf_we    = {4{ws_gr_we && ws_valid}} & ws_rf_wen;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_final_result;

assign ws_reg_write = (rf_we != 0);



assign ws_to_rf_bus = {rf_we   ,  //40:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };



endmodule