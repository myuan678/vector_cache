module vec_cache_wr_resp_direction_decode 
import vector_cache_pkg::*;
#(
    parameter integer unsigned WIDTH = 4//四个方向
)(
    input  logic             clk              ,
    input  logic             rst_n            ,
    input  logic             req_vld          ,
    input  input_req_pld_t   req_pld          ,
    output logic [WIDTH-1:0] v_wresp_vld      ,
    output wr_resp_pld_t     v_wresp_pld [WIDTH-1:0]

);
    
    generate
        for(genvar i=0;i<WIDTH;i=i+1)begin:direction_vld_gen
            always_comb begin
                v_wresp_vld[i] = 'b0;
                if(req_pld.opcode == `VEC_CACHE_CMD_WRITE)begin//写请求才需要回wresp
                    if(req_vld && req_pld.txn_id.direction_id==i)begin 
                        v_wresp_vld[i] = 1'b1;
                    end
                end
            end
            assign v_wresp_pld[i].txn_id   = req_pld.txn_id;
            assign v_wresp_pld[i].sideband = req_pld.sideband;
        end
    endgenerate





endmodule