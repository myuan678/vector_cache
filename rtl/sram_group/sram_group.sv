module sram_group 
    import vector_cache_pkg::*;
    //#(
    //parameter integer unsigned BLOCK_ID =0 ,
    //parameter integer unsigned ROW_ID   =0)
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
    input  write_ram_cmd_t      south_write_cmd_pld_in       [7:0]    ,
    input  logic [7:0]          south_write_cmd_vld_in                ,
    input  write_ram_cmd_t      north_write_cmd_pld_in       [7:0]    ,
    input  logic [7:0]          north_write_cmd_vld_in                ,
 
    output arb_out_req_t        east_read_cmd_pld_out        [7:0]    ,
    output logic [7:0]          east_read_cmd_vld_out                 , 
    output write_ram_cmd_t      east_write_cmd_pld_out       [7:0]    ,
    output logic [7:0]          east_write_cmd_vld_out                ,

    input  logic [7  :0]        west_data_in_vld                       ,
    input  group_data_pld_t     west_data_in                 [7:0]     ,
    input  logic [7  :0]        east_data_in_vld                       ,
    input  group_data_pld_t     east_data_in                 [7:0]     ,
    input  logic [7  :0]        south_data_in_vld                      ,
    input  group_data_pld_t     south_data_in                [7:0]     ,
    input  logic [7  :0]        north_data_in_vld                      ,
    input  group_data_pld_t     north_data_in                [7:0]     ,

    output logic [7  :0]        west_data_out_vld                      ,
    output group_data_pld_t     west_data_out                [7:0]     ,
    output logic [7  :0]        east_data_out_vld                      ,
    output group_data_pld_t     east_data_out                [7:0]     ,
    output logic [7  :0]        south_data_out_vld                     ,
    output group_data_pld_t     south_data_out               [7:0]     ,
    output logic [7  :0]        north_data_out_vld                     ,   
    output group_data_pld_t     north_data_out               [7:0]    

    //output write_ram_cmd_t      west_write_cmd_pld_out       [7:0]    ,
    //output logic [7:0]          west_write_cmd_vld_out                ,
    //output arb_out_req_t        west_read_cmd_pld_out        [7:0]    ,
    //output logic [7:0]          west_read_cmd_vld_out                 ,
    //output write_ram_cmd_t      south_write_cmd_pld_out      [7:0]    ,
    //output logic [7:0]          south_write_cmd_vld_out               ,
    //output write_ram_cmd_t      north_write_cmd_pld_out      [7:0]    ,
    //output logic [7:0]          north_write_cmd_vld_out               ,
);
    arb_out_req_t       west_read_cmd_pld_in_row0 [7:0];
    arb_out_req_t       west_read_cmd_pld_in_row1 [7:0];
    arb_out_req_t       west_read_cmd_pld_in_row2 [7:0];
    arb_out_req_t       west_read_cmd_pld_in_row3 [7:0];
    logic [7:0]         west_read_cmd_vld_in_row0      ;
    logic [7:0]         west_read_cmd_vld_in_row1      ;
    logic [7:0]         west_read_cmd_vld_in_row2      ;
    logic [7:0]         west_read_cmd_vld_in_row3      ;
    arb_out_req_t       east_read_cmd_pld_in_row0 [7:0];
    arb_out_req_t       east_read_cmd_pld_in_row1 [7:0];
    arb_out_req_t       east_read_cmd_pld_in_row2 [7:0];
    arb_out_req_t       east_read_cmd_pld_in_row3 [7:0];
    logic [7:0]         east_read_cmd_vld_in_row0      ;
    logic [7:0]         east_read_cmd_vld_in_row1      ;
    logic [7:0]         east_read_cmd_vld_in_row2      ;
    logic [7:0]         east_read_cmd_vld_in_row3      ;
    arb_out_req_t       west_read_cmd_pld_out_row0 [7:0];
    arb_out_req_t       west_read_cmd_pld_out_row1 [7:0];
    arb_out_req_t       west_read_cmd_pld_out_row2 [7:0];
    arb_out_req_t       west_read_cmd_pld_out_row3 [7:0];
    logic [7:0]         west_read_cmd_vld_out_row0      ;
    logic [7:0]         west_read_cmd_vld_out_row1      ;
    logic [7:0]         west_read_cmd_vld_out_row2      ;
    logic [7:0]         west_read_cmd_vld_out_row3      ;
    arb_out_req_t       east_read_cmd_pld_out_row0 [7:0];
    arb_out_req_t       east_read_cmd_pld_out_row1 [7:0];
    arb_out_req_t       east_read_cmd_pld_out_row2 [7:0];
    arb_out_req_t       east_read_cmd_pld_out_row3 [7:0];
    logic [7:0]         east_read_cmd_vld_out_row0      ;
    logic [7:0]         east_read_cmd_vld_out_row1      ;
    logic [7:0]         east_read_cmd_vld_out_row2      ;
    logic [7:0]         east_read_cmd_vld_out_row3      ;

    write_ram_cmd_t     west_write_cmd_pld_in_row0 [7:0];
    write_ram_cmd_t     west_write_cmd_pld_in_row1 [7:0];
    write_ram_cmd_t     west_write_cmd_pld_in_row2 [7:0];
    write_ram_cmd_t     west_write_cmd_pld_in_row3 [7:0];
    logic [7:0]         west_write_cmd_vld_in_row0      ;
    logic [7:0]         west_write_cmd_vld_in_row1      ;
    logic [7:0]         west_write_cmd_vld_in_row2      ;
    logic [7:0]         west_write_cmd_vld_in_row3      ;
    write_ram_cmd_t     east_write_cmd_pld_in_row0 [7:0];
    write_ram_cmd_t     east_write_cmd_pld_in_row1 [7:0];
    write_ram_cmd_t     east_write_cmd_pld_in_row2 [7:0];
    write_ram_cmd_t     east_write_cmd_pld_in_row3 [7:0];
    logic [7:0]         east_write_cmd_vld_in_row0      ;
    logic [7:0]         east_write_cmd_vld_in_row1      ;
    logic [7:0]         east_write_cmd_vld_in_row2      ;
    logic [7:0]         east_write_cmd_vld_in_row3      ;
    write_ram_cmd_t     west_write_cmd_pld_out_row0 [7:0];
    write_ram_cmd_t     west_write_cmd_pld_out_row1 [7:0];
    write_ram_cmd_t     west_write_cmd_pld_out_row2 [7:0];
    write_ram_cmd_t     west_write_cmd_pld_out_row3 [7:0];
    logic [7:0]         west_write_cmd_vld_out_row0      ;
    logic [7:0]         west_write_cmd_vld_out_row1      ;
    logic [7:0]         west_write_cmd_vld_out_row2      ;
    logic [7:0]         west_write_cmd_vld_out_row3      ;
    write_ram_cmd_t     east_write_cmd_pld_out_row0 [7:0];
    write_ram_cmd_t     east_write_cmd_pld_out_row1 [7:0];
    write_ram_cmd_t     east_write_cmd_pld_out_row2 [7:0];
    write_ram_cmd_t     east_write_cmd_pld_out_row3 [7:0];
    logic [7:0]         east_write_cmd_vld_out_row0      ;
    logic [7:0]         east_write_cmd_vld_out_row1      ;
    logic [7:0]         east_write_cmd_vld_out_row2      ;
    logic [7:0]         east_write_cmd_vld_out_row3      ;

    write_ram_cmd_t     south_write_cmd_pld_in_block0 [7:0];
    write_ram_cmd_t     south_write_cmd_pld_in_block1 [7:0];
    write_ram_cmd_t     south_write_cmd_pld_in_block2 [7:0];
    write_ram_cmd_t     south_write_cmd_pld_in_block3 [7:0];
    logic [7:0]         south_write_cmd_vld_in_block0      ;
    logic [7:0]         south_write_cmd_vld_in_block1      ;
    logic [7:0]         south_write_cmd_vld_in_block2      ;
    logic [7:0]         south_write_cmd_vld_in_block3      ;
    write_ram_cmd_t     north_write_cmd_pld_in_block0 [7:0];
    write_ram_cmd_t     north_write_cmd_pld_in_block1 [7:0];
    write_ram_cmd_t     north_write_cmd_pld_in_block2 [7:0];
    write_ram_cmd_t     north_write_cmd_pld_in_block3 [7:0];
    logic [7:0]         north_write_cmd_vld_in_block0      ;
    logic [7:0]         north_write_cmd_vld_in_block1      ;
    logic [7:0]         north_write_cmd_vld_in_block2      ;
    logic [7:0]         north_write_cmd_vld_in_block3      ;
    write_ram_cmd_t     south_write_cmd_pld_out_block0 [7:0];
    write_ram_cmd_t     south_write_cmd_pld_out_block1 [7:0];
    write_ram_cmd_t     south_write_cmd_pld_out_block2 [7:0];
    write_ram_cmd_t     south_write_cmd_pld_out_block3 [7:0];
    logic [7:0]         south_write_cmd_vld_out_block0      ;
    logic [7:0]         south_write_cmd_vld_out_block1      ;
    logic [7:0]         south_write_cmd_vld_out_block2      ;
    logic [7:0]         south_write_cmd_vld_out_block3      ;
    write_ram_cmd_t     north_write_cmd_pld_out_block0 [7:0];
    write_ram_cmd_t     north_write_cmd_pld_out_block1 [7:0];
    write_ram_cmd_t     north_write_cmd_pld_out_block2 [7:0];
    write_ram_cmd_t     north_write_cmd_pld_out_block3 [7:0];
    logic [7:0]         north_write_cmd_vld_out_block0      ;
    logic [7:0]         north_write_cmd_vld_out_block1      ;
    logic [7:0]         north_write_cmd_vld_out_block2      ;
    logic [7:0]         north_write_cmd_vld_out_block3      ;


    bankgroup_data_pld_t    west_data_in_row0   [7:0];
    bankgroup_data_pld_t    west_data_in_row1   [7:0];
    bankgroup_data_pld_t    west_data_in_row2   [7:0];
    bankgroup_data_pld_t    west_data_in_row3   [7:0];
    logic [7  :0]           west_data_in_vld_row0   ;
    logic [7  :0]           west_data_in_vld_row1   ;
    logic [7  :0]           west_data_in_vld_row2   ;
    logic [7  :0]           west_data_in_vld_row3   ;
    bankgroup_data_pld_t    east_data_in_row0   [7:0];
    bankgroup_data_pld_t    east_data_in_row1   [7:0];
    bankgroup_data_pld_t    east_data_in_row2   [7:0];
    bankgroup_data_pld_t    east_data_in_row3   [7:0];
    logic [7  :0]           east_data_in_vld_row0   ;
    logic [7  :0]           east_data_in_vld_row1   ;
    logic [7  :0]           east_data_in_vld_row2   ;
    logic [7  :0]           east_data_in_vld_row3   ;
    bankgroup_data_pld_t    south_data_in_block0[7:0];
    bankgroup_data_pld_t    south_data_in_block1[7:0];
    bankgroup_data_pld_t    south_data_in_block2[7:0];
    bankgroup_data_pld_t    south_data_in_block3[7:0];
    logic [7  :0]           south_data_in_vld_block0;
    logic [7  :0]           south_data_in_vld_block1;
    logic [7  :0]           south_data_in_vld_block2;
    logic [7  :0]           south_data_in_vld_block3;
    bankgroup_data_pld_t    north_data_in_block0[7:0];
    bankgroup_data_pld_t    north_data_in_block1[7:0];
    bankgroup_data_pld_t    north_data_in_block2[7:0];
    bankgroup_data_pld_t    north_data_in_block3[7:0];
    logic [7  :0]           north_data_in_vld_block0;
    logic [7  :0]           north_data_in_vld_block1;
    logic [7  :0]           north_data_in_vld_block2;
    logic [7  :0]           north_data_in_vld_block3;

    bankgroup_data_pld_t    west_data_out_row0   [7:0];
    bankgroup_data_pld_t    west_data_out_row1   [7:0];
    bankgroup_data_pld_t    west_data_out_row2   [7:0];
    bankgroup_data_pld_t    west_data_out_row3   [7:0];
    bankgroup_data_pld_t    east_data_out_row0   [7:0];
    bankgroup_data_pld_t    east_data_out_row1   [7:0];
    bankgroup_data_pld_t    east_data_out_row2   [7:0];
    bankgroup_data_pld_t    east_data_out_row3   [7:0];
    bankgroup_data_pld_t    south_data_out_block0[7:0];
    bankgroup_data_pld_t    south_data_out_block1[7:0];
    bankgroup_data_pld_t    south_data_out_block2[7:0];
    bankgroup_data_pld_t    south_data_out_block3[7:0];
    bankgroup_data_pld_t    north_data_out_block0[7:0];
    bankgroup_data_pld_t    north_data_out_block1[7:0];
    bankgroup_data_pld_t    north_data_out_block2[7:0];
    bankgroup_data_pld_t    north_data_out_block3[7:0];

    logic [7:0] west_data_out_vld_row3;
    logic [7:0] west_data_out_vld_row2;
    logic [7:0] west_data_out_vld_row1;
    logic [7:0] west_data_out_vld_row0;
    logic [7:0] east_data_out_vld_row3;
    logic [7:0] east_data_out_vld_row2;
    logic [7:0] east_data_out_vld_row1;
    logic [7:0] east_data_out_vld_row0;
    logic [7:0] south_data_out_vld_block3;
    logic [7:0] south_data_out_vld_block2;
    logic [7:0] south_data_out_vld_block1;
    logic [7:0] south_data_out_vld_block0;
    logic [7:0] north_data_out_vld_block3;
    logic [7:0] north_data_out_vld_block2;
    logic [7:0] north_data_out_vld_block1;
    logic [7:0] north_data_out_vld_block0;


    arb_out_req_t       west_read_cmd_pld_out_01    [7  :0]  ;
    logic [7  :0]       west_read_cmd_vld_out_01             ;
    arb_out_req_t       east_read_cmd_pld_out_00    [7  :0]  ;
    logic [7  :0]       east_read_cmd_vld_out_00             ;
    write_ram_cmd_t     west_write_cmd_pld_out_01   [7  :0]  ; 
    logic [7  :0]       west_write_cmd_vld_out_01            ; 
    write_ram_cmd_t     east_write_cmd_pld_out_00   [7  :0]  ; 
    logic [7  :0]       east_write_cmd_vld_out_00            ; 
    write_ram_cmd_t     north_write_cmd_pld_out_10  [7  :0]  ;
    logic [7  :0]       north_write_cmd_vld_out_10           ;
    write_ram_cmd_t     south_write_cmd_pld_out_00  [7  :0]  ;
    logic [7  :0]       south_write_cmd_vld_out_00           ;

    arb_out_req_t       east_read_cmd_pld_out_01  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_01  ;
    arb_out_req_t       west_read_cmd_pld_out_02  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_02  ;
    arb_out_req_t       west_read_cmd_pld_out_03  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_03  ;
    arb_out_req_t       east_read_cmd_pld_out_02  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_02  ;
    write_ram_cmd_t     east_write_cmd_pld_out_01 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_01 ;
    write_ram_cmd_t     west_write_cmd_pld_out_02 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_02 ;
    write_ram_cmd_t     west_write_cmd_pld_out_03 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_03 ;
    write_ram_cmd_t     east_write_cmd_pld_out_02 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_02 ;
    write_ram_cmd_t     north_write_cmd_pld_out_12[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_12;
    write_ram_cmd_t     north_write_cmd_pld_out_13[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_13;
    write_ram_cmd_t     south_write_cmd_pld_out_03[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_03;

    arb_out_req_t       west_read_cmd_pld_out_11  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_11  ;
    arb_out_req_t       east_read_cmd_pld_out_10  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_10  ;
    write_ram_cmd_t     west_write_cmd_pld_out_11 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_11 ;
    write_ram_cmd_t     east_write_cmd_pld_out_10 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_10 ;
    write_ram_cmd_t     north_write_cmd_pld_out_20[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_20;
    write_ram_cmd_t     south_write_cmd_pld_out_10[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_10;
    arb_out_req_t       west_read_cmd_pld_out_12  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_12  ;
    arb_out_req_t       east_read_cmd_pld_out_11  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_11  ;
    write_ram_cmd_t     west_write_cmd_pld_out_12 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_12 ;
    write_ram_cmd_t     east_write_cmd_pld_out_11 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_11 ;
    write_ram_cmd_t     north_write_cmd_pld_out_21[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_21;
    write_ram_cmd_t     south_write_cmd_pld_out_01[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_01;
    write_ram_cmd_t     south_write_cmd_pld_out_11[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_11;
    write_ram_cmd_t     north_write_cmd_pld_out_11[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_11;
    arb_out_req_t       west_read_cmd_pld_out_13  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_13  ;
    arb_out_req_t       east_read_cmd_pld_out_12  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_12  ;
    write_ram_cmd_t     west_write_cmd_pld_out_13 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_13 ;
    write_ram_cmd_t     east_write_cmd_pld_out_12 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_12 ;
    write_ram_cmd_t     north_write_cmd_pld_out_22[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_22;
    write_ram_cmd_t     south_write_cmd_pld_out_02[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_02;
    write_ram_cmd_t     south_write_cmd_pld_out_12[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_12;
    write_ram_cmd_t     north_write_cmd_pld_out_23[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_23;
    write_ram_cmd_t     south_write_cmd_pld_out_13[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_13;
    arb_out_req_t       west_read_cmd_pld_out_21   [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_21   ;
    arb_out_req_t       east_read_cmd_pld_out_20   [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_20   ;
    write_ram_cmd_t     west_write_cmd_pld_out_21  [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_21  ;
    write_ram_cmd_t     east_write_cmd_pld_out_20  [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_20  ;
    write_ram_cmd_t     north_write_cmd_pld_out_30 [7  :0];
    logic [7  :0]       north_write_cmd_vld_out_30 ;
    write_ram_cmd_t     south_write_cmd_pld_out_20 [7  :0];
    logic [7  :0]       south_write_cmd_vld_out_20 ;
    arb_out_req_t       west_read_cmd_pld_out_22  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_22  ;
    arb_out_req_t       east_read_cmd_pld_out_21 [7  :0] ;
    logic [7  :0]       east_read_cmd_vld_out_21  ;
    write_ram_cmd_t     west_write_cmd_pld_out_22 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_22 ;
    write_ram_cmd_t     east_write_cmd_pld_out_21 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_21 ;
    write_ram_cmd_t     north_write_cmd_pld_out_31[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_31;
    write_ram_cmd_t     south_write_cmd_pld_out_21[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_21;
    arb_out_req_t       west_read_cmd_pld_out_23  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_23  ;
    arb_out_req_t       east_read_cmd_pld_out_22  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_22  ;
    write_ram_cmd_t     west_write_cmd_pld_out_23 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_23 ;
    write_ram_cmd_t     east_write_cmd_pld_out_22 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_22 ;
    write_ram_cmd_t     north_write_cmd_pld_out_32[7  :0];
    logic [7  :0]       north_write_cmd_vld_out_32;
    write_ram_cmd_t     south_write_cmd_pld_out_22[7  :0];
    logic [7  :0]       south_write_cmd_vld_out_22;
    write_ram_cmd_t     north_write_cmd_pld_out_33[7  :0] ;
    logic [7  :0]       north_write_cmd_vld_out_33 ;
    write_ram_cmd_t     south_write_cmd_pld_out_23 [7  :0];
    logic [7  :0]       south_write_cmd_vld_out_23 ;
    arb_out_req_t       west_read_cmd_pld_out_31[7  :0];
    logic [7  :0]       west_read_cmd_vld_out_31       ;
    arb_out_req_t       east_read_cmd_pld_out_30[7  :0];
    logic [7  :0]       east_read_cmd_vld_out_30       ;
    write_ram_cmd_t     west_write_cmd_pld_out_31[7  :0];
    logic [7  :0]       west_write_cmd_vld_out_31      ;
    write_ram_cmd_t     east_write_cmd_pld_out_30[7  :0];
    logic [7  :0]       east_write_cmd_vld_out_30 ;
    arb_out_req_t       west_read_cmd_pld_out_32  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_32  ;
    arb_out_req_t       east_read_cmd_pld_out_31  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_31  ;
    write_ram_cmd_t     west_write_cmd_pld_out_32 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_32 ;
    write_ram_cmd_t     east_write_cmd_pld_out_31 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_31 ;
    arb_out_req_t       west_read_cmd_pld_out_33  [7  :0];
    logic [7  :0]       west_read_cmd_vld_out_33  ;
    arb_out_req_t       east_read_cmd_pld_out_32  [7  :0];
    logic [7  :0]       east_read_cmd_vld_out_32  ;
    write_ram_cmd_t     west_write_cmd_pld_out_33 [7  :0];
    logic [7  :0]       west_write_cmd_vld_out_33 ;
    write_ram_cmd_t     east_write_cmd_pld_out_32 [7  :0];
    logic [7  :0]       east_write_cmd_vld_out_32 ;

    logic [7  :0]           west_data_out_vld_01                 ;
    bankgroup_data_pld_t    west_data_out_01            [7  :0]  ;
    logic [7  :0]           east_data_out_vld_00                 ;
    bankgroup_data_pld_t    east_data_out_00            [7  :0]  ;
    logic [7  :0]           north_data_out_vld_10                ;
    bankgroup_data_pld_t    north_data_out_10           [7  :0]  ;
    logic [7  :0]           south_data_out_vld_00                ;
    bankgroup_data_pld_t    south_data_out_00           [7  :0]  ;
    logic [7  :0]           west_data_out_vld_02        ;
    bankgroup_data_pld_t    west_data_out_02            [7  :0];
    logic [7  :0]           east_data_out_vld_01        ;
    bankgroup_data_pld_t    east_data_out_01            [7  :0];
    logic [7  :0]           north_data_out_vld_11       ;
    bankgroup_data_pld_t    north_data_out_11           [7  :0];
    logic [7  :0]           south_data_out_vld_01       ;
    bankgroup_data_pld_t    south_data_out_01           [7  :0];
    logic [7  :0]           west_data_out_vld_03        ;
    bankgroup_data_pld_t    west_data_out_03            [7  :0];
    logic [7  :0]           east_data_out_vld_02        ;
    bankgroup_data_pld_t    east_data_out_02            [7  :0];
    logic [7  :0]           north_data_out_vld_12       ;
    bankgroup_data_pld_t    north_data_out_12           [7  :0];
    logic [7  :0]           south_data_out_vld_02       ;
    bankgroup_data_pld_t    south_data_out_02           [7  :0];
    logic [7  :0]           north_data_out_vld_13       ;
    bankgroup_data_pld_t    north_data_out_13           [7  :0];
    logic [7  :0]           south_data_out_vld_03       ;
    bankgroup_data_pld_t    south_data_out_03           [7  :0];
    logic [7  :0]           west_data_out_vld_11        ;
    bankgroup_data_pld_t    west_data_out_11            [7  :0];
    logic [7  :0]           north_data_out_vld_20       ;
    bankgroup_data_pld_t    north_data_out_20           [7  :0];
    logic [7  :0]           south_data_out_vld_10       ;
    bankgroup_data_pld_t    south_data_out_10           [7  :0];
    logic [7  :0]           west_data_out_vld_12        ;
    bankgroup_data_pld_t    west_data_out_12            [7  :0];
    logic [7  :0]           east_data_out_vld_10        ;
    bankgroup_data_pld_t    east_data_out_10            [7  :0];
    logic [7  :0]           east_data_out_vld_11        ;
    bankgroup_data_pld_t    east_data_out_11            [7  :0];
    logic [7  :0]           north_data_out_vld_21       ;
    bankgroup_data_pld_t    north_data_out_21           [7  :0] ;
    logic [7  :0]           south_data_out_vld_11       ;
    bankgroup_data_pld_t    south_data_out_11           [7  :0];
    logic [7  :0]           west_data_out_vld_13        ;
    bankgroup_data_pld_t    west_data_out_13            [7  :0];
    logic [7  :0]           east_data_out_vld_12        ;
    bankgroup_data_pld_t    east_data_out_12            [7  :0];
    logic [7  :0]           north_data_out_vld_22       ;
    bankgroup_data_pld_t    north_data_out_22           [7  :0];
    logic [7  :0]           south_data_out_vld_12       ;
    bankgroup_data_pld_t    south_data_out_12           [7  :0];
    logic [7  :0]           north_data_out_vld_23       ; 
    bankgroup_data_pld_t    north_data_out_23           [7  :0]; 
    logic [7  :0]           south_data_out_vld_13       ; 
    bankgroup_data_pld_t    south_data_out_13           [7  :0]; 
    logic [7  :0]           west_data_out_vld_21         ;
    bankgroup_data_pld_t    west_data_out_21            [7  :0] ;
    logic [7  :0]           east_data_out_vld_20         ;
    bankgroup_data_pld_t    east_data_out_20            [7  :0] ;
    logic [7  :0]           north_data_out_vld_30       ;
    bankgroup_data_pld_t    north_data_out_30           [7  :0];
    logic [7  :0]           south_data_out_vld_20       ;
    bankgroup_data_pld_t    south_data_out_20           [7  :0];
    logic [7  :0]           west_data_out_vld_22         ;
    bankgroup_data_pld_t    west_data_out_22            [7  :0] ;
    logic [7  :0]           east_data_out_vld_21         ;
    bankgroup_data_pld_t    east_data_out_21            [7  :0] ;
    logic [7  :0]           north_data_out_vld_31        ;
    bankgroup_data_pld_t    north_data_out_31           [7  :0] ;
    logic [7  :0]           south_data_out_vld_21        ;
    bankgroup_data_pld_t    south_data_out_21           [7  :0] ;
    logic [7  :0]           west_data_out_vld_23         ;
    bankgroup_data_pld_t    west_data_out_23            [7  :0]  ;
    logic [7  :0]           east_data_out_vld_22         ;
    bankgroup_data_pld_t    east_data_out_22            [7  :0] ;
    logic [7  :0]           north_data_out_vld_32        ;
    bankgroup_data_pld_t    north_data_out_32           [7  :0] ;
    logic [7  :0]           south_data_out_vld_22        ;
    bankgroup_data_pld_t    south_data_out_22           [7  :0] ;
    logic [7  :0]           north_data_out_vld_33         ;
    bankgroup_data_pld_t    north_data_out_33           [7  :0]  ;
    logic [7  :0]           south_data_out_vld_23         ;
    bankgroup_data_pld_t    south_data_out_23           [7  :0]  ;
    logic [7  :0]           west_data_out_vld_31         ;
    bankgroup_data_pld_t    west_data_out_31            [7  :0] ;
    logic [7  :0]           east_data_out_vld_30         ;
    bankgroup_data_pld_t    east_data_out_30            [7  :0] ;
    logic [7  :0]           west_data_out_vld_32         ;
    bankgroup_data_pld_t    west_data_out_32            [7  :0] ;
    logic [7  :0]           east_data_out_vld_31         ;
    bankgroup_data_pld_t    east_data_out_31            [7  :0] ;
    logic [7  :0]           west_data_out_vld_33         ;
    bankgroup_data_pld_t    west_data_out_33            [7  :0] ;
    logic [7  :0]           east_data_out_vld_32         ;
    bankgroup_data_pld_t    east_data_out_32            [7  :0] ;


generate
    for(genvar i=0;i<8;i=i+1)begin
        assign west_read_cmd_pld_in_row0[i] = west_read_cmd_pld_in[i];
        assign west_read_cmd_pld_in_row1[i] = west_read_cmd_pld_in[i];
        assign west_read_cmd_pld_in_row2[i] = west_read_cmd_pld_in[i];
        assign west_read_cmd_pld_in_row3[i] = west_read_cmd_pld_in[i];
        assign west_read_cmd_vld_in_row0[i] = west_read_cmd_vld_in[i];
        assign west_read_cmd_vld_in_row1[i] = west_read_cmd_vld_in[i];
        assign west_read_cmd_vld_in_row2[i] = west_read_cmd_vld_in[i];
        assign west_read_cmd_vld_in_row3[i] = west_read_cmd_vld_in[i];
        assign east_read_cmd_pld_in_row0[i] = east_read_cmd_pld_in[i];
        assign east_read_cmd_pld_in_row1[i] = east_read_cmd_pld_in[i];
        assign east_read_cmd_pld_in_row2[i] = east_read_cmd_pld_in[i];
        assign east_read_cmd_pld_in_row3[i] = east_read_cmd_pld_in[i];
        assign east_read_cmd_vld_in_row0[i] = east_read_cmd_vld_in[i];
        assign east_read_cmd_vld_in_row1[i] = east_read_cmd_vld_in[i];
        assign east_read_cmd_vld_in_row2[i] = east_read_cmd_vld_in[i];
        assign east_read_cmd_vld_in_row3[i] = east_read_cmd_vld_in[i];

        assign west_write_cmd_pld_in_row0[i] = west_write_cmd_pld_in[i];
        assign west_write_cmd_pld_in_row1[i] = west_write_cmd_pld_in[i];
        assign west_write_cmd_pld_in_row2[i] = west_write_cmd_pld_in[i];
        assign west_write_cmd_pld_in_row3[i] = west_write_cmd_pld_in[i];
        assign west_write_cmd_vld_in_row0[i] = west_write_cmd_vld_in[i];
        assign west_write_cmd_vld_in_row1[i] = west_write_cmd_vld_in[i];
        assign west_write_cmd_vld_in_row2[i] = west_write_cmd_vld_in[i];
        assign west_write_cmd_vld_in_row3[i] = west_write_cmd_vld_in[i];
        assign east_write_cmd_pld_in_row0[i] = east_write_cmd_pld_in[i];
        assign east_write_cmd_pld_in_row1[i] = east_write_cmd_pld_in[i];
        assign east_write_cmd_pld_in_row2[i] = east_write_cmd_pld_in[i];
        assign east_write_cmd_pld_in_row3[i] = east_write_cmd_pld_in[i];
        assign east_write_cmd_vld_in_row0[i] = east_write_cmd_vld_in[i];
        assign east_write_cmd_vld_in_row1[i] = east_write_cmd_vld_in[i];
        assign east_write_cmd_vld_in_row2[i] = east_write_cmd_vld_in[i];
        assign east_write_cmd_vld_in_row3[i] = east_write_cmd_vld_in[i];

        assign south_write_cmd_pld_in_block0[i] = south_write_cmd_pld_in[i];
        assign south_write_cmd_pld_in_block1[i] = south_write_cmd_pld_in[i];
        assign south_write_cmd_pld_in_block2[i] = south_write_cmd_pld_in[i];
        assign south_write_cmd_pld_in_block3[i] = south_write_cmd_pld_in[i];
        assign south_write_cmd_vld_in_block0[i] = south_write_cmd_vld_in[i];
        assign south_write_cmd_vld_in_block1[i] = south_write_cmd_vld_in[i];
        assign south_write_cmd_vld_in_block2[i] = south_write_cmd_vld_in[i];
        assign south_write_cmd_vld_in_block3[i] = south_write_cmd_vld_in[i];
        assign north_write_cmd_pld_in_block0[i] = north_write_cmd_pld_in[i];
        assign north_write_cmd_pld_in_block1[i] = north_write_cmd_pld_in[i];
        assign north_write_cmd_pld_in_block2[i] = north_write_cmd_pld_in[i];
        assign north_write_cmd_pld_in_block3[i] = north_write_cmd_pld_in[i];
        assign north_write_cmd_vld_in_block0[i] = north_write_cmd_vld_in[i];
        assign north_write_cmd_vld_in_block1[i] = north_write_cmd_vld_in[i];
        assign north_write_cmd_vld_in_block2[i] = north_write_cmd_vld_in[i];
        assign north_write_cmd_vld_in_block3[i] = north_write_cmd_vld_in[i];
    end
endgenerate
generate
    for(genvar i=0;i<8;i=i+1)begin
        assign west_data_in_row0[i].data     = west_data_in[i].data[255:0];
        assign west_data_in_row0[i].cmd_pld  = west_data_in[i].cmd_pld;
        assign west_data_in_row1[i].data     = west_data_in[i].data[511:256];
        assign west_data_in_row1[i].cmd_pld  = west_data_in[i].cmd_pld;
        assign west_data_in_row2[i].data     = west_data_in[i].data[767:512];
        assign west_data_in_row2[i].cmd_pld  = west_data_in[i].cmd_pld;
        assign west_data_in_row3[i].data     = west_data_in[i].data[1023:768];
        assign west_data_in_row3[i].cmd_pld  = west_data_in[i].cmd_pld;
        assign west_data_in_vld_row0[i]      = west_data_in_vld[i];
        assign west_data_in_vld_row1[i]      = west_data_in_vld[i];
        assign west_data_in_vld_row2[i]      = west_data_in_vld[i];
        assign west_data_in_vld_row3[i]      = west_data_in_vld[i];

        assign east_data_in_row0[i].data     = east_data_in[i].data[255:0];
        assign east_data_in_row0[i].cmd_pld  = east_data_in[i].cmd_pld;
        assign east_data_in_row1[i].data     = east_data_in[i].data[511:256];
        assign east_data_in_row1[i].cmd_pld  = east_data_in[i].cmd_pld;
        assign east_data_in_row2[i].data     = east_data_in[i].data[767:512];
        assign east_data_in_row2[i].cmd_pld  = east_data_in[i].cmd_pld;
        assign east_data_in_row3[i].data     = east_data_in[i].data[1023:768];
        assign east_data_in_row3[i].cmd_pld  = east_data_in[i].cmd_pld;
        assign east_data_in_vld_row0[i]      = east_data_in_vld[i];
        assign east_data_in_vld_row1[i]      = east_data_in_vld[i];
        assign east_data_in_vld_row2[i]      = east_data_in_vld[i];
        assign east_data_in_vld_row3[i]      = east_data_in_vld[i];

        assign south_data_in_block0[i].data     = south_data_in[i].data[255:0];
        assign south_data_in_block0[i].cmd_pld  = south_data_in[i].cmd_pld;
        assign south_data_in_block1[i].data     = south_data_in[i].data[511:256];
        assign south_data_in_block1[i].cmd_pld  = south_data_in[i].cmd_pld;
        assign south_data_in_block2[i].data     = south_data_in[i].data[767:512];
        assign south_data_in_block2[i].cmd_pld  = south_data_in[i].cmd_pld;
        assign south_data_in_block3[i].data     = south_data_in[i].data[1023:768];
        assign south_data_in_block3[i].cmd_pld  = south_data_in[i].cmd_pld;
        assign south_data_in_vld_block0[i]      = south_data_in_vld[i];
        assign south_data_in_vld_block1[i]      = south_data_in_vld[i];
        assign south_data_in_vld_block2[i]      = south_data_in_vld[i];
        assign south_data_in_vld_block3[i]      = south_data_in_vld[i];

        assign north_data_in_block0[i].data     = north_data_in[i].data[255:0];
        assign north_data_in_block0[i].cmd_pld  = north_data_in[i].cmd_pld;
        assign north_data_in_block1[i].data     = north_data_in[i].data[511:256];
        assign north_data_in_block1[i].cmd_pld  = north_data_in[i].cmd_pld;
        assign north_data_in_block2[i].data     = north_data_in[i].data[767:512];
        assign north_data_in_block2[i].cmd_pld  = north_data_in[i].cmd_pld;
        assign north_data_in_block3[i].data     = north_data_in[i].data[1023:768];
        assign north_data_in_block3[i].cmd_pld  = north_data_in[i].cmd_pld;
        assign north_data_in_vld_block0[i]      = north_data_in_vld[i];
        assign north_data_in_vld_block1[i]      = north_data_in_vld[i];
        assign north_data_in_vld_block2[i]      = north_data_in_vld[i];
        assign north_data_in_vld_block3[i]      = north_data_in_vld[i];
    end
endgenerate

    //第一行第一列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (0))
    u_sram_bank_group_00 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (west_read_cmd_pld_in_row0      ),//input
        .west_read_cmd_vld_in       (west_read_cmd_vld_in_row0      ),//input
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_row0     ),//output
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_row0     ),//output
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_01       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_01       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_00       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_00       ),
        .west_write_cmd_pld_in      (west_write_cmd_pld_in_row0     ),//input
        .west_write_cmd_vld_in      (west_write_cmd_vld_in_row0     ),//input
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_row0    ),//output west write output
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_row0    ),//output west write output
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_01      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_01      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_00      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_00      ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_10     ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_10     ),
        .north_write_cmd_pld_in     (north_write_cmd_pld_in_block0  ),//input south write cmd input
        .north_write_cmd_vld_in     (north_write_cmd_vld_in_block0  ),//input south write cmd input
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_00     ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_00     ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_block0 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_block0 ),
        .west_data_in_vld           (west_data_in_vld_row0          ),//input west data_in
        .west_data_in               (west_data_in_row0              ),//input west data_in
        .west_data_out_vld          (west_data_out_vld_row0         ),//output west data_out
        .west_data_out              (west_data_out_row0             ),//output west data_out
        .east_data_in_vld           (west_data_out_vld_01           ),
        .east_data_in               (west_data_out_01               ),
        .east_data_out_vld          (east_data_out_vld_00           ),
        .east_data_out              (east_data_out_00               ),
        .south_data_in_vld          (north_data_out_vld_10          ),
        .south_data_in              (north_data_out_10              ),
        .south_data_out_vld         (south_data_out_vld_00          ),//to 第二行第一列north
        .south_data_out             (south_data_out_00              ),//to 第二行第一列north
        .north_data_in_vld          (north_data_in_vld_block0       ),//input north data
        .north_data_in              (north_data_in_block0           ),//input north data
        .north_data_out_vld         (north_data_out_vld_block0      ), //output north data out
        .north_data_out             (north_data_out_block0          ));//output north data out

    //第一行第二列
    sram_bank_group #(
        .BLOCK_ID(1),
        .ROW_ID  (0))
    u_sram_bank_group_01 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_00       ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_00       ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_01       ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_01       ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_02       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_02       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_01       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_01       ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_00      ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_00      ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_01      ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_01      ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_02      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_02      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_01      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_01      ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_11     ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_11     ),
        .north_write_cmd_pld_in     (north_write_cmd_pld_in_block1  ),//input
        .north_write_cmd_vld_in     (north_write_cmd_vld_in_block1  ),//input
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_01     ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_01     ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_block1 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_block1 ),
        .west_data_in_vld           (east_data_out_vld_00           ),
        .west_data_in               (east_data_out_00               ),
        .west_data_out_vld          (west_data_out_vld_01           ),
        .west_data_out              (west_data_out_01               ),
        .east_data_in_vld           (west_data_out_vld_02           ),
        .east_data_in               (west_data_out_02               ),
        .east_data_out_vld          (east_data_out_vld_01           ),
        .east_data_out              (east_data_out_01               ),
        .south_data_in_vld          (north_data_out_vld_11          ),
        .south_data_in              (north_data_out_11              ),
        .south_data_out_vld         (south_data_out_vld_01          ),
        .south_data_out             (south_data_out_01              ),
        .north_data_in_vld          (north_data_in_vld_block1       ),//input
        .north_data_in              (north_data_in_block1           ),//input
        .north_data_out_vld         (north_data_out_vld_block1      ),
        .north_data_out             (north_data_out_block1          ));

    //第一行第三列
    sram_bank_group #(
        .BLOCK_ID(2),
        .ROW_ID  (0))
    u_sram_bank_group_02 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_01       ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_01       ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_02       ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_02       ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_03       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_03       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_02       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_02       ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_01      ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_01      ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_02      ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_02      ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_03      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_03      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_02      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_02      ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_12     ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_12     ),
        .north_write_cmd_pld_in     (north_write_cmd_pld_in_block2  ),//input
        .north_write_cmd_vld_in     (north_write_cmd_vld_in_block2  ),//input
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_02     ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_02     ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_block2 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_block2 ),
        .west_data_in_vld           (east_data_out_vld_01           ),
        .west_data_in               (east_data_out_01               ),
        .west_data_out_vld          (west_data_out_vld_02           ),
        .west_data_out              (west_data_out_02               ),
        .east_data_in_vld           (west_data_out_vld_03           ),
        .east_data_in               (west_data_out_03               ),
        .east_data_out_vld          (east_data_out_vld_02           ),
        .east_data_out              (east_data_out_02               ),
        .south_data_in_vld          (north_data_out_vld_12          ),
        .south_data_in              (north_data_out_12              ),
        .south_data_out_vld         (south_data_out_vld_02          ),
        .south_data_out             (south_data_out_02              ),
        .north_data_in_vld          (north_data_in_vld_block2       ),//input
        .north_data_in              (north_data_in_block2           ),//input
        .north_data_out_vld         (north_data_out_vld_block2      ),
        .north_data_out             (north_data_out_block2          ));

    //第一行第四列
    sram_bank_group #(
        .BLOCK_ID(3),
        .ROW_ID  (0))
    u_sram_bank_group_03 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_02       ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_02       ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_03       ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_03       ),
        .east_read_cmd_pld_in       (east_read_cmd_pld_in_row0      ),//east input
        .east_read_cmd_vld_in       (east_read_cmd_vld_in_row0      ),//east input
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_row0     ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_row0     ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_02      ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_02      ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_03      ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_03      ),
        .east_write_cmd_pld_in      (east_write_cmd_pld_in_row0     ),//east write input
        .east_write_cmd_vld_in      (east_write_cmd_vld_in_row0     ),//east write input
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_row0    ),//output
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_row0    ),//output
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_13     ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_13     ),
        .north_write_cmd_pld_in     (north_write_cmd_pld_in_block3  ),//input
        .north_write_cmd_vld_in     (north_write_cmd_vld_in_block3  ),//input
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_03     ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_03     ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_block3 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_block3 ),
        .west_data_in_vld           (east_data_out_vld_02           ),
        .west_data_in               (east_data_out_02               ),
        .west_data_out_vld          (west_data_out_vld_03           ),
        .west_data_out              (west_data_out_03               ),
        .east_data_in_vld           (east_data_in_vld_row0          ),//input east data_in
        .east_data_in               (east_data_in_row0              ),//input east data_in
        .east_data_out_vld          (east_data_out_vld_row0         ),//output east data_out
        .east_data_out              (east_data_out_row0             ),//output east data_out
        .south_data_in_vld          (north_data_out_vld_13          ),
        .south_data_in              (north_data_out_13              ),
        .south_data_out_vld         (south_data_out_vld_03          ),
        .south_data_out             (south_data_out_03              ),
        .north_data_in_vld          (north_data_in_vld_block3       ),//input
        .north_data_in              (north_data_in_block3           ),//input
        .north_data_out_vld         (north_data_out_vld_block3      ),
        .north_data_out             (north_data_out_block3          ));
  

    //第二行第一列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_10 ( 
        .clk                        (clk    ),
        .clk_div                    (clk_div),
        .rst_n                      (rst_n  ),
        .west_read_cmd_pld_in       (west_read_cmd_pld_in_row1      ),//input
        .west_read_cmd_vld_in       (west_read_cmd_vld_in_row1      ),//input
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_row1     ),//output
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_row1     ),//output
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_11       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_11       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_10       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_10       ),
        .west_write_cmd_pld_in      (west_write_cmd_pld_in_row1     ),//input
        .west_write_cmd_vld_in      (west_write_cmd_vld_in_row1     ),//input
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_row1    ),//output west write output
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_row1    ),//output west write output
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_11      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_11      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_10      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_10      ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_20     ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_20     ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_00     ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_00     ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_10     ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_10     ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_10     ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_10     ),
        .west_data_in_vld           (west_data_in_vld_row1          ),//input west data_in
        .west_data_in               (west_data_in_row1              ),//input west data_in
        .west_data_out_vld          (west_data_out_vld_row1         ),//output west data_out
        .west_data_out              (west_data_out_row1             ),//output west data_out
        .east_data_in_vld           (west_data_out_vld_11           ),
        .east_data_in               (west_data_out_11               ),
        .east_data_out_vld          (east_data_out_vld_10           ),
        .east_data_out              (east_data_out_10               ),
        .south_data_in_vld          (north_data_out_vld_20          ),
        .south_data_in              (north_data_out_20              ),
        .south_data_out_vld         (south_data_out_vld_10          ),
        .south_data_out             (south_data_out_10              ),
        .north_data_in_vld          (south_data_out_vld_00          ),
        .north_data_in              (south_data_out_00              ),
        .north_data_out_vld         (north_data_out_vld_10          ),
        .north_data_out             (north_data_out_10              ));


    //第二行第二列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_11 ( 
        .clk                        (clk    ),
        .clk_div                    (clk_div),
        .rst_n                      (rst_n  ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_10   ),//input
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_10   ),//input
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_11   ),//output
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_11   ),//output
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_12   ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_12   ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_11   ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_11   ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_10  ),//input
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_10  ),//input
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_11  ),//output west write output
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_11  ),//output west write output
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_12  ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_12  ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_11  ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_11  ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_21 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_21 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_01 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_01 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_11 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_11 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_11 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_11 ),
        .west_data_in_vld           (east_data_out_vld_10       ),//input west data_in
        .west_data_in               (east_data_out_10           ),//input west data_in
        .west_data_out_vld          (west_data_out_vld_11       ),//output west data_out
        .west_data_out              (west_data_out_11           ),//output west data_out
        .east_data_in_vld           (west_data_out_vld_12       ),
        .east_data_in               (west_data_out_12           ),
        .east_data_out_vld          (east_data_out_vld_11       ),
        .east_data_out              (east_data_out_11           ),
        .south_data_in_vld          (north_data_out_vld_21      ),
        .south_data_in              (north_data_out_21          ),
        .south_data_out_vld         (south_data_out_vld_11      ),
        .south_data_out             (south_data_out_11          ),
        .north_data_in_vld          (south_data_out_vld_01      ),
        .north_data_in              (south_data_out_01          ),
        .north_data_out_vld         (north_data_out_vld_11      ),
        .north_data_out             (north_data_out_11          ));


    //第二行第三列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_12 ( 
        .clk                        (clk                        ),
        .clk_div                    (clk_div                    ),
        .rst_n                      (rst_n                      ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_11   ),//input
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_11   ),//input
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_12   ),//output
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_12   ),//output
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_13   ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_13   ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_12   ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_12   ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_11  ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_11  ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_12  ),//output west write output
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_12  ),//output west write output
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_13  ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_13  ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_12  ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_12  ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_22 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_22 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_02 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_02 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_12 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_12 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_12 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_12 ),
        .west_data_in_vld           (east_data_out_vld_11       ),//input west data_in
        .west_data_in               (east_data_out_11           ),//input west data_in
        .west_data_out_vld          (west_data_out_vld_12       ),//output west data_out
        .west_data_out              (west_data_out_12           ),//output west data_out
        .east_data_in_vld           (west_data_out_vld_13       ),
        .east_data_in               (west_data_out_13           ),
        .east_data_out_vld          (east_data_out_vld_12       ),
        .east_data_out              (east_data_out_12           ),
        .south_data_in_vld          (north_data_out_vld_22      ),
        .south_data_in              (north_data_out_22          ),
        .south_data_out_vld         (south_data_out_vld_12      ),
        .south_data_out             (south_data_out_12          ),
        .north_data_in_vld          (south_data_out_vld_02      ),
        .north_data_in              (south_data_out_02          ),
        .north_data_out_vld         (north_data_out_vld_12      ),
        .north_data_out             (north_data_out_12          ));

    //第二行第四列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_13 ( 
        .clk                        (clk                        ),
        .clk_div                    (clk_div                    ),
        .rst_n                      (rst_n                      ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_12   ),//input
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_12   ),//input
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_13   ),//output
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_13   ),//output
        .east_read_cmd_pld_in       (east_read_cmd_pld_in_row1  ),
        .east_read_cmd_vld_in       (east_read_cmd_vld_in_row1  ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_row1 ),//output
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_row1 ),//output
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_12  ),//input
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_12  ),//input
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_13  ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_13  ),
        .east_write_cmd_pld_in      (east_write_cmd_pld_in_row1 ),
        .east_write_cmd_vld_in      (east_write_cmd_vld_in_row1 ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_row1),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_row1),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_23 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_23 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_03 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_03 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_13 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_13 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_13 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_13 ),
        .west_data_in_vld           (east_data_out_vld_12       ),
        .west_data_in               (east_data_out_12           ),
        .west_data_out_vld          (west_data_out_vld_13       ),//output west data_out
        .west_data_out              (west_data_out_13           ),//output west data_out
        .east_data_in_vld           (east_data_in_vld_row1      ),//input 
        .east_data_in               (east_data_in_row1          ),//input 
        .east_data_out_vld          (east_data_out_vld_row1     ),
        .east_data_out              (east_data_out_row1         ),
        .south_data_in_vld          (north_data_out_vld_23      ),
        .south_data_in              (north_data_out_23          ),
        .south_data_out_vld         (south_data_out_vld_13      ),
        .south_data_out             (south_data_out_13          ),
        .north_data_in_vld          (south_data_out_vld_03      ),
        .north_data_in              (south_data_out_03          ),
        .north_data_out_vld         (north_data_out_vld_13      ),
        .north_data_out             (north_data_out_13          ));
    




    //第三行第一列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_20 ( 
        .clk                        (clk                        ),
        .clk_div                    (clk_div                    ),
        .rst_n                      (rst_n                      ),
        .west_read_cmd_pld_in       (west_read_cmd_pld_in_row2  ),
        .west_read_cmd_vld_in       (west_read_cmd_vld_in_row2  ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_row2 ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_row2 ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_21   ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_21   ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_20   ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_20   ),
        .west_write_cmd_pld_in      (west_write_cmd_pld_in_row2 ),
        .west_write_cmd_vld_in      (west_write_cmd_vld_in_row2 ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_row2),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_row2),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_21  ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_21  ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_20  ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_20  ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_30 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_30 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_10 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_10 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_20 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_20 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_20 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_20 ),
        .west_data_in_vld           (west_data_in_vld_row2      ),
        .west_data_in               (west_data_in_row2          ),
        .west_data_out_vld          (west_data_out_vld_row2     ),
        .west_data_out              (west_data_out_row2         ),
        .east_data_in_vld           (west_data_out_vld_21       ),
        .east_data_in               (west_data_out_21           ),
        .east_data_out_vld          (east_data_out_vld_20       ),
        .east_data_out              (east_data_out_20           ),
        .south_data_in_vld          (north_data_out_vld_30      ),
        .south_data_in              (north_data_out_30          ),
        .south_data_out_vld         (south_data_out_vld_20      ),
        .south_data_out             (south_data_out_20          ),
        .north_data_in_vld          (south_data_out_vld_10      ),
        .north_data_in              (south_data_out_10          ),
        .north_data_out_vld         (north_data_out_vld_20      ),
        .north_data_out             (north_data_out_20          ));

    //第三行第二列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_21 ( 
        .clk                        (clk                        ),
        .clk_div                    (clk_div                    ),
        .rst_n                      (rst_n                      ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_20   ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_20   ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_21   ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_21   ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_22   ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_22   ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_21   ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_21   ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_20  ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_20  ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_21  ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_21  ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_22  ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_22  ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_21  ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_21  ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_31 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_31 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_11 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_11 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_21 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_21 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_21 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_21 ),
        .west_data_in_vld           (east_data_out_vld_20       ),
        .west_data_in               (east_data_out_20           ),
        .west_data_out_vld          (west_data_out_vld_21       ),
        .west_data_out              (west_data_out_21           ),
        .east_data_in_vld           (west_data_out_vld_22       ),
        .east_data_in               (west_data_out_22           ),
        .east_data_out_vld          (east_data_out_vld_21       ),
        .east_data_out              (east_data_out_21           ),
        .south_data_in_vld          (north_data_out_vld_31      ),
        .south_data_in              (north_data_out_31          ),
        .south_data_out_vld         (south_data_out_vld_21      ),
        .south_data_out             (south_data_out_21          ),
        .north_data_in_vld          (south_data_out_vld_11      ),
        .north_data_in              (south_data_out_11          ),
        .north_data_out_vld         (north_data_out_vld_21      ),
        .north_data_out             (north_data_out_21          ));

    //第三行第三列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_22 ( 
        .clk                        (clk                        ),
        .clk_div                    (clk_div                    ),
        .rst_n                      (rst_n                      ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_21   ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_21   ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_22   ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_22   ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_23   ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_23   ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_22   ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_22   ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_21  ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_21  ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_22  ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_22  ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_23  ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_23  ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_22  ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_22  ),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_32 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_32 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_12 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_12 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_22 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_22 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_22 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_22 ),
        .west_data_in_vld           (east_data_out_vld_21       ),
        .west_data_in               (east_data_out_21           ),
        .west_data_out_vld          (west_data_out_vld_22       ),
        .west_data_out              (west_data_out_22           ),
        .east_data_in_vld           (west_data_out_vld_23       ),
        .east_data_in               (west_data_out_23           ),
        .east_data_out_vld          (east_data_out_vld_22       ),
        .east_data_out              (east_data_out_22           ),
        .south_data_in_vld          (north_data_out_vld_32      ),
        .south_data_in              (north_data_out_32          ),
        .south_data_out_vld         (south_data_out_vld_22      ),
        .south_data_out             (south_data_out_22          ),
        .north_data_in_vld          (south_data_out_vld_12      ),
        .north_data_in              (south_data_out_12          ),
        .north_data_out_vld         (north_data_out_vld_22      ),
        .north_data_out             (north_data_out_22          ));
    
    //第三行第四列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_23 ( 
        .clk                        (clk                        ),
        .clk_div                    (clk_div                    ),
        .rst_n                      (rst_n                      ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_22   ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_22   ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_23   ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_23   ),
        .east_read_cmd_pld_in       (east_read_cmd_pld_in_row2  ),
        .east_read_cmd_vld_in       (east_read_cmd_vld_in_row2  ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_row2 ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_row2 ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_22  ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_22  ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_23  ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_23  ),
        .east_write_cmd_pld_in      (east_write_cmd_pld_in_row2 ),
        .east_write_cmd_vld_in      (east_write_cmd_vld_in_row2 ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_row2),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_row2),
        .south_write_cmd_pld_in     (north_write_cmd_pld_out_33 ),
        .south_write_cmd_vld_in     (north_write_cmd_vld_out_33 ),
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_13 ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_13 ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_23 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_23 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_23 ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_23 ),
        .west_data_in_vld           (east_data_out_vld_22       ),
        .west_data_in               (east_data_out_22           ),
        .west_data_out_vld          (west_data_out_vld_23       ),
        .west_data_out              (west_data_out_23           ),
        .east_data_in_vld           (east_data_in_vld_row2      ),
        .east_data_in               (east_data_in_row2          ),
        .east_data_out_vld          (east_data_out_vld_row2     ),
        .east_data_out              (east_data_out_row2         ),
        .south_data_in_vld          (north_data_out_vld_33      ),
        .south_data_in              (north_data_out_33          ),
        .south_data_out_vld         (south_data_out_vld_23      ),
        .south_data_out             (south_data_out_23          ),
        .north_data_in_vld          (south_data_out_vld_13      ),
        .north_data_in              (south_data_out_13          ),
        .north_data_out_vld         (north_data_out_vld_23      ),
        .north_data_out             (north_data_out_23          ));

    //第四行第一列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_30 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (west_read_cmd_pld_in_row3      ),
        .west_read_cmd_vld_in       (west_read_cmd_vld_in_row3      ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_row3     ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_row3     ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_31       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_31       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_30       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_30       ),
        .west_write_cmd_pld_in      (west_write_cmd_pld_in_row3     ),
        .west_write_cmd_vld_in      (west_write_cmd_vld_in_row3     ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_row3    ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_row3    ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_31      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_31      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_30      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_30      ),
        .south_write_cmd_pld_in     (south_write_cmd_pld_in_block0  ),//input south write
        .south_write_cmd_vld_in     (south_write_cmd_vld_in_block0  ),//input south write
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_20     ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_20     ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_block0 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_block0 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_30     ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_30     ),
        .west_data_in_vld           (west_data_in_vld_row3          ),
        .west_data_in               (west_data_in_row3              ),
        .west_data_out_vld          (west_data_out_vld_row3         ),
        .west_data_out              (west_data_out_row3             ),
        .east_data_in_vld           (west_data_out_vld_31           ),
        .east_data_in               (west_data_out_31               ),
        .east_data_out_vld          (east_data_out_vld_30           ),
        .east_data_out              (east_data_out_30               ),
        .south_data_in_vld          (south_data_in_vld_block0       ),//input south data
        .south_data_in              (south_data_in_block0           ),//input south data
        .south_data_out_vld         (south_data_out_vld_block0      ),//output south data out
        .south_data_out             (south_data_out_block0          ),//output south data out
        .north_data_in_vld          (south_data_out_vld_20          ),
        .north_data_in              (south_data_out_20              ),
        .north_data_out_vld         (north_data_out_vld_30          ),
        .north_data_out             (north_data_out_30              ));


    //第四行第二列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_31 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_30       ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_30       ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_31       ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_31       ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_32       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_32       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_31       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_31       ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_30      ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_30      ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_31      ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_31      ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_32      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_32      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_31      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_31      ),
        .south_write_cmd_pld_in     (south_write_cmd_pld_in_block1  ),//input south write
        .south_write_cmd_vld_in     (south_write_cmd_vld_in_block1  ),//input south write
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_21     ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_21     ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_block1 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_block1 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_31     ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_31     ),
        .west_data_in_vld           (east_data_out_vld_30           ),
        .west_data_in               (east_data_out_30               ),
        .west_data_out_vld          (west_data_out_vld_31           ),
        .west_data_out              (west_data_out_31               ),
        .east_data_in_vld           (west_data_out_vld_32           ),
        .east_data_in               (west_data_out_32               ),
        .east_data_out_vld          (east_data_out_vld_31           ),
        .east_data_out              (east_data_out_31               ),
        .south_data_in_vld          (south_data_in_vld_block1       ),//input south data
        .south_data_in              (south_data_in_block1           ),//input south data
        .south_data_out_vld         (south_data_out_vld_block1      ),//output south data out
        .south_data_out             (south_data_out_block1          ),//output south data out
        .north_data_in_vld          (south_data_out_vld_21          ),
        .north_data_in              (south_data_out_21              ),
        .north_data_out_vld         (north_data_out_vld_31          ),
        .north_data_out             (north_data_out_31              ));



    //第四行第三列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_32 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_31       ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_31       ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_32       ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_32       ),
        .east_read_cmd_pld_in       (west_read_cmd_pld_out_33       ),
        .east_read_cmd_vld_in       (west_read_cmd_vld_out_33       ),
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_32       ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_32       ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_31      ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_31      ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_32      ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_32      ),
        .east_write_cmd_pld_in      (west_write_cmd_pld_out_33      ),
        .east_write_cmd_vld_in      (west_write_cmd_vld_out_33      ),
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_32      ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_32      ),
        .south_write_cmd_pld_in     (south_write_cmd_pld_in_block2  ),//input south write
        .south_write_cmd_vld_in     (south_write_cmd_vld_in_block2  ),//input south write
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_22     ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_22     ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_block2 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_block2 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_32     ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_32     ),
        .west_data_in_vld           (east_data_out_vld_31           ),
        .west_data_in               (east_data_out_31               ),
        .west_data_out_vld          (west_data_out_vld_32           ),
        .west_data_out              (west_data_out_32               ),
        .east_data_in_vld           (west_data_out_vld_33           ),
        .east_data_in               (west_data_out_33               ),
        .east_data_out_vld          (east_data_out_vld_32           ),
        .east_data_out              (east_data_out_32               ),
        .south_data_in_vld          (south_data_in_vld_block2       ),//input south data
        .south_data_in              (south_data_in_block2           ),//input south data
        .south_data_out_vld         (south_data_out_vld_block2      ),//output south data out
        .south_data_out             (south_data_out_block2          ),//output south data out
        .north_data_in_vld          (south_data_out_vld_22          ),
        .north_data_in              (south_data_out_22              ),
        .north_data_out_vld         (north_data_out_vld_32          ),
        .north_data_out             (north_data_out_32              ));

    //第四行第四列
    sram_bank_group #(
        .BLOCK_ID(0),
        .ROW_ID  (1))
    u_sram_bank_group_33 ( 
        .clk                        (clk                            ),
        .clk_div                    (clk_div                        ),
        .rst_n                      (rst_n                          ),
        .west_read_cmd_pld_in       (east_read_cmd_pld_out_32       ),
        .west_read_cmd_vld_in       (east_read_cmd_vld_out_32       ),
        .west_read_cmd_pld_out      (west_read_cmd_pld_out_33       ),
        .west_read_cmd_vld_out      (west_read_cmd_vld_out_33       ),
        .east_read_cmd_pld_in       (east_read_cmd_pld_in_row3      ),//input
        .east_read_cmd_vld_in       (east_read_cmd_vld_in_row3      ),//input
        .east_read_cmd_pld_out      (east_read_cmd_pld_out_row3     ),
        .east_read_cmd_vld_out      (east_read_cmd_vld_out_row3     ),
        .west_write_cmd_pld_in      (east_write_cmd_pld_out_32      ),
        .west_write_cmd_vld_in      (east_write_cmd_vld_out_32      ),
        .west_write_cmd_pld_out     (west_write_cmd_pld_out_33      ),
        .west_write_cmd_vld_out     (west_write_cmd_vld_out_33      ),
        .east_write_cmd_pld_in      (east_write_cmd_pld_in_row3     ),//input
        .east_write_cmd_vld_in      (east_write_cmd_vld_in_row3     ),//input
        .east_write_cmd_pld_out     (east_write_cmd_pld_out_row3    ),
        .east_write_cmd_vld_out     (east_write_cmd_vld_out_row3    ),
        .south_write_cmd_pld_in     (south_write_cmd_pld_in_block3  ),//input south write
        .south_write_cmd_vld_in     (south_write_cmd_vld_in_block3  ),//input south write
        .north_write_cmd_pld_in     (south_write_cmd_pld_out_23     ),
        .north_write_cmd_vld_in     (south_write_cmd_vld_out_23     ),
        .south_write_cmd_pld_out    (south_write_cmd_pld_out_block3 ),
        .south_write_cmd_vld_out    (south_write_cmd_vld_out_block3 ),
        .north_write_cmd_pld_out    (north_write_cmd_pld_out_33     ),
        .north_write_cmd_vld_out    (north_write_cmd_vld_out_33     ),
        .west_data_in_vld           (east_data_out_vld_32           ),
        .west_data_in               (east_data_out_32               ),
        .west_data_out_vld          (west_data_out_vld_33           ),
        .west_data_out              (west_data_out_33               ),
        .east_data_in_vld           (east_data_in_vld_row3          ),//input east data
        .east_data_in               (east_data_in_row3              ),//input east data
        .east_data_out_vld          (east_data_out_vld_row3         ),
        .east_data_out              (east_data_out_row3             ),
        .south_data_in_vld          (south_data_in_vld_block3       ),//input south data
        .south_data_in              (south_data_in_block3           ),//input south data
        .south_data_out_vld         (south_data_out_vld_block3      ),//output south data out
        .south_data_out             (south_data_out_block3          ),//output south data out
        .north_data_in_vld          (south_data_out_vld_23          ),
        .north_data_in              (south_data_out_23              ),
        .north_data_out_vld         (north_data_out_vld_33          ),
        .north_data_out             (north_data_out_33              ));


generate
    for(genvar i=0;i<8;i=i+1)begin
        assign west_data_out[i].data[255:0]   = west_data_out_row0[i].data;
        assign west_data_out[i].data[511:256] = west_data_out_row1[i].data;
        assign west_data_out[i].data[767:512] = west_data_out_row2[i].data;
        assign west_data_out[i].data[1023:768]= west_data_out_row3[i].data;
        assign west_data_out[i].cmd_pld       = west_data_out_row0[i].cmd_pld;
        assign west_data_out_vld[i]           = west_data_out_vld_row3[i] && west_data_out_vld_row2[i] && west_data_out_vld_row1[i] && west_data_out_vld_row0[i];

        assign east_data_out[i].data[255:0]   = east_data_out_row0[i].data;
        assign east_data_out[i].data[511:256] = east_data_out_row1[i].data;
        assign east_data_out[i].data[767:512] = east_data_out_row2[i].data;
        assign east_data_out[i].data[1023:768]= east_data_out_row3[i].data;
        assign east_data_out[i].cmd_pld       = east_data_out_row0[i].cmd_pld;
        assign east_data_out_vld[i]           = east_data_out_vld_row3[i] && east_data_out_vld_row2[i] && east_data_out_vld_row1[i] && east_data_out_vld_row0[i];

        assign south_data_out[i].data[255:0]   = south_data_out_block0[i].data;
        assign south_data_out[i].data[511:256] = south_data_out_block1[i].data;
        assign south_data_out[i].data[767:512] = south_data_out_block2[i].data;
        assign south_data_out[i].data[1023:768]= south_data_out_block3[i].data;
        assign south_data_out[i].cmd_pld       = south_data_out_block0[i].cmd_pld;
        assign south_data_out_vld[i]           = south_data_out_vld_block3[i] && south_data_out_vld_block2[i] && south_data_out_vld_block1[i] && south_data_out_vld_block0[i];

        assign north_data_out[i].data[255:0]   = north_data_out_block0[i].data;
        assign north_data_out[i].data[511:256] = north_data_out_block1[i].data;
        assign north_data_out[i].data[767:512] = north_data_out_block2[i].data;
        assign north_data_out[i].data[1023:768]= north_data_out_block3[i].data;
        assign north_data_out[i].cmd_pld       = north_data_out_block0[i].cmd_pld;
        assign north_data_out_vld[i]           = north_data_out_vld_block3[i] && north_data_out_vld_block2[i] && north_data_out_vld_block1[i] && north_data_out_vld_block0[i];
    end
endgenerate

generate
    for(genvar i=0;i<8;i=i+1)begin
        //assign west_read_cmd_pld_out  [i] = west_read_cmd_pld_out_row0[i];
        //assign west_read_cmd_vld_out  [i] = west_read_cmd_vld_out_row0[i];
        assign east_read_cmd_pld_out  [i] = east_read_cmd_pld_out_row0[i];
        assign east_read_cmd_vld_out  [i] = east_read_cmd_vld_out_row0[i];
        //assign west_write_cmd_pld_out [i] = west_write_cmd_pld_out_row0[i];
        //assign west_write_cmd_vld_out [i] = west_write_cmd_vld_out_row0[i];
        //assign east_write_cmd_pld_out [i] = east_write_cmd_pld_out_row0[i];
        //assign east_write_cmd_vld_out [i] = east_write_cmd_vld_out_row0[i];
        //assign south_write_cmd_pld_out[i] = south_write_cmd_pld_out_block0[i];
        //assign south_write_cmd_vld_out[i] = south_write_cmd_vld_out_block0[i];
        //assign north_write_cmd_pld_out[i] = north_write_cmd_pld_out_block0[i];
        //assign north_write_cmd_vld_out[i] = north_write_cmd_vld_out_block0[i];
    end
endgenerate

endmodule