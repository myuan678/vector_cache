module xy_switch 
import vector_cache_pkg::*;
(
    input  logic                clk                          ,
    input  logic                rst_n                        ,

    //input  logic [7         :0] op_vld                       ,
    //input  logic [4         :0] op_code              [7  :0] ,  //[4]:read; [3]:write; [2:1]:sel byte or 32bit; [0]: mode of read/write
    //input  logic [1         :0] src_id               [7  :0] ,  //0:left; 1:right; 2:up; 3:down
    //input  logic [1         :0] group_id_col         [7  :0] , ////txnid的低2bit表示方向：00：west；01：east；10：south；11：north

    input  logic [7         :0] read_cmd_vld                 ,
    input  arb_out_req_t        read_cmd_pld         [7 :0]  ,
    input  logic [7         :0] write_cmd_vld                ,
    input  arb_out_req_t        write_cmd_pld        [7 :0]  ,

    input  logic [7         :0] sw_data_in_vld_l             ,
    input  logic [31        :0] sw_data_in_l         [7  :0] ,
    output logic [7         :0] sw_data_out_vld_l            ,
    output logic [31        :0] sw_data_out_l        [7  :0] ,

    input  logic [7         :0] sw_data_in_vld_r             ,
    input  logic [31        :0] sw_data_in_r         [7  :0] ,
    output logic [7         :0] sw_data_out_vld_r            ,
    output logic [31        :0] sw_data_out_r        [7  :0] ,

    input  logic [7         :0] sw_data_in_vld_up            ,
    input  logic [31        :0] sw_data_in_up        [7  :0] ,
    output logic [7         :0] sw_data_out_vld_up           ,
    output logic [31        :0] sw_data_out_up       [7  :0] ,

    input  logic [7         :0] sw_data_in_vld_down          ,
    input  logic [31        :0] sw_data_in_down      [7  :0] ,
    output logic [7         :0] sw_data_out_vld_down         ,
    output logic [31        :0] sw_data_out_down     [7  :0]  
);


//read
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                if(read_cmd_vld[i] && group_id_row[i]==group_id_col[i])begin//read 对角线的block
                    if(read_cmd_pld[i].txnid.direction_id==2'd3)begin//north
                        data_out_r[i]    = data_in_l[i];
                        data_out_l[i]    = 'b0;
                        data_out_up[i]   = data_in_r[i];
                        data_out_down[i] = 'b0;
                    end
                    else if(read_cmd_pld[i].txnid.direction_id==2'd2)begin//south 
                        data_out_r[i]    = data_in_l[i];
                        data_out_l[i]    = 'b0;
                        data_out_up[i]   = 'b0;
                        data_out_down[i] = data_in_r[i];
                    end
                    else begin
                        data_out_r[i]    = data_in_l[i];
                        data_out_l[i]    = data_in_r[i];
                        data_out_up[i]   = 'b0;
                        data_out_down[i] = 'b0;    
                    end
                end
            end
        end
    endgenerate

    //write
    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_comb begin
                if(write_cmd_vld && group_id_row[i]==group_id_col[i])begin//write 对角线的block
                    if(write_cmd_pld[i].txnid.direction_id==2'd3)begin//north
                        data_out_r[i]    = data_in_up[i];
                        data_out_l[i]    = data_in_r[i];
                        data_out_up[i]   = 'b0;
                        data_out_down[i] = 'b0;
                    end
                    else if(write_cmd_pld[i].txnid.direction_id==2'd2)begin//south
                        data_out_r[i]    = data_in_down[i];
                        data_out_l[i]    = data_in_r[i];
                        data_out_up[i]   = 'b0;
                        data_out_down[i] = 'b0;
                    end
                    else begin
                        data_out_r[i]    = data_in_l[i];
                        data_out_l[i]    = data_in_r[i];
                        data_out_up[i]   = 'b0;
                        data_out_down[i] = 'b0;
                    end
                end
            end
        end
    endgenerate

    //generate
    //    for(genvar i=0;i<8;i=i+1)begin
    //        always_comb begin
    //            if(op_vld && group_id_col[i] == 0)begin
    //                if(src_id[i]==2'd2)begin
    //                    if(op_code[i][4])begin//read
    //                        data_out_r[i]    = data_in_l[i];
    //                        data_out_l[i]    = 'b0;
    //                        data_out_up[i]   = data_in_r[i];
    //                        data_out_down[i] = 'b0;
    //                    end
    //                    else if(op_code[i][3])begin//write
    //                        data_out_r[i]    = data_in_up[i];
    //                        data_out_l[i]    = data_in_r[i];
    //                        data_out_up[i]   = 'b0;
    //                        data_out_down[i] = 'b0;
    //                    end
    //                end
    //                else if(src_id[i]==2'd3)begin
    //                    if(op_code[i][4])begin
    //                        data_out_r[i]    = data_in_l[i];
    //                        data_out_l[i]    = 'b0;
    //                        data_out_up[i]   = 'b0;
    //                        data_out_down[i] = data_in_r[i];
    //                    end
    //                    else if(op_code[i][3])begin
    //                        data_out_r[i]    = data_in_down[i];
    //                        data_out_l[i]    = data_in_r[i];
    //                        data_out_up[i]   = 'b0;
    //                        data_out_down[i] = 'b0;
    //                    end
    //                end
    //                else begin
    //                    data_out_r[i]    = data_in_l[i];
    //                    data_out_l[i]    = data_in_r[i];
    //                    data_out_up[i]   = 'b0;
    //                    data_out_down[i] = 'b0;
    //                end
    //            end
    //            else begin
    //                data_out_r[i]    = data_in_l[i];
    //                data_out_l[i]    = data_in_r[i];
    //                data_out_up[i]   = 'b0;
    //                data_out_down[i] = 'b0;
    //            end
    //        end
    //    end
    //endgenerate



    generate    
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk)begin
                if(sw_data_out_vld_up && sw_data_out_vld_down)begin
                    $error("READ ERROR: up_vld && down_vld confilct");
                end
            end
        end
    endgenerate

    generate    
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk)begin
                if(sw_data_in_vld_up && sw_data_in_vld_down)begin
                    $error("WRITE ERROR: up_vld && down_vld confilct");
                end
            end
        end
    endgenerate

    generate
        for(genvar i=0;i<8;i=i+1)begin
            always_ff@(posedge clk)begin
                if(group_id_col[i] !== 2'b0)begin
                    if(sw_data_out_vld_up || sw_data_out_vld_down || sw_data_in_vld_up || sw_data_in_vld_down)begin
                        $error("SWITCH ERROR: not switch,no vld");
                    end
                end
            end
        end
    endgenerate
            

endmodule

