`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/04/30 21:07:11
// Design Name: 
// Module Name: cp0_regfile
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////
`include "mycpu.h"


module cp0_regfile(
    input                         clk,
    input                         reset,
    input  [31: 0]                cp0_wdata,
    output [31: 0]                cp0_rdata,
    input  [ 7: 0]                cp0_addr,
    input  [31: 0]                badvaddr,
    input                         ex,
    input  [ 4: 0]                excode,
    input                         bd,
    input  [31: 0]                m2s_pc,
    output [31: 0]                epc,
    input  [ 5: 0]                ext_int_in,
    output                        has_int,
    input                         eret_flush,
    input                         mtc0_we,
   
    //index
    output [$clog2(`TLBNUM)-1:0]  tlb_index,
    //address space
    output                        config_kseg0
    );


//===========count=============
reg tick;
reg [31:0] cp0_count;
always@(posedge clk)
begin
    if(reset)
        tick <= 1'b0;
    else 
        tick = ~tick;

    if(mtc0_we && cp0_addr == `CR_COUNT)
        cp0_count <= cp0_wdata;
    else if(tick)
        cp0_count = cp0_count + 1;
end

//===========compare=============
reg [31:0] cp0_compare;
wire count_eq_compare;
always@(posedge clk)
begin
    if(reset)
        cp0_compare <= 0;
    else if(mtc0_we && cp0_addr == `CR_COMPARE)
        cp0_compare <= cp0_wdata;
end
assign count_eq_compare = (cp0_count == cp0_compare);

//===========status=============
wire [31:0] cp0_status;
wire cp0_status_bev;
reg [7:0] cp0_status_im;
reg cp0_status_exl;
reg cp0_status_ie;
assign cp0_status = {
    9'b0,
    cp0_status_bev,
    6'b0,
    cp0_status_im,
    6'b0,
    cp0_status_exl,
    cp0_status_ie
};
assign cp0_status_bev = 1'b1;
always@(posedge clk)
begin
    if(mtc0_we && cp0_addr == `CR_STATUS)
        cp0_status_im <= cp0_wdata[15:8];
end

always@(posedge clk)
begin
    if(reset)
        cp0_status_exl <= 1'b0;
    else if(ex)
        cp0_status_exl <= 1'b1;
    else if(eret_flush)
        cp0_status_exl <= 1'b0;
    else if(mtc0_we && cp0_addr == `CR_STATUS)
        cp0_status_exl <= cp0_wdata[1];
end

always@(posedge clk)
begin
    if(reset)
        cp0_status_ie <= 1'b0;
    else if(mtc0_we && cp0_addr == `CR_STATUS)
        cp0_status_ie <= cp0_wdata[0];
end
    
    
//=============cause=============
wire [31:0] cp0_cause;
reg cp0_cause_bd;
reg cp0_cause_ti;
reg [7:0] cp0_cause_ip;
reg [4:0] cp0_cause_excode;
assign cp0_cause = {
    cp0_cause_bd,
    cp0_cause_ti,
    14'b0,
    cp0_cause_ip,
    1'b0,
    cp0_cause_excode,
    2'b0
};

always@(posedge clk)
begin
    if(reset)
        cp0_cause_bd <= 1'b0;
    else if(ex && !cp0_status_exl)
        cp0_cause_bd <= bd;
end
always@(posedge clk)
begin
    if(reset)
        cp0_cause_ti <= 1'b0;
    else if(mtc0_we && cp0_addr == `CR_COMPARE)
        cp0_cause_ti <= 1'b0;
    else if(count_eq_compare)
        cp0_cause_ti <= 1'b1;
end
always@(posedge clk)
begin
    if(reset)
        cp0_cause_ip[7:2] <= 6'b0;
    else begin
        cp0_cause_ip[7]   <= ext_int_in[5] | cp0_cause_ti;
        cp0_cause_ip[6:2] <= ext_int_in[4:0];
    end
end
always@(posedge clk)
begin
    if(reset)
        cp0_cause_ip[1:0] <= 2'b0;
    else if(mtc0_we && cp0_addr == `CR_CAUSE)
        cp0_cause_ip[1:0] <=cp0_wdata[9:8];
end
always@(posedge clk)
begin
    if(reset)
        cp0_cause_excode <= 5'b0;
    else if(ex)
        cp0_cause_excode <= excode;
end

//===========epc=============
reg [31:0] cp0_epc;

always@(posedge clk)
begin
    if(ex && !cp0_status_exl)
        cp0_epc <= bd ? m2s_pc - 3'h4 : m2s_pc;
    else if(mtc0_we && cp0_addr == `CR_EPC)
        cp0_epc <= cp0_wdata;
end

//=============BadVAddr=============
reg [31:0] cp0_badvaddr;
always@(posedge clk)
begin
    if(ex && (excode == `EXC_ADEL || excode == `EXC_ADES))
        cp0_badvaddr <= badvaddr;
end

assign epc = cp0_epc;

//==============Int=============
assign has_int = ((cp0_cause_ip & cp0_status_im) != 8'h00) && cp0_status_ie && cp0_status_exl == 0;

//=============Index=============
// wire [31: 0]              cp0_index;
// reg                       p;
// reg [$clog2(`TLBNUM)-1:0] index;
// assign cp0_index = {p,
//                     {(31 - $clog2(`TLBNUM)){1'b0}},
//                     index
// };
// assign tlb_index = index;

// always@(posedge clk)
// begin
//     if(reset)
//         p       <= 1'b0;
//     else if(tlbp_we)
//     begin
//         p       <= tlbp_p;
//         index   <= tlbp_index;
//     end
//     else if(mtc0_we && cp0_addr == `CR_INDEX)
//     begin
//         index   <= cp0_wdata[$clog2(`TLBNUM)-1:0];
//     end
// end

//=============EntryHi============
// reg [18:0] vpn2;
// reg [7 :0] asid;
// wire [31:0] cp0_EntryHi;
// assign cp0_EntryHi = {  vpn2,
//                         5'b0,
//                         asid
// };
// assign tlbwi_vpn2   = vpn2;
// assign tlbwi_asid   = asid;
// assign tlbp_vpn2    = {19{mtc0_we && cp0_addr == `CR_INDEX}} ? cp0_wdata[31:13] : vpn2;
// assign tlbp_asid    = {8{mtc0_we && cp0_addr == `CR_INDEX}}  ? cp0_wdata[ 7: 0] : asid;

// always@(posedge clk)
// begin
//     if(reset)
//         asid <= 0;
//     else if(tlbr_we)
//     begin
//         vpn2 <= tlbr_vpn2;
//         asid <= tlbr_asid;
//     end
//     else if(mtc0_we && cp0_addr == `CR_ENTRYHI)
//     begin
//         vpn2 <= cp0_wdata[31:13];
//         asid <= cp0_wdata[ 7: 0];
//     end
//     else if(ex && (excode ==`EXC_TLBL || excode == `EXC_TLBS || excode == `EXC_MOD))
//     begin
//         vpn2 <= badvaddr[31:13];
//     end
// end

//=============EntryLo0=============
// wire [31: 0]  cp0_EntryLo0;
// reg [19: 0]   pfn0;
// reg [ 2: 0]   c0;
// reg           d0;
// reg           v0;
// reg           g0;
// assign cp0_EntryLo0 = { 6'b0,
//                         pfn0,
//                         c0,
//                         d0,
//                         v0,
//                         g0
// };
// //TLBWI
// assign tlbwi_pfn0   = pfn0;
// assign tlbwi_c0     = c0;
// assign tlbwi_d0     = d0;
// assign tlbwi_v0     = v0;

// always@(posedge clk)
// begin
//     if(tlbr_we)
//     begin
//         pfn0   <= tlbr_pfn0;
//         c0     <= tlbr_c0;
//         d0     <= tlbr_d0;
//         v0     <= tlbr_v0;
//         g0     <= tlbr_g;
//     end
//     else if(mtc0_we && cp0_addr == `CR_ENTRYLO0)
//     begin
//         {pfn0,c0,d0,v0,g0} <= cp0_wdata[25:0];
//     end
// end


//=============EntryLo1============
// wire [31: 0]  cp0_EntryLo1;
// reg [19: 0]   pfn1;
// reg [ 2: 0]   c1;
// reg           d1;
// reg           v1;
// reg           g1;
// assign cp0_EntryLo1 = { 6'b0,
//                         pfn1,
//                         c1,
//                         d1,
//                         v1,
//                         g1
// };
// //TLBWI
// assign tlbwi_pfn1   = pfn1;
// assign tlbwi_c1     = c1;
// assign tlbwi_d1     = d1;
// assign tlbwi_v1     = v1;
// assign tlbwi_g      = g0 && g1;

// always@(posedge clk)
// begin
//     if(tlbr_we)
//     begin
//         pfn1   <= tlbr_pfn1;
//         c1     <= tlbr_c1;
//         d1     <= tlbr_d1;
//         v1     <= tlbr_v1;
//         g1     <= tlbr_g;
//     end
//     else if(mtc0_we && cp0_addr == `CR_ENTRYLO1)
//     begin
//         {pfn1,c1,d1,v1,g1} <= cp0_wdata[25:0];
//     end
// end

//============= Config ============
wire [31: 0] cp0_config;
reg  [ 2: 0] k0;
wire [ 2: 0] AR;
wire [ 2: 0] MT;
wire [ 1: 0] AT;
wire         M;
wire         BE;

assign AR = 3'b0;
assign MT = 3'b1;
assign M  = 1'b1;
assign BE = 1'b0;
assign AT = 2'b0;
assign config_kseg0 = (k0 != 3'h3);
assign cp0_config ={M,
                    15'h0,
                    BE,
                    AT,
                    AR,
                    MT,
                    4'h0,
                    k0
};

always@(posedge clk)
begin
    if(reset)
        k0 <= 3'h3;
    else if(mtc0_we && cp0_addr == `CR_CONFIG)
        k0 <= cp0_wdata[2:0];
end

//============= Config1 ============
wire [31: 0] cp0_config1;
wire [ 5: 0] MMU_size;
wire [ 2: 0] IS;
wire [ 2: 0] IL;
wire [ 2: 0] IA;
wire [ 2: 0] DS;
wire         M1;
wire [ 2: 0] DL;
wire [ 2: 0] DA;
wire         C2;
wire         MD;
wire         PC;
wire         WR;
wire         CA;
wire         EP;
wire         FP;

assign M1       = 1'b1;
assign MMU_size = 6'd15;
assign IS       = 3'h2;
assign IL       = 3'h4;
assign IA       = 3'h1;
assign DS       = 3'h2;
assign DL       = 3'h4;
assign DA       = 3'h1;
assign C2       = 1'b0;
assign MD       = 1'b0;
assign PC       = 1'b0;
assign WR       = 1'b0;
assign CA       = 1'b0;
assign EP       = 1'b0;
assign FP       = 1'b0;

assign cp0_config1 = {  M1,
                        MMU_size,
                        IS,
                        IL,
                        IA,
                        DS,
                        DL,
                        DA,
                        C2,
                        MD,
                        PC,
                        WR,
                        CA,
                        EP,
                        FP
};

//============= TagLo ============
// wire [31: 0] cp0_taglo;
// reg  [19: 0] taglo_tag;
// reg          taglo_d;
// reg          taglo_v;
// assign TagLo_tag    = taglo_tag;
// assign TagLo_d      = taglo_d;
// assign TagLo_v      = taglo_v;
// assign cp0_taglo = {10'h0,
//                     taglo_tag,
//                     taglo_d,
//                     taglo_v
// };

// always@(posedge clk)
// begin
//     if(reset)
//         {taglo_tag,taglo_d,taglo_v} <= 0;
//     else if(mtc0_we && cp0_addr == `CR_TAGLO)
//         {taglo_tag,taglo_d,taglo_v} <= cp0_wdata[21:0];
// end


//read data
assign cp0_rdata = {32{cp0_addr == `CR_COUNT}}      & cp0_count
                 | {32{cp0_addr == `CR_COMPARE}}    & cp0_compare
                 | {32{cp0_addr == `CR_STATUS}}     & cp0_status
                 | {32{cp0_addr == `CR_CAUSE}}      & cp0_cause
                 | {32{cp0_addr == `CR_EPC}}        & cp0_epc
                 | {32{cp0_addr == `CR_BADVADDR}}   & cp0_badvaddr
                //  | {32{cp0_addr == `CR_INDEX}}      & cp0_index
                //  | {32{cp0_addr == `CR_ENTRYHI}}    & cp0_EntryHi
                //  | {32{cp0_addr == `CR_ENTRYLO0}}   & cp0_EntryLo0
                //  | {32{cp0_addr == `CR_ENTRYLO1}}   & cp0_EntryLo1
                 | {32{cp0_addr == `CR_CONFIG}}     & cp0_config
                 | {32{cp0_addr == `CR_CONFIG1}}    & cp0_config1;
                //  | {32{cp0_addr == `CR_TAGLO}}      & cp0_taglo;

endmodule
