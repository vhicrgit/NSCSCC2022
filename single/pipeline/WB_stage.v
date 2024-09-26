`include "../mycpu.h"

module wb_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    output                          ws_allowin    ,
    //from m2s
    input                           m2s_to_ws_valid,
    input  [`M2S_TO_WS_BUS_WD -1:0] m2s_to_ws_bus  ,
    //to rf: for write back
    output [`WS_TO_RF_BUS_WD -1:0]  ws_to_rf_bus  ,
    //to forwarding
    output [4                  :0]  ws_rd         ,
    output reg [`WS_FWD_BUS-1  :0]  ws_fwd_bus_1  ,
    output reg [`WS_FWD_BUS-1  :0]  ws_fwd_bus_2  ,
    output [31                 :0]  ws_final_result,
    output [3                  :0]  ws_rf_wen     ,
    output                          ws_reg_write  ,
    //from hazard
    input                           ws_stall      ,
    //to hazard
    output reg                      ws_valid,
    //trace debug interface
    output [31:0] debug_wb_pc     ,
    output [ 3:0] debug_wb_rf_wen ,
    output [ 4:0] debug_wb_rf_wnum,
    output [31:0] debug_wb_rf_wdata,

    output        ws_ready_go           
);


reg [`M2S_TO_WS_BUS_WD -1:0] m2s_to_ws_bus_r;
wire        ws_gr_we;
wire [4:0] ws_dest;
wire [31:0] ws_pc;
assign {
        ws_rf_wen      ,  //73:70
        ws_gr_we       ,  //69:69
        ws_dest        ,  //68:64
        ws_final_result,  //63:32
        ws_pc             //31:0
       } = m2s_to_ws_bus_r;
assign ws_rd = ws_dest;

wire [3 :0] rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;
assign ws_to_rf_bus = {rf_we   ,  //40:37
                       rf_waddr,  //36:32
                       rf_wdata   //31:0
                      };

assign ws_ready_go = !ws_valid || !ws_stall;
assign ws_allowin  = !ws_valid || ws_ready_go;
always @(posedge clk) begin
    if (reset) begin
        ws_valid <= 1'b0;
    end
    else if (ws_allowin) begin
        ws_valid <= m2s_to_ws_valid;
    end

    if (m2s_to_ws_valid && ws_allowin) begin
        m2s_to_ws_bus_r <= m2s_to_ws_bus;
        ws_fwd_bus_1    <= {1'b1,m2s_to_ws_bus[73:32]};
        ws_fwd_bus_2    <= {1'b1,m2s_to_ws_bus[73:32]};
    end
    else if(ws_allowin)begin
        m2s_to_ws_bus_r <= 0;
        ws_fwd_bus_1    <= 0;
        ws_fwd_bus_2    <= 0;
    end
end

assign rf_we    = {4{ws_gr_we && ws_valid}} & ws_rf_wen;
assign rf_waddr = ws_dest;
assign rf_wdata = ws_final_result;

assign ws_reg_write = (rf_we != 0);



// debug info generate
assign debug_wb_pc       = ws_pc & {32{ws_valid}};
assign debug_wb_rf_wen   = rf_we & {4{ws_valid}} ;
assign debug_wb_rf_wnum  = ws_dest;
assign debug_wb_rf_wdata = rf_wdata;

endmodule
