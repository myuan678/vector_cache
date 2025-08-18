module vec_cache_wr_tag_buf 
    import vector_cache_pkg::*;
    ( 
        input  logic                        clk             ,
        input  logic                        rst_n           ,
        input  logic                        buf_update_en   ,
        input  logic                        buf_clean_en    ,
        input  input_req_pld_t              req_pld         ,
        input  logic [$clog2(WAY_NUM)-1:0]  evict_way       ,

        output logic                        wr_tag_buf_vld  ,
        output wr_buf_pld_t                 wr_tag_buf_pld
    );


    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            wr_tag_buf_vld <= 'b0;
        end
        else begin
            if(buf_update_en)       wr_tag_buf_vld <= 1'b1;
            else if(buf_clean_en)   wr_tag_buf_vld <= 1'b0;
        end
    end

    always_ff@(posedge clk)begin
        wr_tag_buf_pld.index   <= req_pld.cmd_addr.index;
        wr_tag_buf_pld.tag     <= req_pld.cmd_addr.tag;
        wr_tag_buf_pld.way     <= evict_way;
    end

endmodule