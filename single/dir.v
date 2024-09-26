`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/06/30 10:25:09
// Design Name: 
// Module Name: dirty_regfile
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


module dirty_regfile(
input       reset,
input       clk ,
input [7:0] rd_addr,
input [7:0] wr_addr,
input       en  ,
input       din ,
output      dout
    );
    
reg [255:0] dirty;
/*genvar i;
generate for(i=0;i<256;i=i+1)begin
    always@(posedge clk)begin
        if(reset)begin
            dirty[i] <= 21'h0;
        end
        else if(en&&(i==addr))begin
            dirty[i] <= din;
        end
    end
end
endgenerate*/
integer i; 
always@(posedge clk)begin
        if(reset)begin
            for(i=0;i<256;i=i+1)begin
                    dirty[i] <= 0;
            end
        end
        else if(en)begin
            dirty[wr_addr] <= din;
        end
    end


assign dout = (rd_addr ==  wr_addr && en) ? din : dirty[rd_addr]; 


endmodule
