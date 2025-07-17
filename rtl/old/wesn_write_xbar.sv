module wesn_write_xbar
import vector_cache_pkg::*;
(
    input  logic                        clk                                   ,
    input  logic                        rst_n                                 ,
    input  logic [WW_REQ_NUM-1      :0] w_wr_cmd_vld                          ,
    output logic [WW_REQ_NUM-1      :0] w_wr_cmd_rdy                          ,
    input  logic [63                :0] w_wr_addr           [WW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] w_wr_data           [WW_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] w_wr_cmd_txnid      [WW_REQ_NUM-1:0]  ,
    input  logic [127               :0] w_strb              [WW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] w_wr_sideband       [WW_REQ_NUM-1:0]  ,

    input  logic [EW_REQ_NUM-1      :0] e_wr_cmd_vld                          ,
    output logic [EW_REQ_NUM-1      :0] e_wr_cmd_rdy                          ,
    input  logic [63                :0] e_wr_addr           [EW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] e_wr_data           [EW_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] e_wr_cmd_txnid      [EW_REQ_NUM-1:0]  ,
    input  logic [127               :0] e_strb              [EW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] e_wr_sideband       [EW_REQ_NUM-1:0]  ,

    input  logic [SW_REQ_NUM-1      :0] s_wr_cmd_vld                          ,
    output logic [SW_REQ_NUM-1      :0] s_wr_cmd_rdy                          ,
    input  logic [63                :0] s_wr_addr           [SW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] s_wr_data           [SW_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] s_wr_cmd_txnid      [SW_REQ_NUM-1:0]  ,
    input  logic [127               :0] s_strb              [SW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] s_wr_sideband       [SW_REQ_NUM-1:0]  ,

    input  logic [NW_REQ_NUM-1      :0] n_wr_cmd_vld                          ,
    output logic [NW_REQ_NUM-1      :0] n_wr_cmd_rdy                          ,
    input  logic [63                :0] n_wr_addr           [NW_REQ_NUM-1:0]  ,
    input  logic [1023              :0] n_wr_data           [NW_REQ_NUM-1:0]  ,
    input  logic [TXNID_WIDTH-1     :0] n_wr_cmd_txnid      [NW_REQ_NUM-1:0]  ,
    input  logic [127               :0] n_strb              [NW_REQ_NUM-1:0]  ,
    input  logic [SIDEBAND_WIDTH-1  :0] n_wr_sideband       [NW_REQ_NUM-1:0]  ,

    output logic [3:0]          west_wr_vld     ,
    output input_req_pld_t      west_wr_pld[3:0],
    output [1023:0]             west_wr_data[3:0],        
    input  logic [3:0]          west_wr_rdy     ,

    output logic [3:0]          east_wr_vld     ,
    output input_req_pld_t      east_wr_pld[3:0],
    output [1023:0]             east_wr_data[3:0],
    input  logic [3:0]          east_wr_rdy     ,

    output logic [3:0]          south_wr_vld     ,
    output input_req_pld_t      south_wr_pld[3:0],
    output [1023:0]             south_wr_data[3:0],
    input  logic [3:0]          south_wr_rdy     ,

    output logic [3:0]          north_wr_vld     ,
    output input_req_pld_t      north_wr_pld[3:0],
    output [1023:0]             north_wr_data[3:0],
    input  logic [3:0]          north_wr_rdy     
);

    input_wrreq_pld_t  w_in_wr_pld [WW_REQ_NUM-1:0];
    input_wrreq_pld_t  e_in_wr_pld [EW_REQ_NUM-1:0];
    input_wrreq_pld_t  s_in_wr_pld [SW_REQ_NUM-1:0];
    input_wrreq_pld_t  n_in_wr_pld [NW_REQ_NUM-1:0];

    input_wrreq_pld_t  west_full_wr_pld [4-1:0];
    input_wrreq_pld_t  east_full_wr_pld [4-1:0];
    input_wrreq_pld_t  south_full_wr_pld [4-1:0];
    input_wrreq_pld_t  north_full_wr_pld [4-1:0];


    logic [1:0] w_in_select [WW_REQ_NUM-1:0] ;//nto4 select width = $clog2(4)=2
    logic [1:0] e_in_select [EW_REQ_NUM-1:0] ;//地址的高2bit作为select信号，也就是hash_id
    logic [1:0] s_in_select [SW_REQ_NUM-1:0] ;
    logic [1:0] n_in_select [NW_REQ_NUM-1:0] ;

    //select gen
    generate
        for(genvar i=0;i<WW_REQ_NUM;i=i+1)begin
            assign w_in_select[i] = w_wr_addr[i][63:62];
        end
    endgenerate
    generate
        for(genvar i=0;i<EW_REQ_NUM;i=i+1)begin
            assign e_in_select[i] = e_wr_addr[i][63:62];
        end
    endgenerate
    generate
        for(genvar i=0;i<SW_REQ_NUM;i=i+1)begin
            assign s_in_select[i] = s_wr_addr[i][63:62];
        end
    endgenerate
    generate
        for(genvar i=0;i<NW_REQ_NUM;i=i+1)begin
            assign n_in_select[i] = n_wr_addr[i][63:62];
        end
    endgenerate


    generate
        for(genvar i=0;i<WW_REQ_NUM;i=i+1)begin:WEST_WR
            assign w_in_wr_pld[i].cmd_pld.cmd_addr      = w_wr_addr[i]      ;
            assign w_in_wr_pld[i].data                  = w_wr_data[i]      ;
            assign w_in_wr_pld[i].cmd_pld.cmd_txnid     = w_wr_cmd_txnid[i] ;
            assign w_in_wr_pld[i].cmd_pld.cmd_sideband  = w_wr_sideband[i]  ;
            assign w_in_wr_pld[i].cmd_pld.strb          = w_strb[i]         ;
            assign w_in_wr_pld[i].cmd_pld.cmd_opcode    = 1'b0              ; //0 is write
        end
    endgenerate
    generate
        for(genvar i=0;i<EW_REQ_NUM;i=i+1)begin:EAST_WR
            assign e_in_wr_pld[i].cmd_pld.cmd_addr      = e_wr_addr[i]      ;
            assign e_in_wr_pld[i].data                  = e_wr_data[i]      ;
            assign e_in_wr_pld[i].cmd_pld.cmd_txnid     = e_wr_cmd_txnid[i] ;
            assign e_in_wr_pld[i].cmd_pld.cmd_sideband  = e_wr_sideband[i]  ;
            assign e_in_wr_pld[i].cmd_pld.strb          = e_strb[i]         ;
            assign e_in_wr_pld[i].cmd_pld.cmd_opcode    = 1'b0              ; //0 is write
        end
    endgenerate
    generate
        for(genvar i=0;i<SW_REQ_NUM;i=i+1)begin:SOUTH_WR
            assign s_in_wr_pld[i].cmd_pld.cmd_addr      = s_wr_addr[i]      ;
            assign s_in_wr_pld[i].data                  = s_wr_data[i]      ;
            assign s_in_wr_pld[i].cmd_pld.cmd_txnid     = s_wr_cmd_txnid[i] ;
            assign s_in_wr_pld[i].cmd_pld.cmd_sideband  = s_wr_sideband[i]  ;
            assign s_in_wr_pld[i].cmd_pld.strb          = s_strb[i]         ;
            assign s_in_wr_pld[i].cmd_pld.cmd_opcode    = 1'b0              ; //0 is write
        end
    endgenerate
    generate
        for(genvar i=0;i<NW_REQ_NUM;i=i+1)begin:NORTH_WR
            assign n_in_wr_pld[i].cmd_pld.cmd_addr      = n_wr_addr[i]      ;
            assign n_in_wr_pld[i].data                  = n_wr_data[i]      ;
            assign n_in_wr_pld[i].cmd_pld.cmd_txnid     = n_wr_cmd_txnid[i] ;
            assign n_in_wr_pld[i].cmd_pld.cmd_sideband  = n_wr_sideband[i]  ;
            assign n_in_wr_pld[i].cmd_pld.strb          = n_strb[i]         ;
            assign n_in_wr_pld[i].cmd_pld.cmd_opcode    = 1'b0              ; //0 is write
        end
    endgenerate

    nto4_xbar #(
        .IN_NUM  (WW_REQ_NUM),//input num
        .OUT_NUM(4),//output num
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_west_wr_xbar(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .in_vld     (w_wr_cmd_vld       ),
        .in_rdy     (w_wr_cmd_rdy       ),
        .in_pld     (w_in_wr_pld        ),
        .in_select  (w_in_select        ),
        .out_vld    (west_wr_vld        ),
        .out_pld    (west_full_wr_pld   ),
        .out_rdy    (west_wr_rdy       ));
    nto4_xbar #(
        .IN_NUM  (EW_REQ_NUM),
        .OUT_NUM(4),//output num
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_east_wr_xbar(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .in_vld     (e_wr_cmd_vld       ),
        .in_rdy     (e_wr_cmd_rdy       ),
        .in_pld     (e_in_wr_pld        ),
        .in_select  (e_in_select        ),
        .out_vld    (east_wr_vld        ),
        .out_pld    (east_full_wr_pld   ),
        .out_rdy    (east_wr_rdy        ));

    nto4_xbar #(
        .IN_NUM  (SW_REQ_NUM),
        .OUT_NUM(4),//output num
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_south_wr_xbar(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .in_vld     (s_wr_cmd_vld       ),
        .in_rdy     (s_wr_cmd_rdy       ),
        .in_pld     (s_in_wr_pld        ),
        .in_select  (s_in_select        ),
        .out_vld    (south_wr_vld       ),
        .out_pld    (south_full_wr_pld  ),
        .out_rdy    (south_wr_rdy       ));

    nto4_xbar #(
        .IN_NUM  (NW_REQ_NUM),
        .OUT_NUM(4),//output num
        .PLD_WIDTH($bits(input_req_pld_t))
    ) u_north_wr_xbar(
        .clk        (clk                ),
        .rst_n      (rst_n              ),
        .in_vld     (n_wr_cmd_vld       ),
        .in_rdy     (n_wr_cmd_rdy       ),
        .in_pld     (n_in_wr_pld        ),
        .in_select  (n_in_select        ),
        .out_vld    (north_wr_vld       ),
        .out_pld    (north_full_wr_pld  ),
        .out_rdy    (north_wr_rdy       ));

    generate
        for(genvar i=0;i<4;i=i+1)begin: Mto4_XBAR_out_gen
            assign west_wr_data[i] = west_full_wr_pld[i].data;
            assign west_wr_pld[i]  = west_full_wr_pld[i].cmd_pld;

            assign east_wr_data[i] = east_full_wr_pld[i].data;
            assign east_wr_pld[i]  = east_full_wr_pld[i].cmd_pld;

            assign south_wr_data[i] = south_full_wr_pld[i].data;
            assign south_wr_pld[i]  = south_full_wr_pld[i].cmd_pld;

            assign north_wr_data[i] = north_full_wr_pld[i].data;
            assign north_wr_pld[i]  = north_full_wr_pld[i].cmd_pld;
        end
    endgenerate    
    

endmodule