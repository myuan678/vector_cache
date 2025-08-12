module stage2_arbiter 
    import vector_cache_pkg::*; 
    #(
    parameter integer unsigned RD_REQ_NUM = 5,
    parameter integer unsigned WR_REQ_NUM = 5,
    parameter integer unsigned CHANNEL_SHIFT_REG_WIDTH = 10,
    parameter integer unsigned RAM_SHIFT_REG_WIDTH = 20,
    localparam integer unsigned REQ_NUM = RD_REQ_NUM + WR_REQ_NUM
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

    localparam integer unsigned RD_BLOCK0_DELAY = 1;
    localparam integer unsigned RD_BLOCK1_DELAY = 2;
    localparam integer unsigned RD_BLOCK2_DELAY = 3;
    localparam integer unsigned RD_BLOCK3_DELAY = 4; 
    localparam integer unsigned WR_BLOCK0_DELAY = 8;
    localparam integer unsigned WR_BLOCK1_DELAY = 7;
    localparam integer unsigned WR_BLOCK2_DELAY = 6;
    localparam integer unsigned WR_BLOCK3_DELAY = 5; 

    logic [REQ_NUM-1        :0]         all_req_vld                             ;
    logic [REQ_NUM-1        :0]         all_req_rdy                             ;
    arb_out_req_t                       all_req_pld             [REQ_NUM-1:0]   ;
    logic [REQ_NUM-1        :0]         grant_req_vld                           ;
    arb_out_req_t                       grant_req_pld           [REQ_NUM-1:0]   ;
    logic [RAM_SHIFT_REG_WIDTH-1    :0] ram_timer_shift_reg     [7 :0]          ;
    logic [RAM_SHIFT_REG_WIDTH-1    :0] set_ram_mask            [7 :0]          ;
    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] channel_timer_shift_reg [1 :0]          ;
    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] set_channel_mask        [1 :0]          ;
    logic [1                        :0] block_id                [REQ_NUM-1:0]   ;
    logic [4                        :0] dest_ram_id             [REQ_NUM-1:0]   ;//某个block中的某个sram，5bit
    logic [1                        :0] direction_id            [REQ_NUM-1:0]   ;//请求的来源方向
    logic [RD_REQ_NUM-1             :0] rd_pre_allow_bit                        ;
    logic [RD_REQ_NUM-1             :0] rd_allow_bit                            ;
    logic [RD_REQ_NUM-1             :0] allowed_rd_vld                          ;
    logic [WR_REQ_NUM-1             :0] wr_pre_allow_bit                        ;
    logic [WR_REQ_NUM-1             :0] wr_allow_bit                            ;
    logic [WR_REQ_NUM-1             :0] allowed_wr_vld                          ;
    logic [$clog2(REQ_NUM)-1        :0] first_grant_idx                         ;
    logic [$clog2(REQ_NUM)-1        :0] second_grant_idx                        ;


    function automatic [CHANNEL_SHIFT_REG_WIDTH-1:0] write_set_shift_channel_mask;
        input logic [1:0] direc_id;
        write_set_shift_channel_mask = 'b0;
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
        write_set_shift_ram_mask = 'b0;
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

    //=============================================================================================
    //-----------direction_id------------------
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1) begin
            assign direction_id[i] = rd_pld[i].txnid.direction_id;//txnid的低两位作为方向id
        end
    endgenerate
    generate
        for(genvar i=RD_REQ_NUM;i<REQ_NUM;i=i+1) begin
            assign direction_id[i] = wr_pld[i-RD_REQ_NUM].txnid.direction_id;//txnid的低两位作为方向id
        end
    endgenerate

//-----------dest_ram_id-------------------------
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

//-----------block_id ------------------------------
    generate
        for(genvar i=0;i<REQ_NUM;i=i+1) begin
            assign block_id[i] = dest_ram_id[i][2:1];//中间2bit为block_id
        end
    endgenerate
//==========================================================================================


//==========================================================================================
// req mask
//==========================================================================================
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1)begin
            //检查channel的冲突，block0，read直接上channel，所以检查channel_timer的最低bit是否为1，不为1则说明下一拍没有写冲突，
            assign rd_pre_allow_bit[i] = (channel_timer_shift_reg[{dest_ram_id[i][0]}][0]==1'b0);
        end
    endgenerate
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1)begin
           always_comb begin
                rd_allow_bit[i] = 'b0;
                case(block_id[i]) 
                    2'b00: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][RD_BLOCK0_DELAY]==1'b0);
                    2'b01: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][RD_BLOCK1_DELAY]==1'b0);
                    2'b10: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][RD_BLOCK2_DELAY]==1'b0);
                    2'b11: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][RD_BLOCK3_DELAY]==1'b0);
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
                wr_pre_allow_bit[i] = 'b0;
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
                wr_allow_bit[i] = 'b0;
                if(i==0)begin//linefill没有方向id，默认是south
                    case(block_id[i])
                        2'b00: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_LF+WR_BLOCK0_DELAY]==1'b0);
                        2'b01: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_LF+WR_BLOCK1_DELAY]==1'b0);
                        2'b10: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_LF+WR_BLOCK2_DELAY]==1'b0);
                        2'b11: wr_allow_bit[i] = wr_pre_allow_bit[i] && (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_LF+WR_BLOCK3_DELAY]==1'b0);
                    endcase
                end
                else begin
                    case(block_id[i]) 
                        2'b00: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `VEC_CACHE_WEST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_WEST+WR_BLOCK0_DELAY]   == 1'b0) :       //访问block0，west write应检查shift_reg的bit[WEST_WR_BIT]
                                                 (direction_id[i] == `VEC_CACHE_EAST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_EAST+WR_BLOCK0_DELAY]   == 1'b0) :       //访问block0，east write应检查shift_reg的bit[3]
                                                 (direction_id[i] == `VEC_CACHE_SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK0_DELAY]  == 1'b0) :       //访问block0，south write应检查shift_reg的bit[10]
                                                 (direction_id[i] == `VEC_CACHE_NORTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK0_DELAY]  == 1'b0) : 1'b0); //访问block0，north write应检查shift_reg的bit[8]
                        2'b01: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `VEC_CACHE_WEST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_WEST+WR_BLOCK1_DELAY]   == 1'b0) :       //访问block0，west write应检查shift_reg的bit[WEST_WR_BIT]
                                                 (direction_id[i] == `VEC_CACHE_EAST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_EAST+WR_BLOCK1_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK1_DELAY]  == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_NORTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK1_DELAY]  == 1'b0) : 1'b0); 
                        2'b10: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `VEC_CACHE_WEST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_WEST+WR_BLOCK2_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_EAST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_EAST+WR_BLOCK2_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK2_DELAY]  == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_NORTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK2_DELAY]  == 1'b0) : 1'b0); 
                        2'b11: wr_allow_bit[i] = wr_pre_allow_bit[i] && 
                                                ((direction_id[i] == `VEC_CACHE_WEST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_WEST+WR_BLOCK3_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_EAST ) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_EAST+WR_BLOCK3_DELAY]   == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_SOUTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK3_DELAY]  == 1'b0) :       
                                                 (direction_id[i] == `VEC_CACHE_NORTH) ? (ram_timer_shift_reg[dest_ram_id[i][2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK3_DELAY]  == 1'b0) : 1'b0); 
                    endcase
                end
            end
            assign allowed_wr_vld[i] =  wr_vld[i] && wr_allow_bit[i];//不被write屏蔽的写请求
        end
    endgenerate

    assign all_req_vld     = {allowed_rd_vld,allowed_wr_vld};
    assign all_req_pld     = {rd_pld, wr_pld};
//==========================================================================================


//==========================================================================================
// arb 
//==========================================================================================
    vrp_ten2two_arb #(
        .N          (REQ_NUM),
        .PLD_WIDTH  (($bits(arb_out_req_t)))
    ) u_arbiter (
        .clk                (clk               ),
        .rst_n              (rst_n             ),
        .req_vld            (all_req_vld       ),
        .req_rdy            (all_req_rdy       ),
        .req_pld            (all_req_pld       ),
        .first_grant_idx    (first_grant_idx   ),
        .second_grant_idx   (second_grant_idx  ),
        .grant_vld          (grant_req_vld     ),
        .grant_rdy          (grant_req_rdy     ),    
        .grant_pld          (grant_req_pld     )
    );

    assign wr_rdy = all_req_rdy[4:0];
    assign rd_rdy = all_req_rdy[9:5];


//==========================================================================================
//timer set && shift
//==========================================================================================
    always_comb begin
        for(int i=0;i<8;i=i+1)begin
            set_ram_mask[i] = '0;
        end
        for (int i = 0; i < REQ_NUM; i=i+1) begin
            if (grant_req_vld[i] && grant_req_rdy && (grant_req_pld[i].opcode == `VEC_CACHE_WRITE || grant_req_pld[i].opcode == `VEC_CACHE_LINEFILL)) begin        
                set_ram_mask[grant_req_pld[i].dest_ram_id[2:0]] =write_set_shift_ram_mask(grant_req_pld[i].dest_ram_id[2:1],grant_req_pld[i].txnid.direction_id);
            end
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(int i=0;i<8;i=i+1)begin
                ram_timer_shift_reg[i] <= '0;
            end
        end 
        else begin
            for(int i=0;i<8;i=i+1)begin
                ram_timer_shift_reg[i] <= (ram_timer_shift_reg[i] >> 1) | set_ram_mask[i];
            end
        end
    end

    always_comb begin
        for(int i=0;i<2;i=i+1)begin
            set_channel_mask[i] = '0;
        end
        for(int i=0;i<REQ_NUM;i=i+1)begin
            if(grant_req_vld[i] && grant_req_rdy && (grant_req_pld[i].opcode == `VEC_CACHE_WRITE || grant_req_pld[i].opcode == `VEC_CACHE_LINEFILL))begin
                set_channel_mask[grant_req_pld[i].dest_ram_id[0]] = write_set_shift_channel_mask(grant_req_pld_0.txnid.direction_id);
            end
        end
    end
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(int i=0;i<2;i=i+1)begin
                channel_timer_shift_reg[i] <= '0;
            end
        end 
        else begin
            for(int i=0;i<2;i=i+1)begin
                channel_timer_shift_reg[i] <= (channel_timer_shift_reg[i] >> 1) | set_channel_mask[i];
            end
        end
    end


    assign grant_req_vld_0 = grant_req_vld[first_grant_idx] && grant_req_rdy; 
    assign grant_req_pld_0 = grant_req_pld[first_grant_idx];
    assign grant_req_vld_1 = grant_req_vld[second_grant_idx]&& grant_req_rdy;
    assign grant_req_pld_1 = grant_req_pld[second_grant_idx];


endmodule