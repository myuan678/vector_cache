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
    logic [TAG_WIDTH-1      :0]             tag_array_0 [WAY_NUM-1:0]      ;
    logic [TAG_WIDTH-1      :0]             tag_array_1 [WAY_NUM-1:0]      ;

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
    logic [$clog2(WAY_NUM)-1:0]             dest_way_0                     ;
    logic [$clog2(WAY_NUM)-1:0]             dest_way_1                     ;
    logic [TAG_WIDTH-1      :0]             evict_tag_0                    ;
    logic [TAG_WIDTH-1      :0]             evict_tag_1                    ;
    logic [$clog2(WAY_NUM)-1:0]             evict_way_0                    ;
    logic [$clog2(WAY_NUM)-1:0]             evict_way_1                    ;
    //logic [WAY_NUM-1        :0]             weight_oh                      ;
    //logic [$clog2(WAY_NUM)-1:0]             weight                         ;
    logic [$clog2(WAY_NUM)-1:0]             replace_way_0                  ;
    logic [$clog2(WAY_NUM)-1:0]             replace_way_1                  ;
    logic [WAY_NUM-1        :0]             replace_way_oh_0               ;
    logic [WAY_NUM-1        :0]             replace_way_oh_1               ;
    logic                                   replace_vld_0                  ;
    logic                                   replace_vld_1                  ;
    logic                                   req0_hit_wr_tag_buf_0          ;
    logic                                   req0_hit_wr_tag_buf_1          ;
    logic                                   req1_hit_wr_tag_buf_0          ;
    logic                                   req1_hit_wr_tag_buf_1          ;
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
    logic [WAY_NUM-1        :0]             tag_dirty_bit_wr_en_0          ;
    logic [WAY_NUM-1        :0]             tag_dirty_bit_wr_en_1          ;
    logic                                   tag_dirty_in_0                 ;
    logic                                   tag_dirty_in_1                 ;
    logic [INDEX_WIDTH-1    :0]             wr_tag_buf_index_0             ;
    logic [TAG_WIDTH-1      :0]             wr_tag_buf_tag_0               ; 
    logic [INDEX_WIDTH-1    :0]             wr_tag_buf_index_1             ;
    logic [TAG_WIDTH-1      :0]             wr_tag_buf_tag_1               ;    

//================================================================
//        tag_ram access arbiter(wr_buf & tag_req)
//================================================================
    typedef struct packed {
        logic [INDEX_WIDTH-1:0] addr   ;
        tag_t                   data_in;
    } tag_ram_req_t;
    tag_ram_req_t tag_ram_req_pld_0;
    tag_ram_req_t tag_ram_req_pld_1;

    assign wr_tag_buf_rdy_0          = wr_tag_buf_vld_0                                     ;
    assign wr_tag_buf_rdy_1          = ~wr_tag_buf_vld_0 && wr_tag_buf_vld_1                ;
    assign tag_req_rdy               = ~(wr_tag_buf_vld_0 | wr_tag_buf_vld_1)               ;
    assign tag_ram_req_vld_0         = wr_tag_buf_vld_0 | wr_tag_buf_vld_1 | tag_req_vld_0  ;
    assign tag_ram_req_vld_1         = wr_tag_buf_vld_0 | wr_tag_buf_vld_1 | tag_req_vld_1  ;
    assign tag_ram_req_pld_0.addr    = wr_tag_buf_vld_0 ? wr_tag_buf_pld_0.index :
                                       wr_tag_buf_vld_1 ? wr_tag_buf_pld_1.index : tag_req_pld_0.addr.index;

    assign tag_ram_req_pld_0.data_in = wr_tag_buf_vld_0 ? {wr_tag_buf_pld_0.tag,1'b1} : {wr_tag_buf_pld_1,1'b1};

    assign tag_ram_req_pld_1.addr    = wr_tag_buf_vld_0 ? wr_tag_buf_pld_0.index :
                                       wr_tag_buf_vld_1 ? wr_tag_buf_pld_1.index : tag_req_pld_0.addr.index;

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
    assign wr_tag_buf_update_en_0 = miss_0 && req_vld_0  ;
    assign wr_tag_buf_update_en_1 = miss_1 && req_vld_1  ;
    assign wr_tag_buf_index_0     = req_pld_0.addr.index ;
    assign wr_tag_buf_tag_0       = req_pld_0.addr.tag   ;
    assign wr_tag_buf_index_1     = req_pld_1.addr.index ;
    assign wr_tag_buf_tag_1       = req_pld_1.addr.tag   ;
    
    vec_cache_wr_tag_buf u_wr_tag_buf_0 ( 
        .clk           (clk                     ),
        .rst_n         (rst_n                   ),
        .buf_update_en (wr_tag_buf_update_en_0  ),
        .tag           (wr_tag_buf_tag_0        ),
        .index         (wr_tag_buf_index_0      ),
        .evict_way_oh  (evict_way_oh_0          ),
        .tag_buf_rdy   (wr_tag_buf_rdy_0        ),
        .tag_buf_vld   (wr_tag_buf_vld_0        ),
        .tag_buf_pld   (wr_tag_buf_pld_0        ));

    vec_cache_wr_tag_buf u_wr_tag_buf_1 ( 
        .clk           (clk                     ),
        .rst_n         (rst_n                   ),
        .buf_update_en (wr_tag_buf_update_en_1  ),
        .tag           (wr_tag_buf_tag_1        ),
        .index         (wr_tag_buf_index_1      ),
        .evict_way_oh  (evict_way_oh_1          ),
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
        if(tag_req_vld_0 && tag_req_rdy)    req_pld_0 <= tag_req_pld_0;
    end
    always_ff@(posedge clk )begin
        if(tag_req_vld_1 && tag_req_rdy)    req_pld_1 <= tag_req_pld_1;
    end


//========================================================
//        dirty ram 
//========================================================
    assign set_dirty_0         = req_vld_0 && (req_pld_0.opcode==`VEC_CACHE_CMD_WRITE); //write
    assign set_dirty_1         = req_vld_1 && (req_pld_1.opcode==`VEC_CACHE_CMD_WRITE); //write
    assign clr_dirty_0         = req_vld_0 && miss_0 && (req_pld_0.opcode==`VEC_CACHE_CMD_READ);//read_miss
    assign clr_dirty_1         = req_vld_1 && miss_1 && (req_pld_1.opcode==`VEC_CACHE_CMD_READ);

    assign tag_dirty_wr_en_0   = req_vld_0 && ((req_pld_0.opcode==`VEC_CACHE_CMD_WRITE) | (miss_0 && (req_pld_0.opcode==`VEC_CACHE_CMD_READ)));
    assign tag_dirty_wr_en_1   = req_vld_1 && ((req_pld_1.opcode==`VEC_CACHE_CMD_WRITE) | (miss_1 && (req_pld_1.opcode==`VEC_CACHE_CMD_READ)));

    assign tag_dirty_bit_wr_en_0 = dest_way_oh_0;
    assign tag_dirty_bit_wr_en_1 = dest_way_oh_1;

    assign tag_dirty_wr_addr_0 = req_pld_0.addr.index  ;
    assign tag_dirty_wr_addr_1 = req_pld_1.addr.index  ;

    always_comb begin
        tag_dirty_in_0 = 'b0;
        if(set_dirty_0)         tag_dirty_in_0 = 1'b1;
        else if(clr_dirty_0)    tag_dirty_in_0 = 1'b0;
    end
     always_comb begin
        tag_dirty_in_1 = 'b0;
        if(set_dirty_1)         tag_dirty_in_1 = 1'b1;
        else if(clr_dirty_1)    tag_dirty_in_1 = 1'b0;
    end
    
    vec_cache_tag_dirty_array  #( 
        .ADDR_WIDTH(INDEX_WIDTH),
        .DATA_WIDTH(4))
    u_tag_dirty_array ( 
        .clk        (clk                    ),
        .rst_n      (rst_n                  ),
        .addr_0     (tag_dirty_wr_addr_0    ),
        .addr_1     (tag_dirty_wr_addr_1    ),
        .wr_en_0    (tag_dirty_wr_en_0      ),
        .wr_en_1    (tag_dirty_wr_en_1      ),
        .bit_wr_en_0(tag_dirty_bit_wr_en_0  ),
        .bit_wr_en_1(tag_dirty_bit_wr_en_1  ),
        .wr_data_0  (tag_dirty_in_0         ),
        .wr_data_1  (tag_dirty_in_1         ),
        .rd_data_0  (dirty_0                ),
        .rd_data_1  (dirty_1                ));

//==========================================================================
//        hit/miss check
//==========================================================================
    //         weight update 
    //always_ff@(posedge clk or negedge rst_n)begin
    //    if(!rst_n)    weight <= 'b0;
    //    else          weight <= weight+ 1'b1;
    //end
    srrip #( 
        .INDEX_WIDTH(INDEX_WIDTH),
        .RRPV_WIDTH (2          ),
        .WAY_NUM    (WAY_NUM    ),
        .SET_NUM    (SET_NUM    ))
    u_srrip( 
        .clk                (clk                    ),
        .rst_n              (rst_n                  ),
        .req_vld_0          (req_vld_0              ),
        .req_vld_1          (req_vld_1              ),
        .req_index_0        (req_pld_0.addr.index   ),
        .req_index_1        (req_pld_1.addr.index   ),
        .hit_0              (hit_0                  ),
        .hit_1              (hit_1                  ),
        .hit_way_oh_0       (hit_way_oh_0           ),
        .hit_way_oh_1       (hit_way_oh_1           ),
        .miss_0             (miss_0                 ),
        .miss_1             (miss_1                 ),
        .replace_way_0      (replace_way_0          ),
        .replace_way_1      (replace_way_1          ),
        .replace_vld_0      (replace_vld_0          ),
        .replace_vld_1      (replace_vld_1          ));
    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM) ),
        .ONEHOT_WIDTH(WAY_NUM         )) 
    u_replace_way_oh_0 (
        .bin_in    (replace_way_0     ),
        .onehot_out(replace_way_oh_0  ));
    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM) ),
        .ONEHOT_WIDTH(WAY_NUM         )) 
    u_replace_way_oh_1 (
        .bin_in    (replace_way_1     ),
        .onehot_out(replace_way_oh_1  ));
    
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_hit_way_oh_0[i] = tag_ram_dout_0.tag_array[i].valid && (req_pld_0.addr.tag == tag_ram_dout_0.tag_array[i].tag);
        end
    endgenerate
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_hit_way_oh_1[i] = tag_ram_dout_1.tag_array[i].valid && (req_pld_1.addr.tag == tag_ram_dout_1.tag_array[i].tag);
        end
    endgenerate

    assign req0_hit_wr_tag_buf_0 = (req_pld_0.addr.tag==wr_tag_buf_pld_0.tag)&&(req_pld_0.addr.index== wr_tag_buf_pld_0.index);
    assign req0_hit_wr_tag_buf_1 = (req_pld_0.addr.tag==wr_tag_buf_pld_1.tag)&&(req_pld_0.addr.index== wr_tag_buf_pld_1.index);
    assign req1_hit_wr_tag_buf_0 = (req_pld_1.addr.tag==wr_tag_buf_pld_0.tag)&&(req_pld_1.addr.index== wr_tag_buf_pld_0.index);
    assign req1_hit_wr_tag_buf_1 = (req_pld_1.addr.tag==wr_tag_buf_pld_1.tag)&&(req_pld_1.addr.index== wr_tag_buf_pld_1.index);
    
    assign wr_tag_buf_way_oh_0   = wr_tag_buf_pld_0.way_oh;
    assign wr_tag_buf_way_oh_1   = wr_tag_buf_pld_1.way_oh;
    assign hit_way_oh_0          = req0_hit_wr_tag_buf_0 ? wr_tag_buf_way_oh_0 :
                                   req0_hit_wr_tag_buf_1 ? wr_tag_buf_way_oh_1 : tag_ram_hit_way_oh_0;//hit ram or hit wr_tag_buf
    assign hit_way_oh_1          = req1_hit_wr_tag_buf_0 ? wr_tag_buf_way_oh_0 : 
                                   req1_hit_wr_tag_buf_1 ? wr_tag_buf_way_oh_1 : tag_ram_hit_way_oh_1   ;
    assign tag_ram_hit_0        = |tag_ram_hit_way_oh_0                                                 ;
    assign tag_ram_hit_1        = |tag_ram_hit_way_oh_1                                                 ;
    assign hit_0                = tag_ram_hit_0 | req0_hit_wr_tag_buf_0 | req0_hit_wr_tag_buf_1         ;
    assign hit_1                = tag_ram_hit_1 | req1_hit_wr_tag_buf_0 | req1_hit_wr_tag_buf_1         ;
    assign miss_0               = ~hit_0                                                                ;
    assign miss_1               = ~hit_1                                                                ;
    assign evict_way_0          = replace_way_0                                                         ;
    assign evict_way_1          = replace_way_1                                                         ;
    assign evict_way_oh_0       = replace_way_oh_0                                                      ; 
    assign evict_way_oh_1       = replace_way_oh_1                                                      ; 
    assign dest_way_oh_0        = hit_0 ? hit_way_oh_0 : evict_way_oh_0                                 ;
    assign dest_way_oh_1        = hit_1 ? hit_way_oh_1 : evict_way_oh_1                                 ;
    
    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            tag_array_0[i] = tag_ram_dout_0.tag_array[i].tag;
            tag_array_1[i] = tag_ram_dout_1.tag_array[i].tag;
        end
    end
    cmn_real_mux_onehot #( 
        .WIDTH          (WAY_NUM        ),
        .PLD_WIDTH      (TAG_WIDTH      ))
    u_evict_tag_0 (
        .select_onehot (evict_way_oh_0  ),
        .v_pld         (tag_array_0     ),
        .select_pld    (evict_tag_0     ));
    cmn_real_mux_onehot #( 
        .WIDTH          (WAY_NUM        ),
        .PLD_WIDTH      (TAG_WIDTH      ))
    u_evict_tag_1 (
        .select_onehot (evict_way_oh_1  ),
        .v_pld         (tag_array_1     ),
        .select_pld    (evict_tag_1     ));
   
    cmn_onehot2bin #(
        .ONEHOT_WIDTH   (WAY_NUM        )) 
    u_hit_way_oh2bin_0 (
        .onehot_in      (hit_way_oh_0   ),
        .bin_out        (hit_way_0      ));
    cmn_onehot2bin #(
        .ONEHOT_WIDTH   (WAY_NUM        )
    ) u_hit_way_oh2bin_1 (
        .onehot_in      (hit_way_oh_1   ),
        .bin_out        (hit_way_1      ));

    cmn_onehot2bin #(
        .ONEHOT_WIDTH   (WAY_NUM        )) 
    u_dest_way_oh2bin_0 (
        .onehot_in      (dest_way_oh_0   ),
        .bin_out        (dest_way_0      ));
    cmn_onehot2bin #(
        .ONEHOT_WIDTH   (WAY_NUM        )) 
    u_dest_way_oh2bin_1 (
        .onehot_in      (dest_way_oh_1   ),
        .bin_out        (dest_way_1      ));
//================================================================================
//         hazard check and behavior mapping (address hazard check)
//================================================================================
    //generate
    //    for(genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin
    //        always_comb begin
    //            v_hazard_bitmap_0[i] = 1'b0;
    //            v_hazard_bitmap_1[i] = 1'b0;
    //            if( v_mshr_entry_pld[i].valid)begin
    //                v_hazard_bitmap_0[i] =  (req_pld_0.addr.index==v_mshr_entry_pld[i].index)
    //                                    && ((req_pld_0.addr.tag ==v_mshr_entry_pld[i].tag) || (req_pld_0.addr.tag==v_mshr_entry_pld[i].evict_tag));
    //                v_hazard_bitmap_1[i] =  (req_pld_1.addr.index==v_mshr_entry_pld[i].index)
    //                                    && ((req_pld_1.addr.tag ==v_mshr_entry_pld[i].tag) || (req_pld_1.addr.tag==v_mshr_entry_pld[i].evict_tag));
    //            end
    //        end
    //    end
    //endgenerate
    generate
        for(genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin
            always_comb begin
                v_hazard_bitmap_0[i] = 1'b0;
                v_hazard_bitmap_1[i] = 1'b0;
                if( v_mshr_entry_pld[i].valid)begin
                    v_hazard_bitmap_0[i] =  (req_pld_0.addr.index==v_mshr_entry_pld[i].index)
                                        && (dest_way_0 == v_mshr_entry_pld[i].way);
                    v_hazard_bitmap_1[i] =  (req_pld_1.addr.index==v_mshr_entry_pld[i].index)
                                        && (dest_way_1 == v_mshr_entry_pld[i].way);
                end
            end
        end
    endgenerate

    assign mshr_update_en_0                = req_vld_0                                                                                  ;
    assign mshr_update_en_1                = req_vld_1                                                                                  ;   
    assign mshr_update_pld_0.rob_entry_id  = req_pld_0.rob_entry_id                                                                     ; 
    assign mshr_update_pld_0.wdb_entry_id  = req_pld_0.db_entry_id                                                                      ;//只有write在输入带
    assign mshr_update_pld_0.txn_id        = req_pld_0.txn_id                                                                           ;
    assign mshr_update_pld_0.opcode        = req_pld_0.opcode                                                                           ;
    assign mshr_update_pld_0.sideband      = req_pld_0.sideband                                                                         ;
    assign mshr_update_pld_0.index         = req_pld_0.addr.index                                                                       ;
    assign mshr_update_pld_0.offset        = req_pld_0.addr.offset                                                                      ;
    assign mshr_update_pld_0.tag           = req_pld_0.addr.tag                                                                         ;
    assign mshr_update_pld_0.way           = hit_0 ? hit_way_0 : evict_way_0                                                            ;
    assign mshr_update_pld_0.hit           = req_vld_0 && hit_0                                                                         ;
    assign mshr_update_pld_0.need_evict    = req_vld_0 && dirty_0[evict_way_0] && miss_0 && tag_ram_dout_0.tag_array[evict_way_0].valid ;
    assign mshr_update_pld_0.evict_tag     = evict_tag_0                                                                                ;
    assign mshr_update_pld_0.hzd_bitmap    = v_hazard_bitmap_0                                                                          ;
    assign mshr_update_pld_0.hzd_pass      = ((|v_hazard_bitmap_0)==1'b0)                                                               ;
   
   
    assign mshr_update_pld_1.rob_entry_id  = req_pld_1.rob_entry_id                                                                     ;
    assign mshr_update_pld_1.wdb_entry_id  = req_pld_1.db_entry_id                                                                      ;
    assign mshr_update_pld_1.txn_id        = req_pld_1.txn_id                                                                           ;
    assign mshr_update_pld_1.opcode        = req_pld_1.opcode                                                                           ;
    assign mshr_update_pld_1.sideband      = req_pld_1.sideband                                                                         ;
    assign mshr_update_pld_1.index         = req_pld_1.addr.index                                                                       ;
    assign mshr_update_pld_1.offset        = req_pld_1.addr.offset                                                                      ;
    assign mshr_update_pld_1.tag           = req_pld_1.addr.tag                                                                         ;
    assign mshr_update_pld_1.way           = hit_1 ? hit_way_1 : evict_way_1                                                            ;
    assign mshr_update_pld_1.hit           = req_vld_1 && hit_1                                                                         ;
    assign mshr_update_pld_1.need_evict    = req_vld_1 && dirty_1[evict_way_1] && miss_1 && tag_ram_dout_1.tag_array[evict_way_1].valid ;
    assign mshr_update_pld_1.evict_tag     = evict_tag_1                                                                                ;
    assign mshr_update_pld_1.hzd_bitmap    = v_hazard_bitmap_1                                                                          ;
    assign mshr_update_pld_1.hzd_pass      = ((|v_hazard_bitmap_1)==1'b0)                                                               ;
    

//===============================================================
//          wresp decode to direction
//===============================================================
    //vec_cache_wr_resp_direction_decode #(
    //    .WIDTH(4)) 
    //u_wresp_decode_0(
    //    .clk        (clk                         ),
    //    .rst_n      (rst_n                       ),
    //    .req_vld    (tag_req_vld_0               ),
    //    .req_pld    (tag_req_pld_0               ),
    //    .v_wresp_vld(v_wr_resp_vld_0             ),
    //    .v_wresp_pld(v_wr_resp_pld_0             ));
//
    //vec_cache_wr_resp_direction_decode #(
    //    .WIDTH(4)) 
    //u_wresp_decode_1(
    //    .clk        (clk                         ),
    //    .rst_n      (rst_n                       ),
    //    .req_vld    (tag_req_vld_1               ),
    //    .req_pld    (tag_req_pld_1               ),
    //    .v_wresp_vld(v_wr_resp_vld_1             ),
    //    .v_wresp_pld(v_wr_resp_pld_1             ));

    vec_cache_wr_resp_direction_decode #(
        .WIDTH(4)) 
    u_wresp_decode_0(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (req_vld_0                   ),
        .req_pld    (req_pld_0                   ),
        .v_wresp_vld(v_wr_resp_vld_0             ),
        .v_wresp_pld(v_wr_resp_pld_0             ));

    vec_cache_wr_resp_direction_decode #(
        .WIDTH(4)) 
    u_wresp_decode_1(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (req_vld_1                   ),
        .req_pld    (req_pld_1                   ),
        .v_wresp_vld(v_wr_resp_vld_1             ),
        .v_wresp_pld(v_wr_resp_pld_1             ));


endmodule

