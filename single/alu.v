`include "mycpu.h"
module alu(
  input         clk,
  input         reset,
  input  [15:0] alu_op,
  input  [31:0] alu_src1,
  input  [31:0] alu_src2,
  output [63:0] alu_result,
  //mul & div
  output        m_axis_dout_tvalid,
  output        div_block,
  //overflow
  input         overflow_en,
  output        overflow,
  //exception
  input         cancel,
  //
  output        mul_data_ok,
  input         m1s_allowin
);

wire op_add;   
wire op_sub;   
wire op_slt;   
wire op_sltu;  
wire op_and;   
wire op_nor;   
wire op_or;    
wire op_xor;   
wire op_sll;   
wire op_srl;   
wire op_sra;   
wire op_lui;   
wire op_mul;
wire op_mulu;
wire op_div;
wire op_divu;



// control code decomposition
assign op_add  = alu_op[ 0];
assign op_sub  = alu_op[ 1];
assign op_slt  = alu_op[ 2];
assign op_sltu = alu_op[ 3];
assign op_and  = alu_op[ 4];
assign op_nor  = alu_op[ 5];
assign op_or   = alu_op[ 6];
assign op_xor  = alu_op[ 7];
assign op_sll  = alu_op[ 8];
assign op_srl  = alu_op[ 9];
assign op_sra  = alu_op[10];
assign op_lui  = alu_op[11];
assign op_mul  = alu_op[12] && !cancel;
assign op_mulu = alu_op[13] && !cancel;
assign op_div  = alu_op[14] && !cancel;
assign op_divu = alu_op[15] && !cancel;


wire [31:0] add_sub_result; 
wire [31:0] slt_result; 
wire [31:0] sltu_result;
wire [31:0] and_result;
wire [31:0] nor_result;
wire [31:0] or_result;
wire [31:0] xor_result;
wire [31:0] lui_result;
wire [31:0] sll_result; 
wire [63:0] sr64_result; 
wire [31:0] sr_result; 
wire [31:0] srl_result;
wire [31:0] sra_result;
wire [63:0] mul_result;
wire [63:0] mulu_result;
wire [63:0] div_result;
wire [63:0] divu_result;

// 32-bit adder
wire [31:0] adder_a;
wire [31:0] adder_b;
wire        adder_cin;
wire [31:0] adder_result;
wire        adder_cout;

assign adder_a   = alu_src1;
assign adder_b   = (op_sub | op_slt | op_sltu) ? ~alu_src2 : alu_src2;
assign adder_cin = (op_sub | op_slt | op_sltu) ? 1'b1      : 1'b0;
assign {adder_cout, adder_result} = adder_a + adder_b + adder_cin;
assign overflow = overflow_en & ((adder_a[31] & adder_b[31] & !adder_result[31]) | (!adder_a[31] & !adder_b[31] & adder_result[31]));

// ADD, SUB result
assign add_sub_result = adder_result;

// SLT result
assign slt_result[31:1] = 31'b0;
assign slt_result[0]    = (alu_src1[31] & ~alu_src2[31])
                        | ((alu_src1[31] ~^ alu_src2[31]) & adder_result[31]);

// SLTU result
assign sltu_result[31:1] = 31'b0;
assign sltu_result[0]    = ~adder_cout;

// bitwise operation
assign and_result = alu_src1 & alu_src2;
assign or_result  = alu_src1 | alu_src2;
assign nor_result = ~or_result;
assign xor_result = alu_src1 ^ alu_src2;
assign lui_result = {alu_src2[15:0], 16'b0};

// SLL result 


// SRL, SRA result
assign sr64_result = {{32{op_sra & alu_src2[31]}}, alu_src2[31:0]} >> alu_src1[4:0];

assign sr_result   = sr64_result[30:0];
// assign srl_result = alu_src2[31:0] >> alu_src1[4:0];
// assign sra_result = $signed(alu_src2[31:0]) >>> alu_src1[4:0];

wire [31:0] shift_src;
wire [31:0] shift_result;
wire [31:0] mask;
assign shift_src = op_sll ? {
  alu_src2[0] ,alu_src2[1] ,alu_src2[2] ,alu_src2[3] ,alu_src2[4] ,alu_src2[5] ,alu_src2[6] ,alu_src2[7] ,
  alu_src2[8] ,alu_src2[9] ,alu_src2[10] ,alu_src2[11] ,alu_src2[12] ,alu_src2[13] ,alu_src2[14] ,alu_src2[15] ,
  alu_src2[16] ,alu_src2[17] ,alu_src2[18] ,alu_src2[19] ,alu_src2[20] ,alu_src2[21] ,alu_src2[22] ,alu_src2[23] ,
  alu_src2[24] ,alu_src2[25] ,alu_src2[26] ,alu_src2[27] ,alu_src2[28] ,alu_src2[29] ,alu_src2[30] ,alu_src2[31]
} : alu_src2[31:0];
assign shift_result = shift_src >> alu_src1[4:0];
assign srl_result = shift_result;
assign sll_result = {
  shift_result[0] ,shift_result[1] ,shift_result[2] ,shift_result[3] ,shift_result[4] ,shift_result[5] ,shift_result[6] ,shift_result[7] ,
  shift_result[8] ,shift_result[9] ,shift_result[10] ,shift_result[11] ,shift_result[12] ,shift_result[13] ,shift_result[14] ,shift_result[15] ,
  shift_result[16] ,shift_result[17] ,shift_result[18] ,shift_result[19] ,shift_result[20] ,shift_result[21] ,shift_result[22] ,shift_result[23] ,
  shift_result[24] ,shift_result[25] ,shift_result[26] ,shift_result[27] ,shift_result[28] ,shift_result[29] ,shift_result[30] ,shift_result[31]
};
assign mask = ~(32'hffffffff >> alu_src1[4:0]);
assign sra_result = (mask & {32{alu_src2[31]}}) | shift_result;

//MUL result
wire mul_block;
wire [32:0] extd_alu_src1;
wire [32:0] extd_alu_src2;
reg [3:0] mul_cnt;
wire [65:0] mul_result_raw;
// wire [63:0] mulu_result_raw;
// reg [63:0] mul_result_r;
// reg [63:0] mulu_result_r;

// assign mulu_result = alu_src1 * alu_src2;
// assign mul_result = $signed(alu_src1) * $signed(alu_src2);
// assign mul_result   = mul_result_raw;
// assign mulu_result  = mulu_result_raw;
assign extd_alu_src1= {33{op_mul | op_div}} & {alu_src1[31],alu_src1} | {33{op_mulu | op_divu}} & {1'b0,alu_src1};
assign extd_alu_src2= {33{op_mul | op_div}} & {alu_src2[31],alu_src2} | {33{op_mulu | op_divu}} & {1'b0,alu_src2};
assign mul_block    = (op_mul || op_mulu) && (mul_cnt < `MUL_CNT);
assign mul_data_ok  = (op_mul || op_mulu) && (mul_cnt == `MUL_CNT);
assign mul_result   = mul_result_raw[63:0];

always@(posedge clk)
begin
    if(reset)
      mul_cnt <= 0;
    else if(mul_cnt >= `MUL_CNT && m1s_allowin)
      mul_cnt <= 0;
    else if((op_mul || op_mulu) && (mul_cnt < `MUL_CNT))
      mul_cnt <= mul_cnt + 1;    
end

// always@(posedge clk)
// begin
//   if(mul_cnt == `MUL_CNT)
//     mul_result_r  <= mul_result_raw;
//     mulu_result_r <= mulu_result_raw;
// end

multiplier_signed multiplier_signed(
  .CLK    (clk),
  .A      ($signed(extd_alu_src1)),
  .B      ($signed(extd_alu_src2)),
  .P      (mul_result_raw)
);

// multiplier_unsigned multiplier_unsigned(
//   .CLK    (clk),
//   .A      (alu_src1),
//   .B      (alu_src2),
//   .P      (mulu_result_raw)
// );


//DIV result
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

// assign s_axis_divisor_tready = (us_axis_divisor_tready & op_divu) | (ss_axis_divisor_tready & op_div);
// assign s_axis_dividend_tready = (us_axis_dividend_tready & op_divu) | (ss_axis_dividend_tready & op_div);
// assign m_axis_dout_tvalid = (um_axis_dout_tvalid & op_divu) | (sm_axis_dout_tvalid & op_div);
assign s_axis_divisor_tready  = (ss_axis_divisor_tready & (op_div | op_divu));
assign s_axis_dividend_tready = (ss_axis_dividend_tready & (op_div | op_divu));
assign m_axis_dout_tvalid     = (sm_axis_dout_tvalid & (op_div | op_divu));

// assign us_axis_dividend_tvalid = op_divu & (state == still | state == send);
// assign us_axis_divisor_tvalid = op_divu & (state == still | state == send);
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

// divider_unsigned divider_unsigned(
//   .aclk                    (clk),
//   .s_axis_divisor_tdata    (s_axis_divisor_tdata),
//   .s_axis_divisor_tready   (us_axis_divisor_tready),
//   .s_axis_divisor_tvalid   (us_axis_divisor_tvalid),

//   .s_axis_dividend_tdata    (s_axis_dividend_tdata),
//   .s_axis_dividend_tready   (us_axis_dividend_tready),
//   .s_axis_dividend_tvalid   (us_axis_dividend_tvalid),

//   .m_axis_dout_tdata    (um_axis_dout_tdata),
//   .m_axis_dout_tvalid   (um_axis_dout_tvalid)
// );

// final result mux
assign alu_result = ({64{op_add|op_sub }} & {32'b0,add_sub_result})
                  | ({64{op_slt        }} & {32'b0,slt_result})
                  | ({64{op_sltu       }} & {32'b0,sltu_result})
                  | ({64{op_and        }} & {32'b0,and_result})
                  | ({64{op_nor        }} & {32'b0,nor_result})
                  | ({64{op_or         }} & {32'b0,or_result})
                  | ({64{op_xor        }} & {32'b0,xor_result})
                  | ({64{op_lui        }} & {32'b0,lui_result})
                  | ({64{op_sll        }} & {32'b0,sll_result})
                  | ({64{op_srl        }} & {32'b0,srl_result})
                  | ({64{op_sra        }} & {32'b0,sra_result})
                  | ({64{op_mul|op_mulu}} & mul_result)
                  | ({64{op_div|op_divu}} & {div_s,div_r});
                  // | ({64{op_divu       }} & um_axis_dout_tdata);

endmodule
