`include "../mycpu.h"

module ex_sub0(
    input                               clk,
    input                               reset,
    input                               es_valid,
    input                               ex_taken,
    input                               exc_flush,
    input                               m1s_ex,
    input                               m1s_allowin,
    input                               config_kseg0,
    input  [`COMPLEX_ES_BUS_WD-1 :0]    ds_to_es_bus,
    output [`ES_TO_M1S_BUS0_WD -1:0]    es_to_m1s_bus,
    output [`ES_FWD_BUS-1 :0]           es_fwd_bus,
    output                              es_res_from_cp0,
    output                              es_res_from_mem,
    output                              div_block          
);

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

wire        es_reg_write    ;
wire [4:0]  es_rd           ;

//exception
wire        ds_ex           ;
wire [4:0]  ds_excode       ;
wire        ds_eret_flush   ;
wire        es_overflow_en  ;
wire        es_overflow     ;
wire [ 4:0] es_excode       ;
wire [31:0] es_badvaddr     ;
wire [31:0] es_pc;
wire [7:0]  es_cp0_addr     ;
wire [31:0] es_cp0_wdata    ;
wire        es_mtc0_we      ;
wire        es_bd           ;
wire        es_ex           ;
wire        es_eret_flush   ;

wire [4:0]  es_rs1;
wire [4:0]  es_rs2;     

// data sram interface
wire            es_data_sram_req    ;
wire            es_data_sram_wr     ;
wire   [1:0]    es_data_sram_size   ;
wire   [3:0]    es_data_sram_wstrb  ;
wire   [31:0]   es_data_sram_addr   ;
wire   [31:0]   es_data_sram_wdata  ;
wire            es_data_sram_addr_ok;
wire            es_data_uncache     ;

wire [31:0] es_pd_pc;
wire [31:0] es_real_target_pc;

wire [31:0] es_alu_src1   ;
wire [31:0] es_alu_src2   ;

wire [63:0] es_result ;
wire [31:0] hi_res;
wire [31:0] lo_res;
wire [31:0] es_final_result;
wire        es_load_op_final;

wire        es_first;

// assign {
//         es_pd_pc            ,  //250:219
//         es_b_or_j           ,  //218
//         es_real_target_pc   ,  //217:186
//         //-------exception---------
//         es_overflow_en      ,  //185
//         es_bd               ,  //184
//         ds_eret_flush       ,  //183
//         es_mtc0_we          ,  //182
//         es_cp0_addr         ,  //181:174
//         es_res_from_cp0     ,  //173
//         ds_ex               ,  //172
//         ds_excode           ,  //171:167
//         //-------exception---------
//         es_l_is_lwl         ,  //166
//         es_l_is_lwr         ,  //165
//         es_l_is_lw          ,  //164
//         es_l_is_lb          ,  //163
//         es_l_is_lbu         ,  //162
//         es_l_is_lh          ,  //161
//         es_l_is_lhu         ,  //160
//         es_s_is_swl         ,  //159
//         es_s_is_swr         ,  //158
//         es_s_is_sw          ,  //157
//         es_s_is_sb          ,  //156
//         es_s_is_sh          ,  //155:
//         es_hi_wen           ,  //154:154
//         es_lo_wen           ,  //153:153
//         es_res_is_hi        ,  //152:152
//         es_res_is_lo        ,  //151:151
//         es_src2_is_0imm     ,  //150:150
//         es_rs2              ,  //149:145
//         es_rs1              ,  //144:140
//         es_alu_op           ,  //139:124
//         es_load_op          ,  //123:123
//         es_src1_is_sa       ,  //122:122
//         es_src1_is_pc       ,  //121:121
//         es_src2_is_imm      ,  //120:120
//         es_src2_is_8        ,  //119:119
//         es_gr_we            ,  //118:118
//         es_mem_we           ,  //117:117
//         es_dest             ,  //116:112
//         es_imm              ,  //111:96
//         es_rs_value         ,  //95 :64
//         es_rt_value         ,  //63 :32
//         es_pc                  //31 :0
//        } = ds_to_es_bus;

assign {
        es_first            ,  //186
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
        es_s_is_sh          ,  //155
        es_hi_wen           ,  //154
        es_lo_wen           ,  //153
        es_res_is_hi        ,  //152
        es_res_is_lo        ,  //151
        es_src2_is_0imm     ,  //150
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
       } = ds_to_es_bus;






assign      es_rd            = es_dest;
assign      es_reg_write     = es_gr_we;
assign      es_res_from_mem  = es_load_op;
assign      es_load_op_final = es_load_op && !es_ex && !ex_taken; 

assign      es_eret_flush = ds_eret_flush & es_valid;




//============================== exception ===============================================
       




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
assign es_badvaddr = (ds_ex && es_excode == `EXC_ADEL) ? es_pc : es_result[31:0];


//========================= alu op &&  mul op && div op=======================================

// alu result
wire [31:0] es_alu_result;

wire [63:0] es_mul_result;
wire [63:0] es_div_result;

assign      es_alu_src1  = es_src1_is_sa  ? {27'b0, es_imm[10:6]} : 
                           es_src1_is_pc  ? es_pc[31:0] :
                           es_rs_value;

assign      es_alu_src2  = es_src2_is_imm ? {{16{es_imm[15]}}, es_imm[15:0]} : 
                          es_src2_is_0imm ? {{16{1'b0}}, es_imm[15:0]} :
                          es_src2_is_8    ? 32'd8 :
                          es_rt_value;

alu u_alu(
    .alu_op             (es_alu_op          ),
    .alu_src1           (es_alu_src1        ),
    .alu_src2           (es_alu_src2        ),
    .alu_result         (es_alu_result      ),
    //overflow
    .overflow_en        (es_overflow_en     ),
    .overflow           (es_overflow        )
    );                                

// mul && div result

//in some cases,we don't need to caculate
//use 'cancel' signal to disable mul/div
wire        cancel;
wire        mul_data_ok;
assign      cancel = exc_flush || ds_ex || m1s_ex || !es_valid;

wire [63:0] multi_result;
wire [63:0] divi_result;
wire        m_axis_dout_tvalid;
reg  [31:0] HI;
reg  [31:0] LO;
wire        op_mul;
wire        op_mulu;
wire        op_div;
wire        op_divu;
assign      op_mul  = es_alu_op[12];
assign      op_mulu = es_alu_op[13];
assign      op_div  = es_alu_op[14];
assign      op_divu = es_alu_op[15];

assign      hi_res = HI;
assign      lo_res = LO;

always@(posedge clk)
begin
    if(!cancel)
    begin
        if(m_axis_dout_tvalid)
            {LO,HI} = es_result;
        else if(mul_data_ok)
            {HI,LO} = es_result;
        else if (es_hi_wen)
            HI = es_alu_src1;
        else if (es_lo_wen)
            LO = es_alu_src1;
    end
end

wire        mul_block;
wire [32:0] extd_alu_src1;
wire [32:0] extd_alu_src2;
reg  [3:0]  mul_cnt;
wire [65:0] mul_result_raw;

assign extd_alu_src1= {33{op_mul | op_div}} & {es_alu_src1[31],es_alu_src1} | {33{op_mulu | op_divu}} & {1'b0,es_alu_src1};
assign extd_alu_src2= {33{op_mul | op_div}} & {es_alu_src2[31],es_alu_src2} | {33{op_mulu | op_divu}} & {1'b0,es_alu_src2};
assign mul_block    = (op_mul || op_mulu) && (mul_cnt < `MUL_CNT);
assign mul_data_ok  = (op_mul || op_mulu) && (mul_cnt == `MUL_CNT);
assign es_mul_result  = mul_result_raw[63:0];

always@(posedge clk)
begin
    if(reset)
      mul_cnt <= 0;
    else if(mul_cnt >= `MUL_CNT && m1s_allowin)
      mul_cnt <= 0;
    else if((op_mul || op_mulu) && (mul_cnt < `MUL_CNT))
      mul_cnt <= mul_cnt + 1;    
end

multiplier_signed multiplier_signed(
  .CLK    (clk),
  .A      ($signed(extd_alu_src1)),
  .B      ($signed(extd_alu_src2)),
  .P      (mul_result_raw)
);

reg [32:0] dividend;
reg [32:0] divisor;

wire [32:0] s_axis_divisor_tdata;
wire s_axis_divisor_tready;
wire us_axis_divisor_tready;
wire us_axis_divisor_tvalid;
wire ss_axis_divisor_tready;
wire ss_axis_divisor_tvalid;

wire [32:0] s_axis_dividend_tdata;
wire s_axis_dividend_tready;
wire us_axis_dividend_tready;
wire us_axis_dividend_tvalid;
wire ss_axis_dividend_tready;
wire ss_axis_dividend_tvalid;

// wire [63:0] um_axis_dout_tdata;
wire [79:0] sm_axis_dout_tdata;
wire [31:0] div_s;
wire [31:0] div_r;
// wire um_axis_dout_tvalid;
wire sm_axis_dout_tvalid;

reg [1:0] state;
reg [1:0] next_state;
parameter still = 0;
parameter send = 1;
parameter compute = 2;
parameter s3 = 3;

assign s_axis_divisor_tready  = (ss_axis_divisor_tready & (op_div | op_divu));
assign s_axis_dividend_tready = (ss_axis_dividend_tready & (op_div | op_divu));
assign m_axis_dout_tvalid     = (sm_axis_dout_tvalid & (op_div | op_divu));

assign ss_axis_dividend_tvalid  = (op_div | op_divu) & (state == still | state == send);
assign ss_axis_divisor_tvalid   = (op_div | op_divu) & (state == still | state == send);

assign s_axis_dividend_tdata = (state == still) ? extd_alu_src1 : dividend;
assign s_axis_divisor_tdata  = (state == still) ? extd_alu_src2 : divisor;
assign div_s = sm_axis_dout_tdata[71:40];
assign div_r = sm_axis_dout_tdata[31:0];

assign div_block = (next_state != still) || mul_block;

always@(posedge clk)
begin
  if(reset)
    state <= still;
  else
    state <= next_state;
end

always@(posedge clk)
begin
    if(reset)
        begin
            dividend = 33'b0;
            divisor = 33'b0;
        end
    else if(state == still & next_state == send)
        begin
            dividend = extd_alu_src1;
            divisor = extd_alu_src2;
        end
end

always@*
begin
  case(state)
  still:
    begin
      if(op_div | op_divu) next_state = send;
      else                 next_state = still;
    end
  
  send:
    begin
      if(s_axis_divisor_tready & s_axis_divisor_tready) next_state = compute;
      else next_state = send;
    end
  
  compute:
    begin
      if(m_axis_dout_tvalid) next_state = still;
      else next_state = compute;
    end
  
  default: next_state = still;
  endcase
end

divider_signed divider_signed(
  .aclk                    (clk),
  .s_axis_divisor_tdata    (s_axis_divisor_tdata),
  .s_axis_divisor_tready   (ss_axis_divisor_tready),
  .s_axis_divisor_tvalid   (ss_axis_divisor_tvalid),

  .s_axis_dividend_tdata    (s_axis_dividend_tdata),
  .s_axis_dividend_tready   (ss_axis_dividend_tready),
  .s_axis_dividend_tvalid   (ss_axis_dividend_tvalid),

  .m_axis_dout_tdata    (sm_axis_dout_tdata),
  .m_axis_dout_tvalid   (sm_axis_dout_tvalid)
);

assign es_div_result  = {div_s,div_r};




// final result
assign      op_alu    = | es_alu_op[11:0];

assign      es_result = ({64{op_mul|op_mulu}} & es_mul_result) | 
                        ({64{op_div|op_divu}} & es_div_result) |
                        ({64{op_alu}} & es_alu_result );

assign      es_final_result = es_res_is_hi ? hi_res
                            : es_res_is_lo ? lo_res
                            : es_result[31:0];



//========================== data sram && address space==================================

wire kuseg;
wire kseg0;
wire kseg1;
wire kseg2;
wire kseg3;

assign      sb_wen =  {4{es_result[1:0] == 2'b00}} & 4'b0001
               | {4{es_result[1:0] == 2'b01}} & 4'b0010
               | {4{es_result[1:0] == 2'b10}} & 4'b0100
               | {4{es_result[1:0] == 2'b11}} & 4'b1000;
assign      sh_wen =  {4{es_result[1:0] == 2'b00}} & 4'b0011 
               | {4{es_result[1:0] == 2'b10}} & 4'b1100;               
assign      swl_wen = {4{es_result[1:0] == 2'b00}} & 4'b0001
               | {4{es_result[1:0] == 2'b01}} & 4'b0011
               | {4{es_result[1:0] == 2'b10}} & 4'b0111
               | {4{es_result[1:0] == 2'b11}} & 4'b1111;               
assign      swr_wen = {4{es_result[1:0] == 2'b00}} & 4'b1111 
               | {4{es_result[1:0] == 2'b01}} & 4'b1110 
               | {4{es_result[1:0] == 2'b10}} & 4'b1100 
               | {4{es_result[1:0] == 2'b11}} & 4'b1000;             
assign      swl_wdata = {32{es_result[1:0] == 2'b00}} & {24'b0,es_rt_value[31:24]}
                 | {32{es_result[1:0] == 2'b01}} & {16'b0,es_rt_value[31:16]}
                 | {32{es_result[1:0] == 2'b10}} & {8'b0,es_rt_value[31:8]}
                 | {32{es_result[1:0] == 2'b11}} & es_rt_value;        
assign      swr_wdata = {32{es_result[1:0] == 2'b00}} & es_rt_value
                 | {32{es_result[1:0] == 2'b01}} & {es_rt_value[23:0],8'b0}
                 | {32{es_result[1:0] == 2'b10}} & {es_rt_value[15:0],16'b0}
                 | {32{es_result[1:0] == 2'b11}} & {es_rt_value[7:0],24'b0}; 

// assign kuseg = (es_result[31:28] < 4'h8);
assign kseg0 = (es_result[31:28] >= 4'h8) && (es_result[31:28] < 4'ha);
assign kseg1 = (es_result[31:28] >= 4'ha) && (es_result[31:28] < 4'hc);
// assign kseg2 = (es_result[31:28] >= 4'hc) && (es_result[31:28] < 4'he);
// assign kseg3 = (es_result[31:28] >= 4'he);

assign es_data_uncache = kseg0 && config_kseg0 || kseg1;

assign low_addr        = es_result[1:0];

assign es_data_sram_req   = (es_load_op_final | es_mem_we);

assign es_data_sram_wstrb = {4{es_mem_we & es_valid & !es_ex}} & (    {4{es_s_is_sb}} & sb_wen
                                                                |  {4{es_s_is_sh}} & sh_wen
                                                                |  {4{es_s_is_sw}} & 4'b1111
                                                                |  {4{es_s_is_swl}}& swl_wen
                                                                |  {4{es_s_is_swr}}& swr_wen
                                                               );
assign es_data_sram_wr    = es_mem_we && !es_ex && !ex_taken;

assign es_data_sram_addr  = (kseg0 || kseg1) ?  {3'd0,es_result[28:0]} : es_result[31:0]; 

assign es_data_sram_wdata = {32{es_s_is_sb}}  & {4{es_rt_value[7:0]}} 
                       | {32{es_s_is_sh}}  & {2{es_rt_value[15:0]}}
                       | {32{es_s_is_sw}}  & es_rt_value 
                       | {32{es_s_is_swl}} & swl_wdata
                       | {32{es_s_is_swr}} & swr_wdata;
                        
                        

assign es_data_sram_size  = {2{es_result[1:0] == 2'b00}} & {2{es_l_is_lw | es_s_is_sw}}& 2'b10
                        |{2{es_l_is_lh | es_s_is_sh | es_l_is_lhu}}& 2'b01
                        |{2{es_l_is_lb | es_s_is_sb | es_l_is_lbu}}& 2'b00
                        |{2{es_result[1:0] == 2'b00}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b00
                        |{2{es_result[1:0] == 2'b01}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b01
                        |{2{es_result[1:0] == 2'b10}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b10
                        |{2{es_result[1:0] == 2'b11}} & {2{es_l_is_lwl | es_s_is_swl}}& 2'b10
                        |{2{es_result[1:0] == 2'b00}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b10
                        |{2{es_result[1:0] == 2'b01}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b10
                        |{2{es_result[1:0] == 2'b10}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b01
                        |{2{es_result[1:0] == 2'b11}} & {2{es_l_is_lwr | es_s_is_swr}}& 2'b00;


assign lwl_wen = {4{es_result[1:0] == 2'b00}} & 4'b1000
               | {4{es_result[1:0] == 2'b01}} & 4'b1100
               | {4{es_result[1:0] == 2'b10}} & 4'b1110
               | {4{es_result[1:0] == 2'b11}} & 4'b1111;
               
assign lwr_wen = {4{es_result[1:0] == 2'b00}} & 4'b1111
               | {4{es_result[1:0] == 2'b01}} & 4'b0111
               | {4{es_result[1:0] == 2'b10}} & 4'b0011
               | {4{es_result[1:0] == 2'b11}} & 4'b0001;

assign es_rf_wen = {4{es_gr_we && ! es_l_is_lwl && !es_l_is_lwr}} & 4'b1111
                 | {4{es_l_is_lwl}} & lwl_wen
                 | {4{es_l_is_lwr}} & lwr_wen;



assign es_fwd_bus = {
                    es_valid,
                    es_reg_write,
                    es_rd,
                    es_final_result
                    };

//=================================es to m1s bus==============================================

assign es_to_m1s_bus = {
                        es_first            , //239
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


endmodule