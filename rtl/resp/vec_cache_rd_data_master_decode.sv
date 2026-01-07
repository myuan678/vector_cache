module vec_cache_rd_data_master_decode 
    import vector_cache_pkg::*;
    #(
    parameter integer unsigned  M = 8,
    parameter integer unsigned  N = 16
)(
    input  logic        [M-1:0] in_vld         ,
    input  us_data_pld_t        in_pld [M-1:0] ,
    output logic        [N-1:0] out_vld        ,
    output us_data_pld_t        out_pld [N-1:0]
);
    logic [$clog2(N)-1:0]       select [M-1:0] ;

    generate
        for(genvar i=0;i<M;i=i+1)begin
            assign select[i] = in_pld[i].txn_id.master_id;
        end
    endgenerate


    always_comb begin
        for (int j = 0; j < N; j++) begin
            out_vld[j] = 1'b0;
            out_pld[j] = '0;
        end
        for (int i = 0; i < M; i++) begin
            if (in_vld[i]) begin
                out_vld[select[i]] = 1'b1       ;
                out_pld[select[i]] = in_pld[i]  ;
            end
        end
    end


endmodule
