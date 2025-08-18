module vec_cache_tag_dirty 
    import vector_cache_pkg::*;
( 
    input  logic                            clk             ,
    input  logic                            rst_n           ,
    input  logic                            dirty_update_0  ,
    input  logic                            dirty_update_1  ,
    input  logic                            dirty_clean_0   ,
    input  logic                            dirty_clean_1   ,

    input  logic [2**INDEX_WIDTH-1 :0]      tag_idx_oh_0    ,
    input  logic [2**INDEX_WIDTH-1 :0]      tag_idx_oh_1    ,
    input  logic [WAY_NUM-1        :0]      dest_way_oh_0   ,
    input  logic [WAY_NUM-1        :0]      dest_way_oh_1   ,

    output logic [WAY_NUM-1        :0]      tag_dirty[2**INDEX_WIDTH-1:0] 
);


    generate
        for(genvar i=0;i<2**INDEX_WIDTH;i=i+1)begin
            for(genvar j=0;j<WAY_NUM;j=j+1)begin
                always_ff@(posedge clk or negedge rst_n)begin//write->dirty
                    if(!rst_n) begin
                        tag_dirty[i][j] <= 1'b0;
                    end 
                    else if( dirty_update_0 && A_tag_idx_oh[i] && A_dest_way_oh[j]) begin
                        tag_dirty[i][j] <= 1'b1; 
                    end
                    else if(dirty_update_1 && B_tag_idx_oh[i] && B_dest_way_oh[j]) begin
                        tag_dirty[i][j] <= 1'b1; 
                    end
                    else if(dirty_clean_0 && A_tag_idx_oh[i] && A_dest_way_oh[j] ) begin
                        tag_dirty[i][j] <= 1'b0; 
                    end 
                    else if(dirty_clean_1 && B_tag_idx_oh[i] && B_dest_way_oh[j] ) begin
                        tag_dirty[i][j] <= 1'b0; 
                    end
                end
            end
        end
    endgenerate

endmodule