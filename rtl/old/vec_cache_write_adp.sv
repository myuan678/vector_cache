module vec_cache_write_adp 
    import vector_cache_pkg::*;
    (
        input  logic clk           ,
        input  logic rst_n         ,
        input  logic req_vld       ,
        input  logic req_pld       ,
        input  logic evict_data    ,
        input  logic adp_done      ,
        output logic wr_adp_done   ,
        output logic adp_rdy       ,
        output logic adp_done_idx
    );
    evict_pld_t evict_pld;
    logic evict_vld ;
    logic wr_data;
    always_ff@(posedge clk or negedge rst_n) begin
        if      (!rst_n)        evict_vld <= 1'b0;
        else if (req_vld)       evict_vld <= 1'b1;
    end

    always_ff@(posedge clk) begin
        evict_pld.tag      <= evict_req_pld.tag    ;
        evict_pld.index    <= evict_req_pld.index  ;
        evict_pld.offset   <= evict_req_pld.offset ;
        evict_pld.rd_last  <= evict_req_pld.rd_last;
        evict_pld.evict_id <= evict_req_id         ;
    end

    assign wr_data = evict_data;

endmodule