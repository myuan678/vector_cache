module vec_cache_sram_group 
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
    logic [7:0]             shift_sn_data_vld_wire_tmp [7:0];
    group_data_pld_t   [7:0]     shift_sn_data_wire_tmp[7:0];

    logic [7:0]             shift_sn_write_cmd_vld_wire_tmp[7:0];
    write_ram_cmd_t         shift_sn_write_cmd_wire_tmp[7:0][7:0];
    
    logic [7:0]             lr_read_cmd_vld_wire       [4:0][4:0];
    arb_out_req_t           lr_read_cmd_pld_wire  [4:0][4:0][7:0];
    logic [7:0]             rl_read_cmd_vld_wire       [4:0][4:0];
    arb_out_req_t           rl_read_cmd_pld_wire  [4:0][4:0][7:0];

    logic [7:0]             lr_write_cmd_vld_wire      [4:0][4:0];
    write_ram_cmd_t         lr_write_cmd_pld_wire [4:0][4:0][7:0];
    logic [7:0]             rl_write_cmd_vld_wire      [4:0][4:0];
    write_ram_cmd_t         rl_write_cmd_pld_wire [4:0][4:0][7:0];

    logic [7:0]             ns_write_cmd_vld_wire      [4:0][4:0];
    write_ram_cmd_t         ns_write_cmd_pld_wire [4:0][4:0][7:0];
    logic [7:0]             sn_write_cmd_vld_wire      [4:0][4:0];
    write_ram_cmd_t         sn_write_cmd_pld_wire [4:0][4:0][7:0];

    logic [7:0]             lr_data_vld_wire  [4:0][4:0];
    bankgroup_data_pld_t    lr_data_wire [4:0][4:0][7:0];   
    logic [7:0]             rl_data_vld_wire  [4:0][4:0];
    bankgroup_data_pld_t    rl_data_wire [4:0][4:0][7:0];

    logic [7:0]             sn_data_vld_wire  [4:0][4:0];
    bankgroup_data_pld_t    sn_data_wire [4:0][4:0][7:0];   
    logic [7:0]             ns_data_vld_wire  [4:0][4:0];
    bankgroup_data_pld_t    ns_data_wire [4:0][4:0][7:0];

    generate
        for(genvar i=0;i<4;i=i+1)begin:ROW_IN_CMD_GEN
            for(genvar j=0;j<8;j=j+1)begin:CHANNEL_CMD_GEN
                assign lr_read_cmd_pld_wire  [i][0][j] = west_read_cmd_pld_in[j];
                assign lr_read_cmd_vld_wire  [i][0][j] = west_read_cmd_vld_in[j];
                assign rl_read_cmd_pld_wire  [i][4][j] = east_read_cmd_pld_in[j];
                assign rl_read_cmd_vld_wire  [i][4][j] = east_read_cmd_vld_in[j];
                assign lr_write_cmd_pld_wire [i][0][j] = west_write_cmd_pld_in[j];
                assign lr_write_cmd_vld_wire [i][0][j] = west_write_cmd_vld_in[j];
                assign rl_write_cmd_pld_wire [i][4][j] = east_write_cmd_pld_in[j];
                assign rl_write_cmd_vld_wire [i][4][j] = east_write_cmd_vld_in[j];
                //assign sn_write_cmd_pld_wire [4][i][j] = south_write_cmd_pld_in[j];
                //assign sn_write_cmd_vld_wire [4][i][j] = south_write_cmd_vld_in[j];
                assign ns_write_cmd_pld_wire [0][i][j] = north_write_cmd_pld_in[j];
                assign ns_write_cmd_vld_wire [0][i][j] = north_write_cmd_vld_in[j];
            end
        end
    endgenerate
    generate
        for(genvar j=0;j<8;j=j+1)begin:SOUTH_WR_CMD_GEN
            assign sn_write_cmd_pld_wire [4][0][j] = south_write_cmd_pld_in[j];
            assign sn_write_cmd_vld_wire [4][0][j] = south_write_cmd_vld_in[j];
            assign sn_write_cmd_pld_wire [4][1][j] = shift_sn_write_cmd_wire_tmp[j][1];
            assign sn_write_cmd_vld_wire [4][1][j] = shift_sn_write_cmd_vld_wire_tmp[j][1];
            assign sn_write_cmd_pld_wire [4][2][j] = shift_sn_write_cmd_wire_tmp[j][3];
            assign sn_write_cmd_vld_wire [4][2][j] = shift_sn_write_cmd_vld_wire_tmp[j][3];
            assign sn_write_cmd_pld_wire [4][3][j] = shift_sn_write_cmd_wire_tmp[j][5];
            assign sn_write_cmd_vld_wire [4][3][j] = shift_sn_write_cmd_vld_wire_tmp[j][5];
        end
    endgenerate
    
    
    generate
        for(genvar i=0;i<8;i=i+1)begin:CHANNEL_IN_DATA_GEN
            assign lr_data_wire[0][0][i].data      = west_data_in[i].data[255:0];
            assign lr_data_wire[0][0][i].cmd_pld   = west_data_in[i].cmd_pld;
            assign lr_data_wire[1][0][i].data      = west_data_in[i].data[511:256];
            assign lr_data_wire[1][0][i].cmd_pld   = west_data_in[i].cmd_pld;
            assign lr_data_wire[2][0][i].data      = west_data_in[i].data[767:512];
            assign lr_data_wire[2][0][i].cmd_pld   = west_data_in[i].cmd_pld;
            assign lr_data_wire[3][0][i].data      = west_data_in[i].data[1023:768];
            assign lr_data_wire[3][0][i].cmd_pld   = west_data_in[i].cmd_pld;
            assign lr_data_vld_wire[0][0][i]       = west_data_in_vld[i];
            assign lr_data_vld_wire[1][0][i]       = west_data_in_vld[i];
            assign lr_data_vld_wire[2][0][i]       = west_data_in_vld[i];
            assign lr_data_vld_wire[3][0][i]       = west_data_in_vld[i];
            assign rl_data_wire[0][4][i].data      = east_data_in[i].data[255:0];
            assign rl_data_wire[0][4][i].cmd_pld   = east_data_in[i].cmd_pld;
            assign rl_data_wire[1][4][i].data      = east_data_in[i].data[511:256];
            assign rl_data_wire[1][4][i].cmd_pld   = east_data_in[i].cmd_pld;
            assign rl_data_wire[2][4][i].data      = east_data_in[i].data[767:512];
            assign rl_data_wire[2][4][i].cmd_pld   = east_data_in[i].cmd_pld;
            assign rl_data_wire[3][4][i].data      = east_data_in[i].data[1023:768];
            assign rl_data_wire[3][4][i].cmd_pld   = east_data_in[i].cmd_pld;
            assign rl_data_vld_wire[0][4][i]       = east_data_in_vld[i];
            assign rl_data_vld_wire[1][4][i]       = east_data_in_vld[i];
            assign rl_data_vld_wire[2][4][i]       = east_data_in_vld[i];
            assign rl_data_vld_wire[3][4][i]       = east_data_in_vld[i];
            assign sn_data_wire[4][0][i].data     = south_data_in[i].data[255:0];//south写需要平衡延迟
            assign sn_data_wire[4][0][i].cmd_pld  = south_data_in[i].cmd_pld;
            assign sn_data_wire[4][1][i].data     = shift_sn_data_wire_tmp[i][1].data[511:256];
            assign sn_data_wire[4][1][i].cmd_pld  = shift_sn_data_wire_tmp[i][1].cmd_pld;
            assign sn_data_wire[4][2][i].data     = shift_sn_data_wire_tmp[i][3].data[767:512];
            assign sn_data_wire[4][2][i].cmd_pld  = shift_sn_data_wire_tmp[i][3].cmd_pld;
            assign sn_data_wire[4][3][i].data     = shift_sn_data_wire_tmp[i][5].data[1023:768];
            assign sn_data_wire[4][3][i].cmd_pld  = shift_sn_data_wire_tmp[i][5].cmd_pld;

            assign sn_data_vld_wire[4][0][i]      = south_data_in_vld[i];
            assign sn_data_vld_wire[4][1][i]      = shift_sn_data_vld_wire_tmp[i][1];
            assign sn_data_vld_wire[4][2][i]      = shift_sn_data_vld_wire_tmp[i][3];
            assign sn_data_vld_wire[4][3][i]      = shift_sn_data_vld_wire_tmp[i][5];
            assign ns_data_wire[0][0][i].data     = north_data_in[i].data[255:0];
            assign ns_data_wire[0][0][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign ns_data_wire[0][1][i].data     = north_data_in[i].data[511:256];
            assign ns_data_wire[0][1][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign ns_data_wire[0][2][i].data     = north_data_in[i].data[767:512];
            assign ns_data_wire[0][2][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign ns_data_wire[0][3][i].data     = north_data_in[i].data[1023:768];
            assign ns_data_wire[0][3][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign ns_data_vld_wire[0][0][i]      = north_data_in_vld[i];
            assign ns_data_vld_wire[0][1][i]      = north_data_in_vld[i];
            assign ns_data_vld_wire[0][2][i]      = north_data_in_vld[i];
            assign ns_data_vld_wire[0][3][i]      = north_data_in_vld[i];
        end
    endgenerate


    //shift_reg south write data
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    for(int j=0;j<8;j=j+1)begin
                        shift_sn_data_wire_tmp[i][j] <= 'b0;
                    end
                end
                else begin
                    shift_sn_data_wire_tmp[i][0] <= south_data_in[i];
                    for(int j=1;j<8;j=j+1)begin
                        shift_sn_data_wire_tmp[i][j] <= shift_sn_data_wire_tmp[i][j-1];
                    end
                end
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    shift_sn_data_vld_wire_tmp[i] <= 'b0;
                end
                else begin
                    shift_sn_data_vld_wire_tmp[i] <= {shift_sn_data_vld_wire_tmp[i][6:0], south_data_in_vld[i]};
                end
            end
        end
    endgenerate
    //shift_reg south write cmd
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    for(int j=0;j<8;j=j+1)begin
                        shift_sn_write_cmd_wire_tmp[i][j] <= 'b0;
                    end
                end
                else begin
                    shift_sn_write_cmd_wire_tmp[i][0] <= south_write_cmd_pld_in[i];
                    for(int j=1;j<8;j=j+1)begin
                        shift_sn_write_cmd_wire_tmp[i][j] <= shift_sn_write_cmd_wire_tmp[i][j-1];
                    end
                end
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    shift_sn_write_cmd_vld_wire_tmp[i] <= 'b0;
                end
                else begin
                    shift_sn_write_cmd_vld_wire_tmp[i] <= {shift_sn_write_cmd_vld_wire_tmp[i][6:0], south_write_cmd_vld_in[i]};
                end
            end
        end
    endgenerate
    

      
    generate
        for(genvar i=0;i<4;i=i+1)begin:ROW_SRAM_BANK_GROUP//row_id
            for(genvar j=0;j<4;j=j+1)begin:COL_SRAM_BANK_GROUP//block_id
                vec_cache_sram_bank_group #(
                    .ROW_ID  (i),
                    .BLOCK_ID(j))
                u_sram_bank_group ( 
                    .clk                        (clk                             ),
                    .clk_div                    (clk_div                         ),
                    .rst_n                      (rst_n                           ),
                    .west_read_cmd_pld_in       (lr_read_cmd_pld_wire[i][j]      ),
                    .west_read_cmd_vld_in       (lr_read_cmd_vld_wire[i][j]      ),
                    .west_read_cmd_pld_out      (rl_read_cmd_pld_wire[i][j]      ),
                    .west_read_cmd_vld_out      (rl_read_cmd_vld_wire[i][j]      ),
                    .east_read_cmd_pld_in       (rl_read_cmd_pld_wire[i][j+1]    ),
                    .east_read_cmd_vld_in       (rl_read_cmd_vld_wire[i][j+1]    ),
                    .east_read_cmd_pld_out      (lr_read_cmd_pld_wire[i][j+1]    ),
                    .east_read_cmd_vld_out      (lr_read_cmd_vld_wire[i][j+1]    ),
                    .west_write_cmd_pld_in      (lr_write_cmd_pld_wire[i][j]     ),
                    .west_write_cmd_vld_in      (lr_write_cmd_vld_wire[i][j]     ),
                    .west_write_cmd_pld_out     (rl_write_cmd_pld_wire[i][j]     ),
                    .west_write_cmd_vld_out     (rl_write_cmd_vld_wire[i][j]     ),
                    .east_write_cmd_pld_in      (rl_write_cmd_pld_wire[i][j+1]   ),
                    .east_write_cmd_vld_in      (rl_write_cmd_vld_wire[i][j+1]   ),
                    .east_write_cmd_pld_out     (lr_write_cmd_pld_wire[i][j+1]   ),
                    .east_write_cmd_vld_out     (lr_write_cmd_vld_wire[i][j+1]   ),
                    .south_write_cmd_pld_in     (sn_write_cmd_pld_wire[i+1][j]   ),
                    .south_write_cmd_vld_in     (sn_write_cmd_vld_wire[i+1][j]   ),
                    .north_write_cmd_pld_in     (ns_write_cmd_pld_wire[i][j]     ),
                    .north_write_cmd_vld_in     (ns_write_cmd_vld_wire[i][j]     ),
                    .south_write_cmd_pld_out    (ns_write_cmd_pld_wire[i+1][j]   ),
                    .south_write_cmd_vld_out    (ns_write_cmd_vld_wire[i+1][j]   ),
                    .north_write_cmd_pld_out    (sn_write_cmd_pld_wire[i][j]     ),
                    .north_write_cmd_vld_out    (sn_write_cmd_vld_wire[i][j]     ),
                    .west_data_in_vld           (lr_data_vld_wire[i][j]          ),
                    .west_data_in               (lr_data_wire[i][j]              ),
                    .west_data_out_vld          (rl_data_vld_wire[i][j]          ),
                    .west_data_out              (rl_data_wire[i][j]              ),
                    .east_data_in_vld           (rl_data_vld_wire[i][j+1]        ),
                    .east_data_in               (rl_data_wire[i][j+1]            ),
                    .east_data_out_vld          (lr_data_vld_wire[i][j+1]        ),
                    .east_data_out              (lr_data_wire[i][j+1]            ),
                    .south_data_in_vld          (sn_data_vld_wire[i+1][j]        ),
                    .south_data_in              (sn_data_wire[i+1][j]            ),
                    .south_data_out_vld         (ns_data_vld_wire[i+1][j]        ),
                    .south_data_out             (ns_data_wire[i+1][j]            ),
                    .north_data_in_vld          (ns_data_vld_wire[i][j]          ),
                    .north_data_in              (ns_data_wire[i][j]              ),
                    .north_data_out_vld         (sn_data_vld_wire[i][j]          ),
                    .north_data_out             (sn_data_wire[i][j]              ));
            end    
        end
    endgenerate


generate
    for(genvar i=0;i<8;i=i+1)begin:CHANNEL_OUT_DATA_GEN
        assign west_data_out[i].data[255:0]   = rl_data_wire[0][0][i].data;
        assign west_data_out[i].data[511:256] = rl_data_wire[1][0][i].data;
        assign west_data_out[i].data[767:512] = rl_data_wire[2][0][i].data;
        assign west_data_out[i].data[1023:768]= rl_data_wire[3][0][i].data;
        assign west_data_out[i].cmd_pld       = rl_data_wire[0][0][i].cmd_pld;
        assign west_data_out_vld[i]           = rl_data_vld_wire[1][0][i];

        assign east_data_out[i].data[255:0]   = lr_data_wire[0][4][i].data;
        assign east_data_out[i].data[511:256] = lr_data_wire[1][4][i].data;
        assign east_data_out[i].data[767:512] = lr_data_wire[2][4][i].data;
        assign east_data_out[i].data[1023:768]= lr_data_wire[3][4][i].data;
        assign east_data_out[i].cmd_pld       = lr_data_wire[0][4][i].cmd_pld;
        assign east_data_out_vld[i]           = lr_data_vld_wire[0][4][i] ;

        assign south_data_out[i].data[255:0]   = ns_data_wire[4][0][i].data;
        assign south_data_out[i].data[511:256] = ns_data_wire[4][1][i].data;
        assign south_data_out[i].data[767:512] = ns_data_wire[4][2][i].data;
        assign south_data_out[i].data[1023:768]= ns_data_wire[4][3][i].data;
        assign south_data_out[i].cmd_pld       = ns_data_wire[4][0][i].cmd_pld;
        assign south_data_out_vld[i]           = ns_data_vld_wire[4][0][i];

        assign north_data_out[i].data[255:0]   = sn_data_wire[0][0][i].data;
        assign north_data_out[i].data[511:256] = sn_data_wire[0][1][i].data;
        assign north_data_out[i].data[767:512] = sn_data_wire[0][2][i].data;
        assign north_data_out[i].data[1023:768]= sn_data_wire[0][3][i].data;
        assign north_data_out[i].cmd_pld       = sn_data_wire[0][0][i].cmd_pld;
        assign north_data_out_vld[i]           = sn_data_vld_wire[0][0][i] ;
    end
endgenerate

generate
    for(genvar i=0;i<8;i=i+1)begin:CHANNEL_OUT_CMD_GEN
        assign east_read_cmd_pld_out  [i] = lr_read_cmd_pld_wire[0][4][i];
        assign east_read_cmd_vld_out  [i] = lr_read_cmd_vld_wire[0][4][i];

        assign east_write_cmd_pld_out [i] = lr_write_cmd_pld_wire[0][4][i];  
        assign east_write_cmd_vld_out [i] = lr_write_cmd_vld_wire[0][4][i];  
        
    end
endgenerate



endmodule