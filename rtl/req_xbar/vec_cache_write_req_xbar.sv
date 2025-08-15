module vec_cache_write_req_xbar 
import vector_cache_pkg::*;
#(
    parameter integer unsigned W_REQ_NUM = 8
) (
    input  logic                              clk                                ,
    input  logic                              rst_n                              ,

    input  logic [W_REQ_NUM-1         :0]     wr_cmd_vld                         ,
    input  input_write_cmd_pld_t              wr_cmd_pld      [W_REQ_NUM-1:0]    ,
    output logic [W_REQ_NUM-1         :0]     wr_cmd_rdy                         ,

    input  logic [3                   :0]     alloc_vld                          ,
    input  logic [DB_ENTRY_IDX_WIDTH-1:0]     alloc_idx         [3:0]            ,
    output logic [3:0]                        alloc_rdy                          ,

    output logic [3                   :0]     sel_wr_vld                         ,
    output input_req_pld_t                    sel_wr_pld      [3:0]              ,      
    output wdb_pld_t                          sel_wr_data_pld [3:0]              , //data + db_entry_id 
    input  logic [3                   :0]     sel_wr_rdy     
);

    input_wrreq_pld_t                         in_wr_pld       [W_REQ_NUM-1:0]    ;
    input_wrreq_pld_t                         sel_full_wr_pld [4-1        :0]    ;
    logic [1          :0]                     in_select       [W_REQ_NUM-1:0]    ;//nto4 select width = $clog2(4)=2,地址高2bit作为select
    logic [3          :0]                     pre_sel_wr_vld                     ;
    input_req_pld_t                           pre_sel_wr_pld  [3          :0]    ;
    logic [W_REQ_NUM-1:0]                     pre_wr_cmd_rdy                     ;

//select gen
    
    generate
        for(genvar i=0;i<W_REQ_NUM;i=i+1)begin
            assign in_select[i] = wr_cmd_pld[i].cmd_addr[63:62];
        end
    endgenerate

    generate
        for(genvar i=0;i<W_REQ_NUM;i=i+1)begin:WEST_WR
            assign in_wr_pld[i].cmd_pld.cmd_addr      = wr_cmd_pld[i].cmd_addr      ;
            assign in_wr_pld[i].cmd_pld.cmd_txnid     = wr_cmd_pld[i].cmd_txnid     ;
            assign in_wr_pld[i].cmd_pld.cmd_sideband  = wr_cmd_pld[i].cmd_sideband  ;
            assign in_wr_pld[i].data                  = wr_cmd_pld[i].data          ;
            assign in_wr_pld[i].cmd_pld.strb          = wr_cmd_pld[i].strb          ;
            //assign in_wr_pld[i].cmd_pld.cmd_opcode    = `VEC_CACHE_CMD_WRITE        ; //1 is write
            assign in_wr_pld[i].cmd_pld.cmd_opcode    = 2'd1        ; 
        end
    endgenerate

    vec_cache_nto4_xbar #(
        .N (W_REQ_NUM),//input num
        .PLD_WIDTH($bits(input_wrreq_pld_t))
    ) u_west_wr_xbar(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .in_vld     (wr_cmd_vld         ),
        .in_rdy     (pre_wr_cmd_rdy     ),
        .in_pld     (in_wr_pld          ),
        .in_select  (in_select          ),
        .out_vld    (pre_sel_wr_vld     ),
        .out_pld    (sel_full_wr_pld    ),
        .out_rdy    (sel_wr_rdy         ));


    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign sel_wr_vld[i] = pre_sel_wr_vld[i] && alloc_vld[i];
        end
    endgenerate

    generate
        for(genvar i=0;i<W_REQ_NUM;i=i+1)begin
            //assign wr_cmd_rdy[i] = pre_wr_cmd_rdy[i] && sel_wr_vld[i]; 
            assign wr_cmd_rdy[i] = {W_REQ_NUM{pre_wr_cmd_rdy[i]}} && wr_cmd_vld[i]; 
        end
    endgenerate

    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign alloc_rdy[i]     = sel_wr_vld[i]  && sel_wr_rdy[i]  ;
        end
    endgenerate

    

    generate
        for(genvar i=0;i<4;i=i+1)begin: Mto4_XBAR_out_gen
            //assign sel_wr_pld[i].cmd_vld      = sel_full_wr_pld[i].cmd_pld.cmd_vld;
            assign sel_wr_pld[i].cmd_addr     = sel_full_wr_pld[i].cmd_pld.cmd_addr;
            assign sel_wr_pld[i].cmd_txnid    = sel_full_wr_pld[i].cmd_pld.cmd_txnid;
            assign sel_wr_pld[i].cmd_sideband = sel_full_wr_pld[i].cmd_pld.cmd_sideband;
            assign sel_wr_pld[i].strb         = sel_full_wr_pld[i].cmd_pld.strb;
            assign sel_wr_pld[i].cmd_opcode   = sel_full_wr_pld[i].cmd_pld.cmd_opcode;
            assign sel_wr_pld[i].db_entry_id  = alloc_idx[i];
            assign sel_wr_pld[i].rob_entry_id = 'b0;//tmp,在8to2arb赋值

            assign sel_wr_data_pld[i].data        = sel_full_wr_pld[i].data;
            assign sel_wr_data_pld[i].db_entry_id = alloc_idx[i]; 
            assign sel_wr_data_pld[i].cmd         = sel_wr_pld[i];
        end
    endgenerate

endmodule