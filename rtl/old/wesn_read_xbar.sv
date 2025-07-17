module wesn_read_xbar 
import vector_cache_pkg::*
(
    input  logic                        clk                                     ,
    input  logic                        rst_n                                   ,

    //direction west WR
    input  logic [WR_REQ_NUM-1      :0] w_rd_cmd_vld                           ,
    output logic [WR_REQ_NUM-1      :0] w_rd_cmd_rdy                           ,
    input  logic [63                :0] w_rd_addr           [WR_REQ_NUM-1:0]   ,
    input  logic [TXNID_WIDTH-1     :0] w_rd_cmd_txnid      [WR_REQ_NUM-1:0]   ,
    input  logic [SIDEBAND_WIDTH-1  :0] w_rd_sideband       [WR_REQ_NUM-1:0]   ,

    input  logic [ER_REQ_NUM-1      :0] e_rd_cmd_vld                          ,
    output logic [ER_REQ_NUM-1      :0] e_rd_cmd_rdy                          ,
    input  logic [63                :0] e_rd_addr           [ER_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] e_rd_cmd_txnid      [ER_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] e_rd_sideband       [ER_REQ_NUM-1:0]  ,
    //direction south
    input  logic [SR_REQ_NUM-1      :0] s_rd_cmd_vld                          ,
    output logic [SR_REQ_NUM-1      :0] s_rd_cmd_rdy                          ,
    input  logic [63                :0] s_rd_addr           [SR_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] s_rd_cmd_txnid      [SR_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] s_rd_sideband       [SR_REQ_NUM-1:0]  ,
    //direction north
    input  logic [NR_REQ_NUM-1      :0] n_rd_cmd_vld                          ,
    output logic [NR_REQ_NUM-1      :0] n_rd_cmd_rdy                          ,
    input  logic [63                :0] n_rd_addr           [NR_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] n_rd_cmd_txnid      [NR_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] n_rd_sideband       [NR_REQ_NUM-1:0]  ,
    
    output logic [3                 :0] w_rd_vld        ,
    output input_req_pld_t              w_rd_pld[3:0]   ,
    input  logic [3                 :0] w_rd_rdy        ,

    output logic [3                 :0] e_rd_vld        ,
    output input_req_pld_t              e_rd_pld[3:0]   ,
    input  logic [3                 :0] e_rd_rdy        ,

    output logic [3                 :0] s_rd_vld        ,
    output input_req_pld_t              s_rd_pld[3:0]   ,
    input  logic [3                 :0] s_rd_rdy        ,

    output logic [3                 :0] n_rd_vld        ,
    output input_req_pld_t              n_rd_pld[3:0]   ,
    input  logic [3                 :0] n_rd_rdy

);

    input_req_pld_t  w_in_rd_pld [WR_REQ_NUM-1:0];
    input_req_pld_t  e_in_rd_pld [ER_REQ_NUM-1:0];
    input_req_pld_t  s_in_rd_pld [SR_REQ_NUM-1:0];
    input_req_pld_t  n_in_rd_pld [NR_REQ_NUM-1:0];

    logic [1:0] w_in_select [WW_REQ_NUM-1:0] ;
    logic [1:0] e_in_select [EW_REQ_NUM-1:0] ;
    logic [1:0] s_in_select [SW_REQ_NUM-1:0] ;
    logic [1:0] n_in_select [NW_REQ_NUM-1:0] ;
    //select gen
    generate
        for(genvar i=0;i<WR_REQ_NUM;i=i+1)begin
            assign w_in_select[i] = w_rd_addr[i][63:62];
        end
    endgenerate
    generate
        for(genvar i=0;i<ER_REQ_NUM;i=i+1)begin
            assign e_in_select[i] = e_rd_addr[i][63:62];
        end
    endgenerate
    generate
        for(genvar i=0;i<SR_REQ_NUM;i=i+1)begin
            assign s_in_select[i] = s_rd_addr[i][63:62];
        end
    endgenerate
    generate
        for(genvar i=0;i<NR_REQ_NUM;i=i+1)begin
            assign n_in_select[i] = n_rd_addr[i][63:62];
        end
    endgenerate



    generate
        for(genvar i=0;i<WR_REQ_NUM;i=i+1)begin:WEST
            assign w_in_rd_pld[i].cmd_addr      = w_rd_addr[i]      ;
            assign w_in_rd_pld[i].cmd_txnid     = w_rd_cmd_txnid[i] ;
            assign w_in_rd_pld[i].cmd_sideband  = w_rd_sideband[i]  ;
            assign w_in_rd_pld[i].strb          = 'b0;
            assign w_in_rd_pld[i].cmd_opcode    = 1'b1;//1 is read
        end
    endgenerate
    generate
        for(genvar i=0;i<ER_REQ_NUM;i=i+1)begin:EAST
            assign e_in_rd_pld[i].cmd_addr      = e_rd_addr[i]      ;
            assign e_in_rd_pld[i].cmd_txnid     = e_rd_cmd_txnid[i] ;
            assign e_in_rd_pld[i].cmd_sideband  = e_rd_sideband[i]  ;
            assign e_in_rd_pld[i].strb          = 'b0;
            assign e_in_rd_pld[i].cmd_opcode    = 1'b1;
        end
    endgenerate
    generate
        for(genvar i=0;i<SR_REQ_NUM;i=i+1)begin:SOUTH
            assign s_in_rd_pld[i].cmd_addr      = s_rd_addr[i]      ;
            assign s_in_rd_pld[i].cmd_txnid     = s_rd_cmd_txnid[i] ;
            assign s_in_rd_pld[i].cmd_sideband  = s_rd_sideband[i]  ;
            assign s_in_rd_pld[i].strb          = 'b0;
            assign s_in_rd_pld[i].cmd_opcode    = 1'b1;
        end
    endgenerate
    generate
        for(genvar i=0;i<NR_REQ_NUM;i=i+1)begin:NORTH
            assign n_in_rd_pld[i].cmd_addr      = n_rd_addr[i]      ;
            assign n_in_rd_pld[i].cmd_txnid     = n_rd_cmd_txnid[i] ;
            assign n_in_rd_pld[i].cmd_sideband  = n_rd_sideband[i]  ;
            assign n_in_rd_pld[i].strb          = 'b0;
            assign n_in_rd_pld[i].cmd_opcode    = 1'b1;
        end
    endgenerate


    nto4_xbar #(
        .N  (WR_REQ_NUM),//west read req num
        .PLD_WIDTH($bits(input_req_pld_t))//
    ) u_west_rd_xbar(
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (w_rd_cmd_vld   ),
        .in_rdy (w_rd_cmd_rdy   ),
        .in_pld (w_in_rd_pld    ),
        .in_select(w_in_select),
        .out_vld(w_rd_vld       ),
        .out_pld(w_rd_pld       ),
        .out_rdy(w_rd_rdy       ));

    nto4_xbar #(
        .N  (ER_REQ_NUM),
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_east_rd_xbar(
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (e_rd_cmd_vld   ),
        .in_rdy (e_rd_cmd_rdy   ),
        .in_pld (e_in_rd_pld    ),
        .in_select(e_in_select),
        .out_vld(e_rd_vld       ),
        .out_pld(e_rd_pld       ),
        .out_rdy(e_rd_rdy       ));

    nto4_xbar #(
        .N  (SR_REQ_NUM),
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_south_rd_xbar(
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (s_rd_cmd_vld   ),
        .in_rdy (s_rd_cmd_rdy   ),
        .in_pld (s_in_rd_pld    ),
        .in_select(s_in_select),
        .out_vld(s_rd_vld       ),
        .out_pld(s_rd_pld       ),
        .out_rdy(s_rd_rdy       ));   

    nto4_xbar #(
        .N  (NR_REQ_NUM),
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_north_rd_xbar(
        .clk    (clk            ),
        .rst_n  (rst_n          ),
        .in_vld (n_rd_cmd_vld   ),
        .in_rdy (n_rd_cmd_rdy   ),
        .in_pld (n_in_rd_pld    ),
        .in_select(n_in_select),
        .out_vld(n_rd_vld       ),
        .out_pld(n_rd_pld       ),
        .out_rdy(n_rd_rdy       ));


    
    

endmodule