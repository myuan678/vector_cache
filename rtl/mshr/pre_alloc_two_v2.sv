module pre_alloc_two #(
    parameter int unsigned ENTRY_NUM = 32,
    parameter int unsigned ENTRY_ID_WIDTH = $clog2(ENTRY_NUM)
)(
    input  logic                        clk         ,
    input  logic                        rst_n       ,
    
    input  logic [ENTRY_NUM-1       :0] v_in_vld    ,   // 1: entry is free
    output logic [ENTRY_NUM-1       :0] v_in_rdy    ,
    
    output logic                        out_vld_0   ,
    input  logic                        out_rdy_0   ,
    output logic                        out_vld_1   ,

    input  logic                        out_rdy_1   ,
    output logic [ENTRY_ID_WIDTH-1  :0] out_idx_0   ,
    output logic [ENTRY_ID_WIDTH-1  :0] out_idx_1
);

    logic [ENTRY_NUM-1      :0]         free_idx_oh_1  ;
    logic [ENTRY_ID_WIDTH-1 :0]         free_idx_bin_1 ;
    logic                               free_vld_1     ;
    logic [ENTRY_NUM-1      :0]         free_idx_oh_2  ;
    logic [ENTRY_ID_WIDTH-1 :0]         free_idx_bin_2 ;
    logic                               free_vld_2     ;
    logic [ENTRY_ID_WIDTH-1 :0]         stored_idx_0   ; 
    logic [ENTRY_ID_WIDTH-1 :0]         stored_idx_1   ;
    logic                               stored_vld_0   ; 
    logic                               stored_vld_1   ;  
    logic                               alloc_new_0    ; 
    logic                               alloc_new_1    ;
    logic                               consume_0      ;
    logic                               consume_1      ;

    cmn_lead_two #(
        .ENTRY_NUM(ENTRY_NUM)
    ) u_cmn_lead_two (
        .v_entry_vld        (v_in_vld       ),
        .v_free_idx_oh_1    (free_idx_oh_1  ),
        .v_free_idx_bin_1   (free_idx_bin_1 ),
        .v_free_vld_1       (free_vld_1     ),
        .v_free_idx_oh_2    (free_idx_oh_2  ),
        .v_free_idx_bin_2   (free_idx_bin_2 ),
        .v_free_vld_2       (free_vld_2     ));

    
    // Allocate
    assign alloc_new_0 = free_vld_1 && !stored_vld_0            ;
    assign alloc_new_1 = free_vld_2 && !stored_vld_1            ;
    assign consume_0   = stored_vld_0 && out_rdy_0              ;
    assign consume_1   = stored_vld_1 && out_rdy_1 && out_rdy_0 ;

    // Store idx_0
    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            stored_idx_0 <= '0              ;
            stored_vld_0 <= 1'b0            ;
        end 
        else if(alloc_new_0) begin
            stored_idx_0 <= free_idx_bin_1  ;
            stored_vld_0 <= 1'b1            ;
        end 
        else if(consume_0) begin
            stored_vld_0 <= 1'b0            ;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if(~rst_n) begin
            stored_idx_1 <= '0              ;
            stored_vld_1 <= 1'b0            ;
        end 
        else if(alloc_new_1) begin
            stored_idx_1 <= free_idx_bin_2  ;
            stored_vld_1 <= 1'b1            ;
        end 
        else if(consume_1) begin
            stored_vld_1 <= 1'b0            ;
        end
    end

    assign out_vld_0 = stored_vld_0             ;
    assign out_vld_1 = stored_vld_1 && out_rdy_0;  
    assign out_idx_0 = stored_idx_0             ;
    assign out_idx_1 = stored_idx_1             ;

    assign v_in_rdy = (alloc_new_0 ? free_idx_oh_1 : 'b0) | (alloc_new_1 ? free_idx_oh_2 : 'b0);

endmodule