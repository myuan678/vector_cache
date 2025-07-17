module eightto2_req_arbiter 
    import vector_cache_pkg::*;
    #(
    parameter integer unsigned REQ_NUM= 8,
    parameter integer unsigned ENTRY_IDX_WIDTH=4,
    parameter integer unsigned PLD_WIDTH = 32
    //parameter type            PLD_TYPE = logic
)(
    input                            clk                    ,
    input                            rst_n                  ,
    input  logic [REQ_NUM-1      :0] v_req_vld              ,
    input  logic [PLD_WIDTH-1    :0] v_req_pld[REQ_NUM-1:0] ,
    output logic [REQ_NUM-1      :0] v_req_rdy              ,

    input  logic                     mshr_alloc_vld  ,
    input  logic[ENTRY_IDX_WIDTH-1:0]mshr_alloc_idx_1,
    input  logic[ENTRY_IDX_WIDTH-1:0]mshr_alloc_idx_2,
    output logic                     mshr_alloc_rdy  ,
    
    output logic                     out_grant_vld   ,
    output logic [PLD_WIDTH-1    :0] out_grant_pld_1 ,
    output logic [PLD_WIDTH-1    :0] out_grant_pld_2 ,
    input  logic                     out_grant_rdy
);
    logic [REQ_NUM-1        :0] free_oh_1            ;
    logic [$clog2(REQ_NUM)-1:0] free_id_1            ;
    logic                       free_vld_1           ;
    logic [REQ_NUM-1        :0] free_oh_2            ;
    logic [$clog2(REQ_NUM)-1:0] free_id_2            ;
    logic                       free_vld_2           ;

    cmn_lead_two #(
        .ENTRY_NUM (REQ_NUM)
    ) u_cmn_lead_two(
        .v_entry_vld      (v_req_vld  ),
        .v_free_idx_oh_1  (free_oh_1  ),
        .v_free_idx_bin_1 (free_id_1  ),
        .v_free_vld_1     (free_vld_1 ),
        .v_free_idx_oh_2  (free_oh_2  ),
        .v_free_idx_bin_2 (free_id_2  ),
        .v_free_vld_2     (free_vld_2 )
    );

    assign out_grant_vld      = (|v_req_vld) && mshr_alloc_vld  ;
    assign out_grant_pld_1    = v_req_pld[free_id_1]            ;
    assign out_grant_pld_2    = v_req_pld[free_id_2]            ;
    assign v_req_rdy          = {REQ_NUM{out_grant_rdy}} && (free_vld_1 | free_vld_2) && mshr_alloc_vld;//TODO:
    assign mshr_alloc_rdy     = out_grant_vld && out_grant_rdy  ;


endmodule
