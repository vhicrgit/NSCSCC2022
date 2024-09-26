module tlb
#(
    parameter TLBNUM = 16
)
(
    input                       clk,
    input                       reset,

    // search port 0
    input  [              18:0] s0_vpn2,     
    input                       s0_odd_page,     
    input  [               7:0] s0_asid,     
    output                      s0_found,     
    output [$clog2(TLBNUM)-1:0] s0_index,   
    output [              19:0] s0_pfn,     
    output [               2:0] s0_c,     
    output                      s0_d,     
    output                      s0_v, 
 
    // search port 1     
    input  [              18:0] s1_vpn2,     
    input                       s1_odd_page,     
    input  [               7:0] s1_asid,     
    output                      s1_found,     
    output [$clog2(TLBNUM)-1:0] s1_index,      
    output [              19:0] s1_pfn,     
    output [               2:0] s1_c,     
    output                      s1_d,     
    output                      s1_v, 
 
    // write port     
    input                       we,         
    input  [$clog2(TLBNUM)-1:0] w_index,     
    input  [              18:0] w_vpn2,     
    input  [               7:0] w_asid,     
    input                       w_g,     
    input  [              19:0] w_pfn0,     
    input  [               2:0] w_c0,     
    input                       w_d0,
    input                       w_v0,     
    input  [              19:0] w_pfn1,     
    input  [               2:0] w_c1,     
    input                       w_d1,     
    input                       w_v1, 
 
    // read port     
    input  [$clog2(TLBNUM)-1:0] r_index,     
    output [              18:0] r_vpn2,     
    output [               7:0] r_asid,     
    output                      r_g,     
    output [              19:0] r_pfn0,     
    output [               2:0] r_c0,     
    output                      r_d0,     
    output                      r_v0,     
    output [              19:0] r_pfn1,     
    output [               2:0] r_c1,     
    output                      r_d1,     
    output                      r_v1 
);

reg [18:0]          tlb_vpn2[TLBNUM-1:0];
reg [7:0]           tlb_asid[TLBNUM-1:0];
reg                 tlb_g   [TLBNUM-1:0];
reg [19:0]          tlb_pfn0[TLBNUM-1:0];
reg [2:0]           tlb_c0  [TLBNUM-1:0];
reg                 tlb_d0  [TLBNUM-1:0];
reg                 tlb_v0  [TLBNUM-1:0];
reg [19:0]          tlb_pfn1[TLBNUM-1:0];
reg [2:0]           tlb_c1  [TLBNUM-1:0];
reg                 tlb_d1  [TLBNUM-1:0];
reg                 tlb_v1  [TLBNUM-1:0];

wire [TLBNUM-1:0] match0;
wire [TLBNUM-1:0] match1;



// search 
wire   [$clog2(TLBNUM)-1:0]     s0_index_arr[TLBNUM-1:0];
wire   [$clog2(TLBNUM)-1:0]     s1_index_arr[TLBNUM-1:0];

genvar i;
generate for(i=0;i<TLBNUM;i=i+1)begin   
    assign match0[i] = (s0_vpn2 == tlb_vpn2[i]) && ((s0_asid == tlb_asid[i]) || tlb_g[i]);
    assign match1[i] = (s1_vpn2 == tlb_vpn2[i]) && ((s1_asid == tlb_asid[i]) || tlb_g[i]);
    if(i == 0)begin
        assign s0_index_arr[i] =  0;//{$clog2(TLBNUM){match0[i]}} & i; 
        assign s1_index_arr[i] =  0;//{$clog2(TLBNUM){match1[i]}} & i;
    end
    else begin
        assign s0_index_arr[i] = s0_index_arr[i-1] | ({$clog2(TLBNUM){match0[i]}} & i);
        assign s1_index_arr[i] = s1_index_arr[i-1] | ({$clog2(TLBNUM){match1[i]}} & i);
    end
end
endgenerate

assign      s0_found = |match0;
assign      s1_found = |match1;

assign      s0_index =  s0_index_arr[TLBNUM-1];
assign      s1_index =  s1_index_arr[TLBNUM-1];

assign      s0_pfn   =  s0_odd_page ? tlb_pfn1[s0_index] : tlb_pfn0[s0_index];
assign      s0_c     =  s0_odd_page ? tlb_c1  [s0_index] : tlb_c0  [s0_index];
assign      s0_d     =  s0_odd_page ? tlb_d1  [s0_index] : tlb_d0  [s0_index];
assign      s0_v     =  s0_odd_page ? tlb_v1  [s0_index] : tlb_v0  [s0_index];

assign      s1_pfn   =  s1_odd_page ? tlb_pfn1[s1_index] : tlb_pfn0[s1_index];
assign      s1_c     =  s1_odd_page ? tlb_c1  [s1_index] : tlb_c0  [s1_index];
assign      s1_d     =  s1_odd_page ? tlb_d1  [s1_index] : tlb_d0  [s1_index];
assign      s1_v     =  s1_odd_page ? tlb_v1  [s1_index] : tlb_v0  [s1_index];



// write
genvar k;
generate for(k=0;k<TLBNUM;k=k+1)begin
    always@(posedge clk)begin
        if(reset)begin
            tlb_vpn2[k] <= 0;
            tlb_asid[k] <= 0;    
            tlb_g   [k] <= 0;
            tlb_pfn0[k] <= 0;
            tlb_c0  [k] <= 0;
            tlb_d0  [k] <= 0;
            tlb_v0  [k] <= 0;
            tlb_pfn1[k] <= 0;
            tlb_c1  [k] <= 0;
            tlb_d1  [k] <= 0;
            tlb_v1  [k] <= 0;
        end
        else if(we && w_index == k)begin
            tlb_vpn2[k] <= w_vpn2;
            tlb_asid[k] <= w_asid;    
            tlb_g   [k] <= w_g;
            tlb_pfn0[k] <= w_pfn0;
            tlb_c0  [k] <= w_c0;
            tlb_d0  [k] <= w_d0;
            tlb_v0  [k] <= w_v0;
            tlb_pfn1[k] <= w_pfn1;
            tlb_c1  [k] <= w_c1;
            tlb_d1  [k] <= w_d1;
            tlb_v1  [k] <= w_v1;
        end
    end
end
endgenerate


// read 
assign r_vpn2 = tlb_vpn2[r_index];
assign r_asid = tlb_asid[r_index];
assign r_g    = tlb_g   [r_index];
assign r_pfn0 = tlb_pfn0[r_index];
assign r_c0   = tlb_c0  [r_index];
assign r_d0   = tlb_d0  [r_index];
assign r_v0   = tlb_v0  [r_index];
assign r_pfn1 = tlb_pfn1[r_index];
assign r_c1   = tlb_c1  [r_index];
assign r_d1   = tlb_d1  [r_index];
assign r_v1   = tlb_v1  [r_index];

endmodule