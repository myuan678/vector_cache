module vec_cache_tag_dirty_array #( 
    parameter integer unsigned ADDR_WIDTH = 10,
    parameter integer unsigned DATA_WIDTH = 4
    )(
    input  logic                     clk            ,
    input  logic                     rst_n          ,
    input  logic                     wr_en_0        ,
    input  logic                     wr_en_1        ,
    input  logic [DATA_WIDTH-1:0]    bit_wr_en_0    ,
    input  logic [DATA_WIDTH-1:0]    bit_wr_en_1    ,
    input  logic [ADDR_WIDTH-1:0]    addr_0         ,
    input  logic [ADDR_WIDTH-1:0]    addr_1         ,
    input  logic                     wr_data_0      ,
    input  logic                     wr_data_1      ,

    output logic [DATA_WIDTH-1:0]    rd_data_0      ,
    output logic [DATA_WIDTH-1:0]    rd_data_1   
);
    logic [DATA_WIDTH-1        :0]   tag_dirty[2**ADDR_WIDTH-1:0] ;


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int i = 0; i < 2**ADDR_WIDTH; i++) begin
                tag_dirty[i] <= '0;
            end
        end 
        else begin
            if (wr_en_0)begin
                for(int j=0;j<DATA_WIDTH;j=j+1)begin
                    if(bit_wr_en_0[j]) tag_dirty[addr_0][j] <= wr_data_0;
                end
            end  
            if (wr_en_1) begin
                for(int j=0;j<DATA_WIDTH;j=j+1)begin
                    if(bit_wr_en_1[j]) tag_dirty[addr_1][j] <= wr_data_1;
                end
            end 
        end
    end

    always_ff @(posedge clk) begin
        if(wr_en_0) rd_data_0 <= tag_dirty[addr_0];
        if(wr_en_1) rd_data_1 <= tag_dirty[addr_1];
    end
    
endmodule