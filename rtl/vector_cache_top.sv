module vector_cache_top 
import vector_cache_pkg::*; 
(   
    input  logic clk                                                          ,
    input  logic clk_div                                                      ,
    input  logic rst_n                                                        ,

//-------------------------------------------------------------------------------------
//              upstream interface
//-------------------------------------------------------------------------------------
//---read
    //direction west 
    input  logic [WR_REQ_NUM-1      :0] w_rd_cmd_vld                          ,
    input  input_read_cmd_pld_t         w_rd_cmd_pld        [WR_REQ_NUM-1:0]  ,
    output logic [WR_REQ_NUM-1      :0] w_rd_cmd_rdy                          ,

    //east
    input  logic [ER_REQ_NUM-1      :0] e_rd_cmd_vld                          ,
    input  input_read_cmd_pld_t         e_rd_cmd_pld        [ER_REQ_NUM-1:0]  ,
    output logic [ER_REQ_NUM-1      :0] e_rd_cmd_rdy                          ,

    //south
    input  logic [SR_REQ_NUM-1      :0] s_rd_cmd_vld                          ,
    input  input_read_cmd_pld_t         s_rd_cmd_pld        [SR_REQ_NUM-1:0]  ,
    output logic [SR_REQ_NUM-1      :0] s_rd_cmd_rdy                          ,

    //north
    input  logic [NR_REQ_NUM-1      :0] n_rd_cmd_vld                          ,
    input  input_read_cmd_pld_t         n_rd_cmd_pld        [NR_REQ_NUM-1:0]  ,
    output logic [NR_REQ_NUM-1      :0] n_rd_cmd_rdy                          ,

//---write
    input  logic [WW_REQ_NUM-1      :0] w_wr_cmd_vld                          ,
    input  input_write_cmd_pld_t        w_wr_cmd_pld        [WW_REQ_NUM-1:0]  ,
    output logic [WW_REQ_NUM-1      :0] w_wr_cmd_rdy                          ,

    input  logic [EW_REQ_NUM-1      :0] e_wr_cmd_vld                          ,
    input  input_write_cmd_pld_t        e_wr_cmd_pld        [EW_REQ_NUM-1:0]  ,
    output logic [EW_REQ_NUM-1      :0] e_wr_cmd_rdy                          ,

    input  logic [SW_REQ_NUM-1      :0] s_wr_cmd_vld                          ,
    input  input_write_cmd_pld_t        s_wr_cmd_pld        [SW_REQ_NUM-1:0]  ,
    output logic [SW_REQ_NUM-1      :0] s_wr_cmd_rdy                          ,

    input  logic [NW_REQ_NUM-1      :0] n_wr_cmd_vld                          ,
    input  input_write_cmd_pld_t        n_wr_cmd_pld        [NW_REQ_NUM-1:0]  ,
    output logic [NW_REQ_NUM-1      :0] n_wr_cmd_rdy                          ,

    //resp
    output logic [WB_REQ_NUM-1      :0] w_resp_vld                            ,
    output wr_resp_pld_t                w_resp_pld          [WB_REQ_NUM-1:0]  ,
    output logic [EB_REQ_NUM-1      :0] e_resp_vld                            ,
    output wr_resp_pld_t                e_resp_pld          [EB_REQ_NUM-1:0]  ,
    output logic [SB_REQ_NUM-1      :0] s_resp_vld                            ,
    output wr_resp_pld_t                s_resp_pld          [SB_REQ_NUM-1:0]  ,
    output logic [NB_REQ_NUM-1      :0] n_resp_vld                            ,
    output wr_resp_pld_t                n_resp_pld          [NB_REQ_NUM-1:0]  ,
    
    //Rdata
    output logic [WRD_REQ_NUM-1     :0] w_rd_data_vld                         ,
    output us_data_pld_t                w_rd_data_pld     [WRD_REQ_NUM-1   :0], // data+txnid+addr+sideband+xxxx
    input  logic [WRD_REQ_NUM-1     :0] w_rd_data_rdy                         ,

    output logic [ERD_REQ_NUM-1     :0] e_rd_data_vld                         ,
    output us_data_pld_t                e_rd_data_pld     [ERD_REQ_NUM-1   :0],
    input  logic [ERD_REQ_NUM-1     :0] e_rd_data_rdy                         ,

    output logic [SRD_REQ_NUM-1     :0] s_rd_data_vld                         ,
    output us_data_pld_t                s_rd_data_pld     [SRD_REQ_NUM-1   :0], // data+txnid+addr+sideband+xxxx
    input  logic [SRD_REQ_NUM-1     :0] s_rd_data_rdy                         ,

    output logic [NRD_REQ_NUM-1     :0] n_rd_data_vld                         ,
    output us_data_pld_t                n_rd_data_pld     [NRD_REQ_NUM-1   :0], // data+txnid+addr+sideband+xxxx
    input  logic [NRD_REQ_NUM-1     :0] n_rd_data_rdy                         ,

//-------------------------------------------------------------------------------------
//              downstream interface
//-------------------------------------------------------------------------------------
    //AR
    output logic                        down_txreq_vld                      ,
    input  logic                        ds_input_txreq_rdy                  ,
    output downstream_txreq_pld_t       down_txreq_pld                      , // addr+txnid+sideband+xxxx
    //AW+W evdb out to ds       
    output logic                        evict_to_ds_vld                     ,
    input  logic                        ds_input_evict_rdy                  ,
    output evict_to_ds_pld_t            evict_to_ds_pld                     ,// data+txnid+addr+sideband+xxxx
    //R     
    input  logic                        ds_to_lfdb_vld                      ,
    input  ds_to_lfdb_pld_t             ds_to_lfdb_pld                      ,
    output logic                        ds_to_lfdb_rdy                      ,
    //Bresp     
    input  logic                        bresp_vld                           ,//evict_done
    input  bresp_pld_t                  bresp_pld                           ,//txnid+sideband+hash_id
    output logic                        bresp_rdy
);

    logic [7    :0]                     v_hash_req_vld [3:0]           ;
    input_req_pld_t                     v_hash_req_pld [3:0][7:0]      ;
    logic [7    :0]                     v_hash_req_rdy [3:0]           ;

    logic [3:0]                         w_rd_vld                       ;
    input_req_pld_t                     w_rd_pld[3:0]                  ;
    logic [3:0]                         w_rd_rdy                       ;

    logic [3:0]                         e_rd_vld                       ;
    input_req_pld_t                     e_rd_pld[3:0]                  ;
    logic [3:0]                         e_rd_rdy                       ;

    logic [3:0]                         s_rd_vld                       ;
    input_req_pld_t                     s_rd_pld[3:0]                  ;
    logic [3:0]                         s_rd_rdy                       ;

    logic [3:0]                         n_rd_vld                       ;
    input_req_pld_t                     n_rd_pld[3:0]                  ;
    logic [3:0]                         n_rd_rdy                       ;

    logic [3:0]                         w_wr_vld                       ;
    input_req_pld_t                     w_wr_pld[3:0]                  ;
    wdb_pld_t                           w_wdb_data_pld [3:0]           ;
    logic [3:0]                         w_wr_rdy                       ;

    logic [3:0]                         e_wr_vld                       ;
    input_req_pld_t                     e_wr_pld   [3:0]               ;
    wdb_pld_t                           e_wdb_data_pld [3:0]           ;
    logic [3:0]                         e_wr_rdy                       ;

    logic [3:0]                         s_wr_vld                       ;
    input_req_pld_t                     s_wr_pld   [3:0]               ;
    wdb_pld_t                           s_wdb_data_pld [3:0]           ;
    logic [3:0]                         s_wr_rdy                       ;

    logic [3:0]                         n_wr_vld                       ;
    input_req_pld_t                     n_wr_pld   [3:0]               ;
    wdb_pld_t                           n_wdb_data_pld [3:0]           ;
    logic [3:0]                         n_wr_rdy                       ;

    logic [3:0]                         vv_wr_resp_vld_1[3:0]          ;
    wr_resp_pld_t                       vv_wr_resp_pld_1[3:0][3:0]     ;
    logic [3:0]                         vv_wr_resp_vld_2[3:0]          ;
    wr_resp_pld_t                       vv_wr_resp_pld_2[3:0][3:0]     ;

    logic [3:0]                         v_down_txreq_rdy               ;
    logic [3:0]                         v_down_txreq_vld               ;
    downstream_txreq_pld_t              v_down_txreq_pld[3:0]          ;

    logic [3:0]                         v_bresp_vld                    ;
    bresp_pld_t                         v_bresp_pld[3:0]               ;
    logic [3:0]                         v_bresp_rdy                    ;

    logic [3:0]                         v_lfdb_to_ram_vld              ;
    write_ram_pld_t                     v_lfdb_to_ram_pld[3:0]         ;
    logic [3:0]                         v_lfdb_to_ram_rdy              ;

    logic [3:0]                         v_ds_to_lfdb_vld               ;
    logic [3:0]                         v_ds_to_lfdb_rdy               ;
    ds_to_lfdb_pld_t                    v_ds_to_lfdb_pld[3:0]          ;


    logic [3:0]                         v_evict_to_ds_vld              ;
    evict_to_ds_pld_t                   v_evict_to_ds_pld[3:0]         ;
    logic [3:0]                         v_evict_to_ds_rdy              ;

    logic [3:0]                         v_linefill_alloc_vld           ;
    logic [$clog2(LFDB_ENTRY_NUM/4)-1 :0] v_linefill_alloc_idx[3:0]    ;
    logic [3:0]                         v_linefill_alloc_rdy           ;


    logic [3:0]                         v_evict_alloc_vld              ;
    logic [$clog2(EVDB_ENTRY_NUM/4)-1:0] v_evict_alloc_idx[3:0]         ;
    logic [3:0]                         v_evict_alloc_rdy              ; 

    logic [3:0]                         v_evict_clean                  ;
    logic [MSHR_ENTRY_IDX_WIDTH-1  :0]  v_evict_clean_idx[3:0]         ;           
    logic [3:0]                         v_linefill_data_done           ;
    logic [MSHR_ENTRY_IDX_WIDTH-1  :0]  v_linefill_data_done_idx[3:0]  ;
    logic [3:0]                         v_linefill_to_ram_done         ;
    logic [MSHR_ENTRY_IDX_WIDTH-1  :0]  v_linefill_to_ram_done_idx[3:0];

    logic [3:0]                         v_west_read_cmd_vld            ;//4hash
    logic [3:0]                         v_west_read_cmd_rdy            ;
    arb_out_req_t                       v_west_read_cmd_pld [3:0]      ;
    logic [3:0]                         v_east_read_cmd_vld            ;
    logic [3:0]                         v_east_read_cmd_rdy            ;
    arb_out_req_t                       v_east_read_cmd_pld [3:0]      ;
    logic [3:0]                         v_south_read_cmd_vld           ;
    logic [3:0]                         v_south_read_cmd_rdy           ;
    arb_out_req_t                       v_south_read_cmd_pld [3:0]     ;
    logic [3:0]                         v_north_read_cmd_vld           ;
    logic [3:0]                         v_north_read_cmd_rdy           ;
    arb_out_req_t                       v_north_read_cmd_pld [3:0]     ;
    logic [3:0]                         v_west_write_cmd_vld           ;
    arb_out_req_t                       v_west_write_cmd_pld [3:0]     ;
    logic [3:0]                         v_west_write_cmd_rdy           ;
    logic [3:0]                         v_east_write_cmd_vld           ;
    arb_out_req_t                       v_east_write_cmd_pld [3:0]     ;
    logic [3:0]                         v_east_write_cmd_rdy           ;
    logic [3:0]                         v_south_write_cmd_vld          ;
    arb_out_req_t                       v_south_write_cmd_pld[3:0]     ;
    logic [3:0]                         v_south_write_cmd_rdy          ;
    logic [3:0]                         v_north_write_cmd_vld          ;
    arb_out_req_t                       v_north_write_cmd_pld[3:0]     ;
    logic [3:0]                         v_north_write_cmd_rdy          ;

    logic [3:0]                         v_lf_wrreq_vld                 ;
    arb_out_req_t                       v_lf_wrreq_pld[3:0]            ;
    logic [3:0]                         v_lf_wrreq_rdy                 ;

    logic [3:0]                         v_evict_req_vld                ;
    arb_out_req_t                       v_evict_req_pld[3:0]           ;
    logic [3:0]                         v_evict_req_rdy                ;

    logic [3:0]                         v_west_write_alloc_vld         ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_west_write_alloc_idx[3:0]    ;
    logic [3:0]                         v_west_write_alloc_rdy         ;
    logic [3:0]                         v_east_write_alloc_vld         ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_east_write_alloc_idx[3:0]    ;
    logic [3:0]                         v_east_write_alloc_rdy         ;
    logic [3:0]                         v_north_write_alloc_vld        ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_north_write_alloc_idx[3:0]   ;
    logic [3:0]                         v_north_write_alloc_rdy        ;
    logic [3:0]                         v_south_write_alloc_vld        ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_south_write_alloc_idx[3:0]   ;
    logic [3:0]                         v_south_write_alloc_rdy        ;

    logic [3:0]                         v_west_read_alloc_vld          ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_west_read_alloc_idx[3:0]     ;
    logic [3:0]                         v_west_read_alloc_rdy          ;
    logic [3:0]                         v_east_read_alloc_vld          ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_east_read_alloc_idx[3:0]     ;
    logic [3:0]                         v_east_read_alloc_rdy          ;
    logic [3:0]                         v_south_read_alloc_vld         ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_south_read_alloc_idx[3:0]    ;
    logic [3:0]                         v_south_read_alloc_rdy         ;
    logic [3:0]                         v_north_read_alloc_vld         ;
    logic [DB_ENTRY_IDX_WIDTH-1:0]      v_north_read_alloc_idx[3:0]    ;
    logic [3:0]                         v_north_read_alloc_rdy         ;

    logic [3                   :0]      v_west_read_to_us_done          ;
    logic [3                   :0]      v_east_read_to_us_done          ;
    logic [3                   :0]      v_south_read_to_us_done         ;
    logic [3                   :0]      v_north_read_to_us_done         ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_west_read_to_us_done_idx[3:0] ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_east_read_to_us_done_idx[3:0] ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_south_read_to_us_done_idx[3:0];
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_north_read_to_us_done_idx[3:0];
    logic [3                   :0]      v_west_rdb_to_us_data_vld       ;
    logic [3                   :0]      v_east_rdb_to_us_data_vld       ;
    logic [3                   :0]      v_south_rdb_to_us_data_vld      ;
    logic [3                   :0]      v_north_rdb_to_us_data_vld      ;
    us_data_pld_t                       v_west_rdb_to_us_data_pld[3:0]  ;
    us_data_pld_t                       v_east_rdb_to_us_data_pld[3:0]  ;
    us_data_pld_t                       v_south_rdb_to_us_data_pld[3:0] ;
    us_data_pld_t                       v_north_rdb_to_us_data_pld[3:0] ;
    logic [3                  :0]       west_rdb_mem_en                 ;
    logic [3                  :0]       west_rdb_wr_en                  ;
    read_rdb_addr_t                     west_rdb_addr[3:0]              ;
    logic [3                  :0]       east_rdb_mem_en                 ;
    logic [3                  :0]       east_rdb_wr_en                  ;
    read_rdb_addr_t                     east_rdb_addr[3:0]              ;
    logic [3                  :0]       south_rdb_mem_en                ;
    logic [3                  :0]       south_rdb_wr_en                 ;
    read_rdb_addr_t                     south_rdb_addr[3:0]             ;
    logic [3                  :0]       north_rdb_mem_en                ;
    logic [3                  :0]       north_rdb_wr_en                 ;
    read_rdb_addr_t                     north_rdb_addr[3:0]             ;

    logic [3:0]                         v_west_write_done               ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_west_write_done_idx[3:0]      ;
    logic [3:0]                         v_east_write_done               ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_east_write_done_idx[3:0]      ;
    logic [3:0]                         v_south_write_done              ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_south_write_done_idx[3:0]     ;
    logic [3:0]                         v_north_write_done              ;
    logic [MSHR_ENTRY_IDX_WIDTH-1:0]    v_north_write_done_idx[3:0]     ;

    
    logic [3:0]                         west_write_cmd_vld_in           ;
    write_ram_pld_t                     west_write_cmd_pld_in[3:0]      ;//sram的write cmd pld 带了write data，从WDB到SRAM
    logic [3:0]                         west_write_cmd_rdy              ;
    logic [3:0]                         east_write_cmd_vld_in           ;
    write_ram_pld_t                     east_write_cmd_pld_in[3:0]      ;//sram的write cmd pld 带了write data，从WDB到SRAM
    logic [3:0]                         east_write_cmd_rdy              ;
    logic [3:0]                         south_write_cmd_vld_in          ;
    write_ram_pld_t                     south_write_cmd_pld_in[3:0]     ;//sram的write cmd pld 带了write data，从WDB到SRAM
    logic [3:0]                         south_write_cmd_rdy             ;
    logic [3:0]                         north_write_cmd_vld_in          ;
    write_ram_pld_t                     north_write_cmd_pld_in[3:0]     ;//sram的write cmd pld 带了write data，从WDB到SRAM
    logic [3:0]                         north_write_cmd_rdy             ;

    logic [7:0]                         toram_west_rd_cmd_vld               ;
    arb_out_req_t                       toram_west_rd_cmd_pld [7:0]         ;
    logic [7:0]                         toram_west_write_cmd_vld_in         ;
    logic [7:0]                         toram_east_write_cmd_vld_in         ;
    logic [7:0]                         toram_south_write_cmd_vld_in        ;
    logic [7:0]                         toram_north_write_cmd_vld_in        ;
    write_ram_pld_t                     toram_west_write_cmd_pld_in [7:0]   ;
    write_ram_pld_t                     toram_east_write_cmd_pld_in [7:0]   ;
    write_ram_pld_t                     toram_south_write_cmd_pld_in[7:0]   ;
    write_ram_pld_t                     toram_north_write_cmd_pld_in[7:0]   ;
    write_ram_cmd_t                     east_write_cmd_pld_out [7:0]        ;   
    logic [7:0]                         east_write_cmd_vld_out              ;
    arb_out_req_t                       east_read_cmd_pld_out  [7:0]        ;    
    logic [7:0]                         east_read_cmd_vld_out               ;   
    logic [7:0]                         east_data_out_vld_toloop            ;
    group_data_pld_t                    east_data_out_toloop  [7:0]         ;  
    write_ram_cmd_t                     west_write_cmd_pld_out [7:0]        ;
    logic [7:0]                         west_write_cmd_vld_out              ;

    arb_out_req_t                       west_read_cmd_pld_out [7:0]         ;
    logic [7:0]                         west_read_cmd_vld_out               ;
    logic [7:0]                         west_data_out_vld                   ;
    group_data_pld_t                    west_data_out [7:0]                 ;   
    logic [7:0]                         east_data_out_vld_todb              ;
    group_data_pld_t                    east_data_out_todb[7:0]             ;    
    logic [7:0]                         west_data_out_vld_todb              ;
    group_data_pld_t                    west_data_out_todb  [7:0]           ;       
    logic [7:0]                         south_data_out_vld_todb             ;
    group_data_pld_t                    south_data_out_todb  [7:0]          ;   
    logic [7:0]                         north_data_out_vld_todb             ;
    group_data_pld_t                    north_data_out_todb [7:0]           ;  
    
    logic [3:0]                         east_data_out_vld_to_rdb            ;
    group_data_pld_t                    east_data_out_to_rdb[3:0]           ;    
    logic [3:0]                         west_data_out_vld_to_rdb            ;
    group_data_pld_t                    west_data_out_to_rdb  [3:0]         ;       
    logic [3:0]                         south_data_out_vld_to_rdb           ;
    group_data_pld_t                    south_data_out_to_rdb  [3:0]        ;   
    logic [3:0]                         north_data_out_vld_to_rdb           ;
    group_data_pld_t                    north_data_out_to_rdb [3:0]         ; 
    logic [3:0]                         evict_data_out_vld_to_evdb          ;
    group_data_pld_t                    evict_data_out_to_evdb [3:0]        ;    

    
    

    read_req_xbar #(
        .R_REQ_NUM (WR_REQ_NUM)
    ) u_west_read_req_xbar(
        .clk         (clk           ),
        .rst_n       (rst_n         ),
        .rd_cmd_vld  (w_rd_cmd_vld  ),
        .rd_cmd_rdy  (w_rd_cmd_rdy  ),
        .rd_cmd_pld  (w_rd_cmd_pld  ),
        .sel_rd_vld  (w_rd_vld      ),
        .sel_rd_pld  (w_rd_pld      ),
        .sel_rd_rdy  ({v_hash_req_rdy[3][7],v_hash_req_rdy[2][7],v_hash_req_rdy[1][7],v_hash_req_rdy[0][7]}));

    read_req_xbar #(
        .R_REQ_NUM (ER_REQ_NUM)
    ) u_east_read_req_xbar(
        .clk         (clk           ),
        .rst_n       (rst_n         ),
        .rd_cmd_vld  (e_rd_cmd_vld  ),
        .rd_cmd_rdy  (e_rd_cmd_rdy  ),
        .rd_cmd_pld  (e_rd_cmd_pld  ),
        .sel_rd_vld  (e_rd_vld      ),
        .sel_rd_pld  (e_rd_pld      ),
        .sel_rd_rdy  ({v_hash_req_rdy[3][5],v_hash_req_rdy[2][5],v_hash_req_rdy[1][5],v_hash_req_rdy[0][5]}));

    read_req_xbar #(
        .R_REQ_NUM (SR_REQ_NUM)
    ) u_south_read_req_xbar(
        .clk         (clk           ),
        .rst_n       (rst_n         ),
        .rd_cmd_vld  (s_rd_cmd_vld  ),
        .rd_cmd_rdy  (s_rd_cmd_rdy  ),
        .rd_cmd_pld  (s_rd_cmd_pld  ),
        .sel_rd_vld  (s_rd_vld      ),
        .sel_rd_pld  (s_rd_pld      ),
        .sel_rd_rdy  ({v_hash_req_rdy[3][3],v_hash_req_rdy[2][3],v_hash_req_rdy[1][3],v_hash_req_rdy[0][3]}      ));

    read_req_xbar #(
        .R_REQ_NUM (SR_REQ_NUM)
    ) u_north_read_req_xbar(
        .clk         (clk           ),
        .rst_n       (rst_n         ),
        .rd_cmd_vld  (n_rd_cmd_vld  ),
        .rd_cmd_rdy  (n_rd_cmd_rdy  ),
        .rd_cmd_pld  (n_rd_cmd_pld  ),
        .sel_rd_vld  (n_rd_vld      ),
        .sel_rd_pld  (n_rd_pld      ),
        .sel_rd_rdy  ({v_hash_req_rdy[3][1],v_hash_req_rdy[2][1],v_hash_req_rdy[1][1],v_hash_req_rdy[0][1]}      ));

    write_req_xbar #(
        .W_REQ_NUM(WW_REQ_NUM)
    ) u_west_write_req_xbar(
        .clk             (clk                   ),
        .rst_n           (rst_n                 ),
        .wr_cmd_vld      (w_wr_cmd_vld          ),
        .wr_cmd_rdy      (w_wr_cmd_rdy          ),
        .wr_cmd_pld      (w_wr_cmd_pld          ),
        .alloc_vld       (v_west_write_alloc_vld),
        .alloc_idx       (v_west_write_alloc_idx),
        .alloc_rdy       (v_west_write_alloc_rdy),
        .sel_wr_vld      (w_wr_vld              ),
        .sel_wr_pld      (w_wr_pld              ),
        .sel_wr_data_pld (w_wdb_data_pld        ),
        .sel_wr_rdy      ({v_hash_req_rdy[3][6],v_hash_req_rdy[2][6],v_hash_req_rdy[1][6],v_hash_req_rdy[0][6]}              ));

    write_req_xbar #(
        .W_REQ_NUM(EW_REQ_NUM)
    ) u_east_write_req_xbar(
        .clk             (clk                   ),
        .rst_n           (rst_n                 ),
        .wr_cmd_vld      (e_wr_cmd_vld          ),
        .wr_cmd_rdy      (e_wr_cmd_rdy          ),
        .wr_cmd_pld      (e_wr_cmd_pld          ),
        .alloc_vld       (v_east_write_alloc_vld),
        .alloc_idx       (v_east_write_alloc_idx),
        .alloc_rdy       (v_east_write_alloc_rdy),
        .sel_wr_vld      (e_wr_vld              ),
        .sel_wr_pld      (e_wr_pld              ),
        .sel_wr_data_pld (e_wdb_data_pld        ),
        .sel_wr_rdy      ({v_hash_req_rdy[3][4],v_hash_req_rdy[2][4],v_hash_req_rdy[1][4],v_hash_req_rdy[0][4]}              ));

    write_req_xbar #(
        .W_REQ_NUM(SW_REQ_NUM)
    ) u_south_write_req_xbar(
        .clk             (clk                    ),
        .rst_n           (rst_n                  ),
        .wr_cmd_vld      (s_wr_cmd_vld           ),
        .wr_cmd_rdy      (s_wr_cmd_rdy           ),
        .wr_cmd_pld      (s_wr_cmd_pld           ),
        .alloc_vld       (v_south_write_alloc_vld),
        .alloc_idx       (v_south_write_alloc_idx),
        .alloc_rdy       (v_south_write_alloc_rdy),
        .sel_wr_vld      (s_wr_vld               ),
        .sel_wr_pld      (s_wr_pld               ),
        .sel_wr_data_pld (s_wdb_data_pld         ),
        .sel_wr_rdy      ({v_hash_req_rdy[3][2],v_hash_req_rdy[2][2],v_hash_req_rdy[1][2],v_hash_req_rdy[0][2]}               ));

    write_req_xbar #(
        .W_REQ_NUM(NW_REQ_NUM)
    ) u_north_write_req_xbar(
        .clk             (clk                    ),
        .rst_n           (rst_n                  ),
        .wr_cmd_vld      (n_wr_cmd_vld           ),
        .wr_cmd_rdy      (n_wr_cmd_rdy           ),
        .wr_cmd_pld      (n_wr_cmd_pld           ),
        .alloc_vld       (v_north_write_alloc_vld),
        .alloc_idx       (v_north_write_alloc_idx),
        .alloc_rdy       (v_north_write_alloc_rdy),
        .sel_wr_vld      (n_wr_vld               ),
        .sel_wr_pld      (n_wr_pld               ),
        .sel_wr_data_pld (n_wdb_data_pld         ),
        .sel_wr_rdy      ({v_hash_req_rdy[3][0],v_hash_req_rdy[2][0],v_hash_req_rdy[1][0],v_hash_req_rdy[0][0]}       ));


//从这8个（4R+4W)中选2
    
    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign v_hash_req_vld[i] = {w_rd_vld[i],w_wr_vld[i],e_rd_vld[i],e_wr_vld[i],s_rd_vld[i],s_wr_vld[i],n_rd_vld[i],n_wr_vld[i]};
            assign v_hash_req_pld[i] = {w_rd_pld[i],w_wr_pld[i],e_rd_pld[i],e_wr_pld[i],s_rd_pld[i],s_wr_pld[i],n_rd_pld[i],n_wr_pld[i]};
        end
    endgenerate
//---------------------------------------------------------------------------------------
//            cache ctrl 4hash
//---------------------------------------------------------------------------------------
    generate
        for(genvar i=0;i<4;i=i+1)begin:hash_cache_ctrl_gen
            vec_cache_ctrl u_hash_cache_ctrl(
                .clk                    (clk                      ),
                .rst_n                  (rst_n                    ),
                .hash_req_vld           (v_hash_req_vld[i]        ),//每个hash的8个请求，8选2
                .hash_req_pld           (v_hash_req_pld[i]        ),//每个hash的8个请求，8选2
                .hash_req_rdy           (v_hash_req_rdy[i]        ),//TODO:to req xbar
                .v_wr_resp_vld_1        (vv_wr_resp_vld_1[i]      ),//wr resp
                .v_wr_resp_pld_1        (vv_wr_resp_pld_1[i]      ),//wr resp
                .v_wr_resp_vld_2        (vv_wr_resp_vld_2[i]      ),//wr resp
                .v_wr_resp_pld_2        (vv_wr_resp_pld_2[i]      ),//wr resp
                .down_txreq_rdy         (v_down_txreq_rdy[i]      ),
                .down_txreq_vld         (v_down_txreq_vld[i]      ),
                .down_txreq_pld         (v_down_txreq_pld[i]      ),

                .west_read_cmd_vld      (v_west_read_cmd_vld[i]   ),
                .west_read_cmd_pld      (v_west_read_cmd_pld[i]   ),
                .west_read_cmd_rdy      (v_west_read_cmd_rdy[i]   ),
                .east_read_cmd_vld      (v_east_read_cmd_vld[i]   ),
                .east_read_cmd_pld      (v_east_read_cmd_pld[i]   ),
                .east_read_cmd_rdy      (v_east_read_cmd_rdy[i]   ),
                .south_read_cmd_vld     (v_south_read_cmd_vld[i]  ),
                .south_read_cmd_pld     (v_south_read_cmd_pld[i]  ),
                .south_read_cmd_rdy     (v_south_read_cmd_rdy[i]  ),
                .north_read_cmd_vld     (v_north_read_cmd_vld[i]  ),//arb出访问sram的请求
                .north_read_cmd_pld     (v_north_read_cmd_pld[i]  ),//arb出访问sram的请求
                .north_read_cmd_rdy     (v_north_read_cmd_rdy[i]  ),

                .west_write_cmd_rdy     (w_wr_rdy[i]              ),
                .east_write_cmd_rdy     (e_wr_rdy[i]              ),
                .south_write_cmd_rdy    (s_wr_rdy[i]              ),
                .north_write_cmd_rdy    (n_wr_rdy[i]              ),
                .west_write_cmd_vld     (v_west_write_cmd_vld[i]  ),//arb出访问sram的请求
                .west_write_cmd_pld     (v_west_write_cmd_pld[i]  ),//arb出访问sram的请求
                .east_write_cmd_vld     (v_east_write_cmd_vld[i]  ),
                .east_write_cmd_pld     (v_east_write_cmd_pld[i]  ),
                .south_write_cmd_vld    (v_south_write_cmd_vld[i] ),
                .south_write_cmd_pld    (v_south_write_cmd_pld[i] ),
                .north_write_cmd_vld    (v_north_write_cmd_vld[i] ),
                .north_write_cmd_pld    (v_north_write_cmd_pld[i] ),
                .evict_req_pld          (v_evict_req_pld[i]       ),
                .evict_req_vld          (v_evict_req_vld[i]       ),
                .evict_req_rdy          (v_evict_req_rdy[i]       ),
                .lf_wrreq_vld           (v_lf_wrreq_vld[i]        ),
                .lf_wrreq_pld           (v_lf_wrreq_pld[i]        ),
                .lf_wrreq_rdy           (v_lf_wrreq_rdy[i]        ),

                .bresp_vld              (v_bresp_vld[i]           ),
                .bresp_pld              (v_bresp_pld[i]           ),
                .bresp_rdy              (v_bresp_rdy[i]           ),

                .linefill_alloc_vld     (v_linefill_alloc_vld[i]  ),
                .linefill_alloc_idx     (v_linefill_alloc_idx[i]  ),
                .linefill_alloc_rdy     (v_linefill_alloc_rdy[i]  ),

                .w_rd_alloc_vld         (v_west_read_alloc_vld[i]  ),
                .w_rd_alloc_idx         (v_west_read_alloc_idx[i]  ),
                .w_rd_alloc_rdy         (v_west_read_alloc_rdy[i]  ),
                .e_rd_alloc_vld         (v_east_read_alloc_vld[i]  ),
                .e_rd_alloc_idx         (v_east_read_alloc_idx[i]  ),
                .e_rd_alloc_rdy         (v_east_read_alloc_rdy[i]  ),
                .s_rd_alloc_vld         (v_south_read_alloc_vld[i] ),
                .s_rd_alloc_idx         (v_south_read_alloc_idx[i] ),
                .s_rd_alloc_rdy         (v_south_read_alloc_rdy[i] ),
                .n_rd_alloc_vld         (v_north_read_alloc_vld[i] ),
                .n_rd_alloc_idx         (v_north_read_alloc_idx[i] ),
                .n_rd_alloc_rdy         (v_north_read_alloc_rdy[i] ),

                .evict_alloc_vld        (v_evict_alloc_vld[i]          ),
                .evict_alloc_idx        (v_evict_alloc_idx[i]          ),
                .evict_alloc_rdy        (v_evict_alloc_rdy[i]          ),

                .evict_clean_idx        (v_evict_clean_idx[i]          ),
                .evict_clean            (v_evict_clean[i]              ),
                .linefill_data_done     (v_linefill_data_done[i]       ),
                .linefill_data_done_idx (v_linefill_data_done_idx[i]   ),
                .linefill_done          (v_linefill_to_ram_done[i]     ),
                .linefill_done_idx      (v_linefill_to_ram_done_idx[i] ),

                .west_rd_done           (v_west_read_to_us_done[i]     ),
                .west_rd_done_idx       (v_west_read_to_us_done_idx[i] ),
                .east_rd_done           (v_east_read_to_us_done[i]     ),
                .east_rd_done_idx       (v_east_read_to_us_done_idx[i] ),
                .south_rd_done          (v_south_read_to_us_done[i]    ),
                .south_rd_done_idx      (v_south_read_to_us_done_idx[i]),
                .north_rd_done          (v_north_read_to_us_done[i]    ),
                .north_rd_done_idx      (v_north_read_to_us_done_idx[i]),
                .west_wr_done           (v_west_write_done[i]          ),
                .west_wr_done_idx       (v_west_write_done_idx[i]      ),
                .east_wr_done           (v_east_write_done[i]          ),
                .east_wr_done_idx       (v_east_write_done_idx[i]      ),
                .south_wr_done          (v_south_write_done[i]         ),
                .south_wr_done_idx      (v_south_write_done_idx[i]     ),
                .north_wr_done          (v_north_write_done[i]         ),
                .north_wr_done_idx      (v_north_write_done_idx[i]     )
            );
        end
    endgenerate
//---------------------------------------------------------------------------------------
//            end
//---------------------------------------------------------------------------------------

//============================================================================================  
//WResp decode
//每个hash输出每方向各两个wresp,共8个，4个hash共输出32个wresp
//4hash下每个方向会有8个wresp，将这8个decode到具体的master,所以是4个8toN的decode cross bar
//TODO：
    logic [7:0]     west_wresp_vld          ;
    wr_resp_pld_t   west_wresp_pld  [7:0]   ;
    logic [7:0]     east_wresp_vld          ;
    wr_resp_pld_t   east_wresp_pld  [7:0]   ;
    logic [7:0]     south_wresp_vld         ;
    wr_resp_pld_t   south_wresp_pld [7:0]   ;
    logic [7:0]     north_wresp_vld         ;
    wr_resp_pld_t   north_wresp_pld [7:0]   ;
    assign west_wresp_vld = {vv_wr_resp_vld_1[0][0],vv_wr_resp_vld_2[0][0],vv_wr_resp_vld_1[1][0],vv_wr_resp_vld_2[1][0],
                            vv_wr_resp_vld_1[2][0],vv_wr_resp_vld_2[2][0],vv_wr_resp_vld_1[3][0],vv_wr_resp_vld_2[3][0]};
    assign west_wresp_pld = {vv_wr_resp_pld_1[0][0],vv_wr_resp_pld_2[0][0],vv_wr_resp_pld_1[1][0],vv_wr_resp_pld_2[1][0],
                            vv_wr_resp_pld_1[2][0],vv_wr_resp_pld_2[2][0],vv_wr_resp_pld_1[3][0],vv_wr_resp_pld_2[3][0]};

    assign east_wresp_vld = {vv_wr_resp_vld_1[0][1],vv_wr_resp_vld_2[0][1],vv_wr_resp_vld_1[1][1],vv_wr_resp_vld_2[1][1],
                            vv_wr_resp_vld_1[2][1],vv_wr_resp_vld_2[2][1],vv_wr_resp_vld_1[3][1],vv_wr_resp_vld_2[3][1]};
    assign east_wresp_pld = {vv_wr_resp_pld_1[0][1],vv_wr_resp_pld_2[0][1],vv_wr_resp_pld_1[1][1],vv_wr_resp_pld_2[1][1],
                            vv_wr_resp_pld_1[2][1],vv_wr_resp_pld_2[2][1],vv_wr_resp_pld_1[3][1],vv_wr_resp_pld_2[3][1]};

    assign south_wresp_vld = {vv_wr_resp_vld_1[0][2],vv_wr_resp_vld_2[0][2],vv_wr_resp_vld_1[1][2],vv_wr_resp_vld_2[1][2],
                            vv_wr_resp_vld_1[2][2],vv_wr_resp_vld_2[2][2],vv_wr_resp_vld_1[3][2],vv_wr_resp_vld_2[3][2]};
    assign south_wresp_pld = {vv_wr_resp_pld_1[0][2],vv_wr_resp_pld_2[0][2],vv_wr_resp_pld_1[1][2],vv_wr_resp_pld_2[1][2],
                            vv_wr_resp_pld_1[2][2],vv_wr_resp_pld_2[2][2],vv_wr_resp_pld_1[3][2],vv_wr_resp_pld_2[3][2]};

    assign north_wresp_vld = {vv_wr_resp_vld_1[0][3],vv_wr_resp_vld_2[0][3],vv_wr_resp_vld_1[1][3],vv_wr_resp_vld_2[1][3],
                            vv_wr_resp_vld_1[2][3],vv_wr_resp_vld_2[2][3],vv_wr_resp_vld_1[3][3],vv_wr_resp_vld_2[3][3]};
    assign north_wresp_pld = {vv_wr_resp_pld_1[0][3],vv_wr_resp_pld_2[0][3],vv_wr_resp_pld_1[1][3],vv_wr_resp_pld_2[1][3],
                            vv_wr_resp_pld_1[2][3],vv_wr_resp_pld_2[2][3],vv_wr_resp_pld_1[3][3],vv_wr_resp_pld_2[3][3]};
    

    wr_resp_master_decode #(
        .IN_NUM (8),
        .OUT_NUM(WB_REQ_NUM),
        .PLD_WIDTH()
    ) u_west_resp_master_decode(
        .clk         (clk           ),
        .rst_n       (rst_n         ),
        .in_wresp_vld(west_wresp_vld),
        .in_wresp_pld(west_wresp_pld),
        .out_resp_vld(w_resp_vld    ),
        .out_resp_pld(w_resp_pld    ));

    wr_resp_master_decode #(
        .IN_NUM(8),
        .OUT_NUM(WB_REQ_NUM),
        .PLD_WIDTH()
    ) u_east_resp_master_decode(
        .clk         (clk           ),
        .rst_n       (rst_n         ),
        .in_wresp_vld(east_wresp_vld),
        .in_wresp_pld(east_wresp_pld),
        .out_resp_vld(e_resp_vld    ),
        .out_resp_pld(e_resp_pld    ));

    wr_resp_master_decode #(
        .IN_NUM(8),
        .OUT_NUM(WB_REQ_NUM),
        .PLD_WIDTH()
    ) u_south_resp_master_decode(
        .clk         (clk            ),
        .rst_n       (rst_n          ),
        .in_wresp_vld(south_wresp_vld),
        .in_wresp_pld(south_wresp_pld),
        .out_resp_vld(s_resp_vld     ),
        .out_resp_pld(s_resp_pld     ));

    wr_resp_master_decode #(
        .IN_NUM(8),
        .OUT_NUM(WB_REQ_NUM),
        .PLD_WIDTH()
    ) u_north_resp_master_decode(
        .clk         (clk            ),
        .rst_n       (rst_n          ),
        .in_wresp_vld(north_wresp_vld),
        .in_wresp_pld(north_wresp_pld),
        .out_resp_vld(n_resp_vld     ),
        .out_resp_pld(n_resp_pld     ));


//---------------------------------------------------------------------------------------
//            downstream decode && arb
//---------------------------------------------------------------------------------------
//AR
    vrp_arb #(
        .WIDTH(4),// linefill txreq(AR) need 4to1 arbiter
        .PLD_WIDTH($bits(downstream_txreq_pld_t))
    ) u_AR_down_txreq_arb(
        .v_vld_s(v_down_txreq_vld   ),
        .v_pld_s(v_down_txreq_pld   ),
        .v_rdy_s(v_down_txreq_rdy   ),
        .rdy_m  (ds_input_txreq_rdy ),
        .vld_m  (down_txreq_vld     ),//output to ds
        .pld_m  (down_txreq_pld     ) //output to ds
    );

//R  RXDATA decode 
    logic [1:0] ds_to_lfdb_decode_idx;
    assign ds_to_lfdb_decode_idx = ds_to_lfdb_pld.linefill_cmd.addr[63:62];
    v_1toN_decode #(
        .N(4)
    ) u_linefill_rxdata_decode (
        .vld      (ds_to_lfdb_vld   ), //1 to 4hash
        .vld_index(ds_to_lfdb_decode_idx), //hash id 
        .v_out_vld(v_ds_to_lfdb_vld ));
    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign v_ds_to_lfdb_pld[i] = ds_to_lfdb_pld;
        end
    endgenerate
    assign ds_to_lfdb_rdy = 1'b1;    //preallocate, no back press

//AW+W
    vrp_arb #(
        .WIDTH(4),//evict down(AW+W) need 4to1 arbiter
        .PLD_WIDTH($bits(evict_to_ds_pld_t))
    ) u_EVICT_down_arb(
        .v_vld_s(v_evict_to_ds_vld     ),
        .v_pld_s(v_evict_to_ds_pld     ),
        .v_rdy_s(v_evict_to_ds_rdy     ),
        .rdy_m  (ds_input_evict_rdy    ), 
        .vld_m  (evict_to_ds_vld       ), //output to ds
        .pld_m  (evict_to_ds_pld       ));//output to ds
//bresp
        logic [1:0]bresp_decode_idx;
        assign bresp_decode_idx = bresp_pld.hash_id;
    v_1toN_decode #(
        .N(4)
    ) u_Bresp_decode (
        .vld      (bresp_vld           ),//1to4
        .vld_index(bresp_decode_idx   ),//hash id //这是evict_down，用它来release rob entry
        .v_out_vld(v_bresp_vld         ));
    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign v_bresp_pld [i] = bresp_pld;
        end
    endgenerate
    assign bresp_rdy       = 1'b1; //preallocate no back press

//---------------------------------------------------------------------------------------
//            end
//---------------------------------------------------------------------------------------


generate
    for(genvar i=0;i<4;i=i+1)begin:hash_linefillDB_gen
        linefillDB # ( 
            .ARB_TO_LFDB_DELAY(WR_CMD_DELAY_LF))
         u_linefill_data_buffer(
            .clk                     (clk                          ),
            .rst_n                   (rst_n                        ),
            .linefill_data_done      (v_linefill_data_done[i]      ),
            .linefill_data_done_idx  (v_linefill_data_done_idx[i]  ),
            .linefill_to_ram_done    (v_linefill_to_ram_done[i]    ),
            .linefill_to_ram_done_idx(v_linefill_to_ram_done_idx[i]),
            .ds_to_lfdb_vld          (v_ds_to_lfdb_vld[i]          ),
            .ds_to_lfdb_pld          (v_ds_to_lfdb_pld[i]          ),
            .ds_to_lfdb_rdy          (v_ds_to_lfdb_rdy[i]          ),
            .lfdb_rdreq_vld          (v_lf_wrreq_vld[i]            ),//arb decode出的linefill 请求
            .lfdb_rdreq_pld          (v_lf_wrreq_pld[i]            ),//arb decode出的linefill 请求
            .lfdb_rdreq_rdy          (v_lf_wrreq_rdy[i]            ),//arb decode出的linefill 请求
            .lfdb_to_ram_vld         (v_lfdb_to_ram_vld[i]         ),//to sram
            .lfdb_to_ram_pld         (v_lfdb_to_ram_pld[i]         ),//to sram
            //.lfdb_to_ram_rdy         (v_lfdb_to_ram_rdy[i]         ),//to sram
            .lfdb_to_ram_rdy         (1'b1                         ),//to sram
            .alloc_vld               (v_linefill_alloc_vld[i]      ),
            .alloc_idx               (v_linefill_alloc_idx[i]      ),
            .alloc_rdy               (v_linefill_alloc_rdy[i]      )
        );
    end
endgenerate
generate
    for(genvar i=0;i<4;i=i+1)begin:hash_evictDB_gen
        evictDB   u_evict_data_buffer (
            .clk                (clk),
            .rst_n              (rst_n),  
            .evict_clean        (v_evict_clean[i]       ),   
            .evict_clean_idx    (v_evict_clean_idx[i]   ),
            .evict_req_pld      (v_evict_req_pld[i]     ),
            .evict_req_vld      (v_evict_req_vld[i]     ),
            .evict_req_rdy      (v_evict_req_rdy[i]     ),
            .ram_to_evdb_data_in(evict_data_out_to_evdb[i] ),//sram input data
            .ram_to_evdb_data_vld(evict_data_out_vld_to_evdb[i]),   
            .alloc_vld          (v_evict_alloc_vld[i]   ),
            .alloc_idx          (v_evict_alloc_idx[i]   ),
            .alloc_rdy          (v_evict_alloc_rdy[i]   ),
            .evict_to_ds_vld    (v_evict_to_ds_vld[i]   ),
            .evict_to_ds_pld    (v_evict_to_ds_pld[i]   ),
            .evict_to_ds_rdy    (v_evict_to_ds_rdy[i]   )
        );
    end
endgenerate
    
generate
    for(genvar i=0;i<4;i=i+1)begin:hash_RDB_gen
        rdb_agent u_west_rdb_agent(
            .clk                (clk                            ),      
            .rst_n              (rst_n                          ),
            .to_us_done         (v_west_read_to_us_done[i]      ),
            .to_us_done_idx     (v_west_read_to_us_done_idx[i]  ),
            .dataram_rd_vld     (v_west_read_cmd_vld[i]         ),
            .dataram_rd_pld     (v_west_read_cmd_pld[i]         ),
            .dataram_rd_rdy     (v_west_read_cmd_rdy[i]         ),
            .alloc_vld          (v_west_read_alloc_vld[i]       ),
            .alloc_idx          (v_west_read_alloc_idx[i]       ),
            .alloc_rdy          (v_west_read_alloc_rdy[i]       ),
            .RDB_rdy            ( 1'b1                          ),
            .rdb_mem_en         (west_rdb_mem_en[i]             ),
            .rdb_wr_en          (west_rdb_wr_en[i]              ),
            .rdb_addr           (west_rdb_addr[i]               ));
        readDB u_west_read_data_buffer(
            .clk                (clk                            ),        
            .rst_n              (rst_n                          ),
            .rdb_addr           (west_rdb_addr[i]               ),
            .rdb_mem_en         (west_rdb_mem_en[i]             ),
            .rdb_wr_en          (west_rdb_wr_en[i]              ),
            .ram_to_rdb_data_in (west_data_out_to_rdb[i]        ),//from sram array
            .ram_to_rdb_data_vld(west_data_out_vld_to_rdb[i]    ),//from sram
            .rdb_to_us_data_vld (v_west_rdb_to_us_data_vld[i]   ),
            .rdb_to_us_data_pld (v_west_rdb_to_us_data_pld[i]   ));// top output 

        rdb_agent u_east_rdb_agent(
            .clk                (clk                            ),      
            .rst_n              (rst_n                          ),
            .to_us_done         (v_east_read_to_us_done[i]      ),
            .to_us_done_idx     (v_east_read_to_us_done_idx[i]  ),
            .dataram_rd_vld     (v_east_read_cmd_vld[i]         ),
            .dataram_rd_pld     (v_east_read_cmd_pld[i]         ),
            .dataram_rd_rdy     (v_east_read_cmd_rdy[i]         ),
            .alloc_vld          (v_east_read_alloc_vld[i]       ),
            .alloc_idx          (v_east_read_alloc_idx[i]       ),
            .alloc_rdy          (v_east_read_alloc_rdy[i]       ),
            .RDB_rdy            (1'b1                           ),
            .rdb_mem_en         (east_rdb_mem_en[i]             ),
            .rdb_wr_en          (east_rdb_wr_en[i]              ),
            .rdb_addr           (east_rdb_addr[i]               ));
        readDB u_east_read_data_buffer(
            .clk                (clk                            ),        
            .rst_n              (rst_n                          ),
            .rdb_addr           (east_rdb_addr[i]               ),
            .rdb_mem_en         (east_rdb_mem_en[i]             ),
            .rdb_wr_en          (east_rdb_wr_en [i]             ),
            .ram_to_rdb_data_in (east_data_out_to_rdb[i]        ),//from sram array
            .ram_to_rdb_data_vld(east_data_out_vld_to_rdb[i]    ),//from sram
            .rdb_to_us_data_vld (v_east_rdb_to_us_data_vld[i]   ),
            .rdb_to_us_data_pld (v_east_rdb_to_us_data_pld[i]   ));// top output
            
        rdb_agent u_south_rdb_agent(
            .clk                (clk                            ),      
            .rst_n              (rst_n                          ),
            .to_us_done         (v_south_read_to_us_done[i]     ),
            .to_us_done_idx     (v_south_read_to_us_done_idx[i] ),
            .dataram_rd_vld     (v_south_read_cmd_vld[i]        ),
            .dataram_rd_pld     (v_south_read_cmd_pld[i]        ),
            .dataram_rd_rdy     (v_south_read_cmd_rdy[i]        ),
            .alloc_vld          (v_south_read_alloc_vld[i]      ),
            .alloc_idx          (v_south_read_alloc_idx[i]      ),
            .alloc_rdy          (v_south_read_alloc_rdy[i]      ),
            .RDB_rdy            (1'b1                           ),
            .rdb_mem_en         (south_rdb_mem_en[i]            ),
            .rdb_wr_en          (south_rdb_wr_en[i]             ),
            .rdb_addr           (south_rdb_addr[i]              ));
        readDB u_south_read_data_buffer(
            .clk                (clk                            ),        
            .rst_n              (rst_n                          ),
            .rdb_addr           (south_rdb_addr[i]              ),
            .rdb_mem_en         (south_rdb_mem_en[i]            ),
            .rdb_wr_en          (south_rdb_wr_en[i]             ),
            .ram_to_rdb_data_in (south_data_out_to_rdb[i]       ),//from sram array
            .ram_to_rdb_data_vld(south_data_out_vld_to_rdb[i]   ),//from sram
            .rdb_to_us_data_vld (v_south_rdb_to_us_data_vld[i]  ),
            .rdb_to_us_data_pld (v_south_rdb_to_us_data_pld[i]  ));// top output 

        rdb_agent u_north_rdb_agent(
            .clk                (clk                            ),      
            .rst_n              (rst_n                          ),
            .to_us_done         (v_north_read_to_us_done[i]     ),
            .to_us_done_idx     (v_north_read_to_us_done_idx[i] ),
            .dataram_rd_vld     (v_north_read_cmd_vld[i]        ),
            .dataram_rd_pld     (v_north_read_cmd_pld[i]        ),
            .dataram_rd_rdy     (v_north_read_cmd_rdy[i]        ),
            .alloc_vld          (v_north_read_alloc_vld[i]      ),
            .alloc_idx          (v_north_read_alloc_idx[i]      ),
            .alloc_rdy          (v_north_read_alloc_rdy[i]      ),
            .RDB_rdy            (1'b1                           ),
            .rdb_mem_en         (north_rdb_mem_en[i]            ),
            .rdb_wr_en          (north_rdb_wr_en[i]             ),
            .rdb_addr           (north_rdb_addr[i]              ));
        readDB u_north_read_data_buffer(                
            .clk                (clk                            ),        
            .rst_n              (rst_n                          ),
            .rdb_addr           (north_rdb_addr[i]              ),
            .rdb_mem_en         (north_rdb_mem_en[i]            ),
            .rdb_wr_en          (north_rdb_wr_en[i]             ),
            .ram_to_rdb_data_in (north_data_out_to_rdb[i]       ),//from sram array
            .ram_to_rdb_data_vld(north_data_out_vld_to_rdb[i]   ),//from sram
            .rdb_to_us_data_vld (v_north_rdb_to_us_data_vld[i]  ),
            .rdb_to_us_data_pld (v_north_rdb_to_us_data_pld[i]  ));// top output 
    end
endgenerate


//============= data to us decode===========================
    rd_data_master_decode #( 
        .M(4),
        .N(WRD_REQ_NUM)
    ) u_west_rdata_switch_xbar(
        .in_vld  (v_west_rdb_to_us_data_vld),
        .in_pld  (v_west_rdb_to_us_data_pld),
        //.select  (v_west_rdb_to_us_data_pld.txnid.master_id),
        .out_vld (w_rd_data_vld            ),
        .out_pld (w_rd_data_pld            ));
    rd_data_master_decode #( 
        .M(4),
        .N(ERD_REQ_NUM)
    ) u_east_rdata_switch_xbar(
        .in_vld  (v_east_rdb_to_us_data_vld),
        .in_pld  (v_east_rdb_to_us_data_pld),
        //.select  (v_east_rdb_to_us_data_pld.txnid.master_id),
        .out_vld (e_rd_data_vld            ),
        .out_pld (e_rd_data_pld            ));

    rd_data_master_decode #( 
        .M(4),
        .N(SRD_REQ_NUM)
    ) u_south_rdata_switch_xbar(
        .in_vld  (v_south_rdb_to_us_data_vld),
        .in_pld  (v_south_rdb_to_us_data_pld),
        //.select  (v_south_rdb_to_us_data_pld.txnid.master_id),
        .out_vld (s_rd_data_vld             ),
        .out_pld (s_rd_data_pld             ));

    rd_data_master_decode #( 
        .M(4),
        .N(NRD_REQ_NUM)
    ) u_north_rdata_switch_xbar(
        .in_vld  (v_north_rdb_to_us_data_vld),
        .in_pld  (v_north_rdb_to_us_data_pld),
        //.select  (v_north_rdb_to_us_data_pld.txnid.master_id),
        .out_vld (n_rd_data_vld             ),
        .out_pld (n_rd_data_pld             ));



//WDB
    generate
        for(genvar i=0;i<4;i=i+1)begin:hash_WDB_gen
            write_DB_agent #( 
                .ARB_TO_WDB_DELAY(WR_CMD_DELAY_WEST),
                .WRITE_DONE_DELAY())
            u_west_write_DB_agent(
                .clk            (clk                         ),
                .rst_n          (rst_n                       ),
                .alloc_vld      (v_west_write_alloc_vld[i]   ),
                .alloc_idx      (v_west_write_alloc_idx[i]   ),
                .alloc_rdy      (v_west_write_alloc_rdy[i]   ),
                .write_wdb_pld  (w_wdb_data_pld[i]           ),
                .write_wdb_vld  (w_wr_vld[i]                 ),
                .write_wdb_rdy  (w_wr_rdy[i]                 ),//to mshr arb
                .write_done     (v_west_write_done[i]        ),
                .write_done_idx (v_west_write_done_idx[i]    ),
                .dataram_wr_vld (v_west_write_cmd_vld[i]     ),
                .dataram_wr_pld (v_west_write_cmd_pld[i]     ),
                .dataram_wr_rdy (v_west_write_cmd_rdy[i]     ),
                .write_sram_vld (west_write_cmd_vld_in[i]    ),//output
                .write_sram_pld (west_write_cmd_pld_in[i]    ),//output to sram
                .write_sram_rdy (1'b1       ));

            write_DB_agent  #( 
                .ARB_TO_WDB_DELAY(WR_CMD_DELAY_EAST),
                .WRITE_DONE_DELAY())
            u_east_write_DB_agent(
                .clk            (clk                         ),
                .rst_n          (rst_n                       ),
                .alloc_vld      (v_east_write_alloc_vld[i]   ),
                .alloc_idx      (v_east_write_alloc_idx[i]   ),
                .alloc_rdy      (v_east_write_alloc_rdy[i]   ),
                .write_wdb_pld  (e_wdb_data_pld[i]           ),
                .write_wdb_vld  (e_wr_vld[i]                 ),
                .write_wdb_rdy  (e_wr_rdy[i]                 ),//to mshr arb
                .write_done     (v_east_write_done[i]        ),
                .write_done_idx (v_east_write_done_idx[i]    ),
                .dataram_wr_vld (v_east_write_cmd_vld[i]     ),
                .dataram_wr_pld (v_east_write_cmd_pld[i]     ),
                .dataram_wr_rdy (v_east_write_cmd_rdy[i]     ),
                .write_sram_vld (east_write_cmd_vld_in[i]    ),
                .write_sram_pld (east_write_cmd_pld_in[i]    ),
                .write_sram_rdy (1'b1       ));
                //.write_sram_rdy (east_write_cmd_rdy[i]       )
        
            write_DB_agent #( 
                .ARB_TO_WDB_DELAY(WR_CMD_DELAY_SOUTH),
                .WRITE_DONE_DELAY())
             u_south_write_DB_agent(
                .clk            (clk                         ),
                .rst_n          (rst_n                       ),
                .alloc_vld      (v_south_write_alloc_vld[i]  ),
                .alloc_idx      (v_south_write_alloc_idx[i]  ),
                .alloc_rdy      (v_south_write_alloc_rdy[i]  ),
                .write_wdb_pld  (s_wdb_data_pld[i]           ),
                .write_wdb_vld  (s_wr_vld[i]                 ),
                .write_wdb_rdy  (s_wr_rdy[i]                 ),//to mshr arb
                .write_done     (v_south_write_done[i]       ),
                .write_done_idx (v_south_write_done_idx[i]   ),
                .dataram_wr_vld (v_south_write_cmd_vld[i]    ),
                .dataram_wr_pld (v_south_write_cmd_pld[i]    ),
                .dataram_wr_rdy (v_south_write_cmd_rdy[i]    ),
                .write_sram_vld (south_write_cmd_vld_in[i]   ),
                .write_sram_pld (south_write_cmd_pld_in[i]   ),
                .write_sram_rdy (1'b1      ));
                //.write_sram_rdy (south_write_cmd_rdy[i]      )
        
            write_DB_agent #( 
                .ARB_TO_WDB_DELAY(WR_CMD_DELAY_NORTH),
                .WRITE_DONE_DELAY())
            u_north_write_DB_agent(
                .clk            (clk                         ),
                .rst_n          (rst_n                       ),
                .alloc_vld      (v_north_write_alloc_vld[i]  ),
                .alloc_idx      (v_north_write_alloc_idx[i]  ),
                .alloc_rdy      (v_north_write_alloc_rdy[i]  ),
                .write_wdb_pld  (n_wdb_data_pld[i]           ),
                .write_wdb_vld  (n_wr_vld[i]                 ),
                .write_wdb_rdy  (n_wr_rdy[i]                 ),//to mshr arb
                .write_done     (v_north_write_done[i]       ),
                .write_done_idx (v_north_write_done_idx[i]   ),
                .dataram_wr_vld (v_north_write_cmd_vld[i]    ),
                .dataram_wr_pld (v_north_write_cmd_pld[i]    ),
                .dataram_wr_rdy (v_north_write_cmd_rdy[i]    ),
                .write_sram_vld (north_write_cmd_vld_in[i]   ),
                .write_sram_pld (north_write_cmd_pld_in[i]   ),
                .write_sram_rdy (1'b1      ));
                //.write_sram_rdy (north_write_cmd_rdy[i]      )
        end
    endgenerate

    read_cmd_sel u_read_cmd_sel ( 
        .v_west_read_cmd_vld    (v_west_read_cmd_vld    ),
        .v_east_read_cmd_vld    (v_east_read_cmd_vld    ),
        .v_south_read_cmd_vld   (v_south_read_cmd_vld   ),
        .v_north_read_cmd_vld   (v_north_read_cmd_vld   ),
        .v_evict_req_vld        (v_evict_req_vld        ),
        .v_west_read_cmd_pld    (v_west_read_cmd_pld    ),
        .v_east_read_cmd_pld    (v_east_read_cmd_pld    ),
        .v_south_read_cmd_pld   (v_south_read_cmd_pld   ),
        .v_north_read_cmd_pld   (v_north_read_cmd_pld   ),
        .v_evict_req_pld        (v_evict_req_pld        ),
        .toram_west_rd_cmd_vld  (toram_west_rd_cmd_vld  ),
        .toram_west_rd_cmd_pld  (toram_west_rd_cmd_pld  ));

    write_cmd_sel u_write_cmd_sel( 
        .v_lfdb_to_ram_vld              (v_lfdb_to_ram_vld              ),
        .west_write_cmd_vld_in          (west_write_cmd_vld_in          ),
        .east_write_cmd_vld_in          (east_write_cmd_vld_in          ),
        .south_write_cmd_vld_in         (south_write_cmd_vld_in         ),
        .north_write_cmd_vld_in         (north_write_cmd_vld_in         ),
        .v_lfdb_to_ram_pld              (v_lfdb_to_ram_pld              ),
        .west_write_cmd_pld_in          (west_write_cmd_pld_in          ),
        .east_write_cmd_pld_in          (east_write_cmd_pld_in          ),
        .south_write_cmd_pld_in         (south_write_cmd_pld_in         ),
        .north_write_cmd_pld_in         (north_write_cmd_pld_in         ),
        .toram_west_write_cmd_vld_in    (toram_west_write_cmd_vld_in    ),
        .toram_east_write_cmd_vld_in    (toram_east_write_cmd_vld_in    ),
        .toram_south_write_cmd_vld_in   (toram_south_write_cmd_vld_in   ),
        .toram_north_write_cmd_vld_in   (toram_north_write_cmd_vld_in   ),
        .toram_west_write_cmd_pld_in    (toram_west_write_cmd_pld_in    ),
        .toram_east_write_cmd_pld_in    (toram_east_write_cmd_pld_in    ),
        .toram_south_write_cmd_pld_in   (toram_south_write_cmd_pld_in   ),
        .toram_north_write_cmd_pld_in   (toram_north_write_cmd_pld_in   ));

    rdb_data_sel u_rd_data_sel ( 
        .east_data_out_vld_todb   (east_data_out_vld_todb   ),
        .east_data_out_todb       (east_data_out_todb       ),
        .west_data_out_vld_todb   (west_data_out_vld_todb   ),
        .west_data_out_todb       (west_data_out_todb       ),
        .south_data_out_vld_todb  (south_data_out_vld_todb  ),
        .south_data_out_todb      (south_data_out_todb      ),
        .north_data_out_vld_todb  (north_data_out_vld_todb  ),
        .north_data_out_todb      (north_data_out_todb      ),
        .east_data_out_vld_to_rdb (east_data_out_vld_to_rdb ),
        .east_data_out_to_rdb     (east_data_out_to_rdb     ),
        .west_data_out_vld_to_rdb (west_data_out_vld_to_rdb ),
        .west_data_out_to_rdb     (west_data_out_to_rdb     ),
        .south_data_out_vld_to_rdb(south_data_out_vld_to_rdb),
        .south_data_out_to_rdb    (south_data_out_to_rdb    ),
        .evict_data_out_vld_to_evdb(evict_data_out_vld_to_evdb),
        .evict_data_out_to_evdb    (evict_data_out_to_evdb  ),
        .north_data_out_vld_to_rdb(north_data_out_vld_to_rdb),
        .north_data_out_to_rdb    (north_data_out_to_rdb    ));


//---------------------------------------------------------------------------------------
//            SRAM ARRAY
//---------------------------------------------------------------------------------------

        write_ram_cmd_t                     toram_west_write_cmd_pld_in_cmd [7:0]     ;
        write_ram_cmd_t                     toram_south_write_cmd_pld_in_cmd[7:0]     ;
        write_ram_cmd_t                     toram_north_write_cmd_pld_in_cmd[7:0]     ;
        write_ram_cmd_t                     toram_east_write_cmd_pld_in_cmd [7:0];

        group_data_pld_t                    toram_west_write_cmd_pld_in_data [7:0]    ;
        group_data_pld_t                    toram_south_write_cmd_pld_in_data[7:0]    ;
        group_data_pld_t                    toram_north_write_cmd_pld_in_data[7:0]    ;
        group_data_pld_t                    toram_east_write_cmd_pld_in_data [7:0]    ;

        generate
            for(genvar i=0;i<8;i=i+1)begin
                assign toram_west_write_cmd_pld_in_cmd [i] = toram_west_write_cmd_pld_in[i].write_cmd;
                assign toram_south_write_cmd_pld_in_cmd[i] = toram_south_write_cmd_pld_in[i].write_cmd;
                assign toram_north_write_cmd_pld_in_cmd[i] = toram_north_write_cmd_pld_in[i].write_cmd;
                assign toram_east_write_cmd_pld_in_cmd [i] = toram_east_write_cmd_pld_in[i].write_cmd;

                assign toram_west_write_cmd_pld_in_data [i] = toram_west_write_cmd_pld_in[i].data ;
                assign toram_south_write_cmd_pld_in_data[i] = toram_south_write_cmd_pld_in[i].data;
                assign toram_north_write_cmd_pld_in_data[i] = toram_north_write_cmd_pld_in[i].data;
                assign toram_east_write_cmd_pld_in_data [i] = toram_east_write_cmd_pld_in[i].data ;
            end
        endgenerate

    
    sram_group  u_vec_data_ram_array(
        .clk                      (clk                                      ),
        .clk_div                  (clk_div                                  ),
        .rst_n                    (rst_n                                    ),
        .west_read_cmd_pld_in     (toram_west_rd_cmd_pld                    ),
        .west_read_cmd_vld_in     (toram_west_rd_cmd_vld                    ),
        .west_write_cmd_pld_in    (toram_west_write_cmd_pld_in_cmd    ),
        .west_write_cmd_vld_in    (toram_west_write_cmd_vld_in              ),
        .east_write_cmd_pld_in    (west_write_cmd_pld_out                   ),//from loopback
        .east_write_cmd_vld_in    (west_write_cmd_vld_out                   ),//from loopback
        .south_write_cmd_pld_in   (toram_south_write_cmd_pld_in_cmd   ),
        .south_write_cmd_vld_in   (toram_south_write_cmd_vld_in             ),
        .north_write_cmd_pld_in   (toram_north_write_cmd_pld_in_cmd   ),
        .north_write_cmd_vld_in   (toram_north_write_cmd_vld_in             ),
        .east_write_cmd_pld_out   (east_write_cmd_pld_out                   ),
        .east_write_cmd_vld_out   (east_write_cmd_vld_out                   ),
        .east_read_cmd_pld_in     (west_read_cmd_pld_out                    ),//from loopback
        .east_read_cmd_vld_in     (west_read_cmd_vld_out                    ),//from loopback
        .east_read_cmd_pld_out    (east_read_cmd_pld_out                    ),
        .east_read_cmd_vld_out    (east_read_cmd_vld_out                    ),

        .west_data_in_vld         (toram_west_write_cmd_vld_in              ),//from west wdb
        .west_data_in             (toram_west_write_cmd_pld_in_data         ),//from west wdb
        .east_data_in_vld         (west_data_out_vld                        ),//from loopback
        .east_data_in             (west_data_out                            ),//from loopback
        .south_data_in_vld        (toram_south_write_cmd_vld_in             ),
        .south_data_in            (toram_south_write_cmd_pld_in_data        ),
        .north_data_in_vld        (toram_north_write_cmd_vld_in             ),
        .north_data_in            (toram_north_write_cmd_pld_in_data        ),
        .west_data_out_vld        (west_data_out_vld_todb                   ),//to west rdb
        .west_data_out            (west_data_out_todb                       ),//to west rdb
        .east_data_out_vld        (east_data_out_vld_toloop                 ),//to loopback
        .east_data_out            (east_data_out_toloop                     ),//to loopback
        .south_data_out_vld       (south_data_out_vld_todb                  ),//to south db
        .south_data_out           (south_data_out_todb                      ),//to south db
        .north_data_out_vld       (north_data_out_vld_todb                  ),//to north db
        .north_data_out           (north_data_out_todb                      ));
        //.west_read_cmd_pld_out    (west_read_cmd_pld_out    ),//
        //.west_read_cmd_vld_out    (west_read_cmd_vld_out    ),//
        

 
    loop_back  u_loop_back ( 
        .clk                     (clk                               ),
        .clk_div                 (clk_div                           ),
        .rst_n                   (rst_n                             ),
        .west_write_cmd_pld_in   (east_write_cmd_pld_out            ),//from sram
        .west_write_cmd_vld_in   (east_write_cmd_vld_out            ),//from sram
        .west_read_cmd_pld_in    (east_read_cmd_pld_out             ),//from sram
        .west_read_cmd_vld_in    (east_read_cmd_vld_out             ),//from sram
        .west_data_in_vld        (east_data_out_vld_toloop          ),//from sram
        .west_data_in            (east_data_out_toloop              ),//from sram
        .east_write_cmd_pld_in   (toram_east_write_cmd_pld_in_cmd   ),//from east wdb
        .east_write_cmd_vld_in   (toram_east_write_cmd_vld_in             ),//from east wdb
        .east_data_in_vld        (toram_east_write_cmd_vld_in             ),//from east wdb
        .east_data_in            (toram_east_write_cmd_pld_in_data        ),//from east wdb
        .west_read_cmd_pld_out   (west_read_cmd_pld_out             ),//to sram
        .west_read_cmd_vld_out   (west_read_cmd_vld_out             ),//to sram
        .west_write_cmd_pld_out  (west_write_cmd_pld_out            ),//to sram
        .west_write_cmd_vld_out  (west_write_cmd_vld_out            ),//to sram
        .west_data_out_vld       (west_data_out_vld                 ),//to sram
        .west_data_out           (west_data_out                     ),//to sram
        .east_read_cmd_pld_out   (                                  ),//float
        .east_read_cmd_vld_out   (                                  ),//float
        .east_data_out_vld       (east_data_out_vld_todb            ),//to east rdb
        .east_data_out           (east_data_out_todb                ));
//---------------------------------------------------------------------------------------

endmodule
