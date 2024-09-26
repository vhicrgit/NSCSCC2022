`ifndef MYCPU_H
    `define MYCPU_H

    `define BR_BUS_WD           33
    `define F1S_TO_F2S_BUS_WD   40
    `define F2S_TO_DS_BUS_WD    104
    `define DS_TO_ES_BUS_WD     251
    `define ES_TO_M1S_BUS_WD    239
    `define M1S_TO_M2S_BUS_WD   167
    `define M2S_TO_WS_BUS_WD    74
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
    `define M1S                 2'd1
    `define M2S                 2'd2
    `define WB                  2'd3
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

  
`endif
