module vec_cache_write_cmd_sel 
    import vector_cache_pkg::*;
    (
    input logic [3:0]       v_lfdb_to_ram_vld                   ,
    input logic [3:0]       west_write_cmd_vld_in               ,
    input logic [3:0]       east_write_cmd_vld_in               ,
    input logic [3:0]       south_write_cmd_vld_in              ,
    input logic [3:0]       north_write_cmd_vld_in              ,
    input write_ram_pld_t   v_lfdb_to_ram_pld       [3:0]       ,
    input write_ram_pld_t   west_write_cmd_pld_in   [3:0]       ,
    input write_ram_pld_t   east_write_cmd_pld_in   [3:0]       ,
    input write_ram_pld_t   south_write_cmd_pld_in  [3:0]       ,
    input write_ram_pld_t   north_write_cmd_pld_in  [3:0]       ,

    output logic [7:0]      toram_west_write_cmd_vld_in         ,
    output logic [7:0]      toram_east_write_cmd_vld_in         ,
    output logic [7:0]      toram_south_write_cmd_vld_in        ,
    output logic [7:0]      toram_north_write_cmd_vld_in        ,
    output write_ram_pld_t  toram_west_write_cmd_pld_in [7:0]   ,
    output write_ram_pld_t  toram_east_write_cmd_pld_in [7:0]   ,
    output write_ram_pld_t  toram_south_write_cmd_pld_in[7:0]   ,
    output write_ram_pld_t  toram_north_write_cmd_pld_in[7:0]  
);

    generate
        for(genvar i=0;i<4;i=i+1)begin:WEST_WRITE_GEN
            always_comb begin
                toram_west_write_cmd_vld_in[2*i]  = 'b0;
                toram_west_write_cmd_vld_in[2*i+1]= 'b0;
                toram_west_write_cmd_pld_in[2*i]  = 'b0;
                toram_west_write_cmd_pld_in[2*i+1]= 'b0;
                if(west_write_cmd_vld_in[i])begin
                    if(west_write_cmd_pld_in[i].write_cmd.req_cmd_pld.dest_ram_id.channel_id)begin
                        toram_west_write_cmd_vld_in[2*i]      = 1'b0;
                        toram_west_write_cmd_vld_in[2*i+1]    = west_write_cmd_vld_in[i];
                        toram_west_write_cmd_pld_in[2*i]      = west_write_cmd_pld_in[i];
                        toram_west_write_cmd_pld_in[2*i+1]    = west_write_cmd_pld_in[i];
                    end
                    else begin
                        toram_west_write_cmd_vld_in[2*i]      = west_write_cmd_vld_in[i];
                        toram_west_write_cmd_vld_in[2*i+1]    = 1'b0;
                        toram_west_write_cmd_pld_in[2*i]      = west_write_cmd_pld_in[i];
                        toram_west_write_cmd_pld_in[2*i+1]    = west_write_cmd_pld_in[i];
                    end
                end
            end
        end
    endgenerate
    generate
        for(genvar i=0;i<4;i=i+1)begin:EAST_WRITE_GEN
            always_comb begin
                toram_east_write_cmd_vld_in[2*i]  = 'b0;
                toram_east_write_cmd_vld_in[2*i+1]= 'b0;
                toram_east_write_cmd_pld_in[2*i]  = 'b0;
                toram_east_write_cmd_pld_in[2*i+1]= 'b0;
                if(east_write_cmd_vld_in[i])begin
                    if(east_write_cmd_pld_in[i].write_cmd.req_cmd_pld.dest_ram_id.channel_id)begin
                        toram_east_write_cmd_vld_in[2*i]      = 1'b0;
                        toram_east_write_cmd_vld_in[2*i+1]    = east_write_cmd_vld_in[i];
                        toram_east_write_cmd_pld_in[2*i]      = east_write_cmd_pld_in[i];
                        toram_east_write_cmd_pld_in[2*i+1]    = east_write_cmd_pld_in[i];
                    end
                    else begin
                        toram_east_write_cmd_vld_in[2*i]      = east_write_cmd_vld_in[i];
                        toram_east_write_cmd_vld_in[2*i+1]    = 1'b0;
                        toram_east_write_cmd_pld_in[2*i]      = east_write_cmd_pld_in[i];
                        toram_east_write_cmd_pld_in[2*i+1]    = east_write_cmd_pld_in[i];
                    end
                end
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<4;i=i+1)begin:NORTH_WRITE_GEN
            always_comb begin
                toram_north_write_cmd_vld_in[2*i]  = 'b0;
                toram_north_write_cmd_vld_in[2*i+1]= 'b0;
                toram_north_write_cmd_pld_in[2*i]  = 'b0;
                toram_north_write_cmd_pld_in[2*i+1]= 'b0;
                if(north_write_cmd_vld_in[i])begin
                    if(north_write_cmd_pld_in[i].write_cmd.req_cmd_pld.dest_ram_id.channel_id)begin
                        toram_north_write_cmd_vld_in[2*i]      = 1'b0;
                        toram_north_write_cmd_vld_in[2*i+1]    = north_write_cmd_vld_in[i];
                        toram_north_write_cmd_pld_in[2*i]      = north_write_cmd_pld_in[i];
                        toram_north_write_cmd_pld_in[2*i+1]    = north_write_cmd_pld_in[i];
                    end
                    else begin
                        toram_north_write_cmd_vld_in[2*i]      = north_write_cmd_vld_in[i];
                        toram_north_write_cmd_vld_in[2*i+1]    = 1'b0;
                        toram_north_write_cmd_pld_in[2*i]      = north_write_cmd_pld_in[i];
                        toram_north_write_cmd_pld_in[2*i+1]    = north_write_cmd_pld_in[i];
                    end
                end
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<4;i=i+1)begin:SOUTH_WRITE_GEN
            always_comb begin
                toram_south_write_cmd_vld_in[2*i]  = 'b0;
                toram_south_write_cmd_vld_in[2*i+1]= 'b0;
                toram_south_write_cmd_pld_in[2*i]  = 'b0;
                toram_south_write_cmd_pld_in[2*i+1]= 'b0;
                if(v_lfdb_to_ram_vld[i] && v_lfdb_to_ram_pld[i].write_cmd.req_cmd_pld.dest_ram_id.channel_id)begin
                    toram_south_write_cmd_vld_in[2*i]   = v_lfdb_to_ram_vld[i];
                    toram_south_write_cmd_vld_in[2*i+1] = south_write_cmd_vld_in[i];
                    toram_south_write_cmd_pld_in[2*i]   = v_lfdb_to_ram_pld[i];
                    toram_south_write_cmd_pld_in[2*i+1] = south_write_cmd_pld_in[i];
                end
                else if(v_lfdb_to_ram_vld[i] && (v_lfdb_to_ram_pld[i].write_cmd.req_cmd_pld.dest_ram_id.channel_id==1'b0))begin
                    toram_south_write_cmd_vld_in[2*i]   = south_write_cmd_vld_in[i];
                    toram_south_write_cmd_vld_in[2*i+1] = v_lfdb_to_ram_vld[i];
                    toram_south_write_cmd_pld_in[2*i]   = south_write_cmd_pld_in[i];
                    toram_south_write_cmd_pld_in[2*i+1] = v_lfdb_to_ram_pld[i];
                end
            end
        end
    endgenerate
    

endmodule