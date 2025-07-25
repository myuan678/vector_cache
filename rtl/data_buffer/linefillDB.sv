module linefillDB 
    import vector_cache_pkg::*;
    #( 
        parameter integer unsigned ARB_TO_LFDB_DELAY    = 5
    )
    (
    input  logic                            clk                     ,
    input  logic                            rst_n                   ,

    output logic                            alloc_vld               ,
    output logic [$clog2(LFDB_ENTRY_NUM/4)-1:0] alloc_idx           ,
    input  logic                            alloc_rdy               ,
    
    input  logic                            ds_to_lfdb_vld          ,
    input  ds_to_lfdb_pld_t                 ds_to_lfdb_pld          , //addr + data
    output logic                            ds_to_lfdb_rdy          ,
    
    input  logic                            lfdb_rdreq_vld          ,
    input  arb_out_req_t                    lfdb_rdreq_pld          , //read lfdb ; addr
    output logic                            lfdb_rdreq_rdy          ,
    
    output logic                            lfdb_to_ram_vld         ,
    output write_ram_pld_t                  lfdb_to_ram_pld         ,
    input  logic                            lfdb_to_ram_rdy         ,

    output logic                            linefill_data_done      ,//to rob
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0] linefill_data_done_idx  ,
    output logic                            linefill_to_ram_done    ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0] linefill_to_ram_done_idx
);

    logic [1023                     :0]     data_in                 ;
    logic [1023                     :0]     data_out                ;
    logic                                   db_mem_en               ;
    logic                                   db_wr_en                ;
    logic [CACHE_LINE_SIZE-1        :0]     db_byte_en              ;
    logic [$clog2(LFDB_ENTRY_NUM)-1 :0]     db_addr                 ; //entry_id
    logic [LFDB_ENTRY_NUM/4-1       :0]     v_lfdb_entry_vld        ;
    logic                                   read_lfdb_vld           ;
    read_lfdb_pld_t                         read_lfdb_pld           ;
    logic                                   read_lfdb_vld_d         ;
    read_lfdb_pld_t                         read_lfdb_pld_d         ;


//-----------------DELAY----------------------------------------------------------------
    logic [LF_DONE_DELAY-1     :0] delay_shift_reg;
    arb_out_req_t                  delay_pld_reg[LF_DONE_DELAY-1:0];
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)    delay_shift_reg <= {LF_DONE_DELAY{1'b0}};
        else           delay_shift_reg <= {delay_shift_reg[LF_DONE_DELAY-2:0], lfdb_rdreq_vld};
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<LF_DONE_DELAY;i=i+1)begin
                delay_pld_reg[i] <= 'b0;
            end
        end
        else begin
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
    logic        sending;        // 是否正在发起连续4拍请求
    logic [1:0]  req_cnt;        // 当前发第几个请求
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sending         <= 1'b0;
            req_cnt         <= 2'd0;
            read_lfdb_vld   <= 1'b0;
            read_lfdb_pld   <= '0;
        end 
        else begin//开始发送4拍
            if (!sending && delay_shift_reg[ARB_TO_LFDB_DELAY-1]) begin//ARB_TO_LFDB_DELAY-1拍后开始发送,linefill_data_done
                sending                   <= 1'b1;
                req_cnt                   <= 2'd0;
                read_lfdb_vld             <= 1'b1;
                read_lfdb_pld.req_cmd_pld <= delay_pld_reg[ARB_TO_LFDB_DELAY-1];
                read_lfdb_pld.req_num     <= 2'd0;
                read_lfdb_pld.last        <= 1'b0;
            end
            else if (sending) begin
                //if (req_cnt == 2'd2) sending <= 1'b0; // 3发完之后下拍停止
                sending                   <= (req_cnt==2'd2) ? 1'b0 : 1'b1;
                req_cnt                   <= req_cnt + 1;
                read_lfdb_vld             <= 1'b1;
                read_lfdb_pld.req_cmd_pld <= delay_pld_reg[ARB_TO_LFDB_DELAY-1 + req_cnt + 1];  // 后续数据
                read_lfdb_pld.req_num     <= req_cnt + 1;
                read_lfdb_pld.last        <= (req_cnt == 2'd2);  // 下一拍是最后一个
                
            end
            else begin
                read_lfdb_vld <= 1'b0;
            end
        end
    end

    //assign read_lfdb_vld  = delay_shift_reg[ARB_TO_LFDB_DELAY-1];
    //assign read_lfdb_pld  = delay_pld_reg[ARB_TO_LFDB_DELAY-1];
    assign data_in        = ds_to_lfdb_pld.data;
    assign db_mem_en      = read_lfdb_vld | ds_to_lfdb_vld;
    assign db_wr_en       = read_lfdb_vld ? 1'b0 : (ds_to_lfdb_vld ? 1'b1: 1'b0);
    assign lfdb_rdreq_rdy = read_lfdb_vld ? 1'b1 : 1'b0 ;
    assign ds_to_lfdb_rdy = read_lfdb_vld ? 1'b0 : 1'b1 ;
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
    assign lfdb_to_ram_pld.data                  = data_out;  
    assign lfdb_to_ram_pld.write_cmd.req_cmd_pld = read_lfdb_pld_d.req_cmd_pld;
    assign lfdb_to_ram_pld.write_cmd.last        = read_lfdb_pld_d.last;
    assign lfdb_to_ram_pld.write_cmd.req_num     = read_lfdb_pld_d.req_num;
    assign lfdb_to_ram_vld                       = read_lfdb_vld_d;



    //linefill_data_done表示数据写入了LFDB，应该是ds_to_lfdb_vld
    //arb出的linefill_wrreq，读LFDB
    
    assign linefill_data_done       = ds_to_lfdb_rdy && ds_to_lfdb_vld && ds_to_lfdb_pld.last;
    assign linefill_data_done_idx   = ds_to_lfdb_pld.linefill_cmd.rob_entry_id;
    assign linefill_to_ram_done     = lfdb_to_ram_vld && lfdb_to_ram_rdy && read_lfdb_pld.last;
    assign linefill_to_ram_done_idx = read_lfdb_pld.req_cmd_pld.rob_entry_id;
    


    

    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(LFDB_ENTRY_NUM)),
        .DATA_WIDTH  (1024             )//linefillDB width 
    ) u_lf_data_buffer (
        .clk    (clk        ),
        .en     (db_mem_en  ),
        .wr_en  (db_wr_en   ),
        .addr   (db_addr    ),
        .wr_data(data_in    ),
        .rd_data(data_out   )
    );

//一次pre_alloc 4个，并且读出4个后才release lfdb entry
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            v_lfdb_entry_vld = 'b1;
        end
        else if(db_mem_en && db_wr_en)begin
            v_lfdb_entry_vld[db_addr] = 1'b0;
        end
        else if(db_mem_en && (db_wr_en==1'b0) && lfdb_to_ram_pld.write_cmd.last)begin
            v_lfdb_entry_vld[lfdb_to_ram_pld.write_cmd.req_cmd_pld.db_entry_id] = 1'b1;
        end
        else begin
            v_lfdb_entry_vld <= v_lfdb_entry_vld;
        end
    end

    pre_alloc_one #(
        .ENTRY_NUM(LFDB_ENTRY_NUM/4),
        .ENTRY_ID_WIDTH($clog2(LFDB_ENTRY_NUM/4))
    ) u_pre_alloc_lfdb (
        .clk        (clk             ),
        .rst_n      (rst_n           ),
        .v_in_vld   (v_lfdb_entry_vld),
        .v_in_rdy   (                ),//TODO
        .out_vld    (alloc_vld       ),
        .out_rdy    (alloc_rdy       ),
        .out_index  (alloc_idx       )
    );


    

endmodule
