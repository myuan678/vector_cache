module vr_2grant_arb (
    input  logic                    w_dataram_rd_vld        ,
    input  logic                    e_dataram_rd_vld        ,
    input  logic                    s_dataram_rd_vld        ,
    input  logic                    n_dataram_rd_vld        ,
    input  logic                    evict_rd_vld            ,

    output logic                    w_dataram_rd_rdy        ,
    output logic                    e_dataram_rd_rdy        ,
    output logic                    s_dataram_rd_rdy        ,
    output logic                    n_dataram_rd_rdy        ,
    output logic                    evict_rd_rdy            ,

    input  logic                    w_dataram_wr_vld        ,
    input  logic                    e_dataram_wr_vld        ,
    input  logic                    s_dataram_wr_vld        ,
    input  logic                    n_dataram_wr_vld        ,
    input  logic                    linefill_req_vld        ,

    output logic                    w_dataram_wr_rdy        ,
    output logic                    e_dataram_wr_rdy        ,
    output logic                    s_dataram_wr_rdy        ,
    output logic                    n_dataram_wr_rdy        ,
    output logic                    linefill_req_rdy        ,


    output logic                    arbout_w_dataram_rd_vld ,
    output logic                    arbout_e_dataram_rd_vld ,
    output logic                    arbout_s_dataram_rd_vld ,
    output logic                    arbout_n_dataram_rd_vld ,
    output logic                    arbout_evict_rd_vld     , 

    output logic                    arbout_w_dataram_wr_vld ,
    output logic                    arbout_e_dataram_wr_vld ,
    output logic                    arbout_s_dataram_wr_vld ,
    output logic                    arbout_n_dataram_wr_vld ,
    output logic                    arbout_linefill_req_vld , 

    input  logic                    grant_rdy                 
);

    logic [9  :0]          v_req_vld            ;
    logic [9  :0]          v_req_rdy            ;
    logic [9  :0]          v_grant_vld          ;
    logic [9  :0]          first_grant_oh       ;    
    logic [9  :0]          second_grant_oh      ;   
    logic [9  :0]          remaining_reqs       ; 

    assign v_req_vld = {w_dataram_rd_vld,e_dataram_rd_vld,s_dataram_rd_vld,n_dataram_rd_vld,evict_rd_vld,w_dataram_wr_vld,e_dataram_wr_vld,s_dataram_wr_vld,n_dataram_wr_vld,linefill_req_vld};
    
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
        .v_free_idx_bin (   ),
        .v_free_vld     ()
    );
    

    assign v_grant_vld      = first_grant_oh | second_grant_oh;
    assign v_req_rdy        = v_grant_vld & ({10{grant_rdy}});
    
    assign w_dataram_rd_rdy = v_req_rdy[9];
    assign e_dataram_rd_rdy = v_req_rdy[8];
    assign s_dataram_rd_rdy = v_req_rdy[7];
    assign n_dataram_rd_rdy = v_req_rdy[6];
    assign evict_rd_rdy     = v_req_rdy[5];
    assign w_dataram_wr_rdy = v_req_rdy[4];
    assign e_dataram_wr_rdy = v_req_rdy[3];
    assign s_dataram_wr_rdy = v_req_rdy[2];
    assign n_dataram_wr_rdy = v_req_rdy[1];
    assign linefill_req_rdy = v_req_rdy[0];

    assign arbout_w_dataram_rd_vld = v_grant_vld[9];
    assign arbout_e_dataram_rd_vld = v_grant_vld[8];
    assign arbout_s_dataram_rd_vld = v_grant_vld[7];
    assign arbout_n_dataram_rd_vld = v_grant_vld[6];
    assign arbout_evict_rd_vld     = v_grant_vld[5];
    assign arbout_w_dataram_wr_vld = v_grant_vld[4];
    assign arbout_e_dataram_wr_vld = v_grant_vld[3];
    assign arbout_s_dataram_wr_vld = v_grant_vld[2];
    assign arbout_n_dataram_wr_vld = v_grant_vld[1];
    assign arbout_linefill_req_vld = v_grant_vld[0];
 
endmodule