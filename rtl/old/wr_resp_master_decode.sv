module wr_resp_master_decode 
import vector_cache_pkg::*;
#(
    parameter integer unsigned IN_NUM = 8,
    parameter integer unsigned OUT_NUM = 8,
    parameter integer unsigned PLD_WIDTH= 32
) (
    input  logic            clk,
    input  logic            rst_n,
    
    input  logic [7:0]      west_wresp_vld,
    input  wr_resp_pld_t    west_wresp_pld  [7:0],
    input  logic [7:0]      east_wresp_vld  ,
    input  wr_resp_pld_t    east_wresp_pld  [7:0],
    input  logic [7:0]      south_wresp_vld ,
    input  wr_resp_pld_t    south_wresp_pld [7:0],
    input  logic [7:0]      north_wresp_vld ,
    input  wr_resp_pld_t    north_wresp_pld [7:0],


    output logic [WB_REQ_NUM-1      :0] w_resp_vld                                ,
    output wr_resp_pld_t                w_resp_pld          [WB_REQ_NUM-1:0]      ,
    
    output logic [EB_REQ_NUM-1      :0] e_resp_vld,
    output wr_resp_pld_t                e_resp_pld          [EB_REQ_NUM-1:0]      ,
 
    output logic [SB_REQ_NUM-1      :0] s_resp_vld,
    output wr_resp_pld_t                s_resp_pld          [SB_REQ_NUM-1:0]      ,
   
    output logic [NB_REQ_NUM-1      :0] n_resp_vld,
    output wr_resp_pld_t                n_resp_pld          [NB_REQ_NUM-1:0]      
);


    logic [$clog2(WB_REQ_NUM)-1:0] select_west[7:0];
    logic [$clog2(EB_REQ_NUM)-1:0] select_east[7:0];
    logic [$clog2(SB_REQ_NUM)-1:0] select_south[7:0];
    logic [$clog2(NB_REQ_NUM)-1:0] select_north[7:0];
    generate
        for(genvar i=0;i<8;i=i+1)begin:select_gen
            assign select_west[i] = west_wresp_pld[i].txnid[TXNID_WIDTH-1:2]; //txnid中除低2bit外，其余作为master的id
            assign select_east[i] = east_wresp_pld[i].txnid[TXNID_WIDTH-1:2];
            assign select_south[i] = south_wresp_pld[i].txnid[TXNID_WIDTH-1:2];
            assign select_north[i] = north_wresp_pld[i].txnid[TXNID_WIDTH-1:2];
        end
    endgenerate

    m_to_n_xbar #(
        .M(8),
        .N(WW_REQ_NUM),
        .PLD_WIDTH($bits(wr_resp_pld_t))
    ) u_west_master_decode (
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (west_wresp_vld ),
        .in_pld (west_wresp_pld ),
        .select (select_west    ),
        .out_vld(w_resp_vld     ),
        .out_pld(w_resp_pld     ));
    m_to_n_xbar #(
        .M(8),
        .N(EW_REQ_NUM),
        .PLD_WIDTH($bits(wr_resp_pld_t))
    ) u_east_master_decode (
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (east_wresp_vld ),
        .in_pld (east_wresp_pld ),
        .select (select_east    ),
        .out_vld(e_resp_vld     ),
        .out_pld(e_resp_pld     ));
    m_to_n_xbar #(
        .M(8),
        .N(SW_REQ_NUM),
        .PLD_WIDTH($bits(wr_resp_pld_t))
    ) u_south_master_decode (
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (south_wresp_vld),
        .in_pld (south_wresp_pld),
        .select (select_south   ),
        .out_vld(s_resp_vld     ),
        .out_pld(s_resp_pld     ));
    m_to_n_xbar #(
        .M(8),
        .N(NW_REQ_NUM),
        .PLD_WIDTH($bits(wr_resp_pld_t))
    ) u_north_master_decode (
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (north_wresp_vld),
        .in_pld (north_wresp_pld),
        .select (select_north   ),
        .out_vld(n_resp_vld     ),
        .out_pld(n_resp_pld     ));


endmodule