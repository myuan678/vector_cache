module ten_to_two_arb 
    import vector_cache_pkg::*; 
    #(
    parameter integer unsigned RD_REQ_NUM = 5,
    parameter integer unsigned WR_REQ_NUM = 5,
    parameter integer unsigned SHIFT_REG_WIDTH = 15,
    parameter integer unsigned REQ_NUM = RD_REQ_NUM + WR_REQ_NUM
    ) (
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic [RD_REQ_NUM-1:0]   rd_vld,
    input  arb_out_req_t            rd_pld[RD_REQ_NUM-1:0],
    output logic [RD_REQ_NUM-1:0]   rd_rdy,


    input  logic [WR_REQ_NUM-1:0]   wr_vld,
    input  arb_out_req_t            wr_pld[WR_REQ_NUM-1:0],
    output logic [WR_REQ_NUM-1:0]   wr_rdy,

    output logic                    grant_req_vld_0,
    output arb_out_req_t            grant_req_pld_0,
    output logic                    grant_req_vld_1,
    output arb_out_req_t            grant_req_pld_1,
    input  logic                    grant_req_rdy   //sram rdy
);

    logic [REQ_NUM-1        :0] all_req_vld                   ;
    arb_out_req_t               all_req_pld     [REQ_NUM-1:0] ;
    logic [SHIFT_REG_WIDTH-1:0] timer_shift_reg [7        :0] ;
    logic [1                :0] block_id        [REQ_NUM-1:0] ;
    logic [4                :0] dest_ram_id     [REQ_NUM-1:0] ;//某个block中的某个sram，5bit
    logic [1                :0] direction_id    [REQ_NUM-1:0] ;//请求的来源方向
    logic [RD_REQ_NUM-1     :0] rd_allow_bit                  ;
    logic [RD_REQ_NUM-1     :0] allowed_rd_vld                ;
    

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
    

    //read 可能由于前面的写请求记录的timer，而不能发，先基于timer对5个读请求做mask
    generate
        for (genvar i = 0; i < RD_REQ_NUM; i = i + 1) begin : block_check_gen
            always_comb begin
                case (block_id[i])
                    2'b00: rd_allow_bit[i] = (timer_shift_reg[i][0] == 1'b0);//访问block0，应检查shift_reg的bit0
                    2'b01: rd_allow_bit[i] = (timer_shift_reg[i][1] == 1'b0);//访问block1，应检查shift_reg的bit1
                    2'b10: rd_allow_bit[i] = (timer_shift_reg[i][2] == 1'b0);//访问block2，应检查shift_reg的bit2
                    2'b11: rd_allow_bit[i] = (timer_shift_reg[i][3] == 1'b0);//访问block3，应检查shift_reg的bit3
                    default: rd_allow_bit[i] = 1'b0; // 
                endcase
            end
        end
    endgenerate
    generate
        for(genvar i=0;i<RD_REQ_NUM;i=i+1) begin
            assign allowed_rd_vld[i] =  rd_vld[i] && rd_allow_bit[i];//不被write 屏蔽的读请求
        end
    endgenerate

    assign all_req_vld = {allowed_rd_vld,wr_vld};
    assign all_req_pld = {rd_pld, wr_pld};

    //再mask地址冲突的请求
    logic [REQ_NUM-1:0] conflict_mask [REQ_NUM-1:0]; 
    logic [REQ_NUM-1:0] pld_conflict_mask;
    logic [REQ_NUM-1:0] masked_vld;
    generate
        genvar i, j;       
        for (i = 0; i < REQ_NUM; i = i + 1) begin : gen_mask
            logic [REQ_NUM-1:0] pld_match;//pld高3bit相同的请求
            logic [REQ_NUM-1:0] priority_mask = {{i{1'b0}}, {REQ_NUM-i{1'b1}}};
            for (j = 0; j < REQ_NUM; j = j + 1) begin : gen_match_bit
                assign pld_match[j] = all_req_vld[j] && (dest_ram_id[i] == dest_ram_id[j]);
            end            
            // 生成优先级掩码（低优先级位为1）
            assign conflict_mask[i] = all_req_vld[i] ? (pld_match & priority_mask) : {REQ_NUM{1'b0}};
        end
    endgenerate
    
    // 合并//TODO：有点问题
    //generate
    //    logic [REQ_NUM-1:0] merged_mask [0:REQ_NUM];
    //    assign merged_mask[0] = {REQ_NUM{1'b0}};
    //    for (genvar k = 0; k < REQ_NUM; k = k + 1) begin : merge_loop
    //        assign merged_mask[k+1] = merged_mask[k] | conflict_mask[k];
    //    end
    //    assign pld_conflict_mask = merged_mask[REQ_NUM];
    //endgenerate
    assign masked_vld = all_req_vld & ~pld_conflict_mask;

    //------------------------------------------------------------------------------------

    n_to_2_arb #(
        .N          (REQ_NUM),
        .PLD_WIDTH  ($bits(arb_out_req_t))
    ) u_arbiter (
        .clk        (clk                               ),
        .rst_n      (rst_n                             ),
        .req_vld    (masked_vld                        ),
        .req_rdy    ({rd_rdy, wr_rdy}                  ),
        .req_pld    (all_req_pld                       ),
        .grant_vld  ({grant_req_vld_0, grant_req_vld_1}),
        .grant_rdy  (grant_req_rdy                     ),    
        .grant_pld  ({grant_req_pld_0, grant_req_pld_1})
    );

    //function automatic [SHIFT_REG_WIDTH-1:0] read_set_shift_bit_mask;
    //    input logic [1:0] bk_id;
    //    case(bk_id)
    //        2'b00: read_set_shift_bit_mask[RD_SHIFT_BIT]  = 1'b1;
    //        2'b01: read_set_shift_bit_mask[RD_SHIFT_BIT+1]= 1'b1;
    //        2'b10: read_set_shift_bit_mask[RD_SHIFT_BIT+2]= 1'b1;
    //        2'b11: read_set_shift_bit_mask[RD_SHIFT_BIT+3]= 1'b1;
    //    endcase
    //endfunction

    function automatic [SHIFT_REG_WIDTH-1:0] get_set_bit_mask;
        input logic [1:0] bk_id;
        input logic [1:0] direc_id;
        case (bk_id)
            2'b00: begin//block0
                case (direc_id)
                    2'b00: get_set_bit_mask[7]  = 1'b1; // west
                    2'b01: get_set_bit_mask[9]  = 1'b1; // east
                    2'b10: get_set_bit_mask[7]  = 1'b1; // south
                    2'b11: get_set_bit_mask[13] = 1'b1; // north
                    default: get_set_bit_mask = 'b0;
                endcase
            end
            2'b01: begin//block1
                case (direc_id)
                    2'b00: get_set_bit_mask[6]  = 1'b1; // west:bit[7]
                    2'b01: get_set_bit_mask[8]  = 1'b1; // east
                    2'b10: get_set_bit_mask[6]  = 1'b1; // south
                    2'b11: get_set_bit_mask[12] = 1'b1; // north
                    default: get_set_bit_mask = 'b0;
                endcase
            end
            2'b10: begin//block2
                case (direc_id)
                    2'b00: get_set_bit_mask[5]  = 1'b1; // west:bit[6]
                    2'b01: get_set_bit_mask[7]  = 1'b1; // east
                    2'b10: get_set_bit_mask[5]  = 1'b1; // south
                    2'b11: get_set_bit_mask[11] = 1'b1; // north
                    default: get_set_bit_mask = 'b0;
                endcase
            end
            2'b11: begin//block3
                case (direc_id)
                    2'b00: get_set_bit_mask[4] = 1'b1; // west:bit[13]
                    2'b01: get_set_bit_mask[6] = 1'b1; // east
                    2'b10: get_set_bit_mask[4] = 1'b1; // south
                    2'b11: get_set_bit_mask[10] = 1'b1; // north
                    default: get_set_bit_mask = 'b0;
                endcase
            end
            default: get_set_bit_mask = 'b0;
        endcase
    endfunction

    logic [SHIFT_REG_WIDTH  :0]  set_req0_timer;
    logic [SHIFT_REG_WIDTH  :0]  set_req1_timer;
    logic [1                :0]  grant0_block_id;
    logic [1                :0]  grant0_direction_id;
    logic [1                :0]  grant1_block_id;
    logic [1                :0]  grant1_direction_id;
    assign grant0_block_id     = grant_req_pld_0.dest_ram_id[2:1]  ;
    assign grant0_direction_id = grant_req_pld_0.txnid[1:0]        ;
    assign grant1_block_id     = grant_req_pld_1.dest_ram_id[2:1]  ;
    assign grant1_direction_id = grant_req_pld_1.txnid[1:0]        ;
    


    assign set_req0_timer    = grant_req_vld_0 ? get_set_bit_mask(grant0_block_id, grant0_direction_id) : 'b0;
    assign set_req1_timer    = grant_req_vld_1 ? get_set_bit_mask(grant1_block_id, grant1_direction_id) : 'b0;

    
generate
    for (genvar i = 0; i < 8; i = i + 1) begin : SLAVE_PROC
        // 确定当前slave是否是被grant0选中的，用来确定掩码是否需要对该slave生效
        logic apply_req0 ;
        logic apply_req1 ;
        logic [SHIFT_REG_WIDTH-1:0] combined_mask; 
        assign apply_req0 = grant_req_vld_0 && (grant_req_pld_0.dest_ram_id == i);
        // 确定当前slave是否是被grant0选中的，确定掩码是否需要对该slave生
        assign apply_req1 = grant_req_vld_1 && (grant_req_pld_1.dest_ram_id == i);
        assign combined_mask= (apply_req0 ? set_req0_timer : 'b0) | (apply_req1 ? set_req1_timer : 'b0);
        // 更新对应slave的timer_shift_reg
        always @(posedge clk or negedge rst_n) begin
            if (!rst_n) begin
                timer_shift_reg[i] <= 'b0;
            end else begin
                timer_shift_reg[i] <= (timer_shift_reg[i] >> 1) | combined_mask;
            end
        end
    end
endgenerate
    
      
    
    

endmodule