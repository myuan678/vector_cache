module sram_mem_inst #(
    parameter integer unsigned MEM_NUM    = 16              ,
    parameter integer unsigned CHANNEL    = 8               ,
    parameter integer unsigned MEM_WIDTH  = 32              ,
    parameter integer unsigned MEM_DEPTH  = 2048            ,
    parameter integer unsigned SEL_WIDTH  = $clog2(CHANNEL) ,
    parameter integer unsigned ADDR_WIDTH = $clog2(MEM_DEPTH)
) (
    input  logic                  clk                     ,
    input  logic                  rst_n                   ,
    input  logic [SEL_WIDTH-1 :0] sel                     ,
    input  logic [CHANNEL-1   :0] mem_en_in               ,
    output logic [CHANNEL-1   :0] mem_en_out              ,
    input  logic [CHANNEL-1   :0] wr_en_in                ,
    output logic [CHANNEL-1   :0] wr_en_out               ,
    input  logic [ADDR_WIDTH-1:0] addr_in    [CHANNEL-1:0],
    output logic [ADDR_WIDTH-1:0] addr_out   [CHANNEL-1:0],
    input  logic [MEM_WIDTH-1 :0] wr_data_in [CHANNEL-1:0],
    output logic [MEM_WIDTH-1 :0] wr_data_out[CHANNEL-1:0],
    input  logic [MEM_WIDTH-1 :0] rd_data_in [CHANNEL-1:0],
    output logic [MEM_WIDTH-1 :0] rd_data_out[CHANNEL-1:0]

);
    logic [MEM_WIDTH-1:0]   rd_data ;
    logic                   mem_en  ;
    logic [ADDR_WIDTH-1:0]  addr    ;
    logic [MEM_WIDTH-1 :0]  wr_data ;

    generate;
        for(genvar i=0;i<CHANNEL;i=i+1)begin
            assign rd_data_out[i]   = rd_data_in[i] & rd_data   ;
            assign mem_en_out[i]    = mem_en_in[i]              ;
            assign wr_en_out[i]     = wr_en_in[i]               ;
            assign wr_data_out[i]   = wr_data_in[i]             ;
            assign addr_out[i]      = addr_in[i]                ;
        end
    endgenerate

    assign mem_en   = mem_en_in[sel]    ;
    assign addr     = addr_in[sel]      ;
    assign wr_en    = wr_en_in[sel]     ;
    assign wr_data  = wr_data_in[sel]   ;

    mem_inst u_mem_inst(
        .clk    (clk    ),
        .rst_n  (rst_n  ),
        .en     (mem_en ),
        .wr_en  (wr_en  ),
        .addr   (addr   ),
        .byte_wr_en(byte_wr_en),
        .wr_data(wr_data),
        .rd_data(rd_data)
    );

endmodule