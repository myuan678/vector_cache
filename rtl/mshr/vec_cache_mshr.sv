module vec_cache_mshr 
    import vector_cache_pkg::*;
    (
    input  logic                                        clk                       ,
    input  logic                                        rst_n                     ,    
    input  logic                                        prefetch_enable           ,

    input  logic                                        mshr_update_en            ,
    input  mshr_entry_t                                 mshr_update_pld_A         ,
    input  mshr_entry_t                                 mshr_update_pld_B         ,

    output logic                                        alloc_vld                 ,//to tag pipe
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]             alloc_index_1             ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]             alloc_index_2             ,
    input  logic                                        alloc_rdy                 ,

    output logic                                        west_read_cmd_vld  ,
    output arb_out_req_t                                west_read_cmd_pld  ,
    output logic                                        east_read_cmd_vld  ,
    output arb_out_req_t                                east_read_cmd_pld  ,
    output logic                                        south_read_cmd_vld ,
    output arb_out_req_t                                south_read_cmd_pld ,
    output logic                                        north_read_cmd_vld ,
    output arb_out_req_t                                north_read_cmd_pld ,
    output logic                                        west_write_cmd_vld ,
    output arb_out_req_t                                west_write_cmd_pld ,
    output logic                                        east_write_cmd_vld ,
    output arb_out_req_t                                east_write_cmd_pld ,
    output logic                                        south_write_cmd_vld,
    output arb_out_req_t                                south_write_cmd_pld,
    output logic                                        north_write_cmd_vld,
    output arb_out_req_t                                north_write_cmd_pld,

    output arb_out_req_t                                evict_req_pld       ,
    output logic                                        evict_req_vld       ,
    input  logic                                        evict_req_rdy       ,
    output arb_out_req_t                                lf_wrreq_pld        ,//linefill write request
    output logic                                        lf_wrreq_vld        ,//linefill write request
    input  logic                                        lf_wrreq_rdy        ,

    input  logic                                        dataram_rdy               ,

    input  logic                                        downstream_txreq_rdy      ,// to ds
    output logic                                        downstream_txreq_vld      ,
    output downstream_txreq_pld_t                       downstream_txreq_pld      ,

    input  logic                                        linefill_data_done        ,//linefill ack
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           linefill_data_done_idx    ,
    input  logic                                        linefill_done             ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           linefill_done_idx         ,

    input  logic                                        west_rd_done     ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_rd_done_idx ,
    input  logic                                        east_rd_done     ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_rd_done_idx ,
    input  logic                                        south_rd_done    ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_rd_done_idx,
    input  logic                                        north_rd_done    ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_rd_done_idx,

    input  logic                                        west_wr_done     ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             west_wr_done_idx ,
    input  logic                                        east_wr_done     ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             east_wr_done_idx ,
    input  logic                                        south_wr_done    ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             south_wr_done_idx,
    input  logic                                        north_wr_done    ,
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]             north_wr_done_idx,

    input  logic                                        evict_clean               ,//evict ack
    input  logic [MSHR_ENTRY_IDX_WIDTH-1  :0]           evict_clean_idx           ,
    input  logic                                        bresp_vld                 ,//Bresp evict done
    input  bresp_pld_t                                  bresp_pld                 ,//Bresp //txnid+sideband+rob_id
    output logic                                        bresp_rdy                 ,//Bresp

    output logic [MSHR_ENTRY_IDX_WIDTH   :0]            entry_release_done_index  ,
    output logic                                        mshr_stall                , 
    output mshr_entry_t                                 v_mshr_entry_pld[MSHR_ENTRY_NUM-1:0],
    //add RDB and RDBagent interface
    
    input  logic                                        w_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          w_rd_alloc_idx      ,
    input  logic                                        e_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          e_rd_alloc_idx      ,
    input  logic                                        s_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          s_rd_alloc_idx      ,
    input  logic                                        n_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]          n_rd_alloc_idx      ,

    input  logic                                        linefill_alloc_vld  ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]         linefill_alloc_idx  ,
    input  logic                                        evict_alloc_vld     ,
    input  logic [$clog2(EVDB_ENTRY_NUM/4)-1:0]         evict_alloc_idx     ,

    output logic                                        w_rd_alloc_rdy      ,//TODO:
    output logic                                        e_rd_alloc_rdy      ,
    output logic                                        s_rd_alloc_rdy      ,
    output logic                                        n_rd_alloc_rdy      ,
    output logic [MSHR_ENTRY_NUM-1:0]                   linefill_alloc_rdy  ,
    output logic                                        evit_alloc_rdy


);

    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en                               ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en_1                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_mshr_update_en_2                             ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_entry_active                                 ;  

    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_vld                                    ; 
    logic  [MSHR_ENTRY_NUM-1         :0]                v_alloc_rdy                                    ;


    //logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_rd_vld                               ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_rd_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_rd_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_rd_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_rd_vld                             ;
    arb_out_req_t                                       v_w_dataram_rd_pld  [MSHR_ENTRY_NUM-1:0]       ;
    arb_out_req_t                                       v_e_dataram_rd_pld  [MSHR_ENTRY_NUM-1:0]       ;
    arb_out_req_t                                       v_s_dataram_rd_pld  [MSHR_ENTRY_NUM-1:0]       ;
    arb_out_req_t                                       v_n_dataram_rd_pld  [MSHR_ENTRY_NUM-1:0]       ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_rd_rdy                              ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_rd_rdy                              ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_rd_rdy                              ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_rd_rdy                              ;
    arb_out_req_t                                       v_dataram_rd_pld   [MSHR_ENTRY_NUM-1:0]        ;

    //logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_vld                               ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_wr_vld                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_w_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_e_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_s_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_n_dataram_wr_rdy                             ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_dataram_wr_rdy                               ;
    arb_out_req_t                                       v_dataram_wr_pld    [MSHR_ENTRY_NUM-1:0]       ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_vld                         ;
    downstream_txreq_pld_t                              v_downstream_txreq_pld     [MSHR_ENTRY_NUM-1:0];
    logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txreq_rdy                         ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_linefill_req_vld                             ;
    arb_out_req_t                                       v_linefill_req_pld  [MSHR_ENTRY_NUM-1      :0] ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_linefill_req_rdy                             ;

    logic  [MSHR_ENTRY_NUM-1         :0]                v_evict_rd_vld                                 ;
    logic  [MSHR_ENTRY_NUM-1         :0]                v_evict_rd_rdy                                 ;
    arb_out_req_t                                       v_evict_rd_pld[MSHR_ENTRY_NUM-1         :0]    ;

    //logic  [MSHR_ENTRY_NUM-1         :0]                v_downstream_txrsp_vld                         ;
    //logic  [ICACHE_REQ_OPCODE_WIDTH-1:0]                v_downstream_txrsp_opcode  [MSHR_ENTRY_NUM-1:0];

    logic  [MSHR_ENTRY_IDX_WIDTH-1 :0]                  dataram_release_index                          ;
    logic                                               dataram_release_index_vld                      ;
    logic  [MSHR_ENTRY_IDX_WIDTH   :0]                  downstream_release_index                       ; 
    
    logic  [MSHR_ENTRY_NUM-1         :0]                v_entry_release_done                           ;
     
    logic [MSHR_ENTRY_NUM-1         :0]                 v_release_en                                   ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_linefill_done                                ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_linefill_data_done                           ;
    //logic [MSHR_ENTRY_NUM-1         :0]                 v_rd_done                                      ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_west_rd_done                                  ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_east_rd_done                                  ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_south_rd_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_north_rd_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_west_wr_done                                  ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_east_wr_done                                  ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_south_wr_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_north_wr_done                                 ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_evict_done                                    ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_evict_clean                                   ;
    logic [MSHR_ENTRY_NUM-1         :0]                 v_mshr_entry_pld_valid                          ;

    logic [MSHR_ENTRY_IDX_WIDTH-1   :0]                 mshr_update_alloc_idx1;
    logic [MSHR_ENTRY_IDX_WIDTH-1   :0]                 mshr_update_alloc_idx2;


    arb_out_req_t   linefill_req_pld;
    arb_out_req_t   w_dataram_wr_pld;
    arb_out_req_t   e_dataram_wr_pld;
    arb_out_req_t   s_dataram_wr_pld;
    arb_out_req_t   n_dataram_wr_pld;
    arb_out_req_t   evict_rd_pld;
    arb_out_req_t   w_dataram_rd_pld;
    arb_out_req_t   e_dataram_rd_pld;
    arb_out_req_t   s_dataram_rd_pld;
    arb_out_req_t   n_dataram_rd_pld;

    assign mshr_update_alloc_idx1 = mshr_update_pld_A.alloc_idx;
    assign mshr_update_alloc_idx2 = mshr_update_pld_B.alloc_idx;

    always_ff@(posedge clk )begin
        v_mshr_entry_pld[mshr_update_alloc_idx1]   <= mshr_update_pld_A;
        v_mshr_entry_pld[mshr_update_alloc_idx2]   <= mshr_update_pld_B;
    end
    //always_ff@(posedge clk or negedge rst_n) begin
    //    if(!rst_n)begin
    //        for(int i=0;i<MSHR_ENTRY_NUM;i=i+1)begin
    //            v_mshr_entry_pld[i].valid <= 1'b0 ;
    //        end
    //    end
    //    else if(mshr_update_en && v_mshr_update_en_1[alloc_index_1] && v_mshr_update_en_2[alloc_index_2])begin
    //        v_mshr_entry_pld[alloc_index_1].valid <= 1'b1;
    //        v_mshr_entry_pld[alloc_index_2].valid <= 1'b1;
    //    end 
    //    else begin
    //        v_mshr_entry_pld[entry_release_done_index].valid <= 1'b0;
    //    end
    //end
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            for(int i=0;i<MSHR_ENTRY_NUM;i=i+1)begin
                v_mshr_entry_pld_valid[i] <= 1'b0 ;
            end
        end
        else if(mshr_update_en && v_mshr_update_en_1[mshr_update_alloc_idx1] && v_mshr_update_en_2[mshr_update_alloc_idx2])begin
            v_mshr_entry_pld_valid[mshr_update_alloc_idx1] <= 1'b1;
            v_mshr_entry_pld_valid[mshr_update_alloc_idx2] <= 1'b1;
        end 
        else begin
            v_mshr_entry_pld_valid[entry_release_done_index] <= 1'b0;
        end
    end

    assign mshr_stall = ( (&v_entry_active)==1'b1);


    pre_alloc_two #(
        .ENTRY_NUM(MSHR_ENTRY_NUM    ),
        .ENTRY_ID_WIDTH(INDEX_WIDTH)
    ) u_pre_allocator (
        .clk        (clk          ),
        .rst_n      (rst_n        ),
        .v_in_vld   (v_in_vld     ),
        .v_in_rdy   (v_in_rdy     ),
        .out_vld    (out_vld      ),
        .out_rdy    (out_rdy      ),
        .out_index_1(alloc_index_1),
        .out_index_2(alloc_index_2));

// mshr entry enable decode
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_update_entry_dec1 (
        .enable         (mshr_update_en    ),
        .enable_index   (mshr_update_alloc_idx1     ),
        .v_out_en       (v_mshr_update_en_1));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_update_entry_dec2 (
        .enable         (mshr_update_en    ),
        .enable_index   (mshr_update_alloc_idx2     ),
        .v_out_en       (v_mshr_update_en_2));
    assign v_mshr_update_en = v_mshr_update_en_1 | v_mshr_update_en_2;

// entry_done decode
    //rxdata 进入LFDB，linefill请求可以举手参与仲裁
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_lf_data_dec (
        .enable         (linefill_data_done    ),
        .enable_index   (linefill_data_done_idx),
        .v_out_en       (v_linefill_data_done  ));
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
        .enable         (west_rd_done        ),
        .enable_index   (west_rd_done_idx    ),
        .v_out_en       (v_west_rd_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_east_rd_done_dec (
        .enable         (east_rd_done        ),
        .enable_index   (east_rd_done_idx    ),
        .v_out_en       (v_east_rd_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_south_rd_done_dec (
        .enable         (south_rd_done        ),
        .enable_index   (south_rd_done_idx    ),
        .v_out_en       (v_south_rd_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_north_rd_done_dec (
        .enable         (north_rd_done        ),
        .enable_index   (north_rd_done_idx    ),
        .v_out_en       (v_north_rd_done      ));
//------------------------------------------

//--------write_done decode--------------
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_west_wr_done_dec (
        .enable         (west_wr_done        ),
        .enable_index   (west_wr_done_idx    ),
        .v_out_en       (v_west_wr_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_east_wr_done_dec (
        .enable         (east_wr_done        ),
        .enable_index   (east_wr_done_idx    ),
        .v_out_en       (v_east_wr_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_south_wr_done_dec (
        .enable         (south_wr_done        ),
        .enable_index   (south_wr_done_idx    ),
        .v_out_en       (v_south_wr_done      ));
    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_north_wr_done_dec (
        .enable         (north_wr_done        ),
        .enable_index   (north_wr_done_idx    ),
        .v_out_en       (v_north_wr_done      ));
//-------------------------------------------------

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_evict_done_dec (
        .enable         (bresp_vld      ),//evict_done
        .enable_index   (bresp_pld.rob_entry_id ),
        .v_out_en       (v_evict_done   ));

    v_en_decode #(
        .WIDTH          (MSHR_ENTRY_NUM )
    )   u_evict_clean_dec (
        .enable         (evict_clean    ),
        .enable_index   (evict_clean_idx),
        .v_out_en       (v_evict_clean  ));

    

////entry_release_done  index
    onehot2bin2  #(
            .ONEHOT_WIDTH   (MSHR_ENTRY_NUM      )
    ) u_release_done_index(
        .onehot_in      (v_release_en            ),
        .bin_out        (entry_release_done_index));
    
    onehot2bin2   #(
           .ONEHOT_WIDTH   (MSHR_ENTRY_NUM      )
    ) u_ds_req_entry_index(
        .onehot_in      (v_downstream_txreq_rdy  ),
        .bin_out        (downstream_release_index));
   

    //check state
    generate
        for (genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin:MSHR_ENTRY_ARRAY
            vec_cache_mshr_entry  u_vec_cache_mshr_entry(
            .clk                    (clk                        ),
            .rst_n                  (rst_n                      ),
            .mshr_update_en         (v_mshr_update_en[i]        ),
            .mshr_entry_pld         (v_mshr_entry_pld[i]        ),
            .mshr_entry_vld         (v_mshr_entry_pld_valid[i]  ),

            .entry_active           (v_entry_active[i]          ),
            .alloc_vld              (v_alloc_vld[i]             ),
            .alloc_rdy              (v_alloc_rdy[i]             ),

            .w_dataram_rd_rdy       (v_w_dataram_rd_rdy[i]      ),
            .e_dataram_rd_rdy       (v_e_dataram_rd_rdy[i]      ),
            .s_dataram_rd_rdy       (v_s_dataram_rd_rdy[i]      ),
            .n_dataram_rd_rdy       (v_n_dataram_rd_rdy[i]      ),
            //.dataram_rd_pld         (v_dataram_rd_pld[i]        ),
            .w_dataram_rd_vld       (v_w_dataram_rd_vld[i]      ),
            .e_dataram_rd_vld       (v_e_dataram_rd_vld[i]      ),
            .s_dataram_rd_vld       (v_s_dataram_rd_vld[i]      ),
            .n_dataram_rd_vld       (v_n_dataram_rd_vld[i]      ),
            .w_dataram_rd_pld       (v_w_dataram_rd_pld[i]      ),
            .e_dataram_rd_pld       (v_e_dataram_rd_pld[i]      ),
            .s_dataram_rd_pld       (v_s_dataram_rd_pld[i]      ),
            .n_dataram_rd_pld       (v_n_dataram_rd_pld[i]      ),

            //.wr_rdy                 (v_dataram_wr_rdy[i]        ),
            .w_dataram_wr_rdy       (v_w_dataram_wr_rdy[i]      ),
            .e_dataram_wr_rdy       (v_e_dataram_wr_rdy[i]      ),
            .s_dataram_wr_rdy       (v_s_dataram_wr_rdy[i]      ),
            .n_dataram_wr_rdy       (v_n_dataram_wr_rdy[i]      ),
            .dataram_wr_pld         (v_dataram_wr_pld[i]        ),
            .w_dataram_wr_vld       (v_w_dataram_wr_vld[i]      ),
            .e_dataram_wr_vld       (v_e_dataram_wr_vld[i]      ),
            .s_dataram_wr_vld       (v_s_dataram_wr_vld[i]      ),
            .n_dataram_wr_vld       (v_n_dataram_wr_vld[i]      ),

            .evict_rdy              (v_evict_rd_rdy[i]          ),
            .evict_rd_vld           (v_evict_rd_vld[i]          ),  
            .evict_rd_pld           (v_evict_rd_pld[i]          ),
              
            .downstream_txreq_vld   (v_downstream_txreq_vld[i]  ),
            .downstream_txreq_rdy   (v_downstream_txreq_rdy[i]  ),
            .downstream_txreq_pld   (v_downstream_txreq_pld[i]  ),


            .linefill_req_vld       (v_linefill_req_vld[i]      ),
            .linefill_req_pld       (v_linefill_req_pld[i]      ),
            .linefill_req_rdy       (v_linefill_req_rdy[i]      ),

            .linefill_data_done     (v_linefill_data_done[i]    ),
            .linefill_done          (v_linefill_done[i]         ),
            //.rd_done                (v_rd_done[i]               ),
            .west_rd_done           (v_west_rd_done[i]          ),
            .east_rd_done           (v_east_rd_done[i]          ),
            .south_rd_done          (v_south_rd_done[i]         ),
            .north_rd_done          (v_north_rd_done[i]         ),
            .west_wr_done           (v_west_wr_done[i]          ),
            .east_wr_done           (v_east_wr_done[i]          ),
            .south_wr_done          (v_south_wr_done[i]         ),
            .north_wr_done          (v_north_wr_done[i]         ),
            .evict_done             (v_evict_done[i]            ),
            .evict_clean            (v_evict_clean[i]           ),

            .linefill_alloc_vld     (linefill_alloc_vld         ),
            .linefill_alloc_idx     (linefill_alloc_idx         ),
            .evict_alloc_vld        (evict_alloc_vld            ),
            .evict_alloc_idx        (evict_alloc_idx            ),
            .w_rd_alloc_vld         (w_rd_alloc_vld             ),
            .w_rd_alloc_idx         (w_rd_alloc_idx             ),
            .e_rd_alloc_vld         (e_rd_alloc_vld             ),
            .e_rd_alloc_idx         (e_rd_alloc_idx             ),
            .s_rd_alloc_vld         (s_rd_alloc_vld             ),
            .s_rd_alloc_idx         (s_rd_alloc_idx             ),
            .n_rd_alloc_vld         (n_rd_alloc_vld             ),
            .n_rd_alloc_idx         (n_rd_alloc_idx             ),

            .v_release_en           (v_release_en               ),
            .release_en             (v_release_en[i]            ));
        end
    endgenerate

    //miss req to DS arb
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM ),
        .PLD_WIDTH ($bits(downstream_txreq_pld_t))
    ) u_downstream_req_arb (
        .v_vld_s(v_downstream_txreq_vld ),
        .v_rdy_s(v_downstream_txreq_rdy ),
        .v_pld_s(v_downstream_txreq_pld ),
        .vld_m  (downstream_txreq_vld   ),
        .rdy_m  (downstream_txreq_rdy   ),
        .pld_m  (downstream_txreq_pld   ));


    
//读arb----------------------------------------------------------------
    logic         w_out_dataram_rd_vld;
    arb_out_req_t w_out_dataram_rd_pld;
    logic         e_out_dataram_rd_vld;
    arb_out_req_t e_out_dataram_rd_pld;
    logic         s_out_dataram_rd_vld;
    arb_out_req_t s_out_dataram_rd_pld;
    logic         n_out_dataram_rd_vld;
    arb_out_req_t n_out_dataram_rd_pld;
    logic [4:0]   v_rd_rdy            ;
    logic [4:0]   v_wr_rdy            ;

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_w_dataram_rd_arb (
        .v_vld_s(v_w_dataram_rd_vld ),
        .v_rdy_s(v_w_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (w_dataram_rd_vld   ),
        .rdy_m  (v_rd_rdy[4]         ),
        .pld_m  (w_dataram_rd_pld   ));

        assign w_out_dataram_rd_vld             = w_dataram_rd_vld && w_rd_alloc_vld;
        assign w_out_dataram_rd_pld.db_entry_id = w_rd_alloc_idx;
    
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_e_dataram_rd_arb (
        .v_vld_s(v_e_dataram_rd_vld ),
        .v_rdy_s(v_e_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (e_dataram_rd_vld   ),
        .rdy_m  (v_rd_rdy[3]         ),
        .pld_m  (e_dataram_rd_pld     ));
        assign e_out_dataram_rd_vld = e_dataram_rd_vld && e_rd_alloc_vld;
        assign e_out_dataram_rd_pld.db_entry_id = e_rd_alloc_idx;
        
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_s_dataram_rd_arb (
        .v_vld_s(v_s_dataram_rd_vld ),
        .v_rdy_s(v_s_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (s_dataram_rd_vld   ),
        .rdy_m  (v_rd_rdy[2]         ),
        .pld_m  (s_dataram_rd_pld     ));
        assign s_out_dataram_rd_vld = s_dataram_rd_vld && s_rd_alloc_vld;
        assign s_out_dataram_rd_pld.db_entry_id = s_rd_alloc_idx;
        
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_n_dataram_rd_arb (
        .v_vld_s(v_n_dataram_rd_vld ),
        .v_rdy_s(v_n_dataram_rd_rdy ),
        .v_pld_s(v_dataram_rd_pld   ),
        .vld_m  (n_dataram_rd_vld   ),
        .rdy_m  (v_rd_rdy[1]         ),
        .pld_m  (n_dataram_rd_pld   ));
        assign n_out_dataram_rd_vld = n_dataram_rd_vld && n_rd_alloc_vld;
        assign n_out_dataram_rd_pld.db_entry_id = n_rd_alloc_idx;

        assign v_data_rd_rdy = v_w_dataram_rd_rdy |v_e_dataram_rd_rdy |v_s_dataram_rd_rdy |v_n_dataram_rd_rdy;
//--------------------------------------------------------------------

//写arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_w_dataram_wr_arb (
        .v_vld_s(v_w_dataram_wr_vld   ),
        .v_rdy_s(v_w_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (w_dataram_wr_vld     ),
        .rdy_m  (v_wr_rdy[4]          ),
        .pld_m  (w_dataram_wr_pld    ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_e_dataram_wr_arb (
        .v_vld_s(v_e_dataram_wr_vld   ),
        .v_rdy_s(v_e_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (e_dataram_wr_vld     ),
        .rdy_m  (v_wr_rdy[3]           ),
        .pld_m  (e_dataram_wr_pld    ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_s_dataram_wr_arb (
        .v_vld_s(v_s_dataram_wr_vld   ),
        .v_rdy_s(v_s_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (s_dataram_wr_vld     ),
        .rdy_m  (v_wr_rdy[2]           ),
        .pld_m  (s_dataram_wr_pld    ));

    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_n_dataram_wr_arb (
        .v_vld_s(v_n_dataram_wr_vld   ),
        .v_rdy_s(v_n_dataram_wr_rdy   ),
        .v_pld_s(v_dataram_wr_pld     ),
        .vld_m  (n_dataram_wr_vld     ),
        .rdy_m  (v_wr_rdy[1]           ),
        .pld_m  (n_dataram_wr_pld    ));

    assign v_dataram_wr_rdy =   v_w_dataram_wr_rdy | v_e_dataram_wr_rdy | v_s_dataram_wr_rdy | v_n_dataram_wr_rdy;
//-------------------------------------------------------------------------

//evict read req arb----------------------------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_dataram_evict_arb (
        .v_vld_s(v_evict_rd_vld   ),
        .v_rdy_s(v_evict_rd_rdy   ),
        .v_pld_s(v_evict_rd_pld   ),
        .vld_m  (evict_rd_vld     ),
        .rdy_m  (v_rd_rdy[0]      ),
        .pld_m  (evict_rd_pld     ));
//------------------------------------------------------------------------

//linefill req(write sram) arb--------------------------------------------
    vrp_arb #(
        .WIDTH     (MSHR_ENTRY_NUM),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_lfreq_arb (
        .v_vld_s(v_linefill_req_vld   ),
        .v_rdy_s(v_linefill_req_rdy   ),
        .v_pld_s(v_linefill_req_pld   ),
        .vld_m  (linefill_req_vld     ),
        .rdy_m  (v_wr_rdy[0]          ),
        .pld_m  (linefill_req_pld     ));

//------------------------------------------------------------------------
//第二级arbiter，10选2
    logic                                        req_ram_vld_0;
    arb_out_req_t                                req_ram_pld_0;
    logic                                        req_ram_vld_1;
    arb_out_req_t                                req_ram_pld_1;
    
        ten_to_two_arb #(
            .RD_REQ_NUM (5),
            .WR_REQ_NUM (5),
            .SHIFT_REG_WIDTH (15),
            .REQ_NUM (10)
        ) u_10to2_arb (
            .clk            (clk                      ),
            .rst_n          (rst_n                    ),
            .rd_vld         ({w_dataram_rd_vld,e_dataram_rd_vld,s_dataram_rd_vld,n_dataram_rd_vld,evict_rd_vld}),
            .rd_pld         ({w_dataram_rd_pld,e_dataram_rd_pld,s_dataram_rd_pld,n_dataram_rd_pld,evict_rd_pld}),
            .rd_rdy         (v_rd_rdy                 ),
            .wr_vld         ({w_dataram_wr_vld,e_dataram_wr_vld,s_dataram_wr_vld,n_dataram_wr_vld,linefill_req_vld}),
            .wr_pld         ({w_dataram_wr_pld,e_dataram_wr_pld,s_dataram_wr_pld,n_dataram_wr_pld,linefill_req_pld}),
            .wr_rdy         (v_wr_rdy                 ),
            .grant_req_vld_0(req_ram_vld_0            ),
            .grant_req_pld_0(req_ram_pld_0            ),
            .grant_req_vld_1(req_ram_vld_1            ),
            .grant_req_pld_1(req_ram_pld_1            ),
            .grant_req_rdy  ({dataram_rdy,dataram_rdy})    //sram 输入的rdy信号
        );


 //arbiter 选出的2个请求做decode，确定是哪个方向的读或写，
//输出应该是8个，只不过是8个只有2个会同时有效
//输出应该是10个？

    always_comb begin
        west_read_cmd_vld  = 'b0;
        west_read_cmd_pld  = 'b0;
        east_read_cmd_vld  = 'b0;
        east_read_cmd_pld  = 'b0;
        south_read_cmd_vld = 'b0;
        south_read_cmd_pld = 'b0;
        north_read_cmd_vld = 'b0;
        north_read_cmd_pld = 'b0;
        west_write_cmd_vld  = 'b0;
        west_write_cmd_pld  = 'b0;
        east_write_cmd_vld  = 'b0;
        east_write_cmd_pld  = 'b0;
        south_write_cmd_vld = 'b0;
        south_write_cmd_pld = 'b0;
        north_write_cmd_vld = 'b0;
        north_write_cmd_pld = 'b0;
        evict_req_pld       = 'b0;//TODO
        evict_req_vld       = 'b0; 
        lf_wrreq_pld        = 'b0;  
        lf_wrreq_vld        = 'b0; //opcode 0write;1read;2evict;3linefill
 
        if(req_ram_pld_0.opcode== 2'd1 | req_ram_pld_1.opcode== 2'd1 )begin
            west_read_cmd_vld   = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd0)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd0));//west
            west_read_cmd_pld   = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd0)) ? req_ram_pld_0 : req_ram_pld_1;//west
            east_read_cmd_vld   = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd1)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd1));//east
            east_read_cmd_pld   = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd1)) ? req_ram_pld_0 : req_ram_pld_1;//east
            south_read_cmd_vld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd2)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd2));//south
            south_read_cmd_pld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd2)) ? req_ram_pld_0 : req_ram_pld_1;//south
            north_read_cmd_vld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd3)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd3));//north
            north_read_cmd_pld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd3)) ? req_ram_pld_0 : req_ram_pld_1;//west
            west_write_cmd_vld  = 1'b0;
            west_write_cmd_pld  = 'b0 ;
            east_write_cmd_vld  = 1'b0;
            east_write_cmd_pld  = 'b0 ;
            south_write_cmd_vld = 1'b0;
            south_write_cmd_pld = 'b0 ;
            north_write_cmd_vld = 1'b0;
            north_write_cmd_pld = 'b0 ;
            evict_req_vld       = 'b0;
            evict_req_pld       = 'b0;
            lf_wrreq_vld        = 'b0;
            lf_wrreq_pld        = 'b0;
        end
        else if(req_ram_pld_0.opcode== 2'd2 | req_ram_pld_1.opcode== 2'd2)begin
            west_read_cmd_vld   = 1'b0;
            west_read_cmd_pld   = 'b0 ;
            east_read_cmd_vld   = 1'b0;
            east_read_cmd_pld   = 'b0 ;
            south_read_cmd_vld  = 1'b0;
            south_read_cmd_pld  = 'b0 ;
            north_read_cmd_vld  = 1'b0;
            north_read_cmd_pld  = 'b0 ;
            west_write_cmd_vld  = 1'b0;
            west_write_cmd_pld  = 'b0 ;
            east_write_cmd_vld  = 1'b0;
            east_write_cmd_pld  = 'b0 ;
            south_write_cmd_vld = 1'b0;
            south_write_cmd_pld = 'b0 ;
            north_write_cmd_vld = 1'b0;
            north_write_cmd_pld = 'b0 ;
            evict_req_vld       = 'b0;
            evict_req_pld       = 'b0;
            lf_wrreq_vld        = req_ram_vld_0 | req_ram_vld_1;
            lf_wrreq_pld        = req_ram_vld_0 ? req_ram_pld_0 : req_ram_pld_1;  
        end
        else if(req_ram_pld_0.opcode== 2'd0 | req_ram_pld_1.opcode== 2'd0)begin
            west_read_cmd_vld   = 1'b0;
            west_read_cmd_pld   = 'b0 ;
            east_read_cmd_vld   = 1'b0;
            east_read_cmd_pld   = 'b0 ;
            south_read_cmd_vld  = 1'b0;
            south_read_cmd_pld  = 'b0 ;
            north_read_cmd_vld  = 1'b0;
            north_read_cmd_pld  = 'b0 ;
            west_write_cmd_vld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd0)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd0));//west
            west_write_cmd_pld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd0)) ? req_ram_pld_0 : req_ram_pld_1;//west
            east_write_cmd_vld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd1)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd1));//east
            east_write_cmd_pld  = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd1)) ? req_ram_pld_0 : req_ram_pld_1;//east
            south_write_cmd_vld = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd2)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd2));//south
            south_write_cmd_pld = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd2)) ? req_ram_pld_0 : req_ram_pld_1;//south
            north_write_cmd_vld = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd3)) | (req_ram_vld_1 && (req_ram_pld_1.txnid.direction_id==2'd3));//north    
            north_write_cmd_pld = (req_ram_vld_0 && (req_ram_pld_0.txnid.direction_id==2'd3)) ? req_ram_pld_0 : req_ram_pld_1;//west
            evict_req_vld       = 'b0;
            evict_req_pld       = 'b0;
            lf_wrreq_vld        = 'b0;
            lf_wrreq_pld        = 'b0;
        end
        else if(req_ram_pld_0.opcode== 2'd3 | req_ram_pld_1.opcode== 2'd3)begin
            west_read_cmd_vld   = 1'b0;
            west_read_cmd_pld   = 'b0 ;
            east_read_cmd_vld   = 1'b0;
            east_read_cmd_pld   = 'b0 ;
            south_read_cmd_vld  = 1'b0;
            south_read_cmd_pld  = 'b0 ;
            north_read_cmd_vld  = 1'b0;
            north_read_cmd_pld  = 'b0 ;
            west_write_cmd_vld  = 1'b0;
            west_write_cmd_pld  = 'b0 ;
            east_write_cmd_vld  = 1'b0;
            east_write_cmd_pld  = 'b0 ;
            south_write_cmd_vld = 1'b0;
            south_write_cmd_pld = 'b0 ;
            north_write_cmd_vld = 1'b0;
            north_write_cmd_pld = 'b0 ;
            evict_req_vld       = req_ram_vld_0 | req_ram_vld_1;
            evict_req_pld       = req_ram_vld_0 ? req_ram_pld_0 : req_ram_pld_1;
            lf_wrreq_vld        = 'b0;
            lf_wrreq_pld        = 'b0;
        end
    end

    
endmodule

