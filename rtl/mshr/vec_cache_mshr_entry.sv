module vec_cache_mshr_entry
    import vector_cache_pkg::*; 
    (
    input  logic                               clk                        ,
    input  logic                               rst_n                      , 
    input  logic                               mshr_update_en_0           ,
    input  logic                               mshr_update_en_1           ,
    input  mshr_entry_t                        mshr_update_pld_0          ,
    input  mshr_entry_t                        mshr_update_pld_1          ,

    output hzd_mshr_pld_t                      mshr_out_pld               ,

    output logic                               alloc_vld                  ,
    input  logic                               alloc_rdy                  ,

    input  logic                               dataram_rd_rdy_w           ,
    input  logic                               dataram_rd_rdy_e           ,
    input  logic                               dataram_rd_rdy_s           ,
    input  logic                               dataram_rd_rdy_n           ,
    output logic                               dataram_rd_vld_w           ,
    output logic                               dataram_rd_vld_e           ,
    output logic                               dataram_rd_vld_s           ,
    output logic                               dataram_rd_vld_n           ,
    output arb_out_req_t                       dataram_rd_pld           ,

    input  logic                               dataram_wr_rdy_w           ,
    input  logic                               dataram_wr_rdy_e           ,
    input  logic                               dataram_wr_rdy_s           ,
    input  logic                               dataram_wr_rdy_n           ,
    output logic                               dataram_wr_vld_w           ,
    output logic                               dataram_wr_vld_e           ,
    output logic                               dataram_wr_vld_s           ,
    output logic                               dataram_wr_vld_n           ,
    output arb_out_req_t                       dataram_wr_pld             ,

    input  logic                               evict_rdy                  ,
    output logic                               evict_rd_vld               ,
    output arb_out_req_t                       evict_rd_pld               ,

    output logic                               downstream_txreq_vld       ,
    input  logic                               downstream_txreq_rdy       ,
    output downstream_txreq_pld_t              downstream_txreq_pld       ,

    output logic                               linefill_req_vld           ,
    input  logic                               linefill_req_rdy           ,
    output arb_out_req_t                       linefill_req_pld           ,

    input  logic                               ds_txreq_done              ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0]ds_txreq_done_db_id        ,
    input  logic                               linefill_done              ,
    input  logic                               evict_clean                ,
    input  logic                               evict_done                 ,
    input  logic                               rd_done_west               ,
    input  logic                               rd_done_east               ,
    input  logic                               rd_done_south              ,
    input  logic                               rd_done_north              ,
    input  logic                               wr_done_west               ,
    input  logic                               wr_done_east               ,
    input  logic                               wr_done_south              ,
    input  logic                               wr_done_north              ,
    input  logic                               rdb_alloc_nfull_west       ,
    input  logic                               rdb_alloc_nfull_east       ,
    input  logic                               rdb_alloc_nfull_south      ,
    input  logic                               rdb_alloc_nfull_north      ,

    input  logic [MSHR_ENTRY_NUM-1 :0]         v_release_en               ,
    output logic                               release_en                 


);

    logic[MSHR_ENTRY_NUM-1 :0] v_keep_hzd_bitmap       ;
    logic                      hzd_release             ;
    logic                      hazard_free             ;
    logic                      need_evict              ;
    logic                      miss                    ;
    logic                      is_read                 ;
    logic                      is_write                ;
    logic                      state_evict_sent        ;
    logic                      state_evict_dram_clean  ;//ram to evdb done, evict_clean
    logic                      state_evdb_to_ds_done   ;
    logic                      state_ds_to_lfdb_sent   ;
    logic                      state_ds_to_lfdb_done   ;
    logic                      state_linefill_sent     ;
    logic                      state_linefill_done     ;
    logic                      state_rd_dataram_sent   ;
    logic                      state_rd_dataram_done   ;
    logic                      state_wr_dataram_sent   ;
    logic                      state_wr_dataram_done   ;
    logic                      hzd_checkpass           ;
    logic   [1:0]              direc_id                ;
    logic   [1:0]              hash_id                 ;
    dest_ram_id_t              dest_ram_id             ;
    logic                      evict_rd_vld_0          ;
    logic                      evict_rd_vld_1          ;
    logic                      evict_rd_vld_2          ;
    logic                      evict_rd_vld_3          ;
    arb_out_req_t              evict_rd_pld_0          ;
    arb_out_req_t              evict_rd_pld_1          ;
    arb_out_req_t              evict_rd_pld_2          ;
    arb_out_req_t              evict_rd_pld_3          ;  
    logic                      idle                    ;
    logic                      active                  ;
    mshr_entry_t               mshr_update_pld         ;
    mshr_entry_t               mshr_entry_pld_reg_file ;

    assign mshr_update_en  = mshr_update_en_0 | mshr_update_en_1                       ;
    assign mshr_update_pld = mshr_update_en_0 ? mshr_update_pld_0 : mshr_update_pld_1  ;
    
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            mshr_entry_pld_reg_file <=  'b0;
        end
        else if(mshr_update_en)begin
            mshr_entry_pld_reg_file <= mshr_update_pld;
        end
        else if(ds_txreq_done)   begin
            mshr_entry_pld_reg_file.wdb_entry_id <= ds_txreq_done_db_id;
        end
    end

    assign is_read       = (mshr_update_pld.opcode== `VEC_CACHE_CMD_READ)   ;
    assign is_write      = (mshr_update_pld.opcode== `VEC_CACHE_CMD_WRITE)  ;
    assign need_evict    = mshr_update_pld.need_evict                       ;
    assign miss          = ~mshr_update_pld.hit                             ; 
    assign hzd_checkpass = mshr_update_pld.hzd_pass                         ;
    assign direc_id      = mshr_entry_pld_reg_file.txn_id.direction_id      ;
    assign hash_id       = mshr_entry_pld_reg_file.tag[TAG_WIDTH-1:TAG_WIDTH-2];
    assign dest_ram_id   = {mshr_entry_pld_reg_file.tag[TAG_WIDTH-1:TAG_WIDTH-2],mshr_entry_pld_reg_file.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
    

    assign alloc_vld                        = idle;
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                          idle <= 1'b1;
        else if(alloc_rdy && alloc_vld)     idle <= 1'b0;
        else if(release_en && active)       idle <= 1'b1;
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                      active <= 1'b0;
        else if(mshr_update_en)         active <= 1'b1;
        else if(release_en    )         active <= 1'b0;         
    end
    
//========================================================
// hazard_checking WAIT_dependency
//========================================================
    assign mshr_out_pld.valid     = active && ~release_en             ;
    assign mshr_out_pld.txn_id    = mshr_entry_pld_reg_file.txn_id    ;
    assign mshr_out_pld.tag       = mshr_entry_pld_reg_file.tag       ;
    assign mshr_out_pld.index     = mshr_entry_pld_reg_file.index     ;
    assign mshr_out_pld.evict_tag = mshr_entry_pld_reg_file.evict_tag ;

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)              v_keep_hzd_bitmap <= 'b0                                ;
        else if(mshr_update_en) v_keep_hzd_bitmap <= mshr_update_pld.hzd_bitmap         ;
        else                    v_keep_hzd_bitmap <= v_keep_hzd_bitmap & (~v_release_en);
    end
    assign hzd_release = ((|v_keep_hzd_bitmap)==1'b0);

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)        hazard_free <= 1'b0 ;
        else              hazard_free <= (hzd_checkpass && mshr_update_en) || ( hzd_release && active);
    end

//========================================================
    // evict 
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_evict_sent <= 1'b1            ;
        else if(mshr_update_en)                                     state_evict_sent <= ~need_evict     ;
        else if(evict_rd_vld && evict_rdy && evict_rd_pld.last)     state_evict_sent <= 1'b1            ;
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_evict_dram_clean <= 1'b1      ;
        else if(mshr_update_en)                                     state_evict_dram_clean <= ~need_evict;
        else if(evict_clean)                                        state_evict_dram_clean <= 1'b1      ;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_evdb_to_ds_done <= 1'b1       ;
        else if(mshr_update_en)                                     state_evdb_to_ds_done <= ~need_evict;
        else if(evict_done)                                         state_evdb_to_ds_done <= 1'b1       ;
    end
    
    // linefill 
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                  state_ds_to_lfdb_sent <= 1'b1       ;
        else if(mshr_update_en)                                     state_ds_to_lfdb_sent <= ~miss      ;
        else if(downstream_txreq_vld && downstream_txreq_rdy)       state_ds_to_lfdb_sent <= 1'b1       ;
    end
    
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                                                  state_ds_to_lfdb_done <= 1'b1       ; 
        else if(mshr_update_en)                                     state_ds_to_lfdb_done <= ~miss      ;
        else if(ds_txreq_done)                                      state_ds_to_lfdb_done <= 1'b1       ;
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_linefill_sent <= 1'b1         ;
        else if(mshr_update_en)                                     state_linefill_sent <= ~miss        ;
        else if(linefill_req_vld && linefill_req_rdy)               state_linefill_sent <= 1'b1         ;
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                  state_linefill_done <= 1'b1         ;
        else if(mshr_update_en)                                     state_linefill_done <= ~miss        ;
        else if(linefill_done )                                     state_linefill_done <= 1'b1         ;
    end   
    
    //read
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                  state_rd_dataram_sent <= 1'b1      ;
        else if(mshr_update_en)                                     state_rd_dataram_sent <= ~is_read  ;
        else if((dataram_rd_vld_w && dataram_rd_rdy_w) |(dataram_rd_vld_e && dataram_rd_rdy_e) | (dataram_rd_vld_s && dataram_rd_rdy_s) | (dataram_rd_vld_n && dataram_rd_rdy_n))state_rd_dataram_sent <= 1'b1;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_rd_dataram_done <= 1'b1           ;
        else if(mshr_update_en)                                     state_rd_dataram_done <= ~is_read       ;
        else if(rd_done_west | rd_done_east | rd_done_south | rd_done_north)state_rd_dataram_done <= 1'b1   ;
    end

    //write
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_wr_dataram_sent <= 1'b1       ;
        else if(mshr_update_en)                                     state_wr_dataram_sent <= ~is_write  ;
        else if((dataram_wr_vld_w && dataram_wr_rdy_w) | (dataram_wr_vld_e && dataram_wr_rdy_e) |(dataram_wr_vld_s && dataram_wr_rdy_s) |(dataram_wr_vld_n && dataram_wr_rdy_n)) state_wr_dataram_sent <= 1'b1;
    end


    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                  state_wr_dataram_done <= 1'b1           ;
        else if(mshr_update_en)                                     state_wr_dataram_done <= ~is_write      ;
        else if(wr_done_west | wr_done_east | wr_done_south | wr_done_north) state_wr_dataram_done <= 1'b1  ;
    end

    assign release_en = state_rd_dataram_done && state_wr_dataram_done                              ; //read or write is the end 

    assign evict_rd_vld_0                    = hazard_free && ~state_evict_sent                      ;
    assign evict_rd_pld_0.txn_id.direction_id= mshr_entry_pld_reg_file.txn_id.direction_id           ;
    assign evict_rd_pld_0.txn_id.master_id   = mshr_entry_pld_reg_file.txn_id.master_id              ;
    assign evict_rd_pld_0.txn_id.mode        = mshr_entry_pld_reg_file.txn_id.mode                   ;
    assign evict_rd_pld_0.txn_id.byte_sel    = 2'd0                                                  ;
    assign evict_rd_pld_0.opcode             = `VEC_CACHE_EVICT                                      ; // evict opcode
    assign evict_rd_pld_0.sideband           = mshr_entry_pld_reg_file.sideband                      ;
    assign evict_rd_pld_0.way                = mshr_entry_pld_reg_file.way                           ;
    assign evict_rd_pld_0.tag                = mshr_entry_pld_reg_file.tag                           ;
    assign evict_rd_pld_0.index              = mshr_entry_pld_reg_file.index                         ; 
    assign evict_rd_pld_0.offset             = mshr_entry_pld_reg_file.offset                        ;
    assign evict_rd_pld_0.hash_id            = hash_id                                               ;
    assign evict_rd_pld_0.dest_ram_id        = dest_ram_id                                           ;
    assign evict_rd_pld_0.rob_entry_id       = mshr_entry_pld_reg_file.rob_entry_id                  ;
    assign evict_rd_pld_0.db_entry_id        = {mshr_entry_pld_reg_file.rob_entry_id,2'b00}          ;
    assign evict_rd_pld_0.last               = 1'b0;
    
    assign evict_rd_vld_1                    = hazard_free && ~state_evict_sent                      ;
    assign evict_rd_pld_1.txn_id.direction_id= mshr_entry_pld_reg_file.txn_id.direction_id           ;
    assign evict_rd_pld_1.txn_id.master_id   = mshr_entry_pld_reg_file.txn_id.master_id              ;
    assign evict_rd_pld_1.txn_id.mode        = mshr_entry_pld_reg_file.txn_id.mode                   ;
    assign evict_rd_pld_1.txn_id.byte_sel    = 2'd1                                                  ;
    assign evict_rd_pld_1.opcode             = `VEC_CACHE_EVICT                                      ;
    assign evict_rd_pld_1.sideband           = mshr_entry_pld_reg_file.sideband                      ;
    assign evict_rd_pld_1.index              = mshr_entry_pld_reg_file.index                         ; 
    assign evict_rd_pld_1.tag                = mshr_entry_pld_reg_file.tag                           ;
    assign evict_rd_pld_1.offset             = mshr_entry_pld_reg_file.offset                        ;
    assign evict_rd_pld_1.way                = mshr_entry_pld_reg_file.way                           ;
    assign evict_rd_pld_1.hash_id            = hash_id                                               ;
    assign evict_rd_pld_1.dest_ram_id        = dest_ram_id                                           ;
    assign evict_rd_pld_1.rob_entry_id       = mshr_entry_pld_reg_file.rob_entry_id                  ;
    assign evict_rd_pld_1.db_entry_id        = {mshr_entry_pld_reg_file.rob_entry_id,2'b01}          ;
    assign evict_rd_pld_1.last               = 1'b0                                                  ;
    
    assign evict_rd_vld_2                    = hazard_free && ~state_evict_sent                      ;
    assign evict_rd_pld_2.txn_id.direction_id= mshr_entry_pld_reg_file.txn_id.direction_id           ;
    assign evict_rd_pld_2.txn_id.master_id   = mshr_entry_pld_reg_file.txn_id.master_id              ;
    assign evict_rd_pld_2.txn_id.mode        = mshr_entry_pld_reg_file.txn_id.mode                   ;
    assign evict_rd_pld_2.txn_id.byte_sel    = 2'd2                                                  ;
    assign evict_rd_pld_2.opcode             = `VEC_CACHE_EVICT                                      ;
    assign evict_rd_pld_2.sideband           = mshr_entry_pld_reg_file.sideband                      ;
    assign evict_rd_pld_2.way                = mshr_entry_pld_reg_file.way                           ;
    assign evict_rd_pld_2.index              = mshr_entry_pld_reg_file.index                         ; 
    assign evict_rd_pld_2.tag                = mshr_entry_pld_reg_file.tag                           ;
    assign evict_rd_pld_2.offset             = mshr_entry_pld_reg_file.offset                        ;
    assign evict_rd_pld_2.hash_id            = hash_id                                               ;
    assign evict_rd_pld_2.dest_ram_id        = dest_ram_id                                           ;
    assign evict_rd_pld_2.rob_entry_id       = mshr_entry_pld_reg_file.rob_entry_id                  ;
    assign evict_rd_pld_2.db_entry_id        = {mshr_entry_pld_reg_file.rob_entry_id,2'b10}          ;
    assign evict_rd_pld_2.last               = 1'b0                                                  ;
    
    assign evict_rd_vld_3                    = hazard_free && ~state_evict_sent   ;
    assign evict_rd_pld_3.txn_id.direction_id= mshr_entry_pld_reg_file.txn_id.direction_id           ;
    assign evict_rd_pld_3.txn_id.master_id   = mshr_entry_pld_reg_file.txn_id.master_id              ;
    assign evict_rd_pld_3.txn_id.mode        = mshr_entry_pld_reg_file.txn_id.mode                   ;
    assign evict_rd_pld_3.txn_id.byte_sel    = 2'd3                                                  ;
    assign evict_rd_pld_3.opcode             = `VEC_CACHE_EVICT                                      ;
    assign evict_rd_pld_3.sideband           = mshr_entry_pld_reg_file.sideband                      ;
    assign evict_rd_pld_3.way                = mshr_entry_pld_reg_file.way                           ;
    assign evict_rd_pld_3.index              = mshr_entry_pld_reg_file.index                         ; 
    assign evict_rd_pld_3.tag                = mshr_entry_pld_reg_file.tag                           ;
    assign evict_rd_pld_3.offset             = mshr_entry_pld_reg_file.offset                        ;
    assign evict_rd_pld_3.hash_id            = hash_id                                               ;
    assign evict_rd_pld_3.dest_ram_id        = dest_ram_id                                           ;
    assign evict_rd_pld_3.rob_entry_id       = mshr_entry_pld_reg_file.rob_entry_id                  ;
    assign evict_rd_pld_3.db_entry_id        = {mshr_entry_pld_reg_file.rob_entry_id,2'b11}          ;
    assign evict_rd_pld_3.last               = 1'b1                                                  ;
    
    
    vrp_arb #(
        .WIDTH     (4 ),
        .PLD_WIDTH ($bits(arb_out_req_t))
    ) u_evict_four_part_arb (
        .v_vld_s({evict_rd_vld_3,evict_rd_vld_2,evict_rd_vld_1,evict_rd_vld_0} ),
        .v_rdy_s({evict_rd_rdy_3,evict_rd_rdy_2,evict_rd_rdy_1,evict_rd_rdy_0} ),
        .v_pld_s({evict_rd_pld_3,evict_rd_pld_2,evict_rd_pld_1,evict_rd_pld_0} ),
        .vld_m  (evict_rd_vld ),
        .rdy_m  (evict_rdy    ),
        .pld_m  (evict_rd_pld ));


    assign linefill_req_vld                 = state_ds_to_lfdb_done && ~state_linefill_done && ~state_linefill_sent;
    assign linefill_req_pld.txn_id          = mshr_entry_pld_reg_file.txn_id                        ;
    assign linefill_req_pld.opcode          = `VEC_CACHE_LINEFILL                                   ; //linefill opcode ;
    assign linefill_req_pld.sideband        = mshr_entry_pld_reg_file.sideband                      ;
    assign linefill_req_pld.tag             = mshr_entry_pld_reg_file.tag                           ;
    assign linefill_req_pld.index           = mshr_entry_pld_reg_file.index                         ;
    assign linefill_req_pld.offset          = mshr_entry_pld_reg_file.offset                        ;
    assign linefill_req_pld.way             = mshr_entry_pld_reg_file.way                           ;
    assign linefill_req_pld.hash_id         = hash_id                                               ;
    assign linefill_req_pld.dest_ram_id     = dest_ram_id                                           ;
    assign linefill_req_pld.rob_entry_id    = mshr_entry_pld_reg_file.rob_entry_id                  ;
    assign linefill_req_pld.db_entry_id     = mshr_entry_pld_reg_file.wdb_entry_id                  ;
    assign linefill_req_pld.last            = 1'b1;

    assign downstream_txreq_vld             = (hazard_free && (~state_ds_to_lfdb_sent) && state_evict_dram_clean) ;
    assign downstream_txreq_pld.txn_id      = mshr_entry_pld_reg_file.txn_id                        ;
    assign downstream_txreq_pld.opcode      = mshr_entry_pld_reg_file.opcode                        ;
    assign downstream_txreq_pld.sideband    = mshr_entry_pld_reg_file.sideband                      ;
    assign downstream_txreq_pld.addr.tag    = mshr_entry_pld_reg_file.tag                           ;
    assign downstream_txreq_pld.addr.index  = mshr_entry_pld_reg_file.index                         ;
    assign downstream_txreq_pld.addr.offset = mshr_entry_pld_reg_file.offset                        ;
    assign downstream_txreq_pld.way         = mshr_entry_pld_reg_file.way                           ;
    assign downstream_txreq_pld.dest_ram_id = dest_ram_id                   ;
    assign downstream_txreq_pld.db_entry_id = 'b0                                                   ;
    assign downstream_txreq_pld.rob_entry_id= mshr_entry_pld_reg_file.rob_entry_id                  ;
    
   
    assign dataram_rd_vld_w             = rdb_alloc_nfull_west &&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`VEC_CACHE_WEST );
    assign dataram_rd_vld_e             = rdb_alloc_nfull_east &&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`VEC_CACHE_EAST );
    assign dataram_rd_vld_s             = rdb_alloc_nfull_south&&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`VEC_CACHE_SOUTH);
    assign dataram_rd_vld_n             = rdb_alloc_nfull_north&&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`VEC_CACHE_NORTH);
    
    assign dataram_rd_pld.txn_id        = mshr_entry_pld_reg_file.txn_id                            ;
    assign dataram_rd_pld.opcode        = `VEC_CACHE_READ                                           ; //read opcode ;
    assign dataram_rd_pld.sideband      = mshr_entry_pld_reg_file.sideband                          ;
    assign dataram_rd_pld.way           = mshr_entry_pld_reg_file.way                               ;
    assign dataram_rd_pld.index         = mshr_entry_pld_reg_file.index                             ;  
    assign dataram_rd_pld.offset        = mshr_entry_pld_reg_file.offset                            ;
    assign dataram_rd_pld.tag           = mshr_entry_pld_reg_file.tag                               ;
    assign dataram_rd_pld.hash_id       = hash_id                                                   ;
    assign dataram_rd_pld.dest_ram_id   = dest_ram_id                                               ;
    assign dataram_rd_pld.rob_entry_id  = mshr_entry_pld_reg_file.rob_entry_id                      ;
    assign dataram_rd_pld.db_entry_id   = 'b0                                                       ;//暂时没有alloc
    assign dataram_rd_pld.last          = 1'b1;


    assign dataram_wr_vld_w             = hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id ==`VEC_CACHE_WEST );
    assign dataram_wr_vld_e             = hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id ==`VEC_CACHE_EAST );
    assign dataram_wr_vld_s             = hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id ==`VEC_CACHE_SOUTH);
    assign dataram_wr_vld_n             = hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id ==`VEC_CACHE_NORTH);

    assign dataram_wr_pld.txn_id        = mshr_entry_pld_reg_file.txn_id                            ;
    assign dataram_wr_pld.opcode        = `VEC_CACHE_WRITE                                          ; //write opcode ;
    assign dataram_wr_pld.sideband      = mshr_entry_pld_reg_file.sideband                          ;
    assign dataram_wr_pld.tag           = mshr_entry_pld_reg_file.tag                               ;
    assign dataram_wr_pld.offset        = mshr_entry_pld_reg_file.offset                            ;
    assign dataram_wr_pld.way           = mshr_entry_pld_reg_file.way                               ;
    assign dataram_wr_pld.index         = mshr_entry_pld_reg_file.index                             ;  
    assign dataram_wr_pld.hash_id       = hash_id                                                   ;
    assign dataram_wr_pld.dest_ram_id   = dest_ram_id                                               ;
    assign dataram_wr_pld.rob_entry_id  = mshr_entry_pld_reg_file.rob_entry_id                      ;
    assign dataram_wr_pld.db_entry_id   = mshr_entry_pld_reg_file.wdb_entry_id                      ;
    assign dataram_wr_pld.last          = 1'b1                                                      ;

endmodule