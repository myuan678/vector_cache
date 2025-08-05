module evictDB 
    import vector_cache_pkg::*;
    (
    input  logic                            clk,
    input  logic                            rst_n,

    output logic                            evict_clean     ,//ram_to_evict_db done signal
    output logic[MSHR_ENTRY_IDX_WIDTH-1:0]  evict_clean_idx ,

    input  arb_out_req_t                    evict_req_pld   ,
    input  logic                            evict_req_vld   ,
    output logic                            evict_req_rdy   ,

    input  group_data_pld_t                 ram_to_evdb_data_in,
    input  logic                            ram_to_evdb_data_vld,

    output logic                            alloc_vld       ,
    output [$clog2(EVDB_ENTRY_NUM/4)-1:0]   alloc_idx       ,
    input  logic                            alloc_rdy       ,

    output logic                            evict_to_ds_vld ,
    output evict_to_ds_pld_t                evict_to_ds_pld ,
    input  logic                            evict_to_ds_rdy
);

    logic [1023              :0]   data_in         ;
    logic                          db_mem_en       ;
    logic [1023              :0]   data_out        ;
    logic                          db_wr_en        ;
    logic [DB_ENTRY_IDX_WIDTH-1:0] db_addr         ; //entry_id
    logic [EVDB_ENTRY_NUM/4-1:0]   v_evdb_entry_idle;
    logic [EVDB_ENTRY_NUM/4-1:0]   v_evdb_entry_active;
    logic [EVDB_ENTRY_NUM/4-1:0]   v_evdb_entry_rdy;
    arb_out_req_t                  write_evdb_pld  ;
    logic                          write_evdb_vld  ;
    logic                          write_evdb_rdy  ;
    logic                          read_evdb_vld   ; //read evdb
    arb_out_req_t                  read_evdb_pld   ;
    logic                          read_evdb_rdy   ;
    arb_out_req_t                  read_evdb_pld_d ;
    logic                          evdb_entry_release;    
    logic [DB_ENTRY_IDX_WIDTH-3:0] evdb_entry_release_idx;

    //rob arbiter evict_req_vld
    //-----------------DELAY----------------------------------------------------------------
    logic [EVICT_DOWN_DELAY-1  :0] shift_reg;
    arb_out_req_t                  delay_pld_reg[EVICT_DOWN_DELAY-1:0];
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shift_reg <= {EVICT_DOWN_DELAY{1'b0}};
        else begin
            shift_reg <= {shift_reg[EVICT_DOWN_DELAY-2:0], evict_req_vld};
        end
    end
    
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<EVICT_DOWN_DELAY;i=i+1)begin
                delay_pld_reg[i] <= 'b0;
            end
        end
        else begin
            delay_pld_reg[0] <= evict_req_pld;
            for(int i=1;i<EVICT_DOWN_DELAY;i=i+1)begin
                delay_pld_reg[i] <= delay_pld_reg[i-1];
            end
        end
    end

    //从发起evict_rd,经过读sram需要的延迟后，write_evdb_vld
    assign write_evdb_vld = shift_reg[READ_SRAM_DELAY-1]    ; 
    assign write_evdb_pld = delay_pld_reg[READ_SRAM_DELAY-1];//addr

    assign read_evdb_vld  = shift_reg[EVICT_DOWN_DELAY-1]; //evict_down
    assign read_evdb_pld  = delay_pld_reg[EVICT_DOWN_DELAY-1];
    //===============================================================================

    assign evict_clean    = write_evdb_vld && write_evdb_rdy && write_evdb_pld.last;
    assign evict_clean_idx= delay_pld_reg[EVICT_CLEAN_DELAY-1].rob_entry_id;
    
    //arb，write_evdb_vld写优先 
    assign db_mem_en      = write_evdb_vld | read_evdb_vld;
    assign db_addr        = write_evdb_vld ? write_evdb_pld.db_entry_id : read_evdb_pld.db_entry_id;
    assign db_wr_en       = write_evdb_vld ? 1'b0 : (read_evdb_vld ? 1'b1: 1'b0);
    assign data_in        = ram_to_evdb_data_in             ;
    assign write_evdb_rdy = write_evdb_vld ? 1'b1 : 1'b0    ;
    assign read_evdb_rdy  = write_evdb_vld ? 1'b0 : 1'b1    ;
    

    



    //TODO：打一拍好像
    always_ff@(posedge clk )begin
        read_evdb_pld_d <= read_evdb_pld ;
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                      evict_to_ds_vld <= 1'b0;
        else if(db_mem_en && ~db_wr_en) evict_to_ds_vld <= 1'b1;
    end
    assign evict_to_ds_pld.data        = data_out;
    assign evict_to_ds_pld.db_entry_id = read_evdb_pld_d.db_entry_id;
    assign evict_to_ds_pld.rob_entry_id= read_evdb_pld_d.rob_entry_id;
    assign evict_to_ds_pld.sideband    = read_evdb_pld_d.sideband;
    assign evict_to_ds_pld.txnid       = read_evdb_pld_d.txnid;
    assign evict_to_ds_pld.addr        = {read_evdb_pld_d.tag,read_evdb_pld_d.index,read_evdb_pld_d.offset};
    assign evict_req_rdy               = read_evdb_rdy;//TODO



    logic [1:0] rd_evdb_counter;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                  rd_evdb_counter <= 2'd0;
        else if(evict_to_ds_vld && evict_to_ds_rdy) rd_evdb_counter <= rd_evdb_counter +2'd1;
        else if(evict_to_ds_pld.last)               rd_evdb_counter <= 2'd0;
        else                                        rd_evdb_counter <= rd_evdb_counter;
    end
    assign evdb_entry_release     = evict_to_ds_vld && evict_to_ds_rdy && evict_to_ds_pld.last;
    assign evdb_entry_release_idx = evict_to_ds_pld.db_entry_id[DB_ENTRY_IDX_WIDTH-1:2];

   
    //always_ff@(posedge clk or negedge rst_n) begin
    //    if(!rst_n)                          v_evdb_entry_vld                         <= 'hff;
    //    else if(alloc_vld && alloc_rdy)     v_evdb_entry_vld[alloc_idx]              <= 1'b0;
    //    else if(evdb_entry_release)         v_evdb_entry_vld[evdb_entry_release_idx] <= 1'b1;
    //    else                                v_evdb_entry_vld                         <= v_evdb_entry_vld;
    //end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<RW_DB_ENTRY_NUM;i=i+1)begin
                v_evdb_entry_idle[i]  <= 1'b1;
            end
        end                                    
        else begin
            for(int i=0;i<RW_DB_ENTRY_NUM;i=i+1)begin
                if(v_evdb_entry_idle[i] && v_evdb_entry_rdy[i])begin
                    v_evdb_entry_idle[i] <= 1'b0;
                end
            end    
            if(read_evdb_vld && read_evdb_rdy && v_evdb_entry_active[read_evdb_pld.db_entry_id] )begin
                v_evdb_entry_idle[read_evdb_pld.db_entry_id]<= 1'b1;
            end
        end
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            for(int i=0;i<RW_DB_ENTRY_NUM;i=i+1)begin
                v_evdb_entry_active[i] <= 'b0;
            end
        end
        else begin
            if(write_evdb_vld)begin
                v_evdb_entry_active[write_evdb_pld.db_entry_id] <= 'b1;
            end
            else if(read_evdb_vld && read_evdb_rdy)begin
                v_evdb_entry_active[read_evdb_pld.db_entry_id] <= 'b0;
            end               
        end                              
    end

    pre_alloc_one #(
        .ENTRY_NUM     (EVDB_ENTRY_NUM/4        ),
        .ENTRY_ID_WIDTH($clog2(EVDB_ENTRY_NUM/4))
    ) u_pre_alloc_evdb (
        .clk        (clk             ),
        .rst_n      (rst_n           ),
        .v_in_vld   (v_evdb_entry_idle),
        .v_in_rdy   (v_evdb_entry_rdy),
        .out_vld    (alloc_vld       ),
        .out_rdy    (alloc_rdy       ),
        .out_index  (alloc_idx       )
    );

    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(RW_DB_ENTRY_NUM)),
        .DATA_WIDTH  (DATA_WIDTH)
    ) u_evict_data_buffer (
        .clk    (clk        ),
        .en     (db_mem_en  ),
        .wr_en  (db_wr_en   ),
        .addr   (db_addr    ),
        .wr_data(data_in    ),
        .rd_data(data_out   ));



endmodule