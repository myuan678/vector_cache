module vec_cache_wr_tag_buf 
    import vector_cache_pkg::*;
    ( 
        input  logic                        clk             ,
        input  logic                        rst_n           ,
        input  logic                        buf_update_en   ,
        //input  input_req_pld_t              req_pld         ,
        input  logic [TAG_WIDTH-1:0]        tag             ,
        input  logic [INDEX_WIDTH-1:0]      index           ,
        //input  logic [$clog2(WAY_NUM)-1:0]  evict_way       ,
        input  logic [WAY_NUM-1:0]          evict_way_oh    ,

        input  logic                        tag_buf_rdy     ,
        output logic                        tag_buf_vld     ,
        output wr_buf_pld_t                 tag_buf_pld
    );


    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            tag_buf_vld <= 'b0;
        end
        else begin
            if(buf_update_en)       tag_buf_vld <= 1'b1;
            else if(tag_buf_rdy)    tag_buf_vld <= 1'b0;
        end
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            tag_buf_pld   <= '{default: 0};
        end
        else if(buf_update_en)begin
            tag_buf_pld.index   <= index        ;
            tag_buf_pld.tag     <= tag          ;
            tag_buf_pld.way_oh  <= evict_way_oh ;
        end
    end

endmodule