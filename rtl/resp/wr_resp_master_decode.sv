module wr_resp_master_decode 
    import vector_cache_pkg::*;
    #(
        parameter integer unsigned IN_NUM = 8,
        parameter integer unsigned OUT_NUM = 8,
        parameter integer unsigned PLD_WIDTH= 32
    ) (
        input  logic                    clk                 ,
        input  logic                    rst_n               ,
        input  logic [7:0]              in_wresp_vld        ,
        input  wr_resp_pld_t            in_wresp_pld[7:0]   ,
        output logic [WB_REQ_NUM-1 :0]  out_resp_vld        ,
        output wr_resp_pld_t            out_resp_pld[WB_REQ_NUM-1:0]      
    );

    logic [$clog2(WB_REQ_NUM)-1:0] select[7:0];

    generate
        for(genvar i=0;i<8;i=i+1)begin:select_gen
            assign select[i] = in_wresp_pld[i].txnid.master_id; //txnid中除低2bit外，其余作为master的id
        end
    endgenerate

    m_to_n_xbar #(
        .M(8),
        .N(WW_REQ_NUM),
        .PLD_WIDTH($bits(wr_resp_pld_t))
    ) u_master_decode (
        .in_vld (in_wresp_vld   ),
        .in_pld (in_wresp_pld   ),
        .select (select         ),
        .out_vld(out_resp_vld   ),
        .out_pld(out_resp_pld   ));

endmodule