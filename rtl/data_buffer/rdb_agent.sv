module rdb_agent 
    import vector_cache_pkg::*;
    (
    input  logic                            clk             ,
    input  logic                            rst_n           ,
    output logic                            to_us_done      , //means rob entry release
    output logic [DB_ENTRY_IDX_WIDTH-1:0]   to_us_done_idx  ,

    input  logic                            dataram_rd_vld  ,
    input  arb_out_req_t                    dataram_rd_pld  ,
    output logic                            dataram_rd_rdy  ,

    output logic                            alloc_vld       ,
    output logic [DB_ENTRY_IDX_WIDTH-1:0]   alloc_idx       ,
    input  logic                            alloc_rdy       ,
    input  logic                            RDB_rdy         ,

    output logic                            rdb_mem_en      ,
    output logic                            rdb_wr_en       ,
    output read_rdb_addr_t                  rdb_addr
    
);

    logic                       read_rdb_vld        ; //
    arb_out_req_t               read_rdb_pld        ; //rdb entry id 作为地址，并带着其他的id，txnid/sideband
    logic                       read_rdb_rdy        ;  //应该是arb发出一个读请求，可以确定N拍之后数据进入到RDB，所以把rd_req delayN拍后作为read_rdb_vld
    logic                       ram_write_rdb_vld   ;//write RDB
    arb_out_req_t               ram_write_rdb_pld   ;
    logic                       ram_write_rdb_rdy   ;
    logic [RW_DB_ENTRY_NUM-1:0] v_rdb_entry_vld     ;

//-----------------DELAY----------------------------------------------------------------
    logic [TO_US_DONE_DELAY-1:0] shift_reg   ;
    arb_out_req_t                delay_pld_reg[TO_US_DONE_DELAY-1:0];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {TO_US_DONE_DELAY{1'b0}};
        else
            shift_reg <= {shift_reg[TO_US_DONE_DELAY-2:0], dataram_rd_vld};
    end
    //rd_pld的延迟
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<TO_US_DONE_DELAY;i=i+1)begin
                delay_pld_reg[i] <= 'b0;
            end
        end
        else begin
            delay_pld_reg[0] <= dataram_rd_pld;
            for(int i=1;i<TO_US_DONE_DELAY;i=i+1)begin
                delay_pld_reg[i] <= delay_pld_reg[i-1];
            end
        end
    end
    //-----------------------------------------------------------------------------------

    //agent 内部产生读完sram 数据要写入rdb的vld请求 “写RDB”
    //1.访问sram的延迟，数据需要写入rdb
    assign ram_write_rdb_vld = shift_reg[READ_SRAM_DELAY-1];//dataram_rd_vld加上访问sram的延迟，认为数据可以写入到RDB了
    assign ram_write_rdb_pld = delay_pld_reg[READ_SRAM_DELAY-1];//addr

     //agent内部产生读rdb的请求  “读RDB”
    //2. 数据已经写入到RDB，可以读出发给US
    assign read_rdb_vld   = shift_reg[RDB_DATA_RDY_DELAY-1];
    assign read_rdb_pld   = delay_pld_reg[RDB_DATA_RDY_DELAY-1];
    
    //3.再延迟，数据已经发给US，产生to_us_done，//TODO:
    assign to_us_done     = shift_reg[TO_US_DONE_DELAY-1];
    assign to_us_done_idx = delay_pld_reg[TO_US_DONE_DELAY-1].rob_entry_id;

//----------------------------------------------------------------------------------------

    //读写RDB的arbiter  写优先(ram_to_rdb_vld ：read_rdb_vld);
    assign rdb_mem_en            = ram_write_rdb_vld | read_rdb_vld  ;
    assign rdb_wr_en             = ram_write_rdb_vld ? 1'b1 : 1'b0   ;
    assign rdb_addr.db_entry_id  = ram_write_rdb_vld ? ram_write_rdb_pld.db_entry_id : read_rdb_pld.db_entry_id; //addr 确定等于arb出的read请求的rdb id
    assign rdb_addr.txnid        = ram_write_rdb_vld ? ram_write_rdb_pld.txnid : read_rdb_pld.txnid;
    assign rdb_addr.rob_entry_id = ram_write_rdb_vld ? ram_write_rdb_pld.rob_entry_id : read_rdb_pld.rob_entry_id;
    assign ram_write_rdb_rdy     = RDB_rdy && ram_write_rdb_vld;
    assign read_rdb_rdy          = RDB_rdy && read_rdb_vld && (~ram_write_rdb_vld);
    assign dataram_rd_rdy        = RDB_rdy && ~ram_write_rdb_vld;//

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            v_rdb_entry_vld = 'b1;
        end
        else begin
            if(rdb_mem_en && rdb_wr_en)begin
                v_rdb_entry_vld[rdb_addr] <= 1'b0;
            end
            else if(rdb_mem_en && rdb_wr_en==1'b0)begin
                v_rdb_entry_vld[rdb_addr] <= 1'b1;
            end
            else begin
                v_rdb_entry_vld <= v_rdb_entry_vld;
            end
        end
    end

    pre_alloc_one #(
        .ENTRY_NUM      (RW_DB_ENTRY_NUM   ),
        .ENTRY_ID_WIDTH (DB_ENTRY_IDX_WIDTH)
    ) u_pre_alloc_rdb (
        .clk        (clk             ),
        .rst_n      (rst_n           ),
        .v_in_vld   (v_rdb_entry_vld ),
        .v_in_rdy   (                ),
        .out_vld    (alloc_vld       ),
        .out_rdy    (alloc_rdy       ),
        .out_index  (alloc_idx       )
    );

    


endmodule