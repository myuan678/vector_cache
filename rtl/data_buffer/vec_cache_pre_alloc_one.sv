module vec_cache_pre_alloc_one #(
    parameter integer unsigned ENTRY_NUM = 32,
    parameter integer unsigned ENTRY_ID_WIDTH = $clog2(ENTRY_NUM),
    parameter integer unsigned PRE_ALLO_NUM = 1
) (
    input  logic                        clk               ,
    input  logic                        rst_n             ,
    input  logic [ENTRY_NUM-1       :0] v_in_vld          ,
    output logic [ENTRY_NUM-1       :0] v_in_rdy          ,
    output logic                        out_vld           ,
    input  logic                        out_rdy           ,
    output logic [ENTRY_ID_WIDTH-1  :0] out_index
);
//------
//---signals
//------
    logic [ENTRY_ID_WIDTH-1 :0] free_mshr_id        ;
    logic [ENTRY_NUM-1      :0] free_mshr_oh        ;
    logic                       free_mshr_vld       ;

    logic mshr_id_wr                                ;
    logic mshr_id_rd                                ;
    logic pre_allo_buf_empty                        ;
    logic pre_allo_buf_full                         ;

    cmn_lead_one #(
        .ENTRY_NUM (ENTRY_NUM)
    ) u_cmn_lead_one(
        .v_entry_vld    (v_in_vld           ),
        .v_free_idx_oh  (free_mshr_oh       ),
        .v_free_idx_bin (free_mshr_id       ),
        .v_free_vld     (free_mshr_vld      )
    );
    assign v_in_rdy   = (free_mshr_vld && !pre_allo_buf_full) ? free_mshr_oh : {ENTRY_ID_WIDTH{1'b0}};

    assign mshr_id_wr = free_mshr_vld      ;
    assign mshr_id_rd = out_vld && out_rdy ;

    fifo#(
        .DATA_WIDTH(ENTRY_ID_WIDTH),
        .ADDR_WIDTH(PRE_ALLO_NUM     )
    )u_fifo(
        .clk   (clk                  ),
        .rst_n (rst_n                ),
        .wr_ena(mshr_id_wr           ),
        .rd_ena(mshr_id_rd           ),
        .din   (free_mshr_id         ),
        .dout  (out_index            ),
        .full  (pre_allo_buf_full    ),
        .empty (pre_allo_buf_empty   )
    );
    assign  out_vld = !pre_allo_buf_empty;

endmodule