module mem_block
import vector_cache_pkg::*;
(
    input  logic                clk_2g                     ,
    input  logic                clk_1g                     ,
    input  logic                rst_n                      ,

    input  logic [7:0]          read_cmd_vld_in            ,
    input  arb_out_req_t        read_cmd_pld_in     [7:0]  ,
    output logic [7:0]          read_cmd_vld_out           ,
    output arb_out_req_t        read_cmd_pld_out    [7:0]  ,

    input  logic [7:0]          write_cmd_vld_in           ,
    input  arb_out_req_t        write_cmd_pld_in    [7:0]  ,
    output logic [7:0]          write_cmd_vld_out          ,
    output arb_out_req_t        write_cmd_pld_out   [7:0]  ,

    input  logic [7         :0] rd_data_in_vld             ,
    input  logic [31        :0] rd_data_in         [7  :0] ,
    output logic [7         :0] rd_data_out_vld            ,
    output logic [31        :0] rd_data_out        [7  :0] ,

    input  logic [7         :0] wr_data_in_vld             ,
    input  logic [31        :0] wr_data_in         [7  :0] ,
    output logic [7         :0] wr_data_out_vld            ,
    output logic [31        :0] wr_data_out        [7  :0] 
);

    parameter integer unsigned ID = 0;

    logic [7:0]          read_cmd_vld_d1        ;
    logic [7:0]          read_cmd_vld_d2        ;
    logic [7:0]          write_cmd_vld_d1       ;
    logic [7:0]          write_cmd_vld_d2       ;
    arb_out_req_t        read_cmd_pld_d1[7:0]   ;
    arb_out_req_t        read_cmd_pld_d2[7:0]   ;
    arb_out_req_t        write_cmd_pld_d1[7:0]  ;
    arb_out_req_t        write_cmd_pld_d2[7:0]  ;

    logic [31        :0] rd_data        [7  :0] ;
    logic [31        :0] wr_data        [7  :0] ;

    logic [7:0]wr_need_pipe_1;
    logic [7:0]wr_need_pipe_2;
    logic [7:0]wr_need_pipe;


    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk_2g or negedge rst_n)begin
                if(!rst_n) begin
                    read_cmd_vld_d1[i] <= 'b0;
                    read_cmd_vld_d2[i] <= 'b0;
                end
                else if(read_cmd_vld_in[i])begin
                    read_cmd_vld_d1[i] <= read_cmd_vld_in[i];
                    read_cmd_vld_d2[i] <= read_cmd_vld_d1[i];
                end
                else begin
                    read_cmd_vld_d1[i] <= 'b0;
                    read_cmd_vld_d2[i] <= 'b0;
                end
            end
        end
    endgenerate
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk_2g or negedge rst_n)begin
                if(!rst_n) begin
                    write_cmd_vld_d1[i] <= 'b0;
                    write_cmd_vld_d2[i] <= 'b0;
                end
                else if(write_cmd_vld_in[i])begin
                    write_cmd_vld_d1[i] <= write_cmd_vld_in[i];
                    write_cmd_vld_d2[i] <= write_cmd_vld_d1[i];
                end
                else begin
                    write_cmd_vld_d1[i] <= 'b0;
                    write_cmd_vld_d2[i] <= 'b0;
                end
            end
        end
    endgenerate
    
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk_2g or negedge rst_n)begin
                if(!rst_n)begin
                    read_cmd_pld_d1[i]    <= 'b0;
                    read_cmd_pld_d2[i]    <= 'b0;
                    write_cmd_pld_d1[i]   <= 'b0;
                    write_cmd_pld_d2[i]   <= 'b0;
                end
                else begin
                    read_cmd_pld_d1[i]    <= read_cmd_pld_in[i];
                    read_cmd_pld_d2[i]    <= read_cmd_pld_d1[i];
                    write_cmd_pld_d1[i]   <= write_cmd_pld_in[i];
                    write_cmd_pld_d2[i]   <= write_cmd_pld_d1[i];
                end
            end
        end
    endgenerate

    //read
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                read_cmd_vld_out[i] = 1'b0;
                if(read_cmd_vld_in[i] && (group_id_col_in[i]==ID))begin
                    read_cmd_vld_out[i] = read_cmd_vld_in[i];
                end
            end
        end
    endgenerate
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                read_cmd_pld_out [i] = 'b0;
                if(read_cmd_vld_in[i])begin
                    read_cmd_pld_out[i] = read_cmd_pld_in[i];
                end
            end
        end    
    endgenerate

//write
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                write_cmd_vld_out[i] = 1'b0;
                if(write_cmd_vld_in[i] && (group_id_col_in[i]==ID))begin
                    write_cmd_vld_out[i] = write_cmd_vld_d2[i];
                end
            end
        end
    endgenerate
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                write_cmd_pld_out [i] = 'b0;
                if(read_cmd_vld_in[i])begin
                    write_cmd_pld_out[i] = write_cmd_pld_d2[i];
                end
            end
        end    
    endgenerate

    sram_inst_cmd_t read_cmd_out[7:0];
    sram_inst_cmd_t write_cmd_out[7:0];

    //read arbiter
    generate
        for(genvar i=0;i<4;i=i+1)begin  //read
            assign rd_data_out[i*2]   = (read_cmd_vld_out[i*2]==1'b0 ) ? rd_data_in[i*2] : 
                                                    read_cmd_out[i*2].addr[9] ? rd_data[i*2] : rd_data[i*2+1]   ;//地址的最高bit决定sram hash 二选一
            assign rd_data_out[i*2+1] = (read_cmd_vld_out[i*2+1]==1'b0 ) ? rd_data_in[i*2+1] : 
                                                    read_cmd_out[i*2+1].addr[9] ? rd_data[i*2] : rd_data[i*2+1] ;
        end
    endgenerate

    always_ff@(posedge clk_2g or negedge rst_n)begin
        if(read_cmd_vld_in && write_cmd_vld_in)begin
            $error("ERROR:  READ && WRITE can't happen at same time!");
        end
    end

    // write arb 1to3
    //generate
    //    for(genvar i=0;i<4;i=i+1)begin
    //        assign wr_data[i*2]       = (cmd_vld_out[i*2] && op_code_out[i*2][3]==1'b0) ? 'b0 : 
    //                                                   addr[i*2][9] ? wr_data_in[i*2] : wr_data_in[i*2+1]  ;
//
    //        assign wr_data[i*2+1]     = (cmd_vld_out[i*2+1] && op_code_out[i*2+1][3]==1'b0) ? 'b0 : 
    //                                                   addr[i*2+1][9] ? wr_data_in[i*2] : wr_data_in[i*2+1];
//
    //        assign wr_data_out[i*2]   = (cmd_vld_out[i*2] && op_code_out[i*2][3]==1'b0)     ? wr_data_in[i*2] : 'b0   ;
    //        assign wr_data_out[i*2+1] = (cmd_vld_out[i*2+1] && op_code_out[i*2+1][3]==1'b0) ? wr_data_in[i*2+1] : 'b0 ;
    //    end
    //endgenerate


    // write arb 1to3
    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign wr_data[i*2]       = write_cmd_vld_out[i*2] ? (write_cmd_out[i*2].addr[9] ? wr_data_in[i*2] : wr_data_in[i*2+1]) : 'b0 ;

            assign wr_data[i*2+1]     = write_cmd_vld_out[i*2+1] ? (write_cmd_out[i*2+1].addr[9] ? wr_data_in[i*2] : wr_data_in[i*2+1]) : 'b0;

            assign wr_data_out[i*2]   = write_cmd_vld_out[i*2]   ? 'b0 : wr_data_in[i*2]  ;
            assign wr_data_out[i*2+1] = write_cmd_vld_out[i*2+1] ? 'b0 : wr_data_in[i*2+1] ;
        end
    endgenerate


    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign read_cmd_out[i].addr     = {read_cmd_pld_out[i].index,read_cmd_pld_out[i].way};
            assign read_cmd_out[i].mode     = read_cmd_pld_out[i].txnid.mode;
            assign read_cmd_out[i].byte_sel = read_cmd_pld_out[i].txnid.byte_sel;
            //assign read_cmd_out.opcode = 1'b0; //读写cmd分开，不需要opcode

            assign write_cmd_out[i].addr       = {write_cmd_pld_out[i].index,write_cmd_pld_out[i].way};
            assign write_cmd_out[i].mode       = write_cmd_pld_out[i].txnid.mode;
            assign write_cmd_out[i].byte_sel   = write_cmd_pld_out[i].txnid.byte_sel;
            //assign write_cmd_out.opcode     = 1'b1;//读写cmd分开，不需要opcode
        end
    endgenerate
        



    sram_2inst u_hash0(
        .clk        (clk                    ),
        .rst_n      (rst_n                  ),
        .read_vld_a (read_cmd_vld_out[0]    ),
        .read_cmd_a (read_cmd_out[0]        ),
        .write_vld_a(write_cmd_vld_out[0]   ),
        .write_cmd_a(write_cmd_out[0]       ),
        .read_vld_b (read_cmd_vld_out[1]    ),
        .read_cmd_b (read_cmd_out[1]        ),
        .write_vld_b(write_cmd_vld_out[1]   ),
        .write_cmd_b(write_cmd_out[1]       ),
        .wr_data_a  (wr_data[0]             ),
        .wr_data_b  (wr_data[1]             ),
        .rd_data_a  (rd_data[0]             ),
        .rd_data_b  (rd_data[1]             ));

    sram_2inst u_hash1(
        .clk        (clk                    ),
        .rst_n      (rst_n                  ),
        .read_vld_a (read_cmd_vld_out[2]    ),
        .read_cmd_a (read_cmd_out[2]        ),
        .write_vld_a(write_cmd_vld_out[2]   ),
        .write_cmd_a(write_cmd_out[2]       ),
        .read_vld_b (read_cmd_vld_out[3]    ),
        .read_cmd_b (read_cmd_out[3]        ),
        .write_vld_b(write_cmd_vld_out[3]   ),
        .write_cmd_b(write_cmd_out[3]       ),
        .wr_data_a  (wr_data[2]             ),
        .wr_data_b  (wr_data[3]             ),
        .rd_data_a  (rd_data[2]             ),
        .rd_data_b  (rd_data[3]             ));

    sram_2inst u_hash2(
        .clk        (clk                    ),
        .rst_n      (rst_n                  ),
        .read_vld_a (read_cmd_vld_out[4]    ),
        .read_cmd_a (read_cmd_out[4]        ),
        .write_vld_a(write_cmd_vld_out[4]   ),
        .write_cmd_a(write_cmd_out[4]       ),
        .read_vld_b (read_cmd_vld_out[5]    ),
        .read_cmd_b (read_cmd_out[5]        ),
        .write_vld_b(write_cmd_vld_out[5]   ),
        .write_cmd_b(write_cmd_out[5]       ),
        .wr_data_a  (wr_data[4]             ),
        .wr_data_b  (wr_data[5]             ),
        .rd_data_a  (rd_data[4]             ),
        .rd_data_b  (rd_data[5]             ));

    sram_2inst u_hash3(
        .clk        (clk                    ),
        .rst_n      (rst_n                  ),
        .read_vld_a (read_cmd_vld_out[6]    ),
        .read_cmd_a (read_cmd_out[6]        ),
        .write_vld_a(write_cmd_vld_out[6]   ),
        .write_cmd_a(write_cmd_out[6]       ),
        .read_vld_b (read_cmd_vld_out[7]    ),
        .read_cmd_b (read_cmd_out[7]        ),
        .write_vld_b(write_cmd_vld_out[7]   ),
        .write_cmd_b(write_cmd_out[7]       ),
        .wr_data_a  (wr_data[6]             ),
        .wr_data_b  (wr_data[7]             ),
        .rd_data_a  (rd_data[6]             ),
        .rd_data_b  (rd_data[7]             ));

    




             


endmodule


