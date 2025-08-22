module vec_cache_tag_ctrl
    import vector_cache_pkg::*;
    (
    input  logic                                clk                                   ,
    input  logic                                rst_n                                 ,

    output logic [3:0]                          v_wr_resp_vld_0                       , //双发
    output wr_resp_pld_t                        v_wr_resp_pld_0     [3:0]             , //txnid+sideband
    output logic [3:0]                          v_wr_resp_vld_1                       , //双发
    output wr_resp_pld_t                        v_wr_resp_pld_1     [3:0]             , //txnid+sideband    

    input  logic                                tag_req_vld_0                         ,
    input  logic                                tag_req_vld_1                         ,
    input  input_req_pld_t                      tag_req_pld_0                         ,
    input  input_req_pld_t                      tag_req_pld_1                         ,
    output logic                                tag_req_rdy                           ,//to 8to2 arb
    input  hzd_mshr_pld_t                       v_mshr_entry_pld  [MSHR_ENTRY_NUM-1:0],

    output logic                                mshr_update_en_0                      ,
    output logic                                mshr_update_en_1                      ,
    output mshr_entry_t                         mshr_update_pld_0                     ,
    output mshr_entry_t                         mshr_update_pld_1                     

    );

    logic                                   tag_ram_req_vld_0              ;
    logic                                   tag_ram_req_vld_1              ;
    logic                                   tag_mem_en_0                   ;
    logic                                   tag_mem_en_1                   ;
    tag_ram_t                               tag_ram_din_0                  ;
    tag_ram_t                               tag_ram_dout_0                 ;
    logic                                   tag_ram_wr_en_0                ;
    logic [INDEX_WIDTH-1     :0]            tag_ram_addr_0                 ;
    tag_ram_t                               tag_ram_din_1                  ;
    tag_ram_t                               tag_ram_dout_1                 ;
    logic                                   tag_ram_wr_en_1                ;
    logic [INDEX_WIDTH-1     :0]            tag_ram_addr_1                 ;
    logic                                   tag_ram_rdy                    ;
    
    
    logic [MSHR_ENTRY_NUM-1 :0]             v_hazard_bitmap_0              ;
    logic [MSHR_ENTRY_NUM-1 :0]             v_hazard_bitmap_1              ;
    logic                                   req_vld_0                      ;
    logic                                   req_vld_1                      ;
    input_req_pld_t                         req_pld_0                      ;
    input_req_pld_t                         req_pld_1                      ;
    logic                                   wr_tag_buf_vld_0               ;
    logic                                   wr_tag_buf_vld_1               ;
    wr_buf_pld_t                            wr_tag_buf_pld_0               ;
    wr_buf_pld_t                            wr_tag_buf_pld_1               ;
    logic                                   wr_buf_vld                     ;

    logic [WAY_NUM-1        :0]             dirty_0                        ;
    logic [WAY_NUM-1        :0]             dirty_1                        ;
    logic [WAY_NUM-1        :0]             tag_ram_hit_way_oh_0           ;
    logic [WAY_NUM-1        :0]             hit_way_oh_0                   ;
    logic [WAY_NUM-1        :0]             evict_way_oh_0                 ;
    logic [$clog2(WAY_NUM)-1:0]             hit_way_0                      ;
    logic [WAY_NUM-1        :0]             tag_ram_hit_way_oh_1           ;
    logic [WAY_NUM-1        :0]             hit_way_oh_1                   ;
    logic [WAY_NUM-1        :0]             evict_way_oh_1                 ;
    logic [$clog2(WAY_NUM)-1:0]             hit_way_1                      ;
    logic [WAY_NUM-1        :0]             dest_way_oh_0                  ;
    logic [WAY_NUM-1        :0]             dest_way_oh_1                  ;
    logic [TAG_WIDTH-1      :0]             evict_tag_0                    ;
    logic [TAG_WIDTH-1      :0]             evict_tag_1                    ;
    logic [$clog2(WAY_NUM)-1:0]             evict_way_0                    ;
    logic [$clog2(WAY_NUM)-1:0]             evict_way_1                    ;
    logic [WAY_NUM-1        :0]             weight_oh                      ;
    logic [$clog2(WAY_NUM)-1:0]             weight                         ;
    logic                                   wr_tag_buf_hit_0               ;
    logic                                   wr_tag_buf_hit_1               ;
    logic                                   tag_ram_hit_0                  ;
    logic                                   tag_ram_hit_1                  ;
    logic                                   hit_0                          ;
    logic                                   hit_1                          ;
    logic                                   miss_0                         ;
    logic                                   miss_1                         ;
    logic [WAY_NUM-1        :0]             wr_tag_buf_way_oh_0            ;
    logic [WAY_NUM-1        :0]             wr_tag_buf_way_oh_1            ;

    logic                                   wr_tag_buf_update_en_0         ;
    logic                                   wr_tag_buf_update_en_1         ;
    logic                                   wr_tag_buf_rdy_0               ;
    logic                                   wr_tag_buf_rdy_1               ;

    logic                                   set_dirty_0                    ;
    logic                                   set_dirty_1                    ;
    logic                                   clr_dirty_0                    ;
    logic                                   clr_dirty_1                    ;
    logic                                   tag_dirty_wr_en_0              ;
    logic                                   tag_dirty_wr_en_1              ;
    logic [INDEX_WIDTH-1    :0]             tag_dirty_wr_addr_0            ;
    logic [INDEX_WIDTH-1    :0]             tag_dirty_wr_addr_1            ;
    logic [WAY_NUM-1        :0]             tag_dirty_in_0                 ;
    logic [WAY_NUM-1        :0]             tag_dirty_in_1                 ;

//================================================================
//        tag_ram access arbiter(wr_buf & tag_req)
//================================================================
    typedef struct packed {
        logic [INDEX_WIDTH-1:0] addr   ;
        tag_t                   data_in;
    } tag_ram_req_t;
    tag_ram_req_t tag_ram_req_pld_0;
    tag_ram_req_t tag_ram_req_pld_1;

    //assign wr_buf_vld                = wr_tag_buf_vld_0 | wr_tag_buf_vld_1;
    assign wr_tag_buf_rdy_0          = wr_tag_buf_vld_0                      ;
    assign wr_tag_buf_rdy_1          = ~wr_tag_buf_vld_0 && wr_tag_buf_vld_1 ;
    assign tag_req_rdy               = ~(wr_tag_buf_vld_0 | wr_tag_buf_vld_1);
    assign tag_ram_req_vld_0         = wr_tag_buf_vld_0 | wr_tag_buf_vld_1 | tag_req_vld_0;
    assign tag_ram_req_vld_1         = wr_tag_buf_vld_0 | wr_tag_buf_vld_1 | tag_req_vld_1;
    assign tag_ram_req_pld_0.addr    = wr_tag_buf_vld_0 ? wr_tag_buf_pld_0.index :
                                       wr_tag_buf_vld_1 ? wr_tag_buf_pld_1.index : tag_req_pld_0.cmd_addr.index;

    assign tag_ram_req_pld_0.data_in = wr_tag_buf_vld_0 ? {wr_tag_buf_pld_0.tag,1'b1} : {wr_tag_buf_pld_1,1'b1};

    assign tag_ram_req_pld_1.addr    = wr_tag_buf_vld_0 ? wr_tag_buf_pld_0.index :
                                       wr_tag_buf_vld_1 ? wr_tag_buf_pld_1.index : tag_req_pld_0.cmd_addr.index;

    assign tag_ram_req_pld_1.data_in = wr_tag_buf_vld_0 ? {wr_tag_buf_pld_0.tag,1'b1} : {wr_tag_buf_pld_1,1'b1};
    

//========================================================
//        tag  ram
//========================================================
    assign tag_mem_en_0    = tag_ram_req_vld_0;
    assign tag_mem_en_1    = tag_ram_req_vld_1;

    assign tag_ram_wr_en_0 = wr_tag_buf_vld_0 | wr_tag_buf_vld_1;
    assign tag_ram_wr_en_1 = wr_tag_buf_vld_0 | wr_tag_buf_vld_1;

    assign tag_ram_addr_0  = tag_ram_req_pld_0.addr;
    assign tag_ram_addr_1  = tag_ram_req_pld_1.addr;

    assign tag_ram_din_0   = tag_ram_req_pld_0.data_in;
    assign tag_ram_din_1   = tag_ram_req_pld_1.data_in;

    toy_mem_model_bit #(
        .ADDR_WIDTH  (INDEX_WIDTH  ),
        .DATA_WIDTH  (($bits(tag_ram_t)))) 
    u_tag_ramA (
        .clk    (clk                ),
        .en     (tag_mem_en_0       ),
        .wr_en  (tag_ram_wr_en_0    ),
        .addr   (tag_ram_addr_0     ),
        .wr_data(tag_ram_din_0      ),
        .rd_data(tag_ram_dout_0     ));
    toy_mem_model_bit #(
        .ADDR_WIDTH  (INDEX_WIDTH),
        .DATA_WIDTH  (($bits(tag_ram_t)))) 
    u_tag_ramB (
        .clk    (clk                ),
        .en     (tag_mem_en_1       ),
        .wr_en  (tag_ram_wr_en_1    ),
        .addr   (tag_ram_addr_1     ),
        .wr_data(tag_ram_din_1      ),
        .rd_data(tag_ram_dout_1     ));    
//================================================================
//        wr tag buffer （miss need to update wr_tag_buf）
//================================================================
    assign wr_tag_bu_update_enf_0 = miss_0 && req_vld_0                   ;
    assign wr_tag_buf_update_en_1 = miss_1 && req_vld_0                   ;
    
    vec_cache_wr_tag_buf u_wr_tag_buf_0 ( 
        .clk           (clk                     ),
        .rst_n         (rst_n                   ),
        .buf_update_en (wr_tag_buf_update_en_0  ),
        .req_pld       (req_pld_0               ),
        .evict_way     (evict_way_0             ),
        .tag_buf_rdy   (wr_tag_buf_rdy_0        ),
        .tag_buf_vld   (wr_tag_buf_vld_0        ),
        .tag_buf_pld   (wr_tag_buf_pld_0        ));

    vec_cache_wr_tag_buf u_wr_tag_buf_1 ( 
        .clk           (clk                     ),
        .rst_n         (rst_n                   ),
        .buf_update_en (wr_tag_buf_update_en_1  ),
        .req_pld       (req_pld_1               ),
        .evict_way     (evict_way_1             ),
        .tag_buf_rdy   (wr_tag_buf_rdy_1        ),
        .tag_buf_vld   (wr_tag_buf_vld_1        ),
        .tag_buf_pld   (wr_tag_buf_pld_1        ));

//================================================================
//        tag req pld buffer 
//================================================================
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            req_vld_0  <= 1'b0;
            req_vld_1  <= 1'b0;
        end
        else begin
            req_vld_0 <= tag_req_vld_0 && tag_req_rdy;
            req_vld_1 <= tag_req_vld_1 && tag_req_rdy;
        end
    end
 
    always_ff@(posedge clk )begin
        req_pld_0 <= tag_req_pld_0;
        req_pld_1 <= tag_req_pld_1;
    end


//========================================================
//        dirty ram 
//========================================================
    assign set_dirty_0         = req_vld_0 && (req_pld_0.cmd_opcode==`VEC_CACHE_CMD_WRITE); //write
    assign set_dirty_1         = req_vld_1 && (req_pld_1.cmd_opcode==`VEC_CACHE_CMD_WRITE); //write
    assign clr_dirty_0         = req_vld_0 && miss_0 && (req_pld_0.cmd_opcode==`VEC_CACHE_CMD_READ);//read_miss
    assign clr_dirty_1         = req_vld_1 && miss_1 && (req_pld_1.cmd_opcode==`VEC_CACHE_CMD_READ);

    assign tag_dirty_wr_en_0   = set_dirty_0 | clr_dirty_0 ;
    assign tag_dirty_wr_en_1   = set_dirty_1 | clr_dirty_1 ;

    assign tag_dirty_wr_addr_0 = req_pld_0.cmd_addr.index  ;
    assign tag_dirty_wr_addr_1 = req_pld_1.cmd_addr.index  ;

    assign tag_dirty_in_0      = dest_way_oh_0             ;
    assign tag_dirty_in_1      = dest_way_oh_1             ;
    
    vec_cache_tag_dirty_array  #( 
        .ADDR_WIDTH(INDEX_WIDTH),
        .DATA_WIDTH(WAY_NUM))
    u_tag_dirty_array ( 
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .addr_0     (tag_dirty_wr_addr_0),
        .addr_1     (tag_dirty_wr_addr_1),
        .wr_en_0    (tag_dirty_wr_en_0  ),
        .wr_en_1    (tag_dirty_wr_en_1  ),
        .wr_data_0  (tag_dirty_in_0     ),
        .wr_data_1  (tag_dirty_in_1     ),
        .rd_data_0  (dirty_0            ),
        .rd_data_1  (dirty_1            ));

//==========================================================================
//        hit/miss check
//==========================================================================
    //----------------------------------------------------------
    //         lru update 
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)    weight<= 'b0;
        else          weight <= weight+ 1'b1;
    end
    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM        )) 
    u_weight_oh (
        .bin_in    (weight     ),
        .onehot_out(weight_oh  ));
    assign evict_way_0    = weight;
    assign evict_way_1    = weight;

    cmn_bin2onehot #(
        .ONEHOT_WIDTH(WAY_NUM           ),
        .BIN_WIDTH   ($clog2(WAY_NUM)   )) 
    u_bin2onehot_0 (
        .bin_in    (wr_tag_buf_pld_0.way),
        .onehot_out(wr_tag_buf_way_oh_0 ));

    cmn_bin2onehot #(
        .ONEHOT_WIDTH(WAY_NUM           ),
        .BIN_WIDTH   ($clog2(WAY_NUM)   ))
     u_bin2onehot_1 (
        .bin_in    (wr_tag_buf_pld_1.way),
        .onehot_out(wr_tag_buf_way_oh_1 ));
    
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_hit_way_oh_0[i] = tag_ram_dout_0.tag_array[i].valid && (req_pld_0.cmd_addr.tag == tag_ram_dout_0.tag_array[i].tag);
        end
    endgenerate
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_hit_way_oh_1[i] = tag_ram_dout_1.tag_array[i].valid && (req_pld_1.cmd_addr.tag == tag_ram_dout_1.tag_array[i].tag);
        end
    endgenerate
    
    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WAY_NUM   )) 
    u_hit_way_oh2bin_0 (
        .onehot_in (hit_way_oh_0),
        .bin_out   (hit_way_0   ));
    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WAY_NUM)
    ) u_hit_way_oh2bin_1 (
        .onehot_in (hit_way_oh_1),
        .bin_out   (hit_way_1   )
    );
    
    assign wr_tag_buf_hit_0 = req_vld_0 && (((req_pld_0.cmd_addr.tag==wr_tag_buf_pld_0.tag)&&(req_pld_0.cmd_addr.index== wr_tag_buf_pld_0.index)) || ((req_pld_0.cmd_addr.tag==wr_tag_buf_pld_1.tag)&&(req_pld_0.cmd_addr.index== wr_tag_buf_pld_1.index)));
    assign wr_tag_buf_hit_1 = req_vld_1 && (((req_pld_1.cmd_addr.tag==wr_tag_buf_pld_0.tag)&&(req_pld_1.cmd_addr.index== wr_tag_buf_pld_0.index)) || ((req_pld_1.cmd_addr.tag==wr_tag_buf_pld_1.tag)&&(req_pld_1.cmd_addr.index== wr_tag_buf_pld_1.index)));
    
    assign hit_way_oh_0 = wr_tag_buf_hit_0 ? wr_tag_buf_way_oh_0 : tag_ram_hit_way_oh_0;//hit ram or hit wr_tag_buf
    assign hit_way_oh_1 = wr_tag_buf_hit_1 ? wr_tag_buf_way_oh_1 : tag_ram_hit_way_oh_1;

    assign tag_ram_hit_0 = |tag_ram_hit_way_oh_0;
    assign tag_ram_hit_1 = |tag_ram_hit_way_oh_1;

    assign hit_0  = tag_ram_hit_0 || wr_tag_buf_hit_0;
    assign hit_1  = tag_ram_hit_1 || wr_tag_buf_hit_1;
    assign miss_0 = ~hit_0;
    assign miss_1 = ~hit_1;
    assign evict_way_oh_0 = weight_oh; 
    assign evict_way_oh_1 = weight_oh; 
    assign dest_way_oh_0 = hit_0 ? hit_way_oh_0 : evict_way_oh_0;
    assign dest_way_oh_1 = hit_1 ? hit_way_oh_1 : evict_way_oh_1;

    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            if(dest_way_oh_0[i]==1'b1)begin
                evict_tag_0 = tag_ram_dout_0.tag_array[i].tag;
            end
        end
    end
    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            if(dest_way_oh_1[i]==1'b1)begin
                evict_tag_1 = tag_ram_dout_1.tag_array[i].tag;
            end
        end
    end 

//================================================================================
//         hazard check and behavior mapping (address hazard check)
//================================================================================
    assign mshr_update_en_0 = req_vld_0;
    assign mshr_update_en_1 = req_vld_1;   

    generate
        for(genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin
            assign v_hazard_bitmap_0[i] = mshr_update_en_0 && v_mshr_entry_pld[i].valid && ~v_mshr_entry_pld[i].release_bit 
                                        && (req_pld_0.cmd_addr.index==v_mshr_entry_pld[i].index)
                                        && ((req_pld_0.cmd_addr.tag==v_mshr_entry_pld[i].tag) || (req_pld_0.cmd_addr.tag==v_mshr_entry_pld[i].evict_tag));

            assign v_hazard_bitmap_1[i] = mshr_update_en_1 && v_mshr_entry_pld[i].valid && ~v_mshr_entry_pld[i].release_bit 
                                        && (req_pld_1.cmd_addr.index==v_mshr_entry_pld[i].index)
                                        && ((req_pld_1.cmd_addr.tag==v_mshr_entry_pld[i].tag) || (req_pld_1.cmd_addr.tag==v_mshr_entry_pld[i].evict_tag));   
        end
    endgenerate

    //mshr_entry pld
    assign mshr_update_pld_0.txnid         = req_pld_0.cmd_txnid                                                                                    ;
    assign mshr_update_pld_0.opcode        = req_pld_0.cmd_opcode;
    assign mshr_update_pld_0.hash_id       = req_pld_0.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1]                                                        ;
    assign mshr_update_pld_0.dest_ram_id   = {req_pld_0.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1],req_pld_0.cmd_addr.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
    assign mshr_update_pld_0.sideband      = req_pld_0.cmd_sideband                                                                                 ;
    assign mshr_update_pld_0.index         = req_pld_0.cmd_addr.index                                                                               ;
    assign mshr_update_pld_0.offset        = req_pld_0.cmd_addr.offset                                                                              ;
    assign mshr_update_pld_0.req_tag       = req_pld_0.cmd_addr.tag                                                                                 ;
    assign mshr_update_pld_0.way           = hit_0 ? hit_way_0 : evict_way_0                                                                        ;
    assign mshr_update_pld_0.is_read       = req_vld_0 && (req_pld_0.cmd_opcode== `VEC_CACHE_CMD_READ )                                             ;
    assign mshr_update_pld_0.is_write      = req_vld_0 && (req_pld_0.cmd_opcode== `VEC_CACHE_CMD_WRITE)                                             ;
    assign mshr_update_pld_0.hit           = hit_0                                                                                                  ;
    assign mshr_update_pld_0.need_linefill = miss_0 && req_vld_0                                                                                    ;
    assign mshr_update_pld_0.need_evict    = dirty_0[evict_way_0] && miss_0 && tag_ram_dout_0.tag_array[evict_way_0].valid                          ;
    assign mshr_update_pld_0.evict_tag     = evict_tag_0                                                                                            ;
    assign mshr_update_pld_0.hzd_bitmap    = v_hazard_bitmap_0                                                                                      ;
    assign mshr_update_pld_0.release_bitmap= 'b0                                                                                                    ;
    assign mshr_update_pld_0.hzd_pass      = ((|v_hazard_bitmap_0)==1'b0)                                                                           ;
    assign mshr_update_pld_0.alloc_idx     = req_pld_0.rob_entry_id                                                                                 ; 
    assign mshr_update_pld_0.wdb_entry_id  = req_pld_0.db_entry_id                                                                                  ;//只有write在输入带

    assign mshr_update_pld_1.txnid         = req_pld_1.cmd_txnid                                                                                    ;
    assign mshr_update_pld_1.opcode        = req_pld_1.cmd_opcode;
    assign mshr_update_pld_1.hash_id       = req_pld_1.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1]                                                        ;
    assign mshr_update_pld_1.dest_ram_id   = {req_pld_1.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1],req_pld_1.cmd_addr.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
    assign mshr_update_pld_1.sideband      = req_pld_1.cmd_sideband                                                                                 ;
    assign mshr_update_pld_1.index         = req_pld_1.cmd_addr.index                                                                               ;
    assign mshr_update_pld_1.offset        = req_pld_1.cmd_addr.offset                                                                              ;
    assign mshr_update_pld_1.req_tag       = req_pld_1.cmd_addr.tag                                                                                 ;
    assign mshr_update_pld_1.way           = hit_1 ? hit_way_1 : evict_way_1                                                                        ;
    assign mshr_update_pld_1.is_read       = req_vld_1 && (req_pld_1.cmd_opcode== `VEC_CACHE_CMD_READ )                                             ;
    assign mshr_update_pld_1.is_write      = req_vld_1 && (req_pld_1.cmd_opcode== `VEC_CACHE_CMD_WRITE)                                             ;
    assign mshr_update_pld_1.hit           = hit_1                                                                                                  ;
    assign mshr_update_pld_1.need_linefill = miss_1 && req_vld_1                                                                                    ;
    assign mshr_update_pld_1.need_evict    = dirty_1[evict_way_1] && miss_1 && tag_ram_dout_1.tag_array[evict_way_1].valid                          ;
    assign mshr_update_pld_1.evict_tag     = evict_tag_1                                                                                            ;
    assign mshr_update_pld_1.hzd_bitmap    = v_hazard_bitmap_1                                                                                      ;
    assign mshr_update_pld_1.release_bitmap= 'b0                                                                                                    ;
    assign mshr_update_pld_1.hzd_pass      = ((|v_hazard_bitmap_1)==1'b0)                                                                           ;
    assign mshr_update_pld_1.alloc_idx     = req_pld_1.rob_entry_id                                                                                 ;
    assign mshr_update_pld_1.wdb_entry_id  = req_pld_1.db_entry_id                                                                                  ;

//===============================================================
//          wresp decode to direction
//===============================================================
    vec_cache_wr_resp_direction_decode #(
        .WIDTH(4)) 
    u_wresp_decode_0(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (tag_req_vld_0               ),
        .req_pld    (tag_req_pld_0               ),
        .v_wresp_vld(v_wr_resp_vld_0             ),
        .v_wresp_pld(v_wr_resp_pld_0             ));

    vec_cache_wr_resp_direction_decode #(
        .WIDTH(4)) 
    u_wresp_decode_1(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (tag_req_vld_1               ),
        .req_pld    (tag_req_pld_1               ),
        .v_wresp_vld(v_wr_resp_vld_1             ),
        .v_wresp_pld(v_wr_resp_pld_1             ));


endmodule

