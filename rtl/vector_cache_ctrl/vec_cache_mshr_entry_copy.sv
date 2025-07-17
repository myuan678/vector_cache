// linefill（txreq) && evict 可以并行的版本
module vec_cache_mshr_entry
    import vector_cache_pkg::*; 
    (
    input  logic                               clk                        ,
    input  logic                               rst_n                      , 
    input  logic                               mshr_update_en             ,
    input  mshr_entry_t                          mshr_entry_pld             ,
    //input  logic                               hzd_checkpass              ,
    output logic                               entry_active               ,

    output logic                               alloc_vld                  ,
    input  logic                               alloc_rdy                  ,

    input  logic                               rd_rdy                     ,
    output logic                               dataram_rd_vld             ,
    output rd_pld_t                            dataram_rd_pld             ,

    input  logic                               wr_rdy                     ,
    output logic                               dataram_wr_vld             ,
    output wr_pld_nd_t                         dataram_wr_pld             ,

    input  logic                               evict_rdy                  ,
    output logic                               evict_rd_vld               ,
    output evict_pld_t                         evict_rd_pld               ,

    output logic                               downstream_txreq_vld       ,
    input  logic                               downstream_txreq_rdy       ,
    output downstream_txreq_t                  downstream_txreq_pld       ,

    output logic                               linefill_req_vld           ,
    input  logic                               linefill_req_rdy           ,
    output linefill_req_t                      linefill_req_pld           ,

    input  logic                               linefill_data_done          ,
    //input  logic                               linefill_done              ,
    input  logic [MSHR_ENTRY_NUM-1 :0]         v_release_en               ,
    output logic                               release_en                 ,

    input  logic                               evict_clean                ,
    input  logic                               evict_done                 ,
    input  logic                               rd_done                    ,
    input  logic                               wr_done                    ,

    output logic                               wr_data_buf_rd_en          ,
    output logic                               wr_data_buf_rd_addr

);
    logic                      entry_valid             ;
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
    logic                      state_evict_sent        ;
    logic                      state_evict_dram_clean  ;
    logic                      state_evict_to_ds_done  ;
    logic                      state_linefill_sent     ;
    logic                      state_ds_to_lfdb        ;
    logic                      state_linefill_done     ;
    logic                      state_rd_dataram_sent   ;
    logic                      state_rd_dataram_done   ;
    logic                      state_wr_dataram_sent   ;
    logic                      state_wr_dataram_done   ;
    logic                      hzd_checkpass           ;
    assign hzd_checkpass = mshr_entry_pld.hzd_pass;
    assign entry_active  = mshr_entry_pld.valid   ;
    assign alloc_vld     = ~entry_valid           ;
    assign allocate_en   = mshr_update_en         ;
    assign entry_valid   = mshr_entry_pld.valid   ;
    
//========================================================
// hazard_checking WAIT_dependency
//========================================================
    logic [MSHR_ENTRY_NUM-1 :0] v_hzd_bitmap;
    assign v_hzd_bitmap = mshr_entry_pld.pld.hzd_bitmap;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)              v_keep_hzd_bitmap <= 'b0;
        else if(mshr_update_en) v_keep_hzd_bitmap <= v_hzd_bitmap;
        else                    v_keep_hzd_bitmap <= v_keep_hzd_bitmap & (~v_release_en);
    end
    assign hzd_release = ((|v_keep_hzd_bitmap)==1'b0);

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)        hazard_free <= 1'b0;
        else              hazard_free <= (hzd_checkpass && mshr_update_en) || ( hzd_release && entry_valid);
    end

//========================================================
// entry 
//1: read dataram
//2：evict && linefill
        //write evict
        //read evict
//3：linefill
//4：read wrdata buffer 然后write dataram
//========================================================
    // evict 
    assign need_linefill = mshr_entry_pld.need_linefill ;
    assign need_evict    = mshr_entry_pld.need_evict    ;
    assign hit           = mshr_entry_pld.hit;
    assign miss          = ~hit;
    assign is_read       = mshr_entry_pld.is_read;
    assign is_write      =  mshr_entry_pld.is_write; 

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                state_evict_sent <= 1'b1            ;
        else if(mshr_update_en && need_evict)     state_evict_sent <= 1'b0            ;
        else if(evict_rd_vld && evict_rdy)        state_evict_sent <= 1'b1            ;
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                state_evict_dram_clean <= 1'b1      ;
        else if(mshr_update_en && need_evict)     state_evict_dram_clean <= 1'b0      ;
        else if(evict_clean)                      state_evict_dram_clean <= 1'b1      ;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                state_evict_to_ds_done <= 1'b1            ;
        else if(mshr_update_en && need_evict)     state_evict_to_ds_done <= 1'b0            ;
        else if(evict_done)                       state_evict_to_ds_done <= 1'b1            ;
    end

    assign evict_rd_vld           = hazard_free && ~state_evict_sent;//evict is a read, readout data, write into Evict data buffer
    assign evict_rd_pld.way       = mshr_entry_pld.dest_way         ;
    assign evict_rd_pld.index     = mshr_entry_pld.index            ;
    assign evict_rd_pld.txnid     = mshr_entry_pld.txnid            ;
    assign evict_rd_pld.entry_idx = mshr_entry_pld.alloc_idx        ;
    //assign evict_rd_pld.last      = ;


    // linefill 
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                          state_linefill_sent <= 1'b1;
        else if(mshr_update_en && (need_linefill||need_evict))              state_linefill_sent <= 1'b0;
        else if(downstream_txreq_vld && downstream_txreq_rdy)               state_linefill_sent <= 1'b1;
    end
    
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                          state_ds_to_lfdb<= 1'b1; 
        else if(mshr_update_en && (need_linefill||need_evict))              state_ds_to_lfdb<= 1'b0;
        else if(linefill_data_done)                                         state_ds_to_lfdb<= 1'b1;//获取到linefill_data
    end

    assign linefill_req_vld           = state_ds_to_lfdb && state_evict_dram_clean && ~state_linefill_done;//需要发4个，offset+1作为下一个地址
    assign linefill_req_pld.index     = mshr_entry_pld.index    ;
    assign linefill_req_pld.way       = mshr_entry_pld.way      ;
    assign linefill_req_pld.txnid     = mshr_entry_pld.txnid    ;
    assign linefill_req_pld.opcode    = mshr_entry_pld.opcode   ;
    assign linefill_req_pld.last      = 1'b0;
    assign linefill_req_pld.entry_idx = mshr_entry_pld.alloc_idx;
    //
    //assign linefill_req_vld        = state_ds_to_lfdb && state_evict_dram_clean;//需要发4个，offset+1作为下一个地址
    //assign linefill_req_pld.index  = mshr_entry_pld.index    ;
    //assign linefill_req_pld.way    = mshr_entry_pld.way      ;
    //assign linefill_req_pld.last   = 1'b0;

    assign linefill_done = linefill_req_vld && linefill_req_rdy;

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                  state_linefill_done <= 1'b1  ;
        else if(mshr_update_en && (need_linefill||need_evict))      state_linefill_done <= 1'b0  ;
        else if(linefill_done )                                     state_linefill_done <= 1'b1  ;//linefill_done means linefill data wrote into ram done
        //else if(linefill_done && state_evict_dram_clean )                   state_linefill_done <= 1'b1  ;//TODO
    end   

    //assign downstream_txreq_vld     = (hazard_free && (~state_linefill_sent) && state_evict_dram_clean) ;
    assign downstream_txreq_vld             = (hazard_free && ~state_linefill_sent);
    assign downstream_txreq_pld.addr.tag    = mshr_entry_pld.tag      ;
    assign downstream_txreq_pld.addr.index  = mshr_entry_pld.index    ;
    assign downstream_txreq_pld.addr.offset = mshr_entry_pld.offset   ;
    assign downstream_txreq_pld.txnid       = mshr_entry_pld.txnid    ;
    assign downstream_txreq_pld.opcode      = mshr_entry_pld.opcode   ;
    assign downstream_txreq_pld.entry_idx   = mshr_entry_pld.alloc_idx;


    //read
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)                                                                  state_rd_dataram_sent <= 1'b1    ;
        //else if(is_read &&((hit && mshr_update_en)||( miss && state_linefill_done)))state_rd_dataram_sent <= 1'b0    ;
        else if(is_read &&((hit && mshr_update_en)|| miss ))state_rd_dataram_sent <= 1'b0    ;
        else if(dataram_rd_vld && rd_rdy)                                           state_rd_dataram_sent <= 1'b1    ;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                                  state_rd_dataram_done <= 1'b1    ;
        //else if(is_read &&((hit && mshr_update_en)||( miss && state_linefill_done)))state_rd_dataram_done <= 1'b0    ;
        else if(is_read &&((hit && mshr_update_en)|| miss ))  state_rd_dataram_done <= 1'b0    ;
        else if(rd_done)                                                            state_rd_dataram_done <= 1'b1    ;
    end
    assign dataram_rd_vld           = is_read && hazard_free && state_linefill_done && ~state_rd_dataram_sent ;
    assign dataram_rd_pld.way       = mshr_entry_pld.dest_way ;
    assign dataram_rd_pld.index     = mshr_entry_pld.index    ;  
    assign dataram_rd_pld.txnid     = mshr_entry_pld.txnid    ;
    assign dataram_rd_pld.opcode    = mshr_entry_pld.opcode   ;
    assign dataram_rd_pld.entry_idx = mshr_entry_pld.alloc_idx;

    //write

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                      state_wr_dataram_sent <= 1'b1   ;
        else if(is_write && ((hit && mshr_update_en ) || miss ))        state_wr_dataram_sent <= 1'b0   ;
        else if(dataram_wr_vld && wr_rdy )                              state_wr_dataram_sent <= 1'b1   ;
    end


    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                                      state_wr_dataram_done <= 1'b1    ;
        else if(is_write && ((hit && mshr_update_en ) || miss ))        state_wr_dataram_done <= 1'b0    ;
        else if(wr_done )                                               state_wr_dataram_done <= 1'b1    ;
    end

    assign dataram_wr_tmp_vld = is_write && hazard_free && state_linefill_done && ~state_wr_dataram_sent ;
    assign wr_data_buf_en     = dataram_wr_tmp_vld;
    assign dataram_wr_vld     = dataram_wr_tmp_vld && wr_data_vld;
    //assign dataram_wr_vld     = dataram_wr_tmp_vld && state_wr_data_ok;
 
    assign dataram_wr_pld.way    = mshr_entry_pld.dest_way ;
    assign dataram_wr_pld.index  = mshr_entry_pld.index    ;  
    assign dataram_wr_pld.txnid  = mshr_entry_pld.txnid    ;
    assign dataram_wr_pld.opcode = mshr_entry_pld.opcode   ;
    assign dataram_wr_pld.entry_idx =  mshr_entry_pld.alloc_idx;

    //assign wr_data_buf_rd_en   = wr_grant && wr_data_rdy;
    //assign wr_data_buf_rd_addr = mshr_entry_pld.pld.addr;

    assign release_en = state_rd_dataram_done || state_wr_dataram_done ; //read or write is the end 

    
    

//========================================================
// write dataram   linefill data  process in dataram_ctrl
//========================================================

    
endmodule