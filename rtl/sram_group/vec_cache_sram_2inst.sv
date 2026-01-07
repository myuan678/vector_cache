module vec_cache_sram_2inst
    import vector_cache_pkg::*;
    (
    input  logic                clk         ,
    input  logic                rst_n       ,

    input  logic                read_vld_0  ,
    input  sram_inst_cmd_t      read_cmd_0  ,
    input  logic                write_vld_0 ,
    input  sram_inst_cmd_t      write_cmd_0 ,
    input  logic [31     :0]    wr_data_0   ,

    input  logic                read_vld_1  ,
    input  sram_inst_cmd_t      read_cmd_1  ,
    input  logic                write_vld_1 ,
    input  sram_inst_cmd_t      write_cmd_1 ,
    input  logic [31     :0]    wr_data_1   ,

    output logic [31     :0]    rd_data_0   ,
    output logic [31     :0]    rd_data_1

);

    logic                 read_sel        ;  //cross sel
    logic                 read_sel_d      ;  //cross sel delay
    logic                 write_sel       ;
    logic [31         :0] sram0_wr_data   ;
    logic [31         :0] sram0_rd_data   ;
    logic                 sram0_read_vld  ;
    sram_inst_cmd_t       sram0_read_cmd  ;
    logic                 sram0_write_vld ;
    sram_inst_cmd_t       sram0_write_cmd ;

    logic [31         :0] sram1_wr_data   ;
    logic [31         :0] sram1_rd_data   ;
    logic                 sram1_read_vld  ;
    sram_inst_cmd_t       sram1_read_cmd  ;
    logic                 sram1_write_vld ;
    sram_inst_cmd_t       sram1_write_cmd ;

    assign read_sel  = read_cmd_0.dest_ram_id.channel_id;
    assign write_sel = write_cmd_0.dest_ram_id.channel_id;
    

    always_comb begin
        sram0_read_cmd = read_cmd_0  ;
        sram0_read_vld = read_vld_0  ;
        sram1_read_cmd = read_cmd_1  ;
        sram1_read_vld = read_vld_1  ;
    end

    always_comb begin
        sram0_write_cmd = write_cmd_0 ;
        sram0_wr_data   = wr_data_0   ;
        sram0_write_vld = write_vld_0 ;

        sram1_write_cmd = write_cmd_1 ;
        sram1_wr_data   = wr_data_1   ;
        sram1_write_vld = write_vld_1 ;
    end

    always_comb begin
        rd_data_0 = sram0_rd_data;
        rd_data_1 = sram1_rd_data;
    end
    
    vec_cache_sram_inst u_sram_inst_0 (
        .clk      (clk              ),
        .rst_n    (rst_n            ),
        .read_vld (sram0_read_vld   ),
        .read_cmd (sram0_read_cmd   ),
        .write_vld(sram0_write_vld  ),
        .write_cmd(sram0_write_cmd  ),
        .wr_data  (sram0_wr_data    ),
        .rd_data  (sram0_rd_data    )
    );
    vec_cache_sram_inst u_sram_inst_1 (
        .clk      (clk              ),
        .rst_n    (rst_n            ),
        .read_vld (sram1_read_vld   ),
        .read_cmd (sram1_read_cmd   ),
        .write_vld(sram1_write_vld  ),
        .write_cmd(sram1_write_cmd  ),
        .wr_data  (sram1_wr_data    ),
        .rd_data  (sram1_rd_data    )
    );
   
endmodule
