module wr_resp_direction_decode 
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
                if(req_pld.cmd_opcode==1'b0)begin//写请求才需要回wresp
                    if(req_vld && req_pld.cmd_txnid.direction_id==i)begin //txnid的低两位作为方向id,高位作为master id
                        v_wresp_vld[i] = 1'b1;
                    end
                end
            end
            assign v_wresp_pld[i].txnid = req_pld.cmd_txnid;
            assign v_wresp_pld[i].sideband = req_pld.cmd_sideband;
        end
    endgenerate





endmodule