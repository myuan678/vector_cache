module vec_cache_ctrl 
    import vector_cache_pkg::*;    
    (
    input  logic                                        clk     ,
    input  logic                                        rst_n   ,

    input  logic  [7:0]                                 hash_req_vld                           , 
    input  input_req_pld_t                              hash_req_pld [7:0]                     ,
    output logic [7:0]                                  hash_req_rdy                           ,

    //rob out wr_resp
    output logic [3:0]                                  v_wr_resp_vld_0                        , //双发
    output wr_resp_pld_t                                v_wr_resp_pld_0[3:0]                   , //txnid+sideband
    output logic [3:0]                                  v_wr_resp_vld_1                        , //双发
    output wr_resp_pld_t                                v_wr_resp_pld_1[3:0]                   , //txnid+sideband

    //arb out
    output logic                                        west_read_cmd_vld                      ,
    output arb_out_req_t                                west_read_cmd_pld                      ,
    //input  logic                                        west_read_cmd_rdy                      ,
    output logic                                        east_read_cmd_vld                      ,
    output arb_out_req_t                                east_read_cmd_pld                      ,
    //input  logic                                        east_read_cmd_rdy                      ,
    output logic                                        south_read_cmd_vld                     ,
    output arb_out_req_t                                south_read_cmd_pld                     ,
    //input  logic                                        south_read_cmd_rdy                     ,
    output logic                                        north_read_cmd_vld                     ,
    output arb_out_req_t                                north_read_cmd_pld                     ,
    //input  logic                                        north_read_cmd_rdy                     ,

    input  logic                                        west_write_cmd_rdy                     ,
    input  logic                                        east_write_cmd_rdy                     ,
    input  logic                                        south_write_cmd_rdy                    ,
    input  logic                                        north_write_cmd_rdy                    ,
    output logic                                        west_write_cmd_vld                     ,
    output arb_out_req_t                                west_write_cmd_pld                     ,
    output logic                                        east_write_cmd_vld                     ,
    output arb_out_req_t                                east_write_cmd_pld                     ,
    output logic                                        south_write_cmd_vld                    ,
    output arb_out_req_t                                south_write_cmd_pld                    ,
    output logic                                        north_write_cmd_vld                    ,
    output arb_out_req_t                                north_write_cmd_pld                    ,
    output arb_out_req_t                                evict_req_pld                          ,
    output logic                                        evict_req_vld                          ,
    input  logic                                        evict_req_rdy                          ,
    output arb_out_req_t                                lf_wrreq_pld                           ,//linefill write request
    output logic                                        lf_wrreq_vld                           ,//linefill write request
    input  logic                                        lf_wrreq_rdy                           ,

    //AR
    input  logic                                        down_txreq_rdy                          ,
    output logic                                        down_txreq_vld                          ,
    output downstream_txreq_pld_t                       down_txreq_pld                          ,// down_txreq_entry_id into pld

    input  logic                                        linefill_alloc_vld                      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM/4)-1:0]        linefill_alloc_idx                      ,
    output logic                                        linefill_alloc_rdy                      ,

    input  logic                                        w_rdb_alloc_nfull                       ,
    input  logic                                        e_rdb_alloc_nfull                       ,
    input  logic                                        s_rdb_alloc_nfull                       ,
    input  logic                                        n_rdb_alloc_nfull                       ,

    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             evict_clean_idx                         ,
    input  logic                                        evict_clean                             ,
    input  logic                                        ds_txreq_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             ds_txreq_done_idx                       ,
    input  logic                                        linefill_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             linefill_done_idx                       ,

    input  logic                                        west_rd_done                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_rd_done_idx                        ,
    input  logic                                        east_rd_done                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_rd_done_idx                        ,
    input  logic                                        south_rd_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_rd_done_idx                       ,
    input  logic                                        north_rd_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_rd_done_idx                       ,

    input  logic                                        west_wr_done                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_wr_done_idx                        ,
    input  logic                                        east_wr_done                            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_wr_done_idx                        ,
    input  logic                                        south_wr_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_wr_done_idx                       ,
    input  logic                                        north_wr_done                           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_wr_done_idx                       ,
    //Bresp
    input  logic                                        bresp_vld                               ,//Bresp evict done
    input  bresp_pld_t                                  bresp_pld                               ,//Bresp //txnid+sideband
    output logic                                        bresp_rdy                               //Bresp 
);

    logic                                               tag_req_vld_A                       ;
    logic                                               tag_req_vld_B                       ;
    input_req_pld_t                                     tag_req_grantA_pld                  ;
    input_req_pld_t                                     tag_req_grantB_pld                  ;
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

    eightto2_req_arbiter #(
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
        .out_grant_vld_0                (tag_req_vld_A              ),
        .out_grant_vld_1                (tag_req_vld_B              ),
        .out_grant_pld_0                (tag_req_grantA_pld         ),
        .out_grant_pld_1                (tag_req_grantB_pld         ),
        .out_grant_rdy                  (tag_req_rdy                ));

    vec_cache_tag_ctrl u_tag_pipe(
        .clk                            (clk                        ),
        .rst_n                          (rst_n                      ),
        .v_wr_resp_vld_0                (v_wr_resp_vld_0            ),
        .v_wr_resp_pld_0                (v_wr_resp_pld_0            ),
        .v_wr_resp_vld_1                (v_wr_resp_vld_1            ),
        .v_wr_resp_pld_1                (v_wr_resp_pld_1            ),
        .tag_req_vld_A                  (tag_req_vld_A              ),
        .tag_req_vld_B                  (tag_req_vld_B              ),
        .tag_req_grantA_pld             (tag_req_grantA_pld         ),
        .tag_req_grantB_pld             (tag_req_grantB_pld         ),
        .tag_req_rdy                    (tag_req_rdy                ),
        .v_mshr_entry_pld               (v_mshr_entry_pld           ),
        .mshr_alloc_idx_0               (mshr_alloc_idx_0           ),
        .mshr_alloc_idx_1               (mshr_alloc_idx_1           ),
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
        
        //.west_read_cmd_rdy              (west_read_cmd_rdy          ),
        //.east_read_cmd_rdy              (east_read_cmd_rdy          ),
        //.south_read_cmd_rdy             (south_read_cmd_rdy         ),
        //.north_read_cmd_rdy             (north_read_cmd_rdy         ),
        .west_read_cmd_vld              (west_read_cmd_vld          ),
        .west_read_cmd_pld              (west_read_cmd_pld          ),
        .east_read_cmd_vld              (east_read_cmd_vld          ),
        .east_read_cmd_pld              (east_read_cmd_pld          ),
        .south_read_cmd_vld             (south_read_cmd_vld         ),
        .south_read_cmd_pld             (south_read_cmd_pld         ),
        .north_read_cmd_vld             (north_read_cmd_vld         ),
        .north_read_cmd_pld             (north_read_cmd_pld         ),

        .west_write_cmd_rdy             (west_write_cmd_rdy         ),
        .east_write_cmd_rdy             (east_write_cmd_rdy         ),
        .south_write_cmd_rdy            (south_write_cmd_rdy        ),
        .north_write_cmd_rdy            (north_write_cmd_rdy        ),
        .west_write_cmd_vld             (west_write_cmd_vld         ),
        .west_write_cmd_pld             (west_write_cmd_pld         ),
        .east_write_cmd_vld             (east_write_cmd_vld         ),
        .east_write_cmd_pld             (east_write_cmd_pld         ),
        .south_write_cmd_vld            (south_write_cmd_vld        ),
        .south_write_cmd_pld            (south_write_cmd_pld        ),
        .north_write_cmd_vld            (north_write_cmd_vld        ),
        .north_write_cmd_pld            (north_write_cmd_pld        ),
        .evict_req_pld                  (evict_req_pld              ),
        .evict_req_vld                  (evict_req_vld              ),
        .evict_req_rdy                  (evict_req_rdy              ),
        .lf_wrreq_pld                   (lf_wrreq_pld               ),
        .lf_wrreq_vld                   (lf_wrreq_vld               ),
        .lf_wrreq_rdy                   (lf_wrreq_rdy               ),

        .dataram_rdy                    (1'b1                       ),
        .downstream_txreq_rdy           (down_txreq_rdy             ),
        .downstream_txreq_vld           (down_txreq_vld             ),
        .downstream_txreq_pld           (down_txreq_pld             ),
        
        .ds_txreq_done                  (ds_txreq_done              ),
        .ds_txreq_done_idx              (ds_txreq_done_idx          ),
        .linefill_done                  (linefill_done              ),
        .linefill_done_idx              (linefill_done_idx          ),

        .west_rd_done                   (west_rd_done               ),
        .west_rd_done_idx               (west_rd_done_idx           ),
        .east_rd_done                   (east_rd_done               ),
        .east_rd_done_idx               (east_rd_done_idx           ),
        .south_rd_done                  (south_rd_done              ),
        .south_rd_done_idx              (south_rd_done_idx          ),
        .north_rd_done                  (north_rd_done              ),
        .north_rd_done_idx              (north_rd_done_idx          ),

        .west_wr_done                   (west_wr_done               ),
        .west_wr_done_idx               (west_wr_done_idx           ),
        .east_wr_done                   (east_wr_done               ),
        .east_wr_done_idx               (east_wr_done_idx           ),
        .south_wr_done                  (south_wr_done              ),
        .south_wr_done_idx              (south_wr_done_idx          ),
        .north_wr_done                  (north_wr_done              ),
        .north_wr_done_idx              (north_wr_done_idx          ),
        
        .evict_clean                    (evict_clean                ),
        .evict_clean_idx                (evict_clean_idx            ),
        .bresp_vld                      (bresp_vld                  ),
        .bresp_pld                      (bresp_pld                  ),
        .bresp_rdy                      (bresp_rdy                  ), 
        .v_mshr_entry_pld_out           (v_mshr_entry_pld           ),

        .w_rdb_alloc_nfull              (w_rdb_alloc_nfull          ),
        .e_rdb_alloc_nfull              (e_rdb_alloc_nfull          ),
        .s_rdb_alloc_nfull              (s_rdb_alloc_nfull          ),
        .n_rdb_alloc_nfull              (n_rdb_alloc_nfull          ),

        .linefill_alloc_vld             (linefill_alloc_vld         ),
        .linefill_alloc_idx             (linefill_alloc_idx         ),
        .linefill_alloc_rdy             (linefill_alloc_rdy         ));



endmodule