`ifndef MYCPU_H
    `define MYCPU_H

    `define CACHE_TO_FIFO_WD    102
    `define BR_BUS_WD           33
    `define FIFO_TO_DS_BUS_WD   102
    `define SIMPLE_ES_BUS_WD    216
    `define COMPLEX_ES_BUS_WD   187
    `define DECODE_BUS_WD       252
    `define ES_TO_M1S_BUS0_WD   240
    `define ES_TO_M1S_BUS1_WD   76
    `define M1S_TO_M2S_BUS0_WD  168
    `define M1S_TO_M2S_BUS1_WD  75
    `define M2S_TO_WS_BUS_WD    75
    `define WS_TO_RF_BUS_WD     41
    
    `define CR_STATUS           8'b01100_000
    `define CR_CAUSE            8'b01101_000
    `define CR_EPC              8'b01110_000
    `define CR_COUNT            8'b01001_000
    `define CR_COMPARE          8'b01011_000
    `define CR_BADVADDR         8'b01000_000
    `define CR_INDEX            8'b00000_000
    `define CR_CONFIG           8'b10000_000
    `define CR_CONFIG1          8'b10000_001

    //forwarding
    // `define M1S_0               3'd1
    // `define M1S_1               3'd2
    // `define M2S_0               3'd3
    // `define M2S_1               3'd4
    `define ES_FWD_BUS          39
    `define M1S_FWD_BUS         39
    `define M2S_FWD_BUS         39
    `define WS_FWD_BUS          43
    
    //multi
    `define MUL_CNT             4'd6

    
    `define EXC_INT             8'h00
    `define EXC_MOD             8'h01
    `define EXC_ADEL            8'h04
    `define EXC_ADES            8'h05
    `define EXC_SYS             8'h08
    `define EXC_BP              8'h09
    `define EXC_RI              8'h0a
    `define EXC_OV              8'h0c

    `define TLBNUM              16

    `define FETCH_NORMAL        2'b00
    `define FETCH_ONE_MORE      2'b01
    `define FETCH_TWO_MORE      2'b10

    `define GET_NEXT            2'b00
    `define GET_DELAY_SLOT      2'b01
    `define GET_BRANCH_TARGET   2'b10

    //issue mode
    `define NULL                2'h0
    `define SIGNLE              2'h1
    `define DUAL                2'h2
    //inst type
    `define COMPLEX             2'h0
    `define SIMPLE              2'h1
  
`endif
