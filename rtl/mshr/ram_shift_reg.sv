module ram_shift_reg 
    import vector_cache_pkg::*;
    #( 
        parameter integer unsigned RAM_SHIFT_REG_WIDTH = 20
    )( 
        input  logic                                clk,
        input  logic                                rst_n,
        input  logic                                w_dataram_wr_vld        ,
        input  logic                                e_dataram_wr_vld        ,
        input  logic                                s_dataram_wr_vld        ,
        input  logic                                n_dataram_wr_vld        ,
        input  logic                                linefill_req_vld        ,
        input  logic [2:0]                          w_wr_ram_sel            ,   
        input  logic [2:0]                          e_wr_ram_sel            ,   
        input  logic [2:0]                          s_wr_ram_sel            ,   
        input  logic [2:0]                          n_wr_ram_sel            ,   
        input  logic [2:0]                          lf_wr_ram_sel           ,    

        output logic [RAM_SHIFT_REG_WIDTH-1:0]      ram_shift_reg[7:0]
    );

    localparam integer unsigned     WR_BLOCK0_DELAY = 8;
    localparam integer unsigned     WR_BLOCK1_DELAY = 7;
    localparam integer unsigned     WR_BLOCK2_DELAY = 6;
    localparam integer unsigned     WR_BLOCK3_DELAY = 5; 


    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<8;i=i+1)begin
                ram_shift_reg[i] <= 'b0;
            end
        end
        else begin
            for(int i=0;i<8;i=i+1)begin
                ram_shift_reg[i] <= {1'b0,ram_shift_reg[i][RAM_SHIFT_REG_WIDTH-1:1]};
            end
            if(w_dataram_wr_vld ) begin
                case(w_wr_ram_sel[2:1])
                    2'd0:ram_shift_reg[w_wr_ram_sel][WR_CMD_DELAY_WEST+WR_BLOCK0_DELAY] <= 1'b1;
                    2'd1:ram_shift_reg[w_wr_ram_sel][WR_CMD_DELAY_WEST+WR_BLOCK1_DELAY] <= 1'b1;
                    2'd2:ram_shift_reg[w_wr_ram_sel][WR_CMD_DELAY_WEST+WR_BLOCK2_DELAY] <= 1'b1;
                    2'd3:ram_shift_reg[w_wr_ram_sel][WR_CMD_DELAY_WEST+WR_BLOCK3_DELAY] <= 1'b1;   
                endcase    
            end
            if(e_dataram_wr_vld)begin
                case(e_wr_ram_sel[2:1])
                    2'd0:ram_shift_reg[e_wr_ram_sel][WR_CMD_DELAY_EAST+WR_BLOCK0_DELAY] <= 1'b1;
                    2'd1:ram_shift_reg[e_wr_ram_sel][WR_CMD_DELAY_EAST+WR_BLOCK1_DELAY] <= 1'b1;
                    2'd2:ram_shift_reg[e_wr_ram_sel][WR_CMD_DELAY_EAST+WR_BLOCK2_DELAY] <= 1'b1;
                    2'd3:ram_shift_reg[e_wr_ram_sel][WR_CMD_DELAY_EAST+WR_BLOCK3_DELAY] <= 1'b1;   
                endcase 
            end
            if(s_dataram_wr_vld)begin
                case(s_wr_ram_sel[2:1])
                    2'd0:ram_shift_reg[s_wr_ram_sel][WR_CMD_DELAY_SOUTH+WR_BLOCK0_DELAY] <= 1'b1;
                    2'd1:ram_shift_reg[s_wr_ram_sel][WR_CMD_DELAY_SOUTH+WR_BLOCK1_DELAY] <= 1'b1;
                    2'd2:ram_shift_reg[s_wr_ram_sel][WR_CMD_DELAY_SOUTH+WR_BLOCK2_DELAY] <= 1'b1;
                    2'd3:ram_shift_reg[s_wr_ram_sel][WR_CMD_DELAY_SOUTH+WR_BLOCK3_DELAY] <= 1'b1;   
                endcase 
            end
            if(n_dataram_wr_vld)begin
                case(n_wr_ram_sel[2:1])
                    2'd0:ram_shift_reg[n_wr_ram_sel][WR_CMD_DELAY_NORTH+WR_BLOCK0_DELAY] <= 1'b1;
                    2'd1:ram_shift_reg[n_wr_ram_sel][WR_CMD_DELAY_NORTH+WR_BLOCK1_DELAY] <= 1'b1;
                    2'd2:ram_shift_reg[n_wr_ram_sel][WR_CMD_DELAY_NORTH+WR_BLOCK2_DELAY] <= 1'b1;
                    2'd3:ram_shift_reg[n_wr_ram_sel][WR_CMD_DELAY_NORTH+WR_BLOCK3_DELAY] <= 1'b1;   
                endcase 
            end
            if(linefill_req_vld)begin
                case(lf_wr_ram_sel[2:1])
                    2'd0:ram_shift_reg[lf_wr_ram_sel][WR_CMD_DELAY_LF+WR_BLOCK0_DELAY] <= 1'b1;
                    2'd1:ram_shift_reg[lf_wr_ram_sel][WR_CMD_DELAY_LF+WR_BLOCK1_DELAY] <= 1'b1;
                    2'd2:ram_shift_reg[lf_wr_ram_sel][WR_CMD_DELAY_LF+WR_BLOCK2_DELAY] <= 1'b1;
                    2'd3:ram_shift_reg[lf_wr_ram_sel][WR_CMD_DELAY_LF+WR_BLOCK3_DELAY] <= 1'b1;   
                endcase 
            end
        end
    end


endmodule
