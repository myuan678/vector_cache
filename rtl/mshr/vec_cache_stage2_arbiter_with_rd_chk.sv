module vec_cache_stage2_arbiter 
    import vector_cache_pkg::*; 
    #(
    parameter integer unsigned  CHANNEL_SHIFT_REG_WIDTH = 20,
    parameter integer unsigned  RAM_SHIFT_REG_WIDTH     = 20
    ) (
    input  logic                    clk                         ,
    input  logic                    rst_n                       ,

    input  logic                    dataram_rd_in_vld_w         ,
    input  logic                    dataram_rd_in_vld_e         ,
    input  logic                    dataram_rd_in_vld_s         ,
    input  logic                    dataram_rd_in_vld_n         ,
    input  logic                    dataram_rd_in_vld_ev        ,

    input  arb_out_req_t            dataram_rd_in_pld_w         ,
    input  arb_out_req_t            dataram_rd_in_pld_e         ,
    input  arb_out_req_t            dataram_rd_in_pld_s         ,
    input  arb_out_req_t            dataram_rd_in_pld_n         ,
    input  arb_out_req_t            dataram_rd_in_pld_ev        ,

    output logic                    dataram_rd_in_rdy_w         ,
    output logic                    dataram_rd_in_rdy_e         ,
    output logic                    dataram_rd_in_rdy_s         ,
    output logic                    dataram_rd_in_rdy_n         ,
    output logic                    dataram_rd_in_rdy_ev        ,

    input  logic                    dataram_wr_in_vld_w         ,
    input  logic                    dataram_wr_in_vld_e         ,
    input  logic                    dataram_wr_in_vld_s         ,
    input  logic                    dataram_wr_in_vld_n         ,
    input  logic                    dataram_wr_in_vld_lf        ,

    input  arb_out_req_t            dataram_wr_in_pld_w         ,
    input  arb_out_req_t            dataram_wr_in_pld_e         ,
    input  arb_out_req_t            dataram_wr_in_pld_s         ,
    input  arb_out_req_t            dataram_wr_in_pld_n         ,
    input  arb_out_req_t            dataram_wr_in_pld_lf        ,

    output logic                    dataram_wr_in_rdy_w         ,
    output logic                    dataram_wr_in_rdy_e         ,
    output logic                    dataram_wr_in_rdy_s         ,
    output logic                    dataram_wr_in_rdy_n         ,
    output logic                    dataram_wr_in_rdy_lf        ,

    output logic                    dataram_rd_out_vld_w        ,
    output logic                    dataram_rd_out_vld_e         ,
    output logic                    dataram_rd_out_vld_s         ,
    output logic                    dataram_rd_out_vld_n         ,
    output logic                    dataram_rd_out_vld_ev       ,  
    output arb_out_req_t            dataram_rd_out_pld_w        ,
    output arb_out_req_t            dataram_rd_out_pld_e        ,
    output arb_out_req_t            dataram_rd_out_pld_s        ,
    output arb_out_req_t            dataram_rd_out_pld_n         ,
    output arb_out_req_t            dataram_rd_out_pld_ev       ,

    output logic                    dataram_wr_out_vld_w        ,
    output logic                    dataram_wr_out_vld_e         ,
    output logic                    dataram_wr_out_vld_s         ,
    output logic                    dataram_wr_out_vld_n         ,
    output logic                    dataram_wr_out_vld_lf       ,  
    output arb_out_req_t            dataram_wr_out_pld_w        ,
    output arb_out_req_t            dataram_wr_out_pld_e        ,
    output arb_out_req_t            dataram_wr_out_pld_s        ,
    output arb_out_req_t            dataram_wr_out_pld_n        ,
    output arb_out_req_t            dataram_wr_out_pld_lf       ,   
    
    output arb_out_req_t            read_cmd_to_ram_pld_0       ,
    output arb_out_req_t            read_cmd_to_ram_pld_1       ,
    output logic                    read_cmd_to_ram_vld_0       ,
    output logic                    read_cmd_to_ram_vld_1              
    );


    localparam integer unsigned     RD_BLOCK0_DELAY = 1;
    localparam integer unsigned     RD_BLOCK1_DELAY = 2;
    localparam integer unsigned     RD_BLOCK2_DELAY = 3;
    localparam integer unsigned     RD_BLOCK3_DELAY = 4; 
    localparam integer unsigned     WR_BLOCK0_DELAY = 8;
    localparam integer unsigned     WR_BLOCK1_DELAY = 7;
    localparam integer unsigned     WR_BLOCK2_DELAY = 6;
    localparam integer unsigned     WR_BLOCK3_DELAY = 5; 

    

    logic                           dataram_rd_in_vld_permitted_w       ;
    logic                           dataram_rd_in_vld_permitted_e       ;
    logic                           dataram_rd_in_vld_permitted_s       ;
    logic                           dataram_rd_in_vld_permitted_n       ;
    logic                           dataram_rd_in_vld_permitted_ev      ;

    logic                           dataram_wr_in_vld_permitted_w       ;
    logic                           dataram_wr_in_vld_permitted_e       ;
    logic                           dataram_wr_in_vld_permitted_s       ;
    logic                           dataram_wr_in_vld_permitted_n       ;
    logic                           dataram_wr_in_vld_permitted_lf      ;

    logic [1    :0]                 ch_sr_update_en_w                   ;
    logic [1    :0]                 ch_sr_update_en_e                   ;
    logic [1    :0]                 ch_sr_update_en_s                   ;
    logic [1    :0]                 ch_sr_update_en_n                   ;
    logic [1    :0]                 ch_sr_update_en_lf                  ;
    logic [1    :0]                 channel_write_permission_w          ;
    logic [1    :0]                 channel_write_permission_e          ;
    logic [1    :0]                 channel_write_permission_s          ;
    logic [1    :0]                 channel_write_permission_n           ;
    logic [1    :0]                 channel_write_permission_lf         ;
    logic [1    :0]                 channel_read_permission             ;

    logic [7    :0]                 ram_sr_update_en_w                  ;
    logic [7    :0]                 ram_sr_update_en_e                  ;
    logic [7    :0]                 ram_sr_update_en_s                  ;
    logic [7    :0]                 ram_sr_update_en_n                   ;
    logic [7    :0]                 ram_sr_update_en_lf                 ;

    logic [7    :0]                 ram_write_permission_w               ;
    logic [7    :0]                 ram_write_permission_e              ;
    logic [7    :0]                 ram_write_permission_s              ;
    logic [7    :0]                 ram_write_permission_n               ;
    logic [7    :0]                 ram_write_permission_lf             ;
    logic [7    :0]                 ram_read_permission                  ;

    logic [4    :0]                 permitted_rd_vld                    ;
    arb_out_req_t                   permitted_rd_pld        [4:0]       ;


    assign dataram_rd_out_pld_w   = dataram_rd_in_pld_w ;
    assign dataram_rd_out_pld_e   = dataram_rd_in_pld_e ;
    assign dataram_rd_out_pld_s   = dataram_rd_in_pld_s ;
    assign dataram_rd_out_pld_n   = dataram_rd_in_pld_n ;
    assign dataram_rd_out_pld_ev  = dataram_rd_in_pld_ev;

    assign dataram_wr_out_pld_w   = dataram_wr_in_pld_w ;
    assign dataram_wr_out_pld_e   = dataram_wr_in_pld_e ;
    assign dataram_wr_out_pld_s   = dataram_wr_in_pld_s ;
    assign dataram_wr_out_pld_n   = dataram_wr_in_pld_n ;
    assign dataram_wr_out_pld_lf  = dataram_wr_in_pld_lf;

    //=============================================================================================
    // Permission check for read requests
    logic dataram_rd_in_vld_with_permission_w;
    logic dataram_rd_in_vld_with_permission_e;
    logic dataram_rd_in_vld_with_permission_s;
    logic dataram_rd_in_vld_with_permission_n;
    logic dataram_rd_in_vld_with_permission_ev;
    
    assign dataram_rd_in_vld_with_permission_w  = dataram_rd_in_vld_w  && channel_read_permission[dataram_rd_in_pld_w.dest_ram_id.channel_id]  && ram_read_permission[dataram_rd_in_pld_w.dest_ram_id];
    assign dataram_rd_in_vld_with_permission_e  = dataram_rd_in_vld_e  && channel_read_permission[dataram_rd_in_pld_e.dest_ram_id.channel_id]  && ram_read_permission[dataram_rd_in_pld_e.dest_ram_id];
    assign dataram_rd_in_vld_with_permission_s  = dataram_rd_in_vld_s  && channel_read_permission[dataram_rd_in_pld_s.dest_ram_id.channel_id]  && ram_read_permission[dataram_rd_in_pld_s.dest_ram_id];
    assign dataram_rd_in_vld_with_permission_n  = dataram_rd_in_vld_n  && channel_read_permission[dataram_rd_in_pld_n.dest_ram_id.channel_id]  && ram_read_permission[dataram_rd_in_pld_n.dest_ram_id];
    assign dataram_rd_in_vld_with_permission_ev = dataram_rd_in_vld_ev && channel_read_permission[dataram_rd_in_pld_ev.dest_ram_id.channel_id] && ram_read_permission[dataram_rd_in_pld_ev.dest_ram_id];
    
    // RAM ID deduplication for read requests: only keep the highest priority request for each RAM
    // Priority order: w(4) > e(3) > s(2) > n(1) > ev(0)
    // This ensures that if two read requests are selected, they will access different RAMs
    logic rd_ram_id_conflict_e, rd_ram_id_conflict_s, rd_ram_id_conflict_n, rd_ram_id_conflict_ev;
    
    assign rd_ram_id_conflict_e = dataram_rd_in_vld_with_permission_w && 
                                  (dataram_rd_in_pld_e.dest_ram_id == dataram_rd_in_pld_w.dest_ram_id);
    
    assign rd_ram_id_conflict_s = (dataram_rd_in_vld_with_permission_w && 
                                   (dataram_rd_in_pld_s.dest_ram_id == dataram_rd_in_pld_w.dest_ram_id)) ||
                                  (dataram_rd_in_vld_with_permission_e && 
                                   (dataram_rd_in_pld_s.dest_ram_id == dataram_rd_in_pld_e.dest_ram_id));
    
    assign rd_ram_id_conflict_n = (dataram_rd_in_vld_with_permission_w && 
                                   (dataram_rd_in_pld_n.dest_ram_id == dataram_rd_in_pld_w.dest_ram_id)) ||
                                  (dataram_rd_in_vld_with_permission_e && 
                                   (dataram_rd_in_pld_n.dest_ram_id == dataram_rd_in_pld_e.dest_ram_id)) ||
                                  (dataram_rd_in_vld_with_permission_s && 
                                   (dataram_rd_in_pld_n.dest_ram_id == dataram_rd_in_pld_s.dest_ram_id));
    
    assign rd_ram_id_conflict_ev = (dataram_rd_in_vld_with_permission_w && 
                                    (dataram_rd_in_pld_ev.dest_ram_id == dataram_rd_in_pld_w.dest_ram_id)) ||
                                   (dataram_rd_in_vld_with_permission_e && 
                                    (dataram_rd_in_pld_ev.dest_ram_id == dataram_rd_in_pld_e.dest_ram_id)) ||
                                   (dataram_rd_in_vld_with_permission_s && 
                                    (dataram_rd_in_pld_ev.dest_ram_id == dataram_rd_in_pld_s.dest_ram_id)) ||
                                   (dataram_rd_in_vld_with_permission_n && 
                                    (dataram_rd_in_pld_ev.dest_ram_id == dataram_rd_in_pld_n.dest_ram_id));
    
    // Final permitted read requests: permission check + RAM ID deduplication
    assign dataram_rd_in_vld_permitted_w  = dataram_rd_in_vld_with_permission_w;  // Highest priority, no conflict
    assign dataram_rd_in_vld_permitted_e  = dataram_rd_in_vld_with_permission_e && !rd_ram_id_conflict_e;
    assign dataram_rd_in_vld_permitted_s  = dataram_rd_in_vld_with_permission_s && !rd_ram_id_conflict_s;
    assign dataram_rd_in_vld_permitted_n  = dataram_rd_in_vld_with_permission_n && !rd_ram_id_conflict_n;
    assign dataram_rd_in_vld_permitted_ev = dataram_rd_in_vld_with_permission_ev && !rd_ram_id_conflict_ev;

    // Permission check for write requests (no deduplication needed)
    assign dataram_wr_in_vld_permitted_w  = dataram_wr_in_vld_w  && channel_write_permission_w [dataram_wr_in_pld_w .dest_ram_id.channel_id] && (ram_write_permission_w [dataram_wr_in_pld_w .dest_ram_id]);
    assign dataram_wr_in_vld_permitted_e  = dataram_wr_in_vld_e  && channel_write_permission_e [dataram_wr_in_pld_e .dest_ram_id.channel_id] && (ram_write_permission_e [dataram_wr_in_pld_e .dest_ram_id]);
    assign dataram_wr_in_vld_permitted_s  = dataram_wr_in_vld_s  && channel_write_permission_s [dataram_wr_in_pld_s .dest_ram_id.channel_id] && (ram_write_permission_s [dataram_wr_in_pld_s .dest_ram_id]);
    assign dataram_wr_in_vld_permitted_n  = dataram_wr_in_vld_n  && channel_write_permission_n [dataram_wr_in_pld_n .dest_ram_id.channel_id] && (ram_write_permission_n [dataram_wr_in_pld_n .dest_ram_id]);
    assign dataram_wr_in_vld_permitted_lf = dataram_wr_in_vld_lf && channel_write_permission_lf[dataram_wr_in_pld_lf.dest_ram_id.channel_id] && (ram_write_permission_lf[dataram_wr_in_pld_lf.dest_ram_id]);

    vec_cache_vr_2grant_arb u_vr_2grant_arb ( 
        .dataram_rd_in_vld_w        (dataram_rd_in_vld_permitted_w      ),
        .dataram_rd_in_vld_e        (dataram_rd_in_vld_permitted_e      ),
        .dataram_rd_in_vld_s        (dataram_rd_in_vld_permitted_s      ),
        .dataram_rd_in_vld_n        (dataram_rd_in_vld_permitted_n      ),
        .dataram_rd_in_vld_ev       (dataram_rd_in_vld_permitted_ev     ),
        .dataram_rd_in_rdy_w        (dataram_rd_in_rdy_w                ),
        .dataram_rd_in_rdy_e        (dataram_rd_in_rdy_e                ),
        .dataram_rd_in_rdy_s        (dataram_rd_in_rdy_s                ),
        .dataram_rd_in_rdy_n        (dataram_rd_in_rdy_n                ),
        .dataram_rd_in_rdy_ev       (dataram_rd_in_rdy_ev               ),
        .dataram_wr_in_vld_w        (dataram_wr_in_vld_permitted_w      ),
        .dataram_wr_in_vld_e        (dataram_wr_in_vld_permitted_e      ),
        .dataram_wr_in_vld_s        (dataram_wr_in_vld_permitted_s      ),
        .dataram_wr_in_vld_n        (dataram_wr_in_vld_permitted_n      ),
        .dataram_wr_in_vld_lf       (dataram_wr_in_vld_permitted_lf     ),
        .dataram_wr_in_rdy_w        (dataram_wr_in_rdy_w                ),
        .dataram_wr_in_rdy_e        (dataram_wr_in_rdy_e                ),
        .dataram_wr_in_rdy_s        (dataram_wr_in_rdy_s                ),
        .dataram_wr_in_rdy_n        (dataram_wr_in_rdy_n                ),
        .dataram_wr_in_rdy_lf       (dataram_wr_in_rdy_lf               ),
        .dataram_rd_out_vld_w       (dataram_rd_out_vld_w               ),
        .dataram_rd_out_vld_e       (dataram_rd_out_vld_e               ),
        .dataram_rd_out_vld_s       (dataram_rd_out_vld_s               ),
        .dataram_rd_out_vld_n       (dataram_rd_out_vld_n               ),
        .dataram_rd_out_vld_ev      (dataram_rd_out_vld_ev              ),
        .dataram_wr_out_vld_w       (dataram_wr_out_vld_w               ),
        .dataram_wr_out_vld_e       (dataram_wr_out_vld_e               ),
        .dataram_wr_out_vld_s       (dataram_wr_out_vld_s               ),
        .dataram_wr_out_vld_n       (dataram_wr_out_vld_n               ),
        .dataram_wr_out_vld_lf      (dataram_wr_out_vld_lf              ));


        
    generate for(genvar i=0;i<2;i=i+1) begin
        assign ch_sr_update_en_w    [i] = (dataram_wr_out_pld_w.dest_ram_id.channel_id == i) && dataram_wr_out_vld_w;
        assign ch_sr_update_en_e    [i] = (dataram_wr_out_pld_e.dest_ram_id.channel_id == i) && dataram_wr_out_vld_e;
        assign ch_sr_update_en_s    [i] = (dataram_wr_out_pld_s.dest_ram_id.channel_id == i) && dataram_wr_out_vld_s;
        assign ch_sr_update_en_n    [i] = (dataram_wr_out_pld_n.dest_ram_id.channel_id == i) && dataram_wr_out_vld_n;
        assign ch_sr_update_en_lf   [i] = (dataram_wr_out_pld_lf.dest_ram_id.channel_id== i) && dataram_wr_out_vld_lf;

        vec_cache_channel_shift_reg  #( 
            .CHANNEL_SHIFT_REG_WIDTH(20)) 
        u_channel_sr (
            .clk                   (clk                             ),    
            .rst_n                 (rst_n                           ),

            .update_en_w           (ch_sr_update_en_w [i]           ),
            .update_en_e           (ch_sr_update_en_e [i]           ),
            .update_en_s           (ch_sr_update_en_s [i]           ),
            .update_en_n           (ch_sr_update_en_n [i]           ),
            .update_en_lf          (ch_sr_update_en_lf[i]           ),

            .write_permission_w    (channel_write_permission_w [i]  ),
            .write_permission_e    (channel_write_permission_e [i]  ),
            .write_permission_s    (channel_write_permission_s [i]  ),
            .write_permission_n    (channel_write_permission_n [i]  ),
            .write_permission_lf   (channel_write_permission_lf[i]  ),

            .read_permission       (channel_read_permission    [i]  ));
    end endgenerate


    
    generate
        for(genvar i=0;i<2;i=i+1)begin
            assign ram_sr_update_en_w[i]  = dataram_wr_out_vld_w  && (dataram_wr_out_pld_w.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_w.dest_ram_id.block_id == 2'd0);
            assign ram_sr_update_en_e[i]  = dataram_wr_out_vld_e  && (dataram_wr_out_pld_e.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_e.dest_ram_id.block_id == 2'd0);
            assign ram_sr_update_en_s[i]  = dataram_wr_out_vld_s  && (dataram_wr_out_pld_s.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_s.dest_ram_id.block_id == 2'd0);
            assign ram_sr_update_en_n[i]  = dataram_wr_out_vld_n  && (dataram_wr_out_pld_n.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_n.dest_ram_id.block_id == 2'd0);
            assign ram_sr_update_en_lf[i] = dataram_wr_out_vld_lf && (dataram_wr_out_pld_lf.dest_ram_id.channel_id== i) && (dataram_wr_out_pld_lf.dest_ram_id.block_id== 2'd0);
            vec_cache_ram_shift_reg  #( 
                .RAM_SHIFT_REG_WIDTH    (20                             ),
                .RAM_BLOCK_WRITE_DELAY  (WR_BLOCK0_DELAY                ), 
                .RAM_BLOCK_READ_DELAY   (RD_BLOCK0_DELAY                )) 
            u_ram_shifte_reg ( 
                .clk                    (clk                            ),
                .rst_n                  (rst_n                          ),
                .update_en_w            (ram_sr_update_en_w [i]         ),
                .update_en_e            (ram_sr_update_en_e [i]         ),
                .update_en_s            (ram_sr_update_en_s [i]         ),
                .update_en_n            (ram_sr_update_en_n [i]         ),
                .update_en_lf           (ram_sr_update_en_lf[i]         ),

                .write_permission_w     (ram_write_permission_w [i]     ),
                .write_permission_e     (ram_write_permission_e [i]     ),
                .write_permission_s     (ram_write_permission_s [i]     ),
                .write_permission_n     (ram_write_permission_n [i]     ),
                .write_permission_lf    (ram_write_permission_lf[i]     ),
                .read_permission        (ram_read_permission[i]         ));
        end
    endgenerate

    generate
        for(genvar i=0;i<2;i=i+1)begin
            assign ram_sr_update_en_w[i+2]  = dataram_wr_out_vld_w  && (dataram_wr_out_pld_w.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_w.dest_ram_id.block_id == 2'd1);
            assign ram_sr_update_en_e[i+2]  = dataram_wr_out_vld_e  && (dataram_wr_out_pld_e.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_e.dest_ram_id.block_id == 2'd1);
            assign ram_sr_update_en_s[i+2]  = dataram_wr_out_vld_s  && (dataram_wr_out_pld_s.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_s.dest_ram_id.block_id == 2'd1);
            assign ram_sr_update_en_n[i+2]  = dataram_wr_out_vld_n  && (dataram_wr_out_pld_n.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_n.dest_ram_id.block_id == 2'd1);
            assign ram_sr_update_en_lf[i+2] = dataram_wr_out_vld_lf && (dataram_wr_out_pld_lf.dest_ram_id.channel_id== i) && (dataram_wr_out_pld_lf.dest_ram_id.block_id== 2'd1);
            vec_cache_ram_shift_reg  #( 
                .RAM_SHIFT_REG_WIDTH    (20                             ),
                .RAM_BLOCK_WRITE_DELAY  (WR_BLOCK1_DELAY                ), 
                .RAM_BLOCK_READ_DELAY   (RD_BLOCK1_DELAY                )) 
            u_ram_shifte_reg ( 
                .clk                    (clk                            ),
                .rst_n                  (rst_n                          ),
                .update_en_w            (ram_sr_update_en_w [i+2]       ),
                .update_en_e            (ram_sr_update_en_e [i+2]       ),
                .update_en_s            (ram_sr_update_en_s [i+2]       ),
                .update_en_n            (ram_sr_update_en_n [i+2]       ),
                .update_en_lf           (ram_sr_update_en_lf[i+2]       ),

                .write_permission_w     (ram_write_permission_w [i+2]   ),
                .write_permission_e     (ram_write_permission_e [i+2]   ),
                .write_permission_s     (ram_write_permission_s [i+2]   ),
                .write_permission_n     (ram_write_permission_n [i+2]   ),
                .write_permission_lf    (ram_write_permission_lf[i+2]   ),
                .read_permission        (ram_read_permission[i+2]       ));
        end
    endgenerate

    generate
        for(genvar i=0;i<2;i=i+1)begin
            assign ram_sr_update_en_w[i+4]  = dataram_wr_out_vld_w  && (dataram_wr_out_pld_w.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_w.dest_ram_id.block_id == 2'd2);
            assign ram_sr_update_en_e[i+4]  = dataram_wr_out_vld_e  && (dataram_wr_out_pld_e.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_e.dest_ram_id.block_id == 2'd2);
            assign ram_sr_update_en_s[i+4]  = dataram_wr_out_vld_s  && (dataram_wr_out_pld_s.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_s.dest_ram_id.block_id == 2'd2);
            assign ram_sr_update_en_n[i+4]  = dataram_wr_out_vld_n  && (dataram_wr_out_pld_n.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_n.dest_ram_id.block_id == 2'd2);
            assign ram_sr_update_en_lf[i+4] = dataram_wr_out_vld_lf && (dataram_wr_out_pld_lf.dest_ram_id.channel_id== i) && (dataram_wr_out_pld_lf.dest_ram_id.block_id== 2'd2);
            vec_cache_ram_shift_reg  #( 
                .RAM_SHIFT_REG_WIDTH    (20                             ),
                .RAM_BLOCK_WRITE_DELAY  (WR_BLOCK2_DELAY                ), 
                .RAM_BLOCK_READ_DELAY   (RD_BLOCK2_DELAY                )) 
            u_ram_shifte_reg ( 
                .clk                    (clk                            ),
                .rst_n                  (rst_n                          ),
                .update_en_w            (ram_sr_update_en_w [i+4]       ),
                .update_en_e            (ram_sr_update_en_e [i+4]       ),
                .update_en_s            (ram_sr_update_en_s [i+4]       ),
                .update_en_n            (ram_sr_update_en_n [i+4]       ),
                .update_en_lf           (ram_sr_update_en_lf[i+4]       ),

                .write_permission_w     (ram_write_permission_w [i+4]   ),
                .write_permission_e     (ram_write_permission_e [i+4]   ),
                .write_permission_s     (ram_write_permission_s [i+4]   ),
                .write_permission_n     (ram_write_permission_n [i+4]   ),
                .write_permission_lf    (ram_write_permission_lf[i+4]   ),
                .read_permission        (ram_read_permission[i+4]       ));
        end
    endgenerate

    generate
        for(genvar i=0;i<2;i=i+1)begin
            assign ram_sr_update_en_w[i+6]  = dataram_wr_out_vld_w  && (dataram_wr_out_pld_w.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_w.dest_ram_id.block_id == 2'd3);
            assign ram_sr_update_en_e[i+6]  = dataram_wr_out_vld_e  && (dataram_wr_out_pld_e.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_e.dest_ram_id.block_id == 2'd3);
            assign ram_sr_update_en_s[i+6]  = dataram_wr_out_vld_s  && (dataram_wr_out_pld_s.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_s.dest_ram_id.block_id == 2'd3);
            assign ram_sr_update_en_n[i+6]  = dataram_wr_out_vld_n  && (dataram_wr_out_pld_n.dest_ram_id.channel_id == i) && (dataram_wr_out_pld_n.dest_ram_id.block_id == 2'd3);
            assign ram_sr_update_en_lf[i+6] = dataram_wr_out_vld_lf && (dataram_wr_out_pld_lf.dest_ram_id.channel_id== i) && (dataram_wr_out_pld_lf.dest_ram_id.block_id== 2'd3);
            vec_cache_ram_shift_reg  #( 
                .RAM_SHIFT_REG_WIDTH    (20                             ),
                .RAM_BLOCK_WRITE_DELAY  (WR_BLOCK3_DELAY                ), 
                .RAM_BLOCK_READ_DELAY   (RD_BLOCK3_DELAY                )) 
            u_ram_shifte_reg ( 
                .clk                    (clk                            ),
                .rst_n                  (rst_n                          ),
                .update_en_w            (ram_sr_update_en_w [i+6]       ),
                .update_en_e            (ram_sr_update_en_e [i+6]       ),
                .update_en_s            (ram_sr_update_en_s [i+6]       ),
                .update_en_n            (ram_sr_update_en_n [i+6]       ),
                .update_en_lf           (ram_sr_update_en_lf[i+6]       ),

                .write_permission_w     (ram_write_permission_w [i+6]   ),
                .write_permission_e     (ram_write_permission_e [i+6]   ),
                .write_permission_s     (ram_write_permission_s [i+6]   ),
                .write_permission_n     (ram_write_permission_n [i+6]   ),
                .write_permission_lf    (ram_write_permission_lf[i+6]   ),
                .read_permission        (ram_read_permission[i+6]       ));
        end
    endgenerate

        
        assign permitted_rd_vld[4] = dataram_rd_out_vld_w ;
        assign permitted_rd_vld[3] = dataram_rd_out_vld_e ;
        assign permitted_rd_vld[2] = dataram_rd_out_vld_s ;
        assign permitted_rd_vld[1] = dataram_rd_out_vld_n ;
        assign permitted_rd_vld[0] = dataram_rd_out_vld_ev;
        assign permitted_rd_pld[4] = dataram_rd_out_pld_w ;
        assign permitted_rd_pld[3] = dataram_rd_out_pld_e ;
        assign permitted_rd_pld[2] = dataram_rd_out_pld_s ;
        assign permitted_rd_pld[1] = dataram_rd_out_pld_n ;
        assign permitted_rd_pld[0] = dataram_rd_out_pld_ev;

        always_comb begin
            read_cmd_to_ram_vld_0 = 1'b0;
            read_cmd_to_ram_pld_0 = '0;
            read_cmd_to_ram_vld_1 = 1'b0;
            read_cmd_to_ram_pld_1 = '0;
            for (int i=0; i<5; i=i+1) begin
                if (permitted_rd_vld[i]) begin
                    if (!read_cmd_to_ram_vld_0) begin
                        read_cmd_to_ram_vld_0 = 1'b1;
                        read_cmd_to_ram_pld_0 = permitted_rd_pld[i];
                    end
                    else if (!read_cmd_to_ram_vld_1) begin
                        read_cmd_to_ram_vld_1 = 1'b1;
                        read_cmd_to_ram_pld_1 = permitted_rd_pld[i];
                    end
                end
            end
        end



endmodule

