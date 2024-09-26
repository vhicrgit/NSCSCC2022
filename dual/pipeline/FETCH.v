`include "../mycpu.h"


module fetch(
    input               clk             ,
    input               reset           ,
    // from bht
    input     [31:0]    pd_pc0_i        ,
    input     [31:0]    pd_pc1_i        ,
    input     [1:0]     br_flag         ,
    // from hazard
    input               flush           ,
    // from f1s
    input     [31:0]    inst_pc         ,
    input               inst_req        ,
    
    input               ex0_i           ,
    input     [4:0]     ex_code0_i      ,
    input               ex1_i           ,
    input     [4:0]     ex_code1_i      ,
    // to f1s
    output    [31:0]    seq_pc          ,
    output              inst_addr_ok    ,
    // to f2s
    output   [`CACHE_TO_FIFO_WD-1 :0]   icache_bus_0  ,
    output   [`CACHE_TO_FIFO_WD-1 :0]   icache_bus_1  ,
    output   [1:0]      inst_rdata_valid,        


    // to axi
    input               rd_rdy          ,
    output              rd_req          ,
    output    [2:0]     rd_type         ,
    output    [31:0]    rd_addr         ,
    input               ret_valid       ,
    input               ret_last        ,
    input     [31:0]    ret_data
);

reg         icache_is_busy;

reg         ex0_o;
reg [4:0]   ex0_code_o;
reg         ex1_o;
reg         ex1_code_o;
reg [31:0]  pd_pc0_o;
reg [31:0]  pd_pc1_o;
reg [31:0]  pc0_o;
reg [31:0]  pc1_o;

wire   inst0_valid;
wire   inst1_valid;

wire   [31:0]   inst_rdata0;
wire   [31:0]   inst_rdata1;
wire   [31:0]   inst0;
wire   [31:0]   inst1;

reg   inst0_valid_en;
reg   inst1_valid_en;

wire   inst_icache_edge;

reg    [1:0]    INST_FETCH_STATE;
reg    [1:0]    INST_UNCACHE_STATE;

reg    [31:0]   branch_dest_cached;
reg    [31:0]   branch_dest_uncache;
wire   [31:0]   icache_pc;
reg    [31:0]   npc;

wire            addr_ok;

// address space
wire        kuseg;
wire        kseg0;
wire        kseg1;
wire        kseg2;
wire        kseg3;
wire        inst_uncache;
wire        inst_cache;

// flush
reg         inst_flush;


assign icache_bus_0 = {
       ex0_o ,
       ex0_code_o,
       pd_pc0_o,
       inst_rdata0,
       pc0_o
};

assign icache_bus_1 = {
       ex1_o ,      //101
       ex1_code_o,  //100:96
       pd_pc1_o,    //95:64
       inst_rdata1, //63:32
       pc1_o        //31:0
};

assign      seq_pc     = npc;

assign inst_icache_edge = (inst_pc[4:2] == 3'b111) ;

// assign kuseg = (inst_pc[31:28] < 4'h8);
assign kseg0 = (inst_pc[31:28] >= 4'h8) && (inst_pc[31:28] < 4'ha);
assign kseg1 = (inst_pc[31:28] >= 4'ha) && (inst_pc[31:28] < 4'hc);
// assign kseg2 = (inst_pc[31:28] >= 4'hc) && (inst_pc[31:28] < 4'he);
// assign kseg3 = (inst_pc[31:28] >= 4'he);
// assign kseg01 = inst_pc[31:30] == 2'b10;

assign inst_uncache  = kseg1;
assign inst_cache    = ~inst_uncache;
assign icache_pc     = (kseg0 || kseg1) ?  {3'd0,inst_pc[28:0]} : inst_pc[31:0];


always@(posedge clk)begin
    if(reset)begin
        ex0_o <= 1'b0;
        ex0_code_o <= 0; 
        ex1_o <= 1'b0;
        ex1_code_o <= 0;
        pd_pc0_o <= 0;
        pd_pc1_o <= 0;
        pc0_o <= 0;
        pc1_o <= 0;
    end
    else begin
        ex0_o <= ex0_i;
        ex0_code_o <= ex_code0_i; 
        ex1_o <= ex1_i;
        ex1_code_o <= ex_code1_i;
        pd_pc0_o <= pd_pc0_i;
        pd_pc1_o <= pd_pc1_i;
        pc0_o <= inst_pc;
        pc1_o <= inst_pc + 4; 
    end
end

always@(posedge clk)begin
    if(reset)begin
        icache_is_busy <= 1'b0;
    end
    else if(inst_req & ~icache_is_busy & ~flush & ~ex0_i & addr_ok)begin
        icache_is_busy <= 1'b1;
    end
    else if(icache_is_busy & inst0_valid)begin
        icache_is_busy <= 1'b0;
    end
end

always@(posedge clk)begin
    if(reset)begin
        inst_flush <= 1'b0;
    end
    else if(~inst_flush)begin
        if(flush & icache_is_busy & ~inst0_valid)begin
            inst_flush <= 1'b1;
        end
    end
    else if(inst_flush)begin
        if(inst0_valid)begin
            inst_flush <= 1'b0;
        end
    end
end


assign  inst_rdata_valid[0] = (inst0_valid & inst0_valid_en | ex0_i) & ~flush & ~inst_flush;
assign  inst_rdata_valid[1] = inst1_valid & inst1_valid_en & ~flush & ~inst_flush;

assign  inst_addr_ok = addr_ok | (ex0_i & ~flush  & ~inst_flush); 

assign  inst_rdata0  = ex0_i & ~flush  & ~inst_flush ? 32'h0 : inst0;
assign  inst_rdata1  = inst1;



always@(posedge clk)begin
    if(reset | flush)begin
        INST_FETCH_STATE <= `FETCH_NORMAL;
    end
    else if(inst0_valid & inst_cache & ~inst_flush) begin
        case(INST_FETCH_STATE)
            `FETCH_NORMAL:begin
                if(br_flag[0] & inst_icache_edge)begin
                    INST_FETCH_STATE <= `FETCH_ONE_MORE;
                    branch_dest_cached <= pd_pc0_i;
                end
                else if(br_flag[1] & ~inst_icache_edge)begin
                    INST_FETCH_STATE <= `FETCH_ONE_MORE;
                    branch_dest_cached   <= pd_pc1_i;
                end
                else if(br_flag[1] & inst_icache_edge)begin
                    INST_FETCH_STATE <= `FETCH_TWO_MORE;
                    branch_dest_cached   <= pd_pc1_i;
                end
            end
            `FETCH_ONE_MORE:begin
                INST_FETCH_STATE <= `FETCH_NORMAL; 
            end
            `FETCH_TWO_MORE:begin
                if(inst_icache_edge)begin
                    INST_FETCH_STATE <= `FETCH_ONE_MORE;
                end
                else begin
                    INST_FETCH_STATE <= `FETCH_NORMAL;
                end
            end
        endcase
    end
end

always@(posedge clk)begin
    if(reset | flush)begin
        INST_UNCACHE_STATE <= `GET_NEXT;
    end
    else if(inst0_valid & inst_uncache & ~inst_flush)begin
        case(INST_UNCACHE_STATE)
            `GET_NEXT:begin
                if(br_flag[0])begin
                    INST_UNCACHE_STATE <= `GET_DELAY_SLOT;
                    branch_dest_uncache <= pd_pc0_i;
                end
                else begin
                    INST_UNCACHE_STATE <= `GET_NEXT;
                end
            end
            `GET_DELAY_SLOT:begin
                INST_UNCACHE_STATE <= `GET_BRANCH_TARGET;
            end
            `GET_BRANCH_TARGET:begin
                if(br_flag[0])begin
                    INST_UNCACHE_STATE <= `GET_DELAY_SLOT;
                    branch_dest_uncache <= pd_pc0_i;
                end
                else begin
                    INST_UNCACHE_STATE <= `GET_NEXT;
                end
            end
        endcase
    end
end

always@(*)begin
    if(inst_cache)begin
        if(ex0_i & ~inst_flush)begin
            inst0_valid_en = 1'b1;
            inst1_valid_en = 1'b0;
            npc            = inst_pc + 4;
        end
        else begin
                if(inst0_valid & ~inst_flush & ~flush)begin
                case(INST_FETCH_STATE)
                `FETCH_NORMAL:begin
                    if(inst_icache_edge)begin
                        inst0_valid_en = 1'b1;
                        inst1_valid_en = 1'b0;
                        npc   = inst_pc + 4;
                    end
                    else begin
                        if(br_flag[0])begin
                            npc = pd_pc0_i;
                        end
                        else begin
                            npc = inst_pc + 8;
                        end
                        inst0_valid_en = 1'b1;
                        inst1_valid_en = 1'b1;
                    end
                end
                `FETCH_ONE_MORE:begin
                    npc = branch_dest_cached;
                    inst0_valid_en = 1'b1;
                    inst1_valid_en = 1'b0;
                end
                `FETCH_TWO_MORE:begin
                    if(inst_icache_edge)begin
                        npc  = inst_pc + 4;
                        inst0_valid_en = 1'b1;
                        inst1_valid_en = 1'b0;
                    end
                    else begin
                        npc = branch_dest_cached;
                        inst0_valid_en = 1'b1;
                        inst1_valid_en = 1'b1;
                    end
                end
                default:begin
                    npc = inst_pc;
                    inst0_valid_en = 1'b1;
                    inst1_valid_en = 1'b1;
                end
                endcase
            end
            else begin
                npc = inst_pc;
                inst0_valid_en = 1'b1;
                inst1_valid_en = 1'b1;
            end 
        end
    end 
    else begin
        if(ex0_i & ~inst_flush)begin
            inst0_valid_en = 1'b1;
            inst1_valid_en = 1'b0;
            npc            = inst_pc + 4;
        end
        else begin
            if(inst0_valid & ~inst_flush & ~flush)begin
                inst0_valid_en = 1'b1;
                inst1_valid_en = 1'b0;
                case(INST_UNCACHE_STATE)
                    `GET_NEXT:begin
                        npc = inst_pc + 4;                
                    end
                    `GET_DELAY_SLOT:begin
                        npc = branch_dest_uncache;
                    end
                    `GET_BRANCH_TARGET:begin
                        npc = inst_pc + 4;
                    end 
                    default:begin
                        npc = inst_pc + 4;
                    end
                endcase
                end
            else begin
                npc = inst_pc;
                inst0_valid_en = 1'b1;
                inst1_valid_en = 1'b0;
            end       
        end
    end   
end

//  TLB


//  ICache

icache icache_t(
        .clk(clk),
        .reset(reset),

        .valid(inst_req & ~icache_is_busy & ~flush & ~ex0_i),
        .index(icache_pc[12:5]),
        .tag(icache_pc[31:13]),
        .offset(icache_pc[4:0]),

        .addr_ok(addr_ok),

        .inst_rdata1_ok(inst0_valid),
        .inst_rdata2_ok(inst1_valid),
        .inst_rdata1(inst0),
        .inst_rdata2(inst1),
        .is_uncache(inst_uncache),

        .rd_rdy(rd_rdy),
        .rd_req(rd_req),
        .rd_type(rd_type),
        .rd_addr(rd_addr),
        .ret_valid(ret_valid),
        .ret_last(ret_last),
        .ret_data(ret_data)
);



endmodule