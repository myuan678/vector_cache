module sram_bank_group 
import vector_cache_pkg::*;
(
    input  logic                clk                           ,
    input  logic                rst_n                         ,

    input  logic [4         :0] op_code_in            [7  :0] ,  //[4]:read; [3]:write; [2:1]:sel byte or 32bit; [0]: mode of read/write
    input  logic [1         :0] src_id_in             [7  :0] ,  //0:left; 1:right; 2:up; 3:down
    input  logic [1         :0] group_id_col_in       [7  :0] ,
    input  logic [9         :0] addr_in               [7  :0] ,

    output logic [4         :0] op_code_out           [7  :0] ,  //[4]:read; [3]:write; [2:1]:sel byte or 32bit; [0]: mode of read/write
    output logic [1         :0] src_id_out            [7  :0] ,  //0:left; 1:right; 2:up; 3:down 
    output logic [1         :0] group_id_col_out      [7  :0] ,
    output logic [9         :0] addr_out              [7  :0] ,

    input  logic [7         :0] data_in_vld_l                 ,
    input  logic [31        :0] data_in_l             [7  :0] ,
    output logic [7         :0] data_out_vld_l                ,
    output logic [31        :0] data_out_l            [7  :0] ,

    input  logic [7         :0] data_in_vld_r                 ,
    input  logic [31        :0] data_in_r             [7  :0] ,
    output logic [7         :0] data_out_vld_r                ,
    output logic [31        :0] data_out_r            [7  :0] ,

    input  logic [7         :0] data_in_vld_up                ,
    input  logic [31        :0] data_in_up            [7  :0] ,
    output logic [7         :0] data_out_vld_up               ,
    output logic [31        :0] data_out_up           [7  :0] ,

    input  logic [7         :0] data_in_vld_down              ,
    input  logic [31        :0] data_in_down          [7  :0] ,
    output logic [7         :0] data_out_vld_down             ,
    output logic [31        :0] data_out_down         [7  :0]  
);
    logic [4         :0] g_op_code_in            [7  :0][7  :0] ;
    logic [1         :0] g_src_id_in             [7  :0][7  :0] ;
    logic [1         :0] g_group_id_col_in       [7  :0][7  :0] ;
    logic [9         :0] g_addr_in               [7  :0][7  :0] ;
    logic [4         :0] g_op_code_out           [7  :0][7  :0] ;
    logic [1         :0] g_src_id_out            [7  :0][7  :0] ;
    logic [1         :0] g_group_id_col_out      [7  :0][7  :0] ;
    logic [9         :0] g_addr_out              [7  :0][7  :0] ;
    logic [7         :0] g_data_in_vld_l                [7  :0] ;
    logic [31        :0] g_data_in_l             [7  :0][7  :0] ;
    logic [7         :0] g_data_out_vld_l               [7  :0] ;
    logic [31        :0] g_data_out_l            [7  :0][7  :0] ;
    logic [7         :0] g_data_in_vld_r                [7  :0] ;
    logic [31        :0] g_data_in_r             [7  :0][7  :0] ;
    logic [7         :0] g_data_out_vld_r               [7  :0] ;
    logic [31        :0] g_data_out_r            [7  :0][7  :0] ;
    logic [7         :0] g_data_in_vld_up               [7  :0] ;
    logic [31        :0] g_data_in_up            [7  :0][7  :0] ;
    logic [7         :0] g_data_out_vld_up              [7  :0] ;
    logic [31        :0] g_data_out_up           [7  :0][7  :0] ;
    logic [7         :0] g_data_in_vld_down             [7  :0] ;
    logic [31        :0] g_data_in_down          [7  :0][7  :0] ;
    logic [7         :0] g_data_out_vld_down            [7  :0] ;
    logic [31        :0] g_data_out_down         [7  :0][7  :0] ; 

    generate;
        for(genvar i=0;i<8;i=i+1)begin//8份sram_bank组成一个sram_bank_group，所以每个bank有相同的8输入，也就是把8输入复制8份
            always_comb begin
                g_op_code_in[i]       = op_code_in          ;
                g_src_id_in[i]        = src_id_in           ;
                g_addr_in[i]          = addr_in             ;
                g_group_id_col_in[i]  = group_id_col_in     ;  
     
                g_data_in_vld_l[i]    = data_in_vld_l       ;
                g_data_in_l[i]        = data_in_l           ;

                g_data_in_vld_r[i]    = data_in_vld_r       ;
                g_data_in_r[i]        = data_in_r           ;

                g_data_in_vld_up[i]   = data_in_vld_up      ; 
                g_data_in_up[i]       = data_in_up          ;

                g_data_in_vld_down[i] = data_in_vld_down    ;
                g_data_in_down[i]     = data_in_down        ;

            end
        end
    endgenerate



    generate
        for(genvar i=0;i<8;i=i+1)begin
            sram_bank u_sram_bank(
                .clk                    (clk                ),
                .rst_n                  (rst_n              ),

                .op_code_in             (g_op_code_in[i]      ),
                .src_id_in              (g_src_id_in[i]       ),
                .addr_in                (g_addr_in[i]         ),
                .group_id_col_in        (g_group_id_col_in[i] ),
                .op_code_out            (g_op_code_out[i]     ),
                .src_id_out             (g_src_id_out[i]      ),
                .addr_out               (g_addr_out[i]        ),
                .group_id_col_out       (g_group_id_col_out[i]),
                .data_in_vld_l          (g_data_in_vld_l      ),
                .data_in_l              (g_data_in_l[i]       ),
                .data_out_vld_l         (g_data_out_vld_l     ),
                .data_out_l             (g_data_out_l[i]      ),
                .data_in_vld_r          (g_data_in_vld_r      ),
                .data_in_r              (g_data_in_r[i]       ),
                .data_out_vld_r         (g_data_out_vld_r     ),
                .data_out_r             (g_data_out_r[i]      ),
                .data_in_vld_up         (g_data_in_vld_up     ),
                .data_in_up             (g_data_in_up[i]      ),
                .data_out_vld_up        (g_data_out_vld_up    ),
                .data_out_up            (g_data_out_up[i]     ),
                .data_in_vld_down       (g_data_in_vld_down   ),
                .data_in_down           (g_data_in_down[i]    ),
                .data_out_vld_down      (g_data_out_vld_down  ),
                .data_out_down          (g_data_out_down[i]   )
            );
        end
    endgenerate

endmodule