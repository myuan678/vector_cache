//module pre_alloc_two
//    #(
//        parameter integer unsigned ENTRY_NUM = 32,
//        parameter integer unsigned ENTRY_ID_WIDTH = $clog2(ENTRY_NUM),
//        parameter integer unsigned PRE_ALLO_NUM = 2
//    )(
//    input  logic                       clk          ,
//    input  logic                       rst_n        ,
//    input  logic [ENTRY_NUM-1     :0]  v_in_vld     ,
//    output logic [ENTRY_NUM-1     :0]  v_in_rdy     ,
//    output logic                       out_vld_0    ,
//    input  logic                       out_rdy_0    ,
//    output logic [ENTRY_ID_WIDTH-1:0]  out_idx_0    ,
//    output logic                       out_vld_1    ,
//    input  logic                       out_rdy_1    ,
//    output logic [ENTRY_ID_WIDTH-1:0]  out_idx_1
//);
//
//    logic [ENTRY_ID_WIDTH-1:0]  free_mshr_id_0    ;
//    logic [ENTRY_NUM-1     :0]  free_mshr_oh_0    ;
//    logic                       free_mshr_vld_0   ;
//    logic [ENTRY_ID_WIDTH-1:0]  free_mshr_id_1    ;
//    logic [ENTRY_NUM-1     :0]  free_mshr_oh_1    ;
//    logic                       free_mshr_vld_1   ;
//    logic                       mshr_id_wr        ;
//    logic                       mshr_id_rd        ;
//    logic                       pre_alloc_empty_0 ;
//    logic                       pre_alloc_full_0  ;
//    logic                       pre_alloc_empty_1 ;
//    logic                       pre_alloc_full_1  ;
//    logic [ENTRY_ID_WIDTH-1:0]  mshr_din_id_0     ;
//    logic [ENTRY_ID_WIDTH-1:0]  mshr_din_id_1     ;
//
//    cmn_lead_two #(
//        .ENTRY_NUM (ENTRY_NUM)
//    ) u_cmn_lead_two(
//        .v_entry_vld      (v_in_vld        ),
//        .v_free_idx_oh_1  (free_mshr_oh_0  ),
//        .v_free_idx_bin_1 (free_mshr_id_0  ),
//        .v_free_vld_1     (free_mshr_vld_0 ),
//        .v_free_idx_oh_2  (free_mshr_oh_1  ),
//        .v_free_idx_bin_2 (free_mshr_id_1  ),
//        .v_free_vld_2     (free_mshr_vld_1 ));
//    //assign v_in_rdy   = (free_mshr_vld_0 && free_mshr_vld_1 && !pre_allo_buf_full) ? (free_mshr_oh_0 | free_mshr_oh_1) : {ENTRY_NUM{1'b0}};
//
//    assign v_in_rdy = ((free_mshr_vld_0 && pre_alloc_empty_0) || (free_mshr_vld_1 && pre_alloc_empty_1)) ? 
//                      (free_mshr_oh_0 | free_mshr_oh_1) : {ENTRY_NUM{1'b0}};
//
//    assign mshr_id_wr_0  = free_mshr_vld_0       ;
//    assign mshr_id_wr_1  = free_mshr_vld_1       ;
//    assign mshr_din_id_0 = free_mshr_id_0        ;
//    assign mshr_din_id_1 = free_mshr_id_1        ;
//    assign mshr_id_rd_0  = out_vld_0 && out_rdy_0;
//    assign mshr_id_rd_1  = out_vld_1 && out_rdy_1;
//    
//    fifo_2in_2out #( 
//        .DATA_WIDTH (ENTRY_ID_WIDTH),
//        .ADDR_WIDTH (PRE_ALLO_NUM)
//    ) u_fifo ( 
//        .clk        (clk              ),
//        .rst_n      (rst_n            ),
//        .wr_ena0    (mshr_id_wr_0     ),
//        .wr_ena1    (mshr_id_wr_1     ),
//        .din0       (mshr_din_id_0    ),
//        .din1       (mshr_din_id_1    ),
//        .rd_ena0    (mshr_id_rd_0     ),
//        .rd_ena1    (mshr_id_rd_1     ),
//        .dout0      (out_idx_0        ),
//        .dout1      (out_idx_1        ),
//        .full0      (pre_alloc_full_0 ),
//        .full1      (pre_alloc_full_1 ),
//        .empty0     (pre_alloc_empty_0),
//        .empty1     (pre_alloc_empty_1));
//    assign out_vld_0  = !pre_alloc_empty_0 ;
//    assign out_vld_1  = !pre_alloc_empty_1 ;
//endmodule



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
    output logic                       out_vld_0  ,
    input  logic                       out_rdy_0  ,
    output logic                       out_vld_1  ,
    input  logic                       out_rdy_1  ,
    output logic [ENTRY_ID_WIDTH-1:0]  out_idx_0  ,
    output logic [ENTRY_ID_WIDTH-1:0]  out_idx_1
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
    assign two_free_id = {free_mshr_id_2,free_mshr_id_1}    ;
    assign mshr_id_wr  = free_mshr_vld_1 && free_mshr_vld_2  ;
    assign mshr_id_rd  = (out_vld_0 && out_rdy_0) ||  (out_vld_1 && out_rdy_1)  ;

    fifo#(
        .DATA_WIDTH(ENTRY_ID_WIDTH*2),
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
    assign out_vld_0 = !pre_allo_buf_empty                      ;
    assign out_vld_1 = !pre_allo_buf_empty                      ;
    assign out_idx_0 = out_index[ENTRY_ID_WIDTH-1:0]               ;
    assign out_idx_1 = out_index[ENTRY_ID_WIDTH*2-1:ENTRY_ID_WIDTH];

endmodule