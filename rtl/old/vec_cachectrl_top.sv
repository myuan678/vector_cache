module vec_cache_top
    import vector_cache_pkg::*;
(
    input  logic clk,
    input  logic rst_n,

//-----------------------------------------------------------------------------
//              upstream interface
//-----------------------------------------------------------------------------
//WDATA+WCMD: W/E/S/N
//RCMD:W/E/S/N
//Resp: W/E/S/N
//RDATA: W/E/S/N

    //direction west WR
    input  logic [WR_REQ_NUM-1      :0] w_rd_cmd_vld                           ,
    output logic [WR_REQ_NUM-1      :0] w_rd_cmd_rdy                           ,
    input  logic [63                :0] w_rd_addr           [WR_REQ_NUM-1:0]   ,
    input  logic [ID_WIDTH-1        :0] w_rd_cmd_txnid      [WR_REQ_NUM-1:0]   ,
    input  logic [SIDEBAND_WIDTH-1  :0] w_rd_sideband       [WR_REQ_NUM-1:0]   ,

    //direction east
    input  logic [ER_REQ_NUM-1      :0] e_rd_cmd_vld                          ,
    output logic [ER_REQ_NUM-1      :0] e_rd_cmd_rdy                          ,
    input  logic [63                :0] e_rd_addr           [ER_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] e_rd_cmd_txnid      [ER_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] e_rd_sideband       [ER_REQ_NUM-1:0]  ,

    //direction south
    input  logic [SR_REQ_NUM-1      :0] s_rd_cmd_vld                          ,
    output logic [SR_REQ_NUM-1      :0] s_rd_cmd_rdy                          ,
    input  logic [63                :0] s_rd_addr           [SR_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] s_rd_cmd_txnid      [SR_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] s_rd_sideband       [SR_REQ_NUM-1:0]  ,

    //direction north
    input  logic [NR_REQ_NUM-1      :0] n_rd_cmd_vld                          ,
    output logic [NR_REQ_NUM-1      :0] n_rd_cmd_rdy                          ,
    input  logic [63                :0] n_rd_addr           [NR_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] n_rd_cmd_txnid      [NR_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] n_rd_sideband       [NR_REQ_NUM-1:0]  ,


    input  logic [WW_REQ_NUM-1      :0] w_wr_cmd_vld                          ,
    output logic [WW_REQ_NUM-1      :0] w_wr_cmd_rdy                          ,
    input  logic [63                :0] w_wr_addr           [WW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] w_wr_data           [WW_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] w_wr_cmd_txnid      [WW_REQ_NUM-1:0]  ,
    input  logic [127               :0] w_strb              [WW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] w_wr_sideband       [WW_REQ_NUM-1:0]  ,

    input  logic [EW_REQ_NUM-1      :0] e_wr_cmd_vld                          ,
    output logic [EW_REQ_NUM-1      :0] e_wr_cmd_rdy                          ,
    input  logic [63                :0] e_wr_addr           [EW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] e_wr_data           [EW_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] e_wr_cmd_txnid      [EW_REQ_NUM-1:0]  ,
    input  logic [127               :0] e_strb              [EW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] e_wr_sideband       [EW_REQ_NUM-1:0]  ,

    input  logic [SW_REQ_NUM-1      :0] s_wr_cmd_vld                          ,
    output logic [SW_REQ_NUM-1      :0] s_wr_cmd_rdy                          ,
    input  logic [63                :0] s_wr_addr           [SW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] s_wr_data           [SW_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] s_wr_cmd_txnid      [SW_REQ_NUM-1:0]  ,
    input  logic [127               :0] s_strb              [SW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] s_wr_sideband       [SW_REQ_NUM-1:0]  ,

    input  logic [NW_REQ_NUM-1      :0] n_wr_cmd_vld                          ,
    output logic [NW_REQ_NUM-1      :0] n_wr_cmd_rdy                          ,
    input  logic [63                :0] n_wr_addr           [NW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] n_wr_data           [NW_REQ_NUM-1:0]  ,
    input  logic [ID_WIDTH-1        :0] n_wr_cmd_txnid      [NW_REQ_NUM-1:0]  ,
    input  logic [127               :0] n_strb              [NW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] n_wr_sideband       [NW_REQ_NUM-1:0]  ,


    output logic [WB_REQ_NUM-1      :0] w_resp_vld,
    output logic [ID_WIDTH-1        :0] w_resp_txnid        [WB_REQ_NUM-1      :0],
    output logic [SIDEBAND_WIDTH-1  :0] w_resp_sideband     [WB_REQ_NUM-1      :0],

    output logic [EB_REQ_NUM-1      :0] e_resp_vld,
    output logic [ID_WIDTH-1        :0] e_resp_txnid        [EB_REQ_NUM-1      :0],
    output logic [SIDEBAND_WIDTH-1  :0] e_resp_sideband     [EB_REQ_NUM-1      :0],

    output logic [SB_REQ_NUM-1      :0] s_resp_vld,
    output logic [ID_WIDTH-1        :0] s_resp_txnid        [SB_REQ_NUM-1      :0],
    output logic [SIDEBAND_WIDTH-1  :0] s_resp_sideband     [SB_REQ_NUM-1      :0],

    output logic [NB_REQ_NUM-1      :0] n_resp_vld,
    output logic [ID_WIDTH-1        :0] n_resp_txnid        [NB_REQ_NUM-1      :0],
    output logic [SIDEBAND_WIDTH-1  :0] n_resp_sideband     [NB_REQ_NUM-1      :0],

    output logic [WRD_REQ_NUM-1     :0] w_rd_data_vld,
    output logic [ID_WIDTH-1        :0] w_rd_data_txnid     [WRD_REQ_NUM-1     :0],
    output logic [1023              :0] w_rd_data           [WRD_REQ_NUM-1     :0],
    output logic [SIDEBAND_WIDTH-1  :0] w_rd_data_sideband  [WRD_REQ_NUM-1     :0],
    input  logic [WRD_REQ_NUM-1     :0] w_rd_data_rdy                             ,

    output logic [ERD_REQ_NUM-1     :0] e_rd_data_vld,
    output logic [ID_WIDTH-1        :0] e_rd_data_txnid     [ERD_REQ_NUM-1     :0],
    output logic [1023              :0] e_rd_data           [ERD_REQ_NUM-1     :0],
    output logic [SIDEBAND_WIDTH-1  :0] e_rd_data_sideband  [ERD_REQ_NUM-1     :0],
    input  logic [ERD_REQ_NUM-1     :0] e_rd_data_rdy,

    output logic [SRD_REQ_NUM-1     :0] s_rd_data_vld,
    output logic [ID_WIDTH-1        :0] s_rd_data_txnid     [SRD_REQ_NUM-1     :0],
    output logic [1023              :0] s_rd_data           [SRD_REQ_NUM-1     :0],
    output logic [SIDEBAND_WIDTH-1  :0] s_rd_data_sideband  [SRD_REQ_NUM-1     :0],
    input  logic [SRD_REQ_NUM-1     :0] s_rd_data_rdy,

    output logic [NRD_REQ_NUM-1     :0] n_rd_data_vld,
    output logic [ID_WIDTH-1        :0] n_rd_data_txnid     [NRD_REQ_NUM-1     :0],
    output logic [1023              :0] n_rd_data           [NRD_REQ_NUM-1     :0],
    output logic [SIDEBAND_WIDTH-1  :0] n_rd_data_sideband  [NRD_REQ_NUM-1     :0],
    input  logic [NRD_REQ_NUM-1     :0] n_rd_data_rdy,


//-------------------------------------------------------------------------------------
//              downstream interface
//-------------------------------------------------------------------------------------
    //AR
    output logic down_txreq_vld,
    //input  logic down_txreq_rdy,
    input  logic ds_input_txreq_rdy,
    output logic down_txreq_pld, // addr+txnid+sideband+xxxx

    //AW+W
    output logic evict_down_vld,
    //input  logic evict_down_rdy,
    input  logic ds_input_evict_rdy,
    output logic evict_down_pld,// data+txnid+addr+sideband+xxxx

    //R
    input  logic rxdata_vld,
    input  logic rxdata_pld,
    output logic rxdata_rdy,

    //Bresp
    input  logic bresp_vld,
    input  logic bresp_pld,//txnid+sideband
    output logic bresp_rdy

);

    logic [3:0] v_down_txreq_vld;
    logic [3:0] v_down_txreq_rdy;
    logic [3:0] v_down_txreq_pld; // addr+txnid+sideband+xxxx


// four direction read request nto4 xbar
    req_xbar_read #(
        .REQ_NUM()
    ) u_west_read_req_xbar(
        .clk()
    );
    req_xbar_read #(
        .REQ_NUM()
    ) u_east_read_req_xbar(
        .clk()
    );
    req_xbar_read #(
        .REQ_NUM()
    ) u_south_read_req_xbar(
        .clk()
    );
    req_xbar_read #(
        .REQ_NUM()
    ) u_north_read_req_xbar(
        .clk()
    );

// four direction write request nto4 xbar
    req_xbar_write #(
        .REQ_NUM()
    ) u_west_write_req_xbar(
        .clk()
    );
    req_xbar_write #(
        .REQ_NUM()
    ) u_east_write_req_xbar(
        .clk()
    );
    req_xbar_write #(
        .REQ_NUM()
    ) u_south_write_req_xbar(
        .clk()
    );
    req_xbar_write #(
        .REQ_NUM()
    ) u_north_write_req_xbar(
        .clk()
    );

    generate
        for(genvar i=0;i<4;i=i+1)begin:hash_cache_ctrl_gen
            vec_cache_ctrl u_hash0_cache_ctrl(
                .clk            (clk                ),
                .rst_n          (rst_n              ),
                //-----input requst----------
                .tag_req_vld    (),
                .tag_req_input_arb_grant1_pld(),// 8to2 双输入请求
                .tag_req_input_arb_grant2_pld(),// 8to2 双输入请求
                .tag_req_rdy   (),
                .tag_req_index1 (),//preallocate 2entry
                .tag_req_index2 (),//preallocate 2entry
                .vv_mshr_entry_array(),

                .A_wr_resp_vld  (v_A_wr_resp_vld[i] ),  
                .A_wr_resp_pld  (v_A_wr_resp_pld[i] ),
                .A_wr_resp_rdy  (v_A_wr_resp_rdy[i] ),
                .B_wr_resp_vld  (v_B_wr_resp_vld[i] ),
                .B_wr_resp_pld  (v_B_wr_resp_pld[i] ),
                .B_wr_resp_rdy  (v_B_wr_resp_rdy[i] ),

                //add arb interface--------------------

                //-------------------------------------
                .down_txreq_vld (v_down_txreq_vld[i]),//AR
                .down_txreq_rdy (v_down_txreq_rdy[i]),//AR
                .down_txreq_pld (v_down_txreq_pld[i]),//AR
 
                .rx_to_lfdb_vld  (v_rxdata_vld[i]   ),//R
                .rx_to_lfdb_pld  (v_rxdata_pld[i]   ),//R
                .rx_to_lfdb_rdy  (v_rxdata_rdy[i]   ),//R
                .lfdb_to_ram_vld (),//out to ram
                .lfdb_to_ram_pld (),//out to ram
                .lfdb_to_ram_rdy (),//out to ram

                .ram_to_evdb_vld (),//from ram input
                .ram_to_evdb_pld (),//from ram input
                .ram_to_evdb_rdy (),//from ram input
                .evict_down_vld  (v_evict_down_vld[i]),//out to ds, AW+W
                .evict_down_pld  (v_evict_down_pld[i]),//out to ds, AW+W
                .evict_down_rdy  (v_evict_down_rdy[i]),//from evict arb, AW+W

                .bresp_vld       (v_resp_vld[i]     ),//Bresp evict done signal to mshr
                .bresp_pld       (v_resp_pld[i]     ),//Bresp evict done signal to mshr
                .bresp_rdy       (v_resp_rdy[i]     ),//out to ds
            );
        end
    endgenerate


//---------------------------------------------------------------------------------------    
    //wresp_decode
    //双发rob Wresp to upstream 应该是wreq进入rob就会resp,两个resp分别做decode
    //然后再decode到具体的master，就是根据master_id 做1toN的decode？所以4方向各一个1toNmaster
    generate
        for (genvar i=0;i<4;i=i+1)begin:hash
            for(genvar j=0;j<4;j=j+1)begin:direct
                v_1toN_decode #(
                    .WIDTH(4)
                ) u_decode_to_fourdirection (
                    .vld      (v_A_wr_resp_vld[i]      ),
                    .vld_index(v_A_wr_resp_pld[i]      ),//wresp pld 中的direction id
                    .v_out_vld(vv_direction_vld_A[i][j])
                );
                v_1toN_decode #(
                    .WIDTH(4)
                ) u_decode_to_fourdirection (
                    .vld      (v_B_wr_resp_vld[i]      ),
                    .vld_index(v_B_wr_resp_pld[i]      ),//wresp pld 中的direction id
                    .v_out_vld(vv_direction_vld_B[i][j])
                );
            end
        end
    endgenerate
    //v_1toN_decode #(
    //    .WIDTH(4)
    //) u_decode_to_fourdirection (
    //    .vld      (A_wr_resp_vld      ),
    //    .vld_index(A_wr_resp_pld      ),//wresp pld 中的direction id
    //    .v_out_vld(v_direction_vld_A  )
    //);
    //v_1toN_decode #(
    //    .WIDTH(4)
    //) u_decode_to_fourdirection (
    //    .vld      (B_wr_resp_vld     ),
    //    .vld_index(B_wr_resp_pld     ),//wresp pld 中的direction id
    //    .v_out_vld(v_direction_vld_B )
    //);
//---------------------------------------------------------------------------------------  

    
    
    

    
    // Bresp  //EVICT done resp
    


//TODO: 4 hash 信号连接--------------------------------------------------------------------
generate
    for(genvar i=0;i<4;i=i+1)begin
     //linefill data buffer 
        linefillDB u_linefill_DB(
            .clk                    (clk               ),
            .rst_n                  (rst_n             ),
            .linefill_data_done     (linefill_data_done),//linefill data done ack to mshr ROB，it means linefill can hands up for arb 
            .linefill_data_done_idx (linefill_done_idx ),
            .linefill_to_ram_done   (linefill_done     ),//linefill done ack to mshr ROB，it means linefill data write into data ram
            .linefill_to_ram_done_idx(linefill_done_idx),
            .rx_to_lfdb_vld         (rx_to_lfdb_vld    ),
            .rx_to_lfdb_rdy         (rx_to_lfdb_rdy    ),
            .rx_to_lfdb_pld         (rx_to_lfdb_pld    ),
            .lfdb_rdreq_vld         (),//from ram
            .lfdb_rdreq_pld         (),//from_arb
            .lfdb_rdreq_rdy         (),//from ram
            .alloc_idx              (linefill_alloc_idx),
            .alloc_vld              (linefill_alloc_vld),
            .alloc_rdy              (linefill_alloc_rdy),
            .lfdb_to_ram_pld        (lfdb_to_ram_pld   ),//to data sram
            .lfdb_to_ram_vld        (lfdb_to_ram_vld   ),//to data sram
            .lfdb_to_ram_rdy        (lfdb_to_ram_rdy   )//to data sram
        );
    end
endgenerate
generate
    for(genvar i=0;i<4;i=i+1)begin
        evictDB u_evictl_DB(
            .clk              (clk               ),
            .rst_n            (rst_n             ),
            .evict_down_vld   (evict_down_vld    ),//somewhere input evict enable
            .evict_down_rdy   (evict_down_rdy    ),//somewhere input evict enable
            .evict_down_pld   (evict_down_pld    ),
            .ram_to_evdb_pld  (ram_to_evdb_pld   ),//from ram
            .ram_to_evdb_vld  (ram_to_evdb_vld   ),//from_arb
            .ram_to_evdb_rdy  (ram_to_evdb_rdy   ),//from down
            .alloc_idx        (evdb_alloc_idx    ),
            .alloc_vld        (evdb_alloc_vld    ),
            .alloc_rdy        (evdb_alloc_rdy    ),
            .evict_to_ds_vld  (evict_to_ds_vld   ),
            .evict_to_ds_pld  (evict_to_ds_pld   ),
            .evict_to_ds_rdy  (evict_to_ds_rdy   ),
            .evict_clean      (evict_clean       ),
            .evict_clean_idx  (evict_clean_idx   )
        );
    end
endgenerate
//----------------------------------------------------------------------------------------




endmodule