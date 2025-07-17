module cmn_lead_two #(
    parameter integer unsigned ENTRY_NUM = 8
) (
    input  logic [ENTRY_NUM-1           :0] v_entry_vld,
    output logic [ENTRY_NUM-1           :0] v_free_idx_oh_1,
    output logic [$clog2(ENTRY_NUM)-1   :0] v_free_idx_bin_1,
    output logic                            v_free_vld_1,
    output logic [ENTRY_NUM-1           :0] v_free_idx_oh_2,
    output logic [$clog2(ENTRY_NUM)-1   :0] v_free_idx_bin_2,
    output logic                            v_free_vld_2
);

    integer i;
    logic found_first;

    always_comb begin
        // 初始化输出信号
        v_free_idx_oh_1 = {ENTRY_NUM{1'b0}};
        v_free_idx_bin_1 = {$clog2(ENTRY_NUM){1'b0}};
        v_free_vld_1 = 1'b0;
        v_free_idx_oh_2 = {ENTRY_NUM{1'b0}};
        v_free_idx_bin_2 = {$clog2(ENTRY_NUM){1'b0}};
        v_free_vld_2 = 1'b0;
        found_first = 1'b0;

        for (i = 0; i < ENTRY_NUM; i = i + 1) begin
            if (v_entry_vld[i]) begin
                if (!found_first) begin
                    // 找到第一个有效位
                    v_free_idx_oh_1[i] = 1'b1;
                    v_free_idx_bin_1 = i[$clog2(ENTRY_NUM)-1:0];
                    v_free_vld_1 = 1'b1;
                    found_first = 1'b1;
                end 
                else begin
                    // 找到第二个有效位
                    v_free_idx_oh_2[i] = 1'b1;
                    v_free_idx_bin_2 = i[$clog2(ENTRY_NUM)-1:0];
                    v_free_vld_2 = 1'b1;
                    break;
                end
            end
        end
    end

endmodule