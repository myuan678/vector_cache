module read_DB_agent 
    import vector_cache_pkg::*; 
    #( 
    parameter integer unsigned ENTRY_NUM = 16,
    parameter integer unsigned ENTRY_ID_WIDTH = $clog2(ENTRY_NUM),
    parameter integer unsigned READ_SRAM_DELAY = 10,
    parameter integer unsigned RDB_DATA_RDY_DELAY = 15, //是指sram中的数据已经被读到了RDB中，现在可以发起对RDB的读请求，将数据给US
    parameter integer unsigned TO_US_DONE_DELAY   =20 
) (
    input  logic                            clk                 ,
    input  logic                            rst_n               ,
    output logic                            to_us_done          , //means rob entry release
    output logic [DB_ENTRY_IDX_WIDTH-1:0]   to_us_done_idx      ,

    input  logic                            dataram_rd_vld      ,
    input  arb_out_req_t                    dataram_rd_pld      ,
    output logic                            dataram_rd_rdy      ,

    output logic                            alloc_vld           ,
    output logic [DB_ENTRY_IDX_WIDTH-1:0]   alloc_idx           ,
    input  logic                            alloc_rdy           ,
    input  logic                            RDB_rdy             ,

    input  logic [1023:0]                   ram_to_rdb_data_in  ,
    input  logic                            ram_to_rdb_data_vld ,
    output us_data_pld_t                    rdb_to_us_data_pld  ,
    output logic                            rdb_to_us_data_vld  
    );

    logic rdb_mem_en;
    logic rdb_wr_en ;
    logic rdb_addr  ;
    //assign write_rdb_vld = rdb_mem_en && rdb_wr_en;
    rdb_agent u_rdb_agent( 
        .clk            (clk            ),
        .rst_n          (rst_n          ),
        .to_us_done     (to_us_done     ),
        .to_us_done_idx (to_us_done_idx ),
        .dataram_rd_vld (dataram_rd_vld ),
        .dataram_rd_pld (dataram_rd_pld ),
        .dataram_rd_rdy (dataram_rd_rdy ),
        .alloc_vld      (alloc_vld      ),
        .alloc_idx      (alloc_idx      ),
        .alloc_rdy      (alloc_rdy      ),
        .RDB_rdy        (1'b1           ),
        .rdb_mem_en     (rdb_mem_en     ),
        .rdb_wr_en      (rdb_wr_en      ),
        .rdb_addr       (rd_addr        ));

    readDB u_readDB (
        .clk                    (clk                ),
        .rst_n                  (rst_n              ),
        .rdb_addr               (rdb_addr           ),
        .rdb_mem_en             (rdb_mem_en         ),
        .rdb_wr_en              (rdb_wr_en          ),
        .ram_to_rdb_data_in     (ram_to_rdb_data_in ),
        .ram_to_rdb_data_vld    (ram_to_rdb_data_vld),
        .rdb_to_us_data_pld     (rdb_to_us_data_pld ),
        .rdb_to_us_data_vld     (rdb_to_us_data_vld ));



        always_ff@(posedge clk)begin
            if(!(ram_to_rdb_data_vld && (rdb_mem_en && rdb_wr_en)) )begin
                $error("WRIET RDB ERROR: addr && data not match");
            end
        end
endmodule

  