module pre_alloc_two
    #(
        parameter integer unsigned ENTRY_NUM = 32,
        parameter integer unsigned ENTRY_ID_WIDTH = $clog2(ENTRY_NUM),
        parameter integer unsigned PRE_ALLO_NUM = 2
    )
(
    input  logic                       clk        ,
    input  logic                       rst_n      ,
    input  logic [ENTRY_NUM-1     :0]  v_in_vld   ,
    output logic [ENTRY_NUM-1     :0]  v_in_rdy   ,
    output logic                       out_vld    ,
    input  logic                       out_rdy    ,
    output logic [ENTRY_ID_WIDTH-1:0]  out_index_1,
    output logic [ENTRY_ID_WIDTH-1:0]  out_index_2
);

    logic [ENTRY_ID_WIDTH-1:0]  free_mshr_id_1    ;
    logic [ENTRY_NUM-1     :0]  free_mshr_oh_1    ;
    logic                       free_mshr_vld_1   ;
    logic [ENTRY_ID_WIDTH-1:0]  free_mshr_id_2    ;
    logic [ENTRY_NUM-1     :0]  free_mshr_oh_2    ;
    logic                       free_mshr_vld_2   ;
    logic                       mshr_id_wr        ;
    logic                       mshr_id_rd        ;
    logic                       pre_allo_buf_empty;
    logic                       pre_allo_buf_full ;
    logic [ENTRY_ID_WIDTH*2-1:0]out_index         ;


    cmn_lead_two #(
        .ENTRY_NUM (ENTRY_NUM)
    ) u_cmn_lead_two(
        .v_entry_vld      (v_in_vld        ),
        .v_free_idx_oh_1  (free_mshr_oh_1  ),
        .v_free_idx_bin_1 (free_mshr_id_1  ),
        .v_free_vld_1     (free_mshr_vld_1 ),
        .v_free_idx_oh_2  (free_mshr_oh_2  ),
        .v_free_idx_bin_2 (free_mshr_id_2  ),
        .v_free_vld_2     (free_mshr_vld_2 )
    );
    assign v_in_rdy   = (free_mshr_vld_1 && free_mshr_vld_2 && !pre_allo_buf_full) ? (free_mshr_oh_1 | free_mshr_oh_2) : {ENTRY_NUM{1'b0}};

    logic [ENTRY_ID_WIDTH*2-1:0] two_free_id                ;
    assign two_free_id = {free_mshr_id_1, free_mshr_id_2}   ;
    assign mshr_id_wr = free_mshr_vld_1 && free_mshr_vld_2  ;
    assign mshr_id_rd = out_vld && out_rdy                  ;

    fifo#(
        .DATA_WIDTH(ENTRY_ID_WIDTH),
        .ADDR_WIDTH(PRE_ALLO_NUM   )
    )u_fifo(
        .clk   (clk                  ),
        .rst_n (rst_n                ),
        .wr_ena(mshr_id_wr           ),
        .rd_ena(mshr_id_rd           ),
        .din   (two_free_id          ),
        .dout  (out_index            ),
        .full  (pre_allo_buf_full    ),
        .empty (pre_allo_buf_empty   )
    );
    assign out_vld     = !pre_allo_buf_empty                         ;
    assign out_index_1 = out_index[ENTRY_ID_WIDTH-1:0]               ;
    assign out_index_2 = out_index[ENTRY_ID_WIDTH*2-1:ENTRY_ID_WIDTH];

endmodule