module vec_cache_rdb_agent 
    import vector_cache_pkg::*;
    #( 
        parameter integer unsigned READ_SRAM_DELAY    = 10//read_sram delay,data to rdb
    )
    (
    input  logic                            clk                 ,
    input  logic                            rst_n               ,
    output logic                            to_us_done          , //means rob entry release
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0] to_us_done_idx      ,

    input  logic                            dataram_rd_vld      ,
    input  arb_out_req_t                    dataram_rd_pld      ,
    output logic                            dataram_rd_rdy      ,
    input  logic                            RDB_rdy             ,
    output logic                            rdb_nfull           ,

    input  group_data_pld_t                 ram_to_rdb_data_in  ,
    input  logic                            ram_to_rdb_data_vld ,
    output us_data_pld_t                    rdb_to_us_data_pld  ,
    output logic                            rdb_to_us_data_vld  
    
);

    logic                                   read_rdb_vld        ; 
    rw_rdb_pld_t                            read_rdb_pld        ;
    logic                                   read_rdb_vld_d      ; 
    rw_rdb_pld_t                            read_rdb_pld_d      ;
    logic                                   read_rdb_rdy        ; //应该是arb发出一个读请求，可以确定N拍之后数据进入到RDB，所以把rd_req delayN拍后作为read_rdb_vld
    logic                                   ram_write_rdb_vld   ; //write RDB
    rw_rdb_pld_t                            ram_write_rdb_pld   ;
    logic                                   ram_write_rdb_rdy   ;
    logic [RW_DB_ENTRY_NUM/2-1          :0] v_rdb_entry_idle_0  ;
    logic [RW_DB_ENTRY_NUM/2-1          :0] v_rdb_entry_idle_1  ;
    logic [RW_DB_ENTRY_NUM/2-1          :0] v_rdb_entry_active_0;
    logic [RW_DB_ENTRY_NUM/2-1          :0] v_rdb_entry_active_1;
    logic [RW_DB_ENTRY_NUM-1            :0] v_rdb_rdy           ;
    logic [RW_DB_ENTRY_NUM/2-1          :0] v_rdb_rdy_0         ;
    logic [RW_DB_ENTRY_NUM/2-1          :0] v_rdb_rdy_1         ;
    logic [DB_ENTRY_IDX_WIDTH-1         :0] idle_cnt            ;
    logic                                   alloc_vld_0         ;
    logic [$clog2(RW_DB_ENTRY_NUM/2)-1  :0] alloc_idx_0         ;
    logic                                   alloc_rdy_0         ;
    logic                                   alloc_vld_1         ;
    logic [$clog2(RW_DB_ENTRY_NUM/2)-1  :0] alloc_idx_1         ;
    logic                                   alloc_rdy_1         ;

    logic                                   rdb_sel             ;
    logic                                   rdb_sel_1d          ;
    logic                                   rdb_sel_2d          ;
    logic                                   rdb0_mem_en         ;
    logic                                   rdb0_wr_en          ;       
    logic [$clog2(RW_DB_ENTRY_NUM/2)-1  :0] rdb0_addr           ;
    logic [1023                         :0] rdb0_data_in        ;
    logic [1023                         :0] rdb0_data_out       ;

    logic                                   rdb1_mem_en         ;
    logic                                   rdb1_wr_en          ;       
    logic [$clog2(RW_DB_ENTRY_NUM/2)-1  :0] rdb1_addr           ;
    logic [1023                         :0] rdb1_data_in        ;
    logic [1023                         :0] rdb1_data_out       ;
    logic [TO_US_DONE_DELAY-1           :0] shift_reg           ;
    arb_out_req_t                           delay_pld_reg[TO_US_DONE_DELAY-1:0];


    //==============================================================================
    //delay
    //==============================================================================
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) shift_reg <= {TO_US_DONE_DELAY{1'b0}};
        else        shift_reg <= {shift_reg[TO_US_DONE_DELAY-2:0], dataram_rd_vld};
    end
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

    //agent 内部产生读完sram 数据要写入rdb的vld请求 “写RDB”
    //1.访问sram的延迟，数据需要写入rdb
    assign ram_write_rdb_vld              = shift_reg[READ_SRAM_DELAY-1];    //dataram_rd_vld加上访问sram的延迟
    assign ram_write_rdb_pld.rob_entry_id = delay_pld_reg[READ_SRAM_DELAY-1].rob_entry_id;
    assign ram_write_rdb_pld.db_entry_id  = rdb_sel ? alloc_idx_0 : alloc_idx_1;
    assign ram_write_rdb_pld.txn_id       = delay_pld_reg[READ_SRAM_DELAY-1].txn_id;
    assign ram_write_rdb_pld.sideband     = delay_pld_reg[READ_SRAM_DELAY-1].sideband;

    //agent内部产生读rdb的请求  “读RDB”
    //2. 数据已经写入到RDB，可以读出发给US
    //write rdb 请求的下一拍 read_rdb
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                              read_rdb_vld <= 1'b0;
        else if(ram_write_rdb_vld)              read_rdb_vld <= 1'b1;
        else if(read_rdb_vld && read_rdb_rdy)   read_rdb_vld <= 1'b0;
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)       read_rdb_vld_d <= 1'b0;
        else             read_rdb_vld_d <= read_rdb_vld;
    end

    always_ff@(posedge clk)begin
        read_rdb_pld    <= ram_write_rdb_pld;
        read_rdb_pld_d  <= read_rdb_pld;
    end
   

    //3.再延迟,data to US, to_us_done
    //change
    //assign to_us_done     = shift_reg[TO_US_DONE_DELAY-1];
    //assign to_us_done_idx = delay_pld_reg[TO_US_DONE_DELAY-1].rob_entry_id;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            to_us_done     <= 'b0;
            to_us_done_idx <= 'b0;
        end
        else if(read_rdb_vld && read_rdb_rdy)begin
            to_us_done     <= 1'b1;
            to_us_done_idx <= read_rdb_pld.rob_entry_id;
        end
        else begin
            to_us_done     <= 'b0;
            to_us_done_idx <= 'b0;
        end
    end

    //==============================================================================
    //arbiter  (写优先)
    //==============================================================================
    assign rdb0_mem_en       = (~rdb_sel  && ram_write_rdb_vld) || (~rdb_sel_1d && read_rdb_vld);
    assign rdb0_wr_en        = ~rdb_sel && ram_write_rdb_vld && ram_to_rdb_data_vld;
    assign rdb0_addr         = rdb0_wr_en ? ram_write_rdb_pld.db_entry_id : read_rdb_pld.db_entry_id;
    assign rdb0_data_in      = ram_to_rdb_data_in.data ;
    
    assign rdb1_mem_en       = (rdb_sel  && ram_write_rdb_vld) || (rdb_sel_1d && read_rdb_vld);
    assign rdb1_wr_en        = rdb_sel && ram_write_rdb_vld && ram_to_rdb_data_vld;
    assign rdb1_addr         = rdb1_wr_en ? ram_write_rdb_pld.db_entry_id : read_rdb_pld.db_entry_id;
    assign rdb1_data_in      = ram_to_rdb_data_in.data ;

    assign ram_write_rdb_rdy = RDB_rdy && ram_write_rdb_vld && ram_to_rdb_data_vld;
    assign read_rdb_rdy      = RDB_rdy && (~ram_write_rdb_vld);
    assign dataram_rd_rdy    = RDB_rdy ;

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                      rdb_sel <= 1'b0;
        else if(ram_write_rdb_vld && ram_write_rdb_rdy) rdb_sel <= ~rdb_sel; 
    end
    always_ff@(posedge clk )begin
        rdb_sel_1d <= rdb_sel;
        rdb_sel_2d <= rdb_sel_1d;
    end

    assign alloc_rdy_0 = rdb_sel  && ram_write_rdb_vld && ram_write_rdb_rdy;
    assign alloc_rdy_1 = ~rdb_sel && ram_write_rdb_vld && ram_write_rdb_rdy;

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<RW_DB_ENTRY_NUM/2;i=i+1)begin
                v_rdb_entry_idle_0[i]  <= 1'b1;
            end
        end                                    
        else begin
            for(int i=0;i<RW_DB_ENTRY_NUM/2;i=i+1)begin
                if(v_rdb_entry_idle_0[i] && v_rdb_rdy_0[i])begin
                    v_rdb_entry_idle_0[i] <= 1'b0;
                end
            end    
            //if(read_rdb_vld && read_rdb_rdy && v_rdb_entry_active_0[read_rdb_pld.db_entry_id] )begin
            if(~rdb_sel_1d && read_rdb_vld && read_rdb_rdy && v_rdb_entry_active_0[read_rdb_pld.db_entry_id] )begin
                v_rdb_entry_idle_0[read_rdb_pld.db_entry_id]<= 1'b1;
            end
        end
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<RW_DB_ENTRY_NUM/2;i=i+1)begin
                v_rdb_entry_idle_1[i]  <= 1'b1;
            end
        end                                    
        else begin
            for(int i=0;i<RW_DB_ENTRY_NUM/2;i=i+1)begin
                if(v_rdb_entry_idle_1[i] && v_rdb_rdy_1[i])begin
                    v_rdb_entry_idle_1[i] <= 1'b0;
                end
            end    
            if(rdb_sel_1d && read_rdb_vld && read_rdb_rdy && v_rdb_entry_active_1[read_rdb_pld.db_entry_id] )begin
                v_rdb_entry_idle_1[read_rdb_pld.db_entry_id]<= 1'b1;
            end
        end
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            for(int i=0;i<RW_DB_ENTRY_NUM/2;i=i+1)begin
                v_rdb_entry_active_0[i] <= 'b0;
            end
        end
        else begin
            if(~rdb_sel && ram_write_rdb_vld)begin
                v_rdb_entry_active_0[ram_write_rdb_pld.db_entry_id] <= 'b1;
            end
            else if(~rdb_sel_1d && read_rdb_vld && read_rdb_rdy)begin
                v_rdb_entry_active_0[read_rdb_pld.db_entry_id] <= 'b0;
            end               
        end                              
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            for(int i=0;i<RW_DB_ENTRY_NUM/2;i=i+1)begin
                v_rdb_entry_active_1[i] <= 'b0;
            end
        end
        else begin
            if(rdb_sel && ram_write_rdb_vld)begin
                v_rdb_entry_active_1[ram_write_rdb_pld.db_entry_id] <= 'b1;
            end
            else if(rdb_sel_1d && read_rdb_vld && read_rdb_rdy)begin
                v_rdb_entry_active_1[read_rdb_pld.db_entry_id] <= 'b0;
            end               
        end                              
    end

    vec_cache_pre_alloc_one #(
        .ENTRY_NUM      (RW_DB_ENTRY_NUM/2        ),
        .ENTRY_ID_WIDTH ($clog2(RW_DB_ENTRY_NUM/2))
    ) u_pre_alloc_rdb0 (
        .clk            (clk               ),
        .rst_n          (rst_n             ),
        .v_in_vld       (v_rdb_entry_idle_0),
        .v_in_rdy       (v_rdb_rdy_0       ),
        .out_vld        (alloc_vld_0       ),
        .out_rdy        (alloc_rdy_0       ),
        .out_index      (alloc_idx_0       ));
    vec_cache_pre_alloc_one #(
        .ENTRY_NUM      (RW_DB_ENTRY_NUM/2        ),
        .ENTRY_ID_WIDTH ($clog2(RW_DB_ENTRY_NUM/2))
    ) u_pre_alloc_rdb1 (
        .clk            (clk               ),
        .rst_n          (rst_n             ),
        .v_in_vld       (v_rdb_entry_idle_1),
        .v_in_rdy       (v_rdb_rdy_1       ),
        .out_vld        (alloc_vld_1       ),
        .out_rdy        (alloc_rdy_1       ),
        .out_index      (alloc_idx_1       ));

    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(RW_DB_ENTRY_NUM/2)),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_read_data_buffer_0 (
        .clk        (clk            ),
        .en         (rdb0_mem_en    ),
        .wr_en      (rdb0_wr_en     ),
        .addr       (rdb0_addr      ),
        .wr_data    (rdb0_data_in   ),
        .rd_data    (rdb0_data_out  )
    );
    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(RW_DB_ENTRY_NUM/2)),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_read_data_buffer_1 (
        .clk        (clk            ),
        .en         (rdb1_mem_en    ),
        .wr_en      (rdb1_wr_en     ),
        .addr       (rdb1_addr      ),
        .wr_data    (rdb1_data_in   ),
        .rd_data    (rdb1_data_out  )
    );

    always_comb begin
        idle_cnt = 'b0;
        for (int i = 0; i < RW_DB_ENTRY_NUM/2; i=i+1) begin
            if(v_rdb_entry_idle_0[i])begin
                idle_cnt = idle_cnt + 1'b1;
            end
        end
        rdb_nfull = (idle_cnt >= READ_SRAM_DELAY/2);
    end
    
    //to us data
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                              rdb_to_us_data_vld <= 1'b0;
        else if(read_rdb_vld && read_rdb_rdy)   rdb_to_us_data_vld <= 1'b1;
        else                                    rdb_to_us_data_vld <= 1'b0;                                            
    end
    assign rdb_to_us_data_pld.data         = rdb_sel_2d ? rdb1_data_out : rdb0_data_out;
    assign rdb_to_us_data_pld.txn_id       = read_rdb_pld_d.txn_id      ;
    assign rdb_to_us_data_pld.rob_entry_id = read_rdb_pld_d.rob_entry_id;
    assign rdb_to_us_data_pld.sideband     = read_rdb_pld_d.sideband    ;

    


endmodule