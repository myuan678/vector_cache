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
    
    logic [7:0]             west_read_cmd_vld_out_wire       [3:0][3:1];
    logic [7:0]             east_read_cmd_vld_out_wire       [3:0][2:0];  
    logic [7:0]             west_write_cmd_vld_out_wire      [3:0][3:1];
    logic [7:0]             east_write_cmd_vld_out_wire      [3:0][2:0]; 
    logic [7:0]             north_write_cmd_vld_out_wire     [3:1][3:0];
    logic [7:0]             south_write_cmd_vld_out_wire     [2:0][3:0];
    arb_out_req_t           west_read_cmd_pld_out_wire  [3:0][3:1][7:0];
    arb_out_req_t           east_read_cmd_pld_out_wire  [3:0][2:0][7:0];
    write_ram_cmd_t         west_write_cmd_pld_out_wire [3:0][3:1][7:0];
    write_ram_cmd_t         east_write_cmd_pld_out_wire [3:0][2:0][7:0];
    write_ram_cmd_t         north_write_cmd_pld_out_wire[3:1][3:0][7:0];
    write_ram_cmd_t         south_write_cmd_pld_out_wire[2:0][3:0][7:0];

    logic [7:0]             west_data_out_vld_wire  [3:0][3:1];
    logic [7:0]             east_data_out_vld_wire  [3:0][2:0]; 
    logic [7:0]             north_data_out_vld_wire [3:1][3:0];
    logic [7:0]             south_data_out_vld_wire [2:0][3:0];
    bankgroup_data_pld_t    west_data_out_wire [3:0][3:1][7:0];    
    bankgroup_data_pld_t    east_data_out_wire [3:0][2:0][7:0];      
    bankgroup_data_pld_t    north_data_out_wire[3:1][3:0][7:0]; 
    bankgroup_data_pld_t    south_data_out_wire[2:0][3:0][7:0]; 
    

    arb_out_req_t   west_read_cmd_pld_out_wireout[3:0][7:0];
    logic [7:0]     west_read_cmd_vld_out_wireout[3:0];
    arb_out_req_t   east_read_cmd_pld_out_wireout[3:0][7:0];
    logic [7:0]     east_read_cmd_vld_out_wireout[3:0];
    write_ram_cmd_t west_write_cmd_pld_out_wireout[3:0][7:0];
    logic [7:0]     west_write_cmd_vld_out_wireout[3:0];

    write_ram_cmd_t east_write_cmd_pld_out_wireout[3:0][7:0];
    logic [7:0]     east_write_cmd_vld_out_wireout[3:0];
    write_ram_cmd_t south_write_cmd_pld_out_wireout[3:0][7:0];
    logic [7:0]     south_write_cmd_vld_out_wireout[3:0];
    write_ram_cmd_t north_write_cmd_pld_out_wireout[3:0][7:0];
    logic [7:0]     north_write_cmd_vld_out_wireout[3:0];

    logic [7:0]             west_data_out_vld_wireout[3:0];
    bankgroup_data_pld_t    west_data_out_wireout[3:0][7:0]    ;

    logic [7:0]             east_data_out_vld_wireout[3:0];
    bankgroup_data_pld_t    east_data_out_wireout  [3:0][7:0]    ;  

    logic [7:0]             south_data_out_vld_wireout[3:0];
    bankgroup_data_pld_t    south_data_out_wireout   [3:0][7:0]    ;
    logic [7:0]             north_data_out_vld_wireout[3:0];
    bankgroup_data_pld_t    north_data_out_wireout[3:0][7:0]    ;    

    arb_out_req_t   west_read_cmd_pld_in_wire[3:0][7:0];
    logic [7:0]     west_read_cmd_vld_in_wire[3:0];
    arb_out_req_t   east_read_cmd_pld_in_wire[3:0][7:0];
    logic [7:0]     east_read_cmd_vld_in_wire[3:0];
    write_ram_cmd_t west_write_cmd_pld_in_wire[3:0][7:0];
    logic [7:0]     west_write_cmd_vld_in_wire[3:0];
    write_ram_cmd_t east_write_cmd_pld_in_wire[3:0][7:0];
    logic [7:0]     east_write_cmd_vld_in_wire[3:0];

    write_ram_cmd_t south_write_cmd_pld_in_wire[3:0][7:0];
    logic [7:0]     south_write_cmd_vld_in_wire[3:0];
    write_ram_cmd_t north_write_cmd_pld_in_wire[3:0][7:0];
    logic [7:0]     north_write_cmd_vld_in_wire[3:0];
    generate
        for(genvar i=0;i<4;i=i+1)begin
            for(genvar j=0;j<8;j=j+1)begin
                assign west_read_cmd_pld_in_wire[i][j] = west_read_cmd_pld_in[j];
                assign west_read_cmd_vld_in_wire[i][j] = west_read_cmd_vld_in[j];
                assign east_read_cmd_pld_in_wire[i][j] = east_read_cmd_pld_in[j];
                assign east_read_cmd_vld_in_wire[i][j] = east_read_cmd_vld_in[j];
                assign west_write_cmd_pld_in_wire[i][j] = west_write_cmd_pld_in[j];
                assign west_write_cmd_vld_in_wire[i][j] = west_write_cmd_vld_in[j];
                assign east_write_cmd_pld_in_wire[i][j] = east_write_cmd_pld_in[j];
                assign east_write_cmd_vld_in_wire[i][j] = east_write_cmd_vld_in[j];
                assign south_write_cmd_pld_in_wire[i][j] =south_write_cmd_pld_in[j];
                assign south_write_cmd_vld_in_wire[i][j] =south_write_cmd_vld_in[j];
                assign north_write_cmd_pld_in_wire[i][j] =north_write_cmd_pld_in[j];
                assign north_write_cmd_vld_in_wire[i][j] =north_write_cmd_vld_in[j];
            end
        end
    endgenerate
    logic [7:0]             west_data_in_vld_wire    [3:0];
    bankgroup_data_pld_t    west_data_in_wire        [3:0][7:0];
    logic [7:0]             east_data_in_vld_wire    [3:0];
    bankgroup_data_pld_t    east_data_in_wire        [3:0][7:0];
    logic [7:0]             south_data_in_vld_wire   [3:0];
    bankgroup_data_pld_t    south_data_in_wire       [3:0][7:0];
    logic [7:0]             north_data_in_vld_wire   [3:0];
    bankgroup_data_pld_t    north_data_in_wire       [3:0][7:0];
    
    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign west_data_in_wire[0][i].data     = west_data_in[i].data[255:0];
            assign west_data_in_wire[0][i].cmd_pld  = west_data_in[i].cmd_pld;
            assign west_data_in_wire[1][i].data     = west_data_in[i].data[511:256];
            assign west_data_in_wire[1][i].cmd_pld  = west_data_in[i].cmd_pld;
            assign west_data_in_wire[2][i].data     = west_data_in[i].data[767:512];
            assign west_data_in_wire[2][i].cmd_pld  = west_data_in[i].cmd_pld;
            assign west_data_in_wire[3][i].data     = west_data_in[i].data[1023:768];
            assign west_data_in_wire[3][i].cmd_pld  = west_data_in[i].cmd_pld;
            assign west_data_in_vld_wire[0][i]      = west_data_in_vld[i];
            assign west_data_in_vld_wire[1][i]      = west_data_in_vld[i];
            assign west_data_in_vld_wire[2][i]      = west_data_in_vld[i];
            assign west_data_in_vld_wire[3][i]      = west_data_in_vld[i];
            assign east_data_in_wire[0][i].data     = east_data_in[i].data[255:0];
            assign east_data_in_wire[0][i].cmd_pld  = east_data_in[i].cmd_pld;
            assign east_data_in_wire[1][i].data     = east_data_in[i].data[511:256];
            assign east_data_in_wire[1][i].cmd_pld  = east_data_in[i].cmd_pld;
            assign east_data_in_wire[2][i].data     = east_data_in[i].data[767:512];
            assign east_data_in_wire[2][i].cmd_pld  = east_data_in[i].cmd_pld;
            assign east_data_in_wire[3][i].data     = east_data_in[i].data[1023:768];
            assign east_data_in_wire[3][i].cmd_pld  = east_data_in[i].cmd_pld;
            assign east_data_in_vld_wire[0][i]      = east_data_in_vld[i];
            assign east_data_in_vld_wire[1][i]      = east_data_in_vld[i];
            assign east_data_in_vld_wire[2][i]      = east_data_in_vld[i];
            assign east_data_in_vld_wire[3][i]      = east_data_in_vld[i];
            assign south_data_in_wire[0][i].data     = south_data_in[i].data[255:0];
            assign south_data_in_wire[0][i].cmd_pld  = south_data_in[i].cmd_pld;
            assign south_data_in_wire[1][i].data     = south_data_in[i].data[511:256];
            assign south_data_in_wire[1][i].cmd_pld  = south_data_in[i].cmd_pld;
            assign south_data_in_wire[2][i].data     = south_data_in[i].data[767:512];
            assign south_data_in_wire[2][i].cmd_pld  = south_data_in[i].cmd_pld;
            assign south_data_in_wire[3][i].data     = south_data_in[i].data[1023:768];
            assign south_data_in_wire[3][i].cmd_pld  = south_data_in[i].cmd_pld;
            assign south_data_in_vld_wire[0][i]      = south_data_in_vld[i];
            assign south_data_in_vld_wire[1][i]      = south_data_in_vld[i];
            assign south_data_in_vld_wire[2][i]      = south_data_in_vld[i];
            assign south_data_in_vld_wire[3][i]      = south_data_in_vld[i];
            assign north_data_in_wire[0][i].data     = north_data_in[i].data[255:0];
            assign north_data_in_wire[0][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign north_data_in_wire[1][i].data     = north_data_in[i].data[511:256];
            assign north_data_in_wire[1][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign north_data_in_wire[2][i].data     = north_data_in[i].data[767:512];
            assign north_data_in_wire[2][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign north_data_in_wire[3][i].data     = north_data_in[i].data[1023:768];
            assign north_data_in_wire[3][i].cmd_pld  = north_data_in[i].cmd_pld;
            assign north_data_in_vld_wire[0][i]      = north_data_in_vld[i];
            assign north_data_in_vld_wire[1][i]      = north_data_in_vld[i];
            assign north_data_in_vld_wire[2][i]      = north_data_in_vld[i];
            assign north_data_in_vld_wire[3][i]      = north_data_in_vld[i];
        end
    endgenerate

      
    generate
        for(genvar i=0;i<4;i=i+1)begin//row_id
            if(i==0)begin
                for(genvar j=0;j<4;j=j+1)begin//block_id
                    if(j==0)begin
                        sram_bank_group #(
                            .BLOCK_ID(i),
                            .ROW_ID  (j))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (west_read_cmd_pld_in_wire[i]           ),//input
                            .west_read_cmd_vld_in       (west_read_cmd_vld_in_wire[i]           ),//input
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wireout[i]       ),//output
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wireout[i]       ),//output
                            .east_read_cmd_pld_in       (west_read_cmd_pld_out_wire[i][j+1]     ),
                            .east_read_cmd_vld_in       (west_read_cmd_vld_out_wire[i][j+1]     ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wire[i][j]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wire[i][j]       ),
                            .west_write_cmd_pld_in      (west_write_cmd_pld_in_wire[i]          ),//input
                            .west_write_cmd_vld_in      (west_write_cmd_vld_in_wire[i]          ),//input
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wireout[i]      ),//output west write output
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wireout[i]      ),//output west write output
                            .east_write_cmd_pld_in      (west_write_cmd_pld_out_wire[i][j+1]    ),
                            .east_write_cmd_vld_in      (west_write_cmd_vld_out_wire[i][j+1]    ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wire[i][j]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wire[i][j]      ),
                            .south_write_cmd_pld_in     (north_write_cmd_pld_out_wire[i+1][j]   ),
                            .south_write_cmd_vld_in     (north_write_cmd_vld_out_wire[i+1][j]   ),
                            .north_write_cmd_pld_in     (north_write_cmd_pld_in_wire[j]         ),//input south write cmd input
                            .north_write_cmd_vld_in     (north_write_cmd_vld_in_wire[j]         ),//input south write cmd input
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wire[i][j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wire[i][j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wireout[j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wireout[j]     ),
                            .west_data_in_vld           (west_data_in_vld_wire[i]               ),//input west data_in
                            .west_data_in               (west_data_in_wire[i]                   ),//input west data_in
                            .west_data_out_vld          (west_data_out_vld_wireout[i]           ),//output west data_out
                            .west_data_out              (west_data_out_wireout[i]               ),//output west data_out
                            .east_data_in_vld           (west_data_out_vld_wire[i][j+1]         ),
                            .east_data_in               (west_data_out_wire[i][j+1]             ),
                            .east_data_out_vld          (east_data_out_vld_wire[i][j]           ),
                            .east_data_out              (east_data_out_wire[i][j]               ),
                            .south_data_in_vld          (north_data_out_vld_wire[i+1][j]        ),
                            .south_data_in              (north_data_out_wire[i+1][j]            ),
                            .south_data_out_vld         (south_data_out_vld_wire[i][j]          ),//to 第二行第一列north
                            .south_data_out             (south_data_out_wire[i][j]              ),//to 第二行第一列north
                            .north_data_in_vld          (north_data_in_vld_wire[j]              ),//input north data
                            .north_data_in              (north_data_in_wire    [j]              ),//input north data
                            .north_data_out_vld         (north_data_out_vld_wireout[j]          ), //output north data out
                            .north_data_out             (north_data_out_wireout[j]              ));//output north data out
                    end
                    else if(j==3)begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (east_read_cmd_pld_out_wire[i][j-1]     ),
                            .west_read_cmd_vld_in       (east_read_cmd_vld_out_wire[i][j-1]     ),
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wire[i][j]       ),
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wire[i][j]       ),
                            .east_read_cmd_pld_in       (east_read_cmd_pld_in_wire[i]           ),//east input
                            .east_read_cmd_vld_in       (east_read_cmd_vld_in_wire[i]           ),//east input
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wireout[i]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wireout[i]       ),
                            .west_write_cmd_pld_in      (east_write_cmd_pld_out_wire[i][j-1]    ),
                            .west_write_cmd_vld_in      (east_write_cmd_vld_out_wire[i][j-1]    ),
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wire[i][j]      ),
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wire[i][j]      ),
                            .east_write_cmd_pld_in      (east_write_cmd_pld_in_wire[i]          ),//east write input
                            .east_write_cmd_vld_in      (east_write_cmd_vld_in_wire[i]          ),//east write input
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wireout[i]      ),//output
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wireout[i]      ),//output
                            .south_write_cmd_pld_in     (north_write_cmd_pld_out_wire[i+1][j]   ),
                            .south_write_cmd_vld_in     (north_write_cmd_vld_out_wire[i+1][j]   ),
                            .north_write_cmd_pld_in     (north_write_cmd_pld_in_wire[j]         ),//input
                            .north_write_cmd_vld_in     (north_write_cmd_vld_in_wire[j]         ),//input
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wire[i][j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wire[i][j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wireout[j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wireout[j]     ),
                            .west_data_in_vld           (east_data_out_vld_wire[i][j-1]         ),
                            .west_data_in               (east_data_out_wire[i][j-1]             ),
                            .west_data_out_vld          (west_data_out_vld_wire[i][j]           ),
                            .west_data_out              (west_data_out_wire[i][j]               ),
                            .east_data_in_vld           (east_data_in_vld_wire[i]               ),//input east data_in
                            .east_data_in               (east_data_in_wire[i]                   ),//input east data_in
                            .east_data_out_vld          (east_data_out_vld_wireout[i]           ),//output east data_out
                            .east_data_out              (east_data_out_wireout[i]               ),//output east data_out
                            .south_data_in_vld          (north_data_out_vld_wire[i+1][j]        ),
                            .south_data_in              (north_data_out_wire[i+1][j]            ),
                            .south_data_out_vld         (south_data_out_vld_wire[i][j]          ),
                            .south_data_out             (south_data_out_wire[i][j]              ),
                            .north_data_in_vld          (north_data_in_vld_wire[j]              ),//input
                            .north_data_in              (north_data_in_wire    [j]              ),//input
                            .north_data_out_vld         (north_data_out_vld_wireout[j]          ),
                            .north_data_out             (north_data_out_wireout[j]              ));
                    end
                    else begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                      ),
                            .clk_div                    (clk_div                                  ),
                            .rst_n                      (rst_n                                    ),
                            .west_read_cmd_pld_in       (east_read_cmd_pld_out_wire[i][j-1]       ),
                            .west_read_cmd_vld_in       (east_read_cmd_vld_out_wire[i][j-1]       ),
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wire[i][j]         ),
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wire[i][j]         ),
                            .east_read_cmd_pld_in       (west_read_cmd_pld_out_wire[i][j+1]       ),
                            .east_read_cmd_vld_in       (west_read_cmd_vld_out_wire[i][j+1]       ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wire[i][j]         ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wire[i][j]         ),
                            .west_write_cmd_pld_in      (east_write_cmd_pld_out_wire[i][j-1]      ),
                            .west_write_cmd_vld_in      (east_write_cmd_vld_out_wire[i][j-1]      ),
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wire[i][j]        ),
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wire[i][j]        ),
                            .east_write_cmd_pld_in      (west_write_cmd_pld_out_wire[i][j+1]      ),
                            .east_write_cmd_vld_in      (west_write_cmd_vld_out_wire[i][j+1]      ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wire[i][j]        ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wire[i][j]        ),
                            .south_write_cmd_pld_in     (north_write_cmd_pld_out_wire[i+1][j]     ),
                            .south_write_cmd_vld_in     (north_write_cmd_vld_out_wire[i+1][j]     ),
                            .north_write_cmd_pld_in     (north_write_cmd_pld_in_wire[j]           ),//input
                            .north_write_cmd_vld_in     (north_write_cmd_vld_in_wire[j]           ),//input
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wire[i][j]       ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wire[i][j]       ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wireout[j]       ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wireout[j]       ),
                            .west_data_in_vld           (east_data_out_vld_wire[i][j-1]           ),
                            .west_data_in               (east_data_out_wire[i][j-1]               ),
                            .west_data_out_vld          (west_data_out_vld_wire[i][j]             ),
                            .west_data_out              (west_data_out_wire[i][j]                 ),
                            .east_data_in_vld           (west_data_out_vld_wire[i][j+1]           ),
                            .east_data_in               (west_data_out_wire[i][j+1]               ),
                            .east_data_out_vld          (east_data_out_vld_wire[i][j]             ),
                            .east_data_out              (east_data_out_wire[i][j]                 ),
                            .south_data_in_vld          (north_data_out_vld_wire[i+1][j]          ),
                            .south_data_in              (north_data_out_wire[i+1][j]              ),
                            .south_data_out_vld         (south_data_out_vld_wire[i][j]            ),
                            .south_data_out             (south_data_out_wire[i][j]                ),
                            .north_data_in_vld          (north_data_in_vld_wire[j]                ),//input
                            .north_data_in              (north_data_in_wire    [j]                ),//input
                            .north_data_out_vld         (north_data_out_vld_wireout[j]            ),
                            .north_data_out             (north_data_out_wireout[j]                ));
                    end
                end
            end
            else if(i==3)begin
                for(genvar j=0;j<4;j=j+1)begin
                    if(j==0)begin//第四行第一列
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (west_read_cmd_pld_in_wire[i]           ),
                            .west_read_cmd_vld_in       (west_read_cmd_vld_in_wire[i]           ),
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wireout[i]       ),
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wireout[i]       ),
                            .east_read_cmd_pld_in       (west_read_cmd_pld_out_wire[i][j+1]     ),
                            .east_read_cmd_vld_in       (west_read_cmd_vld_out_wire[i][j+1]     ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wire[i][j]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wire[i][j]       ),
                            .west_write_cmd_pld_in      (west_write_cmd_pld_in_wire[i]          ),
                            .west_write_cmd_vld_in      (west_write_cmd_vld_in_wire[i]          ),
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wireout[i]      ),
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wireout[i]      ),
                            .east_write_cmd_pld_in      (west_write_cmd_pld_out_wire[i][j+1]    ),
                            .east_write_cmd_vld_in      (west_write_cmd_vld_out_wire[i][j+1]    ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wire[i][j]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wire[i][j]      ),
                            .south_write_cmd_pld_in     (south_write_cmd_pld_in_wire[j]         ),//input south write
                            .south_write_cmd_vld_in     (south_write_cmd_vld_in_wire[j]         ),//input south write
                            .north_write_cmd_pld_in     (south_write_cmd_pld_out_wire[i-1][j]   ),
                            .north_write_cmd_vld_in     (south_write_cmd_vld_out_wire[i-1][j]   ),
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wireout[j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wireout[j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wire[i][j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wire[i][j]     ),
                            .west_data_in_vld           (west_data_in_vld_wire[i]               ),
                            .west_data_in               (west_data_in_wire[i]                   ),
                            .west_data_out_vld          (west_data_out_vld_wireout[i]           ),
                            .west_data_out              (west_data_out_wireout[i]               ),
                            .east_data_in_vld           (west_data_out_vld_wire[i][j+1]         ),
                            .east_data_in               (west_data_out_wire[i][j+1]             ),
                            .east_data_out_vld          (east_data_out_vld_wire[i][j]           ),
                            .east_data_out              (east_data_out_wire[i][j]               ),
                            .south_data_in_vld          (south_data_in_vld_wire[j]              ),//input south data
                            .south_data_in              (south_data_in_wire    [j]              ),//input south data
                            .south_data_out_vld         (south_data_out_vld_wireout[j]          ),//output south data out
                            .south_data_out             (south_data_out_wireout[j]              ),//output south data out
                            .north_data_in_vld          (south_data_out_vld_wire[i-1][j]        ),
                            .north_data_in              (south_data_out_wire[i-1][j]            ),
                            .north_data_out_vld         (north_data_out_vld_wire[i][j]          ),
                            .north_data_out             (north_data_out_wire[i][j]              ));
                    end
                    else if(j==3)begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (east_read_cmd_pld_out_wire[i][j-1]     ),
                            .west_read_cmd_vld_in       (east_read_cmd_vld_out_wire[i][j-1]     ),
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wire[i][j]       ),
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wire[i][j]       ),
                            .east_read_cmd_pld_in       (east_read_cmd_pld_in_wire[i]           ),//input
                            .east_read_cmd_vld_in       (east_read_cmd_vld_in_wire[i]           ),//input
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wireout[i]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wireout[i]       ),
                            .west_write_cmd_pld_in      (east_write_cmd_pld_out_wire[i][j-1]    ),
                            .west_write_cmd_vld_in      (east_write_cmd_vld_out_wire[i][j-1]    ),
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wire[i][j]      ),
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wire[i][j]      ),
                            .east_write_cmd_pld_in      (east_write_cmd_pld_in_wire[i]          ),//input
                            .east_write_cmd_vld_in      (east_write_cmd_vld_in_wire[i]          ),//input
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wireout[i]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wireout[i]      ),
                            .south_write_cmd_pld_in     (south_write_cmd_pld_in_wire[j]         ),//input south write
                            .south_write_cmd_vld_in     (south_write_cmd_vld_in_wire[j]         ),//input south write
                            .north_write_cmd_pld_in     (south_write_cmd_pld_out_wire[i-1][j]   ),
                            .north_write_cmd_vld_in     (south_write_cmd_vld_out_wire[i-1][j]   ),
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wireout[j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wireout[j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wire[i][j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wire[i][j]     ),
                            .west_data_in_vld           (east_data_out_vld_wire[i][j-1]         ),
                            .west_data_in               (east_data_out_wire[i][j-1]             ),
                            .west_data_out_vld          (west_data_out_vld_wire[i][j]           ),
                            .west_data_out              (west_data_out_wire[i][j]               ),
                            .east_data_in_vld           (east_data_in_vld_wire[i]               ),//input east data
                            .east_data_in               (east_data_in_wire[i]                   ),//input east data
                            .east_data_out_vld          (east_data_out_vld_wireout[i]           ),
                            .east_data_out              (east_data_out_wireout[i]               ),
                            .south_data_in_vld          (south_data_in_vld_wire[j]              ),//input south data
                            .south_data_in              (south_data_in_wire    [j]              ),//input south data
                            .south_data_out_vld         (south_data_out_vld_wireout[j]          ),//output south data out
                            .south_data_out             (south_data_out_wireout[j]              ),//output south data out
                            .north_data_in_vld          (south_data_out_vld_wire[i-1][j]        ),
                            .north_data_in              (south_data_out_wire[i-1][j]            ),
                            .north_data_out_vld         (north_data_out_vld_wire[i][j]          ),
                            .north_data_out             (north_data_out_wire[i][j]              ));
                    end
                    else begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (east_read_cmd_pld_out_wire[i][j-1]     ),
                            .west_read_cmd_vld_in       (east_read_cmd_vld_out_wire[i][j-1]     ),
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wire[i][j]       ),
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wire[i][j]       ),
                            .east_read_cmd_pld_in       (west_read_cmd_pld_out_wire[i][j+1]     ),
                            .east_read_cmd_vld_in       (west_read_cmd_vld_out_wire[i][j+1]     ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wire[i][j]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wire[i][j]       ),
                            .west_write_cmd_pld_in      (east_write_cmd_pld_out_wire[i][j-1]    ),
                            .west_write_cmd_vld_in      (east_write_cmd_vld_out_wire[i][j-1]    ),
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wire[i][j]      ),
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wire[i][j]      ),
                            .east_write_cmd_pld_in      (west_write_cmd_pld_out_wire[i][j+1]    ),
                            .east_write_cmd_vld_in      (west_write_cmd_vld_out_wire[i][j+1]    ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wire[i][j]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wire[i][j]      ),
                            .south_write_cmd_pld_in     (south_write_cmd_pld_in_wire[j]         ),//input south write
                            .south_write_cmd_vld_in     (south_write_cmd_vld_in_wire[j]         ),//input south write
                            .north_write_cmd_pld_in     (south_write_cmd_pld_out_wire[i-1][j]   ),
                            .north_write_cmd_vld_in     (south_write_cmd_vld_out_wire[i-1][j]   ),
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wireout[j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wireout[j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wire[i][j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wire[i][j]     ),
                            .west_data_in_vld           (east_data_out_vld_wire[i][j-1]         ),
                            .west_data_in               (east_data_out_wire[i][j-1]             ),
                            .west_data_out_vld          (west_data_out_vld_wire[i][j]           ),
                            .west_data_out              (west_data_out_wire[i][j]               ),
                            .east_data_in_vld           (west_data_out_vld_wire[i][j+1]         ),
                            .east_data_in               (west_data_out_wire[i][j+1]             ),
                            .east_data_out_vld          (east_data_out_vld_wire[i][j]           ),
                            .east_data_out              (east_data_out_wire[i][j]               ),
                            .south_data_in_vld          (south_data_in_vld_wire[j]              ),//input south data
                            .south_data_in              (south_data_in_wire    [j]              ),//input south data
                            .south_data_out_vld         (south_data_out_vld_wireout[j]          ),//output south data out
                            .south_data_out             (south_data_out_wireout[j]              ),//output south data out
                            .north_data_in_vld          (south_data_out_vld_wire[i-1][j]        ),
                            .north_data_in              (south_data_out_wire[i-1][j]            ),
                            .north_data_out_vld         (north_data_out_vld_wire[i][j]          ),
                            .north_data_out             (north_data_out_wire[i][j]              ));
                    end    
                end
            end
            else begin//第二行第三行
                for(genvar j=0;j<4;j=j+1)begin
                    if(j==0)begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (west_read_cmd_pld_in_wire[i]           ),//input
                            .west_read_cmd_vld_in       (west_read_cmd_vld_in_wire[i]           ),//input
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wireout[i]       ),//output
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wireout[i]       ),//output
                            .east_read_cmd_pld_in       (west_read_cmd_pld_out_wire[i][j+1]     ),
                            .east_read_cmd_vld_in       (west_read_cmd_vld_out_wire[i][j+1]     ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wire[i][j]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wire[i][j]       ),
                            .west_write_cmd_pld_in      (west_write_cmd_pld_in_wire[i]          ),//input
                            .west_write_cmd_vld_in      (west_write_cmd_vld_in_wire[i]          ),//input
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wireout[i]      ),//output west write output
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wireout[i]      ),//output west write output
                            .east_write_cmd_pld_in      (west_write_cmd_pld_out_wire[i][j+1]    ),
                            .east_write_cmd_vld_in      (west_write_cmd_vld_out_wire[i][j+1]    ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wire[i][j]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wire[i][j]      ),
                            .south_write_cmd_pld_in     (north_write_cmd_pld_out_wire[i+1][j]   ),
                            .south_write_cmd_vld_in     (north_write_cmd_vld_out_wire[i+1][j]   ),
                            .north_write_cmd_pld_in     (south_write_cmd_pld_out_wire[i-1][j]   ),
                            .north_write_cmd_vld_in     (south_write_cmd_vld_out_wire[i-1][j]   ),
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wire[i][j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wire[i][j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wire[i][j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wire[i][j]     ),
                            .west_data_in_vld           (west_data_in_vld_wire[i]               ),//input west data_in
                            .west_data_in               (west_data_in_wire[i]                   ),//input west data_in
                            .west_data_out_vld          (west_data_out_vld_wireout[i]           ),//output west data_out
                            .west_data_out              (west_data_out_wireout[i]               ),//output west data_out
                            .east_data_in_vld           (west_data_out_vld_wire[i][j+1]         ),
                            .east_data_in               (west_data_out_wire[i][j+1]             ),
                            .east_data_out_vld          (east_data_out_vld_wire[i][j]           ),
                            .east_data_out              (east_data_out_wire[i][j]               ),
                            .south_data_in_vld          (north_data_out_vld_wire[i+1][j]        ),
                            .south_data_in              (north_data_out_wire[i+1][j]            ),
                            .south_data_out_vld         (south_data_out_vld_wire[i][j]          ),
                            .south_data_out             (south_data_out_wire[i][j]              ),
                            .north_data_in_vld          (south_data_out_vld_wire[i-1][j]        ),
                            .north_data_in              (south_data_out_wire[i-1][j]            ),
                            .north_data_out_vld         (north_data_out_vld_wire[i][j]          ),
                            .north_data_out             (north_data_out_wire[i][j]              ));
                    end
                    else if(j==3)begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (east_read_cmd_pld_out_wire[i][j-1]     ),//input
                            .west_read_cmd_vld_in       (east_read_cmd_vld_out_wire[i][j-1]     ),//input
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wire[i][j]       ),//output
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wire[i][j]       ),//output
                            .east_read_cmd_pld_in       (east_read_cmd_pld_in_wire[i]           ),
                            .east_read_cmd_vld_in       (east_read_cmd_vld_in_wire[i]           ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wireout[i]       ),//output
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wireout[i]       ),//output
                            .west_write_cmd_pld_in      (east_write_cmd_pld_out_wire[i][j-1]    ),//input
                            .west_write_cmd_vld_in      (east_write_cmd_vld_out_wire[i][j-1]    ),//input
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wire[i][j]      ),
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wire[i][j]      ),
                            .east_write_cmd_pld_in      (east_write_cmd_pld_in_wire[i]          ),
                            .east_write_cmd_vld_in      (east_write_cmd_vld_in_wire[i]          ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wireout[i]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wireout[i]      ),
                            .south_write_cmd_pld_in     (north_write_cmd_pld_out_wire[i+1][j]   ),
                            .south_write_cmd_vld_in     (north_write_cmd_vld_out_wire[i+1][j]   ),
                            .north_write_cmd_pld_in     (south_write_cmd_pld_out_wire[i-1][j]   ),
                            .north_write_cmd_vld_in     (south_write_cmd_vld_out_wire[i-1][j]   ),
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wire[i][j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wire[i][j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wire[i][j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wire[i][j]     ),
                            .west_data_in_vld           (east_data_out_vld_wire[i][j-1]         ),
                            .west_data_in               (east_data_out_wire[i][j-1]             ),
                            .west_data_out_vld          (west_data_out_vld_wire[i][j]           ),//output west data_out
                            .west_data_out              (west_data_out_wire[i][j]               ),//output west data_out
                            .east_data_in_vld           (east_data_in_vld_wire[i]               ),//input 
                            .east_data_in               (east_data_in_wire[i]                   ),//input 
                            .east_data_out_vld          (east_data_out_vld_wireout[i]           ),
                            .east_data_out              (east_data_out_wireout[i]               ),
                            .south_data_in_vld          (north_data_out_vld_wire[i+1][j]        ),
                            .south_data_in              (north_data_out_wire[i+1][j]            ),
                            .south_data_out_vld         (south_data_out_vld_wire[i][j]          ),
                            .south_data_out             (south_data_out_wire[i][j]              ),
                            .north_data_in_vld          (south_data_out_vld_wire[i-1][j]        ),
                            .north_data_in              (south_data_out_wire[i-1][j]            ),
                            .north_data_out_vld         (north_data_out_vld_wire[i][j]          ),
                            .north_data_out             (north_data_out_wire[i][j]              ));
                    end
                    else begin
                        sram_bank_group #(
                            .BLOCK_ID(j),
                            .ROW_ID  (i))
                        u_sram_bank_group ( 
                            .clk                        (clk                                    ),
                            .clk_div                    (clk_div                                ),
                            .rst_n                      (rst_n                                  ),
                            .west_read_cmd_pld_in       (east_read_cmd_pld_out_wire[i][j-1]     ),//input
                            .west_read_cmd_vld_in       (east_read_cmd_vld_out_wire[i][j-1]     ),//input
                            .west_read_cmd_pld_out      (west_read_cmd_pld_out_wire[i][j]       ),//output
                            .west_read_cmd_vld_out      (west_read_cmd_vld_out_wire[i][j]       ),//output
                            .east_read_cmd_pld_in       (west_read_cmd_pld_out_wire[i][j+1]     ),
                            .east_read_cmd_vld_in       (west_read_cmd_vld_out_wire[i][j+1]     ),
                            .east_read_cmd_pld_out      (east_read_cmd_pld_out_wire[i][j]       ),
                            .east_read_cmd_vld_out      (east_read_cmd_vld_out_wire[i][j]       ),
                            .west_write_cmd_pld_in      (east_write_cmd_pld_out_wire[i][j-1]    ),//input
                            .west_write_cmd_vld_in      (east_write_cmd_vld_out_wire[i][j-1]    ),//input
                            .west_write_cmd_pld_out     (west_write_cmd_pld_out_wire[i][j]      ),//output west write output
                            .west_write_cmd_vld_out     (west_write_cmd_vld_out_wire[i][j]      ),//output west write output
                            .east_write_cmd_pld_in      (west_write_cmd_pld_out_wire[i][j+1]    ),
                            .east_write_cmd_vld_in      (west_write_cmd_vld_out_wire[i][j+1]    ),
                            .east_write_cmd_pld_out     (east_write_cmd_pld_out_wire[i][j]      ),
                            .east_write_cmd_vld_out     (east_write_cmd_vld_out_wire[i][j]      ),
                            .south_write_cmd_pld_in     (north_write_cmd_pld_out_wire[i+1][j]   ),
                            .south_write_cmd_vld_in     (north_write_cmd_vld_out_wire[i+1][j]   ),
                            .north_write_cmd_pld_in     (south_write_cmd_pld_out_wire[i-1][j]   ),
                            .north_write_cmd_vld_in     (south_write_cmd_vld_out_wire[i-1][j]   ),
                            .south_write_cmd_pld_out    (south_write_cmd_pld_out_wire[i][j]     ),
                            .south_write_cmd_vld_out    (south_write_cmd_vld_out_wire[i][j]     ),
                            .north_write_cmd_pld_out    (north_write_cmd_pld_out_wire[i][j]     ),
                            .north_write_cmd_vld_out    (north_write_cmd_vld_out_wire[i][j]     ),
                            .west_data_in_vld           (east_data_out_vld_wire[i][j-1]         ),//input west data_in
                            .west_data_in               (east_data_out_wire[i][j-1]             ),//input west data_in
                            .west_data_out_vld          (west_data_out_vld_wire[i][j]           ),//output west data_out
                            .west_data_out              (west_data_out_wire[i][j]               ),//output west data_out
                            .east_data_in_vld           (west_data_out_vld_wire[i][j+1]         ),
                            .east_data_in               (west_data_out_wire[i][j+1]             ),
                            .east_data_out_vld          (east_data_out_vld_wire[i][j]           ),
                            .east_data_out              (east_data_out_wire[i][j]               ),
                            .south_data_in_vld          (north_data_out_vld_wire[i+1][j]        ),
                            .south_data_in              (north_data_out_wire[i+1][j]            ),
                            .south_data_out_vld         (south_data_out_vld_wire[i][j]          ),
                            .south_data_out             (south_data_out_wire[i][j]              ),
                            .north_data_in_vld          (south_data_out_vld_wire[i-1][j]        ),
                            .north_data_in              (south_data_out_wire[i-1][j]            ),
                            .north_data_out_vld         (north_data_out_vld_wire[i][j]          ),
                            .north_data_out             (north_data_out_wire[i][j]              ));
                    end   
                end
            end    
        end
    endgenerate


generate
    for(genvar i=0;i<8;i=i+1)begin
        assign west_data_out[i].data[255:0]   = west_data_out_wireout[0][i].data;
        assign west_data_out[i].data[511:256] = west_data_out_wireout[1][i].data;
        assign west_data_out[i].data[767:512] = west_data_out_wireout[2][i].data;
        assign west_data_out[i].data[1023:768]= west_data_out_wireout[3][i].data;
        assign west_data_out[i].cmd_pld       = west_data_out_wireout[0][i].cmd_pld;
        assign west_data_out_vld[i]           = west_data_out_vld_wireout[0][i] ;

        assign east_data_out[i].data[255:0]   = east_data_out_wireout[0][i].data;
        assign east_data_out[i].data[511:256] = east_data_out_wireout[1][i].data;
        assign east_data_out[i].data[767:512] = east_data_out_wireout[2][i].data;
        assign east_data_out[i].data[1023:768]= east_data_out_wireout[3][i].data;
        assign east_data_out[i].cmd_pld       = east_data_out_wireout[0][i].cmd_pld;
        assign east_data_out_vld[i]           = east_data_out_vld_wireout[0][i] ;

        assign south_data_out[i].data[255:0]   = south_data_out_wireout[0][i].data;
        assign south_data_out[i].data[511:256] = south_data_out_wireout[1][i].data;
        assign south_data_out[i].data[767:512] = south_data_out_wireout[2][i].data;
        assign south_data_out[i].data[1023:768]= south_data_out_wireout[3][i].data;
        assign south_data_out[i].cmd_pld       = south_data_out_wireout[0][i].cmd_pld;
        assign south_data_out_vld[i]           = south_data_out_vld_wireout[0][i] ;

        assign north_data_out[i].data[255:0]   = north_data_out_wireout[0][i].data;
        assign north_data_out[i].data[511:256] = north_data_out_wireout[1][i].data;
        assign north_data_out[i].data[767:512] = north_data_out_wireout[2][i].data;
        assign north_data_out[i].data[1023:768]= north_data_out_wireout[3][i].data;
        assign north_data_out[i].cmd_pld       = north_data_out_wireout[0][i].cmd_pld;
        assign north_data_out_vld[i]           = north_data_out_vld_wireout[0][i] ;
    end
endgenerate

generate
    for(genvar i=0;i<8;i=i+1)begin
        assign east_read_cmd_pld_out  [i] = east_read_cmd_pld_out_wireout[0][i];
        assign east_read_cmd_vld_out  [i] = east_read_cmd_vld_out_wireout[0][i];
    end
endgenerate

endmodule