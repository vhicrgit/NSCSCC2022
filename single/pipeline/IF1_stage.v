`include "../mycpu.h"

module if1_stage(
    input                          clk            ,
    input                          reset          ,
    //from f2s
    input                          b_or_j         ,
    input  [31: 0]                 f2s_pc         ,
    input                          f2s_allowin   ,
    //br_bus
    input  [`BR_BUS_WD       -1:0] br_bus         ,
    //from ds
    input  [31:0]                  es_pc,
    //to f2s
    output                         f1s_to_f2s_valid,
    output [`F1S_TO_F2S_BUS_WD -1:0] f1s_to_f2s_bus  ,
    //from hazard
    input                          f2s_flush        ,
    input                          f1s_stall        ,
    //eret
    input                          ex_taken         ,
    input                          eret_taken       ,
    input    [31:0]                epc              ,
    //inst_cache interface
    output                         inst_sram_req    ,
    output                         inst_sram_wr     ,
    output   [1:0]                 inst_sram_size   ,
    output   [3:0]                 inst_sram_wstrb  ,
    output   [31:0]                inst_sram_addr   ,
    output   [31:0]                inst_sram_wdata  ,
    input                          inst_sram_addr_ok,
    output                         inst_uncache,
    //from BHT
    input    [31:0]                pd_pc,
   
    //address space
    input                          config_kseg0
);

//-------------------------- pre-IF stage -------------------------
wire        to_f1s_valid;
wire        pfs_ready_go;
//address space
wire        kuseg;
wire        kseg0;
wire        kseg1;
wire        kseg2;
wire        kseg3;
wire        kseg01;


//pc
wire [31:0] seq_pc;
wire [31:0] nextpc;
reg         nextpc_stall;
reg  [31:0] nextpc_r;

reg  [31:0] epc_r;
reg         ex_taken_r;
reg         eret_taken_r; 




//br bus
wire                        br_taken;
// wire [ 31:0]                br_target;

wire                        br_taken_r;
// wire [ 31:0]                br_target_r;
reg  [`BR_BUS_WD  -1:0]     br_bus_r;
// wire [ 31:0]                br_target_true;
wire [31: 0]                br_real_target;
wire [31: 0]                br_real_target_r;

wire fake;
wire fake_r;

//--------------------------- IF1 stage --------------------------
reg  [31:0]     f1s_pc;
reg  [31:0]     pd_pc_r;
reg  [31:0]     f2s_pc_r;
reg  [31:0]     es_pc_r;
wire [31:0]     f2s_pc_true;
wire [31:0]     es_pc_true;
wire [31:0]     pd_pc_true;
wire [31:0]     real_target_pc;//预测错误时，纠正的pc
reg             f1s_valid;
wire            f1s_ready_go;
wire            f1s_allowin;
reg             pd_pc_r_valid;

wire            f1s_ex;
wire [4:0]      f1s_excode;
wire            addr_unalg;

wire            br_prd_err;
reg             b_or_j_r;
wire            b_or_j_true;
wire            br_prd_err_r;
wire            br_prd_flush;
reg             f2s_flush_r;

reg             stop;


//========================= pre-IF stage ==============================

// pre-IF stage
assign pfs_ready_go =  1'b1;
assign to_f1s_valid  = ~reset && pfs_ready_go;

//address space
// assign kuseg = (nextpc[31:28] < 4'h8);
assign kseg0 = (nextpc[31:28] >= 4'h8) && (nextpc[31:28] < 4'ha);
assign kseg1 = (nextpc[31:28] >= 4'ha) && (nextpc[31:28] < 4'hc);
// assign kseg2 = (nextpc[31:28] >= 4'hc) && (nextpc[31:28] < 4'he);
// assign kseg3 = (nextpc[31:28] >= 4'he);
// assign kseg01 = nextpc[31:30] == 2'b10;
assign inst_uncache  = kseg1;//kseg0 && config_kseg0 || kseg1;

//br bus
assign      {br_prd_err,
            br_real_target} = br_bus;
assign      {br_prd_err_r   ,
            br_real_target_r} = br_bus_r;
// assign br_target_true = br_taken_r ? br_target_r : br_target;
assign es_pc_true = br_prd_err_r ? es_pc_r : es_pc;

always@(posedge clk)begin
    if(reset || pfs_ready_go && f1s_allowin)begin
        br_bus_r          <= 0;
        es_pc_r           <= 0;
    end
    else if(br_prd_err)begin
        br_bus_r          <= br_bus;
        es_pc_r           <= es_pc;
    end
end



//exception
wire [31:0] epc_v;
assign epc_v = {32{eret_taken_r}}  & epc_r 
             | {32{!eret_taken_r}} & epc;

always@(posedge clk)begin
    if(reset || pfs_ready_go && f1s_allowin)begin
        ex_taken_r    <= 1'b0;
    end
    else if(ex_taken)begin
        ex_taken_r    <= 1'b1;
    end
end
//eret_flush
always@(posedge clk)begin
    if(reset || pfs_ready_go && f1s_allowin)begin
        eret_taken_r  <= 1'b0;
        epc_r         <= 0;
    end
    else if(eret_taken)begin
        eret_taken_r  <= 1'b1;
        epc_r         <= epc;
    end
end

//pd_pc
always@(posedge clk)begin
    if(reset || pfs_ready_go && f1s_allowin)begin
        pd_pc_r_valid   <= 1'b0;
        pd_pc_r         <= 0;
    end
    else if(b_or_j)begin
        pd_pc_r_valid   <= 1'b1;
        pd_pc_r         <= pd_pc;
    end
end


assign pd_pc_true   = pd_pc_r_valid ? pd_pc_r : pd_pc;
// assign real_target_pc = (br_taken   | br_taken_r) ? br_target_true : es_pc_true+4'h8;
assign real_target_pc = br_prd_err_r ? br_real_target_r : br_real_target;
assign seq_pc       = f1s_pc + 3'h4;
assign nextpc       = (ex_taken   | ex_taken_r)                                        ? 32'hbfc00380
                    : (eret_taken | eret_taken_r)                                      ? epc_v
                    : (br_prd_err | br_prd_err_r)                                      ? real_target_pc
                    : f1s_is_bd                                                        ? pd_pc_true
                    : seq_pc;
//=========================== IF1 stage =============================

assign br_prd_flush = ((br_prd_err || br_prd_err_r) && (f1s_pc != es_pc_true + 3'h4)) || (f2s_flush_r || f2s_flush);
assign b_or_j_true  = b_or_j_r || b_or_j;
assign f2s_pc_true  = b_or_j_r ? f2s_pc_r : f2s_pc;
//exception
assign f1s_is_bd    = b_or_j_true && (f1s_pc == f2s_pc_true + 3'h4);
assign addr_unalg   = (f1s_pc[1:0] != 2'b00);//unaligned
assign f1s_ex       = addr_unalg;
assign f1s_excode   = addr_unalg               ? `EXC_ADEL 
                    : 0;

// IF stage
assign f1s_ready_go    = !f1s_valid || inst_sram_addr_ok  || f1s_ex;
assign f1s_allowin     = !f1s_valid || f1s_ready_go && f2s_allowin;
assign f1s_to_f2s_valid =  f1s_valid && f1s_ready_go ;//&& !(f2s_flush_r || f2s_flush);

//inst_sram
assign inst_sram_req   = f1s_valid && !f1s_ex && !stop;
assign inst_sram_wr    = 1'b0;
assign inst_sram_wstrb = 4'h0;
assign inst_sram_addr  = (kseg0 || kseg1) ?  {3'd0,f1s_pc[28:0]} : f1s_pc[31:0];
assign inst_sram_wdata = 32'h0;
assign inst_sram_size  = 2'h2;


always@(posedge clk)begin
    if(reset)
        stop <= 1'b0;
    else if(f1s_ready_go && f2s_allowin)
        stop <= 1'b0;
    else if(inst_sram_addr_ok && !f2s_allowin)
        stop <= 1'b1;
end   
// //branch predict error
// always@(posedge clk)begin
//     if(reset || FIFO_allowin && f1s_ready_go)
//         br_prd_err_r <= 0;
//     else if(br_prd_err)
//         br_prd_err_r <= 1;
// end

//branch delay slot
always@(posedge clk)begin
    if(reset || f1s_ready_go && f2s_allowin)begin
        b_or_j_r          <= 0;
        f2s_pc_r          <= 32'h0;
    end
    else if(b_or_j)begin
        b_or_j_r          <= 1'b1;
        f2s_pc_r          <= f2s_pc;
    end
end

//f1s_flush
always@(posedge clk)begin
    if(reset || f1s_ready_go && f2s_allowin)begin
        f2s_flush_r     <= 1'b0;
    end
    else if(f2s_flush)begin
        f2s_flush_r     <= 1'b1;
    end
end


always @(posedge clk) begin
    if (reset) begin
        f1s_valid <= 1'b0;
    end
    else if (f1s_allowin) begin
        f1s_valid <= to_f1s_valid;
    end

    if (reset) begin
        f1s_pc <= 32'hbfbf_fffc;  
    end
    else if (to_f1s_valid && f1s_allowin) begin
        f1s_pc <= nextpc;
    end    
end




assign f1s_to_f2s_bus = {  br_prd_flush,//39
                            f1s_is_bd,  //38
                            f1s_ex,     //37
                            f1s_excode, //36:32
                            f1s_pc      //31:0
                        };

endmodule
