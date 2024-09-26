module BHT #(
    parameter index_len= 8,
    parameter tag_len = 32-index_len-2,
    parameter index_size = 1 << index_len
)
(
    input            clk        ,
    input            rst        ,

    //predict
    input  [31:0]    pc_query   ,
    // output           pred_hit   ,
    // output           pred_use   ,
    output [31:0]    pred_target,

    //update
    input  [31:0]    br_pc      ,
    input  [31:0]    br_target  , 
    input            br_is      ,
    input            br_update
);

// reg       [65:0]     update_buffer;
// wire      [31:0]     br_pc_r;
// wire      [31:0]     br_target_r;
// wire                 br_true_r;
// wire                 br_update_r;

// assign  {br_pc_r,
//         br_target_r,
//         br_true_r,
//         br_update_r} = update_buffer;

reg  [31:0]             br_target_buffer[0:index_size-1];
reg  [tag_len-1:0]      br_tag_buffer[0:index_size-1];
reg  [1:0]              br_status_buffer[0:index_size-1];
reg  [index_size-1:0]   br_valid;




wire [index_len-1:0] rindex_addr;
wire [tag_len-1:0]   rtag_addr;
wire [index_len-1:0] windex_addr;
wire [tag_len-1:0]   wtag_addr;  

wire                 r_hit;

assign rindex_addr = pc_query[31-tag_len:2];
assign rtag_addr   = pc_query[31:31-tag_len+1];
assign windex_addr = br_pc[31-tag_len:2];
assign wtag_addr   = br_pc[31:31-tag_len+1];


//predict
assign r_hit       = br_valid[rindex_addr] && (br_tag_buffer[rindex_addr] == rtag_addr);
assign pred_target = r_hit ? br_target_buffer[rindex_addr] : pc_query+8;
// assign pred_use    = br_status_buffer[rindex_addr][1];
// assign pred_hit    = r_hit;

always@(posedge clk)begin
    if(rst)begin
        br_valid <= 0;
    end
    else if(br_update)begin
        br_valid[windex_addr] <= 1'b1;
        br_tag_buffer[windex_addr]    <= wtag_addr;
        br_target_buffer[windex_addr] <= br_target;
    end
end

always@(posedge clk)begin
    if(rst)begin
        
    end
    else begin      
        case(br_status_buffer[windex_addr])
                2'b00:begin
                    if(~br_is)  br_status_buffer[windex_addr] <= 2'b01;
                end
                2'b01:begin
                    if(~br_is)  br_status_buffer[windex_addr] <= 2'b10;
                    else            br_status_buffer[windex_addr] <= 2'b00;
                end
                2'b10:begin
                    if(~br_is)  br_status_buffer[windex_addr] <= 2'b01;
                    else            br_status_buffer[windex_addr] <= 2'b11;
                end
                2'b11:begin
                    if(~br_is)  br_status_buffer[windex_addr] <= 2'b11;
                end
                default:            br_status_buffer[windex_addr] <= {~br_is,1'b0};

        endcase
    end
end


// always@(posedge clk)begin
//     if(rst)begin    
//         update_buffer <= 0;
//     end
//     else begin
//         update_buffer <= {br_pc,br_target,br_true,br_update};
//     end
// end

endmodule

// module BHT #(
//     parameter index_len= 8,
//     parameter tag_len = 32-index_len-2
// )
// (
//     input            clk        ,
//     input            rst        ,

//     input            b_or_j     ,

//     input  [31:0]    pc_query   ,
//     output [31:0]    npc_target ,

//     input  [31:0]    br_pc      ,
//     input  [31:0]    br_target  , 
//     input            br_is_true ,
//     input            br_is      
// );

// reg       [65:0]     write_buffer;
// wire      [31:0]     br_pc_r;
// wire      [31:0]     br_target_r;
// wire                 br_is_r;
// wire                 br_is_true_r;

// assign  {br_pc_r,br_target_r,br_is_r,br_is_true_r} = write_buffer;

// parameter index_size = 1 << index_len;

// reg  [31:0]         npc_target_buffer[0:index_size-1];
// reg  [2:0]          br_status_buffer[0:index_size-1];

// wire                 rmatch;
// wire                 hit;

// wire [index_len-1:0] rindex_addr;


// wire [index_len-1:0] windex_addr;



// assign rindex_addr = pc_query[31-tag_len:2];
// assign windex_addr = br_pc_r[31-tag_len:2];

// assign hit =  b_or_j &br_status_buffer[rindex_addr][1];

// // assign npc_target  = {32{hit}}&npc_target_buffer[rindex_addr] | {32{!hit}}& (pc_query+8);
// assign npc_target = pc_query+8;

// // assign npc_target = b_or_j  ? ((br_status_buffer[rindex_addr] == 2'b10 || br_status_buffer[rindex_addr] == 2'b11 ) ?
// //                               npc_target_buffer[rindex_addr] : pc_query + 8 ):
// //                              pc_query + 8;



// integer k;
// always@(posedge clk)begin
//     if(rst)begin
//         for(k=0;k<index_size;k=k+1)begin
//             br_status_buffer[k]        <= 0;
//         end
//     end
//     else if(br_is_r)begin
//         if(br_is_true_r)begin
//             br_status_buffer[windex_addr] <=  br_status_buffer[windex_addr] + {3{br_status_buffer[windex_addr][1] ~^ br_status_buffer[windex_addr][0]}} & 3'b000 | 
//                                                                               {3{(br_status_buffer[windex_addr][1] & ~br_status_buffer[windex_addr][0])}}&3'b001 |
//                                                                               {3{(~br_status_buffer[windex_addr][1] & br_status_buffer[windex_addr][0])}}&3'b111;
//             // br_status_buffer[windex_addr] <=        (br_status_buffer[windex_addr] == 2'b00 )? 2'b00:
//             //                                         (br_status_buffer[windex_addr] == 2'b01 )? 2'b00:
//             //                                         (br_status_buffer[windex_addr] == 2'b10 )? 2'b11:
//             //                                         2'b11;
//         end 
//         else begin
//             br_status_buffer[windex_addr] <=  br_status_buffer[windex_addr] + {3{br_status_buffer[windex_addr][1] }} & 3'b111 |                                                                  
//                                                                               {3{~br_status_buffer[windex_addr][1]}} & 3'b001 ;

//             // br_status_buffer[windex_addr] <=        (br_status_buffer[windex_addr] == 2'b00 )? 2'b01:
//             //                                         (br_status_buffer[windex_addr] == 2'b01 )? 2'b10:
//             //                                         (br_status_buffer[windex_addr] == 2'b10 )? 2'b01:
//             //                                         2'b10;
//         end       
//     end
// end



// always@(posedge clk)begin
//     if(rst)begin
//         for(k=0;k<index_size;k=k+1)begin
//             npc_target_buffer[k]       <= 0;
//         end
//     end
//     else if(br_is_r && !br_is_true_r)begin
//         npc_target_buffer[windex_addr]    <= br_target_r;
//     end
// end



// always@(posedge clk)begin
//     if(rst)begin    
//         write_buffer <= 0;
//     end
//     else begin
//         write_buffer <= {br_pc,br_target,br_is,br_is_true};
//     end
// end

// endmodule
