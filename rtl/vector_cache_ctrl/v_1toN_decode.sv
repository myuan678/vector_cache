module v_1toN_decode #(
    parameter integer unsigned N=8
    )(
    input  logic                  vld      ,
    input  logic [$clog2(N)-1:0]  vld_index,
    output logic [N-1        :0]  v_out_vld
    );

    generate
        for (genvar i = 0; i < N; i=i+1) begin : gen_v_out_vld
            always_comb begin
                v_out_vld[i] = 'b0;
                if(i==vld_index  &&  vld)begin
                    v_out_vld[i] = 1'b1;
                end
            end
        end
    endgenerate

endmodule