module write_cmd_sel 
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

    logic [3:0]         south_wr_cmd_vld;
    write_ram_pld_t     south_wr_cmd_pld[3:0];
    
    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign south_wr_cmd_vld[i] = v_lfdb_to_ram_vld[i] | south_write_cmd_vld_in[i];
            assign south_wr_cmd_pld[i] = v_lfdb_to_ram_vld[i] ? v_lfdb_to_ram_pld[i] : south_write_cmd_pld_in[i];
        end
    endgenerate
    //assert 同一个hash中，south_wr和linefill不会同时有效
    generate
        for (genvar i=0;i<4;i=i+1)begin
            always_comb begin
                assert ((v_lfdb_to_ram_vld[i] && south_write_cmd_vld_in[i])==1'b0)
                else $error("ERROR: linefill && sourth write conflict!!");
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                if(west_write_cmd_vld_in[i])begin
                    if(west_write_cmd_pld_in[i].write_cmd.req_cmd_pld.dest_ram_id[0])begin
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
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                if(east_write_cmd_vld_in[i])begin
                    if(east_write_cmd_pld_in[i].write_cmd.req_cmd_pld.dest_ram_id[0])begin
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
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                if(north_write_cmd_vld_in[i])begin
                    if(north_write_cmd_pld_in[i].write_cmd.req_cmd_pld.dest_ram_id[0])begin
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
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                if(south_wr_cmd_vld[i])begin
                    if(south_wr_cmd_pld[i].write_cmd.req_cmd_pld.dest_ram_id[0])begin
                        toram_south_write_cmd_vld_in[2*i]      = 1'b0;
                        toram_south_write_cmd_vld_in[2*i+1]    = south_wr_cmd_vld[i];
                        toram_south_write_cmd_pld_in[2*i]      = south_wr_cmd_pld[i];
                        toram_south_write_cmd_pld_in[2*i+1]    = south_wr_cmd_pld[i];
                    end
                    else begin
                        toram_south_write_cmd_vld_in[2*i]      = south_wr_cmd_vld[i];
                        toram_south_write_cmd_vld_in[2*i+1]    = 1'b0;
                        toram_south_write_cmd_pld_in[2*i]      = south_wr_cmd_pld[i];
                        toram_south_write_cmd_pld_in[2*i+1]    = south_wr_cmd_pld[i];
                    end
                end
            end
        end
    endgenerate

endmodule