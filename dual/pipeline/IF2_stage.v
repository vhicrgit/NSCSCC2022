`include "../mycpu.h"
`define BUF_LEN 3
`define INST_BUF_SIZE (1 << 4)
module fifo(
    input                           clk             ,
    input                           reset           ,
    //f1s
    output                          fifo_allowin    ,
    output  [31: 0]                 fifo_pc,
    //ds
    input  [1                   :0] issue_mode      ,
    output                          fifo_to_ds_valid_0,
    output                          fifo_to_ds_valid_1,
    output [`FIFO_TO_DS_BUS_WD -1:0]fifo_to_ds_bus_0 ,
    output [`FIFO_TO_DS_BUS_WD -1:0]fifo_to_ds_bus_1 ,
    //from hazard
    input                           ds_flush        ,
    //inst_cache interface    
    input   [`CACHE_TO_FIFO_WD-1 :0]   icache_bus_0    ,
    input   [`CACHE_TO_FIFO_WD-1 :0]   icache_bus_1    ,
    input                           valid_i_0       ,
    input                           valid_i_1                         
);

//predecode
// wire        inst_beq;
// wire        inst_bne;
// wire        inst_bgez;
// wire        inst_bgtz;
// wire        inst_blez;
// wire        inst_bltz;
// wire        inst_bgezal;
// wire        inst_bltzal;
// wire        inst_j;
// wire        inst_jal;
// wire        inst_jr;
// wire        inst_jalr;
// wire [5:0]  op;
// wire [4:0]  rt;
// wire [4:0]  rd;
// wire [4:0]  sa;
// wire [5:0]  func;
// wire b_or_j;


//input
wire [31: 0]    pc_i_0    ;
wire [31: 0]    pc_i_1    ;
wire [31: 0]    pd_pc_i_0 ;
wire [31: 0]    pd_pc_i_1 ;
wire [31: 0]    inst_i_0  ;
wire [31: 0]    inst_i_1  ;
wire            ex_i_0    ;
wire            ex_i_1    ;
wire [ 4: 0]    excode_i_0;
wire [ 4: 0]    excode_i_1;


wire         fifo_valid_0;
wire         fifo_valid_1;
wire         fifo_ready_go;

//to ds
wire        fifo_ex_0;
wire [4:0]  fifo_excode_0;
wire [31:0] fifo_pd_pc_0;
wire [31:0] fifo_pc_0;
wire [31:0] fifo_inst_0;
wire        fifo_ex_1;
wire [4:0]  fifo_excode_1;
wire [31:0] fifo_pd_pc_1;
wire [31:0] fifo_pc_1;
wire [31:0] fifo_inst_1;

assign {
        ex_i_0      ,
        excode_i_0  ,
        pd_pc_i_0   ,
        inst_i_0    ,
        pc_i_0      } = icache_bus_0;

assign {
        ex_i_1      ,
        excode_i_1  ,
        pd_pc_i_1   ,
        inst_i_1    ,
        pc_i_1      } = icache_bus_1;


//inst buffer size

reg [31: 0] inst        [0:`INST_BUF_SIZE-1];
reg [31: 0] pd_pc       [0:`INST_BUF_SIZE-1];
reg [31: 0] pc          [0:`INST_BUF_SIZE-1];
reg [ 4: 0] excode      [0:`INST_BUF_SIZE-1];
reg [`INST_BUF_SIZE-1 : 0] ex;
reg [`INST_BUF_SIZE-1 : 0] valid;
reg [`BUF_LEN : 0] head;
reg [`BUF_LEN : 0] tail;
reg [`BUF_LEN+1 : 0] i;
wire        full;  
// wire        empty;
assign full  = valid[tail + `BUF_LEN'b1];
// assign empty = b_or_j && !valid[head + `BUF_LEN'b1] || !b_or_j && !valid[head];//若有分支指令，至少有两条指令才发射

//EnQuene
always@(posedge clk)begin
    if(reset || ds_flush)
        tail <= 0;
    else if(valid_i_0 && valid_i_1 && !full)
        tail <= tail + `BUF_LEN'h2;
    else if(valid_i_0 && !full)
        tail <= tail + `BUF_LEN'b1;
end

always@(posedge clk)begin
    if(valid_i_0 && valid_i_1 && !full)begin
        inst[tail]                  <= inst_i_0;
        pc[tail]                    <= pc_i_0;
        pd_pc[tail]                 <= pd_pc_i_0;
        ex[tail]                    <= ex_i_0;
        excode[tail]                <= excode_i_0;

        inst[tail+`BUF_LEN'b1]      <= inst_i_1;
        pc[tail+`BUF_LEN'b1]        <= pc_i_1;
        pd_pc[tail+`BUF_LEN'b1]     <= pd_pc_i_1;
        ex[tail+`BUF_LEN'b1]        <= ex_i_1;
        excode[tail+`BUF_LEN'b1]    <= excode_i_1;
    end
    else if(valid_i_0 && !full)begin
        inst[tail]          <= inst_i_0;
        pc[tail]            <= pc_i_0;
        pd_pc[tail]         <= pd_pc_i_0;
        ex[tail]            <= ex_i_0;
        excode[tail]        <= excode_i_0;
    end
end

always@(posedge clk)begin
    if(reset || ds_flush)begin
        valid          <= 0;
    end
    else begin
        if(valid_i_0 && valid_i_1 && !full)begin
            valid[tail]                 <= 1'b1;
            valid[tail+`BUF_LEN'b1]     <= 1'b1;
        end
        else if(valid_i_0 && !full)
            valid[tail]                 <= 1'b1;
        
        if(issue_mode == `DUAL)begin
            valid[head]                 <= 1'b0;
            valid[head+ `BUF_LEN'h1]    <= 1'b0;
        end
        else if(issue_mode == `SIGNLE)
            valid[head]                 <= 1'b0;
    end
end

//issue
always@(posedge clk)begin
    if(reset || ds_flush)
        head <= 0;
    else if(issue_mode == `DUAL)
        head <= head + `BUF_LEN'h2;
    else if(issue_mode == `SIGNLE)
        head <= head + `BUF_LEN'h1;
end




// IF stage
assign fifo_valid_0         = valid[head];
assign fifo_valid_1         = valid[head + `BUF_LEN'b1];
assign fifo_allowin         = !full;
assign fifo_to_ds_valid_0   = fifo_valid_0 && !ds_flush;
assign fifo_to_ds_valid_1   = fifo_valid_1 && !ds_flush;



assign fifo_pc_0       = {32{fifo_valid_0}} & pc[head];
assign fifo_inst_0     = {32{fifo_valid_0}} & inst[head];
assign fifo_pd_pc_0    = {32{fifo_valid_0}} & pd_pc[head];
assign fifo_ex_0       = fifo_valid_0 & ex[head];
assign fifo_excode_0   = {5{fifo_valid_0}} & excode[head];

assign fifo_pc_1       = {32{fifo_valid_1}} & pc[head + `BUF_LEN'b1];
assign fifo_inst_1     = {32{fifo_valid_1}} & inst[head + `BUF_LEN'b1];
assign fifo_pd_pc_1    = {32{fifo_valid_1}} & pd_pc[head + `BUF_LEN'b1];
assign fifo_ex_1       = fifo_valid_1 & ex[head + `BUF_LEN'b1];
assign fifo_excode_1   = {5{fifo_valid_1}} & excode[head + `BUF_LEN'b1];


// assign op   = fifo_inst[31:26];
// assign rt   = fifo_inst[20:16];
// assign rd   = fifo_inst[15:11];
// assign sa   = fifo_inst[10: 6];
// assign func = fifo_inst[ 5: 0];

// assign inst_beq     = (op == 6'b000100);
// assign inst_bne     = (op == 6'b000101);
// assign inst_bgez    = (op == 6'b000001) && (rt == 5'b00001);
// assign inst_bgtz    = (op == 6'b000111) && (rt == 5'b00000);
// assign inst_blez    = (op == 6'b000110) && (rt == 5'b00000);
// assign inst_bltz    = (op == 6'b000001) && (rt == 5'b00000);
// assign inst_bgezal  = (op == 6'b000001) && (rt == 5'b10001);
// assign inst_bltzal  = (op == 6'b000001) && (rt == 5'b10000);
// assign inst_j       = (op == 6'b000010);
// assign inst_jal     = (op == 6'b000011);
// assign inst_jr      = (op == 6'b000000) && (rt == 5'b00000) && (rd == 5'b00000) && (sa == 5'b00000) && (func == 6'b001000);
// assign inst_jalr    = (op == 6'b000000) && (rt == 5'b00000) && (sa == 5'b00000) && (func == 6'b001001);


// assign b_or_j = fifo_valid && (inst_beq || inst_bne || inst_bgez || inst_bgtz || inst_blez || inst_bltz 
//               || inst_bgezal || inst_bltzal || inst_j || inst_jal || inst_jr || inst_jalr);



assign fifo_to_ds_bus_0 = {
                        fifo_ex_0      , //101
                        fifo_excode_0  , //100:96
                        fifo_pd_pc_0   , //95:64
                        fifo_inst_0    , //63:32
                        fifo_pc_0        //31:0
                        };

assign fifo_to_ds_bus_1 = {
                        fifo_ex_1      , //101
                        fifo_excode_1  , //100:96
                        fifo_pd_pc_1   , //95:64
                        fifo_inst_1    , //63:32
                        fifo_pc_1        //31:0
                        };

endmodule




 













