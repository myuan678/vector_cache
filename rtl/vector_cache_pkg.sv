package vector_cache_pkg;


    `define WEST   2'b00
    `define EAST   2'b01
    `define SOUTH  2'b10
    `define NORTH  2'b11

//opcode 0write;1read;2evict;3linefill
    `define WRITE     2'b00
    `define READ      2'b01
    `define EVICT     2'b10
    `define LINEFILL  2'b11



    localparam integer unsigned RAM_WIDTH  = 128;
    localparam integer unsigned RAM_DEPTH  = 512;
    localparam integer unsigned RAM_NUM    = 4;
    localparam integer unsigned ADDR_WIDTH = $clog2(RAM_DEPTH);
    localparam integer unsigned SEL= $clog2(RAM_WIDTH/8);

    parameter integer unsigned CHANNEL   = 8    ;



    //ctrl part
    parameter integer unsigned REQ_ADDR_WIDTH  = 64;
    parameter integer unsigned CACHE_SIZE      = 8192*1024; //8MBytes
    parameter integer unsigned CACHE_LINE_SIZE = 512;       //512 Bytes
    parameter integer unsigned WAY_NUM         = 4  ;
    parameter integer unsigned SET_NUM         = CACHE_SIZE/(CACHE_LINE_SIZE*WAY_NUM); //每个set的大小为512Byte，4way 

    parameter integer unsigned INDEX_WIDTH     = $clog2(SET_NUM) ;//12bit
    parameter integer unsigned OFFSET_WIDTH    = $clog2(CACHE_LINE_SIZE)  ;//9bit
    parameter integer unsigned TAG_WIDTH       =  REQ_ADDR_WIDTH-INDEX_WIDTH-OFFSET_WIDTH;//43bit
    parameter integer unsigned BUS_WIDTH       = 128;
    parameter integer unsigned DS_N            = CACHE_LINE_SIZE / BUS_WIDTH;  
    parameter integer unsigned TAG_RAM_WIDTH   = WAY_NUM*(TAG_WIDTH+2);
    

    parameter integer unsigned MSHR_ENTRY_NUM  = 64 ;
    parameter integer unsigned MSHR_ENTRY_IDX_WIDTH = $clog2(MSHR_ENTRY_NUM);
    parameter integer unsigned TXNID_WIDTH     = 5;
    parameter integer unsigned SIDEBAND_WIDTH  = 10;
    parameter integer unsigned OP_WIDTH        = 5;
    //parameter integer unsigned ICACHE_TAG_RAM_WIDTH = WAY_NUM*(TAG_WIDTH+2);

    parameter integer unsigned LFDB_ENTRY_NUM  = 32;
    parameter integer unsigned EVDB_ENTRY_NUM  = 32;
    parameter integer unsigned RW_DB_ENTRY_NUM = 32;
    //parameter integer unsigned RW_DB_ENTRY_IDX_WIDTH = $clog2()
    parameter integer unsigned DB_ENTRY_IDX_WIDTH = $clog2(RW_DB_ENTRY_NUM);

    
    //request direction && master
    parameter integer unsigned MASTER_NUM  = 8; //每个方向上的master的数量，其实个REQ_NUM应该对应
    parameter integer unsigned WR_REQ_NUM  = 8; // west read req_num
    parameter integer unsigned WW_REQ_NUM  = 8; // west write req_num
    parameter integer unsigned WB_REQ_NUM  = 8; // west bresp num
    parameter integer unsigned WRD_REQ_NUM = 8; // west rdata num

    parameter integer unsigned ER_REQ_NUM  = 8; // east read req_num
    parameter integer unsigned EW_REQ_NUM  = 8; // east write req_num
    parameter integer unsigned EB_REQ_NUM  = 8; // east bresp num
    parameter integer unsigned ERD_REQ_NUM = 8; // east rdata num

    parameter integer unsigned NR_REQ_NUM  = 8; //north read req_num
    parameter integer unsigned NW_REQ_NUM  = 8; //north write req_num
    parameter integer unsigned NB_REQ_NUM  = 8; //north bresp num
    parameter integer unsigned NRD_REQ_NUM = 8; //north rdata num
    

    parameter integer unsigned SR_REQ_NUM  = 8; //south read req_num
    parameter integer unsigned SW_REQ_NUM  = 8; //south write req_num
    parameter integer unsigned SB_REQ_NUM  = 8; //south bresp num
    parameter integer unsigned SRD_REQ_NUM = 8; //south rdata num

    parameter integer unsigned DATA_WIDTH           = 1024  ;
    parameter integer unsigned READ_SRAM_DELAY      = 10    ; 
    parameter integer unsigned EVICT_CLEAN_DELAY    = 15    ; 
    parameter integer unsigned EVICT_DOWN_DELAY     = 20    ;
    //parameter integer unsigned ARB_TO_LFDB_DELAY    = 5     ;
    parameter integer unsigned LF_DONE_DELAY        = 10    ;
    parameter integer unsigned RDB_DATA_RDY_DELAY   = 15    ; //是指sram中的数据已经被读到了RDB中，现在可以发起对RDB的读请求，将数据给US
    parameter integer unsigned TO_US_DONE_DELAY     =20     ;

    //parameter integer unsigned WRITE_DONE_DELAY     = 20    ; 
    //parameter integer unsigned ARB_TO_WDB_DELAY     = 5     ;
    parameter integer unsigned WR_CMD_DELAY_WEST    = 2     ;//arb出到开始占用channel的延迟
    parameter integer unsigned WR_CMD_DELAY_EAST    = 3     ;//arb出到开始占用channel的延迟
    parameter integer unsigned WR_CMD_DELAY_SOUTH   = 6     ;//arb出到开始占用channel的延迟
    parameter integer unsigned WR_CMD_DELAY_NORTH   = 4     ;//arb出到开始占用channel的延迟
    parameter integer unsigned WR_CMD_DELAY_LF      = 8     ;//arb出到开始占用channel的延迟

    //地址高2bit作为hash id
    typedef struct packed{
        logic [TAG_WIDTH-1      :0] tag     ;
        logic [INDEX_WIDTH-1    :0] index   ;
        logic [OFFSET_WIDTH-1   :0] offset  ;
    } addr_t;

    typedef struct packed {
        logic [1                   :0] direction_id ;//txnid的低2bit表示方向：00：west；01：east；10：south；11：north
        logic [$clog2(MASTER_NUM)-1:0] master_id    ;
        logic [3:0]                    req_id       ;//每个master可以发N个，假设16个
        logic                          mode         ;//读写时时操作连续的32bit，还是每个32bit中选一个byte，组成32bit。mode=0表示连续，mode=1表示4个byte
        logic [1                   :0] byte_sel     ;//表示读32bit中的哪一个byte
    } txnid_t;

    typedef struct packed {
        logic [63:0]                     cmd_addr    ;
        txnid_t                          cmd_txnid   ;
        logic [SIDEBAND_WIDTH-1      :0] cmd_sideband;
    } input_read_cmd_pld_t;

    typedef struct packed {
        addr_t                           cmd_addr    ;
        txnid_t                          cmd_txnid   ;
        logic [SIDEBAND_WIDTH-1      :0] cmd_sideband;
        logic [127                   :0] strb        ;
        logic [1023                  :0] data        ;
    } input_write_cmd_pld_t;


    typedef struct packed {
        addr_t                           cmd_addr    ;
        txnid_t                          cmd_txnid   ;
        logic [SIDEBAND_WIDTH-1      :0] cmd_sideband;
        logic [127                   :0] strb        ;
        logic [OP_WIDTH-1            :0] cmd_opcode  ;  //0write; 1read//0write; 1read; 2linefill; 3evict
        logic [DB_ENTRY_IDX_WIDTH-1  :0] db_entry_id ;
        logic [MSHR_ENTRY_IDX_WIDTH-1:0] rob_entry_id; 
    } input_req_pld_t;

    typedef struct packed {
        logic [INDEX_WIDTH-1       :0] index       ;
        logic [OFFSET_WIDTH-1      :0] offset      ;
        logic [TAG_WIDTH-1         :0] tag         ;
        logic [$clog2(WAY_NUM)-1   :0] way         ; //way id 
    } wr_buf_pld_t;

    typedef struct packed {
        input_req_pld_t                cmd_pld     ;      
        logic [1023 :0]                data        ;
    } input_wrreq_pld_t;

    typedef struct packed {
        logic [DB_ENTRY_IDX_WIDTH-1:0] db_entry_id ;      
        logic [1023 :0]                data        ;
        logic                          cmd         ;
    }  wdb_pld_t;
    

    typedef struct packed {
        txnid_t                             txnid           ;//txnid的低两位作为方向id,高位作为master id
        logic [OP_WIDTH-1               :0] opcode          ;//write(0) or read(1) or evict(2) or linefill(3) 
        logic [TAG_WIDTH-1              :0] tag             ;
        logic [INDEX_WIDTH-1            :0] index           ;
        logic [OFFSET_WIDTH-1           :0] offset          ;
        logic [$clog2(WAY_NUM)-1        :0] way             ;
        logic [4                        :0] dest_ram_id     ; //最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
        logic [$clog2(MSHR_ENTRY_NUM)-1 :0] rob_entry_id    ;
        logic [$clog2(RW_DB_ENTRY_NUM)-1:0] db_entry_id     ;
        logic [SIDEBAND_WIDTH-1         :0] sideband        ; 
        logic                               last            ;
        //logic [$clog2(DS_N)-1           :0] req_num         ; 
    } arb_out_req_t;

    typedef struct packed {
        arb_out_req_t           req_cmd_pld ;
        logic                   last        ;
        logic [$clog2(DS_N)-1:0]req_num     ; //evict时需要分几次传输数据，第几次，req_num=3时last为1
    } read_ram_cmd_t;

    typedef struct packed {
        arb_out_req_t           req_cmd_pld ;
        logic                   last        ;
        logic [$clog2(DS_N)-1:0]req_num     ; //linefill和evict时需要分几次传输数据，第几次，req_num=3时last为1
    } read_lfdb_pld_t;


    typedef struct packed{
        logic                               valid         ;
        txnid_t                             txnid         ;
        logic [OP_WIDTH-1       :0]         opcode        ;
        logic [INDEX_WIDTH-1    :0]         index         ;
        logic [OFFSET_WIDTH-1   :0]         offset        ;
        logic [TAG_WIDTH-1      :0]         req_tag       ;
        logic [$clog2(WAY_NUM)-1:0]         way           ;
        logic                               is_read       ;
        logic                               is_write      ;
        logic                               hit           ;
        logic                               need_linefill ;
        logic                               need_evict    ;
        logic [TAG_WIDTH-1:0]               evict_tag     ;
        logic [MSHR_ENTRY_NUM-1:0]          hzd_bitmap    ;
        logic                               hzd_pass      ; 
        logic [MSHR_ENTRY_IDX_WIDTH-1:0]    alloc_idx     ;
        logic [SIDEBAND_WIDTH-1 :0]         sideband      ; 
        logic [DB_ENTRY_IDX_WIDTH-1:0]      wdb_entry_id  ;
    } mshr_entry_t;

    

    typedef struct packed {
        txnid_t                     txnid;
        logic [SIDEBAND_WIDTH-1 :0] sideband;
    }wr_resp_pld_t;


    typedef struct packed{
        logic [MSHR_ENTRY_IDX_WIDTH-1:0] rob_entry_id;
        logic [DB_ENTRY_IDX_WIDTH-1  :0] db_entry_id ;
        txnid_t                          txnid       ;
        logic [SIDEBAND_WIDTH-1      :0] sideband    ;
        logic [1                     :0] hash_id     ;
    } bresp_pld_t;

    typedef struct packed{
        txnid_t                          txnid       ;
        logic [OP_WIDTH-1       :0]      opcode      ;
        addr_t                           addr        ;
        logic [WAY_NUM-1        :0]      way         ;
        logic [4:0]                      dest_ram_id ;
        logic [MSHR_ENTRY_IDX_WIDTH-1:0] rob_entry_id;
        logic [LFDB_ENTRY_NUM-1 :0]      db_entry_id ;//linefill db 
        logic [SIDEBAND_WIDTH-1 :0]      sideband    ; 
        
    } downstream_txreq_pld_t;

    typedef struct packed{
        logic  [BUS_WIDTH-1:0]           data        ;
        downstream_txreq_pld_t           linefill_cmd;
        logic                            last;
    }ds_to_lfdb_pld_t;

    typedef struct packed{
        logic  [1023       :0]           data         ;
        arb_out_req_t                    evict_req_pld;
    } ram_to_evdb_pld_t;


    typedef struct packed{
        logic  [1023                    :0] data        ;
        logic  [MSHR_ENTRY_IDX_WIDTH-1  :0] rob_entry_id;
        txnid_t                             txnid       ;
        logic  [SIDEBAND_WIDTH-1        :0] sideband    ;
    }us_data_pld_t;

    typedef struct packed{
        logic  [MSHR_ENTRY_IDX_WIDTH-1  :0] rob_entry_id;
        logic  [DB_ENTRY_IDX_WIDTH-1    :0] db_entry_id ;
        txnid_t                             txnid       ;
        logic  [SIDEBAND_WIDTH-1        :0] sideband    ;
    }read_rdb_addr_t;


    typedef struct packed {
        logic  [BUS_WIDTH-1             :0] data        ;
        addr_t                              addr        ;
        logic                               last        ;
        logic  [MSHR_ENTRY_IDX_WIDTH-1  :0] rob_entry_id;
        logic  [DB_ENTRY_IDX_WIDTH-1    :0] db_entry_id ;
        txnid_t                             txnid       ;
        logic  [SIDEBAND_WIDTH-1        :0] sideband    ;
    }evict_to_ds_pld_t;
    


//sram_2inst opcode def
    typedef struct packed{
        logic [8:0] addr       ;
        txnid_t     txnid      ;
        logic [4:0] dest_ram_id; //最高2bit为hash id，接下来的3bit为dest ram id，5bit确定是哪一个block的哪一个hash的哪一个ram
        logic       mode       ;
        logic [1:0] byte_sel   ;
        //logic [1:0] req_num    ; //linefill/evict时的传输次数编号
        logic       opcode     ; //read: 0read; 1 evict read
    } sram_inst_cmd_t;          // write: 0 write; 1linefill

    
    typedef struct packed {
        logic [31:0]    data   ;
        sram_inst_cmd_t cmd_pld;
    } data_pld_t;

    typedef struct packed {
        logic [255:0]    data   ;
        sram_inst_cmd_t  cmd_pld;
    } bankgroup_data_pld_t;

    typedef struct packed {
        logic [1023:0]   data  ;
        sram_inst_cmd_t  cmd_pld;
    } group_data_pld_t;


    typedef struct packed {
        arb_out_req_t           req_cmd_pld ;
        logic                   last        ;
        logic [$clog2(DS_N)-1:0]req_num     ; //linefill时需要分几次传输数据，第几次，req_num=3时last为1
    } write_ram_cmd_t;

    typedef struct packed {
        group_data_pld_t        data        ;
        write_ram_cmd_t         write_cmd   ;
    } write_ram_pld_t;

endpackage