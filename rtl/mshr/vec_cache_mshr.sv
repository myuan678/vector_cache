module vec_cache_mshr 
    import vector_cache_pkg::*;
    (
    input  logic                                        clk                     ,
    input  logic                                        rst_n                   ,    

    input  logic                                        mshr_update_en_0        ,
    input  logic                                        mshr_update_en_1        ,
    input  mshr_entry_t                                 mshr_update_pld_0       ,
    input  mshr_entry_t                                 mshr_update_pld_1       ,

    output logic                                        alloc_vld_0             ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]             alloc_idx_0             ,
    input  logic                                        alloc_rdy_0             ,
    output logic                                        alloc_vld_1             ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]             alloc_idx_1             ,
    input  logic                                        alloc_rdy_1             ,

    output logic                                        read_cmd_vld_west       ,
    output logic                                        read_cmd_vld_east       ,
    output logic                                        read_cmd_vld_south      ,
    output logic                                        read_cmd_vld_north      , 
    output logic                                        read_cmd_vld_evict      ,

    output arb_out_req_t                                read_cmd_pld_west       ,
    output arb_out_req_t                                read_cmd_pld_east       ,
    output arb_out_req_t                                read_cmd_pld_south      ,
    output arb_out_req_t                                read_cmd_pld_north      ,
    output arb_out_req_t                                read_cmd_pld_evict      ,

    output arb_out_req_t                                read_cmd_to_ram_pld_0   ,
    output arb_out_req_t                                read_cmd_to_ram_pld_1   ,
    output logic                                        read_cmd_to_ram_vld_0   ,
    output logic                                        read_cmd_to_ram_vld_1   ,

    output logic                                        write_cmd_vld_west      ,
    output logic                                        write_cmd_vld_east      ,
    output logic                                        write_cmd_vld_south     ,
    output logic                                        write_cmd_vld_north     ,
    output logic                                        write_cmd_vld_linefill  ,

    output arb_out_req_t                                write_cmd_pld_west      ,
    output arb_out_req_t                                write_cmd_pld_east      ,
    output arb_out_req_t                                write_cmd_pld_south     ,
    output arb_out_req_t                                write_cmd_pld_north     ,
    output arb_out_req_t                                write_cmd_pld_linefill  ,

    input  logic                                        downstream_txreq_rdy    ,
    output logic                                        downstream_txreq_vld    ,
    output downstream_txreq_pld_t                       downstream_txreq_pld    ,

    input  logic                                        ds_txreq_done           ,//linefill ack
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           ds_txreq_done_idx       ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]         ds_txreq_done_db_entry_id,
    input  logic                                        linefill_done           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           linefill_done_idx       ,

    input  logic                                        rd_done_west            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_west        ,
    input  logic                                        rd_done_east            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_east        ,
    input  logic                                        rd_done_south           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_south       ,
    input  logic                                        rd_done_north           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             rd_done_idx_north       ,

    input  logic                                        wr_done_west            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_west        ,
    input  logic                                        wr_done_east            ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_east        ,
    input  logic                                        wr_done_south           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_south       ,
    input  logic                                        wr_done_north           ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             wr_done_idx_north       ,

    input  logic                                        evict_clean             ,//evict ack
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           evict_clean_idx         ,
    input  logic                                        evict_done_resp_vld     ,//Bresp evict done
    input  bresp_pld_t                                  evict_done_resp_pld     ,//Bresp //txnid+sideband+rob_id
    output logic                                        evict_done_resp_rdy     ,//Bresp

    output hzd_mshr_pld_t                               v_mshr_entry_pld_out[MSHR_ENTRY_NUM-1:0],
    input  logic                                        rdb_alloc_nfull_west    ,
    input  logic                                        rdb_alloc_nfull_east    ,
    input  logic                                        rdb_alloc_nfull_south   ,
    input  logic                                        rdb_alloc_nfull_north   ,

    input  logic                                        linefill_alloc_vld      ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]         linefill_alloc_idx      ,
    output logic                                        linefill_alloc_rdy  
    );

    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en_0                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en_1                             ;    
    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_vld                                    ; 
    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_rdy                                    ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld_w                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld_e                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld_s                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld_n                             ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_rdy_w                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_rdy_e                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_rdy_s                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_rdy_n                             ;
    arb_out_req_t                                       v_dataram_rd_pld   [MSHR_ENTRY_NUM-1:0]        ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_vld_w                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_vld_e                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_vld_s                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_vld_n                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_rdy_w                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_rdy_e                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_rdy_s                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_rdy_n                             ;
    arb_out_req_t                                       v_dataram_wr_pld    [MSHR_ENTRY_NUM-1:0]       ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_vld                         ;
    downstream_txreq_pld_t                              v_downstream_txreq_pld[MSHR_ENTRY_NUM-1:0]     ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_rdy                         ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_vld_lf                             ;
    arb_out_req_t                                       v_dataram_wr_pld_lf  [MSHR_ENTRY_NUM-1 :0]      ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_rdy_lf                             ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld_ev                            ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_rdy_ev                            ;
    arb_out_req_t                                       v_dataram_rd_pld_ev[MSHR_ENTRY_NUM-1:0]        ;
     
    logic [MSHR_ENTRY_NUM-1         :0]                 v_release_en                                   ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_linefill_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_ds_txreq_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_rd_done_west                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_rd_done_east                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_rd_done_south                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_rd_done_north                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_wr_done_west                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_wr_done_east                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_wr_done_south                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_wr_done_north                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_evict_done                                   ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_evict_clean                                  ;
    

    logic                                               dataram_wr_stg1_out_vld_w ;
    logic                                               dataram_wr_stg1_out_vld_e ;
    logic                                               dataram_wr_stg1_out_vld_s ;
    logic                                               dataram_wr_stg1_out_vld_n ;
    logic                                               dataram_wr_stg1_out_vld_lf;
    arb_out_req_t                                       dataram_wr_stg1_out_pld_w ;
    arb_out_req_t                                       dataram_wr_stg1_out_pld_e ;
    arb_out_req_t                                       dataram_wr_stg1_out_pld_s ;
    arb_out_req_t                                       dataram_wr_stg1_out_pld_n ;
    arb_out_req_t                                       dataram_wr_stg1_out_pld_lf;
    logic                                               dataram_wr_stg1_out_rdy_w ;
    logic                                               dataram_wr_stg1_out_rdy_e ;
    logic                                               dataram_wr_stg1_out_rdy_s ;
    logic                                               dataram_wr_stg1_out_rdy_n ;
    logic                                               dataram_wr_stg1_out_rdy_lf;

    logic                                               dataram_rd_stg1_out_vld_w ;
    logic                                               dataram_rd_stg1_out_vld_e ;
    logic                                               dataram_rd_stg1_out_vld_s ;
    logic                                               dataram_rd_stg1_out_vld_n ;
    logic                                               dataram_rd_stg1_out_vld_ev;
    arb_out_req_t                                       dataram_rd_stg1_out_pld_w ;
    arb_out_req_t                                       dataram_rd_stg1_out_pld_e ;
    arb_out_req_t                                       dataram_rd_stg1_out_pld_s ;
    arb_out_req_t                                       dataram_rd_stg1_out_pld_n ;
    arb_out_req_t                                       dataram_rd_stg1_out_pld_ev;
    logic                                               dataram_rd_stg1_out_rdy_w ;
    logic                                               dataram_rd_stg1_out_rdy_e ;
    logic                                               dataram_rd_stg1_out_rdy_s ;
    logic                                               dataram_rd_stg1_out_rdy_n ;
    logic                                               dataram_rd_stg1_out_rdy_ev;

    arb_out_req_t                                       read_cmd_to_ram_out_pld_0 ;
    arb_out_req_t                                       read_cmd_to_ram_out_pld_1 ;
    logic                                               read_cmd_to_ram_out_vld_0 ;
    logic                                               read_cmd_to_ram_out_vld_1 ;

    logic                                               read_cmd_vld_reg_west      ;
    logic                                               read_cmd_vld_reg_east      ;
    logic                                               read_cmd_vld_reg_south     ;
    logic                                               read_cmd_vld_reg_north     ;
    logic                                               read_cmd_vld_reg_evict     ;
    arb_out_req_t                                       read_cmd_pld_reg_west      ;
    arb_out_req_t                                       read_cmd_pld_reg_east      ;
    arb_out_req_t                                       read_cmd_pld_reg_south     ;
    arb_out_req_t                                       read_cmd_pld_reg_north     ;
    arb_out_req_t                                       read_cmd_pld_reg_evict     ;
    arb_out_req_t                                       read_cmd_to_ram_pld_reg_0  ;
    arb_out_req_t                                       read_cmd_to_ram_pld_reg_1  ;
    logic                                               read_cmd_to_ram_vld_reg_0  ;
    logic                                               read_cmd_to_ram_vld_reg_1  ;
    logic                                               write_cmd_vld_reg_west     ;
    logic                                               write_cmd_vld_reg_east     ;
    logic                                               write_cmd_vld_reg_south    ;
    logic                                               write_cmd_vld_reg_north    ;
    logic                                               write_cmd_vld_reg_linefill ;
    arb_out_req_t                                       write_cmd_pld_reg_west     ;
    arb_out_req_t                                       write_cmd_pld_reg_east     ;
    arb_out_req_t                                       write_cmd_pld_reg_south    ;
    arb_out_req_t                                       write_cmd_pld_reg_north    ;
    arb_out_req_t                                       write_cmd_pld_reg_linefill ;


    pre_alloc_two #(
        .ENTRY_NUM      (MSHR_ENTRY_NUM          ),
        .ENTRY_ID_WIDTH ($clog2(MSHR_ENTRY_NUM)  )
        //.PRE_ALLO_NUM   (2)
    ) u_pre_allocator (
        .clk        (clk          ),
        .rst_n      (rst_n        ),
        .v_in_vld   (v_alloc_vld  ),
        .v_in_rdy   (v_alloc_rdy  ),
        .out_vld_0  (alloc_vld_0  ),
        .out_vld_1  (alloc_vld_1  ),
        .out_rdy_0  (alloc_rdy_0  ),
        .out_rdy_1  (alloc_rdy_1  ),
        .out_idx_0  (alloc_idx_0  ),
        .out_idx_1  (alloc_idx_1  ));

// mshr entry enable decode
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_update_entry_dec0 (
        .enable         (mshr_update_en_0               ),
        .enable_index   (mshr_update_pld_0.rob_entry_id ),
        .v_out_en       (v_mshr_update_en_0             ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_update_entry_dec1 (
        .enable         (mshr_update_en_1               ),
        .enable_index   (mshr_update_pld_1.rob_entry_id ),
        .v_out_en       (v_mshr_update_en_1             ));

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_lf_data_dec (
        .enable         (ds_txreq_done    ),
        .enable_index   (ds_txreq_done_idx),
        .v_out_en       (v_ds_txreq_done  ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM   )
    )   u_linefill_done_dec (
        .enable         (linefill_done    ),
        .enable_index   (linefill_done_idx),
        .v_out_en       (v_linefill_done  ));

//--------read done decode----------------
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_west_rd_done_dec (
        .enable         (rd_done_west        ),
        .enable_index   (rd_done_idx_west    ),
        .v_out_en       (v_rd_done_west      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_east_rd_done_dec (
        .enable         (rd_done_east        ),
        .enable_index   (rd_done_idx_east    ),
        .v_out_en       (v_rd_done_east      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_south_rd_done_dec (
        .enable         (rd_done_south        ),
        .enable_index   (rd_done_idx_south    ),
        .v_out_en       (v_rd_done_south      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_north_rd_done_dec (
        .enable         (rd_done_north        ),
        .enable_index   (rd_done_idx_north    ),
        .v_out_en       (v_rd_done_north      ));
//------------------------------------------

//--------write_done decode--------------
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_west_wr_done_dec (
        .enable         (wr_done_west        ),
        .enable_index   (wr_done_idx_west    ),
        .v_out_en       (v_wr_done_west      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_east_wr_done_dec (
        .enable         (wr_done_east        ),
        .enable_index   (wr_done_idx_east    ),
        .v_out_en       (v_wr_done_east      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_south_wr_done_dec (
        .enable         (wr_done_south        ),
        .enable_index   (wr_done_idx_south    ),
        .v_out_en       (v_wr_done_south      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_north_wr_done_dec (
        .enable         (wr_done_north        ),
        .enable_index   (wr_done_idx_north    ),
        .v_out_en       (v_wr_done_north      ));
//-------------------------------------------------

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_evict_done_dec (
        .enable         (evict_done_resp_vld                ),//evict_done
        .enable_index   (evict_done_resp_pld.rob_entry_id   ),
        .v_out_en       (v_evict_done                       ));
    assign evict_done_resp_rdy = 1'b1;

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_evict_clean_dec (
        .enable         (evict_clean    ),
        .enable_index   (evict_clean_idx),
        .v_out_en       (v_evict_clean  ));

    //check state
    generate
        for (genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin:MSHR_ENTRY_ARRAY
            vec_cache_mshr_entry  u_vec_cache_mshr_entry(
            .clk                        (clk                        ),
            .rst_n                      (rst_n                      ),
            .mshr_update_en_0           (v_mshr_update_en_0[i]      ),
            .mshr_update_en_1           (v_mshr_update_en_1[i]      ),
            .mshr_update_pld_0          (mshr_update_pld_0          ),
            .mshr_update_pld_1          (mshr_update_pld_1          ),
            .mshr_out_pld               (v_mshr_entry_pld_out[i]    ),
            .alloc_vld                  (v_alloc_vld[i]             ),
            .alloc_rdy                  (v_alloc_rdy[i]             ),

            .dataram_rd_rdy_w           (v_dataram_rd_rdy_w[i]      ),
            .dataram_rd_rdy_e           (v_dataram_rd_rdy_e[i]      ),
            .dataram_rd_rdy_s           (v_dataram_rd_rdy_s[i]      ),
            .dataram_rd_rdy_n           (v_dataram_rd_rdy_n[i]      ),
            .dataram_rd_vld_w           (v_dataram_rd_vld_w[i]      ),
            .dataram_rd_vld_e           (v_dataram_rd_vld_e[i]      ),
            .dataram_rd_vld_s           (v_dataram_rd_vld_s[i]      ),
            .dataram_rd_vld_n           (v_dataram_rd_vld_n[i]      ),
            .dataram_rd_pld             (v_dataram_rd_pld  [i]      ),
            .dataram_wr_rdy_w           (v_dataram_wr_rdy_w[i]      ),
            .dataram_wr_rdy_e           (v_dataram_wr_rdy_e[i]      ),
            .dataram_wr_rdy_s           (v_dataram_wr_rdy_s[i]      ),
            .dataram_wr_rdy_n           (v_dataram_wr_rdy_n[i]      ),
            .dataram_wr_vld_w           (v_dataram_wr_vld_w[i]      ),
            .dataram_wr_vld_e           (v_dataram_wr_vld_e[i]      ),
            .dataram_wr_vld_s           (v_dataram_wr_vld_s[i]      ),
            .dataram_wr_vld_n           (v_dataram_wr_vld_n[i]      ),
            .dataram_wr_pld             (v_dataram_wr_pld[i]        ),
            .evict_rdy                  (v_dataram_rd_rdy_ev[i]     ),
            .evict_rd_vld               (v_dataram_rd_vld_ev[i]     ),  
            .evict_rd_pld               (v_dataram_rd_pld_ev[i]     ),
            .downstream_txreq_vld       (v_downstream_txreq_vld[i]  ),
            .downstream_txreq_rdy       (v_downstream_txreq_rdy[i]  ),
            .downstream_txreq_pld       (v_downstream_txreq_pld[i]  ),
            .linefill_req_vld           (v_dataram_wr_vld_lf[i]     ),
            .linefill_req_pld           (v_dataram_wr_pld_lf[i]     ),
            .linefill_req_rdy           (v_dataram_wr_rdy_lf[i]     ),

            .ds_txreq_done              (v_ds_txreq_done[i]         ),
            .ds_txreq_done_db_entry_id  (ds_txreq_done_db_entry_id  ),
            .linefill_done              (v_linefill_done[i]         ),
            .rd_done_west               (v_rd_done_west[i]          ),
            .rd_done_east               (v_rd_done_east[i]          ),
            .rd_done_south              (v_rd_done_south[i]         ),
            .rd_done_north              (v_rd_done_north[i]         ),
            .wr_done_west               (v_wr_done_west[i]          ),
            .wr_done_east               (v_wr_done_east[i]          ),
            .wr_done_south              (v_wr_done_south[i]         ),
            .wr_done_north              (v_wr_done_north[i]         ),
            .evict_done                 (v_evict_done[i]            ),
            .evict_clean                (v_evict_clean[i]           ),

            .rdb_alloc_nfull_west       (rdb_alloc_nfull_west       ),
            .rdb_alloc_nfull_east       (rdb_alloc_nfull_east       ),
            .rdb_alloc_nfull_south      (rdb_alloc_nfull_south      ),
            .rdb_alloc_nfull_north      (rdb_alloc_nfull_north      ),

            .v_release_en               (v_release_en               ),
            .release_en                 (v_release_en[i]            ));
        end
    endgenerate

    //miss req to DS arb
    logic                    pre_downstream_txreq_vld;
    downstream_txreq_pld_t   pre_downstream_txreq_pld;
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM              ),
        .PLD_WIDTH ($bits(downstream_txreq_pld_t))
    ) u_downstream_req_arb (
        .v_vld_s(v_downstream_txreq_vld     ),
        .v_rdy_s(v_downstream_txreq_rdy     ),
        .v_pld_s(v_downstream_txreq_pld     ),
        .vld_m  (pre_downstream_txreq_vld   ),
        .rdy_m  (downstream_txreq_rdy       ),
        .pld_m  (pre_downstream_txreq_pld   ));

        assign downstream_txreq_pld.txn_id       = pre_downstream_txreq_pld.txn_id        ;
        assign downstream_txreq_pld.opcode       = pre_downstream_txreq_pld.opcode       ;
        assign downstream_txreq_pld.addr.tag     = pre_downstream_txreq_pld.addr.tag     ;
        assign downstream_txreq_pld.addr.index   = pre_downstream_txreq_pld.addr.index   ;
        assign downstream_txreq_pld.addr.offset  = pre_downstream_txreq_pld.addr.offset  ;
        assign downstream_txreq_pld.way          = pre_downstream_txreq_pld.way          ;
        assign downstream_txreq_pld.dest_ram_id  = pre_downstream_txreq_pld.dest_ram_id  ;
        assign downstream_txreq_pld.db_entry_id  = linefill_alloc_idx                    ;
        assign downstream_txreq_pld.rob_entry_id = pre_downstream_txreq_pld.rob_entry_id ;
        assign downstream_txreq_pld.sideband     = pre_downstream_txreq_pld.sideband     ;

        assign downstream_txreq_vld              = linefill_alloc_vld && pre_downstream_txreq_vld;
        assign linefill_alloc_rdy                = downstream_txreq_vld && downstream_txreq_rdy;


//======================================================================
// stage one arbiter
//======================================================================    
//读arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_w_dataram_rd_arb (
        .v_vld_s(v_dataram_rd_vld_w         ),
        .v_rdy_s(v_dataram_rd_rdy_w         ),
        .v_pld_s(v_dataram_rd_pld           ),
        .vld_m  (dataram_rd_stg1_out_vld_w  ),
        .rdy_m  (dataram_rd_stg1_out_rdy_w  ),
        .pld_m  (dataram_rd_stg1_out_pld_w  ));
    
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_e_dataram_rd_arb (
        .v_vld_s(v_dataram_rd_vld_e         ),
        .v_rdy_s(v_dataram_rd_rdy_e         ),
        .v_pld_s(v_dataram_rd_pld           ),
        .vld_m  (dataram_rd_stg1_out_vld_e  ),
        .rdy_m  (dataram_rd_stg1_out_rdy_e  ),
        .pld_m  (dataram_rd_stg1_out_pld_e  ));
        
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_s_dataram_rd_arb (
        .v_vld_s(v_dataram_rd_vld_s         ),
        .v_rdy_s(v_dataram_rd_rdy_s         ),
        .v_pld_s(v_dataram_rd_pld           ),
        .vld_m  (dataram_rd_stg1_out_vld_s  ),
        .rdy_m  (dataram_rd_stg1_out_rdy_s  ),
        .pld_m  (dataram_rd_stg1_out_pld_s  ));
        
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_n_dataram_rd_arb (
        .v_vld_s(v_dataram_rd_vld_n         ),
        .v_rdy_s(v_dataram_rd_rdy_n         ),
        .v_pld_s(v_dataram_rd_pld           ),
        .vld_m  (dataram_rd_stg1_out_vld_n  ),
        .rdy_m  (dataram_rd_stg1_out_rdy_n  ),
        .pld_m  (dataram_rd_stg1_out_pld_n  ));


//写arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_w_dataram_wr_arb (
        .v_vld_s(v_dataram_wr_vld_w         ),
        .v_rdy_s(v_dataram_wr_rdy_w         ),
        .v_pld_s(v_dataram_wr_pld           ),
        .vld_m  (dataram_wr_stg1_out_vld_w  ),
        .rdy_m  (dataram_wr_stg1_out_rdy_w  ),
        .pld_m  (dataram_wr_stg1_out_pld_w  ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_e_dataram_wr_arb (
        .v_vld_s(v_dataram_wr_vld_e         ),
        .v_rdy_s(v_dataram_wr_rdy_e         ),
        .v_pld_s(v_dataram_wr_pld           ),
        .vld_m  (dataram_wr_stg1_out_vld_e  ),
        .rdy_m  (dataram_wr_stg1_out_rdy_e  ),
        .pld_m  (dataram_wr_stg1_out_pld_e  ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_s_dataram_wr_arb (
        .v_vld_s(v_dataram_wr_vld_s         ),
        .v_rdy_s(v_dataram_wr_rdy_s         ),
        .v_pld_s(v_dataram_wr_pld           ),
        .vld_m  (dataram_wr_stg1_out_vld_s  ),
        .rdy_m  (dataram_wr_stg1_out_rdy_s  ),
        .pld_m  (dataram_wr_stg1_out_pld_s  ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_n_dataram_wr_arb (
        .v_vld_s(v_dataram_wr_vld_n         ),
        .v_rdy_s(v_dataram_wr_rdy_n         ),
        .v_pld_s(v_dataram_wr_pld           ),
        .vld_m  (dataram_wr_stg1_out_vld_n  ),
        .rdy_m  (dataram_wr_stg1_out_rdy_n  ),
        .pld_m  (dataram_wr_stg1_out_pld_n  ));


//evict read req arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_dataram_evict_arb (
        .v_vld_s(v_dataram_rd_vld_ev        ),
        .v_rdy_s(v_dataram_rd_rdy_ev        ),
        .v_pld_s(v_dataram_rd_pld_ev        ),
        .vld_m  (dataram_rd_stg1_out_vld_ev ),
        .rdy_m  (dataram_rd_stg1_out_rdy_ev ),
        .pld_m  (dataram_rd_stg1_out_pld_ev ));


//linefill req(write sram) arb--------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_lfreq_arb (
        .v_vld_s(v_dataram_wr_vld_lf        ),
        .v_rdy_s(v_dataram_wr_rdy_lf        ),
        .v_pld_s(v_dataram_wr_pld_lf        ),
        .vld_m  (dataram_wr_stg1_out_vld_lf ),
        .rdy_m  (dataram_wr_stg1_out_rdy_lf ),
        .pld_m  (dataram_wr_stg1_out_pld_lf ));

//======================================================================
// stage two arbiter
//====================================================================== 

    vec_cache_stage2_arbiter # ( 
        .CHANNEL_SHIFT_REG_WIDTH(20),
        .RAM_SHIFT_REG_WIDTH    (20))
    u_stage2_arbiter ( 
        .clk                    (clk                                ),
        .rst_n                  (rst_n                              ),
        .dataram_rd_in_vld_w    (dataram_rd_stg1_out_vld_w          ),
        .dataram_rd_in_vld_e    (dataram_rd_stg1_out_vld_e          ),
        .dataram_rd_in_vld_s    (dataram_rd_stg1_out_vld_s          ),
        .dataram_rd_in_vld_n    (dataram_rd_stg1_out_vld_n          ),
        .dataram_rd_in_vld_ev   (dataram_rd_stg1_out_vld_ev         ),
        .dataram_rd_in_pld_w    (dataram_rd_stg1_out_pld_w          ),
        .dataram_rd_in_pld_e    (dataram_rd_stg1_out_pld_e          ),
        .dataram_rd_in_pld_s    (dataram_rd_stg1_out_pld_s          ),
        .dataram_rd_in_pld_n    (dataram_rd_stg1_out_pld_n          ),
        .dataram_rd_in_pld_ev   (dataram_rd_stg1_out_pld_ev         ),
        .dataram_rd_in_rdy_w    (dataram_rd_stg1_out_rdy_w          ),
        .dataram_rd_in_rdy_e    (dataram_rd_stg1_out_rdy_e          ),
        .dataram_rd_in_rdy_s    (dataram_rd_stg1_out_rdy_s          ),
        .dataram_rd_in_rdy_n    (dataram_rd_stg1_out_rdy_n          ),
        .dataram_rd_in_rdy_ev   (dataram_rd_stg1_out_rdy_ev         ),
        .dataram_wr_in_vld_w    (dataram_wr_stg1_out_vld_w          ),
        .dataram_wr_in_vld_e    (dataram_wr_stg1_out_vld_e          ),
        .dataram_wr_in_vld_s    (dataram_wr_stg1_out_vld_s          ),
        .dataram_wr_in_vld_n    (dataram_wr_stg1_out_vld_n          ),
        .dataram_wr_in_vld_lf   (dataram_wr_stg1_out_vld_lf         ),
        .dataram_wr_in_pld_w    (dataram_wr_stg1_out_pld_w          ),
        .dataram_wr_in_pld_e    (dataram_wr_stg1_out_pld_e          ),
        .dataram_wr_in_pld_s    (dataram_wr_stg1_out_pld_s          ),
        .dataram_wr_in_pld_n    (dataram_wr_stg1_out_pld_n          ),
        .dataram_wr_in_pld_lf   (dataram_wr_stg1_out_pld_lf         ),
        .dataram_wr_in_rdy_w    (dataram_wr_stg1_out_rdy_w          ),
        .dataram_wr_in_rdy_e    (dataram_wr_stg1_out_rdy_e          ),
        .dataram_wr_in_rdy_s    (dataram_wr_stg1_out_rdy_s          ),
        .dataram_wr_in_rdy_n    (dataram_wr_stg1_out_rdy_n          ),
        .dataram_wr_in_rdy_lf   (dataram_wr_stg1_out_rdy_lf         ),
        .dataram_rd_out_vld_w   (read_cmd_vld_reg_west                  ),
        .dataram_rd_out_vld_e   (read_cmd_vld_reg_east                  ),
        .dataram_rd_out_vld_s   (read_cmd_vld_reg_south                 ),
        .dataram_rd_out_vld_n   (read_cmd_vld_reg_north                 ),
        .dataram_rd_out_vld_ev  (read_cmd_vld_reg_evict                 ),
        .dataram_rd_out_pld_w   (read_cmd_pld_reg_west                  ),
        .dataram_rd_out_pld_e   (read_cmd_pld_reg_east                  ),
        .dataram_rd_out_pld_s   (read_cmd_pld_reg_south                 ),
        .dataram_rd_out_pld_n   (read_cmd_pld_reg_north                 ),
        .dataram_rd_out_pld_ev  (read_cmd_pld_reg_evict                 ),
        .dataram_wr_out_vld_w   (write_cmd_vld_reg_west                 ),
        .dataram_wr_out_vld_e   (write_cmd_vld_reg_east                 ),
        .dataram_wr_out_vld_s   (write_cmd_vld_reg_south                ),
        .dataram_wr_out_vld_n   (write_cmd_vld_reg_north                ),
        .dataram_wr_out_vld_lf  (write_cmd_vld_reg_linefill             ),
        .dataram_wr_out_pld_w   (write_cmd_pld_reg_west                 ),
        .dataram_wr_out_pld_e   (write_cmd_pld_reg_east                 ),
        .dataram_wr_out_pld_s   (write_cmd_pld_reg_south                ),
        .dataram_wr_out_pld_n   (write_cmd_pld_reg_north                ),
        .dataram_wr_out_pld_lf  (write_cmd_pld_reg_linefill             ),
        .read_cmd_to_ram_pld_0  (read_cmd_to_ram_pld_reg_0              ),
        .read_cmd_to_ram_pld_1  (read_cmd_to_ram_pld_reg_1              ),
        .read_cmd_to_ram_vld_0  (read_cmd_to_ram_vld_reg_0              ),
        .read_cmd_to_ram_vld_1  (read_cmd_to_ram_vld_reg_1              ));

        always_ff@(posedge clk or negedge rst_n) begin
            if(!rst_n)begin
                read_cmd_vld_west       <= 'b0;
                read_cmd_vld_east       <= 'b0;
                read_cmd_vld_south      <= 'b0;
                read_cmd_vld_north      <= 'b0;
                read_cmd_vld_evict      <= 'b0;
                write_cmd_vld_west      <= 'b0;
                write_cmd_vld_east      <= 'b0;
                write_cmd_vld_south     <= 'b0;
                write_cmd_vld_north     <= 'b0;
                write_cmd_vld_linefill  <= 'b0;
                read_cmd_to_ram_vld_0   <= 'b0;
                read_cmd_to_ram_vld_1   <= 'b0;
            end
            else begin
                read_cmd_vld_west       <= read_cmd_vld_reg_west     ; 
                read_cmd_vld_east       <= read_cmd_vld_reg_east     ;  
                read_cmd_vld_south      <= read_cmd_vld_reg_south    ;  
                read_cmd_vld_north      <= read_cmd_vld_reg_north    ;  
                read_cmd_vld_evict      <= read_cmd_vld_reg_evict    ;  
                write_cmd_vld_west      <= write_cmd_vld_reg_west    ;  
                write_cmd_vld_east      <= write_cmd_vld_reg_east    ;  
                write_cmd_vld_south     <= write_cmd_vld_reg_south   ;  
                write_cmd_vld_north     <= write_cmd_vld_reg_north   ;  
                write_cmd_vld_linefill  <= write_cmd_vld_reg_linefill;
                read_cmd_to_ram_vld_0   <= read_cmd_to_ram_vld_reg_0 ;
                read_cmd_to_ram_vld_1   <= read_cmd_to_ram_vld_reg_1 ;
            end
        end
        always_ff@(posedge clk)begin
            read_cmd_pld_west       <= read_cmd_pld_reg_west        ;
            read_cmd_pld_east       <= read_cmd_pld_reg_east        ;
            read_cmd_pld_south      <= read_cmd_pld_reg_south       ;
            read_cmd_pld_north      <= read_cmd_pld_reg_north       ;
            read_cmd_pld_evict      <= read_cmd_pld_reg_evict       ;
            write_cmd_pld_west      <= write_cmd_pld_reg_west       ;
            write_cmd_pld_east      <= write_cmd_pld_reg_east       ;
            write_cmd_pld_south     <= write_cmd_pld_reg_south      ;
            write_cmd_pld_north     <= write_cmd_pld_reg_north      ;
            write_cmd_pld_linefill  <= write_cmd_pld_reg_linefill   ;
            read_cmd_to_ram_pld_0   <= read_cmd_to_ram_pld_reg_0    ;
            read_cmd_to_ram_pld_1   <= read_cmd_to_ram_pld_reg_1    ;
        end




    
endmodule

