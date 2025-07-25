module readDB 
    import vector_cache_pkg::*;
    (
    input  logic            clk                 ,
    input  logic            rst_n               ,
    input  read_rdb_addr_t  rdb_addr            ,
    input  logic            rdb_mem_en          ,
    input  logic            rdb_wr_en           ,
    input  group_data_pld_t ram_to_rdb_data_in  ,
    input  logic            ram_to_rdb_data_vld ,
    output us_data_pld_t    rdb_to_us_data_pld  ,
    output logic            rdb_to_us_data_vld  
);

    logic [1023:0]      data_in   ;
    logic [1023:0]      data_out  ;
    read_rdb_addr_t     rdb_addr_d;

    always_ff@(posedge clk )begin
        rdb_addr_d <= rdb_addr ;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                          rdb_to_us_data_vld <= 1'b0;
        else if(rdb_mem_en && ~rdb_wr_en)   rdb_to_us_data_vld <= 1'b1;
    end
    assign rdb_to_us_data_pld.data         = data_out                   ;
    assign rdb_to_us_data_pld.txnid        = rdb_addr_d.txnid           ;
    assign rdb_to_us_data_pld.rob_entry_id = rdb_addr_d.rob_entry_id    ;
    assign rdb_to_us_data_pld.sideband     = rdb_addr_d.sideband        ;
    assign data_in                         = ram_to_rdb_data_in.data    ;


    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(RW_DB_ENTRY_NUM)),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_read_data_buffer (
        .clk    (clk        ),
        .en     (rdb_mem_en ),
        .wr_en  (rdb_wr_en  ),
        .addr   (rdb_addr.db_entry_id),
        .wr_data(data_in    ),
        .rd_data(data_out   )
    );

endmodule