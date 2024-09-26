  `include "mycpu.h"

 module cache2axi (
     input                               aclk             ,
     input                               aresetn          ,        
     // Dcache interface
     // r
     input                               dcache_rd_req    ,
     input        [2:0]                  dcache_rd_type   ,
     input        [31:0]                 dcache_rd_addr   ,
     output                              dcache_rd_rdy    ,
     output                              dcache_ret_valid ,
     output                              dcache_ret_last  ,
     output       [31:0]                 dcache_ret_data  ,
     // w
     input                               dcache_wr_req    ,
     input        [2:0]                  dcache_wr_type   ,
     input        [31:0]                 dcache_wr_addr   ,
     input        [3:0]                  dcache_wr_wstrb  ,
     input        [127:0]                dcache_wr_data   ,
     output                              dcache_wr_rdy    ,
     //Icache interface
     // r
     input                               icache_rd_req    ,
     input        [2:0]                  icache_rd_type   ,
     input        [31:0]                 icache_rd_addr   ,
     output                              icache_rd_rdy    ,
     output                              icache_ret_valid ,
     output                              icache_ret_last  ,
     output       [31:0]                 icache_ret_data  ,
     // 
     input                               icache_wr_req    ,
     input        [2:0]                  icache_wr_type   ,
     input        [31:0]                 icache_wr_addr   ,
     input        [3:0]                  icache_wr_wstrb  ,
     input        [127:0]                icache_wr_data   ,
     output                              icache_wr_rdy    ,
     // axi interface
     // read request (ar)
     output       [3 :0]                 axi_arid   ,
     output       [31:0]                 axi_araddr ,
     output       [7 :0]                 axi_arlen  ,
     output       [2 :0]                 axi_arsize ,
     output       [1 :0]                 axi_arburst,
     output       [1 :0]                 axi_arlock ,
     output       [3 :0]                 axi_arcache,
     output       [2 :0]                 axi_arprot ,
     output                              axi_arvalid,
     input                               axi_arready,

     // read response (r)
     input       [3 :0]                  axi_rid    ,
     input       [31:0]                  axi_rdata  ,
     input       [1 :0]                  axi_rresp  ,
     input                               axi_rlast  ,
     input                               axi_rvalid ,
     output                              axi_rready ,

     // write request (aw)
     output      [3 :0]                  axi_awid   ,
     output      [31:0]                  axi_awaddr ,
     output      [7 :0]                  axi_awlen  ,
     output      [2 :0]                  axi_awsize ,
     output      [1 :0]                  axi_awburst,
     output      [1 :0]                  axi_awlock ,
     output      [3 :0]                  axi_awcache,
     output      [2 :0]                  axi_awprot ,
     output                              axi_awvalid,
     input                               axi_awready,

     // write data (w)
     output       [3 :0]                  axi_wid    ,
     output       [31:0]                  axi_wdata  ,
     output       [3 :0]                  axi_wstrb  ,
     output                               axi_wlast  ,
     output                               axi_wvalid ,
     input                                axi_wready ,

     // write response (b)
     input       [3 :0]                  axi_bid    ,
     input       [1 :0]                  axi_bresp  ,
     input                               axi_bvalid ,
     output                              axi_bready 
 );

// some constants

assign  axi_arburst     = 2'b01;
assign  axi_arlock      = 2'b00;
assign  axi_arcache     = 4'b0000;
assign  axi_arprot      = 3'b000;

assign  axi_awid        = 4'b0001;
assign  axi_awburst     = 2'b01;
assign  axi_awlock      = 2'b00;
assign  axi_awcache     = 4'b0000;
assign  axi_awprot      = 3'b000;

assign  axi_wid         = 4'b0001;

/*
读地�?与数据�?�道
*/

reg                 ar_pass_busy;
reg                 r_pass_busy;

reg   [3:0]         r_count;

reg   [3:0]         arid;
reg   [31:0]        araddr;
reg   [2:0]         artype;

wire        relevant;

// reg         rready;


always@(posedge aclk)begin
    if(!aresetn)begin
        ar_pass_busy <= 1'b0;
    end
    else begin
        if(!ar_pass_busy && !r_pass_busy && !relevant)begin
            if(dcache_rd_req || icache_rd_req)begin
                ar_pass_busy <= 1'b1;
            end
        end
        else begin
            if(axi_arready && axi_arvalid)begin
                ar_pass_busy <= 1'b0;
            end
        end
    end
end

always@(posedge aclk)begin
    if(!aresetn)begin
        r_pass_busy <= 1'b0;
    end
    else begin
        if(!r_pass_busy)begin
            if(ar_pass_busy && axi_arvalid && axi_arready)begin
                r_pass_busy <= 1'b1;
                if(!arid[1] && artype == 3'b111)begin
                    r_count <= 4'd8;
                end
                else if(arid[0] && artype == 3'b100)begin
                    r_count <= 4'd4;
                end
                else begin
                    r_count <= 4'd1;
                end
            end
        end
        else begin
            if(axi_rvalid)begin
                if(r_count == 3'd1)begin
                    r_pass_busy <= 1'b0;
                end
                r_count <= r_count -1;
            end

        end
    end   
end


always@(posedge aclk)begin
    if(!aresetn)begin
        arid    <= 4'b0000;
        araddr  <= 0;
        artype  <= 0;
    end
    else begin
        if(!ar_pass_busy && (dcache_rd_req || icache_rd_req) && !r_pass_busy && !relevant)begin
            arid    <= {3'b000,dcache_rd_req};
            araddr  <= {32{dcache_rd_req}}&dcache_rd_addr | {32{icache_rd_req&&!dcache_rd_req}}&icache_rd_addr;
            artype  <= {3{dcache_rd_req}}&dcache_rd_type | {3{icache_rd_req&&!dcache_rd_req}}&icache_rd_type;
        end
    end
end


assign axi_araddr   = araddr;
assign axi_arsize   = artype == 3'b000 ? 3'b000:
                      artype == 3'b001 ? 3'b001:
                                3'b010 ;
assign axi_arid     = arid;
assign axi_arlen    = (artype == 3'b100) ? 8'd3 :
                      (artype == 3'b111) ? 8'd7 :
                       8'h0;
                      
assign axi_arvalid  = ar_pass_busy;
assign axi_rready   = r_pass_busy;
 
assign dcache_rd_rdy    = !ar_pass_busy && !r_pass_busy && !relevant;
assign dcache_ret_valid = axi_rid[0] && axi_rvalid && r_pass_busy;
assign dcache_ret_last  = axi_rid[0] && axi_rvalid && (r_count == 1 ||artype != 3'b100) &&r_pass_busy ;
assign dcache_ret_data  = {32{axi_rid[0]}} & axi_rdata;


assign icache_rd_rdy    = !dcache_rd_req & !ar_pass_busy && !r_pass_busy && !relevant;
assign icache_ret_valid = !axi_rid[0] && axi_rvalid;
assign icache_ret_last  = !axi_rid[0] && axi_rvalid && (r_count == 1 ||artype != 3'b111) ;
assign icache_ret_data  = {32{!axi_rid[0]}} & axi_rdata;


/*
写地�?与数据�?�道
*/

reg                 aw_pass_busy;
reg                 w_pass_busy;
reg                 b_pass_busy;

reg     [31:0]      awaddr;
// reg                 wlast;
reg     [2:0]       awtype;
reg     [3:0]       wstrb;
reg     [31:0]      wdata1;




// reg                 write_buffer_ren;
// reg                 write_buffer_wen;
// reg   [127:0]       write_buffer_datain;
// wire  [31:0]        write_buffer_dataout;
// wire                write_buffer_empty;

reg     [127:0]      write_buffer_data;
reg     [2:0]        buffer_count;

wire    [31:0]       wdata2;

always@(posedge aclk)begin
    if(!aresetn)begin
        aw_pass_busy <= 1'b0;
    end
    else begin
        if(!aw_pass_busy)begin
            if(!w_pass_busy && buffer_count == 0 &&dcache_wr_req && !b_pass_busy )begin
                aw_pass_busy <= 1'b1;
            end
        end
        else begin
            if(axi_awready && axi_awvalid)begin
                aw_pass_busy <= 1'b0;
            end
        end
    end
end

always@(posedge aclk)begin
    if(!aresetn)begin
        w_pass_busy <= 1'b0;
        buffer_count <= 3'h0;
    end
    else begin
        if(!w_pass_busy)begin
            if(!aw_pass_busy &&buffer_count == 0 &&dcache_wr_req && !b_pass_busy)begin
                w_pass_busy <= 1'b1;
                if(dcache_wr_type == 3'b100)begin
                    buffer_count <= 3'h4;
                end
            end
        end
        else begin
            if(axi_wready && axi_wvalid )begin
                if(buffer_count == 1 || awtype != 3'b100)begin
                    w_pass_busy <= 1'b0;
                end     
                if(awtype == 3'b100)begin
                    buffer_count <= buffer_count - 1;
                end             
            end
        end
    end
end

// assign wdata2 = buffer_count == 3'h4 ? write_buffer_data[127:96]:
//                 buffer_count == 3'h3 ? write_buffer_data[95:64]:
//                 buffer_count == 3'h2 ? write_buffer_data[63:32]:
//                 write_buffer_data[31:0];

assign wdata2 = buffer_count == 3'h4 ? write_buffer_data[31:0]:
                buffer_count == 3'h3 ? write_buffer_data[63:32]:
                buffer_count == 3'h2 ? write_buffer_data[95:64]:
                write_buffer_data[127:96];


always@(posedge aclk)begin
    if(!aresetn)begin
        b_pass_busy <= 1'b0;
    end
    else begin
        if(!b_pass_busy)begin
            if(!w_pass_busy&& !aw_pass_busy && buffer_count == 0 && dcache_wr_req)begin
                b_pass_busy <= 1'b1;
            end
        end
        else begin
            if(axi_bready && axi_bvalid)begin
                b_pass_busy <= 1'b0;
            end
        end
    end
end

always@(posedge aclk)begin
    if(!aresetn)begin
        write_buffer_data   <= 128'h0;
        awaddr              <= 32'h0;    
        awtype              <= 3'h0;
        wstrb               <= 4'h0;
        wdata1              <= 32'h0;
    end
    else if(buffer_count == 0 && dcache_wr_req && !aw_pass_busy && !w_pass_busy)begin
        write_buffer_data   <= dcache_wr_data;
        awaddr              <= dcache_wr_addr;
        awtype              <= dcache_wr_type;
        wstrb               <= dcache_wr_wstrb& {4{dcache_wr_type != 3'b100}} | {4{dcache_wr_type == 3'b100}};
        wdata1              <= dcache_wr_data[31:0];
    end
end




// write_buffer  write_buffer1(
//     .clk            (aclk),
//     .resetn         (aresetn),
//     .ren            (write_buffer_ren),
//     .wen            (write_buffer_wen),
//     .data_in        (write_buffer_datain),
//     .data_out       (write_buffer_dataout),
//     .w_count        (write_buffer_wcount)
// );


assign      relevant =     (icache_rd_addr == axi_awaddr || dcache_rd_addr == axi_awaddr) && (aw_pass_busy||w_pass_busy || b_pass_busy);


assign      axi_awaddr     = awaddr;
assign      axi_awlen      = (awtype == 3'b100) ? 8'h3 : 8'h0;
assign      axi_awsize     = awtype == 3'b000 ? 3'b000:
                             awtype == 3'b001 ? 3'b001:
                                                3'b010;
assign      axi_awvalid    = aw_pass_busy ;



assign      axi_wdata      = (awtype == 3'b100 )? wdata2 :wdata1 ;
assign      axi_wstrb      =  wstrb;
assign      axi_wlast      = w_pass_busy && (buffer_count == 1 || awtype != 3'b100);       
assign      axi_wvalid     = w_pass_busy  ;

assign      axi_bready     = b_pass_busy && axi_bvalid;

assign      dcache_wr_rdy  = !aw_pass_busy && !w_pass_busy && !b_pass_busy&& (buffer_count == 0);

endmodule