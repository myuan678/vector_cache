module stage2_arbiter 
    import vector_cache_pkg::*; 
    #(
    parameter integer unsigned  CHANNEL_SHIFT_REG_WIDTH = 10,
    parameter integer unsigned  RAM_SHIFT_REG_WIDTH     = 20
    ) (
    input  logic                    clk                     ,
    input  logic                    rst_n                   ,

    input  logic                    w_dataram_rd_vld        ,
    input  logic                    e_dataram_rd_vld        ,
    input  logic                    s_dataram_rd_vld        ,
    input  logic                    n_dataram_rd_vld        ,
    input  logic                    evict_rd_vld            ,
    input  arb_out_req_t            w_dataram_rd_pld        ,
    input  arb_out_req_t            e_dataram_rd_pld        ,
    input  arb_out_req_t            s_dataram_rd_pld        ,
    input  arb_out_req_t            n_dataram_rd_pld        ,
    input  arb_out_req_t            evict_rd_pld            ,
    output logic                    w_dataram_rd_rdy        ,
    output logic                    e_dataram_rd_rdy        ,
    output logic                    s_dataram_rd_rdy        ,
    output logic                    n_dataram_rd_rdy        ,
    output logic                    evict_rd_rdy            ,
    input  logic                    w_dataram_wr_vld        ,
    input  logic                    e_dataram_wr_vld        ,
    input  logic                    s_dataram_wr_vld        ,
    input  logic                    n_dataram_wr_vld        ,
    input  logic                    linefill_req_vld        ,
    input  arb_out_req_t            w_dataram_wr_pld        ,
    input  arb_out_req_t            e_dataram_wr_pld        ,
    input  arb_out_req_t            s_dataram_wr_pld        ,
    input  arb_out_req_t            n_dataram_wr_pld        ,
    input  arb_out_req_t            linefill_req_pld        ,
    output logic                    w_dataram_wr_rdy        ,
    output logic                    e_dataram_wr_rdy        ,
    output logic                    s_dataram_wr_rdy        ,
    output logic                    n_dataram_wr_rdy        ,
    output logic                    linefill_req_rdy        ,

    output logic                    arbout_w_dataram_rd_vld ,
    output logic                    arbout_e_dataram_rd_vld ,
    output logic                    arbout_s_dataram_rd_vld ,
    output logic                    arbout_n_dataram_rd_vld ,
    output logic                    arbout_evict_rd_vld     ,  
    output arb_out_req_t            arbout_w_dataram_rd_pld ,
    output arb_out_req_t            arbout_e_dataram_rd_pld ,
    output arb_out_req_t            arbout_s_dataram_rd_pld ,
    output arb_out_req_t            arbout_n_dataram_rd_pld ,
    output arb_out_req_t            arbout_evict_rd_pld     ,

    output logic                    arbout_w_dataram_wr_vld ,
    output logic                    arbout_e_dataram_wr_vld ,
    output logic                    arbout_s_dataram_wr_vld ,
    output logic                    arbout_n_dataram_wr_vld ,
    output logic                    arbout_linefill_req_vld ,  
    output arb_out_req_t            arbout_w_dataram_wr_pld ,
    output arb_out_req_t            arbout_e_dataram_wr_pld ,
    output arb_out_req_t            arbout_s_dataram_wr_pld ,
    output arb_out_req_t            arbout_n_dataram_wr_pld ,
    output arb_out_req_t            arbout_linefill_req_pld ,    
    input                           arb_rdy                 
    );


    localparam integer unsigned     RD_BLOCK0_DELAY = 1;
    localparam integer unsigned     RD_BLOCK1_DELAY = 2;
    localparam integer unsigned     RD_BLOCK2_DELAY = 3;
    localparam integer unsigned     RD_BLOCK3_DELAY = 4; 
    localparam integer unsigned     WR_BLOCK0_DELAY = 8;
    localparam integer unsigned     WR_BLOCK1_DELAY = 7;
    localparam integer unsigned     WR_BLOCK2_DELAY = 6;
    localparam integer unsigned     WR_BLOCK3_DELAY = 5; 

    logic [RAM_SHIFT_REG_WIDTH-1    :0] ram_timer_shift_reg     [7 :0]          ;
    logic [CHANNEL_SHIFT_REG_WIDTH-1:0] channel_timer_shift_reg [1 :0]          ;
    logic [2                        :0] rd_dest_ram_id          [4:0]           ;
    logic [4                        :0] rd_pre_allow_bit                        ;
    logic [4                        :0] rd_allow_bit                            ;
    logic                               w_wr_pre_allow_bit                      ;
    logic                               e_wr_pre_allow_bit                      ;
    logic                               s_wr_pre_allow_bit                      ;
    logic                               n_wr_pre_allow_bit                      ;
    logic                               lf_wr_pre_allow_bit                     ;
    logic                               w_wr_allow_bit                          ;
    logic                               e_wr_allow_bit                          ;
    logic                               s_wr_allow_bit                          ;
    logic                               n_wr_allow_bit                          ;
    logic                               lf_wr_allow_bit                         ;
    
    logic                               w_wr_channel_sel                        ;
    logic                               e_wr_channel_sel                        ;
    logic                               s_wr_channel_sel                        ;
    logic                               n_wr_channel_sel                        ;
    logic                               lf_wr_channel_sel                       ;
    logic [2:0]                         w_wr_ram_sel                            ;
    logic [2:0]                         e_wr_ram_sel                            ;
    logic [2:0]                         s_wr_ram_sel                            ;
    logic [2:0]                         n_wr_ram_sel                            ;
    logic [2:0]                         lf_wr_ram_sel                           ;

    assign arbout_w_dataram_rd_pld  = w_dataram_rd_pld;
    assign arbout_e_dataram_rd_pld  = e_dataram_rd_pld;
    assign arbout_s_dataram_rd_pld  = s_dataram_rd_pld;
    assign arbout_n_dataram_rd_pld  = n_dataram_rd_pld;
    assign arbout_evict_rd_pld      = evict_rd_pld    ;

    assign arbout_w_dataram_wr_pld  = w_dataram_wr_pld;
    assign arbout_e_dataram_wr_pld  = e_dataram_wr_pld;
    assign arbout_s_dataram_wr_pld  = s_dataram_wr_pld;
    assign arbout_n_dataram_wr_pld  = n_dataram_wr_pld;
    assign arbout_linefill_req_pld  = linefill_req_pld;

    assign w_wr_channel_sel = w_dataram_wr_pld.dest_ram_id[0];
    assign e_wr_channel_sel = e_dataram_wr_pld.dest_ram_id[0];
    assign s_wr_channel_sel = s_dataram_wr_pld.dest_ram_id[0];
    assign n_wr_channel_sel = n_dataram_wr_pld.dest_ram_id[0];
    assign lf_wr_channel_sel= linefill_req_pld.dest_ram_id[0];

    assign w_wr_ram_sel  = w_dataram_wr_pld.dest_ram_id[2:0];
    assign e_wr_ram_sel  = e_dataram_wr_pld.dest_ram_id[2:0];
    assign s_wr_ram_sel  = s_dataram_wr_pld.dest_ram_id[2:0];
    assign n_wr_ram_sel  = n_dataram_wr_pld.dest_ram_id[2:0];
    assign lf_wr_ram_sel = linefill_req_pld.dest_ram_id[2:0];

    //=============================================================================================
    //read直接上channel，所以检查channel_timer的最低bit是否为1，不为1则说明下一拍没有写冲突
    //read channel mask
    assign w_rd_pre_allow_bit = (channel_timer_shift_reg[w_dataram_rd_pld.dest_ram_id[0]][0]==1'b0) ;
    assign e_rd_pre_allow_bit = (channel_timer_shift_reg[e_dataram_rd_pld.dest_ram_id[0]][0]==1'b0) ;
    assign s_rd_pre_allow_bit = (channel_timer_shift_reg[s_dataram_rd_pld.dest_ram_id[0]][0]==1'b0) ;
    assign n_rd_pre_allow_bit = (channel_timer_shift_reg[n_dataram_rd_pld.dest_ram_id[0]][0]==1'b0) ;
    assign ev_rd_pre_allow_bit= (channel_timer_shift_reg[evict_rd_pld.dest_ram_id[0]    ][0]==1'b0) ;
    assign rd_pre_allow_bit   = {w_rd_pre_allow_bit,e_rd_pre_allow_bit,s_rd_pre_allow_bit,n_rd_pre_allow_bit,ev_rd_pre_allow_bit};
    // read ram mask

    assign rd_dest_ram_id[4] = w_dataram_rd_pld.dest_ram_id[2:0];
    assign rd_dest_ram_id[3] = e_dataram_rd_pld.dest_ram_id[2:0];
    assign rd_dest_ram_id[2] = s_dataram_rd_pld.dest_ram_id[2:0];
    assign rd_dest_ram_id[1] = n_dataram_rd_pld.dest_ram_id[2:0];
    assign rd_dest_ram_id[0] = evict_rd_pld.dest_ram_id[2:0];
    generate
        for(genvar i=0;i<5;i=i+1)begin
            always_comb begin
                 rd_allow_bit[i] = 'b0;
                 case(rd_dest_ram_id[i][2:1]) 
                     2'b00: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[rd_dest_ram_id[i]][RD_BLOCK0_DELAY]==1'b0);
                     2'b01: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[rd_dest_ram_id[i]][RD_BLOCK1_DELAY]==1'b0);
                     2'b10: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[rd_dest_ram_id[i]][RD_BLOCK2_DELAY]==1'b0);
                     2'b11: rd_allow_bit[i] = rd_pre_allow_bit[i] && (ram_timer_shift_reg[rd_dest_ram_id[i]][RD_BLOCK3_DELAY]==1'b0);
                 endcase
            end
        end
    endgenerate

    assign w_rd_allow_bit =  rd_allow_bit[4];
    assign e_rd_allow_bit =  rd_allow_bit[3];
    assign s_rd_allow_bit =  rd_allow_bit[2];
    assign n_rd_allow_bit =  rd_allow_bit[1];
    assign ev_rd_allow_bit=  rd_allow_bit[0];
    assign allow_w_rd_vld = w_rd_allow_bit & w_dataram_rd_vld;
    assign allow_e_rd_vld = e_rd_allow_bit & e_dataram_rd_vld;
    assign allow_s_rd_vld = s_rd_allow_bit & s_dataram_rd_vld;
    assign allow_n_rd_vld = n_rd_allow_bit & n_dataram_rd_vld;
    assign allow_ev_rd_vld = ev_rd_allow_bit & evict_rd_vld  ;
    
    //write channel mask
    assign w_wr_pre_allow_bit = (channel_timer_shift_reg[w_wr_channel_sel ][WR_CMD_DELAY_WEST]==1'b0) ;
    assign e_wr_pre_allow_bit = (channel_timer_shift_reg[e_wr_channel_sel ][WR_CMD_DELAY_EAST]==1'b0) ;
    assign s_wr_pre_allow_bit = (channel_timer_shift_reg[s_wr_channel_sel ][WR_CMD_DELAY_SOUTH]==1'b0);
    assign n_wr_pre_allow_bit = (channel_timer_shift_reg[n_wr_channel_sel ][WR_CMD_DELAY_NORTH]==1'b0);
    assign lf_wr_pre_allow_bit= (channel_timer_shift_reg[lf_wr_channel_sel][WR_CMD_DELAY_LF]==1'b0);

    //write ram mask
    always_comb begin
        w_wr_allow_bit = 1'b0;
        case(w_dataram_wr_pld.dest_ram_id[2:1])
            2'b00:w_wr_allow_bit = w_wr_pre_allow_bit && (ram_timer_shift_reg[w_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_WEST+WR_BLOCK0_DELAY] == 1'b0);
            2'b01:w_wr_allow_bit = w_wr_pre_allow_bit && (ram_timer_shift_reg[w_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_WEST+WR_BLOCK1_DELAY] == 1'b0);
            2'b10:w_wr_allow_bit = w_wr_pre_allow_bit && (ram_timer_shift_reg[w_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_WEST+WR_BLOCK2_DELAY] == 1'b0);
            2'b11:w_wr_allow_bit = w_wr_pre_allow_bit && (ram_timer_shift_reg[w_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_WEST+WR_BLOCK3_DELAY] == 1'b0);
        endcase
    end
    always_comb begin
        e_wr_allow_bit = 1'b0;
        case(e_dataram_wr_pld.dest_ram_id[2:1])
            2'b00:e_wr_allow_bit = e_wr_pre_allow_bit && (ram_timer_shift_reg[e_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_EAST+WR_BLOCK0_DELAY] == 1'b0);
            2'b01:e_wr_allow_bit = e_wr_pre_allow_bit && (ram_timer_shift_reg[e_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_EAST+WR_BLOCK1_DELAY] == 1'b0);
            2'b10:e_wr_allow_bit = e_wr_pre_allow_bit && (ram_timer_shift_reg[e_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_EAST+WR_BLOCK2_DELAY] == 1'b0);
            2'b11:e_wr_allow_bit = e_wr_pre_allow_bit && (ram_timer_shift_reg[e_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_EAST+WR_BLOCK3_DELAY] == 1'b0);
        endcase
    end
    always_comb begin
        s_wr_allow_bit = 1'b0;
        case(s_dataram_wr_pld.dest_ram_id[2:1])
            2'b00:s_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[s_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK0_DELAY] == 1'b0);
            2'b01:s_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[s_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK1_DELAY] == 1'b0);
            2'b10:s_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[s_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK2_DELAY] == 1'b0);
            2'b11:s_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[s_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_SOUTH+WR_BLOCK3_DELAY] == 1'b0);
        endcase
    end
    always_comb begin
        n_wr_allow_bit = 1'b0;
        case(n_dataram_wr_pld.dest_ram_id[2:1])
            2'b00:n_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[n_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK0_DELAY] == 1'b0);
            2'b01:n_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[n_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK1_DELAY] == 1'b0);
            2'b10:n_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[n_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK2_DELAY] == 1'b0);
            2'b11:n_wr_allow_bit = s_wr_pre_allow_bit && (ram_timer_shift_reg[n_dataram_wr_pld.dest_ram_id[2:0]][WR_CMD_DELAY_NORTH+WR_BLOCK3_DELAY] == 1'b0);
        endcase
    end
    always_comb begin
        lf_wr_allow_bit = 1'b0;
        case(linefill_req_pld.dest_ram_id[2:1])
            2'b00:lf_wr_allow_bit = lf_wr_pre_allow_bit && (ram_timer_shift_reg[linefill_req_pld.dest_ram_id[2:0]][WR_CMD_DELAY_LF+WR_BLOCK0_DELAY] == 1'b0);
            2'b01:lf_wr_allow_bit = lf_wr_pre_allow_bit && (ram_timer_shift_reg[linefill_req_pld.dest_ram_id[2:0]][WR_CMD_DELAY_LF+WR_BLOCK1_DELAY] == 1'b0);
            2'b10:lf_wr_allow_bit = lf_wr_pre_allow_bit && (ram_timer_shift_reg[linefill_req_pld.dest_ram_id[2:0]][WR_CMD_DELAY_LF+WR_BLOCK2_DELAY] == 1'b0);
            2'b11:lf_wr_allow_bit = lf_wr_pre_allow_bit && (ram_timer_shift_reg[linefill_req_pld.dest_ram_id[2:0]][WR_CMD_DELAY_LF+WR_BLOCK3_DELAY] == 1'b0);
        endcase
    end

    assign allow_w_wr_vld  = w_wr_allow_bit & w_dataram_wr_vld;
    assign allow_e_wr_vld  = e_wr_allow_bit & e_dataram_wr_vld;
    assign allow_s_wr_vld  = s_wr_allow_bit & s_dataram_wr_vld;
    assign allow_n_wr_vld  = n_wr_allow_bit & n_dataram_wr_vld;
    assign allow_lf_wr_vld = lf_wr_allow_bit & linefill_req_vld;

    vr_2grant_arb u_vr_2grant_arb ( 
        .w_dataram_rd_vld       (allow_w_rd_vld             ),
        .e_dataram_rd_vld       (allow_e_rd_vld             ),
        .s_dataram_rd_vld       (allow_s_rd_vld             ),
        .n_dataram_rd_vld       (allow_n_rd_vld             ),
        .evict_rd_vld           (allow_ev_rd_vld            ),
        .w_dataram_rd_rdy       (w_dataram_rd_rdy           ),
        .e_dataram_rd_rdy       (e_dataram_rd_rdy           ),
        .s_dataram_rd_rdy       (s_dataram_rd_rdy           ),
        .n_dataram_rd_rdy       (n_dataram_rd_rdy           ),
        .evict_rd_rdy           (evict_rd_rdy               ),
        .w_dataram_wr_vld       (allow_w_wr_vld             ),
        .e_dataram_wr_vld       (allow_e_wr_vld             ),
        .s_dataram_wr_vld       (allow_s_wr_vld             ),
        .n_dataram_wr_vld       (allow_n_wr_vld             ),
        .linefill_req_vld       (allow_lf_wr_vld            ),
        .w_dataram_wr_rdy       (w_dataram_wr_rdy           ),
        .e_dataram_wr_rdy       (e_dataram_wr_rdy           ),
        .s_dataram_wr_rdy       (s_dataram_wr_rdy           ),
        .n_dataram_wr_rdy       (n_dataram_wr_rdy           ),
        .linefill_req_rdy       (linefill_req_rdy           ),
        .arbout_w_dataram_rd_vld(arbout_w_dataram_rd_vld    ),
        .arbout_e_dataram_rd_vld(arbout_e_dataram_rd_vld    ),
        .arbout_s_dataram_rd_vld(arbout_s_dataram_rd_vld    ),
        .arbout_n_dataram_rd_vld(arbout_n_dataram_rd_vld    ),
        .arbout_evict_rd_vld    (arbout_evict_rd_vld        ),
        .arbout_w_dataram_wr_vld(arbout_w_dataram_wr_vld    ),
        .arbout_e_dataram_wr_vld(arbout_e_dataram_wr_vld    ),
        .arbout_s_dataram_wr_vld(arbout_s_dataram_wr_vld    ),
        .arbout_n_dataram_wr_vld(arbout_n_dataram_wr_vld    ),
        .arbout_linefill_req_vld(arbout_linefill_req_vld    ),
        .grant_rdy              (1'b1));


    channel_shift_reg  #( 
        .CHANNEL_SHIFT_REG_WIDTH(20)) 
    u_channel_shift_reg(
        .clk                (clk                      ),
        .rst_n              (rst_n                    ),
        .w_dataram_wr_vld   (arbout_w_dataram_wr_vld  ),
        .e_dataram_wr_vld   (arbout_e_dataram_wr_vld  ),
        .s_dataram_wr_vld   (arbout_s_dataram_wr_vld  ),
        .n_dataram_wr_vld   (arbout_n_dataram_wr_vld  ),
        .linefill_req_vld   (arbout_linefill_req_vld  ),
        .w_wr_channel_sel   (w_wr_channel_sel         ),
        .e_wr_channel_sel   (e_wr_channel_sel         ),
        .s_wr_channel_sel   (s_wr_channel_sel         ),
        .n_wr_channel_sel   (n_wr_channel_sel         ),
        .lf_wr_channel_sel  (lf_wr_channel_sel        ),
        .channel_shift_reg  (channel_timer_shift_reg  ));

    ram_shift_reg  #( 
        .RAM_SHIFT_REG_WIDTH(20)) 
    u_ram_shifte_reg ( 
        .clk                (clk                      ),
        .rst_n              (rst_n                    ),
        .w_dataram_wr_vld   (arbout_w_dataram_wr_vld  ),
        .e_dataram_wr_vld   (arbout_e_dataram_wr_vld  ),
        .s_dataram_wr_vld   (arbout_s_dataram_wr_vld  ),
        .n_dataram_wr_vld   (arbout_n_dataram_wr_vld  ),
        .linefill_req_vld   (arbout_linefill_req_vld  ),
        .w_wr_ram_sel       (w_wr_ram_sel             ),
        .e_wr_ram_sel       (e_wr_ram_sel             ),
        .s_wr_ram_sel       (s_wr_ram_sel             ),
        .n_wr_ram_sel       (n_wr_ram_sel             ),
        .lf_wr_ram_sel      (lf_wr_ram_sel            ),
        .ram_shift_reg      (ram_timer_shift_reg      ));

endmodule