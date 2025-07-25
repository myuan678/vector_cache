module sram_bank 
    import vector_cache_pkg::*;
    #(  parameter integer unsigned BLOCK_ID = 0 ,//ID是block的id
        parameter integer unsigned ROW_ID   = 0
    )(
    input  logic                clk                             ,
    input  logic                clk_div                         ,
    input  logic                rst_n                           ,

    input  arb_out_req_t        west_read_cmd_pld_in         [7:0]   ,
    input  logic [7:0]          west_read_cmd_vld_in                 ,
    output arb_out_req_t        west_read_cmd_pld_out        [7:0]   ,
    output logic [7:0]          west_read_cmd_vld_out                ,
    input  arb_out_req_t        east_read_cmd_pld_in         [7:0]   ,
    input  logic [7:0]          east_read_cmd_vld_in                 ,
    output arb_out_req_t        east_read_cmd_pld_out        [7:0]   ,
    output logic [7:0]          east_read_cmd_vld_out                ,

    input  write_ram_cmd_t      west_write_cmd_pld_in        [7:0]   ,
    input  logic [7:0]          west_write_cmd_vld_in                ,
    output write_ram_cmd_t      west_write_cmd_pld_out       [7:0]   ,
    output logic [7:0]          west_write_cmd_vld_out               ,
    input  write_ram_cmd_t      east_write_cmd_pld_in        [7:0]   ,
    input  logic [7:0]          east_write_cmd_vld_in                ,
    output write_ram_cmd_t      east_write_cmd_pld_out       [7:0]   ,
    output logic [7:0]          east_write_cmd_vld_out               ,

    input  write_ram_cmd_t      south_write_cmd_pld_in       [7:0]   ,
    input  logic [7:0]          south_write_cmd_vld_in               ,
    input  write_ram_cmd_t      north_write_cmd_pld_in       [7:0]   ,
    input  logic [7:0]          north_write_cmd_vld_in               ,
    output write_ram_cmd_t      south_write_cmd_pld_out      [7:0]   ,
    output logic [7:0]          south_write_cmd_vld_out              ,
    output write_ram_cmd_t      north_write_cmd_pld_out      [7:0]   ,
    output logic [7:0]          north_write_cmd_vld_out              ,

    input  logic [7         :0] west_data_in_vld                     ,
    input  data_pld_t           west_data_in                 [7  :0] ,
    output logic [7         :0] west_data_out_vld                    ,
    output data_pld_t           west_data_out                [7  :0] ,
    
    input  logic [7         :0] east_data_in_vld                     ,
    input  data_pld_t           east_data_in                 [7  :0] ,
    output logic [7         :0] east_data_out_vld                    ,
    output data_pld_t           east_data_out                [7  :0] ,

    input  logic [7         :0] south_data_in_vld                    ,
    input  data_pld_t           south_data_in                [7  :0] ,
    output logic [7         :0] south_data_out_vld                   ,
    output data_pld_t           south_data_out               [7  :0] ,

    input  logic [7         :0] north_data_in_vld                    ,
    input  data_pld_t           north_data_in                [7  :0] ,
    output logic [7         :0] north_data_out_vld                   ,
    output data_pld_t           north_data_out               [7  :0] 
   
);
    //parameter integer unsigned BLOCK_ID = 0 ;
    logic [1:0] group_id_col[7:0];
    logic [1:0] group_id_row[7:0];
    generate
        for(genvar i=0;i<8;i=i+1)begin:gen_block_id//group_id_col,访问第几列的block
            assign group_id_col[i] = west_read_cmd_pld_in[i].dest_ram_id[2:1];
        end
    endgenerate
    
    
    logic [7    :0] switch_west_read_cmd_out_vld            ;
    arb_out_req_t   switch_west_read_cmd_out_pld    [7:0]   ;
    logic [7    :0] mem_east_read_cmd_out_vld               ;
    arb_out_req_t   mem_east_read_cmd_out_pld       [7:0]   ;
    logic [7    :0] switch_west_write_cmd_out_vld           ;
    write_ram_cmd_t switch_west_write_cmd_out_pld   [7:0]   ;
    logic [7    :0] mem_east_write_cmd_out_vld              ;
    write_ram_cmd_t mem_east_write_cmd_out_pld      [7:0]   ;
    logic [7    :0] switch_west_data_out_vld                ;
    data_pld_t      switch_west_data_out            [7:0]   ;   
    logic [7    :0] mem_east_data_out_vld                   ; 
    data_pld_t      mem_east_data_out               [7:0]   ;     


    mem_block #( 
        .BLOCK_ID (BLOCK_ID)
        //.ROW_ID (ROW_ID)
    ) u_mem_block ( 
        .clk                    (clk                          ),
        .clk_div                (clk_div                      ),
        .rst_n                  (rst_n                        ),
        .west_read_cmd_vld_in   (west_read_cmd_vld_in         ),
        .west_read_cmd_pld_in   (west_read_cmd_pld_in         ),
        .west_read_cmd_vld_out  (west_read_cmd_vld_out        ),
        .west_read_cmd_pld_out  (west_read_cmd_pld_out        ),
        .east_read_cmd_vld_in   (switch_west_read_cmd_out_vld ),
        .east_read_cmd_pld_in   (switch_west_read_cmd_out_pld ),
        .east_read_cmd_vld_out  (mem_east_read_cmd_out_vld    ),
        .east_read_cmd_pld_out  (mem_east_read_cmd_out_pld    ),
        .west_write_cmd_vld_in  (west_write_cmd_vld_in        ),
        .west_write_cmd_pld_in  (west_write_cmd_pld_in        ),
        .west_write_cmd_vld_out (west_write_cmd_vld_out       ),
        .west_write_cmd_pld_out (west_write_cmd_pld_out       ),
        .east_write_cmd_vld_in  (switch_west_write_cmd_out_vld),
        .east_write_cmd_pld_in  (switch_west_write_cmd_out_pld),
        .east_write_cmd_vld_out (mem_east_write_cmd_out_vld   ),
        .east_write_cmd_pld_out (mem_east_write_cmd_out_pld   ),

        .west_data_in_vld       (west_data_in_vld             ),
        .west_data_in           (west_data_in                 ),
        .west_data_out_vld      (west_data_out_vld            ),
        .west_data_out          (west_data_out                ),
        .east_data_in_vld       (switch_west_data_out_vld     ),
        .east_data_in           (switch_west_data_out         ),
        .east_data_out_vld      (mem_east_data_out_vld        ),//mem_out
        .east_data_out          (mem_east_data_out            ));//mem_out


        xy_switch #( 
            .BLOCK_ID(BLOCK_ID),
            .ROW_ID(ROW_ID)
        )u_xy_switch( 
            .clk                      (clk                          ),
            .rst_n                    (rst_n                        ),
            .group_id_col             (group_id_col                 ),
            .group_id_row             (group_id_row                 ),
            .west_read_cmd_in_vld     (mem_east_read_cmd_out_vld    ),
            .west_read_cmd_in_pld     (mem_east_read_cmd_out_pld    ),
            .east_read_cmd_out_vld    (east_read_cmd_vld_out        ),
            .east_read_cmd_out_pld    (east_read_cmd_pld_out        ),
            .west_read_cmd_out_vld    (switch_west_read_cmd_out_vld ),
            .west_read_cmd_out_pld    (switch_west_read_cmd_out_pld ),
            .east_read_cmd_in_vld     (east_read_cmd_vld_in         ),
            .east_read_cmd_in_pld     (east_read_cmd_pld_in         ),
            .west_write_cmd_in_vld    (mem_east_write_cmd_out_vld   ),//mem_east_out
            .west_write_cmd_in_pld    (mem_east_write_cmd_out_pld   ),//mem_east_out
            .east_write_cmd_in_vld    (east_write_cmd_vld_in        ),
            .east_write_cmd_in_pld    (east_write_cmd_pld_in        ),
            .south_write_cmd_in_vld   (south_write_cmd_vld_in       ),
            .south_write_cmd_in_pld   (south_write_cmd_pld_in       ),
            .north_write_cmd_in_vld   (north_write_cmd_vld_in       ),
            .north_write_cmd_in_pld   (north_write_cmd_pld_in       ),
            .west_write_cmd_out_vld   (switch_west_write_cmd_out_vld),//mem_east_in
            .west_write_cmd_out_pld   (switch_west_write_cmd_out_pld),//mem_east_in
            .east_write_cmd_out_vld   (east_write_cmd_vld_out       ),
            .east_write_cmd_out_pld   (east_write_cmd_pld_out       ),
            .west_data_in_vld         (mem_east_data_out_vld        ),
            .west_data_in             (mem_east_data_out            ),
            .west_data_out_vld        (switch_west_data_out_vld     ),
            .west_data_out            (switch_west_data_out         ),
            .east_data_in_vld         (east_data_in_vld             ),
            .east_data_in             (east_data_in                 ),
            .east_data_out_vld        (east_data_out_vld            ),
            .east_data_out            (east_data_out                ),
            .south_data_in_vld        (south_data_in_vld            ),
            .south_data_in            (south_data_in                ),
            .south_data_out_vld       (south_data_out_vld           ),
            .south_data_out           (south_data_out               ),
            .north_data_in_vld        (north_data_in_vld            ),
            .north_data_in            (north_data_in                ),
            .north_data_out_vld       (north_data_out_vld           ),
            .north_data_out           (north_data_out               ),
            .south_write_cmd_out_vld  (south_write_cmd_vld_out      ),
            .south_write_cmd_out_pld  (south_write_cmd_pld_out      ),
            .north_write_cmd_out_vld  (north_write_cmd_vld_out      ),
            .north_write_cmd_out_pld  (north_write_cmd_pld_out      ));

            



endmodule