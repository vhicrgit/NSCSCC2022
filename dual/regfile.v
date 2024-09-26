module regfile(
    input         clk,
    // READ PORT 0
    input  [ 4:0] raddr0,
    output [31:0] rdata0,
    // READ PORT 1
    input  [ 4:0] raddr1,
    output [31:0] rdata1,
    // READ PORT 2
    input  [ 4:0] raddr2,
    output [31:0] rdata2,
    // READ PORT 3
    input  [ 4:0] raddr3,
    output [31:0] rdata3,
    // WRITE PORT 1
    input  [ 3:0]    we0,
    input  [ 4:0] waddr0,
    input  [31:0] wdata0,
    // WRITE PORT 2
    input  [ 3:0]    we1,
    input  [ 4:0] waddr1,
    input  [31:0] wdata1
);
reg [31:0] rf[31:0];
wire [31: 0] final_wdata0;
wire [31: 0] final_wdata1;

assign final_wdata0[ 7: 0] = we0[0] ? wdata0[ 7: 0] : rf[waddr0][ 7: 0];
assign final_wdata0[15: 8] = we0[1] ? wdata0[15: 8] : rf[waddr0][15: 8];
assign final_wdata0[23:16] = we0[2] ? wdata0[23:16] : rf[waddr0][23:16];
assign final_wdata0[31:24] = we0[3] ? wdata0[31:24] : rf[waddr0][31:24];

assign final_wdata1[ 7: 0] = we1[0] ? wdata1[ 7: 0] : rf[waddr1][ 7: 0];
assign final_wdata1[15: 8] = we1[1] ? wdata1[15: 8] : rf[waddr1][15: 8];
assign final_wdata1[23:16] = we1[2] ? wdata1[23:16] : rf[waddr1][23:16];
assign final_wdata1[31:24] = we1[3] ? wdata1[31:24] : rf[waddr1][31:24];

//WRITE
//port 1 write first
always @(posedge clk) begin
    if (we0[0] || we0[1] || we0[2] || we0[3])begin
        rf[waddr0] <= final_wdata0;
    end
    if (we1[0] || we1[1] || we1[2] || we1[3])begin
        rf[waddr1] <= final_wdata1;
    end
end



//READ OUT 0
assign rdata0 = (raddr0==5'b0) ? 32'b0
              : (we1 && waddr1 == raddr0) ? final_wdata1
              : (we0 && waddr0 == raddr0) ? final_wdata0
              : rf[raddr0];

//READ OUT 1
assign rdata1 = (raddr1==5'b0) ? 32'b0 
              : (we1 && waddr1 == raddr1) ? final_wdata1
              : (we0 && waddr0 == raddr1) ? final_wdata0
              : rf[raddr1];

//READ OUT 2
assign rdata2 = (raddr2==5'b0) ? 32'b0
              : (we1 && waddr1 == raddr2) ? final_wdata1
              : (we0 && waddr0 == raddr2) ? final_wdata0
              : rf[raddr2];

//READ OUT 3
assign rdata3 = (raddr3==5'b0) ? 32'b0 
              : (we1 && waddr1 == raddr3) ? final_wdata1
              : (we0 && waddr0 == raddr3) ? final_wdata0
              : rf[raddr3];

endmodule