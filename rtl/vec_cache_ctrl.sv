module vec_cache_ctrl 
    import vector_cache_pkg::*;    
    (
    input  logic                                        clk,
    input  logic                                        rst_n,

    input  logic  [7:0]                                 hash_req_vld                           , 
    input  input_req_pld_t                              hash_req_pld [7:0]                     ,
    output logic [7:0]                                  hash_req_rdy                           ,

    //rob out wr_resp
    output logic [3:0]                                  v_wr_resp_vld_1                        , //双发
    output wr_resp_pld_t                                v_wr_resp_pld_1[3:0]                   , //txnid+sideband
    output logic [3:0]                                  v_wr_resp_vld_2                        , //双发
    output wr_resp_pld_t                                v_wr_resp_pld_2[3:0]                   , //txnid+sideband

    //arb out
    output logic                                        west_read_cmd_vld                      ,
    output arb_out_req_t                                west_read_cmd_pld                      ,
    input  logic                                        west_read_cmd_rdy                      ,
    output logic                                        east_read_cmd_vld                      ,
    output arb_out_req_t                                east_read_cmd_pld                      ,
    input  logic                                        east_read_cmd_rdy                      ,
    output logic                                        south_read_cmd_vld                     ,
    output arb_out_req_t                                south_read_cmd_pld                     ,
    input  logic                                        south_read_cmd_rdy                     ,
    output logic                                        north_read_cmd_vld                     ,
    output arb_out_req_t                                north_read_cmd_pld                     ,
    input  logic                                        north_read_cmd_rdy                     ,

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

    input  logic                                        linefill_alloc_vld    ,
    input  logic [$clog2(RW_DB_ENTRY_NUM/4)-1:0]        linefill_alloc_idx    ,
    output logic                                        linefill_alloc_rdy    ,
    input  logic                                        evict_alloc_vld       ,
    input  logic [$clog2(RW_DB_ENTRY_NUM/4)-1:0]        evict_alloc_idx       ,
    output logic                                        evict_alloc_rdy       ,

    input  logic                                        w_rd_alloc_vld        ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          w_rd_alloc_idx        ,
    output logic                                        w_rd_alloc_rdy        ,
    input  logic                                        e_rd_alloc_vld        ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          e_rd_alloc_idx        ,
    output logic                                        e_rd_alloc_rdy        ,
    input  logic                                        s_rd_alloc_vld        ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          s_rd_alloc_idx        ,
    output logic                                        s_rd_alloc_rdy        ,
    input  logic                                        n_rd_alloc_vld        ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          n_rd_alloc_idx        ,
    output logic                                        n_rd_alloc_rdy        ,


    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             evict_clean_idx       ,
    input  logic                                        evict_clean           ,
    input  logic                                        linefill_data_done    ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             linefill_data_done_idx,
    input  logic                                        linefill_done         ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             linefill_done_idx     ,

    input  logic                                        west_rd_done          ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_rd_done_idx      ,
    input  logic                                        east_rd_done          ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_rd_done_idx      ,
    input  logic                                        south_rd_done         ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_rd_done_idx     ,
    input  logic                                        north_rd_done         ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_rd_done_idx     ,

    input  logic                                        west_wr_done          ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_wr_done_idx      ,
    input  logic                                        east_wr_done          ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_wr_done_idx      ,
    input  logic                                        south_wr_done         ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_wr_done_idx     ,
    input  logic                                        north_wr_done         ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_wr_done_idx     ,
    //Bresp
    input  logic                                        bresp_vld             ,//Bresp evict done
    input  bresp_pld_t                                  bresp_pld             ,//Bresp //txnid+sideband
    output logic                                        bresp_rdy              //Bresp 
);

    logic                                               tag_req_vld                            ;
    input_req_pld_t                                     tag_req_input_arb_grant1_pld           ;
    input_req_pld_t                                     tag_req_input_arb_grant2_pld           ;
    logic                                               tag_req_rdy                            ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]                    tag_req_index                          ;
    mshr_entry_t                                        v_mshr_entry_pld[MSHR_ENTRY_NUM-1:0]   ;

    eightto2_req_arbiter #(
        .REQ_NUM        (8),
        .ENTRY_IDX_WIDTH(),
        .PLD_WIDTH      ($bits(input_req_pld_t))
    ) u_8to2_req_arb (
        .clk                (clk                      ),
        .rst_n              (rst_n                    ),
        .v_req_vld          (hash_req_vld[7:0]        ),
        .v_req_pld          (hash_req_pld[7:0]        ),
        .v_req_rdy          (hash_req_rdy             ),
        .mshr_alloc_vld     (mshr_alloc_vld           ),
        .mshr_alloc_idx_1   (mshr_alloc_index_1       ),
        .mshr_alloc_idx_1   (mshr_alloc_index_2       ),
        .mshr_alloc_rdy     (mshr_alloc_rdy           ),
        .out_grant_vld      (tag_req_vld              ),
        .out_grant_pld_1    (tag_req_input_arb_grant1_pld ),
        .out_grant_pld_2    (tag_req_input_arb_grant2_pld ),
        .out_grant_rdy      (tag_req_rdy              ) //from tag_ctrl
    );

    vec_cache_tag_ctrl u_tag_pipe(
        .clk                         (clk                       ),
        .rst_n                       (rst_n                     ),
        .v_wr_resp_vld_1             (v_wr_resp_vld_1           ),
        .v_wr_resp_pld_1             (v_wr_resp_pld_1           ),
        .v_wr_resp_vld_2             (v_wr_resp_vld_2           ),
        .v_wr_resp_pld_2             (v_wr_resp_pld_2           ),
        .wr_resp_rdy                 (wr_resp_rdy               ),
        .tag_req_vld                 (tag_req_vld               ),
        .tag_req_input_arb_grant1_pld(req_input_arb_grant1_pld  ),//8to2
        .tag_req_input_arb_grant2_pld(req_input_arb_grant2_pld  ),
        .tag_req_rdy                 (tag_req_rdy               ),
        .tag_req_index               (tag_req_index             ),
        .mshr_alloc_idx_1            (mshr_alloc_index_1        ),
        .mshr_alloc_idx_2            (mshr_alloc_index_2        ),
        .v_mshr_entry_pld            (v_mshr_entry_pld          ),
        .mshr_update_en              (mshr_update_en            ),
        .entry_release_done_index    (entry_release_done_index  ),
        .stall                       (mshr_stall                ),
        .mshr_update_pld_A           (mshr_update_pld_A         ),
        .mshr_update_pld_B           (mshr_update_pld_B         ),
        .tag_mem_en                  (tag_mem_en                ),
        .tag_ram_A_wr_en             (tag_ram_A_wr_en           ),
        .tag_ram_A_addr              (tag_ram_A_addr            ),
        .tag_ram_A_din               (tag_ram_A_din             ),
        .tag_ram_A_dout              (tag_ram_A_dout            ),
        .tag_ram_B_wr_en             (tag_ram_B_wr_en           ),
        .tag_ram_B_addr              (tag_ram_B_addr            ),
        .tag_ram_B_din               (tag_ram_B_din             ),
        .tag_ram_B_dout              (tag_ram_B_dout            )
    );

    vec_cache_mshr u_mshr(
        .clk                         (clk                      ),          
        .rst_n                       (rst_n                    ),
        .prefetch_enable             (prefetch_enable          ),
        .mshr_update_en              (mshr_update_en           ),
        .mshr_update_pld_A           (mshr_update_pld_A        ),
        .mshr_update_pld_B           (mshr_update_pld_B        ),
        .alloc_vld                   (mshr_alloc_vld           ),
        .alloc_index_1               (mshr_alloc_index_1       ),
        .alloc_index_2               (mshr_alloc_index_2       ),
        .alloc_rdy                   (mshr_alloc_rdy           ),
        .west_read_cmd_vld           (west_read_cmd_vld        ),
        .west_read_cmd_pld           (west_read_cmd_pld        ),
        .east_read_cmd_vld           (east_read_cmd_vld        ),
        .east_read_cmd_pld           (east_read_cmd_pld        ),
        .south_read_cmd_vld          (south_read_cmd_vld       ),
        .south_read_cmd_pld          (south_read_cmd_pld       ),
        .north_read_cmd_vld          (north_read_cmd_vld       ),
        .north_read_cmd_pld          (north_read_cmd_pld       ),
        .west_write_cmd_vld          (west_write_cmd_vld       ),
        .west_write_cmd_pld          (west_write_cmd_pld       ),
        .east_write_cmd_vld          (east_write_cmd_vld       ),
        .east_write_cmd_pld          (east_write_cmd_pld       ),
        .south_write_cmd_vld         (south_write_cmd_vld      ),
        .south_write_cmd_pld         (south_write_cmd_pld      ),
        .north_write_cmd_vld         (north_write_cmd_vld      ),
        .north_write_cmd_pld         (north_write_cmd_pld      ),
        .evict_req_pld               (evict_req_pld            ),
        .evict_req_vld               (evict_req_vld            ),
        .evict_req_rdy               (evict_req_rdy            ),
        .lf_wrreq_pld                (lf_wrreq_pld             ),
        .lf_wrreq_vld                (lf_wrreq_vld             ),
        .lf_wrreq_rdy                (lf_wrreq_rdy             ),

        .dataram_rdy                 (dataram_rdy              ),
        .downstream_txreq_rdy        (downstream_txreq_rdy     ),
        .downstream_txreq_vld        (downstream_txreq_vld     ),
        .downstream_txreq_pld        (downstream_txreq_pld     ),
        
        .linefill_data_done          (linefill_data_done       ),
        .linefill_data_done_idx      (linefill_data_done_idx   ),
        .linefill_done               (linefill_done            ),
        .linefill_done_idx           (linefill_done_idx        ),

        .west_rd_done               (west_rd_done             ),
        .west_rd_done_idx           (west_rd_done_idx         ),
        .east_rd_done               (east_rd_done             ),
        .east_rd_done_idx           (east_rd_done_idx         ),
        .south_rd_done              (south_rd_done            ),
        .south_rd_done_idx          (south_rd_done_idx        ),
        .north_rd_done              (north_rd_done            ),
        .north_rd_done_idx          (north_rd_done_idx        ),

        .west_wr_done               (west_wr_done             ),
        .west_wr_done_idx           (west_wr_done_idx         ),
        .east_wr_done               (east_wr_done             ),
        .east_wr_done_idx           (east_wr_done_idx         ),
        .south_wr_done              (south_wr_done            ),
        .south_wr_done_idx          (south_wr_done_idx        ),
        .north_wr_done              (north_wr_done            ),
        .north_wr_done_idx          (north_wr_done_idx        ),
        
        .evict_clean                 (evict_clean              ),
        .evict_clean_idx             (evict_clean_idx          ),
        .bresp_vld                   (bresp_vld                ),
        .bresp_pld                   (bresp_pld                ),
        .bresp_rdy                   (bresp_rdy                ),
        .entry_release_done_index    (entry_release_done_index ),
        .mshr_stall                  (mshr_stall               ), 
        .v_mshr_entry_pld            (v_mshr_entry_pld         ),

        .w_rd_alloc_vld              (w_rd_alloc_vld         ),
        .w_rd_alloc_idx              (w_rd_alloc_idx         ),
        .w_rd_alloc_rdy              (w_rd_alloc_rdy         ),
        .e_rd_alloc_vld              (e_rd_alloc_vld         ),
        .e_rd_alloc_idx              (e_rd_alloc_idx         ),
        .e_rd_alloc_rdy              (e_rd_alloc_rdy         ),
        .s_rd_alloc_vld              (s_rd_alloc_vld         ),
        .s_rd_alloc_idx              (s_rd_alloc_idx         ),
        .s_rd_alloc_rdy              (s_rd_alloc_rdy         ),
        .n_rd_alloc_vld              (n_rd_alloc_vld         ),
        .n_rd_alloc_idx              (n_rd_alloc_idx         ),
        .n_rd_alloc_rdy              (n_rd_alloc_rdy         ),

        .linefill_alloc_vld          (linefill_alloc_vld     ),
        .linefill_alloc_idx          (linefill_alloc_idx     ),
        .linefill_alloc_rdy          (linefill_alloc_rdy     ),
        .evict_alloc_vld             (evict_alloc_vld        ),
        .evict_alloc_idx             (evict_alloc_idx        ),
        .evit_alloc_rdy              (evict_alloc_rdy        )
    );



endmodule