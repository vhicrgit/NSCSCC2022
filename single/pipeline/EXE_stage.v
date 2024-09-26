`include "../mycpu.h"

module exe_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          m1s_allowin    ,
    output                         es_allowin    ,
    //from ds
    input                          ds_to_es_valid,
    input  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to m1s
    output                         es_to_m1s_valid,
    output [`ES_TO_M1S_BUS_WD -1:0] es_to_m1s_bus ,
    //from m1s
    input                           m1s_ex,
    //from m2s
    input                          ex_taken      ,
    //to forwarding
    output [4                  :0] es_rs1        ,
    output [4                  :0] es_rs2        ,
    //from forwarding
    input  [31:                 0] m1s_alu_result,
    input  [31:                 0] m2s_alu_result,
    input  [31:                 0] ws_final_result,      
    input  [4                 :0]  m1s_rd       ,
    input  [4                 :0]  m2s_rd       ,
    input  [4                 :0]  ws_rd        ,
    input                          m1s_reg_write,
    input                          m2s_reg_write,
    input                          ws_reg_write ,
    input                          m1s_valid    ,
    input                          m2s_valid    ,
    input                          ws_valid     ,
    input [3                   :0] ws_rf_wen    ,
    output [4                  :0] es_rd,
    //from hazard
    input                          es_flush,
    input                          exc_flush,
    input                          m1s_flush,
    input                          es_stall,
    //to hazard
    output                         es_res_from_cp0,
    output                         es_res_from_mem ,
    output                         es_reg_write,
    output reg                     es_valid,
    output                         div_block,
    //br_bus
    output [`BR_BUS_WD       -1:0] es_br_bus        ,
    output [31                 :0] es_pc,
    output                         es_b_or_j,
    
    input                           ws_ready_go,
    input                           ws_allowin ,

    //address space
    input                           config_kseg0

   
);


wire        es_ready_go   ;

reg  [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus_r;
wire [15:0] es_alu_op       ;
wire        es_load_op      ;
wire        es_src1_is_sa   ;  
wire        es_src1_is_pc   ;
wire        es_src2_is_imm  ;
wire        es_src2_is_0imm ; 
wire        es_src2_is_8    ;
wire        es_gr_we        ;
wire        es_mem_we       ;
wire [ 4:0] es_dest         ;
wire [15:0] es_imm          ;
wire [31:0] es_rs_value     ;
wire [31:0] es_rt_value     ;
wire        es_res_is_hi    ;
wire        es_res_is_lo    ;
wire        es_hi_wen       ;
wire        es_lo_wen       ;        
wire        es_l_is_lw      ;
wire        es_l_is_lb      ;
wire        es_l_is_lbu     ;
wire        es_l_is_lh      ;
wire        es_l_is_lhu     ;
wire        es_l_is_lwl     ;
wire        es_l_is_lwr     ;
wire        es_s_is_sw      ;
wire        es_s_is_sb      ;
wire        es_s_is_sh      ;
wire        es_s_is_swl     ;
wire        es_s_is_swr     ;
wire [3:0]  sb_wen          ;
wire [3:0]  sh_wen          ;
wire [3:0]  swl_wen         ;
wire [3:0]  swr_wen         ;
wire [1:0]  low_addr        ;
wire [3:0]  es_rf_wen       ;
wire [3:0]  lwl_wen         ;
wire [3:0]  lwr_wen         ;
wire [31:0] swl_wdata       ;
wire [31:0] swr_wdata       ;

//exception
wire        ds_ex           ;
wire [4:0]  ds_excode       ;
wire        ds_eret_flush   ;
wire        es_overflow_en  ;
wire        es_overflow     ;
wire [ 4:0] es_excode       ;
wire [31:0] es_badvaddr     ;
// wire [31:0] es_pc           ;
wire [7:0]  es_cp0_addr     ;
wire [31:0] es_cp0_wdata    ;
wire        es_mtc0_we      ;
wire        es_bd           ;
wire        es_ex           ;
wire        es_eret_flush   ;

// data sram interface
wire            es_data_sram_req    ;
wire            es_data_sram_wr     ;
wire   [1:0]    es_data_sram_size   ;
wire   [3:0]    es_data_sram_wstrb  ;
wire   [31:0]   es_data_sram_addr   ;
wire   [31:0]   es_data_sram_wdata  ;
wire            es_data_sram_addr_ok;
wire            es_data_uncache     ;




reg   [31:0] ws_final_result_old;
reg          ws_final_result_stall;

wire  [31:0] ws_final_result_now;

wire  [1:0] alu_src1_fwd  ;
wire  [1:0] alu_src2_fwd  ;
wire  [3:0] alu1_fwd_wen  ;
wire  [3:0] alu2_fwd_wen  ;

wire  [1:0]  alu_src1_fwd_now;
wire  [1:0]  alu_src2_fwd_now;
wire  [3:0]  alu1_fwd_wen_now;
wire  [3:0]  alu2_fwd_wen_now;
reg   [1:0]  alu_src1_fwd_old;
reg   [1:0]  alu_src2_fwd_old;
reg   [3:0]  alu1_fwd_wen_old;
reg   [3:0]  alu2_fwd_wen_old;



assign       ws_final_result_now  = ws_final_result_stall ? ws_final_result_old : ws_final_result;
assign       alu1_fwd_wen_now     = (ws_final_result_stall) ? alu1_fwd_wen_old : alu1_fwd_wen;
assign       alu2_fwd_wen_now     = (ws_final_result_stall) ? alu2_fwd_wen_old : alu2_fwd_wen;
assign       alu_src1_fwd_now     = (ws_final_result_stall) ? alu_src1_fwd_old : alu_src1_fwd;
assign       alu_src2_fwd_now     = (ws_final_result_stall) ? alu_src2_fwd_old : alu_src2_fwd;


assign es_eret_flush = ds_eret_flush & es_valid;


//br_bus
reg [19:0] prd_err_cnt;
reg [19:0] branch_cnt;
wire [31:0] es_pd_pc;
wire [31:0] es_real_target_pc;
wire prd_err;
assign prd_err = es_b_or_j && (es_pd_pc != es_real_target_pc);
assign es_br_bus = {prd_err,es_real_target_pc};

always@(posedge clk)
begin
    if(reset)
        prd_err_cnt <= 0;
    else if(prd_err && !es_stall && !exc_flush)
        prd_err_cnt <= prd_err_cnt + 1;
end

always@(posedge clk)
begin
    if(reset)
        branch_cnt  <=0;
    else if(es_b_or_j && !es_stall && !exc_flush)
        branch_cnt <= branch_cnt + 1;
end

assign {
        es_pd_pc            ,  //250:219
        es_b_or_j           ,  //218
        es_real_target_pc   ,  //217:186
        //-------exception---------
        es_overflow_en      ,  //185
        es_bd               ,  //184
        ds_eret_flush       ,  //183
        es_mtc0_we          ,  //182
        es_cp0_addr         ,  //181:174
        es_res_from_cp0     ,  //173
        ds_ex               ,  //172
        ds_excode           ,  //171:167
        //-------exception---------
        es_l_is_lwl         ,  //166
        es_l_is_lwr         ,  //165
        es_l_is_lw          ,  //164
        es_l_is_lb          ,  //163
        es_l_is_lbu         ,  //162
        es_l_is_lh          ,  //161
        es_l_is_lhu         ,  //160
        es_s_is_swl         ,  //159
        es_s_is_swr         ,  //158
        es_s_is_sw          ,  //157
        es_s_is_sb          ,  //156
        es_s_is_sh          ,  //155:
        es_hi_wen           ,  //154:154
        es_lo_wen           ,  //153:153
        es_res_is_hi        ,  //152:152
        es_res_is_lo        ,  //151:151
        es_src2_is_0imm     ,  //150:150
        es_rs2              ,  //149:145
        es_rs1              ,  //144:140
        es_alu_op           ,  //139:124
        es_load_op          ,  //123:123
        es_src1_is_sa       ,  //122:122
        es_src1_is_pc       ,  //121:121
        es_src2_is_imm      ,  //120:120
        es_src2_is_8        ,  //119:119
        es_gr_we            ,  //118:118
        es_mem_we           ,  //117:117
        es_dest             ,  //116:112
        es_imm              ,  //111:96
        es_rs_value         ,  //95 :64
        es_rt_value         ,  //63 :32
        es_pc                  //31 :0
       } = ds_to_es_bus_r;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;
wire [31:0] es_alu_final_src1   ;
wire [31:0] es_alu_final_src2   ;
wire [63:0] es_alu_result ;
wire [31:0] hi_res;
wire [31:0] lo_res;
wire [31:0] es_final_result;

wire es_load_op_final;

assign es_final_result = es_res_is_hi ? hi_res
                       : es_res_is_lo ? lo_res
                       : es_alu_result[31:0];


assign es_rd            = es_dest;
assign es_reg_write     = es_gr_we;
assign es_res_from_mem  = es_load_op;
assign es_load_op_final = es_load_op && !es_ex && !ex_taken; 


assign es_ready_go     = !es_valid || !es_stall;
assign es_allowin      = !es_valid || es_ready_go && m1s_allowin;
assign es_to_m1s_valid =  es_valid && es_ready_go && !m1s_flush;

always @(posedge clk) begin
    if (reset) begin
        es_valid <= 1'b0;
    end
    else if (es_allowin) begin
        es_valid <= ds_to_es_valid;
    end

    if (ds_to_es_valid && es_allowin) begin
        ds_to_es_bus_r <= ds_to_es_bus;
    end
    else if(es_allowin)begin
        ds_to_es_bus_r <= 0;
    end
end

//======================= forwarding ===========================
assign alu1_fwd_wen = (alu_src1_fwd == `WB) ? ws_rf_wen : 4'b1111;
assign alu2_fwd_wen = (alu_src2_fwd == `WB) ? ws_rf_wen : 4'b1111;


assign alu_src1_fwd = !(es_valid) ? 0
                     : ((es_rs1 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S
                     : ((es_rs1 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S
                     : ((es_rs1 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB 
                     : 0;

assign alu_src2_fwd = !(es_valid) ? 0
                     : ((es_rs2 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S 
                     : ((es_rs2 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S 
                     : ((es_rs2 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB
                     : 0;


assign es_alu_final_src1 = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                                         es_src1_is_pc  ? es_pc[31:0] :
                                         es_alu_src1;
assign es_alu_final_src2 = es_src2_is_imm ? {{16{es_imm[15]}}, es_imm[15:0]} : 
                                         es_src2_is_0imm ? {{16{1'b0}}, es_imm[15:0]} :
                                         es_src2_is_8   ? 32'd8 :
                                         es_alu_src2;

assign es_alu_src1[7:0] = alu1_fwd_wen_now[0] ? { {32{(alu_src1_fwd_now == 2'd0)}} & es_rs_value[7:0]
                                            | {32{(alu_src1_fwd_now == `M1S)}} & m1s_alu_result[7:0]
                                            | {32{(alu_src1_fwd_now == `M2S)}} & m2s_alu_result[7:0]
                                            | {32{(alu_src1_fwd_now == `WB)}} & ws_final_result_now[7:0]}
                                            : es_rs_value[7:0];
assign es_alu_src1[15:8] = alu1_fwd_wen_now[1] ? { {32{(alu_src1_fwd_now == 2'd0)}} & es_rs_value[15:8]
                                            |  {32{(alu_src1_fwd_now == `M1S)}} & m1s_alu_result[15:8]
                                            |  {32{(alu_src1_fwd_now == `M2S)}} & m2s_alu_result[15:8]
                                            |  {32{(alu_src1_fwd_now == `WB)}} & ws_final_result_now[15:8]}
                                            : es_rs_value[15:8];
assign es_alu_src1[23:16] = alu1_fwd_wen_now[2] ? { {32{(alu_src1_fwd_now == 2'd0)}} & es_rs_value[23:16]
                                            |   {32{(alu_src1_fwd_now == `M1S)}} & m1s_alu_result[23:16]
                                            |   {32{(alu_src1_fwd_now == `M2S)}} & m2s_alu_result[23:16]
                                            |   {32{(alu_src1_fwd_now == `WB)}} & ws_final_result_now[23:16]}
                                            : es_rs_value[23:16];
assign es_alu_src1[31:24] = alu1_fwd_wen_now[3] ? { {32{(alu_src1_fwd_now == 2'd0)}} & es_rs_value[31:24]
                                            |   {32{(alu_src1_fwd_now == `M1S)}} & m1s_alu_result[31:24]
                                            |   {32{(alu_src1_fwd_now == `M2S)}} & m2s_alu_result[31:24]
                                            |   {32{(alu_src1_fwd_now == `WB)}} & ws_final_result_now[31:24]}
                                            : es_rs_value[31:24];
                                                                                                           
assign es_alu_src2[7:0] = alu2_fwd_wen_now[0] ? { {32{(alu_src2_fwd_now == 2'd0)}} & es_rt_value[7:0]
                                            | {32{(alu_src2_fwd_now == `M1S)}} & m1s_alu_result[7:0]
                                            | {32{(alu_src2_fwd_now == `M2S)}} & m2s_alu_result[7:0]
                                            | {32{(alu_src2_fwd_now == `WB)}} & ws_final_result_now[7:0]}
                                            : es_rt_value[7:0];
assign es_alu_src2[15:8] = alu2_fwd_wen_now[1] ? { {32{(alu_src2_fwd_now == 2'd0)}} & es_rt_value[15:8]
                                            |  {32{(alu_src2_fwd_now == `M1S)}} & m1s_alu_result[15:8]
                                            |  {32{(alu_src2_fwd_now == `M2S)}} & m2s_alu_result[15:8]
                                            |  {32{(alu_src2_fwd_now == `WB)}} & ws_final_result_now[15:8]}
                                            : es_rt_value[15:8];
assign es_alu_src2[23:16] = alu2_fwd_wen_now[2] ? { {32{(alu_src2_fwd_now == 2'd0)}} & es_rt_value[23:16]
                                            |   {32{(alu_src2_fwd_now == `M1S)}} & m1s_alu_result[23:16]
                                            |   {32{(alu_src2_fwd_now == `M2S)}} & m2s_alu_result[23:16]
                                            |   {32{(alu_src2_fwd_now == `WB)}} & ws_final_result_now[23:16]}
                                            : es_rt_value[23:16];
assign es_alu_src2[31:24] = alu2_fwd_wen_now[3] ? { {32{(alu_src2_fwd_now == 2'd0)}} & es_rt_value[31:24]
                                            |   {32{(alu_src2_fwd_now == `M1S)}} & m1s_alu_result[31:24]
                                            |   {32{(alu_src2_fwd_now == `M2S)}} & m2s_alu_result[31:24]
                                            |   {32{(alu_src2_fwd_now == `WB)}} & ws_final_result_now[31:24]}
                                            : es_rt_value[31:24];    
        


assign sb_wen =  {4{es_alu_result[1:0] == 2'b00}} & 4'b0001
               | {4{es_alu_result[1:0] == 2'b01}} & 4'b0010
               | {4{es_alu_result[1:0] == 2'b10}} & 4'b0100
               | {4{es_alu_result[1:0] == 2'b11}} & 4'b1000;
assign sh_wen =  {4{es_alu_result[1:0] == 2'b00}} & 4'b0011 
               | {4{es_alu_result[1:0] == 2'b10}} & 4'b1100;               
assign swl_wen = {4{es_alu_result[1:0] == 2'b00}} & 4'b0001
               | {4{es_alu_result[1:0] == 2'b01}} & 4'b0011
               | {4{es_alu_result[1:0] == 2'b10}} & 4'b0111
               | {4{es_alu_result[1:0] == 2'b11}} & 4'b1111;               
assign swr_wen = {4{es_alu_result[1:0] == 2'b00}} & 4'b1111 
               | {4{es_alu_result[1:0] == 2'b01}} & 4'b1110 
               | {4{es_alu_result[1:0] == 2'b10}} & 4'b1100 
               | {4{es_alu_result[1:0] == 2'b11}} & 4'b1000;             
assign swl_wdata = {32{es_alu_result[1:0] == 2'b00}} & {24'b0,es_alu_src2[31:24]}
                 | {32{es_alu_result[1:0] == 2'b01}} & {16'b0,es_alu_src2[31:16]}
                 | {32{es_alu_result[1:0] == 2'b10}} & {8'b0,es_alu_src2[31:8]}
                 | {32{es_alu_result[1:0] == 2'b11}} & es_alu_src2;        
assign swr_wdata = {32{es_alu_result[1:0] == 2'b00}} & es_alu_src2
                 | {32{es_alu_result[1:0] == 2'b01}} & {es_alu_src2[23:0],8'b0}
                 | {32{es_alu_result[1:0] == 2'b10}} & {es_alu_src2[15:0],16'b0}
                 | {32{es_alu_result[1:0] == 2'b11}} & {es_alu_src2[7:0],24'b0};        

//in some cases,we don't need to caculate
//use 'cancel' signal to disable mul/div
wire cancel;
wire mul_data_ok;
assign cancel = exc_flush || ds_ex || m1s_ex || !es_valid;
//============mul & div=============
wire [63:0] multi_result;
wire [63:0] divi_result;
wire m_axis_dout_tvalid;
reg [31:0] HI;
reg [31:0] LO;
wire op_mul;
wire op_mulu;
wire op_div;
wire op_divu;
assign op_mul  = es_alu_op[12];
assign op_mulu = es_alu_op[13];
assign op_div  = es_alu_op[14];
assign op_divu = es_alu_op[15];

assign hi_res = HI;
assign lo_res = LO;

always@(posedge clk)
begin
    if(!cancel)
    begin
        if(m_axis_dout_tvalid)
            {LO,HI} = es_alu_result;
        else if(mul_data_ok)
            {HI,LO} = es_alu_result;
        else if (es_hi_wen)
            HI = es_alu_src1;
        else if (es_lo_wen)
            LO = es_alu_src1;
    end
end
               
alu u_alu(
    .clk                (clk                ),
    .reset              (reset              ),
    .alu_op             (es_alu_op          ),
    .alu_src1           (es_alu_final_src1  ),
    .alu_src2           (es_alu_final_src2  ),
    .alu_result         (es_alu_result      ),
    //overflow
    .overflow_en        (es_overflow_en     ),
    .overflow           (es_overflow        ),
    //mul & div
    .m_axis_dout_tvalid (m_axis_dout_tvalid ),
    .div_block          (div_block          ),
    //exception
    .cancel             (cancel             ),
    //mul
    .mul_data_ok        (mul_data_ok        ),
    .m1s_allowin        (m1s_allowin        )
    );

//=============address space=============
wire kuseg;
wire kseg0;
wire kseg1;
wire kseg2;
wire kseg3;

// assign kuseg = (es_alu_result[31:28] < 4'h8);
assign kseg0 = (es_alu_result[31:28] >= 4'h8) && (es_alu_result[31:28] < 4'ha);
assign kseg1 = (es_alu_result[31:28] >= 4'ha) && (es_alu_result[31:28] < 4'hc);
// assign kseg2 = (es_alu_result[31:28] >= 4'hc) && (es_alu_result[31:28] < 4'he);
// assign kseg3 = (es_alu_result[31:28] >= 4'he);


assign es_data_uncache = kseg0 && config_kseg0 || kseg1;

assign low_addr        = es_alu_result[1:0];

assign es_data_sram_req   = (es_load_op_final | es_mem_we);

assign es_data_sram_wstrb = {4{es_mem_we & es_valid & !es_ex}} & (    {4{es_s_is_sb}} & sb_wen
                                                                |  {4{es_s_is_sh}} & sh_wen
                                                                |  {4{es_s_is_sw}} & 4'b1111
                                                                |  {4{es_s_is_swl}}& swl_wen
                                                                |  {4{es_s_is_swr}}& swr_wen
                                                               );
assign es_data_sram_wr    = es_mem_we && !es_ex && !ex_taken;

assign es_data_sram_addr  = (kseg0 || kseg1) ?  {3'd0,es_alu_result[28:0]} : es_alu_result[31:0]; 

assign es_data_sram_wdata = {32{es_s_is_sb}}  & {4{es_alu_src2[7:0]}} 
                       | {32{es_s_is_sh}}  & {2{es_alu_src2[15:0]}}
                       | {32{es_s_is_sw}}  & es_alu_src2 
                       | {32{es_s_is_swl}} & swl_wdata
                       | {32{es_s_is_swr}} & swr_wdata;
                        
                        

assign es_data_sram_size  = {2{es_alu_result[1:0] == 2'b00}} & {2{es_l_is_lw | es_s_is_sw}}& 2'b10
                        |{2{es_l_is_lh | es_s_is_sh | es_l_is_lhu}}& 2'b01
                        |{2{es_l_is_lb | es_s_is_sb | es_l_is_lbu}}& 2'b00
                        |{2{es_alu_result[1:0] == 2'b00}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b00
                        |{2{es_alu_result[1:0] == 2'b01}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b01
                        |{2{es_alu_result[1:0] == 2'b10}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b10
                        |{2{es_alu_result[1:0] == 2'b11}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b10
                        |{2{es_alu_result[1:0] == 2'b00}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b10
                        |{2{es_alu_result[1:0] == 2'b01}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b10
                        |{2{es_alu_result[1:0] == 2'b10}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b01
                        |{2{es_alu_result[1:0] == 2'b11}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b00;


assign lwl_wen = {4{es_alu_result[1:0] == 2'b00}} & 4'b1000
               | {4{es_alu_result[1:0] == 2'b01}} & 4'b1100
               | {4{es_alu_result[1:0] == 2'b10}} & 4'b1110
               | {4{es_alu_result[1:0] == 2'b11}} & 4'b1111;
               
assign lwr_wen = {4{es_alu_result[1:0] == 2'b00}} & 4'b1111
               | {4{es_alu_result[1:0] == 2'b01}} & 4'b0111
               | {4{es_alu_result[1:0] == 2'b10}} & 4'b0011
               | {4{es_alu_result[1:0] == 2'b11}} & 4'b0001;

assign es_rf_wen = {4{es_gr_we && ! es_l_is_lwl && !es_l_is_lwr}} & 4'b1111
                 | {4{es_l_is_lwl}} & lwl_wen
                 | {4{es_l_is_lwr}} & lwr_wen;





assign es_to_m1s_bus = {
                        // data sram interface
                        es_data_sram_wr     , //238
                        es_data_sram_size   , //237:236
                        es_data_sram_wstrb  , //235:232
                        es_data_sram_addr   , //231:200
                        es_data_sram_wdata  , //199:168
                        es_data_uncache     , //167
                        //------exception-------
                        es_cp0_addr    ,  //166:159
                        es_bd          ,  //158
                        es_eret_flush  ,  //157
                        es_mtc0_we     ,  //156
                        es_res_from_cp0,  //155
                        es_cp0_wdata   ,  //154:123
                        es_badvaddr    ,  //122:91
                        es_excode      ,  //90:86
                        es_ex          ,  //85
                        //------exception-------
                        es_data_sram_req  ,  //84
                        es_l_is_lwl    ,  //83
                        es_l_is_lwr    ,  //82
                        es_rf_wen      ,  //81:78
                        low_addr       ,  //77:76
                        es_l_is_lw     ,  //75
                        es_l_is_lb     ,  //74
                        es_l_is_lbu    ,  //73
                        es_l_is_lh     ,  //72
                        es_l_is_lhu    ,  //71
                        es_res_from_mem,  //70:70
                        es_gr_we       ,  //69:69
                        es_dest        ,  //68:64
                        es_final_result,  //63:32
                        es_pc             //31:0
                    };



wire lw_addr_wrong;
wire lh_addr_wrong;
wire sw_addr_wrong;
wire sh_addr_wrong;
assign lw_addr_wrong = (es_l_is_lw & (low_addr != 2'b00));
assign lh_addr_wrong = ((es_l_is_lh | es_l_is_lhu) & (low_addr[0] != 1'b00));
assign sw_addr_wrong = (es_s_is_sw & (low_addr != 2'b00));
assign sh_addr_wrong = (es_s_is_sh & (low_addr[0] != 1'b00));

//cp0
assign es_ex = (ds_ex | lw_addr_wrong | lh_addr_wrong | sw_addr_wrong | sh_addr_wrong | es_overflow);
assign es_excode =  (ds_ex && ds_excode == `EXC_INT)    ? `EXC_INT
                 :  ds_ex                               ? ds_excode
                 :  (lw_addr_wrong | lh_addr_wrong)     ? `EXC_ADEL
                 :  (sw_addr_wrong | sh_addr_wrong)     ? `EXC_ADES
                 :  es_overflow                         ? `EXC_OV
                 :  5'h0;
assign es_cp0_wdata = es_alu_src2;
assign es_badvaddr = (ds_ex && es_excode == `EXC_ADEL) ? es_pc : es_alu_result[31:0];


//some signals need save and record
/*
forward signals valid ,but mem stage not allowin (data sram not achieve data),forward signals need save before 
the stages generate the signals ready go
*/
// always@(posedge clk)begin
//     if(reset)begin
//         ms_alu_result_stall <= 1'b0;
//         ms_alu_result_old   <= 0;
//     end
//     else if(es_to_ms_valid && ms_allowin)begin
//         ms_alu_result_stall <= 1'b0;
//     end 
//     else if((alu_src2_fwd == 2'd1 || alu_src1_fwd == 2'd1) && (ms_ready_go && ws_allowin) && !es_ready_go && es_valid && !es_stall)begin
//           ms_alu_result_stall <= 1'b1;
//           ms_alu_result_old   <= ms_alu_result;
//     end    
// end

always@(posedge clk)begin
    if(reset || es_stall)begin
        ws_final_result_stall <= 1'b0;
        ws_final_result_old   <= 0;
    end
    else if(es_to_m1s_valid && m1s_allowin)begin
        ws_final_result_stall <= 1'b0;
    end 
    else if((alu_src2_fwd == `WB || alu_src1_fwd == `WB) && ws_ready_go && !(es_ready_go && m1s_allowin) && es_valid && !es_stall)begin
        ws_final_result_stall <= 1'b1;
        ws_final_result_old   <= ws_final_result;
    end       
end

always@(posedge clk)begin
    if(reset || es_stall)begin
        alu1_fwd_wen_old      <= 0;
        alu2_fwd_wen_old      <= 0;
        alu_src1_fwd_old      <= 0;
        alu_src2_fwd_old      <= 0;
    end
    else if((alu_src2_fwd == `WB || alu_src1_fwd == `WB) && (ws_ready_go && !(es_ready_go && m1s_allowin) && es_valid && !es_stall))begin
        alu1_fwd_wen_old      <= alu1_fwd_wen;
        alu2_fwd_wen_old      <= alu2_fwd_wen;
        alu_src1_fwd_old      <= alu_src1_fwd;
        alu_src2_fwd_old      <= alu_src2_fwd;
    end
end


endmodule
