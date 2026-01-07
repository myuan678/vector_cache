module vec_cache_vr_2grant_arb (
    input  logic                    dataram_rd_in_vld_w   ,
    input  logic                    dataram_rd_in_vld_e   ,
    input  logic                    dataram_rd_in_vld_s   ,
    input  logic                    dataram_rd_in_vld_n   ,
    input  logic                    dataram_rd_in_vld_ev  ,

    output logic                    dataram_rd_in_rdy_w   ,
    output logic                    dataram_rd_in_rdy_e   ,
    output logic                    dataram_rd_in_rdy_s   ,
    output logic                    dataram_rd_in_rdy_n   ,
    output logic                    dataram_rd_in_rdy_ev  ,

    input  logic                    dataram_wr_in_vld_w   ,
    input  logic                    dataram_wr_in_vld_e   ,
    input  logic                    dataram_wr_in_vld_s   ,
    input  logic                    dataram_wr_in_vld_n   ,
    input  logic                    dataram_wr_in_vld_lf  ,

    output logic                    dataram_wr_in_rdy_w   ,
    output logic                    dataram_wr_in_rdy_e   ,
    output logic                    dataram_wr_in_rdy_s   ,
    output logic                    dataram_wr_in_rdy_n   ,
    output logic                    dataram_wr_in_rdy_lf  ,


    output logic                    dataram_rd_out_vld_w  ,
    output logic                    dataram_rd_out_vld_e  ,
    output logic                    dataram_rd_out_vld_s  ,
    output logic                    dataram_rd_out_vld_n  ,
    output logic                    dataram_rd_out_vld_ev , 

    output logic                    dataram_wr_out_vld_w  ,
    output logic                    dataram_wr_out_vld_e  ,
    output logic                    dataram_wr_out_vld_s  ,
    output logic                    dataram_wr_out_vld_n  ,
    output logic                    dataram_wr_out_vld_lf             
);

    logic [9  :0]          v_req_vld            ;
    logic [9  :0]          v_req_rdy            ;
    logic [9  :0]          v_grant_vld          ;
    logic [9  :0]          first_grant_oh       ;    
    logic [9  :0]          second_grant_oh      ;   
    logic [9  :0]          remaining_reqs       ; 


    assign v_req_vld = {dataram_rd_in_vld_w,dataram_rd_in_vld_e,dataram_rd_in_vld_s,dataram_rd_in_vld_n,dataram_rd_in_vld_ev,
                        dataram_wr_in_vld_w,dataram_wr_in_vld_e,dataram_wr_in_vld_s,dataram_wr_in_vld_n,dataram_wr_in_vld_lf};
          
    // 查找第一优先级请求
    cmn_lead_one #(
        .ENTRY_NUM(10)
    ) u_first_lead_one (
        .v_entry_vld    (v_req_vld      ),
        .v_free_idx_oh  (first_grant_oh ),
        .v_free_idx_bin (),
        .v_free_vld     ()
    );
    
    assign remaining_reqs = v_req_vld & (~first_grant_oh);
    //查找第二优先级请求
    cmn_lead_one #(
        .ENTRY_NUM(10)
    ) u_second_lead_one (
        .v_entry_vld    (remaining_reqs     ),
        .v_free_idx_oh  (second_grant_oh    ),
        .v_free_idx_bin (),
        .v_free_vld     ()
    );
    assign v_grant_vld      = first_grant_oh | second_grant_oh;
    assign v_req_rdy        = v_grant_vld ;
    
    assign dataram_rd_in_rdy_w  = v_req_rdy[9];
    assign dataram_rd_in_rdy_e  = v_req_rdy[8];
    assign dataram_rd_in_rdy_s  = v_req_rdy[7];
    assign dataram_rd_in_rdy_n  = v_req_rdy[6];
    assign dataram_rd_in_rdy_ev = v_req_rdy[5];
    assign dataram_wr_in_rdy_w  = v_req_rdy[4];
    assign dataram_wr_in_rdy_e  = v_req_rdy[3];
    assign dataram_wr_in_rdy_s  = v_req_rdy[2];
    assign dataram_wr_in_rdy_n  = v_req_rdy[1];
    assign dataram_wr_in_rdy_lf = v_req_rdy[0];

    assign dataram_rd_out_vld_w  = v_grant_vld[9];
    assign dataram_rd_out_vld_e  = v_grant_vld[8];
    assign dataram_rd_out_vld_s  = v_grant_vld[7];
    assign dataram_rd_out_vld_n  = v_grant_vld[6];
    assign dataram_rd_out_vld_ev = v_grant_vld[5];
    assign dataram_wr_out_vld_w  = v_grant_vld[4];
    assign dataram_wr_out_vld_e  = v_grant_vld[3];
    assign dataram_wr_out_vld_s  = v_grant_vld[2];
    assign dataram_wr_out_vld_n  = v_grant_vld[1];
    assign dataram_wr_out_vld_lf = v_grant_vld[0];
 
endmodule