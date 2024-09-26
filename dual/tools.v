module decoder_5_32(
    input  [ 4:0] in,
    output [31:0] out
);

genvar i;
generate for (i=0; i<32; i=i+1) begin : gen_for_dec_5_32
    assign out[i] = (in == i);
end endgenerate

endmodule


module decoder_6_64(
    input  [ 5:0] in,
    output [63:0] out
);

genvar i;
generate for (i=0; i<63; i=i+1) begin : gen_for_dec_6_64
    assign out[i] = (in == i);
end endgenerate

endmodule


// module  write_buffer(
//     input                               clk,
//     input                               resetn,

//     input                               ren,
//     input                               wen,
//     input   [127:0]                     data_in,
//     output  [31:0]                      data_out,
//     output  [2:0]                       w_count
// );

// reg  [1:0] now_ptr;
// reg  [2:0] count;        
// reg  [127-1:0]   buffer;

// assign data_out = buffer[now_ptr];

// always@(posedge clk)begin
//     if(!resetn)begin
//         now_ptr <= 0;
//         count   <= 0;
//     end
//     else begin
//         if(ren && (count != 0))begin
//             now_ptr <= (now_ptr == 0) ? 0 : (now_ptr -1);
//             count   <= count -1;
//         end
//         else if(wen && (count == 0))begin
//             now_ptr <= 2'b11;
//             count   <= 3'h4;
//             buffer  <=  data_in;
//         end
//     end
// end

// assign w_count = count;

// endmodule
