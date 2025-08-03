module vec_cache_mshr_entry
    import vector_cache_pkg::*; 
    (
    input  logic                               clk                        ,
    input  logic                               rst_n                      , 
    input  logic                               mshr_update_en             ,
    input  mshr_entry_t                        mshr_entry_pld             ,
    //input  logic                               mshr_entry_vld             ,
    output logic                               entry_active               ,
    output mshr_entry_t                        mshr_out_pld                ,

    output logic                               alloc_vld                  ,
    input  logic                               alloc_rdy                  ,

    //input  logic                               rd_rdy                     ,
    input  logic                               w_dataram_rd_rdy           ,
    input  logic                               e_dataram_rd_rdy           ,
    input  logic                               s_dataram_rd_rdy           ,
    input  logic                               n_dataram_rd_rdy           ,
    output logic                               w_dataram_rd_vld           ,
    output logic                               e_dataram_rd_vld           ,
    output logic                               s_dataram_rd_vld           ,
    output logic                               n_dataram_rd_vld           ,
    output arb_out_req_t                       w_dataram_rd_pld           ,
    output arb_out_req_t                       e_dataram_rd_pld           ,
    output arb_out_req_t                       s_dataram_rd_pld           ,
    output arb_out_req_t                       n_dataram_rd_pld           ,

    //input  logic                               wr_rdy                     ,
    input  logic                               w_dataram_wr_rdy           ,
    input  logic                               e_dataram_wr_rdy           ,
    input  logic                               s_dataram_wr_rdy           ,
    input  logic                               n_dataram_wr_rdy           ,
    output logic                               w_dataram_wr_vld           ,
    output logic                               e_dataram_wr_vld           ,
    output logic                               s_dataram_wr_vld           ,
    output logic                               n_dataram_wr_vld           ,
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

    input  logic                               linefill_data_done         ,
    input  logic                               linefill_done              ,
    input  logic                               evict_clean                ,
    input  logic                               evict_done                 ,
    input  logic                               west_rd_done               ,
    input  logic                               east_rd_done               ,
    input  logic                               south_rd_done              ,
    input  logic                               north_rd_done              ,
    input  logic                               west_wr_done               ,
    input  logic                               east_wr_done               ,
    input  logic                               south_wr_done              ,
    input  logic                               north_wr_done              ,

    input  logic                                w_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]  w_rd_alloc_idx      ,
    input  logic                                e_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]  e_rd_alloc_idx      ,
    input  logic                                s_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]  s_rd_alloc_idx      ,
    input  logic                                n_rd_alloc_vld      ,
    input  logic [$clog2(RW_DB_ENTRY_NUM)-1:0]  n_rd_alloc_idx      ,
    //output logic                                w_rd_alloc_rdy      ,
    //output logic                                e_rd_alloc_rdy      ,
    //output logic                                s_rd_alloc_rdy      ,
    //output logic                                n_rd_alloc_rdy      ,

    input  logic                                linefill_alloc_vld  ,
    input  logic [$clog2(LFDB_ENTRY_NUM/4)-1:0] linefill_alloc_idx  ,
    //output logic                                linefill_alloc_rdy  ,

    input  logic                                evict_alloc_vld     ,
    input  logic [$clog2(EVDB_ENTRY_NUM/4)-1:0] evict_alloc_idx     ,
    //output logic                                evict_alloc_rdy     ,

    input  logic [MSHR_ENTRY_NUM-1 :0]         v_release_en         ,
    output logic                               release_en                 


);
    logic                      state_rd_dataram_2sent  ;
    logic                      linefill_data_2done     ;
    logic[MSHR_ENTRY_NUM-1 :0] v_keep_hzd_bitmap       ;
    logic                      hzd_release             ;
    logic                      hazard_free             ;
    logic                      linefill_sentA          ;
    logic                      linefill_dataA_done     ;
    logic                      state_rd_dataram        ;
    logic                      state_done              ;
    logic                      allocate_en             ;
    logic                      state_rd_sent_done      ;
    logic                      need_linefill           ;
    logic                      need_evict              ;
    logic                      hit                     ;
    logic                      miss                    ;
    logic                      is_read                 ;
    logic                      is_write                ;
    logic                      dataram_rd_vld          ;
    logic                      state_evict_sent        ;
    logic                      state_evict_dram_clean  ;//ram to evdb done, evict_clean
    logic                      state_evdb_to_ds_done   ;
    logic                      state_linefill_sent     ;
    logic                      state_ds_to_lfdb_done   ;
    logic                      state_linefill_done     ;
    logic                      state_rd_dataram_sent   ;
    logic                      state_rd_dataram_done   ;
    logic                      state_wr_dataram_sent   ;
    logic                      state_wr_dataram_done   ;
    logic                      hzd_checkpass           ;
    logic   [1:0]              direc_id                ;  
    logic                      evict_rd_vld_0          ;
    logic                      evict_rd_vld_1          ;
    logic                      evict_rd_vld_2          ;
    logic                      evict_rd_vld_3          ;
    arb_out_req_t              evict_rd_pld_0          ;
    arb_out_req_t              evict_rd_pld_1          ;
    arb_out_req_t              evict_rd_pld_2          ;
    arb_out_req_t              evict_rd_pld_3          ;   
    logic idle;
    logic active;

    mshr_entry_t mshr_entry_pld_reg_file;
    always_ff@(posedge clk )begin
        if(mshr_update_en)begin
            mshr_entry_pld_reg_file <= mshr_entry_pld;
        end
    end
    assign mshr_out_pld   = mshr_entry_pld_reg_file;

    
    assign hzd_checkpass = mshr_entry_pld.hzd_pass  ;
    //assign entry_active  = mshr_entry_vld           ;
    assign entry_active  = ~idle;
    //assign alloc_vld     = ~entry_active            ;
    assign alloc_vld     = idle;
    assign allocate_en   = mshr_update_en           ;
    assign direc_id      = mshr_entry_pld.txnid.direction_id; //txnid的低2bit表示方向：00：west；01：east；10：south；11：north

    
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                          idle <= 1'b1;
        else if(alloc_rdy && alloc_vld)     idle <= 1'b0;
        else if(release_en && active)       idle <= 1'b1;
    end

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                      active <= 1'b0;
        else if(mshr_update_en)         active <= 1'b1;
        else if(release_en      )       active <= 1'b0;         
    end
    
//========================================================
// hazard_checking WAIT_dependency
//========================================================
    logic [MSHR_ENTRY_NUM-1 :0] v_hzd_bitmap;
    assign v_hzd_bitmap = mshr_entry_pld.hzd_bitmap;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)              v_keep_hzd_bitmap <= 'b0;
        else if(mshr_update_en) v_keep_hzd_bitmap <= v_hzd_bitmap;
        else                    v_keep_hzd_bitmap <= v_keep_hzd_bitmap & (~v_release_en);
    end
    assign hzd_release = ((|v_keep_hzd_bitmap)==1'b0);

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)        hazard_free <= 1'b0 ;
        //else              hazard_free <= (hzd_checkpass && mshr_update_en) || ( hzd_release && entry_active);
        else              hazard_free <= (hzd_checkpass && mshr_update_en) || ( hzd_release && active);
    end

    logic [LFDB_ENTRY_NUM-1:0] lfdb_entry_id ;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                             lfdb_entry_id <= 'b0;
        else if(downstream_txreq_vld && downstream_txreq_rdy)  lfdb_entry_id <= downstream_txreq_pld.db_entry_id;
        else                                                   lfdb_entry_id <=  lfdb_entry_id ;
    end


//========================================================
    // evict 
    assign need_linefill = mshr_entry_pld.need_linefill ;
    assign need_evict    = mshr_entry_pld.need_evict    ;
    assign hit           = mshr_entry_pld.hit           ;
    //assign miss          = ~hit                         ;
    assign miss          = mshr_entry_pld.need_linefill ;
    assign is_read       = mshr_entry_pld.is_read       ;
    assign is_write      = mshr_entry_pld.is_write      ; 


    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                              state_evict_sent <= 1'b1 ;
        else if(mshr_update_en && need_evict)                   state_evict_sent <= 1'b0 ;
        else if(evict_rd_vld && evict_rdy && evict_rd_pld.last) state_evict_sent <= 1'b1 ;
        //else if(evict_rd_pld.last)                              state_evict_sent <= 1'b1 ;
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                state_evict_dram_clean <= 1'b1      ;
        else if(mshr_update_en && need_evict)     state_evict_dram_clean <= 1'b0      ;
        else if(evict_clean)                      state_evict_dram_clean <= 1'b1      ;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                state_evdb_to_ds_done <= 1'b1       ;
        else if(mshr_update_en && need_evict)     state_evdb_to_ds_done <= 1'b0       ;
        else if(evict_done)                       state_evdb_to_ds_done <= 1'b1       ;
    end
    //
    //assign evict_alloc_rdy              = evict_rd_vld && evict_rdy;
    assign evict_rd_vld_0                   = evict_alloc_vld && hazard_free && ~state_evict_sent;//evict is read, readout data, write into Evict data buffer
    assign evict_rd_pld_0.txnid.direction_id= mshr_entry_pld_reg_file.txnid.direction_id ;
    assign evict_rd_pld_0.txnid.master_id   = mshr_entry_pld_reg_file.txnid.master_id    ;
    assign evict_rd_pld_0.txnid.mode        = mshr_entry_pld_reg_file.txnid.mode         ;
    assign evict_rd_pld_0.txnid.byte_sel    = 2'd0                              ;
    assign evict_rd_pld_0.opcode            = `EVICT                            ;// evict opcode
    assign evict_rd_pld_0.way               = mshr_entry_pld_reg_file.way                ;
    assign evict_rd_pld_0.tag               = mshr_entry_pld_reg_file.req_tag;
    assign evict_rd_pld_0.index             = mshr_entry_pld_reg_file.index              ; 
    assign evict_rd_pld_0.offset            = mshr_entry_pld_reg_file.offset            ;
    assign evict_rd_pld_0.dest_ram_id       = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign evict_rd_pld_0.rob_entry_id      = mshr_entry_pld_reg_file.alloc_idx          ;
    assign evict_rd_pld_0.db_entry_id       = {evict_alloc_idx,2'b00}           ;
    assign evict_rd_pld_0.last              = 1'b0;
    assign evict_rd_pld_0.sideband          = mshr_entry_pld_reg_file.sideband  ;
    //assign evict_rd_pld_0.req_num           = 2'd0;
    //
    assign evict_rd_vld_1                   = evict_alloc_vld && hazard_free && ~state_evict_sent;
    assign evict_rd_pld_1.txnid.direction_id= mshr_entry_pld_reg_file.txnid.direction_id ;
    assign evict_rd_pld_1.txnid.master_id   = mshr_entry_pld_reg_file.txnid.master_id    ;
    assign evict_rd_pld_1.txnid.mode        = mshr_entry_pld_reg_file.txnid.mode         ;
    assign evict_rd_pld_1.txnid.byte_sel    = 2'd1                              ;
    assign evict_rd_pld_1.opcode            = `EVICT                              ;
    
    assign evict_rd_pld_1.index             = mshr_entry_pld_reg_file.index              ; 
    assign evict_rd_pld_1.tag               = mshr_entry_pld_reg_file.req_tag;
    assign evict_rd_pld_1.offset            = mshr_entry_pld_reg_file.offset            ;
    assign evict_rd_pld_1.way               = mshr_entry_pld_reg_file.way                ;
    
    assign evict_rd_pld_1.dest_ram_id       = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];
    assign evict_rd_pld_1.rob_entry_id      = mshr_entry_pld_reg_file.alloc_idx          ;
    assign evict_rd_pld_1.db_entry_id       = {evict_alloc_idx,2'b01}           ;
    assign evict_rd_pld_1.last              = 1'b0;
    assign evict_rd_pld_1.sideband          = mshr_entry_pld_reg_file.sideband  ;
    //assign evict_rd_pld_1.req_num       = 2'd1;
    //
    assign evict_rd_vld_2                   = evict_alloc_vld && hazard_free && ~state_evict_sent;
    assign evict_rd_pld_2.txnid.direction_id= mshr_entry_pld_reg_file.txnid.direction_id ;
    assign evict_rd_pld_2.txnid.master_id   = mshr_entry_pld_reg_file.txnid.master_id    ;
    assign evict_rd_pld_2.txnid.mode        = mshr_entry_pld_reg_file.txnid.mode         ;
    assign evict_rd_pld_2.txnid.byte_sel    = 2'd2                              ;
    assign evict_rd_pld_2.opcode            = `EVICT                              ;
    assign evict_rd_pld_2.way               = mshr_entry_pld_reg_file.way                ;
    assign evict_rd_pld_2.index             = mshr_entry_pld_reg_file.index              ; 
    assign evict_rd_pld_2.tag               = mshr_entry_pld_reg_file.req_tag;
    assign evict_rd_pld_2.offset            = mshr_entry_pld_reg_file.offset            ;
    assign evict_rd_pld_2.dest_ram_id       = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];
    assign evict_rd_pld_2.rob_entry_id      = mshr_entry_pld_reg_file.alloc_idx          ;
    assign evict_rd_pld_2.db_entry_id       = {evict_alloc_idx,2'b10}           ;
    assign evict_rd_pld_2.last              = 1'b0;
    assign evict_rd_pld_2.sideband          = mshr_entry_pld_reg_file.sideband  ;
    //assign evict_rd_pld_2.req_num       = 2'd2;
    //
    assign evict_rd_vld_3                   = evict_alloc_vld && hazard_free && ~state_evict_sent;
    assign evict_rd_pld_3.txnid.direction_id= mshr_entry_pld_reg_file.txnid.direction_id ;
    assign evict_rd_pld_3.txnid.master_id   = mshr_entry_pld_reg_file.txnid.master_id    ;
    assign evict_rd_pld_3.txnid.mode        = mshr_entry_pld_reg_file.txnid.mode         ;
    assign evict_rd_pld_3.txnid.byte_sel    = 2'd3                              ;
    assign evict_rd_pld_3.opcode            = `EVICT                              ;
    assign evict_rd_pld_3.way               = mshr_entry_pld_reg_file.way                ;
    assign evict_rd_pld_3.index             = mshr_entry_pld_reg_file.index              ; 
    assign evict_rd_pld_3.tag               = mshr_entry_pld_reg_file.req_tag;
    assign evict_rd_pld_3.offset            = mshr_entry_pld_reg_file.offset            ;
    assign evict_rd_pld_3.dest_ram_id       = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];
    assign evict_rd_pld_3.rob_entry_id      = mshr_entry_pld_reg_file.alloc_idx          ;
    assign evict_rd_pld_3.db_entry_id       = {evict_alloc_idx,2'b11}           ;
    assign evict_rd_pld_3.last              = 1'b1;
    assign evict_rd_pld_3.sideband          = mshr_entry_pld_reg_file.sideband  ;
    //assign evict_rd_pld_3.req_num           = 2'd3;

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
    


    // linefill 
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_linefill_sent <= 1'b1;
        else if(mshr_update_en && (need_linefill||need_evict))              state_linefill_sent <= 1'b0;
        //else if(mshr_update_en && need_linefill &&state_evict_dram_clean) state_linefill_sent <= 1'b0
        else if(downstream_txreq_vld && downstream_txreq_rdy)               state_linefill_sent <= 1'b1;
    end
    
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)                                                          state_ds_to_lfdb_done<= 1'b1; 
        else if(mshr_update_en && (need_linefill||need_evict))              state_ds_to_lfdb_done<= 1'b0;
        else if(linefill_data_done)                                         state_ds_to_lfdb_done<= 1'b1;//lfdb 收到linefill_data
    end

    //assign linefill_req_vld           = state_ds_to_lfdb_done && state_evict_dram_clean && ~state_linefill_done;//需要发4个，offset+1作为下一个地址
    assign linefill_req_vld              = state_ds_to_lfdb_done && ~state_linefill_done;
    assign linefill_req_pld.txnid        = mshr_entry_pld_reg_file.txnid    ;
    assign linefill_req_pld.opcode       = `LINEFILL               ; //linefill opcode ;
    assign linefill_req_pld.tag          = mshr_entry_pld_reg_file.req_tag;
    assign linefill_req_pld.index        = mshr_entry_pld_reg_file.index    ;
    assign linefill_req_pld.offset       = mshr_entry_pld_reg_file.offset   ;
    assign linefill_req_pld.way          = mshr_entry_pld_reg_file.way      ;
    assign linefill_req_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的2bit为block id，再下1bit为ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign linefill_req_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx;
    assign linefill_req_pld.db_entry_id  = lfdb_entry_id;
    assign linefill_req_pld.sideband     = mshr_entry_pld_reg_file.sideband;
    assign linefill_req_pld.last         = 1'b1;


    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                  state_linefill_done <= 1'b1  ;
        else if(mshr_update_en && (need_linefill||need_evict))      state_linefill_done <= 1'b0  ;
        else if(linefill_done )                                     state_linefill_done <= 1'b1  ;//linefill_done means linefill data wrote into ram done
    end   

    //assign linefill_alloc_rdy                = downstream_txreq_vld && downstream_txreq_rdy;
    assign downstream_txreq_vld              = linefill_alloc_vld && (hazard_free && (~state_linefill_sent) && state_evict_dram_clean) ;
    assign downstream_txreq_pld.txnid        = mshr_entry_pld_reg_file.txnid    ;
    //assign downstream_txreq_pld.opcode       = mshr_entry_pld.opcode   ;
    assign downstream_txreq_pld.addr.tag     = mshr_entry_pld_reg_file.req_tag  ;
    assign downstream_txreq_pld.addr.index   = mshr_entry_pld_reg_file.index    ;
    assign downstream_txreq_pld.addr.offset  = mshr_entry_pld_reg_file.offset   ;
    assign downstream_txreq_pld.way          = mshr_entry_pld_reg_file.way      ;
    assign downstream_txreq_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的2bit为block id，再下1bit为ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign downstream_txreq_pld.db_entry_id  = linefill_alloc_idx      ;
    assign downstream_txreq_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx;
    assign downstream_txreq_pld.sideband     = mshr_entry_pld_reg_file.sideband  ;
   


    //read
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_rd_dataram_sent <= 1'b1    ;
        else if(is_read &&((hit && mshr_update_en)|| miss ))                state_rd_dataram_sent <= 1'b0    ;
        //else if(dataram_rd_vld && rd_rdy)                                   state_rd_dataram_sent <= 1'b1    ;
        else if((w_dataram_rd_vld && w_dataram_rd_rdy) |(e_dataram_rd_vld && e_dataram_rd_rdy) | (s_dataram_rd_vld && s_dataram_rd_rdy) | (n_dataram_rd_vld && n_dataram_rd_rdy))state_rd_dataram_sent <= 1'b1;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                          state_rd_dataram_done <= 1'b1    ;
        else if(is_read &&((hit && mshr_update_en)|| miss ))                state_rd_dataram_done <= 1'b0    ;
        //else if(rd_done)                                                    state_rd_dataram_done <= 1'b1    ;
        else if(west_rd_done | east_rd_done | south_rd_done | north_rd_done)state_rd_dataram_done <= 1'b1    ;
    end

    //txnid的高2bit表示方向：00：west；01：east；10：south；11：north
    //assign w_rd_alloc_rdy   = w_dataram_rd_vld && w_dataram_rd_rdy;
    //assign e_rd_alloc_rdy   = w_dataram_rd_vld && e_dataram_rd_rdy;
    //assign s_rd_alloc_rdy   = w_dataram_rd_vld && s_dataram_rd_rdy;
    //assign n_rd_alloc_rdy   = w_dataram_rd_vld && n_dataram_rd_rdy;
    //assign w_dataram_rd_vld = w_rd_alloc_vld && is_read && hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`WEST );
    //assign e_dataram_rd_vld = e_rd_alloc_vld && is_read && hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`EAST );
    //assign s_dataram_rd_vld = s_rd_alloc_vld && is_read && hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`SOUTH);
    //assign n_dataram_rd_vld = n_rd_alloc_vld && is_read && hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`NORTH);
    assign w_dataram_rd_vld = w_rd_alloc_vld &&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`WEST );
    assign e_dataram_rd_vld = e_rd_alloc_vld &&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`EAST );
    assign s_dataram_rd_vld = s_rd_alloc_vld &&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`SOUTH);
    assign n_dataram_rd_vld = n_rd_alloc_vld &&  hazard_free && state_linefill_done && ~state_rd_dataram_sent  && (direc_id==`NORTH);
    assign dataram_rd_vld   = w_dataram_rd_vld | e_dataram_rd_vld | s_dataram_rd_vld | n_dataram_rd_vld;

    assign w_dataram_rd_pld.txnid        = mshr_entry_pld_reg_file.txnid                           ;
    assign w_dataram_rd_pld.opcode       = `READ                                           ; //read opcode ;
    assign w_dataram_rd_pld.way          = mshr_entry_pld_reg_file.way                             ;
    assign w_dataram_rd_pld.index        = mshr_entry_pld_reg_file.index                           ;  
    assign w_dataram_rd_pld.offset       = mshr_entry_pld_reg_file.offset;
    assign w_dataram_rd_pld.tag          = mshr_entry_pld_reg_file.req_tag;
    assign w_dataram_rd_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，也即block，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign w_dataram_rd_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx                       ;
    assign w_dataram_rd_pld.db_entry_id  = w_rd_alloc_idx                                 ;
    assign w_dataram_rd_pld.sideband     = mshr_entry_pld_reg_file.sideband;
    assign w_dataram_rd_pld.last         = 1'b1;

    assign e_dataram_rd_pld.txnid        = mshr_entry_pld_reg_file.txnid                           ;
    assign e_dataram_rd_pld.opcode       = `READ                                           ; //read opcode ;
    assign e_dataram_rd_pld.way          = mshr_entry_pld_reg_file.way                             ;
    assign e_dataram_rd_pld.index        = mshr_entry_pld_reg_file.index                           ;  
    assign e_dataram_rd_pld.offset       = mshr_entry_pld_reg_file.offset;
    assign e_dataram_rd_pld.tag          = mshr_entry_pld_reg_file.req_tag;
    assign e_dataram_rd_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign e_dataram_rd_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx                       ;
    assign e_dataram_rd_pld.db_entry_id  = e_rd_alloc_idx                                 ;
    assign e_dataram_rd_pld.sideband     = mshr_entry_pld_reg_file.sideband;
    assign e_dataram_rd_pld.last         = 1'b1;

    assign s_dataram_rd_pld.txnid        = mshr_entry_pld_reg_file.txnid                           ;
    assign s_dataram_rd_pld.opcode       = `READ                                           ; //read opcode ;
    assign s_dataram_rd_pld.index        = mshr_entry_pld_reg_file.index                           ;
    assign s_dataram_rd_pld.offset       = mshr_entry_pld_reg_file.offset;
    assign s_dataram_rd_pld.tag          = mshr_entry_pld_reg_file.req_tag;
    assign s_dataram_rd_pld.way          = mshr_entry_pld_reg_file.way                             ;
    assign s_dataram_rd_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign s_dataram_rd_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx                       ;
    assign s_dataram_rd_pld.db_entry_id  = n_rd_alloc_idx                                 ;
    assign s_dataram_rd_pld.sideband     = mshr_entry_pld_reg_file.sideband;
    assign s_dataram_rd_pld.last         = 1'b1;

    assign n_dataram_rd_pld.txnid        = mshr_entry_pld_reg_file.txnid                           ;
    assign n_dataram_rd_pld.opcode       = `READ                                           ; //read opcode ;
    assign n_dataram_rd_pld.way          = mshr_entry_pld_reg_file.way                             ;
    assign n_dataram_rd_pld.index        = mshr_entry_pld_reg_file.index                           ;  
    assign n_dataram_rd_pld.offset       = mshr_entry_pld_reg_file.offset;
    assign n_dataram_rd_pld.tag          = mshr_entry_pld_reg_file.req_tag;
    assign n_dataram_rd_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign n_dataram_rd_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx                       ;
    assign n_dataram_rd_pld.db_entry_id  = n_rd_alloc_idx                                 ;
    assign n_dataram_rd_pld.sideband     = mshr_entry_pld_reg_file.sideband;
    assign n_dataram_rd_pld.last         = 1'b1;

    //write
    logic dataram_wr_vld;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                      state_wr_dataram_sent <= 1'b1   ;
        else if(is_write && ((hit && mshr_update_en ) || miss ))        state_wr_dataram_sent <= 1'b0   ;
        //else if(dataram_wr_vld && wr_rdy )                              state_wr_dataram_sent <= 1'b1   ;
        else if((w_dataram_wr_vld && w_dataram_wr_rdy) | (e_dataram_wr_vld && e_dataram_wr_rdy) |(s_dataram_wr_vld && s_dataram_wr_rdy) |(n_dataram_wr_vld && n_dataram_wr_rdy)) state_wr_dataram_sent <= 1'b1;
    end


    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                           state_wr_dataram_done <= 1'b1    ;
        else if(is_write && ((hit && mshr_update_en ) || miss ))             state_wr_dataram_done <= 1'b0    ;
        else if(west_wr_done | east_wr_done | south_wr_done | north_wr_done) state_wr_dataram_done <= 1'b1    ;
    end

    //assign dataram_wr_vld    = is_write && hazard_free && state_linefill_done && ~state_wr_dataram_sent ;
    //txnid的高2bit表示方向：00：west；01：east；10：south；11：north
    assign w_dataram_wr_vld = is_write && hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id==`WEST);
    assign e_dataram_wr_vld = is_write && hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id==`EAST);
    assign s_dataram_wr_vld = is_write && hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id==`SOUTH);
    assign n_dataram_wr_vld = is_write && hazard_free && state_linefill_done && ~state_wr_dataram_sent && (direc_id==`NORTH);
    assign dataram_wr_vld   = w_dataram_wr_vld | e_dataram_wr_vld | s_dataram_wr_vld | n_dataram_wr_vld;

 
    assign dataram_wr_pld.txnid        = mshr_entry_pld_reg_file.txnid    ;
    assign dataram_wr_pld.opcode       = `WRITE                    ; //write opcode ;
    assign dataram_wr_pld.way          = mshr_entry_pld_reg_file.way      ;
    assign dataram_wr_pld.index        = mshr_entry_pld_reg_file.index    ;  
    assign dataram_wr_pld.dest_ram_id  = mshr_entry_pld_reg_file.req_tag[TAG_WIDTH-1:TAG_WIDTH-5];//最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
    assign dataram_wr_pld.rob_entry_id = mshr_entry_pld_reg_file.alloc_idx;
    assign dataram_wr_pld.db_entry_id  = mshr_entry_pld_reg_file.wdb_entry_id;

    //assign release_en = state_rd_dataram_done || state_wr_dataram_done ; //read or write is the end 
    assign release_en = state_rd_dataram_done && state_wr_dataram_done ; //read or write is the end 
    //assign release_en = wr_rdy | rd_rdy；


    
endmodule