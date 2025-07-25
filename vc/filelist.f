
$VEC_CACHE_PATH/rtl/vector_cache_pkg.sv
//$VEC_CACHE_PATH/rtl/vector_cache_top.sv
$VEC_CACHE_PATH/rtl/vec_cache_ctrl.sv

//tag_ctrl
$VEC_CACHE_PATH/rtl/tag_ctrl/vec_cache_tag_ctrl.sv
$VEC_CACHE_PATH/rtl/tag_ctrl/eigntto2_req_arbiter.sv

//mshr
$VEC_CACHE_PATH/rtl/mshr/vec_cache_mshr.sv
$VEC_CACHE_PATH/rtl/mshr/vec_cache_mshr_entry.sv
$VEC_CACHE_PATH/rtl/mshr/ten_to_two_arb.sv
$VEC_CACHE_PATH/rtl/mshr/onehot2bin2.sv
$VEC_CACHE_PATH/rtl/mshr/n_to_2_arb.sv
$VEC_CACHE_PATH/rtl/mshr/pre_alloc_two.sv


//req_xbar
$VEC_CACHE_PATH/rtl/req_xbar/read_req_xbar.sv
$VEC_CACHE_PATH/rtl/req_xbar/write_req_xbar.sv
$VEC_CACHE_PATH/rtl/req_xbar/nto4_xbar.sv

//channel map
$VEC_CACHE_PATH/rtl/channel_map/read_cmd_sel.sv
$VEC_CACHE_PATH/rtl/channel_map/write_cmd_sel.sv
$VEC_CACHE_PATH/rtl/channel_map/rdb_data_sel.sv

//DB
$VEC_CACHE_PATH/rtl/data_buffer/evictDB.sv
$VEC_CACHE_PATH/rtl/data_buffer/linefillDB.sv
$VEC_CACHE_PATH/rtl/data_buffer/rdb_agent.sv
$VEC_CACHE_PATH/rtl/data_buffer/readDB.sv
$VEC_CACHE_PATH/rtl/data_buffer/write_DB_agent.sv
$VEC_CACHE_PATH/rtl/data_buffer/pre_alloc_one.sv

//resp
$VEC_CACHE_PATH/rtl/resp/v_1toN_decode.sv
$VEC_CACHE_PATH/rtl/resp/wr_resp_direction_decode.sv
$VEC_CACHE_PATH/rtl/resp/wr_resp_master_decode.sv
$VEC_CACHE_PATH/rtl/resp/rd_data_master_decode.sv

//cmn
$VEC_CACHE_PATH/rtl/cmn/cmn_lead_one.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_bin2onehot.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_lead_two.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_onehot2bin.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_real_mux_onehot.sv
$VEC_CACHE_PATH/rtl/cmn/m_to_n_xbar.sv
$VEC_CACHE_PATH/rtl/cmn/v_en_decode.sv
$VEC_CACHE_PATH/rtl/cmn/vrp_arb.sv
$VEC_CACHE_PATH/rtl/cmn/fifo.sv
$VEC_CACHE_PATH/rtl/cmn/toy_mem_model_bit.sv

//sram
$VEC_CACHE_PATH/rtl/sram_group/loop_back.sv
$VEC_CACHE_PATH/rtl/sram_group/mem_block.sv
$VEC_CACHE_PATH/rtl/sram_group/xy_switch.sv
$VEC_CACHE_PATH/rtl/sram_group/sram_2inst.sv
$VEC_CACHE_PATH/rtl/sram_group/sram_inst.sv
$VEC_CACHE_PATH/rtl/sram_group/sram_bank.sv
$VEC_CACHE_PATH/rtl/sram_group/sram_bank_group.sv
$VEC_CACHE_PATH/rtl/sram_group/sram_group.sv
$VEC_CACHE_PATH/rtl/sram_group/mem_model.sv




