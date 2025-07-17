module sram_bank #(
    parameter integer unsigned CHANNEL   = 8,
    parameter integer unsigned SEL_WIDTH = $clog2(CHANNEL),
    parameter integer unsigned MEM_WIDTH = 32,
    parameter integer unsigned MEM_DEPTH = 2048,
    parameter integer unsigned DATA_WIDTH = 32,
    parameter integer unsigned ADDR_WIDTH = $clog2(MEM_DEPTH),
    parameter integer unsigned MEM_NUM = 8
) (
    input  logic                   clk                         ,
    input  logic                   rst_n                       ,
    input  logic [SEL_WIDTH-1 :0]  sel                         ,
    input  logic [CHANNEL-1   :0]  wr_cmd_vld_in               ,
    output logic [CHANNEL-1   :0]  wr_cmd_vld_out              ,
    input  logic [CHANNEL-1   :0]  rd_cmd_vld_in               ,
    output logic [CHANNEL-1   :0]  rd_cmd_vld_out              ,
    input  logic [ADDR_WIDTH-1:0]  addr_in        [CHANNEL-1:0],
    output logic [ADDR_WIDTH-1:0]  addr_out       [CHANNEL-1:0],
    input  logic [DATA_WIDTH-1:0]  wr_cmd_data_in [CHANNEL-1:0],
    output logic [DATA_WIDTH-1:0]  wr_cmd_data_out[CHANNEL-1:0],
    input  logic [DATA_WIDTH-1:0]  rd_data_in     [CHANNEL-1:0],
    output logic [DATA_WIDTH-1:0]  rd_data_out    [CHANNEL-1:0]
);

    logic [DATA_WIDTH-1:0]  rd_cmd_data ;
    logic [ADDR_WIDTH-1:0]  addr        ;
    logic [DATA_WIDTH-1:0]  wr_data     ;

    generate 
        for(genvar i=0;i<CHANNEL;i=i+1)begin
            assign rd_data_out[i]     = sel ? rd_data_in[i] : rd_cmd_data ;
            assign wr_cmd_vld_out[i]  = wr_cmd_vld_in[i]                  ;
            assign rd_cmd_vld_out[i]  = rd_cmd_vld_in[i]                  ;
            assign wr_cmd_data_out[i] = wr_cmd_data_in[i]                 ;
            assign addr_out[i]        = addr_in[i]                        ;
        end    
    endgenerate

    assign wr_cmd_vld  = wr_cmd_vld_in[sel] ;
    assign rd_cmd_vld  = rd_cmd_vld_in[sel] ;
    assign addr        = addr_in[sel]       ;
    assign wr_cmd_data = wr_cmd_data_in[sel];

        sram_bank_inst  #(
            .CHANNEL   (CHANNEL   ),
            .SEL_WIDTH (SEL_WIDTH ),
            .MEM_WIDTH (MEM_WIDTH ),
            .MEM_DEPTH (MEM_DEPTH ),
            .DATA_WIDTH(DATA_WIDTH),
            .ADDR_WIDTH(ADDR_WIDTH),
            .MEM_NUM   (MEM_NUM   )
        ) u_sram_bank_inst (
            .clk        (clk        ),
            .rst_n      (rst_n      ),
            .wr_cmd_vld (wr_cmd_vld ),
            .rd_cmd_vld (rd_cmd_vld ),
            .addr       (addr       ),
            .rd_data    (rd_cmd_data),
            .wr_data    (wr_cmd_data)
        );

endmodule

