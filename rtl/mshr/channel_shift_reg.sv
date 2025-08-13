module channel_shift_reg 
    import vector_cache_pkg::*; 
    #( 
        parameter integer unsigned CHANNEL_SHIFT_REG_WIDTH = 20
    )
    ( 
        input  logic                   clk                     ,
        input  logic                   rst_n                   ,
        input  logic                   w_dataram_wr_vld        ,
        input  logic                   e_dataram_wr_vld        ,
        input  logic                   s_dataram_wr_vld        ,
        input  logic                   n_dataram_wr_vld        ,
        input  logic                   linefill_req_vld        ,
        input  logic                   w_wr_channel_sel        ,
        input  logic                   e_wr_channel_sel        ,
        input  logic                   s_wr_channel_sel        ,
        input  logic                   n_wr_channel_sel        ,
        input  logic                   lf_wr_channel_sel       ,

        output logic [CHANNEL_SHIFT_REG_WIDTH-1:0]  channel_shift_reg[1:0]     
    );

    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] next_shift;

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            for(int i=0;i<2;i=i+1)begin
                channel_shift_reg[i] <= 'b0 ;
            end
        end                 
        else begin
            channel_shift_reg[0] <= {1'b0, channel_shift_reg[0][CHANNEL_SHIFT_REG_WIDTH-1:1]};
            channel_shift_reg[1] <= {1'b0, channel_shift_reg[1][CHANNEL_SHIFT_REG_WIDTH-1:1]};
            if(w_dataram_wr_vld)begin
                if(w_wr_channel_sel)begin
                    channel_shift_reg[0][WR_CMD_DELAY_WEST]  <= 1'b1;
                end else begin
                    channel_shift_reg[1][WR_CMD_DELAY_WEST]  <= 1'b1;
                end
            end
            if(e_dataram_wr_vld)begin
                if(e_wr_channel_sel)begin
                    channel_shift_reg[0][WR_CMD_DELAY_EAST]  <= 1'b1;
                end else begin
                    channel_shift_reg[1][WR_CMD_DELAY_EAST]  <= 1'b1;
                end
            end   
            if(s_dataram_wr_vld)begin
                if(s_wr_channel_sel)begin
                    channel_shift_reg[0][WR_CMD_DELAY_SOUTH] <= 1'b1;
                end else begin
                    channel_shift_reg[1][WR_CMD_DELAY_SOUTH] <= 1'b1;
                end
            end   
            if(n_dataram_wr_vld)begin
                if(n_wr_channel_sel)begin
                    channel_shift_reg[0][WR_CMD_DELAY_NORTH] <= 1'b1;
                end else begin
                    channel_shift_reg[1][WR_CMD_DELAY_NORTH] <= 1'b1;
                end
            end   
            if(linefill_req_vld)begin
                if(lf_wr_channel_sel)begin
                    channel_shift_reg[0][WR_CMD_DELAY_SOUTH] <= 1'b1;
                end else begin
                    channel_shift_reg[1][WR_CMD_DELAY_SOUTH] <= 1'b1;
                end
            end   
        end
    end


endmodule