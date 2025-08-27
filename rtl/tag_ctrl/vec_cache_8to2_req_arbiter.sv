module vec_cache_8to2_req_arbiter 
    import vector_cache_pkg::*;
    #(
    parameter integer unsigned REQ_NUM= 8,
    parameter integer unsigned ENTRY_IDX_WIDTH=4
)(
    input                            clk                    ,
    input                            rst_n                  ,
    input  logic [REQ_NUM-1      :0] v_req_vld              ,
    input  input_req_pld_t           v_req_pld[REQ_NUM-1:0] ,
    output logic [REQ_NUM-1      :0] v_req_rdy              ,

    input  logic                     mshr_alloc_vld_0       ,
    input  logic[ENTRY_IDX_WIDTH-1:0]mshr_alloc_idx_0       ,
    output logic                     mshr_alloc_rdy_0       ,
    input  logic                     mshr_alloc_vld_1       ,
    input  logic[ENTRY_IDX_WIDTH-1:0]mshr_alloc_idx_1       ,
    output logic                     mshr_alloc_rdy_1       ,
    
    output logic                     out_grant_vld_0        ,
    output logic                     out_grant_vld_1        ,
    output input_req_pld_t           out_grant_pld_0        ,
    output input_req_pld_t           out_grant_pld_1        ,
    input  logic                     out_grant_rdy
);

    logic [REQ_NUM-1        :0] free_oh_1                   ;
    logic [$clog2(REQ_NUM)-1:0] free_id_1                   ;
    logic                       free_vld_1                  ;
    logic [REQ_NUM-1        :0] free_oh_2                   ;
    logic [$clog2(REQ_NUM)-1:0] free_id_2                   ;
    logic                       free_vld_2                  ;

    logic [1:0]                 grant_vld                   ;
    logic [REQ_NUM-1:0]         v_rdy                       ;
    input_req_pld_t             grant_pld[1:0]              ;


    n_to_2_arb #( 
        .N(8),
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_8to2_arb (
        .clk      (clk          ),
        .rst_n    (rst_n        ),
        .req_vld  (v_req_vld    ),
        .req_rdy  (v_rdy        ),
        .req_pld  (v_req_pld    ),
        .grant_vld(grant_vld    ),
        .grant_rdy({out_grant_rdy,out_grant_rdy}),
        .grant_pld(grant_pld    ));


    assign out_grant_vld_0              = grant_vld[0] && mshr_alloc_vld_0;
    assign out_grant_vld_1              = grant_vld[1] && mshr_alloc_vld_1;

    assign out_grant_pld_0.addr         = grant_pld[0].addr        ;
    assign out_grant_pld_0.txn_id       = grant_pld[0].txn_id      ;
    assign out_grant_pld_0.sideband     = grant_pld[0].sideband    ;
    assign out_grant_pld_0.strb         = grant_pld[0].strb        ;
    assign out_grant_pld_0.opcode       = grant_pld[0].opcode      ;
    assign out_grant_pld_0.db_entry_id  = grant_pld[0].db_entry_id ;
    assign out_grant_pld_0.rob_entry_id = mshr_alloc_idx_0         ;

    assign out_grant_pld_1.addr         = grant_pld[1].addr        ;
    assign out_grant_pld_1.txn_id       = grant_pld[1].txn_id      ;
    assign out_grant_pld_1.sideband     = grant_pld[1].sideband    ;
    assign out_grant_pld_1.strb         = grant_pld[1].strb        ;
    assign out_grant_pld_1.opcode       = grant_pld[1].opcode      ;
    assign out_grant_pld_1.db_entry_id  = grant_pld[1].db_entry_id ;
    assign out_grant_pld_1.rob_entry_id = mshr_alloc_idx_1         ;



    generate
        for(genvar i=0;i<REQ_NUM;i=i+1)begin
            assign v_req_rdy[i] = v_rdy[i] && (mshr_alloc_vld_0 || mshr_alloc_vld_1);
        end
    endgenerate

    assign mshr_alloc_rdy_0     = out_grant_vld_0  && out_grant_rdy  ;
    assign mshr_alloc_rdy_1     = out_grant_vld_1  && out_grant_rdy  ;


endmodule
