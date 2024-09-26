`include "../mycpu.h"

module id_stage(
    input                          clk           ,
    input                          reset         ,
    //allowin
    input                          es_allowin    ,
    output                         ds_allowin    ,
    //to f1s
    output  [31:0]                 ds_pc        ,
    //from f2s
    input                          f2s_to_ds_valid,
    input  [`F2S_TO_DS_BUS_WD -1:0]f2s_to_ds_bus  ,
    //to es
    output                         ds_to_es_valid,
    output [`DS_TO_ES_BUS_WD -1:0] ds_to_es_bus  ,
    //to f2s
    // output [`BR_BUS_WD       -1:0] br_bus        ,
    output                         ds_ready_go   ,
    // //to rf: for write back
    // input  [`WS_TO_RF_BUS_WD -1:0] ws_to_rf_bus  ,
    //to regfile
    output  [ 4                :0] rf_raddr1    ,
    output  [ 4                :0] rf_raddr2    ,
    input  [31                :0]  rf_rdata1    ,
    input  [31                :0]  rf_rdata2    ,
    //forwarding
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
    //to forwarding
    output                         br           ,
    output [4:0]                   ds_rs1       ,
    output [4:0]                   ds_rs2       ,
    //from hazard
    input                               es_flush,
    input                               ds_stall,
    //to hazard
    output                              br_taken,
    output reg                          ds_valid,
    //to BHT
    output                          br_prd_err  ,
    output                          ds_b_or_j   ,
    output  [31                 :0] ds_pd_pc    ,
    //from cp0
    input                           has_int     
);



wire [`BR_BUS_WD       -1:0] br_bus;
wire [31                 :0]  f2s_pc;
reg  [`F2S_TO_DS_BUS_WD -1:0] f2s_to_ds_bus_r;

wire [31:0] ds_inst ;
wire        ds_bd   ;
wire [4:0]  f2s_excode;
wire        f2s_ex   ;


assign f2s_pc = ds_pc + 4;            //delay slot pc

assign {
        ds_b_or_j,   //103
        ds_pd_pc,    //102:71
        f2s_ex,      //70
        f2s_excode,  //69:65
        ds_bd  ,    //64
        ds_inst,    //63:32
        ds_pc       //31:0
} = f2s_to_ds_bus_r;

// wire [ 3:0] rf_we   ;
// wire [ 4:0] rf_waddr;
// wire [31:0] rf_wdata;
// assign {rf_we   ,  //40:37
//         rf_waddr,  //36:32
//         rf_wdata   //31:0
//        } = ws_to_rf_bus;

wire [31:0] br_target;

wire [15:0] alu_op;
wire        load_op;
wire        src1_is_sa;
wire        src1_is_pc;
wire        src2_is_imm;
wire        src2_is_0imm;
wire        src2_is_8;
wire        res_from_mem;
wire        gr_we;
wire        mem_we;
wire [ 4:0] dest;
wire [15:0] imm;
wire [31:0] rs_value;
wire [31:0] rt_value;
wire        res_is_hi;
wire        res_is_lo;
wire        hi_wen;
wire        lo_wen;
wire        eret_flush;
wire        mtc0_we;
wire        ds_ex;
wire [7:0]  cp0_addr;
wire [4:0]  ds_excode;
wire        ds_res_from_cp0;
wire        overflow_en;
wire        inst_undef;


wire [ 5:0] op;
wire [ 4:0] rs;
wire [ 4:0] rt;
wire [ 4:0] rd;
wire [ 4:0] sa;
wire [ 5:0] func;
wire [25:0] jidx;
wire [63:0] op_d;
wire [31:0] rs_d;
wire [31:0] rt_d;
wire [31:0] rd_d;
wire [31:0] sa_d;
wire [63:0] func_d;
wire [ 2:0] sel;

wire        inst_addu;
wire        inst_subu;
wire        inst_slt;
wire        inst_sltu;
wire        inst_and;
wire        inst_or;
wire        inst_xor;
wire        inst_nor;
wire        inst_sll;
wire        inst_srl;
wire        inst_sra;
wire        inst_addiu;
wire        inst_lui;
wire        inst_lw;
wire        inst_sw;
wire        inst_beq;
wire        inst_bne;
wire        inst_jal;
wire        inst_jr;

wire        inst_add;
wire        inst_addi;
wire        inst_sub;
wire        inst_slti;
wire        inst_sltiu;
wire        inst_andi;
wire        inst_ori;
wire        inst_xori;
wire        inst_sllv;
wire        inst_srlv;
wire        inst_srav;
wire        inst_mult;
wire        inst_multu;
wire        inst_div;
wire        inst_divu;
wire        inst_mfhi;
wire        inst_mflo;     
wire        inst_mthi;
wire        inst_mtlo;

wire        inst_bgez;
wire        inst_bgtz;
wire        inst_blez;
wire        inst_bltz;
wire        inst_j;
wire        inst_bltzal;
wire        inst_bgezal;
wire        inst_jalr;
wire        inst_lb;
wire        inst_lbu;
wire        inst_lh;
wire        inst_lhu;
wire        inst_sb;
wire        inst_sh;
wire        inst_lwl;
wire        inst_lwr;
wire        inst_swl;
wire        inst_swr;
wire        inst_mul;

wire        inst_syscall;
wire        inst_eret;
wire        inst_break;
wire        inst_mfc0;
wire        inst_mtc0;


wire        dst_is_r31;  
wire        dst_is_rt;   

wire        l_is_lw;
wire        l_is_lb;
wire        l_is_lbu;
wire        l_is_lh;
wire        l_is_lhu;
wire        l_is_lwl;
wire        l_is_lwr;
wire        s_is_sw;
wire        s_is_sb;
wire        s_is_sh;
wire        s_is_swl;
wire        s_is_swr;

wire        rs_eq_rt;
wire        rs_le_zero;
wire        rs_lt_zero;

//============================ forwarding =======================================
wire  [1:                  0] fwd1    ;
wire  [1:                  0] fwd2    ;
wire  [3:                  0] fwd1_wen;
wire  [3:                  0] fwd2_wen;
assign fwd1_wen = (fwd1 == `WB) ? ws_rf_wen : 4'b1111;
assign fwd2_wen = (fwd2 == `WB) ? ws_rf_wen : 4'b1111;

assign fwd1 = !(ds_valid) ? 0
            : ((ds_rs1 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S
            : ((ds_rs1 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S
            : ((ds_rs1 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB
            : 0;

assign fwd2 = !(ds_valid) ? 0
            : ((ds_rs2 == m1s_rd) && (m1s_rd != 5'd0) && m1s_reg_write && m1s_valid) ? `M1S
            : ((ds_rs2 == m2s_rd) && (m2s_rd != 5'd0) && m2s_reg_write && m2s_valid) ? `M2S
            : ((ds_rs2 == ws_rd) && (ws_rd != 5'd0) && ws_reg_write && ws_valid) ? `WB
            : 0;





// to regfile
assign ds_rs1 = rf_raddr1;
assign ds_rs2 = dst_is_rt  ? 4'd0    : 
                            rf_raddr2;


assign ds_ready_go    = !ds_valid || !ds_stall;
assign ds_allowin     = !ds_valid || ds_ready_go && es_allowin;
assign ds_to_es_valid = ds_valid && ds_ready_go && !es_flush;
always @(posedge clk) begin
    if(reset)begin
        ds_valid<=1'b0;
    end
    else if(ds_allowin)begin
        ds_valid<=f2s_to_ds_valid;
    end

    if (f2s_to_ds_valid && ds_allowin) begin
        f2s_to_ds_bus_r <= f2s_to_ds_bus;
    end
    else if(ds_allowin)begin
        f2s_to_ds_bus_r <= 0;
    end
end

assign op   = ds_inst[31:26];
assign rs   = ds_inst[25:21];
assign rt   = ds_inst[20:16];
assign rd   = ds_inst[15:11];
assign sa   = ds_inst[10: 6];
assign func = ds_inst[ 5: 0];
assign imm  = ds_inst[15: 0];
assign jidx = ds_inst[25: 0];
assign sel  = ds_inst[2 : 0];

decoder_6_64 u_dec0(.in(op  ), .out(op_d  ));
decoder_6_64 u_dec1(.in(func), .out(func_d));
decoder_5_32 u_dec2(.in(rs  ), .out(rs_d  ));
decoder_5_32 u_dec3(.in(rt  ), .out(rt_d  ));
decoder_5_32 u_dec4(.in(rd  ), .out(rd_d  ));
decoder_5_32 u_dec5(.in(sa  ), .out(sa_d  ));

assign inst_addu   = op_d[6'h00] & func_d[6'h21] & sa_d[5'h00];
assign inst_subu   = op_d[6'h00] & func_d[6'h23] & sa_d[5'h00];
assign inst_slt    = op_d[6'h00] & func_d[6'h2a] & sa_d[5'h00];
assign inst_sltu   = op_d[6'h00] & func_d[6'h2b] & sa_d[5'h00];
assign inst_and    = op_d[6'h00] & func_d[6'h24] & sa_d[5'h00];
assign inst_or     = op_d[6'h00] & func_d[6'h25] & sa_d[5'h00];
assign inst_xor    = op_d[6'h00] & func_d[6'h26] & sa_d[5'h00];
assign inst_nor    = op_d[6'h00] & func_d[6'h27] & sa_d[5'h00];
assign inst_sll    = op_d[6'h00] & func_d[6'h00] & rs_d[5'h00];
assign inst_srl    = op_d[6'h00] & func_d[6'h02] & rs_d[5'h00];
assign inst_sra    = op_d[6'h00] & func_d[6'h03] & rs_d[5'h00];
assign inst_addiu  = op_d[6'h09];
assign inst_lui    = op_d[6'h0f] & rs_d[5'h00];
assign inst_lw     = op_d[6'h23];
assign inst_sw     = op_d[6'h2b];
assign inst_beq    = op_d[6'h04];
assign inst_bne    = op_d[6'h05];
assign inst_jal    = op_d[6'h03];
assign inst_jr     = op_d[6'h00] & func_d[6'h08] & rt_d[5'h00] & rd_d[5'h00] & sa_d[5'h00];

assign inst_add    = op_d[6'h00] & func_d[6'h20] & sa_d[5'h00];
assign inst_addi   = op_d[6'h08];
assign inst_sub    = op_d[6'h00] & func_d[6'h22] & sa_d[5'h00];
assign inst_slti   = op_d[6'h0a];
assign inst_sltiu  = op_d[6'h0b];
assign inst_andi   = op_d[6'h0c];
assign inst_ori    = op_d[6'h0d];
assign inst_xori   = op_d[6'h0e];
assign inst_sllv   = op_d[6'h00] & func_d[6'h04] & sa_d[5'h00];
assign inst_srav   = op_d[6'h00] & func_d[6'h07] & sa_d[5'h00];
assign inst_srlv   = op_d[6'h00] & func_d[6'h06] & sa_d[5'h00];
assign inst_mult   = op_d[6'h00] & func_d[6'h18] & sa_d[5'h00] & rd_d[5'h00];
assign inst_multu  = op_d[6'h00] & func_d[6'h19] & sa_d[5'h00] & rd_d[5'h00];
assign inst_div    = op_d[6'h00] & func_d[6'h1a] & sa_d[5'h00] & rd_d[5'h00];
assign inst_divu   = op_d[6'h00] & func_d[6'h1b] & sa_d[5'h00] & rd_d[5'h00];
assign inst_mfhi   = op_d[6'h00] & func_d[6'h10] & sa_d[5'h00] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mflo   = op_d[6'h00] & func_d[6'h12] & sa_d[5'h00] & rs_d[5'h00] & rt_d[5'h00];
assign inst_mthi   = op_d[6'h00] & func_d[6'h11] & sa_d[5'h00] & rd_d[5'h00] & rt_d[5'h00];
assign inst_mtlo   = op_d[6'h00] & func_d[6'h13] & sa_d[5'h00] & rd_d[5'h00] & rt_d[5'h00];

assign inst_bgez = op_d[6'h01] & rt_d[5'h01];
assign inst_bgtz = op_d[6'h07] & rt_d[5'h00];
assign inst_blez = op_d[6'h06] & rt_d[5'h00];
assign inst_bltz = op_d[6'h01] & rt_d[5'h00];
assign inst_bltzal = op_d[6'h01] & rt_d[5'h10];
assign inst_bgezal = op_d[6'h01] & rt_d[5'h11];
assign inst_j = op_d[6'h02];
assign inst_jalr = op_d[6'h00] & func_d[6'h09] & sa_d[5'h00] & rt_d[5'h00];
assign inst_lb = op_d[6'h20];
assign inst_lbu = op_d[6'h24];
assign inst_lh = op_d[6'h21];
assign inst_lhu = op_d[6'h25];
assign inst_sb= op_d[6'h28];
assign inst_sh= op_d[6'h29];
assign inst_lwl= op_d[6'h22];
assign inst_lwr= op_d[6'h26];
assign inst_swl= op_d[6'h2a];
assign inst_swr= op_d[6'h2e];
assign inst_mul= op_d[6'h1c] & sa_d[5'h00] & func_d[6'h02];

assign inst_syscall = op_d[6'h00] & func_d[6'h0c];
assign inst_break   = op_d[6'h00] & func_d[6'h0d];
assign inst_eret    = op_d[6'h10] & func_d[6'h18] & rs_d[5'h10] & sa_d[5'h00] & rd_d[5'h00] & rt_d[5'h00];
assign inst_mfc0    = op_d[6'h10] & rs_d[5'h00] & sa_d[5'h00] & !ds_inst[5] & !ds_inst[4] & !ds_inst[3];
assign inst_mtc0    = op_d[6'h10] & rs_d[5'h04] & sa_d[5'h00] & !ds_inst[5] & !ds_inst[4] & !ds_inst[3];


assign inst_undef = !(inst_addu | inst_subu | inst_slt | inst_sltu | inst_and | inst_or | inst_xor | inst_nor | inst_sll | inst_srl | 
                    inst_sra | inst_addiu | inst_lui | inst_lw | inst_sw | inst_beq | inst_bne | inst_jal | inst_jr | inst_add | 
                    inst_addi | inst_sub | inst_slti | inst_sltiu | inst_andi | inst_ori | inst_xori | inst_sllv | inst_srlv | 
                    inst_srav | inst_mult | inst_multu | inst_div | inst_divu | inst_mfhi | inst_mflo | inst_mthi | inst_mtlo | 
                    inst_bgez | inst_bgtz | inst_blez | inst_bltz | inst_j | inst_bltzal | inst_bgezal | inst_jalr | inst_lb | 
                    inst_lbu | inst_lh | inst_lhu | inst_sb | inst_sh | inst_lwl | inst_lwr | inst_swl | inst_swr | inst_syscall | 
                    inst_eret | inst_break | inst_mfc0 | inst_mtc0 | inst_mul);



assign alu_op[ 0] = inst_addu | inst_addiu | inst_lw | inst_sw | inst_jal | inst_add | inst_addi | inst_jalr | inst_bgezal | inst_bltzal
                  | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_sh | inst_sb | inst_lwl | inst_lwr | inst_swl | inst_swr;
assign alu_op[ 1] = inst_subu | inst_sub;
assign alu_op[ 2] = inst_slt | inst_slti;
assign alu_op[ 3] = inst_sltu | inst_sltiu;
assign alu_op[ 4] = inst_and | inst_andi;
assign alu_op[ 5] = inst_nor;
assign alu_op[ 6] = inst_or | inst_ori;
assign alu_op[ 7] = inst_xor | inst_xori;
assign alu_op[ 8] = inst_sll | inst_sllv;
assign alu_op[ 9] = inst_srl | inst_srlv;
assign alu_op[10] = inst_sra | inst_srav;
assign alu_op[11] = inst_lui;
assign alu_op[12] = inst_mult | inst_mul;
assign alu_op[13] = inst_multu;
assign alu_op[14] = inst_div;
assign alu_op[15] = inst_divu;
assign overflow_en = inst_add | inst_sub | inst_addi;

assign load_op = res_from_mem;

assign src1_is_sa   = inst_sll   | inst_srl | inst_sra;
assign src1_is_pc   = inst_jal | inst_jalr | inst_bgezal | inst_bltzal;
assign src2_is_imm  = inst_addiu | inst_lui | inst_lw | inst_sw | inst_addi | inst_slti | inst_sltiu | inst_lb | inst_lbu | inst_lh 
                    | inst_lhu | inst_sb | inst_sh | inst_lwl | inst_lwr | inst_swl | inst_swr;
assign src2_is_0imm = inst_andi | inst_ori | inst_xori;
assign src2_is_8    = inst_jal | inst_jalr | inst_bgezal | inst_bltzal;
assign res_from_mem = inst_lw  | inst_lb | inst_lbu | inst_lh | inst_lhu | inst_lwl | inst_lwr;
assign dst_is_r31   = inst_jal | inst_jalr | inst_bgezal | inst_bltzal;
assign dst_is_rt    = inst_addiu | inst_lui | inst_lw | inst_addi | inst_slti | inst_sltiu | inst_andi | inst_ori | inst_xori | inst_lb 
                    | inst_lbu | inst_lh | inst_lhu | inst_lwl | inst_lwr | inst_mfc0;
assign gr_we        = ~inst_sw & ~inst_beq & ~inst_bne & ~inst_jr & ~inst_mult & ~inst_multu & ~inst_div & ~inst_divu & ~inst_mthi & 
                    ~inst_mtlo & ~inst_j &~inst_bgez &~inst_bgtz &~inst_bltz &~inst_blez &~inst_sb &~inst_sh &~inst_swl &~inst_swr &
                    ~inst_syscall & ~inst_mtc0;
assign mem_we       = inst_sw | inst_sb | inst_sh | inst_swl | inst_swr;
assign res_is_hi    = inst_mfhi;
assign res_is_lo    = inst_mflo;
assign hi_wen       = inst_mthi;
assign lo_wen       = inst_mtlo;
assign l_is_lw      = inst_lw;
assign l_is_lb      = inst_lb;
assign l_is_lbu     = inst_lbu;
assign l_is_lh      = inst_lh;
assign l_is_lhu     = inst_lhu;
assign l_is_lwl     = inst_lwl;
assign l_is_lwr     = inst_lwr;
assign s_is_sw      = inst_sw;
assign s_is_sb      = inst_sb;
assign s_is_sh      = inst_sh;
assign s_is_swl     = inst_swl;
assign s_is_swr     = inst_swr;
assign mtc0_we      = inst_mtc0;
assign eret_flush   = inst_eret & ds_valid;
assign cp0_addr     = {rd,sel};
assign ds_res_from_cp0 = inst_mfc0;

assign dest         = dst_is_r31 ? 5'd31 :
                      dst_is_rt  ? rt    : 
                                   rd;

assign rf_raddr1 = rs;
assign rf_raddr2 = rt;
//===============reg file==========


//===============reg file==========

assign rs_value = rf_rdata1;
assign rt_value = rf_rdata2;

wire [31:0] br_src1;
wire [31:0] br_src2;
assign br = (inst_bne | inst_beq | inst_bltz | inst_blez | inst_bgez | inst_bgtz | inst_bltzal | inst_bgezal | inst_jr | inst_jalr);

assign br_src1[7:0] = fwd1_wen[0] ? {         {32{(fwd1 == 2'd0)}} & rf_rdata1[7:0]
                                            | {32{(fwd1 == `M1S)}} & m1s_alu_result[7:0]
                                            | {32{(fwd1 == `M2S)}} & m2s_alu_result[7:0]
                                            | {32{(fwd1 == `WB)}} & ws_final_result[7:0]}
                                            : rf_rdata1[7:0];
assign br_src1[15:8] = fwd1_wen[1] ? {         {32{(fwd1 == 2'd0)}} & rf_rdata1[15:8]
                                            |  {32{(fwd1 == `M1S)}} & m1s_alu_result[15:8]
                                            |  {32{(fwd1 == `M2S)}} & m2s_alu_result[15:8]
                                            |  {32{(fwd1 == `WB)}} & ws_final_result[15:8]}
                                            : rf_rdata1[15:8];
assign br_src1[23:16] = fwd1_wen[2] ? {         {32{(fwd1 == 2'd0)}} & rf_rdata1[23:16]
                                            |   {32{(fwd1 == `M1S)}} & m1s_alu_result[23:16]
                                            |   {32{(fwd1 == `M2S)}} & m2s_alu_result[23:16]
                                            |   {32{(fwd1 == `WB)}} & ws_final_result[23:16]}
                                            : rf_rdata1[23:16];
assign br_src1[31:24] = fwd1_wen[3] ? {         {32{(fwd1 == 2'd0)}} & rf_rdata1[31:24]
                                            |   {32{(fwd1 == `M1S)}} & m1s_alu_result[31:24]
                                            |   {32{(fwd1 == `M2S)}} & m2s_alu_result[31:24]
                                            |   {32{(fwd1 == `WB)}} & ws_final_result[31:24]}
                                            : rf_rdata1[31:24];
                                           
assign br_src2[7:0] = fwd2_wen[0] ? {         {32{(fwd2 == 2'd0)}} & rf_rdata2[7:0]
                                            | {32{(fwd2 == `M1S)}} & m1s_alu_result[7:0]
                                            | {32{(fwd2 == `M2S)}} & m2s_alu_result[7:0]
                                            | {32{(fwd2 == `WB)}} & ws_final_result[7:0]}
                                            : rf_rdata2[7:0];
assign br_src2[15:8] = fwd2_wen[1] ? {         {32{(fwd2 == 2'd0)}} & rf_rdata2[15:8]
                                            |  {32{(fwd2 == `M1S)}} & m1s_alu_result[15:8]
                                            |  {32{(fwd2 == `M2S)}} & m2s_alu_result[15:8]
                                            |  {32{(fwd2 == `WB)}} & ws_final_result[15:8]}
                                            : rf_rdata2[15:8];
assign br_src2[23:16] = fwd2_wen[2] ? {         {32{(fwd2 == 2'd0)}} & rf_rdata2[23:16]
                                            |   {32{(fwd2 == `M1S)}} & m1s_alu_result[23:16]
                                            |   {32{(fwd2 == `M2S)}} & m2s_alu_result[23:16]
                                            |   {32{(fwd2 == `WB)}} & ws_final_result[23:16]}
                                            : rf_rdata2[23:16];
assign br_src2[31:24] = fwd2_wen[3] ? {         {32{(fwd2 == 2'd0)}} & rf_rdata2[31:24]
                                            |   {32{(fwd2 == `M1S)}} & m1s_alu_result[31:24]
                                            |   {32{(fwd2 == `M2S)}} & m2s_alu_result[31:24]
                                            |   {32{(fwd2 == `WB)}} & ws_final_result[31:24]}
                                            : rf_rdata2[31:24];

wire [31:0] br_real_target;

assign rs_eq_rt = (br_src1 == br_src2);
assign rs_lt_zero = ($signed(br_src1) <  0);
assign rs_le_zero = ($signed(br_src1) <= 0);
assign br_taken = (   inst_beq     &  rs_eq_rt
                   | inst_bne     & !rs_eq_rt
                   | inst_blez    &  rs_le_zero
                   | inst_bltz    &  rs_lt_zero
                   | inst_bgez    & !rs_lt_zero
                   | inst_bgtz    & !rs_le_zero
                   | inst_bltzal  &  rs_lt_zero
                   | inst_bgezal  & !rs_lt_zero
                   | inst_jal
                   | inst_jr
                   | inst_j
                   | inst_jalr
) && ds_valid && !ds_stall;
assign br_target = (inst_beq | inst_bne | inst_bltz | inst_blez | inst_bgez | inst_bgtz | inst_bltzal | inst_bgezal) ? (f2s_pc + {{14{imm[15]}}, imm[15:0], 2'b0}) :
                   (inst_jr | inst_jalr)              ? br_src1 :
                  /*inst_jal??inst_j*/              {f2s_pc[31:28], jidx[25:0], 2'b0};
//  BHT
assign br_real_target = br_taken ? br_target : ds_pc+4'h8;
// assign pd_true = ds_stall || ((ds_pd_pc == br_target && br_taken || !br_taken && (ds_pd_pc == ds_pc+8)) && ds_b_or_j) || !ds_b_or_j;
assign br_prd_err = ds_valid && !ds_stall && ds_b_or_j && (br_real_target != ds_pd_pc);
// assign br_bus       = {br_prd_err,br_real_target}&{`BR_BUS_WD{ds_valid &(!ds_stall && !ds_ex)}};// & !es_flush)}};
//========exception=========
assign ds_ex = f2s_ex | ((inst_syscall | inst_break | inst_undef | has_int) & ds_valid);
assign ds_excode =  has_int         ? `EXC_INT
                 :  f2s_ex          ? f2s_excode
                 :  inst_undef      ? `EXC_RI
                 :  inst_syscall    ? `EXC_SYS
                 :  inst_break      ? `EXC_BP
                 :  5'h0;


assign ds_to_es_bus = {
                        ds_pd_pc         ,  //250:219
                        ds_b_or_j        ,  //218
                        br_real_target   ,  //217:186
                        //-------exception---------
                        overflow_en      ,  //185
                        ds_bd            ,  //184
                        eret_flush       ,  //183
                        mtc0_we          ,  //182
                        cp0_addr         ,  //181:174
                        ds_res_from_cp0  ,  //173
                        ds_ex            ,  //172
                        ds_excode        ,  //171:167
                        l_is_lwl         ,  //166
                        l_is_lwr         ,  //165
                        l_is_lw          ,  //164
                        l_is_lb          ,  //163
                        l_is_lbu         ,  //162
                        l_is_lh          ,  //161
                        l_is_lhu         ,  //160
                        s_is_swl         ,  //159
                        s_is_swr         ,  //158
                        s_is_sw          ,  //157
                        s_is_sb          ,  //156
                        s_is_sh          ,  //155:
                        hi_wen           ,  //154:154
                        lo_wen           ,  //153:153
                        res_is_hi        ,  //152:152
                        res_is_lo        ,  //151:151
                        src2_is_0imm     ,  //150:150
                        ds_rs2           ,  //149:145
                        ds_rs1           ,  //144:140
                        alu_op           ,  //139:124
                        load_op          ,  //123:123
                        src1_is_sa       ,  //122:122
                        src1_is_pc       ,  //121:121
                        src2_is_imm      ,  //120:120
                        src2_is_8        ,  //119:119
                        gr_we            ,  //118:118
                        mem_we           ,  //117:117
                        dest             ,  //116:112
                        imm              ,  //111:96
                        rs_value         ,  //95 :64
                        rt_value         ,  //63 :32
                        ds_pc               //31 :0
                    };
        

endmodule
