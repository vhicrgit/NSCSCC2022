`include "../mycpu.h"

module if1_stage(
    input                           clk            ,
    input                           reset          ,
    //f2s
    input                           fifo_allowin    ,
    //br_bus
    input  [`BR_BUS_WD       -1:0]  br_bus         ,
    //from hazard
    input                           f1s_flush        ,
    //exception
    input                           ex_taken         ,
    input                           eret_taken       ,
    input    [31:0]                 epc              ,
    //inst_cache interface
    input  [31: 0]                  seq_pc         ,
    output                          f1s_ex_0       ,
    output                          f1s_ex_1       ,
    output [ 4: 0]                  f1s_excode_0   ,
    output [ 4: 0]                  f1s_excode_1   ,
    output                          inst_sram_req    ,
    output   [1:0]                  inst_sram_size   ,
    output   [31:0]                 inst_sram_addr   ,
    input                           inst_sram_addr_ok,
    output                          inst_uncache,
   
    //address space
    input                           config_kseg0
);

//-------------------------- pre-IF stage -------------------------
wire        to_f1s_valid;
wire        pfs_ready_go;
//address space
wire        kseg0;
wire        kseg1;
wire        kseg01;
//pc
wire [31:0] nextpc;
reg         nextpc_stall;
reg  [31:0] nextpc_r;
//exception
reg  [31:0] epc_r;
reg         ex_taken_r;
reg         eret_taken_r; 


//br bus
reg  [`BR_BUS_WD  -1:0]     br_bus_r;
wire [31: 0]                br_real_target;
wire [31: 0]                br_real_target_r;



//--------------------------- IF1 stage --------------------------
reg  [31:0]     f1s_pc;
reg  [31:0]     es_pc_r;
wire [31:0]     real_target_pc;//预测错误时，纠正的pc
reg             f1s_valid;
wire            f1s_ready_go;
wire            f1s_allowin;
reg             pd_pc_r_valid;

//exception
wire            addr_unalg_0;
wire            addr_unalg_1;
//predict error
wire            br_prd_err;
wire            br_prd_err_r;


//========================= pre-IF stage ==============================

// pre-IF stage
assign pfs_ready_go =  1'b1;
assign to_f1s_valid  = ~reset && pfs_ready_go;

//address space
assign kseg0 = (nextpc[31:28] >= 4'h8) && (nextpc[31:28] < 4'ha);
assign kseg1 = (nextpc[31:28] >= 4'ha) && (nextpc[31:28] < 4'hc);
assign inst_uncache  = kseg1;//kseg0 && config_kseg0 || kseg1;

//br bus
assign      {br_prd_err,
            br_real_target} = br_bus;
assign      {br_prd_err_r   ,
            br_real_target_r} = br_bus_r;


always@(posedge clk)begin
    if(reset || pfs_ready_go && f1s_allowin)begin
        br_bus_r          <= 0;
    end
    else if(br_prd_err)begin
        br_bus_r          <= br_bus;
    end
end


//exception
wire [31:0] epc_v;
assign epc_v = {32{eret_taken_r}}  & epc_r 
             | {32{!eret_taken_r}} & epc;

// always@(posedge clk)begin
//     if(reset || pfs_ready_go && f1s_allowin)begin
//         ex_taken_r    <= 1'b0;
//     end
//     else if(ex_taken)begin
//         ex_taken_r    <= 1'b1;
//     end
// end
// //eret_flush
// always@(posedge clk)begin
//     if(reset || pfs_ready_go && f1s_allowin)begin
//         eret_taken_r  <= 1'b0;
//         epc_r         <= 0;
//     end
//     else if(eret_taken)begin
//         eret_taken_r  <= 1'b1;
//         epc_r         <= epc;
//     end
// end


assign real_target_pc = br_prd_err_r ? br_real_target_r : br_real_target;
// assign seq_pc       = (f1s_pc[2:0] == 3'b111) ? 32'h8 : 32'h4;
assign nextpc       = (ex_taken)         ? 32'hbfc00380
                    : (eret_taken)       ? epc
                    : (br_prd_err)       ? br_real_target
                    : seq_pc;

//=========================== IF1 stage =============================

//exception
assign addr_unalg_0  = (f1s_pc[1:0] != 2'b00);//unaligned
assign addr_unalg_1  = (f1s_pc[1:0] != 2'b00);//unaligned
assign f1s_ex_0      = addr_unalg_0;
assign f1s_ex_1      = addr_unalg_1;
assign f1s_excode_0  = addr_unalg_0               ? `EXC_ADEL 
                    : 0;
assign f1s_excode_1  = addr_unalg_1               ? `EXC_ADEL 
                    : 0;

// IF stage
assign f1s_ready_go    = !f1s_valid || inst_sram_addr_ok;
assign f1s_allowin     = 1;//!f1s_valid || f1s_ready_go && fifo_allowin || f1s_flush;

//inst_sram
assign inst_sram_req   = f1s_valid && fifo_allowin;
// assign inst_sram_addr  = (kseg0 || kseg1) ?  {3'd0,f1s_pc[28:0]} : f1s_pc[31:0];
assign inst_sram_addr  = f1s_pc[31:0];
assign inst_sram_wdata = 32'h0;
assign inst_sram_size  = 2'h2;

always @(posedge clk) begin
    if (reset) begin
        f1s_valid <= 1'b1;
    end
    else if (f1s_allowin) begin
        f1s_valid <= to_f1s_valid;
    end

    if (reset) begin
        f1s_pc <= 32'hbfc0_0000; 
        //f1s_pc <= 32'hbfbf_fffc;  
    end
    else if (to_f1s_valid && f1s_allowin) begin
        f1s_pc <= nextpc;
    end    
end

// always@(posedge clk)begin
//     if(reset)
//         stop <= 1'b0;
//     else if(f1s_ready_go && fifo_allowin)
//         stop <= 1'b0;
//     else if(inst_sram_addr_ok && !fifo_allowin)
//         stop <= 1'b1;
// end   


endmodule
