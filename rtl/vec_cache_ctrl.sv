module vec_cache_ctrl 
    import vector_cache_pkg::*;    
    (
    input  logic                                        clk                                    ,
    input  logic                                        rst_n                                  ,

    input  logic  [7:0]                                 hash_req_vld                           , 
    input  input_req_pld_t                              hash_req_pld [7:0]                     ,
    output logic [7:0]                                  hash_req_rdy                           ,

    //rob out wr_resp
    output logic [3:0]                                  v_wr_resp_vld_0                        , //双发
    output wr_resp_pld_t                                v_wr_resp_pld_0[3:0]                   , //txnid+sideband
    output logic [3:0]                                  v_wr_resp_vld_1                        , //双发
    output wr_resp_pld_t                                v_wr_resp_pld_1[3:0]                   , //txnid+sideband

    //arb out
    output logic                                        read_cmd_vld_west                   ,
    output logic                                        read_cmd_vld_east                   ,
    output logic                                        read_cmd_vld_south                  ,
    output logic                                        read_cmd_vld_north                  ,
    output logic                                        read_cmd_vld_evict                  ,
    output arb_out_req_t                                read_cmd_pld_west                   ,
    output arb_out_req_t                                read_cmd_pld_east                   ,
    output arb_out_req_t                                read_cmd_pld_south                  ,
    output arb_out_req_t                                read_cmd_pld_north                  ,
    output arb_out_req_t                                read_cmd_pld_evict                  ,
    output arb_out_req_t                                read_cmd_to_ram_pld_0               ,
    output arb_out_req_t                                read_cmd_to_ram_pld_1               ,
    output logic                                        read_cmd_to_ram_vld_0               ,
    output logic                                        read_cmd_to_ram_vld_1               ,
    output logic                                        write_cmd_vld_west                  ,
    output logic                                        write_cmd_vld_east                  ,
    output logic                                        write_cmd_vld_south                 ,
    output logic                                        write_cmd_vld_north                 ,
    output logic                                        write_cmd_vld_linefill              ,
    output arb_out_req_t                                write_cmd_pld_west                  ,
    output arb_out_req_t                                write_cmd_pld_east                  ,
    output arb_out_req_t                                write_cmd_pld_south                 ,
    output arb_out_req_t                                write_cmd_pld_north                 ,
    output arb_out_req_t                                write_cmd_pld_linefill              ,

    //AR
    input  logic                                        down_txreq_rdy                          ,
    output logic                                        down_txreq_vld                          ,
    output downstream_txreq_pld_t                       down_txreq_pld                          ,// down_txreq_entry_id into pld

    input  logic                                        linefill_alloc_vld                      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM/4)-1:0]        linefill_alloc_idx                      ,
    output logic                                        linefill_alloc_rdy                      ,

    input  logic                                        rdb_alloc_nfull_west                    ,
    input  logic                                        rdb_alloc_nfull_east                    ,
    input  logic                                        rdb_alloc_nfull_south                   ,
    input  logic                                        rdb_alloc_nfull_north                   ,

    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             evict_clean_idx                         ,
    input  logic                                        evict_clean                             ,
    input  logic                                        ds_txreq_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             ds_txreq_done_idx                       ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]         ds_txreq_done_db_entry_id               ,
    input  logic                                        linefill_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             linefill_done_idx                       ,

    input  logic                                        rd_done_west                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_west                        ,
    input  logic                                        rd_done_east                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_east                        ,
    input  logic                                        rd_done_south                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_south                       ,
    input  logic                                        rd_done_north                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_north                       ,

    input  logic                                        wr_done_west                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_west                        ,
    input  logic                                        wr_done_east                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_east                        ,
    input  logic                                        wr_done_south                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_south                       ,
    input  logic                                        wr_done_north                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_north                       ,
    //Bresp
    input  logic                                        evict_done_resp_vld                     ,//Bresp evict done
    input  bresp_pld_t                                  evict_done_resp_pld                     ,//Bresp //txnid+sideband
    output logic                                        evict_done_resp_rdy                               //Bresp 
);

    logic                                               tag_req_vld_0                       ;
    logic                                               tag_req_vld_1                       ;
    input_req_pld_t                                     tag_req_pld_0                       ;
    input_req_pld_t                                     tag_req_pld_1                       ;
    logic                                               tag_req_rdy                         ;
    hzd_mshr_pld_t                                      v_mshr_entry_pld[MSHR_ENTRY_NUM-1:0];
    logic                                               mshr_alloc_vld_0                    ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]                    mshr_alloc_idx_0                    ;
    logic                                               mshr_alloc_rdy_0                    ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]                    mshr_alloc_idx_1                    ;
    logic                                               mshr_alloc_vld_1                    ; 
    logic                                               mshr_alloc_rdy_1                    ;
    logic                                               mshr_update_en_0                    ;
    mshr_entry_t                                        mshr_update_pld_0                   ;
    logic                                               mshr_update_en_1                    ;
    mshr_entry_t                                        mshr_update_pld_1                   ;

    vec_cache_8to2_req_arbiter #(
        .REQ_NUM        (8),
        .ENTRY_IDX_WIDTH(MSHR_ENTRY_IDX_WIDTH)
    ) u_8to2_req_arb (
        .clk                            (clk                        ),
        .rst_n                          (rst_n                      ),
        .v_req_vld                      (hash_req_vld[7:0]          ),
        .v_req_pld                      (hash_req_pld[7:0]          ),
        .v_req_rdy                      (hash_req_rdy               ),
        .mshr_alloc_vld_0               (mshr_alloc_vld_0           ),
        .mshr_alloc_idx_0               (mshr_alloc_idx_0           ),
        .mshr_alloc_rdy_0               (mshr_alloc_rdy_0           ),
        .mshr_alloc_vld_1               (mshr_alloc_vld_1           ),
        .mshr_alloc_idx_1               (mshr_alloc_idx_1           ),
        .mshr_alloc_rdy_1               (mshr_alloc_rdy_1           ),
        .out_grant_vld_0                (tag_req_vld_0              ),
        .out_grant_vld_1                (tag_req_vld_1              ),
        .out_grant_pld_0                (tag_req_pld_0              ),
        .out_grant_pld_1                (tag_req_pld_1              ),
        .out_grant_rdy                  (tag_req_rdy                ));

    vec_cache_tag_ctrl u_tag_pipe(
        .clk                            (clk                        ),
        .rst_n                          (rst_n                      ),
        .v_wr_resp_vld_0                (v_wr_resp_vld_0            ),
        .v_wr_resp_pld_0                (v_wr_resp_pld_0            ),
        .v_wr_resp_vld_1                (v_wr_resp_vld_1            ),
        .v_wr_resp_pld_1                (v_wr_resp_pld_1            ),
        .tag_req_vld_0                  (tag_req_vld_0              ),
        .tag_req_vld_1                  (tag_req_vld_1              ),
        .tag_req_pld_0                  (tag_req_pld_0              ),
        .tag_req_pld_1                  (tag_req_pld_1              ),
        .tag_req_rdy                    (tag_req_rdy                ),
        .v_mshr_entry_pld               (v_mshr_entry_pld           ),
        .mshr_update_en_0               (mshr_update_en_0           ),
        .mshr_update_pld_0              (mshr_update_pld_0          ),
        .mshr_update_en_1               (mshr_update_en_1           ),
        .mshr_update_pld_1              (mshr_update_pld_1          ));

    vec_cache_mshr u_mshr(
        .clk                            (clk                        ),          
        .rst_n                          (rst_n                      ),
        .mshr_update_en_0               (mshr_update_en_0           ),
        .mshr_update_en_1               (mshr_update_en_1           ),
        .mshr_update_pld_0              (mshr_update_pld_0          ),
        .mshr_update_pld_1              (mshr_update_pld_1          ),
        .alloc_vld_0                    (mshr_alloc_vld_0           ),
        .alloc_idx_0                    (mshr_alloc_idx_0           ),
        .alloc_rdy_0                    (mshr_alloc_rdy_0           ),
        .alloc_vld_1                    (mshr_alloc_vld_1           ),
        .alloc_idx_1                    (mshr_alloc_idx_1           ),
        .alloc_rdy_1                    (mshr_alloc_rdy_1           ),

        .read_cmd_vld_west              (read_cmd_vld_west          ),
        .read_cmd_vld_east              (read_cmd_vld_east          ),
        .read_cmd_vld_south             (read_cmd_vld_south         ),
        .read_cmd_vld_north             (read_cmd_vld_north         ),
        .read_cmd_vld_evict             (read_cmd_vld_evict         ),
        .read_cmd_pld_west              (read_cmd_pld_west          ),
        .read_cmd_pld_east              (read_cmd_pld_east          ),
        .read_cmd_pld_south             (read_cmd_pld_south         ),
        .read_cmd_pld_north             (read_cmd_pld_north         ),
        .read_cmd_pld_evict             (read_cmd_pld_evict         ),
        .read_cmd_to_ram_pld_0          (read_cmd_to_ram_pld_0      ),
        .read_cmd_to_ram_pld_1          (read_cmd_to_ram_pld_1      ),
        .read_cmd_to_ram_vld_0          (read_cmd_to_ram_vld_0      ),
        .read_cmd_to_ram_vld_1          (read_cmd_to_ram_vld_1      ),
        .write_cmd_vld_west             (write_cmd_vld_west         ),
        .write_cmd_vld_east             (write_cmd_vld_east         ),
        .write_cmd_vld_south            (write_cmd_vld_south        ),
        .write_cmd_vld_north            (write_cmd_vld_north        ),
        .write_cmd_vld_linefill         (write_cmd_vld_linefill     ),
        .write_cmd_pld_west             (write_cmd_pld_west         ),
        .write_cmd_pld_east             (write_cmd_pld_east         ),
        .write_cmd_pld_south            (write_cmd_pld_south        ),
        .write_cmd_pld_north            (write_cmd_pld_north        ),
        .write_cmd_pld_linefill         (write_cmd_pld_linefill     ),

        .downstream_txreq_rdy           (down_txreq_rdy             ),
        .downstream_txreq_vld           (down_txreq_vld             ),
        .downstream_txreq_pld           (down_txreq_pld             ),
        
        .ds_txreq_done                  (ds_txreq_done              ),
        .ds_txreq_done_idx              (ds_txreq_done_idx          ),
        .ds_txreq_done_db_entry_id      (ds_txreq_done_db_entry_id  ),
        .linefill_done                  (linefill_done              ),
        .linefill_done_idx              (linefill_done_idx          ),

        .rd_done_west                   (rd_done_west               ),
        .rd_done_idx_west               (rd_done_idx_west           ),
        .rd_done_east                   (rd_done_east               ),
        .rd_done_idx_east               (rd_done_idx_east           ),
        .rd_done_south                  (rd_done_south              ),
        .rd_done_idx_south              (rd_done_idx_south          ),
        .rd_done_north                  (rd_done_north              ),
        .rd_done_idx_north              (rd_done_idx_north          ),

        .wr_done_west                   (wr_done_west               ),
        .wr_done_idx_west               (wr_done_idx_west           ),
        .wr_done_east                   (wr_done_east               ),
        .wr_done_idx_east               (wr_done_idx_east           ),
        .wr_done_south                  (wr_done_south              ),
        .wr_done_idx_south              (wr_done_idx_south          ),
        .wr_done_north                  (wr_done_north              ),
        .wr_done_idx_north              (wr_done_idx_north          ),
        
        .evict_clean                    (evict_clean                ),
        .evict_clean_idx                (evict_clean_idx            ),
        .evict_done_resp_vld            (evict_done_resp_vld        ),
        .evict_done_resp_pld            (evict_done_resp_pld        ),
        .evict_done_resp_rdy            (evict_done_resp_rdy        ), 
        .v_mshr_entry_pld_out           (v_mshr_entry_pld           ),

        .rdb_alloc_nfull_west           (rdb_alloc_nfull_west       ),
        .rdb_alloc_nfull_east           (rdb_alloc_nfull_east       ),
        .rdb_alloc_nfull_south          (rdb_alloc_nfull_south      ),
        .rdb_alloc_nfull_north          (rdb_alloc_nfull_north      ),

        .linefill_alloc_vld             (linefill_alloc_vld         ),
        .linefill_alloc_idx             (linefill_alloc_idx         ),
        .linefill_alloc_rdy             (linefill_alloc_rdy         ));



endmodule