module dataram_req_arb
    import vector_cache_pkg::*;
    (
    input  logic clk,
    input  logic rst_n,
    input  logic v_mshr_update_entry,
    input  mshr_entry_pld_t v_mshr_entry_pld[ENTRY_NUM-1:0],

    input  logic dataram_rd_vld,
    input  logic dataram_rd_pld,
    output logic dataram_rd_rdy,

    input  logic dataram_wr_vld,
    input  logic dataram_wr_pld,
    output logic dataram_wr_rdy,

    input  logic evict_rd_vld,
    input  logic evict_rd_pld,
    output logic evict_rd_rdy,

    input  logic downstream_rxdat_vld,
    input  logic downstream_rxdat_pld,
    output logic downstream_rxdat_rdy,

    output logic wr_en,
    output logic addr,
    output logic 

    );


endmodule