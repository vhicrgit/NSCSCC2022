module dcache( 
input                   clk,
input                   reset,
 
input                   valid ,
input                   op,
input [7:0]             index,
input [19:0]            tag,
input [3:0]             offset,
input [3:0]             wstrb,
input [31:0]            wdata,
output reg              addr_ok,
output reg              data_ok,
output [31:0]           rdata,
input                   is_uncache,

input                   cache_op,
input                   cache_addruse,
input                   cache_wb,
input                   cache_we,
input [19:0]            TagLo_tag,
input                   TagLo_v,
input                   TagLo_d,

input  wire             rd_rdy,
output  reg             rd_req,
output  reg [2:0]       rd_type,      
output  reg [31:0]      rd_addr,
input  wire             ret_valid,
input  wire             ret_last,
input  wire [31:0]      ret_data,
output  reg             wr_req,
output  reg [2:0]       wr_type,
output  reg [31:0]      wr_addr,
output  reg [3:0]       wr_wstrb,
output  reg [127:0]     wr_data,
input   wire            wr_rdy  
);
reg [2:0] main_state;
reg [2:0] next_main_state;
reg write_state;
reg next_write_state;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg  [7:0]  addr;
//data bank
wire  [31:0] data_ram_0_0;
wire  [31:0] data_ram_0_1;
wire  [31:0] data_ram_0_2;
wire  [31:0] data_ram_0_3;
wire  [31:0] data_ram_1_0;
wire  [31:0] data_ram_1_1;
wire  [31:0] data_ram_1_2;
wire  [31:0] data_ram_1_3;
wire  [31:0] data_ram_2_0;
wire  [31:0] data_ram_2_1;
wire  [31:0] data_ram_2_2;
wire  [31:0] data_ram_2_3;
wire  [31:0] data_ram_3_0;
wire  [31:0] data_ram_3_1;
wire  [31:0] data_ram_3_2;
wire  [31:0] data_ram_3_3;
wire        ena_0_0     ;
wire        ena_0_1     ;
wire        ena_0_2     ;
wire        ena_0_3     ;
wire        ena_1_0     ;
wire        ena_1_1     ;
wire        ena_1_2     ;
wire        ena_1_3     ;
wire        ena_2_0     ;
wire        ena_2_1     ;
wire        ena_2_2     ;
wire        ena_2_3     ;
wire        ena_3_0     ;
wire        ena_3_1     ;
wire        ena_3_2     ;
wire        ena_3_3     ;
wire [3:0]  wea_0_0     ;
wire [3:0]  wea_0_1     ;
wire [3:0]  wea_0_2     ;
wire [3:0]  wea_0_3     ;
wire [3:0]  wea_1_0     ;
wire [3:0]  wea_1_1     ;
wire [3:0]  wea_1_2     ;
wire [3:0]  wea_1_3     ;
wire [3:0]  wea_2_0     ;
wire [3:0]  wea_2_1     ;
wire [3:0]  wea_2_2     ;
wire [3:0]  wea_2_3     ;
wire [3:0]  wea_3_0     ;
wire [3:0]  wea_3_1     ;
wire [3:0]  wea_3_2     ;
wire [3:0]  wea_3_3     ;
wire [7:0] data_addr_0_0;
wire [7:0] data_addr_0_1;
wire [7:0] data_addr_0_2;
wire [7:0] data_addr_0_3;
wire [7:0] data_addr_1_0;
wire [7:0] data_addr_1_1;
wire [7:0] data_addr_1_2;
wire [7:0] data_addr_1_3;
wire [7:0] data_addr_2_0;
wire [7:0] data_addr_2_1;
wire [7:0] data_addr_2_2;
wire [7:0] data_addr_2_3;
wire [7:0] data_addr_3_0;
wire [7:0] data_addr_3_1;
wire [7:0] data_addr_3_2;
wire [7:0] data_addr_3_3;

reg  [31:0]  way0_data_addr;
reg  [31:0]  way1_data_addr;
reg  [31:0]  way2_data_addr;
reg  [31:0]  way3_data_addr;
reg  [31:0] write_data_bram  ;
reg  [31:0]  data_wea_0      ;
reg  [31:0]  data_wea_1      ;
reg  [31:0]  data_wea_2      ;
reg  [31:0]  data_wea_3      ;
reg  [3:0]   way0_data_ena    ;
reg  [3:0]   way1_data_ena    ;
reg  [3:0]   way2_data_ena    ;
reg  [3:0]   way3_data_ena    ;
wire [127:0] way0_data;  
wire [127:0] way1_data; 
wire [127:0] way2_data;  
wire [127:0] way3_data; 
// tagv
wire        way0_tagv_wea ;
wire        way1_tagv_wea ;
wire        way2_tagv_wea ;
wire        way3_tagv_wea ;
wire [20:0] way0_tagv_data;  
wire [20:0] way1_tagv_data; 
wire [20:0] way2_tagv_data;  
wire [20:0] way3_tagv_data; 
wire        way0_tagv_ena ;
wire        way1_tagv_ena ;
wire        way2_tagv_ena ;
wire        way3_tagv_ena ;
reg [7:0]    way0_tagv_addr;
reg [7:0]    way1_tagv_addr;
reg [7:0]    way2_tagv_addr;
reg [7:0]    way3_tagv_addr;
reg  [3:0]  tagv_wea      ;
reg  [20:0] write_tagv_data;
//dir
wire way0_dir_en_0;
wire way0_dir_en_1;
wire way0_dir_en_2;
wire way0_dir_en_3;
reg  [7:0] way0_rd_dir_addr;
reg  [7:0] way1_rd_dir_addr;
reg  [7:0] way2_rd_dir_addr;
reg  [7:0] way3_rd_dir_addr;
reg  [7:0] way0_wr_dir_addr;
reg  [7:0] way1_wr_dir_addr;
reg  [7:0] way2_wr_dir_addr;
reg  [7:0] way3_wr_dir_addr;
reg  [3:0] d_en;
reg  write_dir_data;
wire way0_dir_data ;
wire way1_dir_data ;
wire way2_dir_data ;
wire way3_dir_data ;

data_bram_0_0 bank_0_0(.clka(clk),.addra(data_addr_0_0),.dina(write_data_bram),.douta(data_ram_0_0),.ena(ena_0_0),.wea(wea_0_0));
data_bram_0_0 bank_0_1(.clka(clk),.addra(data_addr_0_1),.dina(write_data_bram),.douta(data_ram_0_1),.ena(ena_0_1),.wea(wea_0_1));
data_bram_0_0 bank_0_2(.clka(clk),.addra(data_addr_0_2),.dina(write_data_bram),.douta(data_ram_0_2),.ena(ena_0_2),.wea(wea_0_2));
data_bram_0_0 bank_0_3(.clka(clk),.addra(data_addr_0_3),.dina(write_data_bram),.douta(data_ram_0_3),.ena(ena_0_3),.wea(wea_0_3));
data_bram_0_0 bank_1_0(.clka(clk),.addra(data_addr_1_0),.dina(write_data_bram),.douta(data_ram_1_0),.ena(ena_1_0),.wea(wea_1_0));
data_bram_0_0 bank_1_1(.clka(clk),.addra(data_addr_1_1),.dina(write_data_bram),.douta(data_ram_1_1),.ena(ena_1_1),.wea(wea_1_1));
data_bram_0_0 bank_1_2(.clka(clk),.addra(data_addr_1_2),.dina(write_data_bram),.douta(data_ram_1_2),.ena(ena_1_2),.wea(wea_1_2));
data_bram_0_0 bank_1_3(.clka(clk),.addra(data_addr_1_3),.dina(write_data_bram),.douta(data_ram_1_3),.ena(ena_1_3),.wea(wea_1_3));
data_bram_0_0 bank_2_0(.clka(clk),.addra(data_addr_2_0),.dina(write_data_bram),.douta(data_ram_2_0),.ena(ena_2_0),.wea(wea_2_0));
data_bram_0_0 bank_2_1(.clka(clk),.addra(data_addr_2_1),.dina(write_data_bram),.douta(data_ram_2_1),.ena(ena_2_1),.wea(wea_2_1));
data_bram_0_0 bank_2_2(.clka(clk),.addra(data_addr_2_2),.dina(write_data_bram),.douta(data_ram_2_2),.ena(ena_2_2),.wea(wea_2_2));
data_bram_0_0 bank_2_3(.clka(clk),.addra(data_addr_2_3),.dina(write_data_bram),.douta(data_ram_2_3),.ena(ena_2_3),.wea(wea_2_3));
data_bram_0_0 bank_3_0(.clka(clk),.addra(data_addr_3_0),.dina(write_data_bram),.douta(data_ram_3_0),.ena(ena_3_0),.wea(wea_3_0));
data_bram_0_0 bank_3_1(.clka(clk),.addra(data_addr_3_1),.dina(write_data_bram),.douta(data_ram_3_1),.ena(ena_3_1),.wea(wea_3_1));
data_bram_0_0 bank_3_2(.clka(clk),.addra(data_addr_3_2),.dina(write_data_bram),.douta(data_ram_3_2),.ena(ena_3_2),.wea(wea_3_2));
data_bram_0_0 bank_3_3(.clka(clk),.addra(data_addr_3_3),.dina(write_data_bram),.douta(data_ram_3_3),.ena(ena_3_3),.wea(wea_3_3));
tagv_ram      tagv_0  (.clka(clk),.addra(way0_tagv_addr),.dina(write_tagv_data),.douta(way0_tagv_data),.ena(way0_tagv_ena),.wea(way0_tagv_wea));
tagv_ram      tagv_1  (.clka(clk),.addra(way1_tagv_addr),.dina(write_tagv_data),.douta(way1_tagv_data),.ena(way1_tagv_ena),.wea(way1_tagv_wea));
tagv_ram      tagv_2  (.clka(clk),.addra(way2_tagv_addr),.dina(write_tagv_data),.douta(way2_tagv_data),.ena(way2_tagv_ena),.wea(way2_tagv_wea));
tagv_ram      tagv_3  (.clka(clk),.addra(way3_tagv_addr),.dina(write_tagv_data),.douta(way3_tagv_data),.ena(way3_tagv_ena),.wea(way3_tagv_wea));
dirty_regfile dir_0   (.reset(reset),.clk(clk),.wr_addr(way0_wr_dir_addr),.rd_addr(way0_rd_dir_addr),.en(way0_dir_en),.din(write_dir_data),.dout(way0_dir_data));
dirty_regfile dir_1   (.reset(reset),.clk(clk),.wr_addr(way1_wr_dir_addr),.rd_addr(way1_rd_dir_addr),.en(way1_dir_en),.din(write_dir_data),.dout(way1_dir_data));
dirty_regfile dir_2   (.reset(reset),.clk(clk),.wr_addr(way2_wr_dir_addr),.rd_addr(way2_rd_dir_addr),.en(way2_dir_en),.din(write_dir_data),.dout(way2_dir_data));
dirty_regfile dir_3   (.reset(reset),.clk(clk),.wr_addr(way3_wr_dir_addr),.rd_addr(way3_rd_dir_addr),.en(way3_dir_en),.din(write_dir_data),.dout(way3_dir_data));

assign way0_data={data_ram_0_3,data_ram_0_2,data_ram_0_1,data_ram_0_0};
assign way1_data={data_ram_1_3,data_ram_1_2,data_ram_1_1,data_ram_1_0};
assign way2_data={data_ram_2_3,data_ram_2_2,data_ram_2_1,data_ram_2_0};
assign way3_data={data_ram_3_3,data_ram_3_2,data_ram_3_1,data_ram_3_0};
assign {data_addr_0_3,data_addr_0_2,data_addr_0_1,data_addr_0_0} = way0_data_addr;
assign {data_addr_1_3,data_addr_1_2,data_addr_1_1,data_addr_1_0} = way1_data_addr;
assign {data_addr_2_3,data_addr_2_2,data_addr_2_1,data_addr_2_0} = way2_data_addr;
assign {data_addr_3_3,data_addr_3_2,data_addr_3_1,data_addr_3_0} = way3_data_addr;
assign {ena_0_3,ena_0_2,ena_0_1,ena_0_0} = way0_data_ena;
assign {ena_1_3,ena_1_2,ena_1_1,ena_1_0} = way1_data_ena;
assign {ena_2_3,ena_2_2,ena_2_1,ena_2_0} = way2_data_ena;
assign {ena_3_3,ena_3_2,ena_3_1,ena_3_0} = way3_data_ena;
assign {wea_0_3,wea_0_2,wea_0_1,wea_0_0} = data_wea_0;
assign {wea_1_3,wea_1_2,wea_1_1,wea_1_0} = data_wea_1;
assign {wea_2_3,wea_2_2,wea_2_1,wea_2_0} = data_wea_2;
assign {wea_3_3,wea_3_2,wea_3_1,wea_3_0} = data_wea_3;
assign way0_tagv_ena = ena_0_0 | ena_0_1 |ena_0_2 | ena_0_3;
assign way1_tagv_ena = ena_1_0 | ena_1_1 |ena_1_2 | ena_1_3;
assign way2_tagv_ena = ena_2_0 | ena_2_1 |ena_2_2 | ena_2_3;
assign way3_tagv_ena = ena_2_0 | ena_3_1 |ena_3_2 | ena_3_3;
assign {way3_tagv_wea,way2_tagv_wea,way1_tagv_wea,way0_tagv_wea} = tagv_wea ;

assign {way3_dir_en,way2_dir_en,way1_dir_en,way0_dir_en} = d_en;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg  [70:0] request_buffer; 
reg  [28:0] miss_buffer;  
reg  [47:0] write_buffer;  

wire  request_en;
wire  miss_en_1;
wire  miss_en_2;
wire  miss_clr;
wire  write_en;

assign request_en = (next_main_state == 1);
assign miss_en_1 = (next_main_state == 3 && main_state == 1);
assign miss_en_2 = (main_state == 4 && ret_valid);
assign miss_clr  = (main_state == 3 && next_main_state == 4);
assign write_en = (next_write_state == 1);
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg [1:0] LRU [255:0] ;
wire way0_hit ;
wire way1_hit ;
wire way2_hit ;
wire way3_hit ;
wire cache_hit ;
wire way0_v;
wire way1_v;
wire way2_v;
wire way3_v;
wire way0_d;
wire way1_d;
wire way2_d;
wire way3_d;
wire way_d; 
wire [19:0] way0_tag;
wire [19:0] way1_tag;  
wire [19:0] way2_tag;
wire [19:0] way3_tag;  
wire [ 1:0] replace_way;  
wire [31:0] way0_load_word ; 
wire [31:0] way1_load_word ; 
wire [31:0] way2_load_word ; 
wire [31:0] way3_load_word ; 

assign {way0_tag,way0_v} = way0_tagv_data;
assign {way1_tag,way1_v} = way1_tagv_data;
assign {way2_tag,way2_v} = way2_tagv_data;
assign {way3_tag,way3_v} = way3_tagv_data;

assign way0_hit = way0_v && (way0_tag == request_buffer[59:40]);
assign way1_hit = way1_v && (way1_tag == request_buffer[59:40]);
assign way2_hit = way2_v && (way2_tag == request_buffer[59:40]);
assign way3_hit = way3_v && (way3_tag == request_buffer[59:40]);
assign cache_hit = way0_hit || way1_hit || way2_hit || way3_hit;

assign way_d = (replace_way == 2'b11) ? way3_dir_data :
               (replace_way == 2'b10) ? way2_dir_data :
               (replace_way == 2'b01) ? way1_dir_data :
                way0_dir_data;

assign way0_load_word = way0_data[request_buffer[39:38]*32 +: 32];
assign way1_load_word = way1_data[request_buffer[39:38]*32 +: 32];
assign way2_load_word = way2_data[request_buffer[39:38]*32 +: 32];
assign way3_load_word = way3_data[request_buffer[39:38]*32 +: 32];

assign replace_way =~way0_tagv_data[0] ? 2'b00      :
                    ~way1_tagv_data[0] ? 2'b01      : 
                    ~way2_tagv_data[0] ? 2'b10      :
                    ~way3_tagv_data[0] ? 2'b11      : 
                        LRU[request_buffer[67:60]];
                                        
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire [1:0] hit_way;
wire hazzard;             
wire [31:0] load_res;
wire hit_write;

assign rdata = load_res;  
assign load_res = {32{way0_hit && main_state == 1}} & way0_load_word |
                  {32{way1_hit && main_state == 1}} & way1_load_word |
                  {32{way2_hit && main_state == 1}} & way2_load_word |
                  {32{way3_hit && main_state == 1}} & way3_load_word |
                  {32{(request_buffer[39:38] == miss_buffer[3:2] && ret_valid && main_state == 4)}}& ret_data |
                  {32{request_buffer[70] && request_buffer[68] == 0 && ret_valid && main_state == 4}}& ret_data ;             
assign hit_way = (way3_hit == 1) ? 2'b11 :
                 (way2_hit == 1) ? 2'b10 :
                 (way1_hit == 1) ? 2'b01 :
                                   2'b00;
assign hit_write = (main_state == 1) &&(cache_hit)&(request_buffer[68]);
assign hazzard = ((cache_hit) && (main_state == 1) && (request_buffer[68]) && (offset[3:2] == request_buffer[39:38]) && (op == 0) && (valid) )|
                 ((write_state == 1) && (offset[3:2] == write_buffer[37:36]) && (valid)&& (op == 0));

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
integer i;
always@(posedge clk)begin
    if(reset)begin
        for(i=0;i<256;i=i+1)begin
                    LRU[i] <= 0;
        end
    end
    else if(main_state == 1 && cache_hit)begin
        LRU[request_buffer[67:60]] <= way0_hit;
    end
    else if(main_state == 1 && !cache_hit)begin
        LRU[request_buffer[67:60]] <= ~LRU[request_buffer[67:60]];
    end
end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

always@(posedge clk)begin
    if(reset)begin
        request_buffer <= 0;
    end
    else if(request_en)begin
        request_buffer <= {is_uncache,//70
                           valid,     //69:69
                           op,        //68:68
                           index,     //67:60
                           tag,       //59:40
                           offset,    //39:36
                           wstrb,     //35:32
                           wdata};    //31:0;
    end
end

always@(posedge clk)begin
    if(reset)begin
       miss_buffer <= 0;
    end
    else if(miss_en_1)begin
        miss_buffer[1:0] <= replace_way;
    end
    else if(miss_clr)begin
        miss_buffer[3:2] <= 0;
    end
    else if(miss_en_2)begin
        miss_buffer[3:2] <=  miss_buffer[3:2]+1;
    end
end

always@(posedge clk)begin
    if(reset)begin
       write_buffer <= 0;
    end
    else if(write_en)begin
        write_buffer <={hit_way  ,   //47:46
                        request_buffer[67:60] ,//45  38
                        request_buffer[39:38] ,//37 36
                        request_buffer[35:32] ,//
                        request_buffer[31:0] };
    end
end

always@(posedge clk)begin
        if(reset)begin
            main_state <= 0;
            write_state <= 0;
       end
        else begin
            main_state <= next_main_state;
        write_state <= next_write_state;
        end
end

reg rdy_en;
reg rdy;
always@(posedge clk )begin
    if(reset)begin
        rdy <= 0;
    end
    else if(rdy_en)begin
        rdy <= 1;
    end
    else begin
        rdy <= 0;
    end
end

always@(*)begin
    addr_ok = 0; 
    data_ok = 0;
    rd_req = 0;
    wr_req = 0;
    data_wea_0 =0;      //16
    data_wea_1 =0; 
    data_wea_2 =0;      //16
    data_wea_3 =0; 
    way0_data_ena = 0;  //4
    way1_data_ena = 0;  //4
    way2_data_ena = 0;  //4
    way3_data_ena = 0;  //4
    tagv_wea  =0;       //2
    d_en = 0;           //2
    write_tagv_data =0;
    write_dir_data = 0;
    write_data_bram = 0;
    wr_type = 0;
    rd_type = 0;
    wr_wstrb = 0;
    way0_rd_dir_addr = 0;
    way1_rd_dir_addr = 0;
    way2_rd_dir_addr = 0;
    way3_rd_dir_addr = 0;
    way0_wr_dir_addr = 0;
    way1_wr_dir_addr = 0;
    way2_wr_dir_addr = 0;
    way3_wr_dir_addr = 0;
    way0_tagv_addr = 0;
    way1_tagv_addr = 0;
    way2_tagv_addr = 0;
    way3_tagv_addr = 0;
    way0_data_addr = 0;
    way1_data_addr = 0;
    way2_data_addr = 0;
    way3_data_addr = 0;
    rdy_en = 0;
    case(main_state)
        0:begin
            if((~hazzard && op == 0) | (op == 1))begin
                addr_ok = 1;
            end
            if(valid && ( (~hazzard && op == 0) | (op == 1)))begin
                next_main_state = 1;
                way0_data_ena = 4'b1111;
                way1_data_ena = 4'b1111;
                way2_data_ena = 4'b1111;
                way3_data_ena = 4'b1111;
                way1_tagv_addr = index ;
                way0_tagv_addr = index ;
                way2_tagv_addr = index ;
                way3_tagv_addr = index ;
                //way0_rd_dir_addr = index;
                //way1_rd_dir_addr = index;
                if(op == 0)begin
                    way0_data_addr[offset[3:2] * 8 +: 8] = index;
                    way1_data_addr[offset[3:2] * 8 +: 8] = index;
                    way2_data_addr[offset[3:2] * 8 +: 8] = index;
                    way3_data_addr[offset[3:2] * 8 +: 8] = index;
                end
            end
            else begin
                next_main_state = 0;
            end
        end
        1:begin
            if(cache_hit)begin
                data_ok =1;
            end
            if(cache_hit)begin
                if(valid && op==1)begin
                    addr_ok = 1;
                end 
                else if(valid && op ==0 && ~hazzard)begin
                    addr_ok = 1;
                end
            end                    
            way0_data_ena = 4'b1111;
            way1_data_ena = 4'b1111;
            way2_data_ena = 4'b1111;
            way3_data_ena = 4'b1111;
            way0_rd_dir_addr = request_buffer[67:60];
            way1_rd_dir_addr = request_buffer[67:60];
            way2_rd_dir_addr = request_buffer[67:60];
            way3_rd_dir_addr = request_buffer[67:60];
            if(!cache_hit)begin 
                if(write_state == 0)begin
                    way1_tagv_addr = request_buffer[67:60] ;
                    way0_tagv_addr = request_buffer[67:60] ;
                    way2_tagv_addr = request_buffer[67:60] ;
                    way3_tagv_addr = request_buffer[67:60] ;
                    way0_data_addr = {4{request_buffer[67:60]}};
                    way1_data_addr = {4{request_buffer[67:60]}};
                    way2_data_addr = {4{request_buffer[67:60]}};
                    way3_data_addr = {4{request_buffer[67:60]}};
                end
                if(request_buffer[70])begin
                    if(request_buffer[68])begin
                        next_main_state = 2;
                        rdy_en = 1;
                    end
                    else begin
                        next_main_state = 3;
                    end  
                end
                else begin
                    if(way_d)begin
                        next_main_state = 2;
                        if(write_state == 1)begin
                            rdy_en = 0;
                        end 
                        else begin
                            rdy_en = 1;
                        end
                    end
                    else begin
                        next_main_state = 3;
                    end
                end
            end
            else if(valid && ( (~hazzard && op == 0) | (op == 1)) )begin
                next_main_state = 1;
                way1_tagv_addr = index ;
                way0_tagv_addr = index ;
                way2_tagv_addr = index ;
                way3_tagv_addr = index ;
                if(op == 0)begin
                    way0_data_addr[offset[3:2] * 8 +: 8] = index;
                    way1_data_addr[offset[3:2] * 8 +: 8] = index;
                    way2_data_addr[offset[3:2] * 8 +: 8] = index;
                    way3_data_addr[offset[3:2] * 8 +: 8] = index;
                end
            end
            else begin
                next_main_state = 0;
            end
        end
        2:begin
            if(wr_rdy && rdy)begin
                next_main_state = 3; 
                wr_req =1;
                if(request_buffer[70])begin
                    wr_addr = {request_buffer[59:40],request_buffer[67:60],request_buffer[39:36]};
                    wr_data = request_buffer[31:0];
                    wr_wstrb = request_buffer[35:32];
                    if(request_buffer[32] + request_buffer[33] + request_buffer[34] + request_buffer[35] == 1 )begin
                        wr_type = 3'b000;
                    end
                    else if(request_buffer[32] + request_buffer[33] + request_buffer[34] + request_buffer[35] == 2 )begin
                        wr_type = 3'b001;
                    end
                    else begin
                        wr_type = 3'b010;
                    end
                end
                else begin
                    wr_type = 3'b100;
                    wr_addr = (miss_buffer[1:0] == 2'b11) ? {way3_tag,request_buffer[67:60],4'b0000} :
                              (miss_buffer[1:0] == 2'b10) ? {way2_tag,request_buffer[67:60],4'b0000} :
                              (miss_buffer[1:0] == 2'b01) ? {way1_tag,request_buffer[67:60],4'b0000} :
                                                            {way0_tag,request_buffer[67:60],4'b0000};
                    wr_data = (miss_buffer[1:0] == 2'b11)? way3_data : 
                              (miss_buffer[1:0] == 2'b10)? way2_data :
                              (miss_buffer[1:0] == 2'b01)? way1_data :
                                                           way0_data;
                end
            end
            else begin
                rdy_en = 1;
                next_main_state = 2;
                way0_data_ena = 4'b1111;
                way1_data_ena = 4'b1111;
                way2_data_ena = 4'b1111;
                way3_data_ena = 4'b1111;
                way0_rd_dir_addr = request_buffer[67:60];
                way1_rd_dir_addr = request_buffer[67:60];
                way2_rd_dir_addr = request_buffer[67:60];
                way3_rd_dir_addr = request_buffer[67:60];
                way1_tagv_addr = request_buffer[67:60] ;
                way0_tagv_addr = request_buffer[67:60] ;
                way2_tagv_addr = request_buffer[67:60] ;
                way3_tagv_addr = request_buffer[67:60] ;
                way0_data_addr = {4{request_buffer[67:60]}};
                way1_data_addr = {4{request_buffer[67:60]}};
                way2_data_addr = {4{request_buffer[67:60]}};
                way3_data_addr = {4{request_buffer[67:60]}};
            end
        end
        3:begin
            rd_req = 1;
            if(request_buffer[70])begin
                if(request_buffer[32] + request_buffer[33] + request_buffer[34] + request_buffer[35] == 1 )begin
                    rd_type = 3'b000;
                end
                else if(request_buffer[32] + request_buffer[33] + request_buffer[34] + request_buffer[35] == 2 )begin
                    rd_type = 3'b001;
                end
                else begin
                    rd_type = 3'b010;
                end
            end
            else begin
                rd_type = 3'b100;
            end

            if(rd_rdy)begin
                next_main_state = 4;
                if(request_buffer[70])begin
                    rd_addr = {request_buffer[59:40],request_buffer[67:60],request_buffer[39:36]};
                end
                else begin
                    rd_addr = { request_buffer[59:40] , request_buffer[67:60] ,4'b0000};
                end
            end
            else begin
                next_main_state = 3;
            end
        end
        4:begin
            way1_wr_dir_addr = request_buffer[67:60] ;
            way0_wr_dir_addr = request_buffer[67:60] ;
            way2_wr_dir_addr = request_buffer[67:60] ;
            way3_wr_dir_addr = request_buffer[67:60] ;
            way0_data_addr = {4{request_buffer[67:60]}};
            way1_data_addr = {4{request_buffer[67:60]}};
            way2_data_addr = {4{request_buffer[67:60]}};
            way3_data_addr = {4{request_buffer[67:60]}};
            way1_tagv_addr = request_buffer[67:60] ;
            way0_tagv_addr = request_buffer[67:60] ;
            way2_tagv_addr = request_buffer[67:60] ;
            way3_tagv_addr = request_buffer[67:60] ;
            write_dir_data = 1;
            if(ret_valid)begin
                if(request_buffer[70])begin
                    next_main_state = 0;
                    data_ok = 1;
                end 
                else begin   
                    if(request_buffer[39:38] == miss_buffer[3:2])begin
                        data_ok = 1;
                        if(request_buffer[68])begin
                            write_data_bram = request_buffer[31:0];
                        end
                        else begin
                            write_data_bram = ret_data;
                        end
                    end
                    else begin
                        write_data_bram = ret_data;
                    end  

                    if(ret_last)begin
                        next_main_state = 0;
                        write_tagv_data ={request_buffer[59:40],1'b1};
                        if(miss_buffer[1:0] == 2'b11)begin
                            if(request_buffer[68])begin
                                d_en[3] = 1;
                            end
                            tagv_wea[3] =1;        
                            data_wea_3[15:12] = 4'b1111;
                            way3_data_ena[3] =1;
                        end
                        else if(miss_buffer[1:0] == 2'b10)begin
                            if(request_buffer[68])begin
                                d_en[2] = 1;
                            end
                            tagv_wea[2] =1;        
                            data_wea_2[15:12] = 4'b1111;
                            way2_data_ena[3] =1;
                        end
                        else if(miss_buffer[1:0] == 2'b01)begin
                            if(request_buffer[68])begin
                                d_en[1] = 1;
                            end
                            tagv_wea[1] =1;        
                            data_wea_1[15:12] = 4'b1111;
                            way1_data_ena[3] =1;
                        end
                        else begin
                            if(request_buffer[68])begin
                                d_en[0] = 1;
                            end
                            tagv_wea[0] =1;
                            data_wea_0[15:12] = 4'b1111;
                            way0_data_ena[3] =1;
                        end
                    end
                    else begin
                        next_main_state = 4;
                        if(miss_buffer[1:0] == 2'b11)begin
                            if(miss_buffer[3:2]== 0)begin
                                data_wea_3[3:0] = 4'b1111;
                                way3_data_ena[0] =1;
                            end
                            else if(miss_buffer[3:2] == 1)begin
                                data_wea_3[7:4] = 4'b1111;
                                way3_data_ena[1] =1;
                            end
                            else if(miss_buffer[3:2] ==2 )begin
                                data_wea_3[11:8] = 4'b1111;
                                way3_data_ena[2] =1;
                            end
                        end
                        else if(miss_buffer[1:0] == 2'b10)begin
                            if(miss_buffer[3:2]==0)begin
                                data_wea_2[3:0] = 4'b1111;
                                way2_data_ena[0] =1;
                            end
                            else if(miss_buffer[3:2] == 1)begin
                                data_wea_2[7:4] = 4'b1111;
                                way2_data_ena[1] =1;
                            end
                            else if(miss_buffer[3:2] ==2 )begin
                                data_wea_2[11:8] = 4'b1111;
                                way2_data_ena[2] =1;
                            end
                        end
                        else if(miss_buffer[1:0] == 2'b01)begin
                            if(miss_buffer[3:2]==0)begin
                                data_wea_1[3:0] = 4'b1111;
                                way1_data_ena[0] =1;
                            end
                            else if(miss_buffer[3:2] == 1)begin
                                data_wea_1[7:4] = 4'b1111;
                                way1_data_ena[1] =1;
                            end
                            else if(miss_buffer[3:2] ==2 )begin
                                data_wea_1[11:8] = 4'b1111;
                                way1_data_ena[2] =1;
                            end
                        end
                        else begin                
                            if(miss_buffer[3:2]==0)begin
                                data_wea_0[3:0] = 4'b1111;
                                way0_data_ena[0] =1;
                            end
                            else if(miss_buffer[3:2] == 1)begin
                                data_wea_0[7:4] = 4'b1111;
                                way0_data_ena[1] =1;
                            end
                            else if(miss_buffer[3:2] ==2 )begin
                                data_wea_0[11:8] = 4'b1111;
                                way0_data_ena[2] =1;
                            end
                        end
                    end 
                end       
            end
            else if(request_buffer[70] && request_buffer[68] == 1)begin
                data_ok = 1;
                next_main_state = 0;
            end
            else begin
                next_main_state = 4;
            end
        end
    endcase
        
    case(write_state)
        1'b0:begin
            if(hit_write)begin
                next_write_state = 1;
            end
            else begin
                next_write_state = 0;
            end
        end
        1'b1:begin
            way1_wr_dir_addr = write_buffer[45:38];
            way0_wr_dir_addr = write_buffer[45:38];
            way2_wr_dir_addr = write_buffer[45:38];
            way3_wr_dir_addr = write_buffer[45:38];
            way0_data_addr[write_buffer[37:36] * 8 +: 8] = write_buffer[45:38];
            way1_data_addr[write_buffer[37:36] * 8 +: 8] = write_buffer[45:38];
            way2_data_addr[write_buffer[37:36] * 8 +: 8] = write_buffer[45:38];
            way3_data_addr[write_buffer[37:36] * 8 +: 8] = write_buffer[45:38];
            d_en[write_buffer[47:46]] = 1;
            write_dir_data = 1;
            write_data_bram = write_buffer[31:0];
            if(write_buffer[47:46] == 2'b11) begin
                if(write_buffer[37:36]==0)begin
                    data_wea_3[3:0] = write_buffer[35:32];
                    way3_data_ena[0] =1;
                end
                else if(write_buffer[37:36] == 1)begin
                    data_wea_3[7:4] = write_buffer[35:32];
                    way3_data_ena[1] =1;
                 end
                else if(write_buffer[37:36] ==2 )begin
                    data_wea_3[11:8] = write_buffer[35:32];
                    way3_data_ena[2] =1;
                end
                else begin
                    data_wea_3[15:12] = write_buffer[35:32];
                    way3_data_ena[3] =1;
                end
            end
            else if(write_buffer[47:46] == 2'b10) begin
                if(write_buffer[37:36]==0)begin
                    data_wea_2[3:0] = write_buffer[35:32];
                    way2_data_ena[0] =1;
                end
                else if(write_buffer[37:36] == 1)begin
                    data_wea_2[7:4] = write_buffer[35:32];
                    way2_data_ena[1] =1;
                 end
                else if(write_buffer[37:36] ==2 )begin
                    data_wea_2[11:8] = write_buffer[35:32];
                    way2_data_ena[2] =1;
                end
                else begin
                    data_wea_2[15:12] = write_buffer[35:32];
                    way2_data_ena[3] =1;
                end
            end
            else if(write_buffer[47:46] == 2'b01) begin
                if(write_buffer[37:36]==0)begin
                    data_wea_1[3:0] = write_buffer[35:32];
                    way1_data_ena[0] =1;
                end
                else if(write_buffer[37:36] == 1)begin
                    data_wea_1[7:4] = write_buffer[35:32];
                    way1_data_ena[1] =1;
                 end
                else if(write_buffer[37:36] ==2 )begin
                    data_wea_1[11:8] = write_buffer[35:32];
                    way1_data_ena[2] =1;
                end
                else begin
                    data_wea_1[15:12] = write_buffer[35:32];
                    way1_data_ena[3] =1;
                end
            end
            else begin
                if(write_buffer[37:36]==0)begin
                    data_wea_0[3:0] = write_buffer[35:32];
                    way0_data_ena[0] =1;
                end
                else if(write_buffer[37:36] == 1)begin
                    data_wea_0[7:4] = write_buffer[35:32];
                    way0_data_ena[1] =1;
                end
                else if(write_buffer[37:36] ==2 )begin
                    data_wea_0[11:8] = write_buffer[35:32];
                    way0_data_ena[2] =1;
                end
                else begin
                    data_wea_0[15:12] = write_buffer[35:32];
                    way0_data_ena[3] =1;
                end
            end
            if(hit_write )begin
                next_write_state = 1;           
            end
            else begin
                next_write_state =0;
            end
        end
    endcase
 end
reg [31:0] count_1;
always@(posedge clk)begin
    if(reset) begin
        count_1 <= 0;
    end
    else if(write_state)begin
        count_1 <= count_1 + 1;
    end
    else begin
        count_1 <= count_1;
    end
end
endmodule
