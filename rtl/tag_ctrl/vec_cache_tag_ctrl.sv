module vec_cache_tag_ctrl
    import vector_cache_pkg::*;
    (
    input  logic                                clk                                   ,
    input  logic                                rst_n                                 ,

    output logic [3:0]                          v_wr_resp_vld_0                       , //双发
    output wr_resp_pld_t                        v_wr_resp_pld_0     [3:0]             , //txnid+sideband
    output logic [3:0]                          v_wr_resp_vld_1                       , //双发
    output wr_resp_pld_t                        v_wr_resp_pld_1     [3:0]             , //txnid+sideband    

    input  logic                                tag_req_vld_A                         ,
    input  logic                                tag_req_vld_B                         ,
    input  input_req_pld_t                      tag_req_pld_A                         ,
    input  input_req_pld_t                      tag_req_pld_B                         ,
    output logic                                tag_req_rdy                           ,//to 8to2 arb
    input  hzd_mshr_pld_t                       v_mshr_entry_pld  [MSHR_ENTRY_NUM-1:0],

    output logic                                mshr_update_en_0                      ,
    output logic                                mshr_update_en_1                      ,
    output mshr_entry_t                         mshr_update_pld_0                     ,
    output mshr_entry_t                         mshr_update_pld_1                     

    );

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
    
    
    logic [MSHR_ENTRY_NUM-1 :0]             v_A_hazard_bitmap              ;
    logic [MSHR_ENTRY_NUM-1 :0]             v_B_hazard_bitmap              ;
    logic                                   req_vld_A                      ;
    logic                                   req_vld_B                      ;
    input_req_pld_t                         req_pld_A                      ;
    input_req_pld_t                         req_pld_B                      ;
    logic                                   wr_tag_buf_vld_A               ;
    logic                                   wr_tag_buf_vld_B               ;
    wr_buf_pld_t                            wr_tag_buf_pld_A               ;
    wr_buf_pld_t                            wr_tag_buf_pld_B               ;
    logic                                   wr_buf_vld                     ;

    logic [WAY_NUM-1        :0]             A_dirty                        ;
    logic [WAY_NUM-1        :0]             B_dirty                        ;
    logic [WAY_NUM-1        :0]             A_tag_ram_hit_way_oh           ;
    logic [WAY_NUM-1        :0]             A_hit_way_oh                   ;
    logic [WAY_NUM-1        :0]             A_evict_way_oh                 ;
    logic [$clog2(WAY_NUM)-1:0]             A_hit_way                      ;
    logic [WAY_NUM-1        :0]             B_tag_ram_hit_way_oh           ;
    logic [WAY_NUM-1        :0]             B_hit_way_oh                   ;
    logic [WAY_NUM-1        :0]             B_evict_way_oh                 ;
    logic [$clog2(WAY_NUM)-1:0]             B_hit_way                      ;
    logic [WAY_NUM-1        :0]             A_dest_way_oh                  ;
    logic [WAY_NUM-1        :0]             B_dest_way_oh                  ;
    logic [TAG_WIDTH-1      :0]             A_evict_tag                    ;
    logic [TAG_WIDTH-1      :0]             B_evict_tag                    ;
    logic [$clog2(WAY_NUM)-1:0]             A_evict_way                    ;
    logic [$clog2(WAY_NUM)-1:0]             B_evict_way                    ;
    logic [$clog2(WAY_NUM)-1:0]             weight                         ;
    logic                                   A_wr_tag_buf_hit               ;
    logic                                   B_wr_tag_buf_hit               ;
    logic                                   A_tag_ram_hit                  ;
    logic                                   B_tag_ram_hit                  ;
    logic                                   A_hit                          ;
    logic                                   B_hit                          ;
    logic                                   A_miss                         ;
    logic                                   B_miss                         ;
    logic [WAY_NUM-1        :0]             A_wr_tag_buf_way_oh            ;
    logic [WAY_NUM-1        :0]             B_wr_tag_buf_way_oh            ;
    logic [WAY_NUM-1        :0]             tag_array_dirty[2**INDEX_WIDTH-1:0];
    logic [2**INDEX_WIDTH-1 :0]             A_tag_idx_oh                   ;
    logic [2**INDEX_WIDTH-1 :0]             B_tag_idx_oh                   ;
    logic                                   wr_tag_buf_A_update_en         ;
    logic                                   wr_tag_buf_B_update_en         ;
    logic                                   wr_tag_buf_A_clean_en          ;
    logic                                   wr_tag_buf_B_clean_en          ;
    logic                                   tag_dirty_update_0             ;
    logic                                   tag_dirty_update_1             ;
    logic                                   tag_dirty_clean_0              ;
    logic                                   tag_dirty_clean_1              ;

//================================================================
//        tag_ram access arbiter(wr_buf & tag_req)
//================================================================
    typedef struct packed {
        logic [INDEX_WIDTH-1:0] addr   ;
        tag_t                   data_in;
    } tag_ram_req_t;
    tag_ram_req_t tag_ram_req_pld_0;
    tag_ram_req_t tag_ram_req_pld_1;

    //assign wr_buf_vld                = wr_tag_buf_vld_A | wr_tag_buf_vld_B;
    assign tag_req_rdy               = ~(wr_tag_buf_vld_A | wr_tag_buf_vld_B);
    assign tag_ram_req_vld_0         = wr_tag_buf_vld_A | wr_tag_buf_vld_B | tag_req_vld_A;
    assign tag_ram_req_vld_1         = wr_tag_buf_vld_A | wr_tag_buf_vld_B | tag_req_vld_B;
    assign tag_ram_req_pld_0.addr    = wr_tag_buf_vld_A ? wr_tag_buf_pld_A.index :
                                       wr_tag_buf_vld_B ? wr_tag_buf_pld_B.index : tag_req_pld_A.cmd_addr.index;

    assign tag_ram_req_pld_0.data_in = wr_tag_buf_vld_A ? {wr_tag_buf_pld_A.tag,1'b1} : {wr_tag_buf_pld_B,1'b1};

    assign tag_ram_req_pld_1.addr    = wr_tag_buf_vld_A ? wr_tag_buf_pld_A.index :
                                       wr_tag_buf_vld_B ? wr_tag_buf_pld_B.index : tag_req_pld_A.cmd_addr.index;

    assign tag_ram_req_pld_1.data_in = wr_tag_buf_vld_A ? {wr_tag_buf_pld_A.tag,1'b1} : {wr_tag_buf_pld_B,1'b1};
    

//========================================================
//        tag  ram
//========================================================
    assign tag_mem_en_0    = tag_ram_req_vld_0;
    assign tag_mem_en_1    = tag_ram_req_vld_1;

    assign tag_ram_wr_en_0 = wr_tag_buf_vld_A | wr_tag_buf_vld_B;
    assign tag_ram_wr_en_1 = wr_tag_buf_vld_A | wr_tag_buf_vld_B;

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
    assign wr_tag_buf_A_update_en = A_miss                                ;
    assign wr_tag_buf_A_clean_en  = wr_tag_buf_vld_A                      ;
    assign wr_tag_buf_B_update_en = B_miss                                ;
    assign wr_tag_buf_B_clean_en  = ~wr_tag_buf_vld_A && wr_tag_buf_vld_B ;
    vec_cache_wr_tag_buf u_wr_tag_buf_A ( 
        .clk           (clk                     ),
        .rst_n         (rst_n                   ),
        .buf_update_en (wr_tag_buf_A_update_en  ),
        .buf_clean_en  (wr_tag_buf_A_clean_en   ),
        .req_pld       (req_pld_A               ),
        .evict_way     (A_evict_way             ),
        .wr_tag_buf_vld(wr_tag_buf_vld_A        ),
        .wr_tag_buf_pld(wr_tag_buf_pld_A        ));

    vec_cache_wr_tag_buf u_wr_tag_buf_B ( 
        .clk           (clk                     ),
        .rst_n         (rst_n                   ),
        .buf_update_en (wr_tag_buf_B_update_en  ),
        .buf_clean_en  (wr_tag_buf_B_clean_en   ),
        .req_pld       (req_pld_B               ),
        .evict_way     (B_evict_way             ),
        .wr_tag_buf_vld(wr_tag_buf_vld_B        ),
        .wr_tag_buf_pld(wr_tag_buf_pld_B        ));

//================================================================
//        tag req pld buffer 
//================================================================
    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            req_vld_A  <= 1'b0;
            req_vld_B  <= 1'b0;
        end
        else begin
            req_vld_A <= tag_req_vld_A && tag_req_rdy;
            req_vld_B <= tag_req_vld_B && tag_req_rdy;
        end
    end
 
    always_ff@(posedge clk )begin
        req_pld_A <= tag_req_pld_A;
        req_pld_B <= tag_req_pld_B;
    end


//========================================================
//        dirty ram 
//========================================================
    assign tag_dirty_update_0 = req_vld_A && (req_pld_A.cmd_opcode==`VEC_CACHE_CMD_WRITE); //write
    assign tag_dirty_update_1 = req_vld_B && (req_pld_B.cmd_opcode==`VEC_CACHE_CMD_WRITE); //write
    assign tag_dirty_clean_0  = req_vld_A && A_miss && (req_pld_A.cmd_opcode==`VEC_CACHE_CMD_READ);//read_miss
    assign tag_dirty_clean_1  = req_vld_B && B_miss && (req_pld_B.cmd_opcode==`VEC_CACHE_CMD_READ);
    cmn_bin2onehot #(
       .BIN_WIDTH    (INDEX_WIDTH   ),
       .ONEHOT_WIDTH (2**INDEX_WIDTH))
    u_tag_dty_idx_bin2onehot_A(
       .bin_in       (req_pld_A.cmd_addr.index),
       .onehot_out   (A_tag_idx_oh            ));
    cmn_bin2onehot #(
       .BIN_WIDTH    (INDEX_WIDTH  ),
       .ONEHOT_WIDTH (2**INDEX_WIDTH))
    u_tag_dty_idx_bin2onehot_B(
       .bin_in       (req_pld_B.cmd_addr.index),
       .onehot_out   (B_tag_idx_oh            ));
    vec_cache_tag_dirty u_tag_dirty_ram ( 
        .clk            (clk                ),
        .rst_n          (rst_n              ),
        .dirty_update_0 (tag_dirty_update_0 ),
        .dirty_update_1 (tag_dirty_update_1 ),
        .dirty_clean_0  (tag_dirty_clean_0  ),
        .dirty_clean_1  (tag_dirty_clean_1  ),
        .tag_idx_oh_0   (A_tag_idx_oh       ),
        .tag_idx_oh_1   (B_tag_idx_oh       ),
        .dest_way_oh_0  (A_dest_way_oh      ),
        .dest_way_oh_1  (B_dest_way_oh      ),
        .tag_dirty      (tag_array_dirty    ));
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign A_dirty[i] = tag_array_dirty[req_pld_A.cmd_addr.index][i];
        end
    endgenerate
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign B_dirty[i] = tag_array_dirty[req_pld_B.cmd_addr.index][i];
        end
    endgenerate    


//==========================================================================
//        hit/miss check
//==========================================================================
    //----------------------------------------------------------
    //         lru weight update 
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            weight<= 'b0;
        end
        else begin
            weight <= weight+ 1'b1;
        end
    end
    assign A_evict_way = weight; //miss way
    assign B_evict_way = weight; //miss way

    cmn_bin2onehot #(
        .ONEHOT_WIDTH(WAY_NUM           ),
        .BIN_WIDTH   ($clog2(WAY_NUM)   )) 
    u_bin2onehot_A (
        .bin_in    (wr_tag_buf_pld_A.way),
        .onehot_out(A_wr_tag_buf_way_oh ));

    cmn_bin2onehot #(
        .ONEHOT_WIDTH(WAY_NUM           ),
        .BIN_WIDTH   ($clog2(WAY_NUM)   ))
     u_bin2onehot_B (
        .bin_in    (wr_tag_buf_pld_B.way),
        .onehot_out(B_wr_tag_buf_way_oh ));
    
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign A_tag_ram_hit_way_oh[i] = tag_ram_dout_0.tag_array[i].valid && (req_pld_A.cmd_addr.tag == tag_ram_dout_0.tag_array[i].tag);
        end
    endgenerate
    assign A_hit_way_oh = A_wr_tag_buf_hit ? A_wr_tag_buf_way_oh : A_tag_ram_hit_way_oh;//hit ram or hit wr_tag_buf

    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign B_tag_ram_hit_way_oh[i] = tag_ram_dout_1.tag_array[i].valid && (req_pld_B.cmd_addr.tag == tag_ram_dout_1.tag_array[i].tag);
        end
    endgenerate
    assign B_hit_way_oh = B_wr_tag_buf_hit ? B_wr_tag_buf_way_oh : B_tag_ram_hit_way_oh;

    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WAY_NUM   )) 
    u_A_hit_way_oh2bin (
        .onehot_in (A_hit_way_oh),
        .bin_out   (A_hit_way   ));
    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WAY_NUM)
    ) u_B_hit_way_oh2bin (
        .onehot_in (B_hit_way_oh),
        .bin_out   (B_hit_way   )
    );
    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM        )) 
    u_evict_way_oh_A (
        .bin_in    (A_evict_way     ),
        .onehot_out(A_evict_way_oh  ));

    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM        )) 
    u_evict_way_oh_B (
        .bin_in    (B_evict_way     ),
        .onehot_out(B_evict_way_oh  ));
    
    assign A_wr_tag_buf_hit = req_vld_A && (((req_pld_A.cmd_addr.tag==wr_tag_buf_pld_A.tag)&&(req_pld_A.cmd_addr.index== wr_tag_buf_pld_A.index)) || ((req_pld_A.cmd_addr.tag==wr_tag_buf_pld_B.tag)&&(req_pld_A.cmd_addr.index== wr_tag_buf_pld_B.index)));
    assign B_wr_tag_buf_hit = req_vld_B && (((req_pld_B.cmd_addr.tag==wr_tag_buf_pld_A.tag)&&(req_pld_B.cmd_addr.index== wr_tag_buf_pld_A.index)) || ((req_pld_B.cmd_addr.tag==wr_tag_buf_pld_B.tag)&&(req_pld_B.cmd_addr.index== wr_tag_buf_pld_B.index)));
    
    assign A_tag_ram_hit = |A_tag_ram_hit_way_oh;
    assign B_tag_ram_hit = |B_tag_ram_hit_way_oh;

    assign A_hit  = A_tag_ram_hit || A_wr_tag_buf_hit;
    assign B_hit  = B_tag_ram_hit || B_wr_tag_buf_hit;
    assign A_miss = ~A_hit && req_vld_A;
    assign B_miss = ~B_hit && req_vld_B;

    assign A_dest_way_oh = A_hit ? A_hit_way_oh : A_evict_way_oh;
    assign B_dest_way_oh = B_hit ? B_hit_way_oh : B_evict_way_oh;

    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            if(A_dest_way_oh[i]==1'b1)begin
                A_evict_tag = tag_ram_dout_0.tag_array[i].tag;
            end
        end
    end
    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            if(B_dest_way_oh[i]==1'b1)begin
                B_evict_tag = tag_ram_dout_1.tag_array[i].tag;
            end
        end
    end 

//================================================================================
//         hazard check and behavior mapping (address hazard check)
//================================================================================
    assign mshr_update_en_0 = req_vld_A;
    assign mshr_update_en_1 = req_vld_B;   

    generate
        for(genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin
            assign v_A_hazard_bitmap[i] = mshr_update_en_0 && v_mshr_entry_pld[i].valid && ~v_mshr_entry_pld[i].release_bit && (req_pld_A.cmd_addr.index==v_mshr_entry_pld[i].index)
                                       && ((req_pld_A.cmd_addr.tag==v_mshr_entry_pld[i].tag) || (req_pld_A.cmd_addr.tag==v_mshr_entry_pld[i].evict_tag));

            assign v_B_hazard_bitmap[i] = mshr_update_en_1 && v_mshr_entry_pld[i].valid && ~v_mshr_entry_pld[i].release_bit && (req_pld_B.cmd_addr.index==v_mshr_entry_pld[i].index)
                                       && ((req_pld_B.cmd_addr.tag==v_mshr_entry_pld[i].tag) || (req_pld_B.cmd_addr.tag==v_mshr_entry_pld[i].evict_tag));   
        end
    endgenerate

    //mshr_entry pld
    assign mshr_update_pld_0.txnid         = req_pld_A.cmd_txnid                                                                                    ;
    assign mshr_update_pld_0.hash_id       = req_pld_A.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1]                                                        ;
    assign mshr_update_pld_0.dest_ram_id   = {req_pld_A.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1],req_pld_A.cmd_addr.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
    assign mshr_update_pld_0.sideband      = req_pld_A.cmd_sideband                                                                                 ;
    assign mshr_update_pld_0.index         = req_pld_A.cmd_addr.index                                                                               ;
    assign mshr_update_pld_0.offset        = req_pld_A.cmd_addr.offset                                                                              ;
    assign mshr_update_pld_0.req_tag       = req_pld_A.cmd_addr.tag                                                                                 ;
    assign mshr_update_pld_0.way           = A_hit ? A_hit_way : A_evict_way                                                                        ;
    assign mshr_update_pld_0.is_read       = req_vld_A && (req_pld_A.cmd_opcode== `VEC_CACHE_CMD_READ )                                             ;
    assign mshr_update_pld_0.is_write      = req_vld_A && (req_pld_A.cmd_opcode== `VEC_CACHE_CMD_WRITE)                                             ;
    assign mshr_update_pld_0.hit           = A_hit                                                                                                  ;
    assign mshr_update_pld_0.need_linefill = ~A_hit && req_vld_A                                                                                    ;
    assign mshr_update_pld_0.need_evict    = A_dirty[A_evict_way] && A_miss && tag_ram_dout_0.tag_array[A_evict_way].valid                          ;
    assign mshr_update_pld_0.evict_tag     = A_evict_tag                                                                                            ;
    assign mshr_update_pld_0.hzd_bitmap    = v_A_hazard_bitmap                                                                                      ;
    assign mshr_update_pld_0.release_bitmap= 'b0                                                                                                    ;
    assign mshr_update_pld_0.hzd_pass      = ((|v_A_hazard_bitmap)==1'b0)                                                                           ;
    assign mshr_update_pld_0.alloc_idx     = req_pld_A.rob_entry_id                                                                                 ; 
    assign mshr_update_pld_0.wdb_entry_id  = req_pld_A.db_entry_id                                                                                  ;//只有write在输入带

    assign mshr_update_pld_1.txnid         = req_pld_B.cmd_txnid                                                                                    ;
    assign mshr_update_pld_1.hash_id       = req_pld_B.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1]                                                        ;
    assign mshr_update_pld_1.dest_ram_id   = {req_pld_B.cmd_addr.tag[TAG_WIDTH-1:TAG_WIDTH-1],req_pld_B.cmd_addr.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
    assign mshr_update_pld_1.sideband      = req_pld_B.cmd_sideband                                                                                 ;
    assign mshr_update_pld_1.index         = req_pld_B.cmd_addr.index                                                                               ;
    assign mshr_update_pld_1.offset        = req_pld_B.cmd_addr.offset                                                                              ;
    assign mshr_update_pld_1.req_tag       = req_pld_B.cmd_addr.tag                                                                                 ;
    assign mshr_update_pld_1.way           = B_hit ? B_hit_way : B_evict_way                                                                        ;
    assign mshr_update_pld_1.is_read       = req_vld_B && (req_pld_B.cmd_opcode== `VEC_CACHE_CMD_READ )                                             ;
    assign mshr_update_pld_1.is_write      = req_vld_B && (req_pld_B.cmd_opcode== `VEC_CACHE_CMD_WRITE)                                             ;
    assign mshr_update_pld_1.hit           = B_hit                                                                                                  ;
    assign mshr_update_pld_1.need_linefill = ~B_hit && req_vld_B                                                                                    ;
    assign mshr_update_pld_1.need_evict    = B_dirty[B_evict_way] && B_miss && tag_ram_dout_1.tag_array[B_evict_way].valid                          ;
    assign mshr_update_pld_1.evict_tag     = B_evict_tag                                                                                            ;
    assign mshr_update_pld_1.hzd_bitmap    = v_B_hazard_bitmap                                                                                      ;
    assign mshr_update_pld_1.release_bitmap= 'b0                                                                                                    ;
    assign mshr_update_pld_1.hzd_pass      = ((|v_B_hazard_bitmap)==1'b0)                                                                           ;
    assign mshr_update_pld_1.alloc_idx     = req_pld_B.rob_entry_id                                                                                 ;
    assign mshr_update_pld_1.wdb_entry_id  = req_pld_B.db_entry_id                                                                                  ;

//===============================================================
//          wresp decode to direction
//===============================================================
    vec_cache_wr_resp_direction_decode #(
        .WIDTH(4)) 
    u_wresp_decode_0(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (tag_req_vld_A               ),
        .req_pld    (tag_req_pld_A               ),
        .v_wresp_vld(v_wr_resp_vld_0             ),
        .v_wresp_pld(v_wr_resp_pld_0             ));

    vec_cache_wr_resp_direction_decode #(
        .WIDTH(4)) 
    u_wresp_decode_1(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (tag_req_vld_B               ),
        .req_pld    (tag_req_pld_B               ),
        .v_wresp_vld(v_wr_resp_vld_1             ),
        .v_wresp_pld(v_wr_resp_pld_1             ));


endmodule

