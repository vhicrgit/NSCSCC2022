`include "../mycpu.h"
`define INST_BUF_SIZE 4
module if2_stage(
    input                           clk            ,
    input                           reset          ,
    //from ds
    input                           ds_allowin     ,
    //from FIFO
    input                           f1s_to_f2s_valid,
    input [`F1S_TO_F2S_BUS_WD -1:0] f1s_to_f2s_bus ,
    //to f1s
    output                          f2s_allowin     ,
    output  [31: 0]                 f2s_pc,
    output                          b_or_j          ,
    //to ds
    output                          f2s_to_ds_valid ,
    output [`F2S_TO_DS_BUS_WD -1:0] f2s_to_ds_bus   ,
    //from hazard
    input                           f2s_flush       ,
    input                           ds_flush        ,
    input                           f2s_stall       ,
    //from es
    input                           br_prd_err      ,
    input   [31: 0]                 es_pc           ,
    //from BHT
    input   [31: 0]                 f2s_pd_pc        ,
    //inst_cache interface
    input                           inst_sram_data_ok,
    input    [31:0]                 inst_sram_rdata                        
);




reg          f2s_valid;
wire         f2s_ready_go;


reg [`F1S_TO_F2S_BUS_WD -1:0] f1s_to_f2s_bus_r;

wire        f2s_is_bd;
wire        f2s_ex;
wire [4:0]  f2s_excode;
reg         inst_sram_data_ok_r;
wire [31:0] f2s_inst_true;
reg         ds_flush_r;
wire        f1s_br_prd_flush;//分支预测错误
wire        f2s_br_prd_flush_true;
wire        f2s_br_prd_flush;
reg         f2s_br_prd_flush_r;
reg         f2s_flush_r;

//pre-decode
wire        inst_beq;
wire        inst_bne;
wire        inst_bgez;
wire        inst_bgtz;
wire        inst_blez;
wire        inst_bltz;
wire        inst_bgezal;
wire        inst_bltzal;
wire        inst_j;
wire        inst_jal;
wire        inst_jr;
wire        inst_jalr;

wire [5:0]  op;
wire [4:0]  rt;
wire [4:0]  rd;
wire [4:0]  sa;
wire [5:0]  func;

//inst buffer size
reg [31: 0] inst_buffer [0:`INST_BUF_SIZE-1];
reg [ 1: 0] head;
reg [ 1: 0] tail;
reg [ 2: 0] i;
wire        empty;
assign empty = (head == tail);

always@(posedge clk)begin
    if(reset)
        head <= 0;
    else if(ds_allowin && f2s_ready_go && !f2s_ex && f2s_valid)
        head <= head + 1'b1;
end

always@(posedge clk)begin
    if(reset)
        tail <= 0;
    else if(inst_sram_data_ok)
        tail <= tail + 1'b1;
end

always@(posedge clk)begin
    if(reset)begin
        for(i=0;i<`INST_BUF_SIZE;i=i+1)
            inst_buffer[i] <= 0;
    end
    else if(inst_sram_data_ok)
            inst_buffer[tail] <= inst_sram_rdata;
end

//  always@(posedge clk)begin
//     if(reset)begin
//         inst_sram_data_ok_r     <= 1'b0;
//     end
//     else if(f2s_ready_go && ds_allowin)begin
//         inst_sram_data_ok_r     <= 1'b0;
//     end
//     else if(inst_sram_data_ok)begin
//         inst_sram_data_ok_r     <= 1'b1;
//     end
// end

always@(posedge clk)begin
    if(reset)begin
        f2s_br_prd_flush_r     <= 1'b0;
    end
    else if(f2s_ready_go && ds_allowin)begin
        f2s_br_prd_flush_r     <= 1'b0;
    end
    else if(f2s_br_prd_flush)begin
        f2s_br_prd_flush_r     <= 1'b1;
    end
end

always@(posedge clk)begin
    if(reset)begin
        f2s_flush_r     <= 1'b0;
    end
    else if(f2s_ready_go && ds_allowin)begin
        f2s_flush_r     <= 1'b0;
    end
    else if(f2s_flush)begin
        f2s_flush_r     <= 1'b1;
    end
end

assign f2s_br_prd_flush = (br_prd_err && (f2s_pc != es_pc+3'h4));
assign f2s_br_prd_flush_true = f1s_br_prd_flush | f2s_br_prd_flush | f2s_br_prd_flush_r;

// IF stage
assign f2s_ready_go    = !f2s_valid || inst_sram_data_ok || f2s_ex || !empty;
assign f2s_allowin     = !f2s_valid || f2s_ready_go && ds_allowin;
assign f2s_to_ds_valid =  f2s_valid && f2s_ready_go && !(ds_flush || ds_flush_r) && !(f2s_br_prd_flush_true | f2s_flush | f2s_flush_r);

always @(posedge clk) begin
    if (reset) begin
        f2s_valid <= 1'b0;
    end
    else if (f2s_allowin) begin
        f2s_valid <= f1s_to_f2s_valid;
    end

    if (f1s_to_f2s_valid && f2s_allowin) begin
        f1s_to_f2s_bus_r  <= f1s_to_f2s_bus;
    end
    else if(f2s_allowin)begin
        f1s_to_f2s_bus_r <= 0;
    end
end




//ds_flush
always@(posedge clk)begin
    if(reset)begin
        ds_flush_r     <= 1'b0;
    end
    else if(f2s_ready_go && ds_allowin)begin
        ds_flush_r     <= 1'b0;
    end
    else if(ds_flush)begin
        ds_flush_r     <= 1'b1;
    end
end


assign f2s_inst_true = empty ? inst_sram_rdata : inst_buffer[head];
assign {
        f1s_br_prd_flush,//39
        f2s_is_bd,       //38
        f2s_ex,          //37
        f2s_excode,      //36:32
        f2s_pc           //31:0
} = f1s_to_f2s_bus_r;

   

//pre-decode
assign op   = f2s_inst_true[31:26];
assign rt   = f2s_inst_true[20:16];
assign rd   = f2s_inst_true[15:11];
assign sa   = f2s_inst_true[10: 6];
assign func = f2s_inst_true[ 5: 0];

assign inst_beq     = (op == 6'b000100);
assign inst_bne     = (op == 6'b000101);
assign inst_bgez    = (op == 6'b000001) && (rt == 5'b00001);
assign inst_bgtz    = (op == 6'b000111) && (rt == 5'b00000);
assign inst_blez    = (op == 6'b000110) && (rt == 5'b00000);
assign inst_bltz    = (op == 6'b000001) && (rt == 5'b00000);
assign inst_bgezal  = (op == 6'b000001) && (rt == 5'b10001);
assign inst_bltzal  = (op == 6'b000001) && (rt == 5'b10000);
assign inst_j       = (op == 6'b000010);
assign inst_jal     = (op == 6'b000011);
assign inst_jr      = (op == 6'b000000) && (rt == 5'b00000) && (rd == 5'b00000) && (sa == 5'b00000) && (func == 6'b001000);
assign inst_jalr    = (op == 6'b000000) && (rt == 5'b00000) && (sa == 5'b00000) && (func == 6'b001001);


assign b_or_j = f2s_valid && (inst_beq || inst_bne || inst_bgez || inst_bgtz || inst_blez || inst_bltz 
              || inst_bgezal || inst_bltzal || inst_j || inst_jal || inst_jr || inst_jalr);



assign f2s_to_ds_bus = {
                        b_or_j,          //103
                        f2s_pd_pc,       //102:71
                        f2s_ex   ,      //70
                        f2s_excode,     //69:65
                        f2s_is_bd,      //64
                        f2s_inst_true , //63:32
                        f2s_pc          //31:0
                        };

endmodule




 













