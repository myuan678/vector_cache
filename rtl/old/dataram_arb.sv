module dataram_arb 
    import vector_cache_pkg::*;
(
    input  logic                    clk,
    input  logic                    rst_n,
    input  mshr_entry_pld_t         v_mshr_entry_pld[ENTRY_NUM-1:0],
    input  logic                    upstream_txdat_rdy,

    input  logic                    dataram_rd_vld,
    input  rd_pld_t                 dataram_rd_pld,
    output logic                    dataram_rd_rdy,
    output logic                    rd_done,
    output logic                    rd_done_idx,

    input  logic                    dataram_wr_vld,
    input  wr_pld_t                 dataram_wr_pld,//with data
    output logic                    dataram_wr_rdy,
    output logic                    wr_done,
    output logic                    wr_done_idx,

    input  logic                    evict_rd_vld,
    input  evict_pld_t              evict_rd_pld,
    output logic                    evict_rd_rdy,
    output logic                    evict_clean,
    output logic                    evict_done,
    output logic                    evict_done_idx,

    input  logic                    linefill_req_vld,
    input  logic                    linefill_req_pld,
    output logic                    linefill_req_rdy,
    output logic                    linefill_done,
    output logic                    linefill_done_idx,

    output logic evict_data,
    output logic evict_data_vld,
    input  logic adp_done
    
);   
 logic dataram_rdy;
 //assign dataram_rdy = (mem_en==1'b0);

//===========================================
// dataram req arbiter
//===========================================

    assign dataram_req_vld = dataram_rd_vld || dataram_wr_vld || evict_rd_vld || linefill_req_vld;
    always_comb begin
        dataram_rd_rdy           = 1'b0;
        dataram_wr_rdy           = 1'b0;
        evict_rd_rdy             = 1'b0;
        downstream_rxdat_rdy     = 1'b0;
        wr_en                    = 1'b0;
        addr                     = 'b0;
        wr_data                  = 'b0;
        if(linefill_req_vld && dataram_rdy)begin
            dataram_rd_rdy       = 1'b1;
            dataram_wr_rdy       = 1'b0;
            evict_rd_rdy         = 1'b0;
            downstream_rxdat_rdy = 1'b0;
            wr_en                = 1'b1;
            addr                 = {linefill_req_pld.index,linefill_req_pld.way};
            wr_data              = linefill_req_pld.data;
        end
        else if(evict_rd_vld && dataram_rdy)begin
            dataram_rd_rdy       = 1'b0;
            dataram_wr_rdy       = 1'b0;
            evict_rd_rdy         = 1'b1;
            downstream_rxdat_rdy = 1'b0;
            wr_en                = 1'b0;
            addr                 = {evict_rd_pld.index,evict_rd_pld.way};
            wr_data              = 'b0;
        end
        else if(dataram_wr_vld && dataram_rdy)begin
            dataram_rd_rdy       = 1'b0;
            dataram_wr_rdy       = 1'b1;
            evict_rd_rdy         = 1'b0;
            downstream_rxdat_rdy = 1'b0;
            wr_en                = 1'b1;
            addr                 = {dataram_wr_pld.index,dataram_wr_pld.way};
            wr_data              = dataram_wr_pld.data;
        end
        else if(dataram_rd_vld && dataram_rdy)begin
            dataram_rd_rdy       = 1'b1;
            dataram_wr_rdy       = 1'b0;
            evict_rd_rdy         = 1'b0;
            downstream_rxdat_rdy = 1'b0;
            wr_en                = 1'b0;
            addr                 = {dataram_rd_pld.index, dataram_rd_pld.way};
            wr_data              = 'b0;
        end  
    end

    //linefill
    assign linefill_done = write_last;//每次linefill进入dataram，需要分四次，最后一次写入后，完成linefill
    assign rd_done        = dataram_rd_vld && dataram_rd_rdy;
    assign wr_done        = dataram_wr_vld && dataram_wr_rdy;
    assign evict_clean    = evict_rd_vld && evict_rd_rdy;
    assign evict_done     = adp_done;   

    assign linefill_ack_entry_idx = linefill_req_pld.entry_idx;
    assign rd_done_idx    = dataram_rd_pld.entry_idx;
    assign wr_done_idx    = dataram_wr_pld.entry_idx;
    assign evict_done_idx = evict_rd_pld.entry_idx;

    assign dataram_addr = {dataram_rd_pld.index, dataram_rd_pld.way,dataram_rd_pld.offset};
   







endmodule