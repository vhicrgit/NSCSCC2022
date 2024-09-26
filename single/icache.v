module icache( 
input                    clk,
input                    reset,
//CPU
input                    valid ,
input  [7:0]             index,
input  [18:0]            tag,
input  [4:0]             offset,
output reg               addr_ok,
output reg               data_ok,
output [31:0]            rdata,
input                    is_uncache,

input   wire             rd_rdy   ,
output  reg              rd_req   ,
output  reg  [2:0]       rd_type  ,      
output  reg  [31:0]      rd_addr  ,
input   wire             ret_valid,
input   wire             ret_last ,
input   wire [31:0]      ret_data
);

//enum    {IDIE,LOOK_UP,MISS,REPLACE,REFILE} cache_state; 
reg [2:0] main_state;
reg [2:0] next_main_state;
//enum    {IDIE,WRITE} write_state;
reg write_state;
reg next_write_state;

/////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg   [ 7:0] addr        ;
wire  [31:0] data_ram_0_0;
wire  [31:0] data_ram_0_1;
wire  [31:0] data_ram_0_2;
wire  [31:0] data_ram_0_3;
wire  [31:0] data_ram_0_4;
wire  [31:0] data_ram_0_5;
wire  [31:0] data_ram_0_6;
wire  [31:0] data_ram_0_7;
wire  [31:0] data_ram_1_0;
wire  [31:0] data_ram_1_1;
wire  [31:0] data_ram_1_2;
wire  [31:0] data_ram_1_3;
wire  [31:0] data_ram_1_4;
wire  [31:0] data_ram_1_5;
wire  [31:0] data_ram_1_6;
wire  [31:0] data_ram_1_7;
wire        ena_0_0     ;
wire        ena_0_1     ;
wire        ena_0_2     ;
wire        ena_0_3     ;
wire        ena_0_4     ;
wire        ena_0_5     ;
wire        ena_0_6     ;
wire        ena_0_7     ;
wire        ena_1_0     ;
wire        ena_1_1     ;
wire        ena_1_2     ;
wire        ena_1_3     ;
wire        ena_1_4     ;
wire        ena_1_5     ;
wire        ena_1_6     ;
wire        ena_1_7     ;
wire [3:0]  wea_0_0     ;
wire [3:0]  wea_0_1     ;
wire [3:0]  wea_0_2     ;
wire [3:0]  wea_0_3     ;
wire [3:0]  wea_0_4     ;
wire [3:0]  wea_0_5     ;
wire [3:0]  wea_0_6     ;
wire [3:0]  wea_0_7     ;
wire [3:0]  wea_1_0     ;
wire [3:0]  wea_1_1     ;
wire [3:0]  wea_1_2     ;
wire [3:0]  wea_1_3     ;
wire [3:0]  wea_1_4     ;
wire [3:0]  wea_1_5     ;
wire [3:0]  wea_1_6     ;
wire [3:0]  wea_1_7     ;

reg  [31:0]  write_data_bram;
reg  [31:0]  data_wea_0      ;
reg  [31:0]  data_wea_1      ;
reg  [7:0]   way0_data_ena    ;
reg  [7:0]   way1_data_ena    ;
wire [255:0] way0_data;  
wire [255:0] way1_data;  
// tagv
wire        way0_tagv_wea ;
wire        way1_tagv_wea ;
wire [19:0] way0_tagv_data;  
wire [19:0] way1_tagv_data;  
wire        way0_tagv_ena ;
wire        way1_tagv_ena ;
reg  [1:0]  tagv_wea      ;
reg  [19:0] write_tagv_data;


data_bram_0_0 bank_0_0(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_0),.ena(ena_0_0),.wea(wea_0_0));
data_bram_0_0 bank_0_1(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_1),.ena(ena_0_1),.wea(wea_0_1));
data_bram_0_0 bank_0_2(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_2),.ena(ena_0_2),.wea(wea_0_2));
data_bram_0_0 bank_0_3(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_3),.ena(ena_0_3),.wea(wea_0_3));
data_bram_0_0 bank_0_4(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_4),.ena(ena_0_4),.wea(wea_0_4));
data_bram_0_0 bank_0_5(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_5),.ena(ena_0_5),.wea(wea_0_5));
data_bram_0_0 bank_0_6(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_6),.ena(ena_0_6),.wea(wea_0_6));
data_bram_0_0 bank_0_7(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_0_7),.ena(ena_0_7),.wea(wea_0_7));
data_bram_0_0 bank_1_0(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_0),.ena(ena_1_0),.wea(wea_1_0));
data_bram_0_0 bank_1_1(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_1),.ena(ena_1_1),.wea(wea_1_1));
data_bram_0_0 bank_1_2(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_2),.ena(ena_1_2),.wea(wea_1_2));
data_bram_0_0 bank_1_3(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_3),.ena(ena_1_3),.wea(wea_1_3));
data_bram_0_0 bank_1_4(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_4),.ena(ena_1_4),.wea(wea_1_4));
data_bram_0_0 bank_1_5(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_5),.ena(ena_1_5),.wea(wea_1_5));
data_bram_0_0 bank_1_6(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_6),.ena(ena_1_6),.wea(wea_1_6));
data_bram_0_0 bank_1_7(.clka(clk),.addra(addr),.dina(write_data_bram),.douta(data_ram_1_7),.ena(ena_1_7),.wea(wea_1_7));
icache_tagv_ram      tagv_0  (.clka(clk),.addra(addr),.dina(write_tagv_data),.douta(way0_tagv_data),.ena(way0_tagv_ena),.wea(way0_tagv_wea));
icache_tagv_ram      tagv_1  (.clka(clk),.addra(addr),.dina(write_tagv_data),.douta(way1_tagv_data),.ena(way1_tagv_ena),.wea(way1_tagv_wea));
icache_dir dir_0   (.reset(reset),.clk(clk),.addr(addr),.en(way0_dir_en),.din(write_dir_data),.dout(way0_dir_data));
icache_dir dir_1   (.reset(reset),.clk(clk),.addr(addr),.en(way1_dir_en),.din(write_dir_data),.dout(way1_dir_data));


assign way0_data={data_ram_0_7,data_ram_0_6,data_ram_0_5,data_ram_0_4,data_ram_0_3,data_ram_0_2,data_ram_0_1,data_ram_0_0};
assign way1_data={data_ram_1_7,data_ram_1_6,data_ram_1_5,data_ram_1_4,data_ram_1_3,data_ram_1_2,data_ram_1_1,data_ram_1_0};
assign {ena_0_7,ena_0_6,ena_0_5,ena_0_4,ena_0_3,ena_0_2,ena_0_1,ena_0_0} = way0_data_ena;
assign {ena_1_7,ena_1_6,ena_1_5,ena_1_4,ena_1_3,ena_1_2,ena_1_1,ena_1_0} = way1_data_ena;
assign {wea_0_7,wea_0_6,wea_0_5,wea_0_4,wea_0_3,wea_0_2,wea_0_1,wea_0_0} = data_wea_0;
assign {wea_1_7,wea_1_6,wea_1_5,wea_1_4,wea_1_3,wea_1_2,wea_1_1,wea_1_0} = data_wea_1;
assign way0_tagv_ena = ena_0_0 | ena_0_1 |ena_0_2 | ena_0_3 | ena_0_4 | ena_0_5 |ena_0_6 | ena_0_7;
assign way1_tagv_ena = ena_1_0 | ena_1_1 |ena_1_2 | ena_1_3 | ena_1_4 | ena_1_5 |ena_1_6 | ena_1_7;
assign {way1_tagv_wea,way0_tagv_wea} = tagv_wea ;

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
reg  [70:0] request_buffer; 
reg  [4:0] miss_buffer;    
wire  request_en;
wire  miss_en_1;
wire  miss_en_2;
wire  miss_clr;

assign request_en = (next_main_state == 1);
assign miss_en_1 = (next_main_state == 3 && main_state == 1);
assign miss_en_2 = (main_state == 4 && ret_valid);
assign miss_clr  = (main_state == 3 && next_main_state == 4);
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire way0_hit ;  //�??0璺綋鍓嶆槸鍚﹀懡涓?
wire way1_hit ;  //�??1璺綋鍓嶆槸鍚﹀懡涓?
wire cache_hit ; //褰撳墠cache鍛戒�?
wire way0_v;     //�??0璺殑鏈夋晥�??
wire way1_v;     //�??1璺殑鏈夋晥�?
wire [18:0] way0_tag;   //�??0璺殑tag
wire [18:0] way1_tag;   //�??1璺殑tag
wire replace_way;            //瑕佹浛鎹㈢殑�??
wire [31:0] way0_load_word ; //�??0璺?氳繃offset鐗囬?夊悗寰楀�?32浣嶆暟鎹?
wire [31:0] way1_load_word ; //�??1璺?氳繃offset鐗囬?夊悗寰楀�?32浣嶆暟鎹?


assign {way0_tag,way0_v} = way0_tagv_data;
assign {way1_tag,way1_v} = way1_tagv_data;

assign way0_hit = way0_v && (way0_tag == request_buffer[59:41]);   
assign way1_hit = way1_v && (way1_tag == request_buffer[59:41]);
assign cache_hit = way0_hit || way1_hit;

assign way0_load_word = way0_data[request_buffer[40:38]*32 +: 32];  
assign way1_load_word = way1_data[request_buffer[40:38]*32 +: 32];

assign replace_way =~way0_tagv_data[0] ? 0 :
                    ~way1_tagv_data[0] ? 1 :
                                    {$random} % 1;                                     
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

wire [31:0] load_res; 

assign rdata = load_res;  
assign load_res = {32{way0_hit}} & way0_load_word |
                  {32{way1_hit}} & way1_load_word |
                  {32{(request_buffer[40:38] == miss_buffer[3:1] && ret_valid && main_state == 4)}}& ret_data |
                  {32{request_buffer[70] && request_buffer[68] == 0 && ret_valid && main_state == 4}}& ret_data ;            

//////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
wire op;
wire [31:0]wdata;
wire [3:0] wstrb;
assign op = 0;

always@(posedge clk)begin
    if(reset)begin
        request_buffer <= 0;
    end
    else if(request_en)begin
        request_buffer <= {is_uncache,//70
                           valid,     //69:69
                           op,        //68:68
                           index,     //67:60
                           tag,       //59:41
                           offset,    //40:36
                           wstrb,     //35:32
                           wdata};    //31:0;
    end
end

always@(posedge clk)begin
    if(reset)begin
       miss_buffer <= 0;
    end
    else if(miss_en_1)begin
        miss_buffer[0] <= replace_way;
    end
    else if(miss_clr)begin
        miss_buffer[3:1] <= 0;
    end
    else if(miss_en_2)begin
        miss_buffer[3:1] <=  miss_buffer[3:1]+1;
    end
end

always@(posedge clk)begin
    if(reset)begin
        main_state <= 0;
    end
    else begin
        main_state <= next_main_state;
    end
end

always@(*)begin
    addr =0;            //8
    addr_ok = 0; 
    data_ok = 0;
    rd_req = 0;
    data_wea_0 =0;      //16
    data_wea_1 =0; 
    way0_data_ena = 0;  //4
    way1_data_ena = 0;  //4
    tagv_wea  =0;       //2
    write_tagv_data =0;
    rd_type = 0;
    case(main_state)
        0:begin
            addr_ok = 1; 
            way0_data_ena = 8'b11111111;
            way1_data_ena = 8'b11111111;
            if(valid)begin
                next_main_state = 1;
                addr = index;
            end
            else begin
                next_main_state = 0;
            end
        end
        1:begin
            if(cache_hit)begin
                data_ok =1;
                addr_ok = valid;
            end   
            way0_data_ena = 8'b11111111;
            way1_data_ena = 8'b11111111;              
            if(!cache_hit)begin 
                next_main_state = 3;
                addr = request_buffer[67:60];
             end
             else if(valid)begin 
                next_main_state = 1;
                addr = index;
             end
             else begin 
                next_main_state = 0 ;
             end
        end
        2:begin
        end
        3:begin
            rd_req = 1;
            if(request_buffer[70])begin
                 rd_type = 3'b010;
            end
            else begin
                rd_type = 3'b111;
            end
            if(rd_rdy)begin
                next_main_state = 4;
                if(request_buffer[70])begin
                    rd_addr = {request_buffer[59:41],request_buffer[67:60],request_buffer[40:36]};
                end
                else begin
                    rd_addr = { request_buffer[59:41] , request_buffer[67:60] ,5'b00000}; 
                end
            end
            else begin
                next_main_state = 3;
            end
        end
        4:begin
            addr = request_buffer[67:60]; 
            if(ret_valid)begin
                if(request_buffer[70])begin
                    next_main_state = 0;
                    data_ok = 1;
                    write_data_bram = ret_data;
                end 
                else begin   
                    if(request_buffer[40:38] == miss_buffer[3:1])begin
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
                        write_tagv_data ={request_buffer[59:41],1'b1};
                        if(miss_buffer[0])begin
                            tagv_wea[1] =1;        
                            data_wea_1[31:28] = 4'b1111;
                            way1_data_ena[7] =1;
                        end
                        else begin
                            tagv_wea[0] =1;
                            data_wea_0[31:28] = 4'b1111;
                            way0_data_ena[7] =1;
                        end
                    end
                    else begin
                        next_main_state = 4;
                        if(miss_buffer[0])begin
                            if(miss_buffer[3:1]== 0)begin
                                data_wea_1[3:0] = 4'b1111;
                                way1_data_ena[0] = 1;
                            end
                            else if(miss_buffer[3:1] == 1)begin
                                data_wea_1[7:4] = 4'b1111;
                                way1_data_ena[1] = 1;
                            end
                            else if(miss_buffer[3:1] == 2 )begin
                                data_wea_1[11:8] = 4'b1111;
                                way1_data_ena[2] = 1;
                            end
                            else if(miss_buffer[3:1] == 3 )begin
                                data_wea_1[15:12] = 4'b1111;
                                way1_data_ena[3] = 1;
                            end
                            else if(miss_buffer[3:1] == 4 )begin
                                data_wea_1[19:16] = 4'b1111;
                                way1_data_ena[4] = 1;
                            end
                            else if(miss_buffer[3:1] == 5 )begin
                                data_wea_1[23:20] = 4'b1111;
                                way1_data_ena[5] = 1;
                            end
                            else if(miss_buffer[3:1] == 6 )begin
                                data_wea_1[27:24] = 4'b1111;
                                way1_data_ena[6] = 1;
                            end
                        end
                        else begin
                            if(miss_buffer[3:1]== 0)begin
                                data_wea_0[3:0] = 4'b1111;
                                way0_data_ena[0] = 1;
                            end
                            else if(miss_buffer[3:1] == 1)begin
                                data_wea_0[7:4] = 4'b1111;
                                way0_data_ena[1] = 1;
                            end
                            else if(miss_buffer[3:1] == 2 )begin
                                data_wea_0[11:8] = 4'b1111;
                                way0_data_ena[2] = 1;
                            end
                            else if(miss_buffer[3:1] == 3 )begin
                                data_wea_0[15:12] = 4'b1111;
                                way0_data_ena[3] = 1;
                            end
                            else if(miss_buffer[3:1] == 4 )begin
                                data_wea_0[19:16] = 4'b1111;
                                way0_data_ena[4] = 1;
                            end
                            else if(miss_buffer[3:1] == 5 )begin
                                data_wea_0[23:20] = 4'b1111;
                                way0_data_ena[5] = 1;
                            end
                            else if(miss_buffer[3:1] == 6 )begin
                                data_wea_0[27:24] = 4'b1111;
                                way0_data_ena[6] = 1;
                            end
                        end
                    end 
                end       
            end
            else begin
                next_main_state = 4;
            end
        end
        default: begin
            next_main_state = 0; 
        end
        endcase
    end
endmodule
