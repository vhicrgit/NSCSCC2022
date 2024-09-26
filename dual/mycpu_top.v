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
    output      [31:0]                  debug_wb_pc_0      ,
    output      [3:0]                   debug_wb_rf_wen_0  ,
    output      [4:0]                   debug_wb_rf_wnum_0 ,
    output      [31:0]                  debug_wb_rf_wdata_0,
    output                              first_0,
    output      [31:0]                  debug_wb_pc_1      ,
    output      [3:0]                   debug_wb_rf_wen_1  ,
    output      [4:0]                   debug_wb_rf_wnum_1 ,
    output      [31:0]                  debug_wb_rf_wdata_1,
    output                              first_1
);

    // inst 
    wire          inst_sram_req    ;
    // wire          inst_sram_wr     ;
    wire   [1:0]  inst_sram_size   ;
    // wire   [3:0]  inst_sram_wstrb  ;
    wire   [31:0] inst_sram_addr   ;
    wire   [31:0] inst_sram_wdata  ;
    wire          inst_sram_addr_ok;
    // wire          inst_sram_data_ok;
    // wire   [31:0] inst_sram_rdata  ;
    // wire          inst_uncache     ;
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


wire         fifo_allowin;
wire         es_allowin;
wire         m1s_allowin;
wire         m2s_allowin;
wire         ws_allowin;
wire         fifo_to_ds_valid_0;
wire         fifo_to_ds_valid_1;
wire         simple_es_bus_valid;
wire         complex_es_bus_valid;
wire [ 1:0]  es_to_m1s_valid;
wire [ 1:0]  m1s_to_m2s_valid;
wire [ 1:0]  m2s_to_ws_valid;
wire         valid_i_0;
wire         valid_i_1;
wire [`CACHE_TO_FIFO_WD-1   :0] icache_bus_0;
wire [`CACHE_TO_FIFO_WD-1   :0] icache_bus_1;
wire [`FIFO_TO_DS_BUS_WD -1 :0] fifo_to_ds_bus_0;
wire [`FIFO_TO_DS_BUS_WD -1 :0] fifo_to_ds_bus_1;
wire [`SIMPLE_ES_BUS_WD-1   :0] simple_es_bus;
wire [`COMPLEX_ES_BUS_WD-1  :0] complex_es_bus;
wire [`ES_TO_M1S_BUS0_WD -1 :0] es_to_m1s_bus_0;
wire [`ES_TO_M1S_BUS1_WD -1 :0] es_to_m1s_bus_1;
wire [`M1S_TO_M2S_BUS0_WD -1 :0] m1s_to_m2s_bus_0;
wire [`M1S_TO_M2S_BUS1_WD -1 :0] m1s_to_m2s_bus_1;
wire [`M2S_TO_WS_BUS_WD -1:0 ] m2s_to_ws_bus_0;
wire [`M2S_TO_WS_BUS_WD -1:0 ] m2s_to_ws_bus_1;
wire [`WS_TO_RF_BUS_WD -1:0  ] ws_to_rf_bus;
wire [`BR_BUS_WD       -1:0  ] br_bus;

wire [`ES_FWD_BUS-1 :0]  es_fwd_bus_0;
wire [`ES_FWD_BUS-1 :0]  es_fwd_bus_1;
wire [`M1S_FWD_BUS-1 :0] m1s_fwd_bus_0;
wire [`M1S_FWD_BUS-1 :0] m1s_fwd_bus_1;
wire [`M2S_FWD_BUS-1 :0] m2s_fwd_bus_0;
wire [`M2S_FWD_BUS-1 :0] m2s_fwd_bus_1;



wire        m1s_ready_go;
wire        m2s_ready_go;
wire        ws_ready_go;

wire [31:0] f1s_pc;
wire [31:0] f2s_pc;
wire [31:0] ds_pc;
wire [31:0] es_pc;
wire        m2s_res_from_mem_ok;

//================================= reg file  ==============================
wire [ 4: 0] rf_raddr0;
wire [31: 0] rf_rdata0;
wire [ 4: 0] rf_raddr1;
wire [31: 0] rf_rdata1;
wire [ 4: 0] rf_raddr2;
wire [31: 0] rf_rdata2;
wire [ 4: 0] rf_raddr3;
wire [31: 0] rf_rdata3;
wire [ 3: 0] rf_we0;
wire [ 4: 0] rf_waddr0;
wire [31: 0] rf_wdata0;
wire [ 3: 0] rf_we1;
wire [ 4: 0] rf_waddr1;
wire [31: 0] rf_wdata1;

//================================= forwarding =============================
wire [1:0]  alu_src1_fwd;
wire [1:0]  alu_src2_fwd;
wire [4:0]  es_rs1;
wire [4:0]  es_rs2;
wire [4:0]  m1s_rd;
wire [4:0]  m2s_rd;
wire [4:0]  ws_rd;
wire        es_reg_write_0;
wire        es_reg_write_1;
wire        m1s_reg_write;
wire        m2s_reg_write;
wire        ws_reg_write;
wire [1:0]  fwd1;
wire [1:0]  fwd2;
wire [31:0] m1s_alu_result;
wire [31:0] m2s_alu_result;
wire [31:0] ws_final_result;
wire [3: 0] ws_rf_wen;
wire [3: 0] fwd1_wen;
wire [3: 0] fwd2_wen;
wire [3: 0] alu1_fwd_wen;
wire [3: 0] alu2_fwd_wen;




//================================== hazard ===============================
wire [4:0] ds_rs1;
wire [4:0] ds_rs2;
wire [4:0] es_rd_0;
wire [4:0] es_rd_1;
wire es_mem_read;
wire m1s_mem_read;
wire m2s_mem_read;
wire es_res_from_cp0;
wire m1s_res_from_cp0;
wire m2s_res_from_cp0;
wire f1s_stall;
wire fifo_stall;
wire ds_stall;
wire es_stall;
wire m1s_stall;
wire m2s_stall;
wire ws_stall;
wire f1s_flush;
wire fifo_flush;
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

//fetch
wire [1:0] issue_mode;
wire [31: 0] pred0_target;
wire [31: 0] pred1_target;
wire [31: 0] seq_pc;
wire inst_rdata0_valid;
wire inst_rdata1_valid;
wire f1s_ex_0;
wire f1s_ex_1;
wire [1:0] br_flag;
wire [4:0] f1s_excode_0;
wire [4:0] f1s_excode_1;
// IF1 stage
if1_stage if1_stage(
    .clk                (aclk               ),
    .reset              (areset             ),
    //from fifo
    .fifo_allowin        (fifo_allowin       ),
    //brbus
    .br_bus             (br_bus             ),
    //from hazard
    .f1s_flush          (f1s_flush           ),
    // inst sram interface
    
    .seq_pc             (seq_pc             ),
    .f1s_ex_0           (f1s_ex_0           ),
    .f1s_ex_1           (f1s_ex_1           ),
    .f1s_excode_0       (f1s_excode_0       ),
    .f1s_excode_1       (f1s_excode_1       ),
    .inst_sram_req      (inst_sram_req      ),
    .inst_sram_size     (inst_sram_size     ),
    .inst_sram_addr     (inst_sram_addr     ),
    .inst_sram_addr_ok  (inst_sram_addr_ok  ),
    //eret
    .ex_taken           (m2s_ex             ),
    .epc                (epc                ),
    .eret_taken         (m2s_eret_flush     ),

    //address space
    .config_kseg0       (config_kseg0       ) 
);

 
fetch fetch(
    .clk                (aclk               ),
    .reset              (areset             ),
    // from bht
    .pd_pc0_i           (pred0_target       ),
    .pd_pc1_i           (pred1_target       ),
    .br_flag            (br_flag            ),
    // from hazard
    .flush              (fifo_flush          ),
    // from f1s
    .inst_pc            (inst_sram_addr     ),
    .inst_req           (inst_sram_req      ),
    .ex0_i              (f1s_ex_0           ),
    .ex_code0_i         (f1s_excode_0       ),
    .ex1_i              (f1s_ex_1           ),
    .ex_code1_i         (f1s_excode_1       ),
    // to f1s
    .seq_pc             (seq_pc             ),
    .inst_addr_ok       (inst_sram_addr_ok),
    // to fifo
    .icache_bus_0       (icache_bus_0       ),
    .icache_bus_1       (icache_bus_1       ),        
    .inst_rdata_valid  ({inst_rdata1_valid,inst_rdata0_valid}  ),

    // to axi
    .rd_rdy         (icache_rd_rdy          ),
    .rd_req         (icache_rd_req          ),
    .rd_type        (icache_rd_type         ),       
    .rd_addr        (icache_rd_addr         ),
    .ret_valid      (icache_ret_valid       ),
    .ret_last       (icache_ret_last        ),
    .ret_data       (icache_ret_data        )
);



// fifo
fifo fifo(
    .clk                (aclk               ),
    .reset              (areset             ),
    //f1s
    .fifo_allowin       (fifo_allowin        ),
    .fifo_pc            (fifo_pc             ),
    //ds
    .issue_mode         (issue_mode         ),
    .fifo_to_ds_valid_0 (fifo_to_ds_valid_0 ),
    .fifo_to_ds_valid_1 (fifo_to_ds_valid_1 ),
    .fifo_to_ds_bus_0   (fifo_to_ds_bus_0   ),
    .fifo_to_ds_bus_1   (fifo_to_ds_bus_1   ),
    //from hazard
    .ds_flush           (ds_flush           ),
    // inst sram interface
    .icache_bus_0       (icache_bus_0       ),
    .icache_bus_1       (icache_bus_1       ),
    .valid_i_0          (inst_rdata0_valid  ),
    .valid_i_1          (inst_rdata1_valid  )
);


BHT BHT(
    .clk            (aclk           ),
    .rst            (areset         ),

    .pc_query       (inst_sram_addr ),
    .br_flag        (br_flag        ),
    .pred0_target   (pred0_target  ),
    .pred1_target   (pred1_target  ),

    .br_pc          (es_pc          ),
    .br_target      (br_bus[31:0]   ), 
    .br_update      (br_bus[32]     ),
    .br_is          (es_b_or_j      )
);



// ID stage
id_stage id_stage(
    .clk                (aclk            ),
    .reset              (areset          ),
    //allowin
    .es_allowin         (es_allowin     ),
    //fifo
    .fifo_to_ds_valid_0 (fifo_to_ds_valid_0 ),
    .fifo_to_ds_valid_1 (fifo_to_ds_valid_1 ),
    .fifo_to_ds_bus_0   (fifo_to_ds_bus_0   ),
    .fifo_to_ds_bus_1   (fifo_to_ds_bus_1   ),
    .issue_mode         (issue_mode         ),
    //to es
    .simple_es_bus      (simple_es_bus          ),
    .complex_es_bus     (complex_es_bus         ),
    .simple_es_bus_valid(simple_es_bus_valid    ),
    .complex_es_bus_valid(complex_es_bus_valid  ),
    //to regfile
    .rf_raddr0          (rf_raddr0      ),
    .rf_rdata0          (rf_rdata0      ),
    .rf_raddr1          (rf_raddr1      ),
    .rf_rdata1          (rf_rdata1      ),
    .rf_raddr2          (rf_raddr2      ),
    .rf_rdata2          (rf_rdata2      ),
    .rf_raddr3          (rf_raddr3      ),
    .rf_rdata3          (rf_rdata3      ),
    // forwarding
    .es_fwd_bus_0                   (es_fwd_bus_0    ),
    .es_fwd_bus_1                   (es_fwd_bus_1    ),
    .m1s_fwd_bus_0                  (m1s_fwd_bus_0   ),
    .m1s_fwd_bus_1                  (m1s_fwd_bus_1   ),
    .m2s_fwd_bus_0                  (m2s_fwd_bus_0   ),
    .m2s_fwd_bus_1                  (m2s_fwd_bus_1   ),
    
    .es_res_from_cp0                (es_res_from_cp0    ),
    .m1s_res_from_cp0               (m1s_res_from_cp0   ),
    .m2s_res_from_cp0               (m2s_res_from_cp0   ),
    .es_mem_read                    (es_mem_read        ),
    .m1s_mem_read                   (m1s_mem_read       ),
    .m2s_mem_read                   (m2s_mem_read       ),
    .m2s_res_from_mem_ok            (m2s_res_from_mem_ok),

    //from cp0
    .has_int            (has_int        )
);

regfile u_regfile(
    .clk        (aclk       ),
    .raddr0     (rf_raddr0  ),
    .rdata0     (rf_rdata0  ),
    .raddr1     (rf_raddr1  ),
    .rdata1     (rf_rdata1  ),
    .raddr2     (rf_raddr2  ),
    .rdata2     (rf_rdata2  ),
    .raddr3     (rf_raddr3  ),
    .rdata3     (rf_rdata3  ),
    .we0        (rf_we0     ),
    .waddr0     (rf_waddr0  ),
    .wdata0     (rf_wdata0  ),
    .we1        (rf_we1     ),
    .waddr1     (rf_waddr1  ),
    .wdata1     (rf_wdata1  )
    );

    
// EXE stage
exe_stage exe_stage(
    .clk                (aclk               ),
    .reset              (areset             ),
    //allowin
    .m1s_allowin        (m1s_allowin         ),
    .es_allowin         (es_allowin         ),
    //ds
    .ds_to_es_valid     ({simple_es_bus_valid,complex_es_bus_valid}),
    .ds_to_es_bus_0     (complex_es_bus     ),
    .ds_to_es_bus_1     (simple_es_bus      ),
    
    .es_fwd_bus_0       (es_fwd_bus_0       ),
    .es_fwd_bus_1       (es_fwd_bus_1       ),
    //to m1s
    .es_to_m1s_valid     (es_to_m1s_valid     ),
    .es_to_m1s_bus_0     (es_to_m1s_bus_0     ),
    .es_to_m1s_bus_1     (es_to_m1s_bus_1     ),
    //from m1s
    .m1s_ex             (m1s_ex               ),
    //from m2s
    .ex_taken           (m2s_ex              ),
    //from hazard
    .es_flush           (es_flush           ),
    .m1s_flush          (m1s_flush          ),
    .es_stall           (es_stall           ),
    //to hazard
    .es_res_from_mem    (es_mem_read        ),
    .es_res_from_cp0    (es_res_from_cp0    ),
    .exc_flush          (exc_flush          ),
    .es_valid           (es_valid           ),
    .div_block          (div_block          ),
    //br_bus
    .es_br_bus          (br_bus             ),
    .es_b_or_j          (es_b_or_j          ),
    .es_pc_bht          (es_pc              ),


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
    .es_to_m1s_bus_0 (es_to_m1s_bus_0 ),
    .es_to_m1s_bus_1 (es_to_m1s_bus_1 ),
    //to es
    .m1s_ex          (m1s_ex          ),
    //to m2s
    .m1s_to_m2s_valid (m1s_to_m2s_valid ),
    .m1s_to_m2s_bus_0 (m1s_to_m2s_bus_0 ),
    .m1s_to_m2s_bus_1 (m1s_to_m2s_bus_1 ),
    //from m2s
    .ex_taken           (m2s_ex        ),
    .eret_taken         (m2s_eret_flush),
    //to forwarding
    .m1s_fwd_bus_0   (m1s_fwd_bus_0   ),
    .m1s_fwd_bus_1   (m1s_fwd_bus_1   ),
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
    .m1s_to_m2s_bus_0 (m1s_to_m2s_bus_0 ),
    .m1s_to_m2s_bus_1 (m1s_to_m2s_bus_1 ),
    //to ws
    .m2s_to_ws_valid (m2s_to_ws_valid ),
    .m2s_to_ws_bus_0 (m2s_to_ws_bus_0 ),
    .m2s_to_ws_bus_1 (m2s_to_ws_bus_1 ),
    //to forwarding
    .m2s_fwd_bus_0   (m2s_fwd_bus_0   ),
    .m2s_fwd_bus_1   (m2s_fwd_bus_1   ),
    //from hazard
    .ws_flush       (ws_flush       ),
    .m2s_stall       (m2s_stall       ),
    .m2s_res_from_cp0(m2s_res_from_cp0),
    //from data-sram
    .data_sram_data_ok(data_sram_data_ok),
    .data_sram_rdata    (data_sram_rdata),
    //to hazard
    .m2s_res_from_mem(m2s_mem_read    ),
    .m2s_valid       (m2s_valid       ) ,
    .m2s_res_from_mem_ok(m2s_res_from_mem_ok),
    //CP0-regfile
    .m2s_cp0_wdata           (cp0_wdata  ),
    .m2s_cp0_rdata           (cp0_rdata  ),
    .m2s_pc_cp0              (m2s_pc     ),
    .m2s_cp0_addr            (cp0_addr   ),
    .m2s_mtc0_we             (m2s_mtc0_we ),
    .m2s_ex                  (m2s_ex      ),
    .m2s_bd                  (m2s_bd      ),
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
    .m2s_to_ws_bus_0 (m2s_to_ws_bus_0 ),
    .m2s_to_ws_bus_1 (m2s_to_ws_bus_1 ),
    //to rf: for write back
    .ws_to_rf_bus_0   ({ rf_we0   ,
                       rf_waddr0,
                       rf_wdata0
                      }  ),
    .ws_to_rf_bus_1   ({ rf_we1   ,
                       rf_waddr1,
                       rf_wdata1
                      }  ),
    //from hazard
    .ws_stall       (ws_stall       ),
    //to forwarding
    //trace debug interface
    .debug_wb_pc_0      (debug_wb_pc_0      ),
    .debug_wb_rf_wen_0  (debug_wb_rf_wen_0  ),
    .debug_wb_rf_wnum_0 (debug_wb_rf_wnum_0 ),
    .debug_wb_rf_wdata_0(debug_wb_rf_wdata_0),
    .ws_first_0(first_0),
    .debug_wb_pc_1      (debug_wb_pc_1      ),
    .debug_wb_rf_wen_1  (debug_wb_rf_wen_1  ),
    .debug_wb_rf_wnum_1 (debug_wb_rf_wnum_1 ),
    .debug_wb_rf_wdata_1(debug_wb_rf_wdata_1),

    .ws_ready_go         (ws_ready_go),
    .ws_first_1(first_1)
);




hazard hazard(
    //from ds
    // .ds_rs1                 (ds_rs1         ),
    // .ds_rs2                 (ds_rs2         ),
    // .br                     (br             ),
    //from es 
    // .es_rd                  (es_rd          ),
    // .es_rs                  (es_rs1         ),
    // .es_rt                  (es_rs2         ),
    // .es_mem_read            (es_mem_read    ),
    // .es_reg_write           (es_reg_write   ),
    // .es_res_from_cp0        (es_res_from_cp0),
    .div_block              (div_block      ),
    .br_prd_err             (br_bus[32]     ),
    //from m1s
    // .m1s_mem_read            (m1s_mem_read    ),
    // .m1s_reg_write           (m1s_reg_write   ),
    // .m1s_rd                  (m1s_rd          ),
    // .m1s_res_from_cp0        (m1s_res_from_cp0),
    //from m2s
    // .m2s_mem_read            (m2s_mem_read    ),
    // .m2s_reg_write           (m2s_reg_write   ),
    // .m2s_rd                  (m2s_rd          ),
    // .m2s_res_from_cp0        (m2s_res_from_cp0),
    // .m2s_res_from_mem_ok     (m2s_res_from_mem_ok),
    .m2s_ex                  (m2s_ex          ),
    .m2s_eret_flush          (m2s_eret_flush  ),
    //to f1s
    .f1s_flush               (f1s_flush       ),
    // .f1s_stall               (f1s_stall       ),
    //to f2s
    .f2s_flush               (fifo_flush       ),
    // .f2s_stall               (fifo_stall       ),
    //to ds
    // .ds_stall               (ds_stall       ),
    .ds_flush               (ds_flush       ),
    //to es
    .es_flush               (es_flush       ),
    .exc_flush              (exc_flush      ),
    .es_stall               (es_stall       ), 
    //to m1s
    .m1s_flush              (m1s_flush       ),
    .m1s_stall              (m1s_stall       ),
    //to m2s
    .m2s_flush              (m2s_flush       ),
    .m2s_stall              (m2s_stall       ), 
    //to ws
    .ws_flush               (ws_flush       ),
    .ws_stall               (ws_stall       )

    // .ds_valid               (ds_valid       ),
    // .es_valid               (es_valid       ),
    // .m1s_valid              (m1s_valid       ),
    // .m2s_valid              (m2s_valid       ),
    // .ws_valid               (ws_valid       )
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





dcache dcache(
//基本输入
    .clk            (aclk                   ),
    .reset          (areset                 ),
//来自CPU的输�????????? 
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


//来自AXI的输�?????????
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
