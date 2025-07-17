module sram_bank #(
    parameter integer unsigned MEM_NUM    = 16,
    parameter integer unsigned CHANNEL    = 8,
    parameter integer unsigned MEM_WIDTH  = 32,
    parameter integer unsigned MEM_DEPTH  = 2048,
    parameter integer unsigned SEL_WIDTH  = $clog2(CHANNEL),
    parameter integer unsigned ADDR_WIDTH = $clog2(MEM_DEPTH)
) (
    input  logic                    clk                     ,
    input  logic                    rst_n                   ,
    input  logic [SEL_WIDTH-1 :0]   sel                     ,
    input  logic [CHANNEL-1   :0]   mem_en_in               ,
    input  logic [CHANNEL-1   :0]   wr_en_in                ,
    input  logic [ADDR_WIDTH-1:0]   addr_in    [CHANNEL-1:0],
    input  logic [MEM_WIDTH-1 :0]   wr_data_in [CHANNEL-1:0],
    input  logic [MEM_WIDTH-1 :0]   rd_data_in [CHANNEL-1:0],
    output logic [MEM_WIDTH-1 :0]   rd_data_out[CHANNEL-1:0]
);

    logic [CHANNEL-1    :0] mem_en_m    [MEM_NUM:0]             ;
    logic [CHANNEL-1    :0] wr_en_m     [MEM_NUM:0]             ;
    logic [ADDR_WIDTH-1 :0] addr_m      [MEM_NUM:0][CHANNEL-1:0];
    logic [MEM_WIDTH-1  :0] wr_data_m   [MEM_NUM:0][CHANNEL-1:0];
    logic [MEM_WIDTH-1  :0] rd_data_m   [MEM_NUM:0][CHANNEL-1:0];

    assign mem_en_m[0]  = mem_en_in ;
    assign wr_en_m[0]   = wr_en_in  ;
    assign addr_m [0]   = addr_in   ;
    assign wr_data_m[0] = wr_data_in;
    

    generate;
        for(genvar i=0;i< MEM_NUM;i=i+1)begin
            sram_bank #(
                .MEM_NUM(MEM_NUM),
                .CHANNEL(CHANNEL),
                .MEM_WIDTH(MEM_WIDTH),
                .ADDR_WIDTH(ADDR_WIDTH)
            ) u_sram_bank(
                .clk        (clk            ),
                .rst_n      (rst_n          ),
                .sel        (sel            ),
                .mem_en_in  (mem_en_m[i]    ),
                .mem_en_out (mem_en_m[i+1]  ),
                .wr_en_in   (wr_en_m[i]     ),
                .wr_en_out  (wr_en_m[i+1]   ),
                .addr_in    (addr_m[i]      ),
                .addr_out   (addr_m[i+1]    ),
                .wr_data_in (wr_data_m[i]   ),
                .wr_data_out(wr_data_m[i+1] ),
                .rd_data_in (rd_data_m[i]   ),
                .rd_data_out(rd_data_m[i+1] )
            );
        end
    endgenerate

    assign rd_data_m[0] = rd_data_in;
    assign rd_data_out = rd_data_m[MEM_NUM];



endmodule