`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2022/07/23 14:46:41
// Design Name: 
// Module Name: icache_dir
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


module icache_dir(
input       reset,
input       clk ,
input [7:0] addr,
input       en  ,
input       din ,
output      dout
    );
    
reg [255:0] dirty;

integer i; 
always@(posedge clk)begin
        if(reset)begin
            for(i=0;i<256;i=i+1)begin
                    dirty[i] <= 0;
            end
        end
        else if(en)begin
            dirty[addr] <= din;
        end
    end


assign dout = dirty[addr]; 


endmodule

