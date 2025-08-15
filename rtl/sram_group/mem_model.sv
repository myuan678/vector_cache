module mem_model#(
    parameter integer unsigned  DATA_WIDTH = 128,   
    parameter integer unsigned  ADDR_WIDTH = 9
)(
    input  logic                     clk        ,      
    input  logic                     rst_n      ,    
    input  logic                     en         ,       
    input  logic                     wr         ,       
    input  logic [DATA_WIDTH/8-1:0]    be         ,
    input  logic [ADDR_WIDTH-1:0]    addr       ,     
    input  logic [DATA_WIDTH-1:0]    data_in    ,
    output logic [DATA_WIDTH-1:0]    data_out  
);
    logic [DATA_WIDTH-1:0] mem [(2**ADDR_WIDTH)-1:0];
    logic [DATA_WIDTH-1:0] mem_data_in              ;

    //write
    //genvar i ;
    integer j ;
    //generate for(i=0;i<DATA_WIDTH;i++) begin
    //    assign mem_data_in[i] = be[i] ? data_in[i] : mem[addr][i];
    //end
    //endgenerate
    generate
        for(genvar i=0;i<DATA_WIDTH/8;i=i+1)begin
            assign mem_data_in[8*i +:8] = be[i] ? data_in[8*i +: 8] : mem[addr][8*i +: 8];
        end
    endgenerate

    always_ff@(posedge clk or negedge rst_n) begin
        if(!rst_n) begin    
            for(j=0;j<(2**ADDR_WIDTH);j++) begin
                mem[j] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if(en && wr) mem[addr] <= mem_data_in;
    end

    //read
    always_ff@(posedge clk) begin
        if(en && !wr) data_out <= mem[addr]; 
    end


endmodule