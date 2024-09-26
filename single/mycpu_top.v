`include "mycpu.h"
module mycpu_top(
    input                               aclk,
    input                               aresetn,
    input        [5:0]                  ext_int,
    // axi interface
    // ar
    output       [3 :0]                 arid   ,
    output       [31:0]                 araddr ,
    output       [7 :0]                 arlen  ,
    output       [2 :0]                 arsize ,
    output       [1 :0]                 arburst,
    output       [1 :0]                 arlock ,
    output       [3 :0]                 arcache,
    output       [2 :0]                 arprot ,
    output                              arvalid,
    input                               arready,

    //r
    input       [3 :0]                  rid    ,
    input       [31:0]                  rdata  ,
    input       [1 :0]                  rresp  ,
    input                               rlast  ,
    input                               rvalid ,
    output                              rready ,

    //aw
    output       [3 :0]                  awid   ,
    output       [31:0]                  awaddr ,
    output       [7 :0]                  awlen  ,
    output       [2 :0]                  awsize ,
    output       [1 :0]                  awburst,
    output       [1 :0]                  awlock ,
    output       [3 :0]                  awcache,
    output       [2 :0]                  awprot ,
    output                               awvalid,
    input                                awready,

    //w
    output       [3 :0]                  wid    ,
    output       [31:0]                  wdata  ,
    output       [3 :0]                  wstrb  ,
    output                               wlast  ,
    output                               wvalid ,
    input                                wready ,

    //b
    input       [3 :0]                  bid    ,
    input       [1 :0]                  bresp  ,
    input                               bvalid ,
    output                              bready ,

    //debug interface
    output   [31:0] debug_wb_pc      ,
    output   [3:0]  debug_wb_rf_wen  ,
    output   [4:0]  debug_wb_rf_wnum ,
    output   [31:0] debug_wb_rf_wdata
);

    // inst 
    wire          inst_sram_req    ;
    wire          inst_sram_wr     ;
    wire   [1:0]  inst_sram_size   ;
    wire   [3:0]  inst_sram_wstrb  ;
    wire   [31:0] inst_sram_addr   ;
    wire   [31:0] inst_sram_wdata  ;
    wire          inst_sram_addr_ok;
    wire          inst_sram_data_ok;
    wire   [31:0] inst_sram_rdata  ;
    wire          inst_uncache     ;
    // data
    wire          data_sram_req    ;
    wire          data_sram_wr     ;
    wire   [1:0]  data_sram_size   ;
    wire   [3:0]  data_sram_wstrb  ;
    wire   [31:0] data_sram_addr   ;
    wire   [31:0] data_sram_wdata  ;
    wire          data_sram_addr_ok;
    wire          data_sram_data_ok;
    wire   [31:0] data_sram_rdata  ;
    wire          data_uncache     ;




wire         areset;
assign areset = ~aresetn;

wire         b_or_j;
wire         f2s_allowin;
wire         ds_allowin;
wire         es_allowin;
wire         m1s_allowin;
wire         m2s_allowin;
wire         ws_allowin;
wire         f1s_to_f2s_valid;
wire         f2s_to_ds_valid;
wire         ds_to_es_valid;
wire         es_to_m1s_valid;
wire         m1s_to_m2s_valid;
wire         m2s_to_ws_valid;
wire [`F1S_TO_F2S_BUS_WD -1:0] f1s_to_f2s_bus;
wire [`F2S_TO_DS_BUS_WD -1:0 ] f2s_to_ds_bus;
wire [`DS_TO_ES_BUS_WD -1:0  ] ds_to_es_bus;
wire [`ES_TO_M1S_BUS_WD -1:0 ] es_to_m1s_bus;
wire [`M1S_TO_M2S_BUS_WD -1:0] m1s_to_m2s_bus;
wire [`M2S_TO_WS_BUS_WD -1:0 ] m2s_to_ws_bus;
wire [`WS_TO_RF_BUS_WD -1:0  ] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0  ] br_bus;

wire        f2s_ready_go;
wire        ds_ready_go;
wire        m1s_ready_go;
wire        m2s_ready_go;
wire        ws_ready_go;

wire [31:0] f2s_pc;
wire [31:0] ds_pc;
wire [31:0] es_pc;
wire        m2s_res_from_mem_ok;

//================================= reg file  ==============================
wire [4:0] rf_raddr1;
wire [31:0] rf_rdata1;
wire [4:0] rf_raddr2;
wire [31:0] rf_rdata2;
wire [3 :0] rf_we;
wire [4 :0] rf_waddr;
wire [31:0] rf_wdata;

//================================= forwarding =============================
wire [1:0] alu_src1_fwd;
wire [1:0] alu_src2_fwd;
wire [4:0] es_rs1;
wire [4:0] es_rs2;
wire [4:0] m1s_rd;
wire [4:0] m2s_rd;
wire [4:0] ws_rd;
wire m1s_reg_write;
wire m2s_reg_write;
wire ws_reg_write;
wire [1:0] fwd1;
wire [1:0] fwd2;
wire [31:0] m1s_alu_result;
wire [31:0] m2s_alu_result;
wire [31:0] ws_final_result;
wire [3: 0] ws_rf_wen;
wire [3: 0] fwd1_wen;
wire [3: 0] fwd2_wen;
wire [3: 0] alu1_fwd_wen;
wire [3: 0] alu2_fwd_wen;


wire [`WS_FWD_BUS-1  :0] ws_fwd_bus_1;
wire [`WS_FWD_BUS-1  :0] ws_fwd_bus_2;
wire [`M1S_FWD_BUS-1 :0] m1s_fwd_bus_1;
wire [`M1S_FWD_BUS-1 :0] m1s_fwd_bus_2;
wire [`M2S_FWD_BUS-1 :0] m2s_fwd_bus_1;
wire [`M2S_FWD_BUS-1 :0] m2s_fwd_bus_2;
//================================== hazard ===============================
wire [4:0] ds_rs1;
wire [4:0] ds_rs2;
wire [4:0] es_rd;
wire es_mem_read;
wire m1s_mem_read;
wire m2s_mem_read;
wire es_res_from_cp0;
wire m1s_res_from_cp0;
wire m2s_res_from_cp0;
wire f1s_stall;
wire f2s_stall;
wire ds_stall;
wire es_stall;
wire m1s_stall;
wire m2s_stall;
wire ws_stall;
wire f1s_flush;
wire f2s_flush;
wire ds_flush;
wire es_flush;
wire m1s_flush;
wire m2s_flush;
wire ws_flush;
wire exc_flushl;
wire br;
wire div_block;

wire ds_valid;
wire es_valid;
wire m1s_valid;
wire m2s_valid;
wire ws_valid;

//===========================  CP0 regfile =========================
wire [31:0] cp0_wdata  ;
wire [ 7:0] cp0_addr   ;
wire [31:0] cp0_rdata  ;
wire [31:0] m2s_pc      ;
wire [ 4:0] m2s_excode  ;
wire        m2s_mtc0_we ;
wire        m2s_ex      ;
wire        m2s_bd      ;
wire        m2s_eret_flush ;
wire [31:0] epc        ;
wire [31:0] m2s_badvaddr;
wire        has_int     ;

wire        config_kseg0;
wire        m1s_ex;







//=========================== cache =============================
//Dcache interface
wire                   dcache_rd_req   ;
wire     [2:0]         dcache_rd_type  ;
wire     [31:0]        dcache_rd_addr  ;
wire                   dcache_rd_rdy   ;
wire                   dcache_ret_valid;
wire                   dcache_ret_last ;
wire    [31:0]         dcache_ret_data ;
 // w
wire                   dcache_wr_req   ;
wire     [2:0]         dcache_wr_type  ;
wire     [31:0]        dcache_wr_addr  ;
wire     [3:0]         dcache_wr_wstrb ;
wire     [127:0]       dcache_wr_data  ;
wire                   dcache_wr_rdy   ;
 //Icache interface
 // r
wire                   icache_rd_req   ;
wire     [2:0]         icache_rd_type  ;
wire     [31:0]        icache_rd_addr  ;
wire                   icache_rd_rdy   ;
wire                   icache_ret_valid;
wire                   icache_ret_last ;
wire    [31:0]         icache_ret_data ;
 // w
wire                   icache_wr_req   ;
wire     [2:0]         icache_wr_type  ;
wire     [31:0]        icache_wr_addr  ;
wire     [3:0]         icache_wr_wstrb ;
wire     [127:0]       icache_wr_data  ;
wire                   icache_wr_rdy   ;

//=========================== BHT =====================
wire                   es_b_or_j;
wire                   pd_true  ;
wire [31:0]            pd_pc    ;   

// IF1 stage
if1_stage if1_stage(
    .clk                (aclk               ),
    .reset              (areset             ),
    //from f2s
    .b_or_j             (b_or_j             ),
    .f2s_pc             (f2s_pc             ),
    .f2s_allowin        (f2s_allowin       ),
    //brbus
    .br_bus             (br_bus             ),
    .es_pc              (es_pc              ),
    //to f2s
    .f1s_to_f2s_valid   (f1s_to_f2s_valid  ),
    .f1s_to_f2s_bus     (f1s_to_f2s_bus    ),
    //from hazard
    .f2s_flush          (f2s_flush           ),
    .f1s_stall          (f1s_stall           ),
    // inst sram interface
    .inst_sram_req      (inst_sram_req      ),
    .inst_sram_wr       (inst_sram_wr       ),
    .inst_sram_size     (inst_sram_size     ),
    .inst_sram_wstrb    (inst_sram_wstrb    ),
    .inst_sram_addr     (inst_sram_addr     ),
    .inst_sram_wdata    (inst_sram_wdata    ),
    .inst_sram_addr_ok  (inst_sram_addr_ok  ),
    .inst_uncache       (inst_uncache       ),
    //eret
    .ex_taken           (m2s_ex             ),
    .epc                (epc                ),
    .eret_taken         (m2s_eret_flush     ),
    //from BHT
    .pd_pc              (pd_pc              ),

    //address space
    .config_kseg0       (config_kseg0       ) 
);

// IF2_FIFO IF2_FIFO(
//     .clk                (aclk               ),
//     .reset              (areset             ),
//     //from IF1
//     .f1s_to_FIFO_bus    (f1s_to_FIFO_bus    ),
//     .f1s_to_FIFO_valid  (f1s_to_FIFO_valid  ),
//     //to IF2
//     .FIFO_to_f2s_bus    (FIFO_to_f2s_bus    ),
//     .FIFO_to_f2s_valid  (FIFO_to_f2s_valid  ),
//     .FIFO_ready_go      (FIFO_ready_go      ),
//     //from IF2
//     .ds_allowin         (ds_allowin         ),
//     .f2s_stall          (f2s_stall          ),
//     .f2s_flush          (f2s_flush          ),
//     //to IF1
//     .FIFO_allowin       (FIFO_allowin       ),
//     //from ID
//     .br_prd_err         (br_bus[32]         ),
//     .es_pc              (es_pc              ),
//     // inst sram interface
//     .inst_sram_data_ok  (inst_sram_data_ok  ),
//     .inst_sram_rdata    (inst_sram_rdata    )
//     );


// IF2 stage
if2_stage if2_stage(
    .clk                (aclk               ),
    .reset              (areset             ),
    //from ds
    .ds_allowin         (ds_allowin         ),
    //from FIFO
    .f1s_to_f2s_valid   (f1s_to_f2s_valid   ),
    .f1s_to_f2s_bus     (f1s_to_f2s_bus     ),
    //to f1s
    .f2s_allowin        (f2s_allowin        ),
    .f2s_pc             (f2s_pc             ),
    .b_or_j             (b_or_j             ),
    //to ds
    .f2s_to_ds_valid    (f2s_to_ds_valid    ),
    .f2s_to_ds_bus      (f2s_to_ds_bus      ),
    //from es
    .br_prd_err         (br_bus[32]         ),
    .es_pc              (es_pc              ),
    //from hazard
    .f2s_flush          (f2s_flush          ),
    .ds_flush           (ds_flush           ),
    .f2s_stall          (f2s_stall          ),
    //from BHT
    .f2s_pd_pc          (pd_pc              ),
    // inst sram interface
    .inst_sram_data_ok  (inst_sram_data_ok  ),
    .inst_sram_rdata    (inst_sram_rdata    )
);


BHT BHT(
    .clk        (aclk           ),
    .rst        (areset         ),

    .pc_query   (f2s_pc         ),
    .pred_target(pd_pc          ),

    .br_pc      (es_pc          ),
    .br_target  (br_bus[31:0]   ), 
    .br_update  (br_bus[32]     ),
    .br_is      (es_b_or_j      )
);


// ID stage
id_stage id_stage(
    .clk            (aclk            ),
    .reset          (areset          ),
    //allowin
    .es_allowin     (es_allowin     ),
    .ds_allowin     (ds_allowin     ),
    //to f1s
    .ds_pc          (ds_pc          ),
    //from f2s
    .f2s_to_ds_valid(f2s_to_ds_valid ),
    .f2s_to_ds_bus  (f2s_to_ds_bus   ),
    //to es
    .ds_to_es_valid (ds_to_es_valid ),
    .ds_to_es_bus   (ds_to_es_bus   ),
    //to pre-fs
    .ds_ready_go    (ds_ready_go    ),
    //to regfile
    .rf_raddr1      (rf_raddr1      ),
    .rf_rdata1      (rf_rdata1      ),
    .rf_raddr2      (rf_raddr2      ),
    .rf_rdata2      (rf_rdata2      ),
    //from forwarding
    .m1s_valid          (m1s_fwd_bus_1[38]),
    .m1s_reg_write      (m1s_fwd_bus_1[37]),
    .m1s_rd             (m1s_fwd_bus_1[36:32]),
    .m1s_alu_result     (m1s_fwd_bus_1[31:0]),
    .m2s_valid          (m2s_fwd_bus_1[38]),
    .m2s_reg_write      (m2s_fwd_bus_1[37]),
    .m2s_rd             (m2s_fwd_bus_1[36:32]),
    .m2s_alu_result     (m2s_fwd_bus_1[31:0]),
    .ws_valid           (ws_fwd_bus_1[42]),
    .ws_rf_wen          (ws_fwd_bus_1[41:38]),
    .ws_reg_write       (ws_fwd_bus_1[37] ),
    .ws_rd              (ws_fwd_bus_1[36:32]),
    .ws_final_result    (ws_fwd_bus_1[31:0]),
    //to forwarding
    .br             (br             ),
    .ds_valid       (ds_valid       ),
    .ds_rs1         (ds_rs1         ),
    .ds_rs2         (ds_rs2         ),
    //from hazard
    .es_flush       (es_flush       ),
    .ds_stall       (ds_stall       ),
    //to hazard
    .br_taken       (br_taken       ),
    //to BHT
    //from cp0
    .has_int        (has_int        )
);

regfile u_regfile(
    .clk    (aclk      ),
    .raddr1 (rf_raddr1),
    .rdata1 (rf_rdata1),
    .raddr2 (rf_raddr2),
    .rdata2 (rf_rdata2),
    .we     (rf_we    ),
    .waddr  (rf_waddr ),
    .wdata  (rf_wdata )
    );

    
// EXE stage
exe_stage exe_stage(
    .clk                (aclk               ),
    .reset              (areset             ),
    //allowin
    .m1s_allowin        (m1s_allowin         ),
    .es_allowin         (es_allowin         ),
    //from ds
    .ds_to_es_valid     (ds_to_es_valid     ),
    .ds_to_es_bus       (ds_to_es_bus       ),
    //to m1s
    .es_to_m1s_valid     (es_to_m1s_valid     ),
    .es_to_m1s_bus       (es_to_m1s_bus       ),
    //from m1s
    .m1s_ex             (m1s_ex               ),
    //from m2s
    .ex_taken           (m2s_ex              ),
    //to forwarding
    .es_rs1             (es_rs1             ),
    .es_rs2             (es_rs2             ),
    .es_rd              (es_rd              ),
    //from forwarding
    // .alu_src1_fwd       (alu_src1_fwd       ),
    // .alu_src2_fwd       (alu_src2_fwd       ),
    // .alu1_fwd_wen       (alu1_fwd_wen       ),
    // .alu2_fwd_wen       (alu2_fwd_wen       ),
    .m1s_valid          (m1s_fwd_bus_2[38]),
    .m1s_reg_write      (m1s_fwd_bus_2[37]),
    .m1s_rd             (m1s_fwd_bus_2[36:32]),
    .m1s_alu_result     (m1s_fwd_bus_2[31:0]),
    .m2s_valid          (m2s_fwd_bus_2[38]),
    .m2s_reg_write      (m2s_fwd_bus_2[37]),
    .m2s_rd             (m2s_fwd_bus_2[36:32]),
    .m2s_alu_result     (m2s_fwd_bus_2[31:0]),
    .ws_valid           (ws_fwd_bus_2[42]),
    .ws_rf_wen          (ws_fwd_bus_2[41:38]),
    .ws_reg_write       (ws_fwd_bus_2[37] ),
    .ws_rd              (ws_fwd_bus_2[36:32]),
    .ws_final_result    (ws_fwd_bus_2[31:0]),
    //from hazard
    .es_flush           (es_flush           ),
    .m1s_flush          (m1s_flush          ),
    .es_stall           (es_stall           ),
    .es_reg_write       (es_reg_write       ),
    //to hazard
    .es_res_from_mem    (es_mem_read        ),
    .exc_flush          (exc_flush          ),
    .es_res_from_cp0    (es_res_from_cp0    ),
    .es_valid           (es_valid           ),
    .div_block          (div_block          ),
    //br_bus
    .es_br_bus          (br_bus             ),
    .es_b_or_j          (es_b_or_j          ),
    .es_pc              (es_pc              ),
    
    
    .ws_ready_go        (ws_ready_go        ),
    .ws_allowin         (ws_allowin         ),


    //address space
    .config_kseg0       (config_kseg0       )

);



// MEM1 stage
mem1_stage mem1_stage(
    .clk            (aclk            ),
    .reset          (areset          ),
    //allowin
    .m2s_allowin     (m2s_allowin     ),
    .m1s_allowin     (m1s_allowin     ),
    //from es
    .es_to_m1s_valid (es_to_m1s_valid ),
    .es_to_m1s_bus   (es_to_m1s_bus   ),
    //to es
    .m1s_ex          (m1s_ex          ),
    //to m2s
    .m1s_to_m2s_valid (m1s_to_m2s_valid ),
    .m1s_to_m2s_bus   (m1s_to_m2s_bus   ),
    //from m2s
    .ex_taken           (m2s_ex        ),
    .eret_taken         (m2s_eret_flush),
    //to forwarding
    .m1s_rd          (m1s_rd          ),
    .m1s_alu_result  (m1s_alu_result  ),
    .m1s_reg_write   (m1s_reg_write   ),
    .m1s_fwd_bus_1   (m1s_fwd_bus_1   ),
    .m1s_fwd_bus_2   (m1s_fwd_bus_2   ),
    //from hazard
    .m2s_flush       (m2s_flush       ),
    .m1s_stall       (m1s_stall       ),
    //to hazard
    .m1s_res_from_mem(m1s_mem_read      ),
    .m1s_res_from_cp0(m1s_res_from_cp0  ),
    .m1s_valid       (m1s_valid         ),
    .m1s_ready_go    (m1s_ready_go      ),     
    // data sram interface
    .data_sram_req      (data_sram_req      ),
    .data_sram_wr       (data_sram_wr       ),
    .data_sram_size     (data_sram_size     ),
    .data_sram_wstrb    (data_sram_wstrb    ),
    .data_sram_addr     (data_sram_addr     ),
    .data_sram_wdata    (data_sram_wdata    ),
    .data_sram_addr_ok  (data_sram_addr_ok  ),
    .data_uncache       (data_uncache       )

         
);

// MEM2 stage
mem2_stage mem2_stage(
    .clk            (aclk            ),
    .reset          (areset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    .m2s_allowin     (m2s_allowin     ),
    //from m1s
    .m1s_to_m2s_valid (m1s_to_m2s_valid ),
    .m1s_to_m2s_bus   (m1s_to_m2s_bus   ),
    //to ws
    .m2s_to_ws_valid (m2s_to_ws_valid ),
    .m2s_to_ws_bus   (m2s_to_ws_bus   ),
    //to forwarding
    .m2s_rd          (m2s_rd          ),
    .m2s_alu_result  (m2s_alu_result  ),
    .m2s_reg_write   (m2s_reg_write   ),
    .m2s_fwd_bus_1   (m2s_fwd_bus_1   ),
    .m2s_fwd_bus_2   (m2s_fwd_bus_2   ),
    //from hazard
    .ws_flush       (ws_flush       ),
    .m2s_stall       (m2s_stall       ),
    .m2s_res_from_cp0(m2s_res_from_cp0),
    //from data-sram
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata(data_sram_rdata)  ,
    //to hazard
    .m2s_res_from_mem(m2s_mem_read    ),
    .m2s_valid       (m2s_valid       ) ,
    .m2s_res_from_mem_ok(m2s_res_from_mem_ok),
    //CP0-regfile
    .m2s_cp0_wdata           (cp0_wdata  ),
    .m2s_cp0_rdata           (cp0_rdata  ),
    .m2s_cp0_addr            (cp0_addr   ),
    .m2s_mtc0_we             (m2s_mtc0_we ),
    .m2s_ex                  (m2s_ex      ),
    .m2s_bd                  (m2s_bd      ),
    .m2s_pc                  (m2s_pc      ),
    .m2s_excode              (m2s_excode  ),
    .m2s_eret_flush          (m2s_eret_flush ),
    .m2s_badvaddr            (m2s_badvaddr) ,

    .m2s_ready_go    (m2s_ready_go)      
);




// WB stage
wb_stage wb_stage(
    .clk            (aclk            ),
    .reset          (areset          ),
    //allowin
    .ws_allowin     (ws_allowin     ),
    //from m2s
    .m2s_to_ws_valid (m2s_to_ws_valid ),
    .m2s_to_ws_bus   (m2s_to_ws_bus   ),
    //to rf: for write back
    .ws_to_rf_bus   ({ rf_we   ,
                       rf_waddr,
                       rf_wdata
                      }  ),
    //from hazard
    .ws_stall       (ws_stall       ),
    //to forwarding
    .ws_rd          (ws_rd          ),
    .ws_fwd_bus_1   (ws_fwd_bus_1   ),
    .ws_fwd_bus_2   (ws_fwd_bus_2   ),
    .ws_final_result(ws_final_result),
    .ws_reg_write   (ws_reg_write   ),
    .ws_valid       (ws_valid       ),
    .ws_rf_wen      (ws_rf_wen      ),
    //trace debug interface
    .debug_wb_pc      (debug_wb_pc      ),
    .debug_wb_rf_wen  (debug_wb_rf_wen  ),
    .debug_wb_rf_wnum (debug_wb_rf_wnum ),
    .debug_wb_rf_wdata(debug_wb_rf_wdata),

    .ws_ready_go         (ws_ready_go)
);



// forwarding forwarding(
//     //from ds
//     .ds_rs1                 (ds_rs1         ),
//     .ds_rs2                 (ds_rs2         ),
//     //from es
//     .es_rs1                 (es_rs1         ),
//     .es_rs2                 (es_rs2         ),
//     //from m1s
//     .m1s_rd                 (m1s_rd          ),
//     .m1s_reg_write          (m1s_reg_write   ),
//     //from m2s
//     .m2s_rd                 (m2s_rd          ),
//     .m2s_reg_write          (m2s_reg_write   ),
//     //from ws
//     .ws_rd                  (ws_rd          ),
//     .ws_reg_write           (ws_reg_write   ),
//     .ws_rf_wen              (ws_rf_wen      ),
//     //to ds
//     .fwd1                   (fwd1           ),
//     .fwd2                   (fwd2           ),
//     .fwd1_wen               (fwd1_wen       ),
//     .fwd2_wen               (fwd2_wen       ),
//     //to es
//     .alu_src1_fwd           (alu_src1_fwd   ),
//     .alu_src2_fwd           (alu_src2_fwd   ),
//     .alu1_fwd_wen           (alu1_fwd_wen   ),
//     .alu2_fwd_wen           (alu2_fwd_wen   ),

//     .ds_valid               (ds_valid       ),
//     .es_valid               (es_valid       ),
//     .m1s_valid              (m1s_valid       ),
//     .m2s_valid              (m2s_valid       ),
//     .ws_valid               (ws_valid       )
// );

hazard hazard(
    //from ds
    .ds_rs1                 (ds_rs1         ),
    .ds_rs2                 (ds_rs2         ),
    .br                     (br             ),
    //from es 
    .es_rd                  (es_rd          ),
    .es_rs                  (es_rs1         ),
    .es_rt                  (es_rs2         ),
    .es_mem_read            (es_mem_read    ),
    .es_reg_write           (es_reg_write   ),
    .es_res_from_cp0        (es_res_from_cp0),
    .div_block              (div_block      ),
    //from m1s
    .m1s_mem_read            (m1s_mem_read    ),
    .m1s_reg_write           (m1s_reg_write   ),
    .m1s_rd                  (m1s_rd          ),
    .m1s_res_from_cp0        (m1s_res_from_cp0),
    //from m2s
    .m2s_mem_read            (m2s_mem_read    ),
    .m2s_reg_write           (m2s_reg_write   ),
    .m2s_rd                  (m2s_rd          ),
    .m2s_res_from_cp0        (m2s_res_from_cp0),
    .m2s_res_from_mem_ok     (m2s_res_from_mem_ok),
    .m2s_ex                  (m2s_ex          ),
    .m2s_eret_flush          (m2s_eret_flush  ),
    //to f1s
    .f1s_flush               (f1s_flush       ),
    .f1s_stall               (f1s_stall       ),
    //to f2s
    .f2s_flush               (f2s_flush       ),
    .f2s_stall               (f2s_stall       ),
    //to ds
    .ds_stall               (ds_stall       ),
    .ds_flush               (ds_flush       ),
    //to es
    .es_flush               (es_flush       ),
    .exc_flush              (exc_flush      ),
    .es_stall               (es_stall), 
    //to m1s
    .m1s_flush              (m1s_flush       ),
    .m1s_stall              (m1s_stall       ),
    //to m2s
    .m2s_flush              (m2s_flush       ),
    .m2s_stall              (m2s_stall       ), 
    //to ws
    .ws_flush               (ws_flush       ),
    .ws_stall               (ws_stall       ),

    .ds_valid               (ds_valid       ),
    .es_valid               (es_valid       ),
    .m1s_valid              (m1s_valid       ),
    .m2s_valid              (m2s_valid       ),
    .ws_valid               (ws_valid       )
);






cache2axi  cache2axi(
    .aclk               (aclk              ),
    .aresetn            (aresetn            ),

    .icache_rd_req      (icache_rd_req     ),
    .icache_rd_type     (icache_rd_type    ),
    .icache_rd_addr     (icache_rd_addr    ),
    .icache_rd_rdy      (icache_rd_rdy     ),
    .icache_ret_valid   (icache_ret_valid  ),
    .icache_ret_last    (icache_ret_last   ),
    .icache_ret_data    (icache_ret_data   ),
     // 
    .icache_wr_req      (icache_wr_req     ),
    .icache_wr_type     (icache_wr_type    ),
    .icache_wr_addr     (icache_wr_addr    ),
    .icache_wr_wstrb    (icache_wr_wstrb   ),
    .icache_wr_data     (icache_wr_data    ),
    .icache_wr_rdy      (icache_wr_rdy     ),

    .dcache_rd_req      (dcache_rd_req      ),
    .dcache_rd_type     (dcache_rd_type     ),
    .dcache_rd_addr     (dcache_rd_addr     ),
    .dcache_rd_rdy      (dcache_rd_rdy      ),
    .dcache_ret_valid   (dcache_ret_valid   ),
    .dcache_ret_last    (dcache_ret_last    ),
    .dcache_ret_data    (dcache_ret_data    ),
     // w
    .dcache_wr_req      (dcache_wr_req      ),
    .dcache_wr_type     (dcache_wr_type     ),
    .dcache_wr_addr     (dcache_wr_addr     ),
    .dcache_wr_wstrb    (dcache_wr_wstrb    ),
    .dcache_wr_data     (dcache_wr_data   ),
    .dcache_wr_rdy      (dcache_wr_rdy      ),

    .axi_arid         (arid             ),
    .axi_araddr       (araddr           ),
    .axi_arlen        (arlen            ),
    .axi_arsize       (arsize           ),
    .axi_arburst      (arburst          ),
    .axi_arlock       (arlock           ),
    .axi_arcache      (arcache          ),
    .axi_arprot       (arprot           ),
    .axi_arvalid      (arvalid          ),
    .axi_arready      (arready          ),
    .axi_rid          (rid              ),
    .axi_rdata        (rdata            ),
    .axi_rresp        (rresp            ),
    .axi_rlast        (rlast            ),
    .axi_rvalid       (rvalid           ),
    .axi_rready       (rready           ),
    .axi_awid         (awid             ),
    .axi_awaddr       (awaddr           ),
    .axi_awlen        (awlen            ),
    .axi_awsize       (awsize           ),
    .axi_awburst      (awburst          ),
    .axi_awlock       (awlock           ),
    .axi_awcache      (awcache          ),
    .axi_awprot       (awprot           ),
    .axi_awvalid      (awvalid          ),
    .axi_awready      (awready          ),
    .axi_wid          (wid              ),
    .axi_wdata        (wdata            ),
    .axi_wstrb        (wstrb            ),
    .axi_wlast        (wlast            ),
    .axi_wvalid       (wvalid           ),
    .axi_wready       (wready           ),
    .axi_bid          (bid              ),
    .axi_bresp        (bresp            ),
    .axi_bvalid       (bvalid           ),
    .axi_bready       (bready           )
    );




icache icache(
//基本输入
    .clk            (aclk                           ),
    .reset          (areset                         ),
//来自CPU的输�????? 
    .valid          (inst_sram_req                  ),
    .index          (inst_sram_addr[12: 5]          ),
    .tag            (inst_sram_addr[31:13]          ),
    .offset         (inst_sram_addr[ 4: 0]          ),
    .addr_ok        (inst_sram_addr_ok              ),
    .data_ok        (inst_sram_data_ok              ),
    .rdata          (inst_sram_rdata                ),
    .is_uncache     (inst_uncache                   ),


//来自AXI的输�?????
//rd
    .rd_rdy         (icache_rd_rdy          ),
    .rd_req         (icache_rd_req          ),
    .rd_type        (icache_rd_type         ),       
    .rd_addr        (icache_rd_addr         ),
    .ret_valid      (icache_ret_valid       ),
    .ret_last       (icache_ret_last        ),
    .ret_data       (icache_ret_data        )
);

dcache dcache(
//基本输入
    .clk            (aclk                   ),
    .reset          (areset                 ),
//来自CPU的输�????? 
    .valid          (data_sram_req          ),
    .op             (data_sram_wr           ),
    .index          (data_sram_addr[11: 4]  ),
    .tag            (data_sram_addr[31:12]  ),
    .offset         (data_sram_addr[ 3: 0]  ),
    .wstrb          (data_sram_wstrb        ),
    .wdata          (data_sram_wdata        ),
    .addr_ok        (data_sram_addr_ok      ),
    .data_ok        (data_sram_data_ok      ),
    .rdata          (data_sram_rdata        ),
    .is_uncache     (data_uncache           ),


//来自AXI的输�?????
//rd
    .rd_rdy         (dcache_rd_rdy          ),
    .rd_req         (dcache_rd_req          ),
    .rd_type        (dcache_rd_type         ),       
    .rd_addr        (dcache_rd_addr         ),
    .ret_valid      (dcache_ret_valid       ),
    .ret_last       (dcache_ret_last        ),
    .ret_data       (dcache_ret_data        ),
    //wr
    .wr_req         (dcache_wr_req          ),
    .wr_type        (dcache_wr_type         ),
    .wr_addr        (dcache_wr_addr         ),
    .wr_wstrb       (dcache_wr_wstrb        ),
    .wr_data        (dcache_wr_data         ),
    .wr_rdy         (dcache_wr_rdy          ),

    //cache inst
    .cache_op       (0                      ),
    .cache_addruse  (0                      ),
    .cache_wb       (0                      ),
    .cache_we       (0                      ),
    .TagLo_tag      (0                      ),
    .TagLo_v        (0                      ),
    .TagLo_d        (0                      )
);





//Attention !!!
//Attention !!!
//Attention !!!
//exception commit point is MEM Stage now
cp0_regfile cp0_regfile(
    .clk                (aclk        ),
    .reset              (areset      ),
    //R & W cp0_regfiles
    .cp0_wdata          (cp0_wdata  ),
    .cp0_rdata          (cp0_rdata  ),
    .cp0_addr           (cp0_addr   ),

    .ext_int_in         (ext_int    ),//interrupt
    .mtc0_we            (m2s_mtc0_we ),
    .ex                 (m2s_ex      ),//exception signal in MEM Stage
    .bd                 (m2s_bd      ),//branch delay solt
    .m2s_pc             (m2s_pc      ),
    .excode             (m2s_excode  ),
    .eret_flush         (m2s_eret_flush ),
    .epc                (epc        ),
    .badvaddr           (m2s_badvaddr),
    //to id
    .has_int            (has_int    ),//interrupt is bounded to ID Stage
    //address space
    .config_kseg0       (config_kseg0)
    );






endmodule
