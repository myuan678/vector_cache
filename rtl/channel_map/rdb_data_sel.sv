module rdb_data_sel 
    import vector_cache_pkg::*;
    (   input  logic [7:0]         east_data_out_vld_todb              ,
        input  group_data_pld_t    east_data_out_todb       [7:0]      ,    
        input  logic [7:0]         west_data_out_vld_todb              ,
        input  group_data_pld_t    west_data_out_todb       [7:0]      ,       
        input  logic [7:0]         south_data_out_vld_todb             ,
        input  group_data_pld_t    south_data_out_todb      [7:0]      ,   
        input  logic [7:0]         north_data_out_vld_todb             ,
        input  group_data_pld_t    north_data_out_todb      [7:0]      ,  

        output logic [3:0]         east_data_out_vld_to_rdb            ,
        output group_data_pld_t    east_data_out_to_rdb     [3:0]      ,    
        output logic [3:0]         west_data_out_vld_to_rdb            ,
        output group_data_pld_t    west_data_out_to_rdb     [3:0]      ,       
        output logic [3:0]         south_data_out_vld_to_rdb           ,
        output group_data_pld_t    south_data_out_to_rdb    [3:0]      ,   
        output logic [3:0]         north_data_out_vld_to_rdb           ,
        output group_data_pld_t    north_data_out_to_rdb    [3:0]      ,
        
        output logic [3:0]         evict_data_out_vld_to_evdb          ,
        output group_data_pld_t    evict_data_out_to_evdb    [3:0]       
    );
    logic [3:0]         south_data_out_vld        ;
    group_data_pld_t    south_data_out    [3:0]   ;  

    generate
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                east_data_out_vld_to_rdb[i]  = east_data_out_vld_todb[2*i] | east_data_out_vld_todb[2*i+1];
                east_data_out_to_rdb[i]      = east_data_out_vld_todb[2*i] ? east_data_out_todb[2*i] : east_data_out_todb[2*i+1];

                west_data_out_vld_to_rdb[i]  = west_data_out_vld_todb[2*i] | west_data_out_vld_todb[2*i+1];
                west_data_out_to_rdb[i]      = west_data_out_vld_todb[2*i] ? west_data_out_todb[2*i] : west_data_out_todb[2*i+1];

                north_data_out_vld_to_rdb[i] = north_data_out_vld_todb[2*i] | north_data_out_vld_todb[2*i+1];
                north_data_out_to_rdb[i]     = north_data_out_vld_todb[2*i] ? north_data_out_todb[2*i] : north_data_out_todb[2*i+1];

                south_data_out_vld[i]       = south_data_out_vld_todb[2*i] | south_data_out_vld_todb[2*i+1];
                south_data_out[i]           = south_data_out_vld_todb[2*i] ? south_data_out_todb[2*i] : south_data_out_todb[2*i+1];
            end
        end
    endgenerate

    ////assert 同一hash的2channel不会同时有效
    //generate
    //    for(genvar i=0;i<4;i=i+1)begin
    //        always_comb begin
    //            assert (west_data_out_vld_todb[2*i] + west_data_out_vld_todb[2*i+1]<= 1)
    //            else $error("ERROR! two channel for 1hash valid conflict!!");
    //        end
    //    end
    //endgenerate
    //generate
    //    for(genvar i=0;i<4;i=i+1)begin
    //        always_comb begin
    //            assert (east_data_out_vld_todb[2*i] + east_data_out_vld_todb[2*i+1]<= 1'b1)
    //            else $error("ERROR! two channel for 1hash valid conflict!!");
    //        end
    //    end
    //endgenerate
    //generate
    //    for(genvar i=0;i<4;i=i+1)begin
    //        always_comb begin
    //            assert (north_data_out_vld_todb[2*i] + north_data_out_vld_todb[2*i+1]<= 1'b1)
    //            else $error("ERROR! two channel for 1hash valid conflict!!");
    //        end
    //    end
    //endgenerate
    //generate
    //    for(genvar i=0;i<4;i=i+1)begin
    //        always_comb begin
    //            assert (south_data_out_vld_todb[2*i] + south_data_out_vld_todb[2*i+1]<= 1'b1)
    //            else $error("ERROR! two channel for 1hash valid conflict!!");
    //        end
    //    end
    //endgenerate

    generate
        for(genvar i=0;i<4;i=i+1)begin
            always_comb begin
                south_data_out_vld_to_rdb[i]  = south_data_out_vld[i] && (south_data_out[i].cmd_pld.opcode==2'd1);//read
                evict_data_out_vld_to_evdb[i] = south_data_out_vld[i] && (south_data_out[i].cmd_pld.opcode==2'd2);//evict

                south_data_out_to_rdb[i]      = south_data_out[i];
                evict_data_out_to_evdb[i]     = south_data_out[i];
            end
        end
    endgenerate

    ////assert south read && evict不会同时有效
    //generate
    //    for(genvar i=0;i<4;i=i+1)begin
    //        always_comb begin
    //            assert (south_data_out_vld_to_rdb[i] + evict_data_out_vld_to_evdb[i]<= 1'b1)
    //            else $error("ERROR: EVICT DB data  && SOUTHRDB data conflict!! only one can be valid");
    //        end
    //    end
    //endgenerate



endmodule