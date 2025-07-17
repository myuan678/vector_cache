module sram_bank_inst 
    import vector_cache_pkg::*;(
    input  logic                      clk         ,
    input  logic                      rst_n       ,
    input  logic   [ADDR_WIDTH-1:0]   addr        ,
    input  logic                      wr_cmd_vld  ,
    input  logic   [DATA_WIDTH-1:0]   wr_data     ,
    input  logic                      rd_cmd_vld  ,
    output logic   [DATA_WIDTH-1:0]   rd_data  
);
    logic [1 :0] sel               ;
    logic        mode              ;
    logic [3 :0] mem_en            ;
    logic [3 :0] wr_en             ;
    logic [3 :0] byte_wr_en   [3:0]; // 4byte 4sram
    logic [31:0] sram_rd_data [3:0];
    logic [31:0] sram_wr_data [3:0];

    assign sel  = addr[2:1];
    assign mode = addr[0]  ;

    always_comb begin
        if (rd_cmd_vld || wr_cmd_vld) begin
            if (mode == 1'b0) begin
                mem_en = 4'b0001 << sel;  //1: sel
            end 
            else begin
                mem_en = 4'b1111;
            end
            wr_en = wr_cmd_vld ? mem_en : 4'b0000;
        end 
        else begin
            mem_en = 4'b0000;
            wr_en  = 4'b0000;
        end
    end

    //write data
    always_comb begin
        for (integer j = 0; j < 4; j = j + 1) begin
            if (mode == 1'b0) begin//4选1一块sram写
                if (j == sel) begin
                    byte_wr_en[j]   = 4'b1111;
                    sram_wr_data[j] = wr_data;
                end 
                else begin
                    byte_wr_en[j]   = 4'b0000;
                    sram_wr_data[j] = sram_rd_data[j];
                end
            end 
            else begin//mode = 1 写4块sram中1byte
                //byte_wr_en[j] = 4'b0000;
                byte_wr_en[j][sel] = 1'b1;
                case (sel)
                    2'b00:   sram_wr_data[j] = {24'b0, wr_data[j*8 +: 8]};
                    2'b01:   sram_wr_data[j] = {16'b0, wr_data[j*8 +: 8], 8'b0};
                    2'b10:   sram_wr_data[j] = {8'b0, wr_data[j*8 +: 8], 16'b0};
                    2'b11:   sram_wr_data[j] = {wr_data[j*8 +: 8], 24'b0};
                    default: sram_wr_data[j] = 32'b0;
                endcase
            end
        end
    end

    generate
        for (genvar i = 0; i < 4; i = i + 1) begin : SRAM_ARRAY
            sram  u_mem_inst (
               .clk         (clk            ),
               .rst_n       (rst_n          ),
               .en          (mem_en[i]      ),
               .wr_en       (wr_en[i]       ),
               .addr        (addr           ),
               .byte_wr_en  (byte_wr_en[i]  ),
               .wr_data     (sram_wr_data[i]),
               .rd_data     (sram_rd_data[i])
            );
        end
    endgenerate

    always_comb begin
        if (rd_cmd_vld) begin
            if (mode == 1'b0) begin
                case (sel)
                    2'b00: rd_data = sram_rd_data[0];
                    2'b01: rd_data = sram_rd_data[1];
                    2'b10: rd_data = sram_rd_data[2];
                    2'b11: rd_data = sram_rd_data[3];
                    default: rd_data = 32'b0;
                endcase
            end 
            else begin    // mode = 1 
                case (sel)
                    2'b00: rd_data = {sram_rd_data[3][7:0], sram_rd_data[2][7:0], sram_rd_data[1][7:0], sram_rd_data[0][7:0]};
                    2'b01: rd_data = {sram_rd_data[3][15:8], sram_rd_data[2][15:8], sram_rd_data[1][15:8], sram_rd_data[0][15:8]};
                    2'b10: rd_data = {sram_rd_data[3][23:16], sram_rd_data[2][23:16], sram_rd_data[1][23:16], sram_rd_data[0][23:16]};
                    2'b11: rd_data = {sram_rd_data[3][31:24], sram_rd_data[2][31:24], sram_rd_data[1][31:24], sram_rd_data[0][31:24]};
                    default: rd_data = 32'b0;
                endcase
            end
        end else begin
            rd_data = 32'b0;
        end
    end

    

endmodule
