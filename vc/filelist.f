
$VEC_CACHE_PATH/rtl/vector_cache_pkg.sv
$VEC_CACHE_PATH/rtl/vector_cache_top.sv
$VEC_CACHE_PATH/rtl/vec_cache_ctrl.sv

//tag_ctrl
$VEC_CACHE_PATH/rtl/tag_ctrl/vec_cache_tag_ctrl.sv
$VEC_CACHE_PATH/rtl/tag_ctrl/vec_cache_8to2_req_arbiter.sv
$VEC_CACHE_PATH/rtl/tag_ctrl/vec_cache_tag_dirty_array.sv
$VEC_CACHE_PATH/rtl/tag_ctrl/vec_cache_wr_tag_buf.sv

//mshr
$VEC_CACHE_PATH/rtl/mshr/vec_cache_mshr.sv
$VEC_CACHE_PATH/rtl/mshr/vec_cache_mshr_entry.sv
$VEC_CACHE_PATH/rtl/mshr/vec_cache_stage2_arbiter.sv
$VEC_CACHE_PATH/rtl/mshr/vec_cache_channel_shift_reg.sv
$VEC_CACHE_PATH/rtl/mshr/vec_cache_ram_shift_reg.sv
$VEC_CACHE_PATH/rtl/mshr/vec_cache_vr_2grant_arb.sv
$VEC_CACHE_PATH/rtl/mshr/pre_alloc_two.sv
$VEC_CACHE_PATH/fcip/cmn/rtl/others/cmn_ip_mimo_queue.sv

//req_xbar
$VEC_CACHE_PATH/rtl/req_xbar/vec_cache_read_req_xbar.sv
$VEC_CACHE_PATH/rtl/req_xbar/vec_cache_write_req_xbar.sv
$VEC_CACHE_PATH/rtl/req_xbar/vec_cache_nto4_xbar.sv

//channel map
//$VEC_CACHE_PATH/rtl/channel_map/read_cmd_sel.sv
$VEC_CACHE_PATH/rtl/channel_map/vec_cache_write_cmd_sel.sv
$VEC_CACHE_PATH/rtl/channel_map/vec_cache_rdb_data_sel.sv

//DB
$VEC_CACHE_PATH/rtl/data_buffer/vec_cache_evdb_agent.sv
$VEC_CACHE_PATH/rtl/data_buffer/vec_cache_lfdb_agent.sv
$VEC_CACHE_PATH/rtl/data_buffer/vec_cache_rdb_agent.sv
$VEC_CACHE_PATH/rtl/data_buffer/vec_cache_wdb_agent.sv
$VEC_CACHE_PATH/rtl/data_buffer/vec_cache_pre_alloc_one.sv

//resp
$VEC_CACHE_PATH/rtl/resp/vec_cache_v_1toN_decode.sv
$VEC_CACHE_PATH/rtl/resp/vec_cache_wr_resp_direction_decode.sv
$VEC_CACHE_PATH/rtl/resp/vec_cache_wr_resp_master_decode.sv
$VEC_CACHE_PATH/rtl/resp/vec_cache_rd_data_master_decode.sv

//cmn
$VEC_CACHE_PATH/rtl/cmn/n_to_2_arb.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_lead_one.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_bin2onehot.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_lead_two.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_onehot2bin.sv
$VEC_CACHE_PATH/rtl/cmn/cmn_real_mux_onehot.sv
$VEC_CACHE_PATH/rtl/cmn/m_to_n_xbar.sv
$VEC_CACHE_PATH/rtl/cmn/v_en_decode.sv
$VEC_CACHE_PATH/rtl/cmn/vrp_arb.sv
$VEC_CACHE_PATH/rtl/cmn/vrp_arb_grant.sv
$VEC_CACHE_PATH/rtl/cmn/fifo.sv
$VEC_CACHE_PATH/rtl/cmn/fifo_2in_2out.sv
$VEC_CACHE_PATH/rtl/cmn/toy_mem_model_bit.sv

//sram
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_loop_back.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_mem_block.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_xy_switch.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_sram_2inst.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_sram_inst.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_sram_bank.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_sram_bank_group.sv
$VEC_CACHE_PATH/rtl/sram_group/vec_cache_sram_group.sv
$VEC_CACHE_PATH/rtl/sram_group/mem_model.sv







