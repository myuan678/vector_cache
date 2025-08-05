module mem_block
import vector_cache_pkg::*;
#(parameter integer unsigned BLOCK_ID = 0           )
(
    input  logic                clk                             ,
    input  logic                clk_div                         ,
    input  logic                rst_n                           ,

    input  logic [7:0]          west_read_cmd_vld_in            ,
    input  arb_out_req_t        west_read_cmd_pld_in     [7:0]  ,
    output logic [7:0]          west_read_cmd_vld_out           ,
    output arb_out_req_t        west_read_cmd_pld_out    [7:0]  ,
    input  logic [7:0]          east_read_cmd_vld_in            ,
    input  arb_out_req_t        east_read_cmd_pld_in     [7:0]  ,
    output logic [7:0]          east_read_cmd_vld_out           ,
    output arb_out_req_t        east_read_cmd_pld_out    [7:0]  ,

    input  logic [7:0]          west_write_cmd_vld_in           ,
    input  write_ram_cmd_t      west_write_cmd_pld_in    [7:0]  ,
    output logic [7:0]          west_write_cmd_vld_out          ,
    output write_ram_cmd_t      west_write_cmd_pld_out   [7:0]  ,
    input  logic [7:0]          east_write_cmd_vld_in           ,
    input  write_ram_cmd_t      east_write_cmd_pld_in    [7:0]  ,
    output logic [7:0]          east_write_cmd_vld_out          ,
    output write_ram_cmd_t      east_write_cmd_pld_out   [7:0]  ,

    input  logic [7  :0]        west_data_in_vld                 ,
    input  data_pld_t           west_data_in             [7  :0] ,
    output logic [7  :0]        west_data_out_vld                ,
    output data_pld_t           west_data_out            [7  :0] ,
    
    input  logic [7  :0]        east_data_in_vld                 ,
    input  data_pld_t           east_data_in             [7  :0] ,
    output logic [7  :0]        east_data_out_vld                ,
    output data_pld_t           east_data_out            [7  :0] 
);



    logic [31:0]        rd_data[7:0] ;
    logic [31:0]        wr_data[7:0] ;

    sram_inst_cmd_t     read_ram_cmd[7:0];
    sram_inst_cmd_t     write_ram_cmd[7:0];
    logic [7:0]         read_ram_cmd_vld;
    logic [7:0]         read_ram_cmd_vld_d1;
    logic [7:0]         read_ram_cmd_vld_d2;
    sram_inst_cmd_t     read_ram_cmd_d1[7:0];
    sram_inst_cmd_t     read_ram_cmd_d2[7:0];
    logic [7:0]         write_ram_cmd_vld_d1;
    logic [7:0]         write_ram_cmd_vld_d2;
    sram_inst_cmd_t     write_ram_cmd_d1[7:0];
    sram_inst_cmd_t     write_ram_cmd_d2[7:0];


    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                west_read_cmd_vld_out[i]  = east_read_cmd_vld_in[i] ;
                west_read_cmd_pld_out[i]  = east_read_cmd_pld_in[i] ;
                east_read_cmd_vld_out[i]  = west_read_cmd_vld_in[i] ;
                east_read_cmd_pld_out[i]  = west_read_cmd_pld_in[i] ;
                east_write_cmd_vld_out[i] = west_write_cmd_vld_in[i];
                east_write_cmd_pld_out[i] = west_write_cmd_pld_in[i];
                west_write_cmd_vld_out[i] = east_write_cmd_vld_in[i];
                west_write_cmd_pld_out[i] = east_write_cmd_pld_in[i];
            end
        end
    endgenerate
    
    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign read_ram_cmd[i].addr        = {west_read_cmd_pld_in[i].index[INDEX_WIDTH-4:0],west_read_cmd_pld_in[i].way};
            assign read_ram_cmd[i].mode        = west_read_cmd_pld_in[i].txnid.mode     ;
            assign read_ram_cmd[i].byte_sel    = west_read_cmd_pld_in[i].txnid.byte_sel ;
            assign read_ram_cmd[i].dest_ram_id = {west_read_cmd_pld_in[i].hash_id,west_read_cmd_pld_in[i].index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
            assign read_ram_cmd[i].txnid       = west_read_cmd_pld_in[i].txnid          ;
            assign read_ram_cmd[i].opcode      = west_read_cmd_pld_in[i].opcode;

            assign write_ram_cmd[i].addr        = {east_write_cmd_pld_in[i].req_cmd_pld.index[INDEX_WIDTH-4:0],east_write_cmd_pld_in[i].req_cmd_pld.way};
            assign write_ram_cmd[i].mode        = east_write_cmd_pld_in[i].req_cmd_pld.txnid.mode    ;
            assign write_ram_cmd[i].byte_sel    = east_write_cmd_pld_in[i].req_num                   ;
            assign write_ram_cmd[i].dest_ram_id = {east_write_cmd_pld_in[i].req_cmd_pld.hash_id,east_write_cmd_pld_in[i].req_cmd_pld.index[INDEX_WIDTH-1:INDEX_WIDTH-3]};
            assign write_ram_cmd[i].txnid       = east_write_cmd_pld_in[i].req_cmd_pld.txnid         ;
            assign write_ram_cmd[i].opcode      = east_write_cmd_pld_in[i].req_cmd_pld.opcode;
        end
    endgenerate

    //read cmd 延迟1拍用来选择read_data
    generate
        for(genvar i=0;i<8;i=i+1)begin
            assign read_ram_cmd_vld[i] = west_read_cmd_vld_in[i];
        end
    endgenerate
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    read_ram_cmd_d1[i]    <= 'b0;
                    read_ram_cmd_vld_d1[i]<= 'b0;
                end
                else begin
                    read_ram_cmd_d1[i]    <= read_ram_cmd[i]        ;
                    read_ram_cmd_vld_d1[i]<= west_read_cmd_vld_in[i];
                end
            end
        end
    endgenerate

    //read 3to1 arbiter
    generate
        for(genvar i=0;i<4;i=i+1)begin  //read  //cmd[1:0]0/1对于hash0，2/3对于hash1，
            assign east_data_out[i*2].data     = (read_ram_cmd_vld_d1[i*2]==1'b0 ) ? west_data_in[i*2].data    : rd_data[i*2] ;//5bit dest_ram_id, 00 00 0 表示hash0，block0 的第一块sram。地址的最高bit决定sram hash 二选一
            assign east_data_out[i*2].cmd_pld  = (read_ram_cmd_vld_d1[i*2]==1'b0 ) ? west_data_in[i*2].cmd_pld : read_ram_cmd_d1[i*2];
            assign east_data_out_vld[i*2]      = (read_ram_cmd_vld_d1[i*2]==1'b0 ) ? west_data_in_vld[i*2]     : read_ram_cmd_vld_d1[i*2] ;
            assign east_data_out[i*2+1].data   = (read_ram_cmd_vld_d1[i*2+1]==1'b0 ) ? west_data_in[i*2+1].data    : rd_data[i*2+1] ;////5bit dest_ram_id, 00 00 1 表示hash0，block0 的第二块sram
            assign east_data_out[i*2+1].cmd_pld= (read_ram_cmd_vld_d1[i*2+1]==1'b0 ) ? west_data_in[i*2+1].cmd_pld : read_ram_cmd_d1[i*2+1];
            assign east_data_out_vld[i*2+1]    = (read_ram_cmd_vld_d1[i*2+1]==1'b0 ) ? west_data_in_vld[i*2+1]     : read_ram_cmd_vld_d1[i*2+1] ;
        end
    endgenerate

    //write cmd 延迟1拍用来选择写入地址
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk or negedge rst_n)begin
                if(!rst_n)begin
                    write_ram_cmd_d1[i]    <= 'b0;
                    write_ram_cmd_vld_d1[i]<= 'b0;
                end
                else begin
                    write_ram_cmd_d1[i]    <= write_ram_cmd[i]       ;
                    write_ram_cmd_vld_d1[i]<= east_write_cmd_vld_in[i];
                end
            end
        end
    endgenerate

    // write 1to3 
    generate
        for(genvar i=0;i<4;i=i+1)begin
            assign wr_data[i*2]                = east_data_in[i*2].data     ;
            assign wr_data[i*2+1]              = east_data_in[i*2+1].data   ;
            assign west_data_out[i*2].data     = east_data_in[i*2].data     ;
            assign west_data_out[i*2].cmd_pld  = east_data_in[i*2].cmd_pld  ;
            assign west_data_out[i*2+1].data   = east_data_in[i*2+1].data   ;
            assign west_data_out[i*2+1].cmd_pld= east_data_in[i*2+1].cmd_pld;
            assign west_data_out_vld[i*2]      = east_data_in_vld[i*2]      ;
            assign west_data_out_vld[i*2+1]    = east_data_in_vld[i*2+1]    ;
        end
    endgenerate


    generate
        for(genvar i=0;i<4;i=i+1)begin:block_four_hashram
            sram_2inst u_hash ( 
                .clk        (clk                            ),
                .rst_n      (rst_n                          ),
                .read_vld_a (read_ram_cmd_vld[2*i]          ),//change
                .read_cmd_a (read_ram_cmd[2*i]              ),
                .write_vld_a(write_ram_cmd_vld_d1[2*i]      ),
                .write_cmd_a(write_ram_cmd_d1[2*i]          ),//change
                .read_vld_b (read_ram_cmd_vld[2*i+1]        ),//change
                .read_cmd_b (read_ram_cmd[2*i+1]            ),
                .write_vld_b(write_ram_cmd_vld_d1[2*i+1]    ),
                .write_cmd_b(write_ram_cmd_d1[2*i+1]        ),//change
                .wr_data_a  (wr_data[2*i]                   ),
                .wr_data_b  (wr_data[2*i+1]                 ),
                .rd_data_a  (rd_data[2*i]                   ),
                .rd_data_b  (rd_data[2*i+1]                 ));
        end
    endgenerate


    //always_ff@(posedge clk)begin
    //    for(int i=0;i<8;i=i+1)begin
    //        if(west_read_cmd_vld_in[i] && east_write_cmd_vld_in[i])begin
    //            $error("Error: read/write conflict in one sram");
    //        end
    //    end
    //end
//
//
//
    //always_ff@(posedge clk)begin
    //    for(int i=0;i<4;i=i+1)begin
    //        if(west_read_cmd_vld_in[2*i] && west_read_cmd_vld_in[2*i+1])begin
    //            if(west_read_cmd_pld_in[2*i].dest_ram_id== west_read_cmd_pld_in[2*i+1].dest_ram_id)begin
    //                $error("Error: read req in one hash group conflict in one sram");
    //            end
    //        end
    //    end
    //end






             


endmodule


