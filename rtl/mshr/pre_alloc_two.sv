module pre_alloc_two #(
    parameter int unsigned ENTRY_NUM      = 32,
    parameter int unsigned ENTRY_ID_WIDTH = $clog2(ENTRY_NUM)
)(
    input  logic                        clk         ,
    input  logic                        rst_n       ,
    
    // Free entry pool interface
    input  logic [ENTRY_NUM-1:0]        v_in_vld    ,   // 1: entry is free/available
    output logic [ENTRY_NUM-1:0]        v_in_rdy    ,   // 1: entry was allocated this cycle
    
    // Output port 0 (highest priority)
    output logic                        out_vld_0   ,
    input  logic                        out_rdy_0   ,
    output logic [ENTRY_ID_WIDTH-1:0]   out_idx_0   ,
    
    // Output port 1 (lower priority, depends on port 0)
    output logic                        out_vld_1   ,
    input  logic                        out_rdy_1   ,
    output logic [ENTRY_ID_WIDTH-1:0]   out_idx_1
);

    // ========================================================================
    // Internal Signals
    // ========================================================================
    
    // Free entry search results
    logic [ENTRY_NUM-1:0]       free_idx_oh_1   ;   // One-hot encoding of first free entry
    logic [ENTRY_ID_WIDTH-1:0]  free_idx_bin_1  ;   // Binary encoding of first free entry
    logic                       free_vld_1      ;   // Valid flag for first free entry
    
    logic [ENTRY_NUM-1:0]       free_idx_oh_2   ;   // One-hot encoding of second free entry
    logic [ENTRY_ID_WIDTH-1:0]  free_idx_bin_2  ;   // Binary encoding of second free entry
    logic                       free_vld_2      ;   // Valid flag for second free entry
    
    // Stored entry IDs
    logic [ENTRY_ID_WIDTH-1:0]  stored_idx_0    ;   // Stored entry ID for port 0
    logic [ENTRY_ID_WIDTH-1:0]  stored_idx_1    ;   // Stored entry ID for port 1
    logic                       stored_vld_0    ;   // Valid flag for stored port 0 entry
    logic                       stored_vld_1    ;   // Valid flag for stored port 1 entry
    
    // Control signals
    logic                       alloc_new_0     ;   // Allocate new entry for port 0
    logic                       alloc_new_1     ;   // Allocate new entry for port 1
    logic                       consume_0       ;   // Consume stored entry 0
    logic                       consume_1       ;   // Consume stored entry 1

    // ========================================================================
    // Find First Two Free Entries
    // ========================================================================
    // This module searches the v_in_vld vector and returns the indices of
    // the first two free (valid) entries in both one-hot and binary formats
    
    cmn_lead_two #(
        .ENTRY_NUM(ENTRY_NUM)
    ) u_cmn_lead_two (
        .v_entry_vld        (v_in_vld       ),
        .v_free_idx_oh_1    (free_idx_oh_1  ),
        .v_free_idx_bin_1   (free_idx_bin_1 ),
        .v_free_vld_1       (free_vld_1     ),
        .v_free_idx_oh_2    (free_idx_oh_2  ),
        .v_free_idx_bin_2   (free_idx_bin_2 ),
        .v_free_vld_2       (free_vld_2     )
    );

    // ========================================================================
    // Control Logic
    // ========================================================================
    
    // Allocate new entry when:
    // - A free entry is available from the search
    // - No entry is currently stored for that port
    assign alloc_new_0 = free_vld_1 && !stored_vld_0;
    assign alloc_new_1 = free_vld_2 && !stored_vld_1;
    
    // Consume stored entry when:
    // - Stored entry is valid
    // - Downstream is ready to accept
    // - For port 1: port 0 must also be ready (sequential ordering)
    assign consume_0 = stored_vld_0 && out_rdy_0;
    assign consume_1 = stored_vld_1 && out_rdy_1 && out_rdy_0;

    // ========================================================================
    // Port 0 Storage Register
    // ========================================================================
    // Stores the first available entry ID until consumed
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_idx_0 <= '0;
            stored_vld_0 <= 1'b0;
        end else if (alloc_new_0) begin
            // Allocate new entry
            stored_idx_0 <= free_idx_bin_1;
            stored_vld_0 <= 1'b1;
        end else if (consume_0) begin
            // Entry consumed by downstream
            stored_vld_0 <= 1'b0;
        end
    end

    // ========================================================================
    // Port 1 Storage Register
    // ========================================================================
    // Stores the second available entry ID until consumed
    
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stored_idx_1 <= '0;
            stored_vld_1 <= 1'b0;
        end else if (alloc_new_1) begin
            // Allocate new entry
            stored_idx_1 <= free_idx_bin_2;
            stored_vld_1 <= 1'b1;
        end else if (consume_1) begin
            // Entry consumed by downstream
            stored_vld_1 <= 1'b0;
        end
    end

    // ========================================================================
    // Output Assignments
    // ========================================================================
    
    // Port 0 outputs
    assign out_vld_0 = stored_vld_0;
    assign out_idx_0 = stored_idx_0;
    
    // Port 1 outputs (valid only when port 0 is ready)
    assign out_vld_1 = stored_vld_1 && out_rdy_0;
    assign out_idx_1 = stored_idx_1;
    
endmodule