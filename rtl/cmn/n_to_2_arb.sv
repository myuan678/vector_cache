module n_to_2_arb #(
    parameter N = 10,       
    parameter PLD_WIDTH = 8 
) (
    input  logic                 clk         ,
    input  logic                 rst_n       ,

    input  logic [N-1        :0] req_vld     ,        
    output logic [N-1        :0] req_rdy     ,        
    input  logic [PLD_WIDTH-1:0] req_pld     [N-1:0], 
    

    output logic [1          :0] grant_vld   ,      
    input  logic [1          :0] grant_rdy   ,      
    output logic [PLD_WIDTH-1:0] grant_pld   [1:0]  
);

    logic [N-1:0]     first_grant_oh    ;    
    logic [N-1:0]     second_grant_oh   ;   
    logic [N-1:0]     remaining_reqs    ;    
    
    cmn_lead_one #(
        .ENTRY_NUM(N)
    ) u_first_lead_one (
        .v_entry_vld    (req_vld        ),
        .v_free_idx_oh  (first_grant_oh ),
        .v_free_idx_bin (               ),
        .v_free_vld     (grant_vld[0]   )
    );
    
    assign remaining_reqs = req_vld & (~first_grant_oh);
    
    cmn_lead_one #(
        .ENTRY_NUM(N)
    ) u_second_lead_one (
        .v_entry_vld    (remaining_reqs ),
        .v_free_idx_oh  (second_grant_oh),
        .v_free_idx_bin (               ),
        .v_free_vld     (grant_vld[1]   )
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

    // req_rdy only depends on local valid grants, not downstream grant_rdy
    // This breaks the critical path: grant_rdy -> req_rdy -> req_vld -> arbitration
    assign req_rdy = (grant_vld[0] ? first_grant_oh  : 'b0)
                   | (grant_vld[1] ? second_grant_oh : 'b0);

endmodule