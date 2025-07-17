module m_to_n_xbar #(
    parameter int M = 8,
    parameter int N = 16,
    parameter int PLD_WIDTH = 32
)(
    input  logic [M-1:0]                      in_vld,
    input  logic [PLD_WIDTH-1:0]             in_pld [M-1:0],
    input  logic [$clog2(N)-1:0]             select [M-1:0],

    output logic [N-1:0]                     out_vld,
    output logic [PLD_WIDTH-1:0]             out_pld [N-1:0]
);

    always_comb begin
        for (int j = 0; j < N; j++) begin
            out_vld[j] = 1'b0;
            out_pld[j] = '0;
        end
        for (int i = 0; i < M; i++) begin
            if (in_vld[i]) begin
                out_vld[select[i]] = 1'b1;
                out_pld[select[i]] = in_pld[i];
            end
        end
    end

    always_comb begin
        for (int i = 0; i < M; i++) begin
            for (int j = i + 1; j < M; j++) begin
                if (in_vld[i] && in_vld[j]) begin
                    assert (select[i] != select[j])
                        else $error("Crossbar conflict: select[%0d]=%0d == select[%0d]=%0d", i, select[i], j, select[j]);
                end
            end
        end
    end


endmodule
