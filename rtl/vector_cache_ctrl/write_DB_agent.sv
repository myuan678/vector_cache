module write_DB_agent 
    import vector_cache_pkg::*;
    #(
    parameter integer unsigned WIDTH = 10,
    parameter integer unsigned ENTRY_NUM = 32,
    parameter integer unsigned ARB_TO_WDB_DELAY = 5,
    parameter integer unsigned US_TO_WDB_DATA_RDY_DELAY = 10,
    parameter integer unsigned WRITE_DONE_DELAY = 20

) (
    input  logic                            clk             ,
    input  logic                            rst_n           ,

    output logic                            alloc_vld       ,
    output logic [$clog2(ENTRY_NUM)-1:0]    alloc_idx       ,
    input  logic                            alloc_rdy       ,

    input  wdb_pld_t                        write_wdb_pld   , //data + wdb_entry_id
    input  logic                            write_wdb_vld   ,
    output logic                            write_wdb_rdy   ,

    input  logic                            dataram_wr_vld  ,
    input  arb_out_req_t                    dataram_wr_pld  ,
    output logic                            dataram_wr_rdy  ,
    
    output logic                            write_sram_vld   ,
    output write_ram_pld_t                  write_sram_pld   ,//addr + data + id (arb_out_req_t && data)
    input  logic                            write_sram_rdy   ,//(sram rdy)

    output logic                            write_done       ,
    output logic [MSHR_ENTRY_IDX_WIDTH-1:0] write_done_idx  //write done idx
);

    logic [ENTRY_NUM-1          :0]         v_wdb_entry_vld ;
    logic [WRITE_DONE_DELAY-1   :0]         delay_shift_reg ;
    arb_out_req_t                           pld_shift_reg[WRITE_DONE_DELAY-1:0] ;
    logic                                   read_wdb_vld    ;//read WDB 高优先级
    arb_out_req_t                           read_wdb_pld    ;//read WDB
    logic                                   read_wdb_rdy    ;//read WDB
    logic                                   wdb_mem_en      ;
    logic                                   wdb_wr_en       ;
    logic [DB_ENTRY_IDX_WIDTH-1 :0]         wdb_addr        ;
    logic [1023                 :0]         data_out        ;
    logic                                   WDB_rdy         ;
    assign WDB_rdy = 1'b1;



//-----------------DELAY----------------------------------------------------------------
    //arb出来的写请求，要去读WDB，假设arb出来的请求到达WDB需要N拍延迟，也就是dataram_wr_vld延迟N拍作为真正的 “读WDB请求”
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)begin
            delay_shift_reg <= {WRITE_DONE_DELAY{1'b0}};
            for(int i=0;i<WRITE_DONE_DELAY;i=i+1)begin
                pld_shift_reg[i] <= 'b0;
            end
        end
        else begin
            delay_shift_reg <= {delay_shift_reg[WRITE_DONE_DELAY-2:0], dataram_wr_vld};
            pld_shift_reg   <= {pld_shift_reg[WRITE_DONE_DELAY-2:0], dataram_wr_pld};
        end
    end

     //写WDB的请求，也就是输入的write_wdb_vld, “写WDB”
//----------------------------------------------------------------------------------------

//读写WDB的arbiter  读优先(read_wdb_vld ：write_wdb_vld(write WDB));
    assign read_wdb_vld   = delay_shift_reg[ARB_TO_WDB_DELAY-1];
    assign read_wdb_pld   = pld_shift_reg[ARB_TO_WDB_DELAY-1];
    assign data_in        = write_wdb_pld.data;
    assign wdb_mem_en     = read_wdb_vld | write_wdb_vld  ;
    assign wdb_wr_en      = read_wdb_vld ? 1'b1 : 1'b0 ;
    assign wdb_addr       = read_wdb_vld ? read_wdb_pld.db_entry_id : write_wdb_pld.db_entry_id; //addr等于arb出的write请求的wdb entry id
    
    assign dataram_wr_rdy = WDB_rdy;
    assign write_wdb_rdy  = (~read_wdb_vld) && write_wdb_vld;


    logic           read_wdb_vld_d;
    arb_out_req_t   read_wdb_pld_d;
    //read WDB，所以read cmd要打一拍
    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            read_wdb_vld_d <= 'b0;
            read_wdb_pld_d <= 'b0;
        end
        else if(read_wdb_vld)begin
            read_wdb_vld_d <= read_wdb_vld;
            read_wdb_pld_d <= read_wdb_pld;
        end
        else begin
            read_wdb_vld_d <= 'b0;
            read_wdb_pld_d <= 'b0;
        end
    end

    assign write_sram_pld.data                  = data_out         ;
    assign write_sram_pld.write_cmd.req_cmd_pld = read_wdb_pld_d   ; //read WDB 然后将pld加上data再给到sram。这个req_cmd_pld可能还需要加上WDB到SRAM的delay//TODO：
    assign write_sram_pld.write_cmd.last        = 1'b1;
    assign write_sram_vld                       = read_wdb_vld_d   ;
    assign write_done                           = delay_shift_reg[WRITE_DONE_DELAY-1];
    assign write_done_idx                       = pld_shift_reg[WRITE_DONE_DELAY-1].rob_entry_id;
    
    //WDB ram
    toy_mem_model_bit #(
        .ADDR_WIDTH  ($clog2(RW_DB_ENTRY_NUM)  ),
        .DATA_WIDTH (DATA_WIDTH )
    ) u_write_data_buffer (
        .clk    (clk        ),
        //.rst_n  (rst_n      ),
        .en     (wdb_mem_en ),
        .wr_en  (wdb_wr_en  ),
        .addr   (wdb_addr   ),
        .wr_data(data_in    ),
        .rd_data(data_out   )
    );


    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            v_wdb_entry_vld = 'b1;
        end
        else begin
            if(wdb_mem_en && wdb_wr_en)             v_wdb_entry_vld[wdb_addr] <= 1'b0;
            else if(wdb_mem_en && wdb_wr_en==1'b0)  v_wdb_entry_vld[wdb_addr] <= 1'b1;
            else                                    v_wdb_entry_vld <= v_wdb_entry_vld;
        end
    end

    pre_alloc_one #(
        .ENTRY_NUM(RW_DB_ENTRY_NUM),
        .ENTRY_ID_WIDTH($clog2(RW_DB_ENTRY_NUM))
    ) u_pre_alloc_rdb (
        .clk        (clk             ),
        .rst_n      (rst_n           ),
        .v_in_vld   (v_wdb_entry_vld ),
        .v_in_rdy   (                ),
        .out_vld    (alloc_vld       ),
        .out_rdy    (alloc_rdy       ),
        .out_index  (alloc_idx       ));

endmodule