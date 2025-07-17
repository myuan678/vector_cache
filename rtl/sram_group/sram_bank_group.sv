module sram_bank_group 
import vector_cache_pkg::*;
#(
    parameter integer unsigned BLOCK_ID =0 ,
    parameter integer unsigned ROW_ID   = 0)
(
    input  logic                clk                                   ,
    input  logic                clk_div                               ,
    input  logic                rst_n                                 ,
    input  arb_out_req_t        west_read_cmd_pld_in         [7:0]    ,
    input  logic [7:0]          west_read_cmd_vld_in                  ,
    input  arb_out_req_t        east_read_cmd_pld_in         [7:0]    ,
    input  logic [7:0]          east_read_cmd_vld_in                  ,
    input  write_ram_cmd_t      west_write_cmd_pld_in        [7:0]    ,
    input  logic [7:0]          west_write_cmd_vld_in                 ,
    input  write_ram_cmd_t      east_write_cmd_pld_in        [7:0]    ,
    input  logic [7:0]          east_write_cmd_vld_in                 ,
    input  write_ram_cmd_t      south_write_cmd_pld_in        [7:0]   ,
    input  logic [7:0]          south_write_cmd_vld_in                ,
    input  write_ram_cmd_t      north_write_cmd_pld_in        [7:0]   ,
    input  logic [7:0]          north_write_cmd_vld_in                ,

    output arb_out_req_t        west_read_cmd_pld_out        [7:0]    ,
    output logic [7:0]          west_read_cmd_vld_out                 ,
    output arb_out_req_t        east_read_cmd_pld_out        [7:0]    ,
    output logic [7:0]          east_read_cmd_vld_out                 ,
    output write_ram_cmd_t      west_write_cmd_pld_out       [7:0]    ,
    output logic [7:0]          west_write_cmd_vld_out                ,
    output write_ram_cmd_t      east_write_cmd_pld_out       [7:0]    ,
    output logic [7:0]          east_write_cmd_vld_out                ,
    output write_ram_cmd_t      south_write_cmd_pld_out      [7:0]    ,
    output logic [7:0]          south_write_cmd_vld_out               ,
    output write_ram_cmd_t      north_write_cmd_pld_out      [7:0]    ,
    output logic [7:0]          north_write_cmd_vld_out               ,

    input  logic [7         :0] west_data_in_vld                      ,
    input  bankgroup_data_pld_t west_data_in                  [7  :0] ,
    input  logic [7         :0] east_data_in_vld                      ,
    input  bankgroup_data_pld_t east_data_in                  [7  :0] ,
    input  logic [7         :0] south_data_in_vld                     ,
    input  bankgroup_data_pld_t south_data_in                 [7  :0] ,
    input  logic [7         :0] north_data_in_vld                     ,
    input  bankgroup_data_pld_t north_data_in                 [7  :0] ,

    output logic [7         :0] west_data_out_vld                     ,
    output bankgroup_data_pld_t west_data_out                 [7  :0] ,
    output logic [7         :0] east_data_out_vld                     ,
    output bankgroup_data_pld_t east_data_out                 [7  :0] ,
    output logic [7         :0] south_data_out_vld                    ,
    output bankgroup_data_pld_t south_data_out                [7  :0] ,
    output logic [7         :0] north_data_out_vld                    ,
    output bankgroup_data_pld_t north_data_out                [7  :0] 
);


    arb_out_req_t        fanout_west_read_cmd_pld_in    [7:0]     [7:0]  ;
    logic [7:0]          fanout_west_read_cmd_vld_in    [7:0]            ;
    arb_out_req_t        fanout_east_read_cmd_pld_in    [7:0]     [7:0]  ;
    logic [7:0]          fanout_east_read_cmd_vld_in    [7:0]            ;
    write_ram_cmd_t      fanout_west_write_cmd_pld_in   [7:0]     [7:0]  ;
    logic [7:0]          fanout_west_write_cmd_vld_in   [7:0]            ;
    write_ram_cmd_t      fanout_east_write_cmd_pld_in   [7:0]     [7:0]  ;
    logic [7:0]          fanout_east_write_cmd_vld_in   [7:0]            ;
    write_ram_cmd_t      fanout_south_write_cmd_pld_in  [7:0]      [7:0] ;
    logic [7:0]          fanout_south_write_cmd_vld_in  [7:0]            ;
    write_ram_cmd_t      fanout_north_write_cmd_pld_in  [7:0]     [7:0]  ;
    logic [7:0]          fanout_north_write_cmd_vld_in  [7:0]            ;

    arb_out_req_t        fanout_west_read_cmd_pld_out   [7:0]     [7:0]  ;
    logic [7:0]          fanout_west_read_cmd_vld_out   [7:0]            ;
    arb_out_req_t        fanout_east_read_cmd_pld_out   [7:0]     [7:0]  ;
    logic [7:0]          fanout_east_read_cmd_vld_out   [7:0]            ;
    write_ram_cmd_t      fanout_west_write_cmd_pld_out  [7:0]     [7:0]  ;
    logic [7:0]          fanout_west_write_cmd_vld_out  [7:0]            ;
    write_ram_cmd_t      fanout_east_write_cmd_pld_out  [7:0]     [7:0]  ;
    logic [7:0]          fanout_east_write_cmd_vld_out  [7:0]            ;
    write_ram_cmd_t      fanout_south_write_cmd_pld_out [7:0]     [7:0]  ;
    logic [7:0]          fanout_south_write_cmd_vld_out [7:0]            ;
    write_ram_cmd_t      fanout_north_write_cmd_pld_out [7:0]     [7:0]  ;
    logic [7:0]          fanout_north_write_cmd_vld_out [7:0]            ;

    logic [7 :0]         fanout_west_data_in_vld        [7:0]            ;
    data_pld_t           fanout_west_data_in            [7:0][7:0]       ;
    logic [7 :0]         fanout_east_data_in_vld        [7:0]            ;
    data_pld_t           fanout_east_data_in            [7:0][7:0]       ;
    logic [7 :0]         fanout_south_data_in_vld       [7:0]            ;
    data_pld_t           fanout_south_data_in           [7:0][7:0]       ;
    logic [7 :0]         fanout_north_data_in_vld       [7:0]            ;
    data_pld_t           fanout_north_data_in           [7:0][7:0]       ;

    logic [7 :0]         fanout_west_data_out_vld       [7:0]            ;
    data_pld_t           fanout_west_data_out           [7:0][7:0]       ;
    logic [7 :0]         fanout_east_data_out_vld       [7:0]            ;
    data_pld_t           fanout_east_data_out           [7:0][7:0]       ;
    logic [7 :0]         fanout_south_data_out_vld      [7:0]            ;
    data_pld_t           fanout_south_data_out          [7:0][7:0]       ;
    logic [7 :0]         fanout_north_data_out_vld      [7:0]            ;
    data_pld_t           fanout_north_data_out          [7:0][7:0]       ;


    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign fanout_west_read_cmd_pld_in  [i] = west_read_cmd_pld_in  ;
            assign fanout_west_read_cmd_vld_in  [i] = west_read_cmd_vld_in  ;
            assign fanout_east_read_cmd_pld_in  [i] = east_read_cmd_pld_in  ;
            assign fanout_east_read_cmd_vld_in  [i] = east_read_cmd_vld_in  ; 
            assign fanout_west_write_cmd_pld_in [i] = west_write_cmd_pld_in ;
            assign fanout_west_write_cmd_vld_in [i] = west_write_cmd_vld_in ;
            assign fanout_east_write_cmd_pld_in [i] = east_write_cmd_pld_in ;
            assign fanout_east_write_cmd_vld_in [i] = east_write_cmd_vld_in ;
            assign fanout_south_write_cmd_pld_in[i] = south_write_cmd_pld_in;
            assign fanout_south_write_cmd_vld_in[i] = south_write_cmd_vld_in;
            assign fanout_north_write_cmd_pld_in[i] = north_write_cmd_pld_in;
            assign fanout_north_write_cmd_vld_in[i] = north_write_cmd_vld_in;
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            for(genvar j=0;j<8;j=j+1)begin
                assign fanout_west_data_in_vld[i][j]      = west_data_in_vld[j]                 ;
                assign fanout_west_data_in[i][j].data     = west_data_in[i].data[j*32 +: 32]    ;
                assign fanout_west_data_in[i][j].cmd_pld  =west_data_in[i].cmd_pld              ;
                assign fanout_east_data_in_vld[i][j]      = east_data_in_vld[j]                 ;
                assign fanout_east_data_in[i][j].data     = east_data_in[i].data[j*32 +: 32]    ;
                assign fanout_east_data_in[i][j].cmd_pld  = east_data_in[i].cmd_pld             ;
                assign fanout_south_data_in_vld[i][j]     = south_data_in_vld[j]                ;
                assign fanout_south_data_in[i][j].data    = south_data_in[i].data[j*32 +: 32]   ;
                assign fanout_south_data_in[i][j].cmd_pld = south_data_in[i].cmd_pld            ;
                assign fanout_north_data_in_vld[i][j]     = north_data_in_vld[j]                ;
                assign fanout_north_data_in[i][j].data    = north_data_in[i].data[j*32 +: 32]   ;
                assign fanout_north_data_in[i][j].cmd_pld = north_data_in[i].cmd_pld            ;
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            sram_bank #( 
                .BLOCK_ID(BLOCK_ID),
                .ROW_ID  (ROW_ID)
            )u_sram_bank(
                .clk                    (clk                      ),
                .clk_div                (clk_div                  ),
                .rst_n                  (rst_n                    ),
                .west_read_cmd_pld_in   (fanout_west_read_cmd_pld_in[i]  ),
                .west_read_cmd_vld_in   (fanout_west_read_cmd_vld_in[i]  ),
                .east_read_cmd_pld_in   (fanout_east_read_cmd_pld_in[i]  ),
                .east_read_cmd_vld_in   (fanout_east_read_cmd_vld_in[i]  ),
                .west_write_cmd_pld_in  (fanout_west_write_cmd_pld_in[i] ),
                .west_write_cmd_vld_in  (fanout_west_write_cmd_vld_in[i] ),
                .east_write_cmd_pld_in  (fanout_east_write_cmd_pld_in[i] ),
                .east_write_cmd_vld_in  (fanout_east_write_cmd_vld_in[i] ),
                .south_write_cmd_pld_in (fanout_south_write_cmd_pld_in[i]),
                .south_write_cmd_vld_in (fanout_south_write_cmd_vld_in[i]),
                .north_write_cmd_pld_in (fanout_north_write_cmd_pld_in[i]),
                .north_write_cmd_vld_in (fanout_north_write_cmd_vld_in[i]),

                .west_read_cmd_pld_out  (fanout_west_read_cmd_pld_out[i] ),
                .west_read_cmd_vld_out  (fanout_west_read_cmd_vld_out[i] ),
                .east_read_cmd_pld_out  (fanout_east_read_cmd_pld_out[i] ),
                .east_read_cmd_vld_out  (fanout_east_read_cmd_vld_out[i] ),
                .west_write_cmd_pld_out (fanout_west_write_cmd_pld_out[i]),
                .west_write_cmd_vld_out (fanout_west_write_cmd_vld_out[i]),
                .east_write_cmd_pld_out (fanout_east_write_cmd_pld_out[i]),
                .east_write_cmd_vld_out (fanout_east_write_cmd_vld_out[i]), 
                .south_write_cmd_pld_out(fanout_south_write_cmd_pld_out[i]),
                .south_write_cmd_vld_out(fanout_south_write_cmd_vld_out[i]),
                .north_write_cmd_pld_out(fanout_north_write_cmd_pld_out[i]),
                .north_write_cmd_vld_out(fanout_north_write_cmd_vld_out[i]),

                .west_data_in_vld       (fanout_west_data_in_vld[i]       ),
                .west_data_in           (fanout_west_data_in[i]           ),
                .east_data_in_vld       (fanout_east_data_in_vld[i]       ),
                .east_data_in           (fanout_east_data_in[i]           ),
                .south_data_in_vld      (fanout_south_data_in_vld [i]     ),
                .south_data_in          (fanout_south_data_in[i]          ),
                .north_data_in_vld      (fanout_north_data_in_vld [i]     ),
                .north_data_in          (fanout_north_data_in[i]          ),

                .west_data_out_vld      (fanout_west_data_out_vld[i]      ),
                .west_data_out          (fanout_west_data_out[i]          ),
                .east_data_out_vld      (fanout_east_data_out_vld[i]      ),
                .east_data_out          (fanout_east_data_out[i]          ),
                .south_data_out_vld     (fanout_south_data_out_vld[i]     ),
                .south_data_out         (fanout_south_data_out[i]         ),
                .north_data_out_vld     (fanout_north_data_out_vld[i]     ),
                .north_data_out         (fanout_north_data_out[i]         ));
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign west_data_out_vld[i] = &fanout_west_data_out_vld[i];
            assign west_data_out[i].cmd_pld = fanout_west_data_out[i][0].cmd_pld;
            assign west_data_out[i].data ={fanout_west_data_out[i][7].data,
                                           fanout_west_data_out[i][6].data,
                                           fanout_west_data_out[i][5].data,
                                           fanout_west_data_out[i][4].data,
                                           fanout_west_data_out[i][3].data,
                                           fanout_west_data_out[i][2].data,
                                           fanout_west_data_out[i][1].data,
                                           fanout_west_data_out[i][0].data};
            assign east_data_out_vld[i] = &fanout_east_data_out_vld[i];
            assign east_data_out[i].cmd_pld =fanout_east_data_out[i][0].cmd_pld;
            assign east_data_out[i].data ={fanout_east_data_out[i][7].data,
                                           fanout_east_data_out[i][6].data,
                                           fanout_east_data_out[i][5].data,
                                           fanout_east_data_out[i][4].data,
                                           fanout_east_data_out[i][3].data,
                                           fanout_east_data_out[i][2].data,
                                           fanout_east_data_out[i][1].data,
                                           fanout_east_data_out[i][0].data};
            assign south_data_out_vld[i] =&fanout_south_data_out_vld[i];
            assign south_data_out[i].cmd_pld = fanout_south_data_out[i][0].cmd_pld;
            assign south_data_out[i].data={fanout_south_data_out[i][7].data,
                                           fanout_south_data_out[i][6].data,
                                           fanout_south_data_out[i][5].data,
                                           fanout_south_data_out[i][4].data,
                                           fanout_south_data_out[i][3].data,
                                           fanout_south_data_out[i][2].data,
                                           fanout_south_data_out[i][1].data,
                                           fanout_south_data_out[i][0].data};
            assign north_data_out_vld[i] =&fanout_north_data_out_vld[i];
            assign north_data_out[i].cmd_pld =fanout_north_data_out[i][0].cmd_pld;
            assign north_data_out[i].data={fanout_north_data_out[i][7].data,
                                           fanout_north_data_out[i][6].data,
                                           fanout_north_data_out[i][5].data,
                                           fanout_north_data_out[i][4].data,
                                           fanout_north_data_out[i][3].data,
                                           fanout_north_data_out[i][2].data,
                                           fanout_north_data_out[i][1].data,
                                           fanout_north_data_out[i][0].data};
        end
    endgenerate


    //dont need output
    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign west_read_cmd_pld_out  [i] = fanout_west_read_cmd_pld_out[0][i]  ;
            assign west_read_cmd_vld_out  [i] = fanout_west_read_cmd_vld_out[0][i]  ;
            assign east_read_cmd_pld_out  [i] = fanout_east_read_cmd_pld_out[0][i]  ;
            assign east_read_cmd_vld_out  [i] = fanout_east_read_cmd_vld_out[0][i]  ;
            assign west_write_cmd_pld_out [i] = fanout_west_write_cmd_pld_out[0][i] ;
            assign west_write_cmd_vld_out [i] = fanout_west_write_cmd_vld_out[0][i] ;
            assign east_write_cmd_pld_out [i] = fanout_east_write_cmd_pld_out[0][i] ;
            assign east_write_cmd_vld_out [i] = fanout_east_write_cmd_vld_out[0][i] ;
            assign south_write_cmd_pld_out[i] = fanout_south_write_cmd_pld_out[0][i];
            assign south_write_cmd_vld_out[i] = fanout_south_write_cmd_vld_out[0][i];
            assign north_write_cmd_pld_out[i] = fanout_north_write_cmd_pld_out[0][i];
            assign north_write_cmd_vld_out[i] = fanout_north_write_cmd_vld_out[0][i];
        end
    endgenerate

endmodule

