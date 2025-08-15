module vec_cache_channel_shift_reg
    import vector_cache_pkg::*;
#(
    parameter integer unsigned CHANNEL_SHIFT_REG_WIDTH = 20
) (
    input   logic                               clk                     ,    
    input   logic                               rst_n                   ,

    input   logic                               update_en_w             ,
    input   logic                               update_en_e             ,
    input   logic                               update_en_s             ,
    input   logic                               update_en_n             ,
    input   logic                               update_en_lf            ,

    output  logic                               write_permission_w      ,
    output  logic                               write_permission_e      ,
    output  logic                               write_permission_s      ,
    output  logic                               write_permission_n      ,
    output  logic                               write_permission_lf     ,

    output  logic                               read_permission         
);

    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] channel_shift_reg;

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n)begin
            channel_shift_reg <= 'b0 ;
        end                 
        else begin
            channel_shift_reg <= {1'b0, channel_shift_reg[CHANNEL_SHIFT_REG_WIDTH-1:1]};
            if(update_en_w)begin
                channel_shift_reg[WR_CMD_DELAY_WEST]  <= 1'b1;
            end
            if(update_en_e)begin
                channel_shift_reg[WR_CMD_DELAY_EAST]  <= 1'b1;
            end   
            if(update_en_s)begin
                channel_shift_reg[WR_CMD_DELAY_SOUTH] <= 1'b1;
            end   
            if(update_en_n)begin
                channel_shift_reg[WR_CMD_DELAY_NORTH] <= 1'b1;
            end   
            if(update_en_lf)begin
                channel_shift_reg[WR_CMD_DELAY_LF] <= 1'b1;
            end   
        end
    end


    assign write_permission_w   = (channel_shift_reg[WR_CMD_DELAY_WEST ]==1'b0);
    assign write_permission_e   = (channel_shift_reg[WR_CMD_DELAY_EAST ]==1'b0);
    assign write_permission_s   = (channel_shift_reg[WR_CMD_DELAY_SOUTH]==1'b0);
    assign write_permission_n   = (channel_shift_reg[WR_CMD_DELAY_NORTH]==1'b0);
    assign write_permission_lf  = (channel_shift_reg[WR_CMD_DELAY_LF   ]==1'b0);
    assign read_permission      = (channel_shift_reg[0]==1'b0);


endmodule