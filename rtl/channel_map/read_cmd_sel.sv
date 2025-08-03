module read_cmd_sel 
    import vector_cache_pkg::*;
    (
    
    input logic [3:0]       v_west_read_cmd_vld         ,   
    input logic [3:0]       v_east_read_cmd_vld         ,   
    input logic [3:0]       v_south_read_cmd_vld        ,   
    input logic [3:0]       v_north_read_cmd_vld        ,
    input logic [3:0]       v_evict_req_vld             ,

    input arb_out_req_t     v_west_read_cmd_pld [3:0]   ,
    input arb_out_req_t     v_east_read_cmd_pld [3:0]   ,
    input arb_out_req_t     v_south_read_cmd_pld[3:0]   ,
    input arb_out_req_t     v_north_read_cmd_pld[3:0]   ,
    input arb_out_req_t     v_evict_req_pld     [3:0]   ,

    output logic [7:0]      toram_west_rd_cmd_vld       ,
    output arb_out_req_t    toram_west_rd_cmd_pld [7:0]       
);
    logic [3:0]     read_vld;
    arb_out_req_t   read_pld[3:0];    
    generate 
        for(genvar i=0;i<4;i=i+1)begin
            assign read_vld[i] = v_west_read_cmd_vld[i] | v_east_read_cmd_vld[i] | v_south_read_cmd_vld[i] | v_north_read_cmd_vld[i] | v_evict_req_vld[i];
            assign read_pld[i] = v_west_read_cmd_vld[i] ? v_west_read_cmd_pld[i] :
                                 v_east_read_cmd_vld[i] ? v_east_read_cmd_pld[i] :
                                 v_south_read_cmd_vld[i]? v_south_read_cmd_pld[i]:
                                 v_north_read_cmd_vld[i]? v_north_read_cmd_pld[i]: v_evict_req_pld[i] ;
        end
    endgenerate
    //generate//assert 同一hash的这五个读请求不会同时有效
    //    for(genvar i=0;i<4;i=i+1)begin
    //        always_comb begin
    //            assert ((v_west_read_cmd_vld[i]+ v_east_read_cmd_vld[i]+v_south_read_cmd_vld[i]+v_north_read_cmd_vld[i]+v_evict_req_vld[i]<=1))
    //            else $error("ERROR: Read requst conflict! only one can be valid!");
    //        end
    //    end
    //endgenerate
    generate
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                toram_west_rd_cmd_vld[2*i]      ='b0;
                toram_west_rd_cmd_vld[2*i+1]    ='b0;
                toram_west_rd_cmd_pld[2*i]      ='b0;
                toram_west_rd_cmd_pld[2*i+1]    ='b0;
                if(read_vld[i])begin
                    if(read_pld[i].dest_ram_id[0])begin
                        toram_west_rd_cmd_vld[2*i]      = 1'b0;
                        toram_west_rd_cmd_vld[2*i+1]    = read_vld[i];
                        toram_west_rd_cmd_pld[2*i]      = read_pld[i];
                        toram_west_rd_cmd_pld[2*i+1]    = read_pld[i];
                    end
                    else begin
                        toram_west_rd_cmd_vld[2*i]      = read_vld[i];
                        toram_west_rd_cmd_vld[2*i+1]    = 1'b0;
                        toram_west_rd_cmd_pld[2*i]      = read_pld[i];
                        toram_west_rd_cmd_pld[2*i+1]    = read_pld[i];
                    end
                end
            end
        end
    endgenerate


endmodule
