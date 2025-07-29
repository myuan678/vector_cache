module ten_to_two_arb 
    import vector_cache_pkg::*; 
    #(
    parameter integer unsigned RD_REQ_NUM = 5,
    parameter integer unsigned WR_REQ_NUM = 5,
    parameter integer unsigned CHANNEL_SHIFT_REG_WIDTH = 10,
    parameter integer unsigned RAM_SHIFT_REG_WIDTH = 20,
    parameter integer unsigned REQ_NUM = RD_REQ_NUM + WR_REQ_NUM
    ) (
    input  logic                    clk                     ,
    input  logic                    rst_n                   ,
    input  logic [RD_REQ_NUM-1:0]   rd_vld                  ,
    input  arb_out_req_t            rd_pld[RD_REQ_NUM-1:0]  ,
    output logic [RD_REQ_NUM-1:0]   rd_rdy                  ,


    input  logic [WR_REQ_NUM-1:0]   wr_vld                  ,
    input  arb_out_req_t            wr_pld[WR_REQ_NUM-1:0]  ,
    output logic [WR_REQ_NUM-1:0]   wr_rdy                  ,

    output logic                    grant_req_vld_0         ,
    output arb_out_req_t            grant_req_pld_0         ,
    output logic                    grant_req_vld_1         ,
    output arb_out_req_t            grant_req_pld_1         ,
    input  logic [1:0]              grant_req_rdy            //sram rdy
);

    logic [REQ_NUM-1        :0]         all_req_vld                             ;
    arb_out_req_t                       all_req_pld             [REQ_NUM-1:0]   ;
    arb_out_req_t                       grant_req_pld           [1:0]           ;
    logic [RAM_SHIFT_REG_WIDTH-1    :0] ram_timer_shift_reg     [7 :0]          ;
    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] channel_timer_shift_reg [1 :0]          ;
    logic [1                        :0] block_id                [REQ_NUM-1:0]   ;
    logic [4                        :0] dest_ram_id             [REQ_NUM-1:0]   ;//某个block中的某个sram，5bit
    logic [1                        :0] direction_id            [REQ_NUM-1:0]   ;//请求的来源方向
    logic [RD_REQ_NUM-1             :0] rd_pre_allow_bit                        ;
    logic [RD_REQ_NUM-1             :0] rd_allow_bit                            ;
    logic [RD_REQ_NUM-1             :0] allowed_rd_vld                          ;
    logic [WR_REQ_NUM-1             :0] wr_pre_allow_bit                        ;
    logic [WR_REQ_NUM-1             :0] wr_allow_bit                            ;
    logic [WR_REQ_NUM-1             :0] allowed_wr_vld                          ;



    //-----------direction_id-------------------------------------------------------------------
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1) begin
            assign direction_id[i] = rd_pld[i].txnid[1:0];//txnid的低两位作为方向id
        end
    endgenerate
    generate
        for(genvar i=RD_REQ_NUM;i<REQ_NUM;i=i+1) begin
            assign direction_id[i] = wr_pld[i-RD_REQ_NUM].txnid[1:0];//txnid的低两位作为方向id
        end
    endgenerate

//-----------dest_ram_id-------------------------------------------------------------------
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1)begin
            assign dest_ram_id[i] = rd_pld[i].dest_ram_id;
        end
    endgenerate
    generate
        for(genvar i=RD_REQ_NUM;i<REQ_NUM;i=i+1) begin
            assign dest_ram_id[i] = wr_pld[i-RD_REQ_NUM].dest_ram_id;
        end
    endgenerate

//-----------block_id -------------------------------------------------------------------
    generate
        for(genvar i=0;i<REQ_NUM;i=i+1) begin
            assign block_id[i] = dest_ram_id[i][2:1];
        end
    endgenerate
//----------------------------------------------------------------------------------------
    localparam integer unsigned RD_BLOCK0_DELAY = 1;
    localparam integer unsigned RD_BLOCK1_DELAY = 2;
    localparam integer unsigned RD_BLOCK2_DELAY = 3;
    localparam integer unsigned RD_BLOCK3_DELAY = 4; 
    localparam integer unsigned WR_BLOCK0_DELAY = 8;
    localparam integer unsigned WR_BLOCK1_DELAY = 7;
    localparam integer unsigned WR_BLOCK2_DELAY = 6;
    localparam integer unsigned WR_BLOCK3_DELAY = 5; 
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1)begin
            //检查channel的冲突，block0，read直接上channel，所以检查channel_timer的最低bit是否为1，不为1则说明下一拍没有写冲突，
            assign rd_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][0]==1'b0);
        end
    endgenerate
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1)begin
           always_comb begin
                case(block_id[i]) 
                    2'b00: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][RD_BLOCK0_DELAY]==1'b0);
                    2'b01: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][RD_BLOCK1_DELAY]==1'b0);
                    2'b10: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][RD_BLOCK2_DELAY]==1'b0);
                    2'b11: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][RD_BLOCK3_DELAY]==1'b0);
                endcase
                allowed_rd_vld[i] =  rd_vld[i] && rd_allow_bit[i];//不被write 屏蔽的读请求
           end
        end
    endgenerate
    
    generate
        for(genvar i=0;i<WR_REQ_NUM;i=i+1)begin
            //写请求经过WR_CMD_DELAY拍后占用channel，检查第WR_CMD_DELAY bit不为1说明这么多拍后不会有写冲突
            //四个方向的写请求CMD_DELAY不同，所以五个写请求不需要检查地址冲突
            always_comb begin
                if(i==0)begin
                    wr_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][WR_CMD_DELAY_LF]==1'b0);
                end
                else begin
                    case(direction_id[i])
                        2'b00: wr_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][WR_CMD_DELAY_WEST]==1'b0);
                        2'b01: wr_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][WR_CMD_DELAY_EAST]==1'b0);
                        2'b10: wr_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][WR_CMD_DELAY_SOUTH]==1'b0);
                        2'b11: wr_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][WR_CMD_DELAY_NORTH]==1'b0);
                    endcase
                end
            end
        end
    endgenerate
    generate//wr_vld[4:1] write; [0] linefill
        for(genvar i=0;i<WR_REQ_NUM; i=i+1)begin
            always_comb begin
                if(i==0)begin//linefill没有方向id，默认是south
                    case(block_id[i])
                        2'b00: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_LF+WR_BLOCK0_DELAY]==1'b0);
                        2'b01: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_LF+WR_BLOCK1_DELAY]==1'b0);
                        2'b10: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_LF+WR_BLOCK2_DELAY]==1'b0);
                        2'b11: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_LF+WR_BLOCK3_DELAY]==1'b0);
                    endcase
                end
                else begin
                    case(block_id[i]) 
                        2'b00: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `WEST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_WEST+WR_BLOCK0_DELAY]   == 1'b0) :       //访问block0，west write应检查shift_reg的bit[WEST_WR_BIT]
                                                 (direction_id[i] == `EAST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_EAST+WR_BLOCK0_DELAY]   == 1'b0) :       //访问block0，east write应检查shift_reg的bit[3]
                                                 (direction_id[i] == `SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_SOUTH+WR_BLOCK0_DELAY]  == 1'b0) :       //访问block0，south write应检查shift_reg的bit[10]
                                                 (direction_id[i] == `NORTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_NORTH+WR_BLOCK0_DELAY]  == 1'b0) : 1'b0); //访问block0，north write应检查shift_reg的bit[8]
                        2'b01: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `WEST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_WEST+WR_BLOCK1_DELAY]   == 1'b0) :       //访问block0，west write应检查shift_reg的bit[WEST_WR_BIT]
                                                 (direction_id[i] == `EAST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_EAST+WR_BLOCK1_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_SOUTH+WR_BLOCK1_DELAY]  == 1'b0) :       
                                                 (direction_id[i] == `NORTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_NORTH+WR_BLOCK1_DELAY]  == 1'b0) : 1'b0); 
                        2'b10: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `WEST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_WEST+WR_BLOCK2_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `EAST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_EAST+WR_BLOCK2_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_SOUTH+WR_BLOCK2_DELAY]  == 1'b0) :       
                                                 (direction_id[i] == `NORTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_NORTH+WR_BLOCK2_DELAY]  == 1'b0) : 1'b0); 
                        2'b11: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `WEST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_WEST+WR_BLOCK3_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `EAST ) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_EAST+WR_BLOCK3_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_SOUTH+WR_BLOCK3_DELAY]  == 1'b0) :       
                                                 (direction_id[i] == `NORTH) ? (ram_timer_shift_reg[dest_ram_id[i]][WR_CMD_DELAY_NORTH+WR_BLOCK3_DELAY]  == 1'b0) : 1'b0); 
                    endcase
                end
            end
            assign allowed_wr_vld[i] =  wr_vld[i] && wr_allow_bit[i];//不被write屏蔽的写请求
        end
    endgenerate

    assign all_req_vld = {allowed_rd_vld,allowed_wr_vld};
    assign all_req_pld = {rd_pld, wr_pld};
    assign grant_req_pld_0 = grant_req_pld[0];
    assign grant_req_pld_1 = grant_req_pld[1];

    n_to_2_arb #(
        .N          (REQ_NUM),
        .PLD_WIDTH  (($bits(arb_out_req_t)))
    ) u_arbiter (
        .clk        (clk                               ),
        .rst_n      (rst_n                             ),
        .req_vld    (all_req_vld                       ),
        .req_rdy    ({rd_rdy, wr_rdy}                  ),
        .req_pld    (all_req_pld                       ),
        .grant_vld  ({grant_req_vld_0, grant_req_vld_1}),
        .grant_rdy  (grant_req_rdy                     ),    
        .grant_pld  (grant_req_pld                     )
    );

    function automatic [CHANNEL_SHIFT_REG_WIDTH-1:0] write_set_shift_channel_mask;
        input logic [1:0] direc_id;
        case(direc_id)
            2'b00: write_set_shift_channel_mask[WR_CMD_DELAY_WEST] = 1'b1;
            2'b01: write_set_shift_channel_mask[WR_CMD_DELAY_EAST] = 1'b1;
            2'b10: write_set_shift_channel_mask[WR_CMD_DELAY_SOUTH]= 1'b1;
            2'b11: write_set_shift_channel_mask[WR_CMD_DELAY_NORTH]= 1'b1;
            default: write_set_shift_channel_mask = 'b0;
        endcase
    endfunction

    function automatic [RAM_SHIFT_REG_WIDTH-1:0] write_set_shift_ram_mask;
        input logic [1:0] bk_id;
        input logic [1:0] direc_id;
        case (bk_id)
            2'b00: begin//block0
                case (direc_id)
                    2'b00: write_set_shift_ram_mask[WR_CMD_DELAY_WEST+WR_BLOCK0_DELAY]  = 1'b1; // west
                    2'b01: write_set_shift_ram_mask[WR_CMD_DELAY_EAST+WR_BLOCK0_DELAY]  = 1'b1; // east
                    2'b10: write_set_shift_ram_mask[WR_CMD_DELAY_SOUTH+WR_BLOCK0_DELAY] = 1'b1; // south
                    2'b11: write_set_shift_ram_mask[WR_CMD_DELAY_NORTH+WR_BLOCK0_DELAY] = 1'b1; // north
                    default: write_set_shift_ram_mask = 'b0;
                endcase
            end
            2'b01: begin//block1
                case (direc_id)
                    2'b00: write_set_shift_ram_mask[WR_CMD_DELAY_WEST+WR_BLOCK1_DELAY]  = 1'b1; // west
                    2'b01: write_set_shift_ram_mask[WR_CMD_DELAY_EAST+WR_BLOCK1_DELAY]  = 1'b1; // east
                    2'b10: write_set_shift_ram_mask[WR_CMD_DELAY_SOUTH+WR_BLOCK1_DELAY] = 1'b1; // south
                    2'b11: write_set_shift_ram_mask[WR_CMD_DELAY_NORTH+WR_BLOCK1_DELAY] = 1'b1; // north
                    default: write_set_shift_ram_mask = 'b0;
                endcase
            end
            2'b10:begin//block2
                case (direc_id)
                    2'b00: write_set_shift_ram_mask[WR_CMD_DELAY_WEST+WR_BLOCK2_DELAY]  = 1'b1; // west
                    2'b01: write_set_shift_ram_mask[WR_CMD_DELAY_EAST+WR_BLOCK2_DELAY]  = 1'b1; // east
                    2'b10: write_set_shift_ram_mask[WR_CMD_DELAY_SOUTH+WR_BLOCK2_DELAY] = 1'b1; // south
                    2'b11: write_set_shift_ram_mask[WR_CMD_DELAY_NORTH+WR_BLOCK2_DELAY] = 1'b1; // north
                    default: write_set_shift_ram_mask = 'b0;
                endcase
            end 
            2'b11: begin//block3
                case (direc_id)
                    2'b00: write_set_shift_ram_mask[WR_CMD_DELAY_WEST+WR_BLOCK3_DELAY]  = 1'b1; // west
                    2'b01: write_set_shift_ram_mask[WR_CMD_DELAY_EAST+WR_BLOCK3_DELAY]  = 1'b1; // east
                    2'b10: write_set_shift_ram_mask[WR_CMD_DELAY_SOUTH+WR_BLOCK3_DELAY] = 1'b1; // south
                    2'b11: write_set_shift_ram_mask[WR_CMD_DELAY_NORTH+WR_BLOCK3_DELAY] = 1'b1; // north
                    default: write_set_shift_ram_mask = 'b0;
                endcase
            end
            default: write_set_shift_ram_mask = 'b0;
        endcase
    endfunction

    logic [CHANNEL_SHIFT_REG_WIDTH  :0]  set_req0_channel_timer;
    logic [CHANNEL_SHIFT_REG_WIDTH  :0]  set_req1_channel_timer;
    logic [RAM_SHIFT_REG_WIDTH      :0]  set_req0_ram_timer;
    logic [RAM_SHIFT_REG_WIDTH      :0]  set_req1_ram_timer;
    always_comb begin
        set_req0_channel_timer = 'b0;
        set_req0_ram_timer     = 'b0;
        if(grant_req_pld_0.opcode==`WRITE )begin //write
            set_req0_channel_timer = write_set_shift_channel_mask(grant_req_pld_0.txnid.direction_id);
            set_req0_ram_timer     = write_set_shift_ram_mask(grant_req_pld_0.dest_ram_id[2:1],grant_req_pld_0.txnid.direction_id);
        end
        else if(grant_req_pld_0.opcode==`LINEFILL)begin//linefill
            set_req0_channel_timer[WR_CMD_DELAY_LF] = 1'b1;
            case(grant_req_pld_0.dest_ram_id[2:1])//block
                2'b00: set_req0_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK0_DELAY] = 1'b1;
                2'b01: set_req0_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK1_DELAY] = 1'b1;
                2'b10: set_req0_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK2_DELAY] = 1'b1;
                2'b11: set_req0_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK3_DELAY] = 1'b1;
            endcase
        end
    end
    always_comb begin
        set_req1_channel_timer = 'b0;
        set_req1_ram_timer     = 'b0;
        if(grant_req_pld_1.opcode==`WRITE )begin //write
            set_req1_channel_timer = write_set_shift_channel_mask(grant_req_pld_1.txnid.direction_id);
            set_req1_ram_timer     = write_set_shift_ram_mask(grant_req_pld_1.dest_ram_id[2:1],grant_req_pld_1.txnid.direction_id);
        end
        else if(grant_req_pld_1.opcode==`LINEFILL)begin//linefill
            set_req1_channel_timer[WR_CMD_DELAY_LF] = 1'b1;
            case(grant_req_pld_1.dest_ram_id[2:1])
                2'b00: set_req1_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK0_DELAY] = 1'b1;
                2'b01: set_req1_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK1_DELAY] = 1'b1;
                2'b10: set_req1_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK2_DELAY] = 1'b1;
                2'b11: set_req1_ram_timer[WR_CMD_DELAY_LF+WR_BLOCK3_DELAY] = 1'b1;
            endcase
        end
    end


    generate
        for (genvar i = 0; i < 8; i = i + 1) begin : RAM_MASK
            logic apply_req0 ;
            logic apply_req1 ;
            logic [RAM_SHIFT_REG_WIDTH-1:0] combined_mask; 
            // 确定当前ram是否是被grant选中的，确定掩码是否需要对该slave生
            assign apply_req0 = grant_req_vld_0 && (grant_req_pld_0.dest_ram_id == i);
            assign apply_req1 = grant_req_vld_1 && (grant_req_pld_1.dest_ram_id == i);
            assign combined_mask= (apply_req0 ? set_req0_ram_timer : 'b0) | (apply_req1 ? set_req1_ram_timer : 'b0);
            // 更新对应ram的timer_shift_reg
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) ram_timer_shift_reg[i] <= 'b0;
                else        ram_timer_shift_reg[i] <= (ram_timer_shift_reg[i] >> 1) | combined_mask;
            end
        end
    endgenerate

    generate
        for (genvar i = 0; i < 2; i = i + 1) begin : CHANNEL_MASK
            logic apply_req0 ;
            logic apply_req1 ;
            logic [CHANNEL_SHIFT_REG_WIDTH-1:0] combined_mask; 
            // 确定当前请求的是该hash中的ram0还是ram1，确定channel的mask对哪一个生效
            assign apply_req0 = grant_req_vld_0 && (grant_req_pld_0.dest_ram_id[0] == i);
            assign apply_req1 = grant_req_vld_1 && (grant_req_pld_1.dest_ram_id[0] == i);
            assign combined_mask= (apply_req0 ? set_req0_channel_timer : 'b0) | (apply_req1 ? set_req1_channel_timer : 'b0);
            // 更新对应的timer_shift_reg
            always @(posedge clk or negedge rst_n) begin
                if (!rst_n) channel_timer_shift_reg[i] <= 'b0;
                else        channel_timer_shift_reg[i] <= (channel_timer_shift_reg[i] >> 1) | combined_mask;
            end
        end
    endgenerate

    

endmodule
