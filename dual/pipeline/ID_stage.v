`include "../mycpu.h"

module id_stage(
    input                           clk           ,
    input                           reset         ,
    //allowin
    input                           es_allowin    ,
    //fifo
    input                           fifo_to_ds_valid_0,
    input                           fifo_to_ds_valid_1,
    input  [`FIFO_TO_DS_BUS_WD -1:0]fifo_to_ds_bus_0  ,
    input  [`FIFO_TO_DS_BUS_WD -1:0]fifo_to_ds_bus_1  ,
    output [ 1                :0]   issue_mode,
    //es
    output [`SIMPLE_ES_BUS_WD-1 :0]    simple_es_bus,
    output [`COMPLEX_ES_BUS_WD-1 :0]   complex_es_bus,
    output                          simple_es_bus_valid,
    output                          complex_es_bus_valid,
    //to regfile
    output [ 4                :0]   rf_raddr0    ,
    output [ 4                :0]   rf_raddr1    ,
    output [ 4                :0]   rf_raddr2    ,
    output [ 4                :0]   rf_raddr3    ,
    input  [31                :0]   rf_rdata0    ,
    input  [31                :0]   rf_rdata1    ,
    input  [31                :0]   rf_rdata2    ,
    input  [31                :0]   rf_rdata3    ,
    //forwarding
    input  [`ES_FWD_BUS-1     :0]   es_fwd_bus_0,
    input  [`ES_FWD_BUS-1     :0]   es_fwd_bus_1,
    input  [`M1S_FWD_BUS-1    :0]   m1s_fwd_bus_0,
    input  [`M1S_FWD_BUS-1    :0]   m1s_fwd_bus_1,
    input  [`M2S_FWD_BUS-1    :0]   m2s_fwd_bus_0,
    input  [`M2S_FWD_BUS-1    :0]   m2s_fwd_bus_1,

    input                           es_res_from_cp0,
    input                           m1s_res_from_cp0,
    input                           m2s_res_from_cp0,
    input                           es_mem_read,
    input                           m1s_mem_read,
    input                           m2s_mem_read,
    input                           m2s_res_from_mem_ok,
    //from cp0
    input                           has_int     
);



//==============================================================================
// wire [`SIMPLE_ES_BUS-1 :0]  simple_es_bus;
// wire [`COMPLEX_ES_BUS-1 :0] complex_es_bus;
// wire                        simple_es_bus_valid;
// wire                        complex_es_bus_valid;
wire  [31:                 0]  es_alu_result_0;
wire  [31:                 0]  es_alu_result_1;
wire  [31:                 0]  m1s_alu_result_0;
wire  [31:                 0]  m1s_alu_result_1;
wire  [31:                 0]  m2s_alu_result_0;
wire  [31:                 0]  m2s_alu_result_1;
wire  [4                 :0]   es_rd_0       ;
wire  [4                 :0]   es_rd_1       ;
wire  [4                 :0]   m1s_rd_0       ;
wire  [4                 :0]   m1s_rd_1       ;
wire  [4                 :0]   m2s_rd_0       ;
wire  [4                 :0]   m2s_rd_1       ;
wire                           es_reg_write_0;
wire                           es_reg_write_1;
wire                           m1s_reg_write_0;
wire                           m1s_reg_write_1;
wire                           m2s_reg_write_0;
wire                           m2s_reg_write_1;
wire                           es_valid_0    ;
wire                           es_valid_1    ;
wire                           m1s_valid_0    ;
wire                           m1s_valid_1    ;
wire                           m2s_valid_0    ;
wire                           m2s_valid_1    ;
    


assign {
        es_valid_0,
        es_reg_write_0,
        es_rd_0,
        es_alu_result_0} = es_fwd_bus_0;
assign {
        es_valid_1,
        es_reg_write_1,
        es_rd_1,
        es_alu_result_1} = es_fwd_bus_1;
assign {
        m1s_valid_0,
        m1s_reg_write_0,
        m1s_rd_0,
        m1s_alu_result_0} = m1s_fwd_bus_0;
assign {
        m1s_valid_1,
        m1s_reg_write_1,
        m1s_rd_1,
        m1s_alu_result_1} = m1s_fwd_bus_1;
assign {
        m2s_valid_0,
        m2s_reg_write_0,
        m2s_rd_0,
        m2s_alu_result_0} = m2s_fwd_bus_0;
assign {
        m2s_valid_1,
        m2s_reg_write_1,
        m2s_rd_1,
        m2s_alu_result_1} = m2s_fwd_bus_1;



wire                        inst_type_0;
wire                        inst_type_1;
wire                        special_inst_0;
wire                        special_inst_1;
wire                        sub_0_ready_go;
wire                        sub_1_ready_go;
wire                        ds_reg_write_0;
wire                        ds_reg_write_1;
wire [ 4: 0]                ds_rs1_0;
wire [ 4: 0]                ds_rs2_0;
wire [ 4: 0]                ds_rd_0;
wire [ 4: 0]                ds_rs1_1;
wire [ 4: 0]                ds_rs2_1;
wire [ 4: 0]                ds_rd_1;
wire [`DECODE_BUS_WD-1 : 0]    decode_bus_0;
wire [`DECODE_BUS_WD-1 : 0]    decode_bus_1;
wire                        b_or_j_0;
wire                        b_or_j_1;
wire                        sub_1_is_bd;


wire                        rd_after_wr;
wire                        wr_after_wr;
wire                        dual_issue;
wire                        signle_issue;

id_sub id_sub_0(
    //ds
    .fifo_to_ds_valid               (fifo_to_ds_valid_0 ),
    .fifo_to_ds_bus                 (fifo_to_ds_bus_0   ),
    .first                          (1'b1               ),
    
    .inst_type                      (inst_type_0        ), //simple or complex
    .ready_go                       (sub_0_ready_go     ),
    .decode_bus                     (decode_bus_0       ),
    .special_inst                   (special_inst_0     ),

    .ds_rs1                         (ds_rs1_0           ),
    .ds_rs2                         (ds_rs2_0           ),
    .ds_rd                          (ds_rd_0            ),
    //to regfile
    .rf_raddr0                      (rf_raddr0          ),
    .rf_rdata0                      (rf_rdata0          ),
    .rf_raddr1                      (rf_raddr1          ),
    .rf_rdata1                      (rf_rdata1          ),

    //forwarding
    .es_alu_result_0                (es_alu_result_0    ),
    .es_alu_result_1                (es_alu_result_1    ),
    .m1s_alu_result_0               (m1s_alu_result_0   ),
    .m1s_alu_result_1               (m1s_alu_result_1   ),
    .m2s_alu_result_0               (m2s_alu_result_0   ),
    .m2s_alu_result_1               (m2s_alu_result_1   ),
    .es_rd_0                        (es_rd_0            ),
    .es_rd_1                        (es_rd_1            ),
    .m1s_rd_0                       (m1s_rd_0           ),
    .m1s_rd_1                       (m1s_rd_1           ),
    .m2s_rd_0                       (m2s_rd_0           ),
    .m2s_rd_1                       (m2s_rd_1           ),
    .es_reg_write_0                 (es_reg_write_0     ),
    .es_reg_write_1                 (es_reg_write_1     ),
    .m1s_reg_write_0                (m1s_reg_write_0    ),
    .m1s_reg_write_1                (m1s_reg_write_1    ),
    .m2s_reg_write_0                (m2s_reg_write_0    ),
    .m2s_reg_write_1                (m2s_reg_write_1    ),
    .es_valid_0                     (es_valid_0         ),
    .es_valid_1                     (es_valid_1         ),
    .m1s_valid_0                    (m1s_valid_0        ),
    .m1s_valid_1                    (m1s_valid_1        ),
    .m2s_valid_0                    (m2s_valid_0        ),
    .m2s_valid_1                    (m2s_valid_1        ),

    .es_res_from_cp0                (es_res_from_cp0    ),
    .m1s_res_from_cp0               (m1s_res_from_cp0   ),
    .m2s_res_from_cp0               (m2s_res_from_cp0   ),
    .es_mem_read                    (es_mem_read        ),
    .m1s_mem_read                   (m1s_mem_read       ),
    .m2s_mem_read                   (m2s_mem_read       ),
    .m2s_res_from_mem_ok            (m2s_res_from_mem_ok),

    //from cp0
    .has_int                        (has_int            ),
    //
    .b_or_j                         (b_or_j_0           ),
    .preinst_is_bj                  (1'b0               ),
    .ds_bd                          (                   )
);

id_sub id_sub_1(
    //ds
    .fifo_to_ds_valid               (fifo_to_ds_valid_1 ),
    .fifo_to_ds_bus                 (fifo_to_ds_bus_1   ),
    .first                          (1'b0               ),
    
    .inst_type                      (inst_type_1        ), //simple or complex
    .ready_go                       (sub_1_ready_go     ),
    .decode_bus                     (decode_bus_1       ),
    .special_inst                   (special_inst_1     ),
    
    .ds_rs1                         (ds_rs1_1           ),
    .ds_rs2                         (ds_rs2_1           ),
    .ds_rd                          (ds_rd_1            ),
    //to regfile
    .rf_raddr0                      (rf_raddr2          ),
    .rf_rdata0                      (rf_rdata2          ),
    .rf_raddr1                      (rf_raddr3          ),
    .rf_rdata1                      (rf_rdata3          ),

    //forwarding
    .es_alu_result_0                (es_alu_result_0    ),
    .es_alu_result_1                (es_alu_result_1    ),
    .m1s_alu_result_0               (m1s_alu_result_0   ),
    .m1s_alu_result_1               (m1s_alu_result_1   ),
    .m2s_alu_result_0               (m2s_alu_result_0   ),
    .m2s_alu_result_1               (m2s_alu_result_1   ),
    .es_rd_0                        (es_rd_0            ),
    .es_rd_1                        (es_rd_1            ),
    .m1s_rd_0                       (m1s_rd_0           ),
    .m1s_rd_1                       (m1s_rd_1           ),
    .m2s_rd_0                       (m2s_rd_0           ),
    .m2s_rd_1                       (m2s_rd_1           ),
    .es_reg_write_0                 (es_reg_write_0     ),
    .es_reg_write_1                 (es_reg_write_1     ),
    .m1s_reg_write_0                (m1s_reg_write_0    ),
    .m1s_reg_write_1                (m1s_reg_write_1    ),
    .m2s_reg_write_0                (m2s_reg_write_0    ),
    .m2s_reg_write_1                (m2s_reg_write_1    ),
    .es_valid_0                     (es_valid_0         ),
    .es_valid_1                     (es_valid_1         ),
    .m1s_valid_0                    (m1s_valid_0        ),
    .m1s_valid_1                    (m1s_valid_1        ),
    .m2s_valid_0                    (m2s_valid_0        ),
    .m2s_valid_1                    (m2s_valid_1        ),

    .es_res_from_cp0                (es_res_from_cp0    ),
    .m1s_res_from_cp0               (m1s_res_from_cp0   ),
    .m2s_res_from_cp0               (m2s_res_from_cp0   ),
    .es_mem_read                    (es_mem_read        ),
    .m1s_mem_read                   (m1s_mem_read       ),
    .m2s_mem_read                   (m2s_mem_read       ),
    .m2s_res_from_mem_ok            (m2s_res_from_mem_ok),

    //from cp0
    .has_int                        (1'b0               ),
    //
    .b_or_j                         (b_or_j_1           ),
    .preinst_is_bj                  (b_or_j_0           ),
    .ds_bd                          (sub_1_is_bd        )
);

assign ds_reg_write_0 = decode_bus_0[118];
assign ds_reg_write_1 = decode_bus_1[118];
assign rd_after_wr  = (ds_rd_0 == ds_rs1_1 || ds_rd_0 == ds_rs2_1) && ds_reg_write_0 && (ds_rd_0 != 0);
assign wr_after_wr  = (ds_rd_0 == ds_rd_1) && ds_reg_write_0 && ds_reg_write_1 && (ds_rd_0 != 0);
assign dual_issue   = (sub_0_ready_go & fifo_to_ds_valid_0 & sub_1_ready_go & fifo_to_ds_valid_1) && !(inst_type_0 && inst_type_1) 
                        && !b_or_j_1 && !rd_after_wr && !wr_after_wr && !(special_inst_0 | special_inst_1);
assign signle_issue = sub_0_ready_go & fifo_to_ds_valid_0 & !b_or_j_0;
assign issue_mode   = (dual_issue & es_allowin) ? `DUAL
                    : (signle_issue & es_allowin) ? `SIGNLE
                    : 0;


assign complex_es_bus = (issue_mode == `DUAL && inst_type_0)    ? {decode_bus_0[251],decode_bus_0[185:0]}
                      : (issue_mode == `DUAL)                   ? {decode_bus_1[251],decode_bus_1[185:0]}
                      : (issue_mode == `SIGNLE)                 ? {decode_bus_0[251],decode_bus_0[185:0]}
                      : 0;
assign simple_es_bus  = (issue_mode == `DUAL && inst_type_0) ? {decode_bus_1[251:186],decode_bus_1[150:118],decode_bus_1[116:0]}
                      : (issue_mode == `DUAL)                ? {decode_bus_0[251:186],decode_bus_0[150:118],decode_bus_0[116:0]}
                      : 0;

assign simple_es_bus_valid = issue_mode == `DUAL;
assign complex_es_bus_valid = (issue_mode == `DUAL) || (issue_mode == `SIGNLE);


// assign simple_es_bus = {
//                         ds_pd_pc         ,  //250:219
//                         b_or_j           ,  //218
//                         br_real_target   ,  //217:186
//                         src2_is_0imm     ,  //150:150
//                         ds_rs2           ,  //149:145
//                         ds_rs1           ,  //144:140
//                         alu_op           ,  //139:124
//                         load_op          ,  //123:123
//                         src1_is_sa       ,  //122:122
//                         src1_is_pc       ,  //121:121
//                         src2_is_imm      ,  //120:120
//                         src2_is_8        ,  //119:119
//                         gr_we            ,  //118:118
//                         dest             ,  //116:112
//                         imm              ,  //111:96
//                         br_src1          ,  //95 :64
//                         br_src2          ,  //63 :32
//                         ds_pc               //31 :0
// };


// assign complex_es_bus = {
//                         //-------exception---------
//                         overflow_en      ,  //185
//                         ds_bd            ,  //184
//                         eret_flush       ,  //183
//                         mtc0_we          ,  //182
//                         cp0_addr         ,  //181:174
//                         ds_res_from_cp0  ,  //173
//                         ds_ex            ,  //172
//                         ds_excode        ,  //171:167
//                         //-------exception---------
//                         l_is_lwl         ,  //166
//                         l_is_lwr         ,  //165
//                         l_is_lw          ,  //164
//                         l_is_lb          ,  //163
//                         l_is_lbu         ,  //162
//                         l_is_lh          ,  //161
//                         l_is_lhu         ,  //160
//                         s_is_swl         ,  //159
//                         s_is_swr         ,  //158
//                         s_is_sw          ,  //157
//                         s_is_sb          ,  //156
//                         s_is_sh          ,  //155:
//                         hi_wen           ,  //154:154
//                         lo_wen           ,  //153:153
//                         res_is_hi        ,  //152:152
//                         res_is_lo        ,  //151:151
//                         src2_is_0imm     ,  //150:150
//                         ds_rs2           ,  //149:145
//                         ds_rs1           ,  //144:140
//                         alu_op           ,  //139:124
//                         load_op          ,  //123:123
//                         src1_is_sa       ,  //122:122
//                         src1_is_pc       ,  //121:121
//                         src2_is_imm      ,  //120:120
//                         src2_is_8        ,  //119:119
//                         gr_we            ,  //118:118
//                         mem_we           ,  //117:117
//                         dest             ,  //116:112
//                         imm              ,  //111:96
//                         br_src1          ,  //95 :64
//                         br_src2          ,  //63 :32
//                         ds_pc               //31 :0
// };

//perf_count
reg [31:0] dual_issue_cnt;
reg [31:0] signle_issue_cnt;
reg [31:0] wait_cnt;
reg [31:0] real_wait_cnt;
reg [31:0] es_not_allowin_cnt;
reg [31:0] ready_but_not_go_cnt;

reg [31:0] sub0_ready_not_go_cnt;
reg [31:0] sub1_ready_sub0_not_cnt;

always@(posedge clk)begin
        if(reset)begin
                dual_issue_cnt <= 0;
                signle_issue_cnt <= 0;
        end
        else if(issue_mode == `DUAL)begin
                dual_issue_cnt <= dual_issue_cnt + 1'b1;
        end
        else if(issue_mode == `SIGNLE)begin
                signle_issue_cnt <= signle_issue_cnt + 1'b1;
        end
end

always@(posedge clk)begin
        if(reset)begin
                wait_cnt <= 0;
                es_not_allowin_cnt <= 0;
        end
        else if((fifo_to_ds_valid_0 || fifo_to_ds_valid_1) && issue_mode == `NULL)begin
                wait_cnt <= wait_cnt + 1'b1;
                if(!es_allowin)
                        es_not_allowin_cnt <= es_not_allowin_cnt + 1'b1;
        end
end

always@(posedge clk)begin
        if(reset)begin
                real_wait_cnt <= 0;
        end
        else if(fifo_to_ds_valid_0 && issue_mode == `NULL)begin
                real_wait_cnt <= real_wait_cnt + 1'b1;
        end
end


always@(posedge clk)begin
        if(reset)begin
                ready_but_not_go_cnt <= 0;
        end
        else if((sub_0_ready_go && fifo_to_ds_valid_0 && sub_1_ready_go && fifo_to_ds_valid_1) && issue_mode == `NULL)begin
                ready_but_not_go_cnt <= ready_but_not_go_cnt + 1'b1;
        end
end

always@(posedge clk)begin
        if(reset)begin
                sub1_ready_sub0_not_cnt <= 0;
        end
        else if((!sub_0_ready_go && sub_1_ready_go && fifo_to_ds_valid_0 && fifo_to_ds_valid_1) && issue_mode == `NULL)begin
                sub1_ready_sub0_not_cnt <= sub1_ready_sub0_not_cnt + 1'b1;
        end
end

always@(posedge clk)begin
        if(reset)begin
                sub0_ready_not_go_cnt <= 0;
        end
        else if(sub_0_ready_go && fifo_to_ds_valid_0 && issue_mode == `NULL)begin
                sub0_ready_not_go_cnt <= sub0_ready_not_go_cnt + 1'b1;
        end
end
        

endmodule
