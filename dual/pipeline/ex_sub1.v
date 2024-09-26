`include "../mycpu.h"

module ex_sub1(
    input                               clk,
    input                               reset,
    input                               es_valid,

    input  [`SIMPLE_ES_BUS_WD -1:0]     ds_to_es_bus,
    output [`ES_TO_M1S_BUS1_WD -1:0]    es_to_m1s_bus,
    output [`ES_FWD_BUS-1 :0]           es_fwd_bus,

    output [`BR_BUS_WD-1:0]             es_br_bus,
    output [31:0]                       es_pc,
    output                              es_b_or_j              
);

wire [15:0] es_alu_op       ;
wire        es_load_op      ;
wire        es_src1_is_sa   ;  
wire        es_src1_is_pc   ;
wire        es_src2_is_imm  ;
wire        es_src2_is_0imm ; 
wire        es_src2_is_8    ;
wire        es_gr_we        ;
wire [ 4:0] es_dest         ;
wire [15:0] es_imm          ;
wire [31:0] es_rs_value     ;
wire [31:0] es_rt_value     ;
wire [3:0]  es_rf_wen       ;

wire [4:0]  es_rs1;
wire [4:0]  es_rs2;



wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_final_result;

wire        es_reg_write    ;
wire [4:0]  es_rd           ;


// br bus
wire [31:0] es_pd_pc;
wire [31:0] es_real_target_pc;
wire        prd_err;

assign prd_err = es_b_or_j && (es_pd_pc != es_real_target_pc);
assign es_br_bus = {prd_err,es_real_target_pc};

wire   es_first;

assign {
        es_first            ,  //215
        es_pd_pc            ,  //214:183
        es_b_or_j           ,  //182
        es_real_target_pc   ,  //181:150

        es_src2_is_0imm     ,  //149
        es_rs2              ,  //148:144
        es_rs1              ,  //143:139
        es_alu_op           ,  //138:123
        es_load_op          ,  //122
        es_src1_is_sa       ,  //121
        es_src1_is_pc       ,  //120
        es_src2_is_imm      ,  //119
        es_src2_is_8        ,  //118
        es_gr_we            ,  //117
        es_dest             ,  //116:112
        es_imm              ,  //111:96
        es_rs_value         ,  //95 :64
        es_rt_value         ,  //63 :32
        es_pc                  //31 :0
       } = ds_to_es_bus;


assign      es_rd            = es_dest;
assign      es_reg_write     = es_gr_we;
assign      es_res_from_mem  = es_load_op;


//========================= alu op =======================================

// alu result
wire [31:0] es_alu_result;

assign      es_alu_src1  = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                                         es_src1_is_pc  ? es_pc[31:0] :
                                         es_rs_value;

assign      es_alu_src2  = es_src2_is_imm ? {{16{es_imm[15]}}, es_imm[15:0]} : 
                                         es_src2_is_0imm ? {{16{1'b0}}, es_imm[15:0]} :
                                         es_src2_is_8   ? 32'd8 :
                                         es_rt_value;

alu u_alu(
    .alu_op             (es_alu_op          ),
    .alu_src1           (es_alu_src1        ),
    .alu_src2           (es_alu_src2        ),
    .alu_result         (es_alu_result      ),
    //overflow
    .overflow_en        (1'b0     )
    );                                




// final result
assign      op_alu    = | es_alu_op[11:0];

assign      es_final_result = {64{op_alu}} & es_alu_result;


assign      es_rf_wen = {4{es_gr_we}} & 4'b1111 ;




assign es_fwd_bus = {
                    es_valid,
                    es_reg_write,
                    es_rd,
                    es_final_result
                    };





//=================================es to m1s bus==============================================

assign es_to_m1s_bus = {
                        es_first       ,  //75
                        es_rf_wen      ,  //74:71
                        es_res_from_mem,  //70:70
                        es_gr_we       ,  //69:69
                        es_dest        ,  //68:64
                        es_final_result,  //63:32
                        es_pc             //31:0
                        };

endmodule