// `timescale 1ns / 1ps
// //////////////////////////////////////////////////////////////////////////////////
// // Company: 
// // Engineer: 
// // 
// // Create Date: 2022/07/23 17:21:24
// // Design Name: 
// // Module Name: IF2_FIFO
// // Project Name: 
// // Target Devices: 
// // Tool Versions: 
// // Description: 
// // 
// // Dependencies: 
// // 
// // Revision:
// // Revision 0.01 - File Created
// // Additional Comments:
// // 
// //////////////////////////////////////////////////////////////////////////////////
// `include "mycpu.h"
// `define LEN 2
// module IF2_FIFO(
//     input           clk,
//     input           reset,
//     //from IF1
//     input [`F1S_TO_FIFO_BUS_WD -1:0]    f1s_to_FIFO_bus,
//     input                               f1s_to_FIFO_valid,

//     //to IF2
//     output [`FIFO_TO_F2S_BUS_WD -1:0]   FIFO_to_f2s_bus,
//     output                              FIFO_to_f2s_valid,
//     output                              FIFO_ready_go,
//     //from IF2
//     input                               ds_allowin,
//     //to IF1
//     output                              FIFO_allowin,
//     //from es
//     input                               br_prd_err,
//     input  [31                      :0] es_pc,
//     //from hazard
//     input                               f2s_stall,
//     input                               f2s_flush,
//     //inst_cache interface
//     input                               inst_sram_data_ok,
//     input    [31:0]                     inst_sram_rdata  
//     );
// parameter SIZE = (1 << `LEN);

// reg [3:0] i;

// //input
// wire [31: 0]   pc_i;
// wire [ 4: 0]   excode_i;
// wire           ex_i;
// wire           is_bd_i;
// wire           br_prd_flush_i;
// //output
// wire [31: 0]   pc_o;
// wire [ 4: 0]   excode_o;
// wire           ex_o;
// wire           is_bd_o;
// wire           br_prd_flush_o;
// wire [31: 0]   inst_o;

// wire           full;

// wire bd;

// reg [`LEN-1 : 0] head;
// reg [`LEN-1 : 0] tail;
// reg [`LEN-1 : 0] inst_ptr;

// reg [SIZE-1  : 0] FIFO_valid;
// reg [31    : 0] FIFO_pc [0 : SIZE-1];
// reg [31    : 0] FIFO_inst [0 : SIZE-1];
// reg [SIZE-1  : 0] FIFO_inst_ok;
// reg [SIZE-1  : 0] FIFO_ex;
// reg [ 4    : 0] FIFO_excode [0 : SIZE-1];
// reg [SIZE-1  : 0] FIFO_is_bd;
// reg [SIZE-1  : 0] FIFO_br_prd_flush;

// assign {br_prd_flush_i,
//         is_bd_i,
//         ex_i,
//         excode_i,
//         pc_i} = f1s_to_FIFO_bus;



// assign is_bd_o          = FIFO_is_bd[head];
// assign ex_o             = FIFO_ex[head];
// assign excode_o         = FIFO_excode[head];
// assign pc_o             = FIFO_pc[head];

// assign bd = (FIFO_pc[head] == es_pc+3'h4);


// always@(posedge clk)begin
//     if(reset)begin
//         tail        <= 0;
//     end
//     else if(FIFO_allowin && f1s_to_FIFO_valid)begin
        
//         FIFO_is_bd[tail]          <= is_bd_i;
//         FIFO_excode[tail]         <= excode_i;
//         FIFO_pc[tail]             <= pc_i;
//         tail                      <= tail + 1;
//     end
// end

// //ex
// always@(posedge clk)begin
//     if(reset)
//         FIFO_ex     <= 0;
//     else begin
//         if(FIFO_ready_go && ds_allowin)
//             FIFO_ex[head]  <= 1'b0;
//         if(FIFO_allowin && f1s_to_FIFO_valid)
//             FIFO_ex[tail]  <= ex_i;
//     end
// end





// always@(posedge clk)begin
//     if(reset)
//         FIFO_br_prd_flush   <= 0;
//     else if(f2s_flush)
//         FIFO_br_prd_flush   <= 4'b1111;
//     else begin
//         if(br_prd_err)
//         begin
//             for(i=0;i<SIZE;i=i+1)
//                 if(!(i==head && bd))
//                     FIFO_br_prd_flush[i] <= 1; 
//         end
//         if(FIFO_ready_go && ds_allowin)
//             FIFO_br_prd_flush[head]  <= 1'b0;
//         if(FIFO_allowin && f1s_to_FIFO_valid)
//             FIFO_br_prd_flush[tail]  <= br_prd_flush_i;
//     end
// end


// always@(posedge clk)begin
//     if(reset)
//         FIFO_valid  <= 0;
//     else begin
//         if(FIFO_ready_go && ds_allowin)
//             FIFO_valid[head]  <= 1'b0;
//         if(FIFO_allowin && f1s_to_FIFO_valid)
//             FIFO_valid[tail]  <= 1'b1;
//     end
// end

// //FIFO_inst_ok
// always@(posedge clk)begin
//     if(reset)begin
//         FIFO_inst_ok                <= 0;
//     end
//     else 
//     begin
//             if(FIFO_ready_go && ds_allowin)
//                 FIFO_inst_ok[head]          <= 0;
//             if(inst_sram_data_ok && !((head == inst_ptr) && FIFO_ready_go && ds_allowin))begin
//                 FIFO_inst_ok[inst_ptr]      <= 1;
//             end
//     end
// end

// //FIFO_inst_ok
// always@(posedge clk)begin
//     if(inst_sram_data_ok)
//         FIFO_inst[inst_ptr]       <= inst_sram_rdata;
// end


// //inst_ptr
// always@(posedge clk)begin
//     if(reset)
//         inst_ptr                    <= 0;
//     else begin
//         if(inst_sram_data_ok)
//         inst_ptr                    <= inst_ptr + 1;
//         if(FIFO_allowin && f1s_to_FIFO_valid && ex_i)
//         inst_ptr                    <= inst_ptr + 1;
//     end
// end

// always@(posedge clk)begin
//     if(reset)begin
//         head        <= 0;
//     end
//     else if(FIFO_ready_go && ds_allowin)begin
//         head        <= head + 1;
//     end
// end

// assign FIFO_ready_go        = (FIFO_ex[head] || inst_sram_data_ok || FIFO_inst_ok[head]) && !f2s_stall;
// assign FIFO_to_f2s_valid    = FIFO_valid[head];
// assign FIFO_allowin         = !full;
// assign full                 = FIFO_valid[tail + `LEN'h2];//(tail + `LEN'h2 == head);

// assign inst_o = FIFO_inst_ok[head] ? FIFO_inst[head] : {32{inst_sram_data_ok && !FIFO_ex[head]}} & inst_sram_rdata;
// assign br_prd_flush_o   = (br_prd_err && !bd || f2s_flush) ? 1'b1 : FIFO_br_prd_flush[head] ;


// assign FIFO_to_f2s_bus = {  inst_o,
//                             br_prd_flush_o,
//                             is_bd_o,
//                             ex_o,
//                             excode_o,
//                             pc_o} & {`FIFO_TO_F2S_BUS_WD{(FIFO_to_f2s_valid)}} ;

// endmodule
