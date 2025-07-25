module read_req_xbar 
    import vector_cache_pkg::*;
    #( 
        parameter integer unsigned R_REQ_NUM = 8
    )(
    input  logic                        clk                                  ,
    input  logic                        rst_n                                ,
    input  logic [R_REQ_NUM-1       :0] rd_cmd_vld                           ,
    output logic [R_REQ_NUM-1       :0] rd_cmd_rdy                           ,
    input  logic [63                :0] rd_addr           [R_REQ_NUM-1:0]    ,
    input  logic [TXNID_WIDTH-1     :0] rd_cmd_txnid      [R_REQ_NUM-1:0]    ,
    input  logic [SIDEBAND_WIDTH-1  :0] rd_sideband       [R_REQ_NUM-1:0]    ,
    output logic [3                 :0] sel_rd_vld                           ,
    output input_req_pld_t              sel_rd_pld            [3:0]          ,
    input  logic [3                 :0] sel_rd_rdy        

    );

    input_req_pld_t  in_rd_pld [R_REQ_NUM-1:0];
    logic [1:0] in_select [WW_REQ_NUM-1:0] ;

    //select gen
    generate
        for(genvar i=0;i<R_REQ_NUM;i=i+1)begin
            assign in_select[i] = rd_addr[i][63:62];
        end
    endgenerate

    generate
        for(genvar i=0;i<R_REQ_NUM;i=i+1)begin:WEST
            assign in_rd_pld[i].cmd_addr      = rd_addr[i]      ;
            assign in_rd_pld[i].cmd_txnid     = rd_cmd_txnid[i] ;
            assign in_rd_pld[i].cmd_sideband  = rd_sideband[i]  ;
            assign in_rd_pld[i].strb          = 'b0             ;
            assign in_rd_pld[i].cmd_opcode    = 1'b1;//1 is read
        end
    endgenerate

    nto4_xbar #(
        .N  (R_REQ_NUM),// read req num
        .PLD_WIDTH($bits(input_req_pld_t))//
    ) u_read_xbar(
        .clk        (clk            ),
        .rst_n      (rst_n          ),
        .in_vld     (rd_cmd_vld     ),
        .in_rdy     (rd_cmd_rdy     ),
        .in_pld     (in_rd_pld      ),
        .in_select  (in_select      ),
        .out_vld    (sel_rd_vld     ),
        .out_pld    (sel_rd_pld     ),
        .out_rdy    (sel_rd_rdy     ));


endmodule