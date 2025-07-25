module n_to_2_arb #(
    parameter N = 10,           // 输入请求数量
    parameter PLD_WIDTH = 8    // payload位宽
) (
    input  wire             clk,
    input  wire             rst_n,
    
    input  wire [N-1        :0] req_vld,        
    output wire [N-1        :0] req_rdy,        
    input  wire [PLD_WIDTH-1:0] req_pld[N-1:0], 
    

    output wire [1          :0] grant_vld,      
    input  wire [1          :0] grant_rdy,      
    output wire [PLD_WIDTH-1:0] grant_pld[1:0]  
);

    logic [N-1:0]     first_grant_oh;     // 第一优先级(one-hot)
    logic [N-1:0]     second_grant_oh;    // 第二优先级(one-hot)
    logic [N-1:0]     remaining_reqs;     // 排除第一优先级后的剩余请求
    
    
    // 查找第一优先级请求
    cmn_lead_one #(
        .ENTRY_NUM(N)
    ) u_first_lead_one (
        .v_entry_vld    (req_vld & ((grant_rdy[0] || !grant_vld[0]) ? {N{1'b1}} : {N{1'b0}})),
        .v_free_idx_oh  (first_grant_oh),
        .v_free_idx_bin (),
        .v_free_vld     (grant_vld[0])
    );
    
    // 排除第一优先级后的剩余请求
    assign remaining_reqs = req_vld & (~first_grant_oh);
    
    //查找第二优先级请求
    cmn_lead_one #(
        .ENTRY_NUM(N)
    ) u_second_lead_one (
        .v_entry_vld    (remaining_reqs & ((grant_rdy[1] || !grant_vld[1]) ? {N{1'b1}} : {N{1'b0}})),
        .v_free_idx_oh  (second_grant_oh),
        .v_free_idx_bin (),
        .v_free_vld     (grant_vld[1])
    );
    

    logic [PLD_WIDTH-1:0] first_selected_pld;
    logic [PLD_WIDTH-1:0] second_selected_pld;
    
    always_comb begin
        first_selected_pld = 'b0;
        for (int i = 0; i < N; i = i + 1) begin
            if (first_grant_oh[i]) begin
                first_selected_pld = req_pld[i];
            end
        end
    end
    
    always_comb begin
        second_selected_pld = 'b0;
        for (int i = 0; i < N; i = i + 1) begin
            if (second_grant_oh[i]) begin
                second_selected_pld = req_pld[i];
            end
        end
    end
    
    assign grant_pld[0] = first_selected_pld;
    assign grant_pld[1] = second_selected_pld;
    
    assign req_rdy = ((grant_rdy[0] || !grant_vld[0]) ? first_grant_oh : 'b0) | 
                    ((grant_rdy[1] || !grant_vld[1]) ? second_grant_oh : 'b0);

endmodule