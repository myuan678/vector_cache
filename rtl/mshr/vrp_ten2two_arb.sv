module vrp_ten2two_arb 
    import vector_cache_pkg::*;
    #(
    parameter integer unsigned N = 10,       
    parameter integer unsigned PLD_WIDTH = 8 ,
    parameter integer unsigned RD_REQ_NUM = 5,
    parameter integer unsigned WR_REQ_NUM = 5,
    parameter integer unsigned CHANNEL_SHIFT_REG_WIDTH = 10,
    parameter integer unsigned RAM_SHIFT_REG_WIDTH = 20,
    localparam integer unsigned REQ_NUM = RD_REQ_NUM + WR_REQ_NUM
    )(
    input  logic                    clk                  ,
    input  logic                    rst_n                ,

    input  logic [N-1        :0]    req_vld              ,        
    output logic [N-1        :0]    req_rdy              ,        
    input  logic [PLD_WIDTH-1:0]    req_pld     [N-1:0]  , 

    output logic [$clog2(N)-1:0]    first_grant_idx      ,
    output logic [$clog2(N)-1:0]    second_grant_idx     ,
    output logic [N-1        :0]    grant_vld            ,      
    input  logic [1          :0]    grant_rdy            ,      
    output logic [PLD_WIDTH-1:0]    grant_pld [N-1:0]  
);

    logic [N-1  :0]                first_grant_oh       ;    
    logic [N-1  :0]                second_grant_oh      ;   
    logic [N-1  :0]                remaining_reqs       ; 
    //logic [$clog2(N)-1:0]          first_grant_idx      ;
    //logic [$clog2(N)-1:0]          second_grant_idx     ;
    
    // 查找第一优先级请求
    cmn_lead_one #(
        .ENTRY_NUM(N)
    ) u_first_lead_one (
        .v_entry_vld    (req_vld        ),
        .v_free_idx_oh  (first_grant_oh ),
        .v_free_idx_bin (first_grant_idx),
        .v_free_vld     ()
    );
    
    assign remaining_reqs = req_vld & (~first_grant_oh);
    //查找第二优先级请求
    cmn_lead_one #(
        .ENTRY_NUM(N)
    ) u_second_lead_one (
        .v_entry_vld    (remaining_reqs     ),
        .v_free_idx_oh  (second_grant_oh    ),
        .v_free_idx_bin (second_grant_idx   ),
        .v_free_vld     ()
    );
    

    assign grant_vld = first_grant_oh | second_grant_oh;
    assign req_rdy   = grant_vld & ({N{grant_rdy}});
    generate
        for (genvar i = 0; i < N; i = i + 1) begin:  gen_grant_pld
            assign grant_pld[i] = req_pld[i];
        end
    endgenerate

endmodule