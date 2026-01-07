module srrip  #( 
        parameter integer unsigned INDEX_WIDTH = 10 ,
        parameter integer unsigned RRPV_WIDTH  = 2  ,
        parameter integer unsigned WAY_NUM     = 4  ,
        parameter integer unsigned SET_NUM     = 1024
    )( 
        input  logic                        clk                 ,
        input  logic                        rst_n               ,
        input  logic                        req_vld_0           ,
        input  logic[INDEX_WIDTH-1      :0] req_index_0         ,
        input  logic                        hit_0               ,
        input  logic[WAY_NUM-1          :0] hit_way_oh_0        ,
        input  logic                        req_vld_1           ,
        input  logic[INDEX_WIDTH-1      :0] req_index_1         ,
        input  logic                        hit_1               ,
        input  logic[WAY_NUM-1          :0] hit_way_oh_1        ,
        input  logic                        miss_0              ,
        input  logic                        miss_1              ,
        output logic[$clog2(WAY_NUM)-1  :0] replace_way_0       ,
        output logic[$clog2(WAY_NUM)-1  :0] replace_way_1       ,
        output logic                        replace_vld_0       ,
        output logic                        replace_vld_1
    );

    localparam MAX_RRPV   = {RRPV_WIDTH{1'b1}}                          ;//2'b11
    localparam INSET_RRPV = MAX_RRPV-1                                  ;
    logic [RRPV_WIDTH-1      :0] rrpv_array [SET_NUM-1:0][WAY_NUM-1:0]  ;
    logic [$clog2(WAY_NUM)-1 :0] hit_way_0                              ;
    logic [$clog2(WAY_NUM)-1 :0] hit_way_1                              ;
    cmn_onehot2bin #( 
        .ONEHOT_WIDTH(WAY_NUM       ))
    u_hitway_bin_0( 
        .onehot_in  (hit_way_oh_0   ),
        .bin_out    (hit_way_0      ));
    cmn_onehot2bin #( 
        .ONEHOT_WIDTH(WAY_NUM       ))
    u_hitway_bin_1( 
        .onehot_in  (hit_way_oh_1   ),
        .bin_out    (hit_way_1      ));

    function automatic int find_victim(input logic [INDEX_WIDTH-1:0] index);
        int victim_way = -1;
        for(int i=0; i<WAY_NUM; i=i+1)begin
            if(rrpv_array[index][i] == MAX_RRPV)begin
                victim_way = i;
                break;
            end
        end
        if(victim_way == -1)begin
            for(int i=0;i<WAY_NUM;i=i+1)begin
                if(rrpv_array[index][i] !== MAX_RRPV)begin
                    rrpv_array[index][i] = rrpv_array[index][i] + {{(RRPV_WIDTH-1){1'b0}},1'b1};
                end
            end
            victim_way = find_victim(index);
        end
        return victim_way;
    endfunction

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            replace_vld_0 <= 1'b0;
            replace_vld_1 <= 1'b0;
        end
        else begin
            replace_vld_0 <= req_vld_0 && miss_0;
            replace_vld_1 <= req_vld_1 && miss_1;
        end
    end

    always_ff@(posedge clk or negedge rst_n)begin
        if(!rst_n)begin
            for(int i=0;i<SET_NUM;i=i+1)begin
                for(int j=0;j<WAY_NUM;j=j+1)begin
                    rrpv_array[i][j] <= MAX_RRPV;//初始值为2'b11
                end
            end
            replace_way_0 <= 'b0;
            replace_way_1 <= 'b0;
        end
        else begin
            if(req_vld_0 && hit_0)begin
                rrpv_array[req_index_0][hit_way_0] <= 'b0;
                replace_way_0 <= 'b0;
            end
            else if(req_vld_0 && miss_0)begin
                int find_victim_way;
                find_victim_way                         = find_victim(req_index_0);
                replace_way_0                           <= find_victim_way        ;
                rrpv_array[req_index_0][find_victim_way]<= INSET_RRPV             ;//新插入的rrpv值定为2
            end
            else begin
                replace_way_0 <= 'b0;
            end

            if(req_vld_1 && hit_1)begin
                rrpv_array[req_index_1][hit_way_1] <= 'b0;
            end
            else if(req_vld_1 && miss_1)begin
                automatic  int find_victim_way;
                find_victim_way                         = find_victim(req_index_1);
                replace_way_1                           <= find_victim_way        ;
                rrpv_array[req_index_1][find_victim_way]<= INSET_RRPV             ;//新插入的rrpv值定为2
            end
            else begin
                replace_way_1 <= 'b0;
            end
        end
    end



endmodule



module srrip_dual #(
    parameter NUM_SETS   = 64,
    parameter NUM_WAYS   = 4,
    parameter RRPV_BITS  = 2
)(
    input  logic                        clk         ,
    input  logic                        rst_n       ,

    input  logic [$clog2(NUM_SETS)-1:0] set_idx0    ,
    input  logic                        access_vld0 ,
    input  logic                        hit0        ,
    input  logic [$clog2(NUM_WAYS)-1:0] hit_way0    ,
    input  logic                        miss_req0   ,
    output logic [$clog2(NUM_WAYS)-1:0] victim_way0 ,
    output logic                        victim_vld0 ,

    input  logic [$clog2(NUM_SETS)-1:0] set_idx1    ,
    input  logic                        access_vld1 ,
    input  logic                        hit1        ,
    input  logic [$clog2(NUM_WAYS)-1:0] hit_way1    ,
    input  logic                        miss_req1   ,
    output logic [$clog2(NUM_WAYS)-1:0] victim_way1 ,
    output logic                        victim_vld1
);

    // ----------------------------
    // RRPV 存储
    // ----------------------------
    logic [RRPV_BITS-1:0] rrpv_array [0:NUM_SETS-1][0:NUM_WAYS-1];
    function automatic logic [$clog2(NUM_WAYS)-1:0] find_victim(
        input logic [$clog2(NUM_SETS)-1:0] set_idx
    );
        logic   found   ;
        begin
            found = 1'b0;
            find_victim = '0;
            for (int way = 0; way < NUM_WAYS; way++) begin
                if (!found && rrpv_array[set_idx][way] == {RRPV_BITS{1'b1}}) begin
                    find_victim = way[$clog2(NUM_WAYS)-1:0];
                    found       = 1'b1;
                end
            end
        end
    endfunction
    function automatic logic [$clog2(NUM_WAYS)-1:0] find_victim_exclude(
        input logic [$clog2(NUM_SETS)-1:0] set_idx,
        input logic [$clog2(NUM_WAYS)-1:0] exclude_way
    );
        logic found;
        begin
            found = 1'b0;
            find_victim_exclude = 'b0;
            for (int way = 0; way < NUM_WAYS; way++) begin
                if (!found && (way[$clog2(NUM_WAYS)-1:0] !== exclude_way) && (rrpv_array[set_idx][way] == {RRPV_BITS{1'b1}})) begin
                    find_victim_exclude = way[$clog2(NUM_WAYS)-1:0];
                    found               = 1'b1;
                end
            end
        end
    endfunction


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < NUM_WAYS; w++) begin
                    rrpv_array[s][w] <= {RRPV_BITS{1'b1}};
                end
            end
            victim_vld0 <= 1'b0;
            victim_vld1 <= 1'b0;
        end 
        else begin
            if (access_vld0 && hit0)//hit
                rrpv_array[set_idx0][hit_way0] <= '0;

            if (access_vld1 && hit1)
                rrpv_array[set_idx1][hit_way1] <= '0;


            victim_vld0 <= 1'b0;
            victim_vld1 <= 1'b0;
            if (miss_req0) begin
                victim_way0 <= find_victim(set_idx0);
                victim_vld0 <= 1'b1;
                rrpv_array[set_idx0][victim_way0] <= 2; //set insert RRPV = 2'd2
            end

            if (miss_req1) begin
                if (miss_req0 && (set_idx0 == set_idx1)) begin
                    victim_way1 <= find_victim_exclude(set_idx1, victim_way0);
                end 
                else begin
                    victim_way1 <= find_victim(set_idx1);
                end
                victim_vld1                         <= 1'b1;
                rrpv_array[set_idx1][victim_way1]   <= 2; //set insert RRPV = 2'd2
            end

            // ---------- Aging ----------
            // 如果某 set 全部不是 max，find_victim 不会选到 所有+1
            for (int s = 0; s < NUM_SETS; s++) begin
                for (int w = 0; w < NUM_WAYS; w++) begin
                    if (rrpv_array[s][w] != {RRPV_BITS{1'b1}})begin
                        rrpv_array[s][w] <= rrpv_array[s][w] + 1'b1;
                    end
                end
            end
        end
    end

endmodule
