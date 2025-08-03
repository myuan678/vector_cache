module vec_cache_tag_ctrl
    import vector_cache_pkg::*;
    #(
        //parameter TAG_INFO_WIDTH = TAG_WIDTH+2,//加1bit valid，加1bit dirty/clean
    parameter TAG_INFO_WIDTH = TAG_WIDTH+1,//加1bit valid
        parameter TAG_RAM_WIDTH  = TAG_INFO_WIDTH * WAY_NUM
    )
    (
    input  logic                                clk                                   ,
    input  logic                                rst_n                                 ,

    //ack to wreite req wr_resp
    output logic [3:0]                          v_wr_resp_vld_1                       , //双发
    output wr_resp_pld_t                        v_wr_resp_pld_1  [3:0]                , //txnid+sideband
    output logic [3:0]                          v_wr_resp_vld_2                       , //双发
    output wr_resp_pld_t                        v_wr_resp_pld_2  [3:0]                , //txnid+sideband    
    input  logic                                wr_resp_rdy                           ,//master 接受write resp的rdy，应该tie1？

    input  logic                                tag_req_vld_1                           ,
    input  logic                                tag_req_vld_2                           ,
    input  input_req_pld_t                      tag_req_input_arb_grant1_pld          ,
    input  input_req_pld_t                      tag_req_input_arb_grant2_pld          ,
    output logic                                tag_req_rdy                           ,//to 8to2 arb
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]     mshr_alloc_idx_1                      ,//mshr entry的pre allocate的entry idx
    input  logic [MSHR_ENTRY_IDX_WIDTH-1:0]     mshr_alloc_idx_2                      ,
    input  mshr_entry_t                         v_mshr_entry_pld[MSHR_ENTRY_NUM-1:0]  ,

    output logic                                mshr_update_en                        ,
    input  logic [MSHR_ENTRY_IDX_WIDTH    :0]   entry_release_done_index              ,
    input  logic                                stall                                 ,
    output mshr_entry_t                         mshr_update_pld_A                     ,
    output mshr_entry_t                         mshr_update_pld_B                     

    //output logic                                tag_mem_en                            ,
    //output logic                                tag_ram_A_wr_en                       ,
    //output logic [INDEX_WIDTH-1     :0]         tag_ram_A_addr                        ,
    //output logic [TAG_RAM_WIDTH-1   :0]         tag_ram_A_din                         ,
    //input  logic [TAG_RAM_WIDTH-1   :0]         tag_ram_A_dout                        ,
    //output logic                                tag_ram_B_wr_en                       ,
    //output logic [INDEX_WIDTH-1     :0]         tag_ram_B_addr                        ,
    //output logic [TAG_RAM_WIDTH-1   :0]         tag_ram_B_din                         ,
    //input  logic [TAG_RAM_WIDTH-1   :0]         tag_ram_B_dout                        

    //---------------------------------------------
    //add change
    //---------------------------------------------

    );
    logic                                tag_mem_en      ;
    logic                                tag_ram_A_wr_en ;
    logic [INDEX_WIDTH-1     :0]         tag_ram_A_addr  ;
    logic [TAG_RAM_WIDTH-1   :0]         tag_ram_A_din   ;
    logic [TAG_RAM_WIDTH-1   :0]         tag_ram_A_dout  ;
    logic                                tag_ram_B_wr_en ;
    logic [INDEX_WIDTH-1     :0]         tag_ram_B_addr  ;
    logic [TAG_RAM_WIDTH-1   :0]         tag_ram_B_din   ;
    logic [TAG_RAM_WIDTH-1   :0]         tag_ram_B_dout  ;
    
    logic tag_req_vld;
    
    logic [MSHR_ENTRY_NUM-1 :0] v_A_hazard_bitmap       ;
    logic [MSHR_ENTRY_NUM-1 :0] v_B_hazard_bitmap       ;
    logic                       cre_tag_req_vld         ;
    input_req_pld_t             cre_tag_req_pldA        ;
    input_req_pld_t             cre_tag_req_pldB        ;
    logic                       req_vld_A               ;
    logic                       req_vld_B               ;
    input_req_pld_t             req_pld_A               ;
    input_req_pld_t             req_pld_B               ;
    logic                       wr_buf_vld              ;
    logic                       wr_tag_buf_A_vld        ;
    logic                       wr_tag_buf_B_vld        ;
    //logic [TAG_WIDTH+1      :0] wr_tag_buf_A_pld        ;
    //logic [TAG_WIDTH+1      :0] wr_tag_buf_B_pld        ;
    wr_buf_pld_t                wr_tag_buf_A_pld        ;
    wr_buf_pld_t                wr_tag_buf_B_pld        ;
    logic [INDEX_WIDTH-1    :0] wr_tag_buf_A_index      ;
    logic [INDEX_WIDTH-1    :0] wr_tag_buf_B_index      ;


    logic                       A_is_write                      ;
    logic                       A_is_read                       ;
    logic                       B_is_write                      ;
    logic                       B_is_read                       ;
    logic                       tag_arrayA_dout_vld             ;  
    logic                       tag_arrayB_dout_vld             ;
    logic                       dest_wayA                       ;
    logic                       dest_wayB                       ;
    logic                       bypass_hazard_free              ;   
    logic [INDEX_WIDTH-1    :0] indexA                          ;
    logic [INDEX_WIDTH-1    :0] indexB                          ;
    logic [TAG_WIDTH+1      :0] tag_ram_A_byte_en               ;
    logic [TAG_WIDTH+1      :0] tag_ram_B_byte_en               ;
    logic [WAY_NUM-1        :0] A_dirty                         ;
    logic [WAY_NUM-1        :0] B_dirty                         ;
    logic [WAY_NUM-1        :0] A_valid                         ;
    logic [WAY_NUM-1        :0] B_valid                         ;
    logic                       A_need_evict                    ;
    logic                       B_need_evict                    ;
    logic [TAG_WIDTH-1      :0] A_evict_tag_array[WAY_NUM-1:0]  ;
    logic [TAG_WIDTH-1      :0] B_evict_tag_array[WAY_NUM-1:0]  ;
    logic [WAY_NUM-1        :0] tag_ram_A_hit_way_oh            ;
    logic [WAY_NUM-1        :0] A_hit_way_oh                    ;
    logic [WAY_NUM-1        :0] A_evict_way_oh                  ;
    logic [$clog2(WAY_NUM)-1:0] A_hit_way                       ;
    logic [WAY_NUM-1        :0] tag_ram_B_hit_way_oh            ;
    logic [WAY_NUM-1        :0] B_hit_way_oh                    ;
    logic [WAY_NUM-1        :0] B_evict_way_oh                  ;
    logic [$clog2(WAY_NUM)-1:0] B_hit_way                       ;
    logic [WAY_NUM-1        :0] A_dest_way_oh                   ;
    logic [WAY_NUM-1        :0] B_dest_way_oh                   ;
    logic [TAG_WIDTH-1      :0] A_evict_tag                     ;
    logic [TAG_WIDTH-1      :0] B_evict_tag                     ;
    logic [$clog2(WAY_NUM)-1:0] A_dest_way                      ;
    logic [$clog2(WAY_NUM)-1:0] B_dest_way                      ;
    logic [$clog2(WAY_NUM)-1:0] A_evict_way                     ;
    logic [$clog2(WAY_NUM)-1:0] B_evict_way                     ;
    logic [$clog2(WAY_NUM)-1:0] weight;
    logic                       A_wr_tag_buf_hit                ;
    logic                       B_wr_tag_buf_hit                ;
    logic                       A_tag_ram_hit                   ;
    logic                       B_tag_ram_hit                   ;
    logic                       A_hit                           ;
    logic                       B_hit                           ;
    logic                       A_miss                          ;
    logic                       B_miss                          ;
    logic                       A_hzd_checkpass                 ;
    logic                       B_hzd_checkpass                 ;
    logic [WAY_NUM-1        :0] A_wr_tag_buf_way_oh;
    logic [WAY_NUM-1        :0] B_wr_tag_buf_way_oh;

    assign tag_req_vld = tag_req_vld_1 || tag_req_vld_2;
    assign tag_req_rdy = (wr_buf_vld==1'b0) && (stall==1'b0);

//--------------------------------------------------------------
//          wresp decode to direction
//--------------------------------------------------------------

    wr_resp_direction_decode #(
        .WIDTH(4)
    ) u_wresp_decode_1(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (tag_req_vld                 ),
        .req_pld    (tag_req_input_arb_grant1_pld),
        .v_wresp_vld(v_wr_resp_vld_1             ),
        .v_wresp_pld(v_wr_resp_pld_1             ));

    wr_resp_direction_decode #(
        .WIDTH(4)
    ) u_wresp_decode_2(
        .clk        (clk                         ),
        .rst_n      (rst_n                       ),
        .req_vld    (tag_req_vld                 ),
        .req_pld    (tag_req_input_arb_grant2_pld),
        .v_wresp_vld(v_wr_resp_vld_2             ),
        .v_wresp_pld(v_wr_resp_pld_2             ));


//--------------------------------------------------------------
//          3 to 1 mux  to select wr buffer and new req
//--------------------------------------------------------------
    
    always_comb begin
        if(wr_tag_buf_A_vld | wr_tag_buf_B_vld)begin
            cre_tag_req_vld = 1'b0;
        end
        else if(wr_tag_buf_A_vld==1'b0 && wr_tag_buf_B_vld==1'b0 && tag_req_rdy)begin
            cre_tag_req_vld = tag_req_vld && tag_req_rdy ;
        end
        else begin
            cre_tag_req_vld = 1'b0;
        end
    end
    
    assign cre_tag_req_pldA = tag_req_input_arb_grant1_pld;
    assign cre_tag_req_pldB = tag_req_input_arb_grant2_pld;

    always_ff@(posedge clk or negedge rst_n) begin
        if(~rst_n)begin
            req_vld_A  <= 1'b0;
            req_vld_B  <= 1'b0;
        end
        else begin
            //req_vld_A <= cre_tag_req_vld;
            //req_vld_B <= cre_tag_req_vld;
            req_vld_A <= tag_req_vld_1 && tag_req_rdy;
            req_vld_B <= tag_req_vld_2 && tag_req_rdy;
        end
    end

    assign A_is_write       = req_vld_A && (req_pld_A.cmd_opcode == 1);
    assign A_is_read        = req_vld_A && (req_pld_A.cmd_opcode == 2);
    assign B_is_write       = req_vld_B && (req_pld_B.cmd_opcode == 1);
    assign B_is_read        = req_vld_B && (req_pld_B.cmd_opcode == 2);
    
    always_ff@(posedge clk or negedge rst_n)begin
        //if(tag_req_vld && tag_req_rdy)begin
        if(!rst_n)begin
            req_pld_A     <= '{default:'b0};
            req_pld_B      <= '{default:'b0};
        end
        else begin
            req_pld_A.cmd_addr      <= cre_tag_req_pldA.cmd_addr;
            req_pld_A.cmd_txnid     <= cre_tag_req_pldA.cmd_txnid;
            req_pld_A.cmd_sideband  <= cre_tag_req_pldA.cmd_sideband;
            req_pld_A.strb          <= cre_tag_req_pldA.strb;
            req_pld_A.cmd_opcode    <= cre_tag_req_pldA.cmd_opcode;
            req_pld_A.db_entry_id   <= cre_tag_req_pldA.db_entry_id;
            req_pld_A.rob_entry_id  <= mshr_alloc_idx_1;
            //req_pld_B <= cre_tag_req_pldB; 
            req_pld_B.cmd_addr      <= cre_tag_req_pldB.cmd_addr;
            req_pld_B.cmd_txnid     <= cre_tag_req_pldB.cmd_txnid;
            req_pld_B.cmd_sideband  <= cre_tag_req_pldB.cmd_sideband;
            req_pld_B.strb          <= cre_tag_req_pldB.strb;
            req_pld_B.cmd_opcode    <= cre_tag_req_pldB.cmd_opcode;
            req_pld_B.db_entry_id   <= cre_tag_req_pldB.db_entry_id;
            req_pld_B.rob_entry_id  <= mshr_alloc_idx_2;
        end
    end

//===========================================
//        update wr tag buffer
//===========================================
//vld -----miss need to enable wr_tag_buf
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            wr_tag_buf_A_vld <= 1'b0;
        end
        else begin
            if(A_miss )                 wr_tag_buf_A_vld <= 1'b1;
            else if(wr_tag_buf_A_vld)   wr_tag_buf_A_vld <= 1'b0;
            else                        wr_tag_buf_A_vld <=wr_tag_buf_A_vld;
        end
    end
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            wr_tag_buf_B_vld <= 1'b0;
        end
        else begin
            if(B_miss)                                           wr_tag_buf_B_vld <= 1'b1;
            else if(wr_tag_buf_A_vld==1'b0 && wr_tag_buf_B_vld)  wr_tag_buf_B_vld <= 1'b0;
            else                                                 wr_tag_buf_B_vld <= wr_tag_buf_B_vld;
        end
    end
    assign wr_buf_vld = wr_tag_buf_A_vld || wr_tag_buf_B_vld;
      
    always_ff@(posedge clk or negedge rst_n) begin //miss need to enable wr_tag_buf
        if(!rst_n)begin
            wr_tag_buf_A_pld <= '{default:'b0};
            wr_tag_buf_B_pld <= '{default:'b0};
        end
        else begin
            wr_tag_buf_A_pld.index <= req_pld_A.cmd_addr.index  ;
            wr_tag_buf_A_pld.tag   <= req_pld_A.cmd_addr.tag    ;
            wr_tag_buf_A_pld.way   <= A_evict_way               ;
            //wr_tag_buf_A_pld.dirty_bit<= A_dirty_bit;

            wr_tag_buf_B_pld.index <= req_pld_B.cmd_addr.index  ;
            wr_tag_buf_B_pld.tag   <= req_pld_B.cmd_addr.tag    ;
            wr_tag_buf_B_pld.way   <= B_evict_way               ;
            //wr_tag_buf_B_pld.dirty_bit<= B_dirty_bit;
        end
    end


    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM)
    ) u_bin2onehot_A (
        .bin_in    (wr_tag_buf_A_pld.way),
        .onehot_out(A_wr_tag_buf_way_oh )
    );
    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM)
    ) u_bin2onehot_B (
        .bin_in    (wr_tag_buf_B_pld.way),
        .onehot_out(B_wr_tag_buf_way_oh )
    );

//========================================================
//        tag  ram
//========================================================
    toy_mem_model_bit #(
        .ADDR_WIDTH  (INDEX_WIDTH  ),
        .DATA_WIDTH  (TAG_RAM_WIDTH)
    ) u_tag_ramA (
        .clk    (clk                ),
        .en     (tag_mem_en         ),
        .wr_en  (tag_ram_A_wr_en    ),
        .addr   (tag_ram_A_addr     ),
        .wr_data(tag_ram_A_din      ),
        .rd_data(tag_ram_A_dout     ));
    toy_mem_model_bit #(
        .ADDR_WIDTH  (INDEX_WIDTH),
        .DATA_WIDTH  (TAG_RAM_WIDTH)
    ) u_tag_ramB (
        .clk    (clk                ),
        .en     (tag_mem_en         ),
        .wr_en  (tag_ram_B_wr_en    ),
        .addr   (tag_ram_B_addr     ),
        .wr_data(tag_ram_B_din      ),
        .rd_data(tag_ram_B_dout     ));

    assign tag_ram_A_wr_en = wr_buf_vld;
    assign tag_ram_B_wr_en = wr_buf_vld;
    //assign tag_mem_en          = wr_buf_vld | cre_tag_req_vld_A | cre_tag_req_vld_B;
    assign tag_mem_en          = wr_buf_vld | cre_tag_req_vld;
    
    always_comb begin
        tag_ram_A_addr = 'b0;
        if(wr_tag_buf_A_vld)        tag_ram_A_addr = wr_tag_buf_A_pld.index;
        else if(wr_tag_buf_B_vld)   tag_ram_A_addr = wr_tag_buf_B_pld.index;
        else if(cre_tag_req_vld)    tag_ram_A_addr = cre_tag_req_pldA.cmd_addr.index;
    end
    
    always_comb begin
        tag_ram_B_addr = 'b0;
        if(wr_tag_buf_A_vld)        tag_ram_B_addr = wr_tag_buf_A_pld.index;
        else if(wr_tag_buf_B_vld)   tag_ram_B_addr = wr_tag_buf_B_pld.index;
        else if(cre_tag_req_vld)    tag_ram_B_addr = cre_tag_req_pldB.cmd_addr.index;
    end

    //TODO://need to add byte_wr_en to get real tag_ram_addr, byte_wr_en should be wr_tag_buf_pld.way
    //assign tag_ram_A_byte_en = wr_tag_buf_A_pld.way ? ;
    //assign tag_ram_B_byte_en = wr_tag_buf_B_pld.way;

    ///////
    logic [WAY_NUM-1:0]         tag_ram_dty[2**INDEX_WIDTH-1:0]  ;
    logic [INDEX_WIDTH-1:0]     A_tag_index;
    logic [INDEX_WIDTH-1:0]     B_tag_index;
    logic [2**INDEX_WIDTH-1:0]  A_tag_idx_ohot;
    logic [2**INDEX_WIDTH-1:0]  B_tag_idx_ohot;
    assign A_tag_index = req_pld_A.cmd_addr.index;
    assign B_tag_index = req_pld_B.cmd_addr.index;
    cmn_bin2onehot #(
       .BIN_WIDTH    (INDEX_WIDTH  ),
       .ONEHOT_WIDTH (2**INDEX_WIDTH)
    )u_tag_dty_idx_bin2onehot_A(
       .bin_in       (A_tag_index        ),
       .onehot_out   (A_tag_idx_ohot   )
    );
    cmn_bin2onehot #(
       .BIN_WIDTH    (INDEX_WIDTH  ),
       .ONEHOT_WIDTH (2**INDEX_WIDTH)
    )u_tag_dty_idx_bin2onehot_B(
       .bin_in       (B_tag_index        ),
       .onehot_out   (B_tag_idx_ohot   )
    );


    generate
        for(genvar i=0;i<2**INDEX_WIDTH;i=i+1)begin
            for(genvar j=0;j<WAY_NUM;j=j+1)begin
                always_ff@(posedge clk or negedge rst_n)begin//write->dirty
                    if(!rst_n) begin
                        tag_ram_dty[i][j] <= 1'b0;
                    end 
                    else if(req_vld_A && A_is_write && A_tag_idx_ohot[i] && A_dest_way_oh[j]) begin
                        tag_ram_dty[i][j] <= 1'b1; 
                    end
                    else if(req_vld_B && B_is_write && B_tag_idx_ohot[i] && B_dest_way_oh[j]) begin
                        tag_ram_dty[i][j] <= 1'b1; 
                    end
                    else if(req_vld_A && A_is_read && A_miss && A_tag_idx_ohot[i]&& A_evict_way_oh[j]) begin
                        tag_ram_dty[i][j] <= 1'b0; 
                    end 
                    else if(req_vld_B && B_is_read && B_miss && B_tag_idx_ohot[i]&& B_evict_way_oh[j]) begin
                        tag_ram_dty[i][j] <= 1'b0; 
                    end
                end
            end
        end
    endgenerate



    always_comb begin
        tag_ram_A_din = 'b0;
        tag_ram_B_din = 'b0;
        if(wr_tag_buf_A_vld)begin
            //tag_ram_A_din = {wr_tag_buf_A_pld.tag,1'b1,wr_tag_buf_A_pld.dirty_bit};//{tag,vld,dirty}
            //tag_ram_B_din = {wr_tag_buf_A_pld.tag,1'b1,wr_tag_buf_A_pld.dirty_bit};
            tag_ram_A_din = {wr_tag_buf_A_pld.tag,1'b1};//{tag,vld,dirty}
            tag_ram_B_din = {wr_tag_buf_A_pld.tag,1'b1};
        end
        else if(wr_tag_buf_A_vld==1'b0 && wr_tag_buf_B_vld)begin
            tag_ram_A_din = {wr_tag_buf_B_pld.tag,1'b1};
            tag_ram_B_din = {wr_tag_buf_B_pld.tag,1'b1};
        end
    end
//==========================================================
//evict_check——clean/dirty
//==========================================================
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            //assign A_dirty[i] = tag_ram_A_dout[i*TAG_WIDTH];//每个tag的最低位为dirty bit
            assign A_dirty[i] = tag_ram_dty[req_pld_A.cmd_addr.index][i];//每个tag的最低位为dirty bit
        end
    endgenerate
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            //assign A_valid[i] = tag_ram_A_dout[i*TAG_WIDTH+1];//每个tag的第二低位为vld bit
            assign A_valid[i] = tag_ram_A_dout[i*TAG_WIDTH];//每个tag的最低位为vld bit
        end
    endgenerate
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign B_dirty[i] = tag_ram_dty[req_pld_B.cmd_addr.index][i];//每个tag的最低位为dirty bit
        end
    endgenerate
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign B_valid[i] = tag_ram_B_dout[i*TAG_WIDTH];//每个tag的最低位为vld bit
        end
    endgenerate

    assign A_need_evict = A_dirty[A_evict_way] && A_miss && A_valid[A_evict_way];
    assign B_need_evict = B_dirty[B_evict_way] && B_miss && B_valid[B_evict_way];
//===========================================
//        hit/miss check
//===========================================
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin //read out the data of [req_pld_A.addr]
            //assign A_evict_tag_array[i] = tag_ram_A_dout[i*TAG_WIDTH+TAG_WIDTH+1:i*TAG_WIDTH+2];//每一路的低两位位vld和dirty，实际tag[TAG_WIDTH+2-1:2]
            assign A_evict_tag_array[i] = tag_ram_A_dout[i*TAG_WIDTH+TAG_WIDTH+1-1:i*TAG_WIDTH+1];//每一路的低位vld，实际tag[TAG_WIDTH+1-1:1]
        end
    endgenerate
    generate
        for(genvar i=0;i<WAY_NUM;i=i+1)begin //read out the data of [req_pld_B.addr]
            //assign B_evict_tag_array[i] = tag_ram_B_dout[i*TAG_WIDTH+TAG_WIDTH+1:i*TAG_WIDTH+2];
            assign B_evict_tag_array[i] = tag_ram_B_dout[i*TAG_WIDTH+TAG_WIDTH+1-1:i*TAG_WIDTH+1];
        end
    endgenerate

    logic [WAY_NUM-1:0] tag_ram_A_hit_way_vld;
    logic [WAY_NUM-1:0] tag_ram_B_hit_way_vld;
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_A_hit_way_vld[i] = tag_ram_A_dout[i*TAG_INFO_WIDTH];
        end
    endgenerate
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_B_hit_way_vld[i] = tag_ram_B_dout[i*TAG_INFO_WIDTH];
        end
    endgenerate
    
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_A_hit_way_oh[i] = tag_ram_A_hit_way_vld[i] && (req_pld_A.cmd_addr.tag == A_evict_tag_array[i]);
        end
    endgenerate
    assign A_hit_way_oh = A_wr_tag_buf_hit ? A_wr_tag_buf_way_oh : tag_ram_A_hit_way_oh;//hit ram or hit wr_tag_buf
    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WAY_NUM)
    ) u_A_hit_way_oh2bin (
        .onehot_in (A_hit_way_oh),
        .bin_out   (A_hit_way   )
    );

    
    generate 
        for(genvar i=0;i<WAY_NUM;i=i+1)begin
            assign tag_ram_B_hit_way_oh[i] = tag_ram_B_hit_way_vld[i] && (req_pld_B.cmd_addr.tag == B_evict_tag_array[i]);
        end
    endgenerate
    assign B_hit_way_oh = B_wr_tag_buf_hit ? B_wr_tag_buf_way_oh : tag_ram_B_hit_way_oh;

    cmn_onehot2bin #(
        .ONEHOT_WIDTH(WAY_NUM)
    ) u_B_hit_way_oh2bin (
        .onehot_in (B_hit_way_oh),
        .bin_out   (B_hit_way)
    );
    
    assign A_wr_tag_buf_hit = req_vld_A && (((req_pld_A.cmd_addr.tag==wr_tag_buf_A_pld.tag)&&(req_pld_A.cmd_addr.index== wr_tag_buf_A_pld.index)) || ((req_pld_A.cmd_addr.tag==wr_tag_buf_B_pld.tag)&&(req_pld_A.cmd_addr.index== wr_tag_buf_B_pld.index)));
    assign B_wr_tag_buf_hit = req_vld_B && (((req_pld_B.cmd_addr.tag==wr_tag_buf_A_pld.tag)&&(req_pld_B.cmd_addr.index== wr_tag_buf_A_pld.index)) || ((req_pld_B.cmd_addr.tag==wr_tag_buf_B_pld.tag)&&(req_pld_B.cmd_addr.index== wr_tag_buf_B_pld.index)));
    
    assign A_tag_ram_hit = |tag_ram_A_hit_way_oh;
    assign B_tag_ram_hit = |tag_ram_B_hit_way_oh;

    assign A_hit  = A_tag_ram_hit || A_wr_tag_buf_hit;
    assign B_hit  = B_tag_ram_hit || B_wr_tag_buf_hit;

    assign A_miss = ~A_hit && req_vld_A;
    assign B_miss = ~B_hit && req_vld_B;

    assign A_dest_way_oh = A_hit ? A_hit_way_oh : A_evict_way_oh;
    assign B_dest_way_oh = B_hit ? B_hit_way_oh : B_evict_way_oh;

    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            if(A_dest_way_oh[i]==1'b1)begin
                A_evict_tag = A_evict_tag_array[i];
            end
        end
    end
    always_comb begin
        for(int i=0;i<WAY_NUM;i=i+1)begin
            if(B_dest_way_oh[i]==1'b1)begin
                B_evict_tag = B_evict_tag_array[i];
            end
        end
    end 

//========================================================
//         hazard check and behavior mapping 
//========================================================
    //always_comb begin
    //    mshr_update_en = 1'b0;
    //    //if(req_vld_A | req_vld_B)begin
    //    if(cre_tag_req_vld)begin
    //        mshr_update_en = 1'b1;
    //    end
    //end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)               mshr_update_en <= 1'b0;
        else if(cre_tag_req_vld) mshr_update_en <= 1'b1;
        else                     mshr_update_en <= 1'b0;

    end     
//========================================================    

//address hazard check
    generate 
        for(genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin:reqA_addr_hazard_check
            always_comb begin
                v_A_hazard_bitmap[i] = 0;
                if(mshr_update_en)begin
                    //if((i==mshr_alloc_idx_1) | (i==entry_release_done_index[MSHR_ENTRY_IDX_WIDTH-1:0]))begin
                    if((i==req_pld_A.rob_entry_id) | (i==entry_release_done_index[MSHR_ENTRY_IDX_WIDTH-1:0]))begin
                        v_A_hazard_bitmap[i] = 1'b0; 
                    end
                    //else if(v_mshr_entry_pldy[i].valid &&(req_pld_A.addr==v_mshr_entry_pld[i].pld.addr))begin
                    else if(v_mshr_entry_pld[i].valid &&(req_pld_A.cmd_addr.index==v_mshr_entry_pld[i].index) &&((req_pld_A.cmd_addr.tag==v_mshr_entry_pld[i].req_tag)|| (A_need_evict && (req_pld_A.cmd_addr.tag==v_mshr_entry_pld[i].evict_tag))))begin
                        v_A_hazard_bitmap[i] = 1'b1;
                    end
                end
            end
        end
    endgenerate
    assign A_hzd_checkpass = ((|v_A_hazard_bitmap)==1'b0);//bypass req,no dependency

    generate //reqB address hazard check
        for(genvar i=0;i<MSHR_ENTRY_NUM;i=i+1)begin:reqB_addr_hazard_check
            always_comb begin
                v_B_hazard_bitmap[i] = 0;
                if(mshr_update_en)begin
                    //if((i==mshr_alloc_idx_2) | (i==entry_release_done_index[MSHR_ENTRY_IDX_WIDTH-1:0]))begin
                    if((i==req_pld_B.rob_entry_id) | (i==entry_release_done_index[MSHR_ENTRY_IDX_WIDTH-1:0]))begin
                        v_B_hazard_bitmap[i] = 1'b0; 
                    end
                    else if(v_mshr_entry_pld[i].valid &&(req_pld_B.cmd_addr.index==v_mshr_entry_pld[i].index) &&((req_pld_B.cmd_addr.tag==v_mshr_entry_pld[i].req_tag)|| (B_need_evict && (req_pld_B.cmd_addr.tag==v_mshr_entry_pld[i].evict_tag))))begin
                        v_B_hazard_bitmap[i] = 1'b1;
                    end
                end
            end
        end
    endgenerate

    assign B_hzd_checkpass                 = ((|v_B_hazard_bitmap)==1'b0)   ; //bypass req,no dependency
    assign A_dest_way                      = A_hit ? A_hit_way : A_evict_way;
    assign B_dest_way                      = B_hit ? B_hit_way : B_evict_way;

    //mshr_entry pld
    assign mshr_update_pld_A.txnid         = req_pld_A.cmd_txnid      ;//direction-master 
    assign mshr_update_pld_A.sideband      = req_pld_A.cmd_sideband   ;
    assign mshr_update_pld_A.index         = req_pld_A.cmd_addr.index ;
    assign mshr_update_pld_A.offset        = req_pld_A.cmd_addr.offset;
    assign mshr_update_pld_A.req_tag       = req_pld_A.cmd_addr.tag   ;
    assign mshr_update_pld_A.way           = A_dest_way               ;
    assign mshr_update_pld_A.is_read       = A_is_read                ;
    assign mshr_update_pld_A.is_write      = A_is_write               ;
    assign mshr_update_pld_A.hit           = A_hit                    ;
    assign mshr_update_pld_A.need_linefill = A_miss                   ;
    assign mshr_update_pld_A.need_evict    = A_need_evict             ;
    assign mshr_update_pld_A.evict_tag     = A_evict_tag              ;
    assign mshr_update_pld_A.hzd_bitmap    = v_A_hazard_bitmap        ;
    assign mshr_update_pld_A.hzd_pass      = A_hzd_checkpass          ;
    assign mshr_update_pld_A.alloc_idx     = req_pld_A.rob_entry_id   ; 
    assign mshr_update_pld_A.wdb_entry_id  = req_pld_A.db_entry_id    ;//只有write在输入带

    assign mshr_update_pld_B.txnid         = req_pld_B.cmd_txnid      ;
    assign mshr_update_pld_B.sideband      = req_pld_B.cmd_sideband   ;
    assign mshr_update_pld_B.index         = req_pld_B.cmd_addr.index ;
    assign mshr_update_pld_B.offset        = req_pld_B.cmd_addr.offset;
    assign mshr_update_pld_B.req_tag       = req_pld_B.cmd_addr.tag   ;
    assign mshr_update_pld_B.way           = B_dest_way               ;
    assign mshr_update_pld_B.is_read       = B_is_read                ;
    assign mshr_update_pld_B.is_write      = B_is_write               ;
    assign mshr_update_pld_B.hit           = B_hit                    ;
    assign mshr_update_pld_B.need_linefill = B_miss                   ;
    assign mshr_update_pld_B.need_evict    = B_need_evict             ;
    assign mshr_update_pld_B.evict_tag     = B_evict_tag              ;
    assign mshr_update_pld_B.hzd_bitmap    = v_B_hazard_bitmap        ;
    assign mshr_update_pld_B.hzd_pass      = B_hzd_checkpass          ;
    assign mshr_update_pld_B.alloc_idx     = req_pld_B.rob_entry_id   ;
    assign mshr_update_pld_B.wdb_entry_id  = req_pld_B.db_entry_id    ;

//========================================================
//             lru weight update 
//========================================================
    assign  indexA        = req_pld_A.cmd_addr.index;
    assign  indexB        = req_pld_B.cmd_addr.index;

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
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM        )
    ) u_evict_way_oh_A (
        .bin_in    (A_evict_way     ),
        .onehot_out(A_evict_way_oh  )
    );
    cmn_bin2onehot #(
        .BIN_WIDTH   ($clog2(WAY_NUM)),
        .ONEHOT_WIDTH(WAY_NUM        )
    ) u_evict_way_oh_B (
        .bin_in    (B_evict_way     ),
        .onehot_out(B_evict_way_oh  )
    );

////=========================================================
////             bypass read data ram (hazard_free) 
////=========================================================





















//===========================================
//===========================================
    logic [63:0] counter_hit;
    logic [63:0] counter_req;
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter_req <= 64'd0;
        end
        else begin
            if(cre_tag_req_vld) counter_req <= counter_req + 64'd1;
            else                counter_req <= counter_req;
        end
    end
    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            counter_hit <= 64'd0;
        end
        else begin
            if(A_hit && B_hit) counter_hit <= counter_hit + 64'd1;
            else               counter_hit <= counter_hit;
        end
    end


endmodule

