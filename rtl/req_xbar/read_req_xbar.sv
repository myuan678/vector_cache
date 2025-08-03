module read_req_xbar 
    import vector_cache_pkg::*;
    #( 
        parameter integer unsigned R_REQ_NUM = 8
    )(
    input  logic                        clk                                  ,
    input  logic                        rst_n                                ,

    input  logic [R_REQ_NUM-1       :0] rd_cmd_vld                           ,
    input  input_read_cmd_pld_t         rd_cmd_pld   [R_REQ_NUM-1:0]         ,
    output logic [R_REQ_NUM-1       :0] rd_cmd_rdy                           ,

    output logic [3                 :0] sel_rd_vld                           ,
    output input_req_pld_t              sel_rd_pld   [3:0]                   ,
    input  logic [3                 :0] sel_rd_rdy        

    );

    input_req_pld_t  in_rd_pld [R_REQ_NUM-1:0] ;
    logic [1    :0]  in_select [R_REQ_NUM-1:0] ;

    //select gen
    generate
        for(genvar i=0;i<R_REQ_NUM;i=i+1)begin
            assign in_select[i] = rd_cmd_pld[i].cmd_addr[63:62];
        end
    endgenerate

    generate
        for(genvar i=0;i<R_REQ_NUM;i=i+1)begin:WEST
            assign in_rd_pld[i].cmd_addr      = rd_cmd_pld[i].cmd_addr      ;
            assign in_rd_pld[i].cmd_txnid     = rd_cmd_pld[i].cmd_txnid     ;
            assign in_rd_pld[i].cmd_sideband  = rd_cmd_pld[i].cmd_sideband  ;
            assign in_rd_pld[i].strb          = 'b0             ;
            assign in_rd_pld[i].cmd_opcode    = 2'd2;//2 is read
            assign in_rd_pld[i].db_entry_id   = 'b0;
            assign in_rd_pld[i].rob_entry_id  = 'b0;
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