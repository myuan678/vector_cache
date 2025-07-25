module nto4_xbar #(
    parameter integer unsigned  N = 8,
    parameter integer unsigned  PLD_WIDTH = 32
)(
    input  logic                     clk,
    input  logic                     rst_n,

    input  logic  [N-1:0]            in_vld,
    input  logic  [PLD_WIDTH-1:0]    in_pld [N-1:0],
    input  logic  [1:0]              in_select [N-1:0],
    output logic  [N-1:0]            in_rdy,

    input  logic  [3:0]              out_rdy,
    output logic  [3:0]              out_vld,
    output logic  [PLD_WIDTH-1:0]    out_pld [3:0]
);

    logic [N-1:0]            sel_rdy[3:0];
    generate
        for (genvar out_idx = 0; out_idx < 4; out_idx++) begin : OUT_PORT
            logic [N-1        :0] sel_vld        ;
            logic [PLD_WIDTH-1:0] sel_pld [N-1:0];
            logic                 arb_vld        ;
            logic [PLD_WIDTH-1:0] arb_pld        ;

            always_comb begin
                for (int i = 0; i < N; i++) begin
                    if (in_vld[i] && in_select[i] == out_idx[1:0]) begin
                        sel_vld[i] = 1'b1;
                        sel_pld[i] = in_pld[i];
                    end else begin
                        sel_vld[i] = 1'b0;
                        sel_pld[i] = '0;
                    end
                end
            end

            vrp_arb #(
                .WIDTH(N),
                .PLD_WIDTH(PLD_WIDTH)
            ) u_arb (
                .v_vld_s(sel_vld         ),
                .v_pld_s(sel_pld         ),
                .v_rdy_s(sel_rdy[out_idx]),
                .rdy_m  (out_rdy[out_idx]),
                .vld_m  (arb_vld         ),
                .pld_m  (arb_pld         )
            );

            assign out_vld[out_idx]     = arb_vld;
            assign out_pld[out_idx]     = arb_pld;
        end
    endgenerate


    generate
        for(genvar i=0;i<N;i=i+1)begin:GEN_IN_RDY
            always_comb begin
                in_rdy[i] = 1'b0; // 默认值为0
                for (int j = 0; j < 4; j++) begin
                    if (in_select[i] == j && out_rdy[j]) begin
                        in_rdy[i] = 1'b1; // 
                    end
                end
            end
        end
    endgenerate

endmodule
