module vec_cache_linefillDB 
    import vector_cache_pkg::*;
    #( 
        parameter integer unsigned ARB_TO_LFDB_DELAY    = 5
    )(
    input  logic                                clk                     ,
    input  logic                                rst_n                   ,

    output logic                                alloc_vld               ,
    output logic [$clog2(LFDB_ENTRY_NUM/4)-1:0] alloc_idx               ,
    input  logic                                alloc_rdy               ,
    
    input  logic                                ds_to_lfdb_vld          ,
    input  ds_to_lfdb_pld_t                     ds_to_lfdb_pld          , //addr + data
    output logic                                ds_to_lfdb_rdy          ,
    
    input  logic                                lfdb_rdreq_vld          ,
    input  arb_out_req_t                        lfdb_rdreq_pld          , //read lfdb ; addr
    output logic                                lfdb_rdreq_rdy          ,
    
    output logic                                lfdb_to_ram_vld         ,
    output write_ram_pld_t                      lfdb_to_ram_pld         ,
    input  logic                                lfdb_to_ram_rdy         ,

    output logic                                ds_txreq_done           ,//to rob
    output logic [MSHR_ENTRY_IDX_WIDTH-1   :0]  ds_txreq_done_idx       ,
    output logic [$clog2(LFDB_ENTRY_NUM/4)-1:0] ds_txreq_done_db_id     ,
    output logic                                linefill_to_ram_done    ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0]     linefill_to_ram_done_idx
);

    logic [1023                     :0]         data_in                 ;
    logic [1023                     :0]         data_out                ;
    logic                                       db_mem_en               ;
    logic                                       db_wr_en                ;
    logic [CACHE_LINE_SIZE-1        :0]         db_byte_en              ;
    logic [$clog2(LFDB_ENTRY_NUM)-1 :0]         db_addr                 ; //entry_id
    logic [LFDB_ENTRY_NUM/4-1       :0]         v_lfdb_entry_idle       ;
    logic [LFDB_ENTRY_NUM/4-1       :0]         v_lfdb_entry_active     ;
    logic [LFDB_ENTRY_NUM/4-1       :0]         v_lfdb_rdy              ;
    logic                                       read_lfdb_vld           ;
    read_lfdb_pld_t                             read_lfdb_pld           ;
    logic                                       read_lfdb_vld_d         ;
    read_lfdb_pld_t                             read_lfdb_pld_d         ;


    logic           grant_lfdb_rdreq_vld;
    arb_out_req_t   grant_lfdb_rdreq_pld;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            grant_lfdb_rdreq_vld <= 1'b0;
            grant_lfdb_rdreq_pld <= 'b0;
        end
        else begin
            grant_lfdb_rdreq_vld <= lfdb_rdreq_vld && lfdb_rdreq_rdy ;
            grant_lfdb_rdreq_pld <= lfdb_rdreq_pld;
        end
    end
    
//-----------------DELAY----------------------------------------------------------------
    logic [LF_DONE_DELAY-1     :0] delay_shift_reg;
    arb_out_req_t                  delay_pld_reg[LF_DONE_DELAY-1:0];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)    delay_shift_reg <= {LF_DONE_DELAY{1'b0}};
        //else           delay_shift_reg <= {delay_shift_reg[LF_DONE_DELAY-2:0], grant_lfdb_rdreq_vld};
        else           delay_shift_reg <= {delay_shift_reg[LF_DONE_DELAY-2:0], lfdb_rdreq_vld};
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<LF_DONE_DELAY;i=i+1)begin
                delay_pld_reg[i] <= 'b0;
            end
        end
        else begin
            //delay_pld_reg[0] <= grant_lfdb_rdreq_pld;
            delay_pld_reg[0] <= lfdb_rdreq_pld;
            for(int i=1;i<LF_DONE_DELAY;i=i+1)begin
                delay_pld_reg[i] <= delay_pld_reg[i-1];
            end
        end
    end
//-----------------------------------------------------------------------------------------------------


    logic [1:0] wr_lf_counter;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)                                  wr_lf_counter <= 2'd0;
        else if(ds_to_lfdb_vld && ds_to_lfdb_rdy)   wr_lf_counter <= wr_lf_counter +2'd1;
        else if(ds_to_lfdb_pld.last)                wr_lf_counter <= 2'd0;
        else                                        wr_lf_counter <= wr_lf_counter;
    end
    
//-----------read_lfdb 优先，读优先-----------------------------------------
    logic           sending;        // 是否正在发起连续4拍请求
    logic [1:0]     req_cnt;        // 当前发第几个请求
    arb_out_req_t   hold_req_pld;
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            sending <= 'b0;
            req_cnt <= 2'd0;
            hold_req_pld <= 'b0;
        end
        else begin
            if(!sending && delay_shift_reg[ARB_TO_LFDB_DELAY-1])begin//ARB_TO_LFDB_DELAY-1拍后开始发送,ds_txreq_done
                sending <= 1'b1;
                req_cnt <= 2'd0;
                hold_req_pld <= delay_pld_reg[ARB_TO_LFDB_DELAY-1];
            end
            else if(sending)begin
                if(req_cnt==2'd3)begin
                    sending <= 1'b0;
                    req_cnt <= 2'd0;
                end
                else begin
                    //sending <= 1'b1;
                    req_cnt <= req_cnt + 2'd1;
                end
            end
        end
    end
    assign read_lfdb_vld             = sending;
    assign read_lfdb_pld.req_cmd_pld = hold_req_pld;
    assign read_lfdb_pld.req_num     = req_cnt;
    assign read_lfdb_pld.last        = (req_cnt == 2'd3) && sending;
   
    assign data_in        = ds_to_lfdb_pld.data;
    assign db_mem_en      = read_lfdb_vld | ds_to_lfdb_vld;
    assign db_wr_en       = read_lfdb_vld ? 1'b0 : (ds_to_lfdb_vld ? 1'b1: 1'b0);
    assign lfdb_rdreq_rdy = read_lfdb_vld  ;

    assign ds_to_lfdb_rdy = ~read_lfdb_vld ;
    assign db_addr        = read_lfdb_vld ? {read_lfdb_pld.req_cmd_pld.db_entry_id,read_lfdb_pld.req_num} : {ds_to_lfdb_pld.linefill_cmd.db_entry_id,wr_lf_counter};


    //read DB，所以read cmd要打一拍
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            read_lfdb_vld_d <= 'b0;
            read_lfdb_pld_d <= 'b0;
        end
        else if(read_lfdb_vld)begin
            read_lfdb_vld_d <= read_lfdb_vld;
            read_lfdb_pld_d <= read_lfdb_pld;
        end
        else begin
            read_lfdb_vld_d <= 'b0;
            read_lfdb_pld_d <= 'b0;
        end
    end
    assign lfdb_to_ram_pld.data.data                  = data_out;  
    assign lfdb_to_ram_pld.data.cmd_pld.addr          = {read_lfdb_pld_d.req_cmd_pld.index[INDEX_WIDTH-4:0],read_lfdb_pld_d.req_cmd_pld.way};
    assign lfdb_to_ram_pld.data.cmd_pld.txnid         = read_lfdb_pld_d.req_cmd_pld.txnid;
    assign lfdb_to_ram_pld.data.cmd_pld.dest_ram_id   = {read_lfdb_pld_d.req_cmd_pld.hash_id, read_lfdb_pld_d.req_cmd_pld.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
    assign lfdb_to_ram_pld.data.cmd_pld.mode          = read_lfdb_pld_d.req_cmd_pld.txnid.mode;
    assign lfdb_to_ram_pld.data.cmd_pld.byte_sel      = read_lfdb_pld_d.req_cmd_pld.txnid.byte_sel;
    assign lfdb_to_ram_pld.data.cmd_pld.opcode        = read_lfdb_pld_d.req_cmd_pld.opcode;
    assign lfdb_to_ram_pld.write_cmd.req_cmd_pld      = read_lfdb_pld_d.req_cmd_pld;
    assign lfdb_to_ram_pld.write_cmd.last             = read_lfdb_pld_d.last;
    assign lfdb_to_ram_pld.write_cmd.req_num          = read_lfdb_pld_d.req_num;
    assign lfdb_to_ram_vld                            = read_lfdb_vld_d;



    //ds_txreq_done
    //arb出的linefill_wrreq，读LFDB
    
    assign ds_txreq_done       = ds_to_lfdb_rdy && ds_to_lfdb_vld && ds_to_lfdb_pld.last;
    assign ds_txreq_done_idx   = ds_to_lfdb_pld.linefill_cmd.rob_entry_id;
    assign ds_txreq_done_db_id = ds_to_lfdb_pld.linefill_cmd.db_entry_id;

    //always_ff@(posedge clk or negedge rst_n)begin
    //    if(!rst_n)begin
    //        linefill_to_ram_done     <= 'b0;
    //        linefill_to_ram_done_idx <= 'b0;
    //    end
    //    else begin
    //        linefill_to_ram_done     <= lfdb_to_ram_vld && lfdb_to_ram_rdy && read_lfdb_pld.last;
    //        linefill_to_ram_done_idx <= read_lfdb_pld.req_cmd_pld.rob_entry_id;
    //    end
    //end
    //change

    assign linefill_to_ram_done = delay_shift_reg[25];
    assign linefill_to_ram_done_idx = delay_pld_reg[25].rob_entry_id;

    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(LFDB_ENTRY_NUM)),
        .DATA_WIDTH  (1024                  )//linefillDB width 
    ) u_lf_data_buffer (
        .clk    (clk        ),
        .en     (db_mem_en  ),
        .wr_en  (db_wr_en   ),
        .addr   (db_addr    ),
        .wr_data(data_in    ),
        .rd_data(data_out   ));

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<RW_DB_ENTRY_NUM/4;i=i+1)begin
                v_lfdb_entry_idle[i]  <= 1'b1;
            end
        end                                    
        else begin
            for(int i=0;i<RW_DB_ENTRY_NUM/4;i=i+1)begin
                if(v_lfdb_entry_idle[i] && v_lfdb_rdy[i])begin
                    v_lfdb_entry_idle[i] <= 1'b0;
                end
            end    
            if(read_lfdb_vld && read_lfdb_pld.last && lfdb_to_ram_rdy && v_lfdb_entry_active[read_lfdb_pld.req_cmd_pld.db_entry_id] )begin
                v_lfdb_entry_idle[read_lfdb_pld.req_cmd_pld.db_entry_id]<= 1'b1;
            end
        end
    end
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n) begin
            for(int i=0;i<RW_DB_ENTRY_NUM/4;i=i+1)begin
                v_lfdb_entry_active[i] <= 'b0;
            end
        end
        else begin
            if(ds_to_lfdb_vld)begin
                v_lfdb_entry_active[ds_to_lfdb_pld.linefill_cmd.db_entry_id] <= 'b1;
            end
            else if(read_lfdb_vld && read_lfdb_pld.last && lfdb_to_ram_rdy)begin
                v_lfdb_entry_active[read_lfdb_pld.req_cmd_pld.db_entry_id] <= 'b0;
            end               
        end                              
    end

    vec_cache_pre_alloc_one #(
        .ENTRY_NUM(LFDB_ENTRY_NUM/4),
        .ENTRY_ID_WIDTH($clog2(LFDB_ENTRY_NUM/4))
    ) u_pre_alloc_lfdb (
        .clk        (clk             ),
        .rst_n      (rst_n           ),
        .v_in_vld   (v_lfdb_entry_idle),
        .v_in_rdy   (v_lfdb_rdy      ),//TODO
        .out_vld    (alloc_vld       ),
        .out_rdy    (alloc_rdy       ),
        .out_index  (alloc_idx       )
    );


    

endmodule
