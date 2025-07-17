//module crossbar_8x4 #(
module nto4_xbar #(
    parameter integer unsigned N = 8, // 输入端口数量
    parameter integer unsigned PLD_WIDTH=32,
    parameter PAYLOAD_WIDTH = 32
) (
    input  wire                         clk,
    input  wire                         rst_n,
    input  wire [N-1:0]                 in_vld,
    output wire [N-1:0]                 in_rdy,
    input  wire [PAYLOAD_WIDTH-1:0]     in_pld[N-1:0],
    input  wire [1:0]                   in_select [N-1:0], 
    output wire [3:0]                   out_vld,
    input  wire [3:0]                   out_rdy,
    output wire [PAYLOAD_WIDTH-1:0]     out_pld[3:0]
);
    wire [3:0]      req [7:0];  
    wire [3:0][7:0] grant;      
    wire [3:0]      grant_valid;

    genvar i, j;
    generate
        for (i = 0; i < 4; i = i + 1) begin : OUTPUT_LOOP
            for (j = 0; j < N; j = j + 1) begin : INPUT_LOOP
                assign req[j][i] = in_vld[j] && (in_select[j] == i);
            end
        end
    endgenerate
    
    // 低位优先级
    generate
        for (i = 0; i < 4; i = i + 1) begin : ARBITER_LOOP
            priority_arbiter #(
                .NUM_REQUESTS(N)
            ) arbiter_inst (
                .req        (req[i]         ),
                .grant      (grant[i]       ),
                .grant_valid(grant_valid[i]));
        end
    endgenerate
    assign out_vld = grant_valid;
    generate
        for (i = 0; i < 4; i = i + 1) begin : OUTPUT_DATA_LOOP
            assign out_pld[i] = (grant_valid[i]) ? in_pld[grant[i]] : {PAYLOAD_WIDTH{1'b0}};

            for (j = 0; j < N; j = j + 1) begin : INPUT_READY_LOOP
                assign in_rdy[j] = (in_select[j] == i) ? (out_rdy[i] && grant[i][j]) : 1'b0;
            end
        end
    endgenerate
endmodule    

module priority_arbiter #(
    parameter NUM_REQUESTS = 8
)(
    input  wire [NUM_REQUESTS-1:0]  req         ,
    output reg  [NUM_REQUESTS-1:0]  grant       ,
    output wire                     grant_valid
);
    always_comb begin
        grant = {NUM_REQUESTS{1'b0}};
        if (|req) begin
            integer i;
            for (i = 0; i < NUM_REQUESTS; i = i + 1) begin
                if (req[i]) begin
                    grant[i] = 1'b1;
                    i = NUM_REQUESTS;
                end
            end
        end
    end 
    assign grant_valid = |grant;
endmodule 