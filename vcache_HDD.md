




整个Vector Cache的交换总体分为两层：

1. 第一层是      Master to Hash Slave
2. 第二层是4 Directions to 1 dimension

第一层在4个方向上先进行哈希，哈希出4组。
第二层在每个哈希维度内，把4个方向上的请求进行仲裁。


## Request Hash Xbar & Response Hash Xbar

对于Vector Cache而言，上游的多个Master在物理位置上分为4组摆放（WNSE），因此多个Master发出的大量命令首先是分为4组各自进行仲裁的。

### Read Request Hash Xbar

针对4个方向，存在4个Read Request Hash Xbar，每个Read Req Hash Xbar的输入为N（Master数量），输出为4（4组哈希）。这个Xbar可以被下游反压。

### Write Request Hash Xbar

类似地，对于写操作而言，也存在4个Write Request Hash Xbar，每个Xbar的输入为N(Master数量)，输出为4（4组哈希）。这个xbar会把数据送往Write Data Buffer，把命令送往Tag Pipeline。因此它可能受到下游两个方向的反压。

### Read Response Hash Xbar

对于读响应（即读数据） ，与写请求相反，每个xbar的输入为4，输出为N。可能受到上游的反压。

### Write Response Hash Xbar

对于写响应，与写请求相反，每个Xbar的输入为4，输出为N。可能受到上游反压。


## Tag Pipeline Req Xbar & Tag Pipeline Rsp Xbar

经过第一层Requset Xbar之后，对于每个Hash后的Tag pipeline而言，会从4个方向上分别收到1个read request,一个write requset，共计8个请求。

Tag pipeline本身为双发射，因此在Tag pipeline输入端，需要一个8x2 xbar。这个xbar可以反压。

对应地，Tag pipeline给各个Master的写响应信号，也有对应的2 to 4 xbar。这个xbar可以反压。 

## Tag Pipeline arbiter & Tag RAM

Tag pipeline本身为双发射,设计中有两份tag ram以供双发射请求同时查询，均为单口，由于在发生miss时采用超前更新策略更新tag ram，write tag buffer用于缓存需要写入tag ram的请求信息，需要一个arbiter决定tag ram的双发射读/单写，优先写更新tag ram，可以反压上游8x2 xbar。
对于读tag ram，需pre allocate ROB entry，对应于双发射，pre allocate两个ROB entry ID，不满足则反压上游。
请求需要检查与ROB中已存请求的hazard，采用index-way hazard check
替换算法采用SRRIP

## Tag Pipeline ROB

ROB用于记录需要访问data sram的请求，深度为64。
对于读请求，需要记录请求信息，hazard bitmap，替换算法结果以及behavior信息，对于写请求还需记录请求对应的Write data buffer的entry ID。
对于访问下游的downstream_txreq请求，需要一个M to 1的仲裁器，可以被下游反压，支持outstanding。
对于访问可以data sram的请求，需要一个Issue arbiter来决定可执行的读写请求。
ROB会接收读写完成信号，用于更新ROB entry状态&&释放ROB entry。


## Tag Pipeline Issue Arbiter

这个仲裁器是ROB中最核心的仲裁逻辑，它的目的是从ROB的所有entry中仲裁出当前能够执行的对SRAM的读/写。

这个仲裁器要解决的核心问题是，对于不同方向的读和写，执行延迟都不同。即从这个命令从Tag Pipeline发出后，到实际作用在Sram之上，它的延迟是不同的。

为了解决这个问题，我们把仲裁器设置为2级。

Stage 1: 先从所有的ROB中分别选出候选的4个读+4个写（分别来自于4个方向）+1个evict+1个linefill，共10个，五读五写。
Stage 2: 根据延迟信息和channel占用信息，记录已发射请求在未来占用sram和channel的时刻，对每个channel有个历史请求占用shift reg；对于每个sram也有历史请求占用情况的shift reg；判断每个方向的读/写当前能不能够被发射，在所有能发射的候选者中选出2个发射。
    目前由于不同方向的写请求占用SRAM和Channel的延迟各不相同（可调整），同周期的写请求之间不会存在冲突，但五个读请求之间需要检查sram冲突
    目前由于写操作均在通道环路的返回区间执行，同周期发射的写请求总是晚于读请求占用channel和sram，因此历史记录表shift reg只需要更新记录写请求的占用

### Delay Recorder

每个指令发射后，都要经过一段时间才能抵达SRAM，并且不同的地址会对应不同的SRAM，不同方向上的指令会对应不同的延迟。

每个sram都需要记录未来某时会被读写，因此每个hash我们需要8个Delay Recorder来记录延迟信息。

由于在当前设计中，sram 阵列行的通道回路上读操作在上侧读取sram，写操作在下侧写入sram，因此可以确定来自同一方向的读和写，写请求到达sram的延迟大于读请求，不会存在先发射的读请求阻塞写请求的情况，因此读请求发射时不需要更新recoder。
每一个write请求（包括write和linefill）需要查验recoder来确认是否无冲突，发射后需要更新对应的recoder，记录自己到达sram所需的延迟，用于后续请求发射时查验
每一个read请求（包括read和evict）需要查验recoder，确认是否无冲突。

### Channel Recoder

对于data sram的访问，每个hash有2个读请求通道，2个写请求通道以及2个数据通道。

ROB选中的请求发射后，会出现数据通道占用的冲突，来自不同方向的写数据到达数据channel也会有不同延迟，对于仲裁选中的两个请求，需要Channel Recoder 分别记录请求发射后数据channel的占用情况

## Data Buffer

Vector Cache哈希为4个Group，针对每个Group，在每个方向（WSNE）上，都放置了Write Data Buffer(WDB)和Read Data Buffer(RDB)。在去往下游的一个方向上，还对应每个Group放置了Evict Data Buffer(EVDB)和Linefill Data Buffer(LFDB)。

如果一个系统里有M个Master，有N个哈希后的Slave(Sram Group)。那么从Master到Slave总存在一个MxN的cross bar，Master在随机访问多个Hash Slave的时候一定会出现冲突。为了缓解冲突，肯定需要放置Data Buffer，而放置Data Buffer的策略有两种，一种是在贴近Master侧放置M个DB，另一种是在贴近Slave侧放置N个DB。

在Vector Cache的设计中，我们选择了在Slave侧放置N个DB，这样做有几个原因：

1. 按照Slave侧配置更匹配实际带宽，不会出现浪费。有时候多个Master接入的总带宽是大于Slave能承受的带宽的，Master是在时分复用地使用带宽。按照每个Master配置Data Buffer是显著过剩的，并且随着Master接入数量的变动，Vector Cache的面积/Floorplan也要持续调整。而按照Slave配置则相对稳定并且保证不浪费面积的情况下获得满带宽。

2. 由于物理实现上的约束，Vector Cache能够接入的Master是环绕在四周的。如果每个Data Buffer当前是否能够和SRAM Group交换数据是不能保证的（即往SRAM读写数据的仲裁器是需要参考Data Buffer状态的），那么这个仲裁将会非常难实现，我们需要一个中心化的仲裁器能够实时观测到所有Data Buffer当前是否能够响应读写请求。为了避开这个问题，我们把Data Buffer设定为永远优先响应SRAM侧的请求，即WDB永远优先被读，RDB永远优先被写。SRAM分为4个Group，为了保证这点，每个Group在每个方向上都配置一个WDB和RDB。

### Write Data Buffer

在每个方向上，Write Data Buffer(WDB)跟随SRAM哈希分为4个Group。上游Master的写请求会经过一个N x 4 crossbar访问到Write Data Buffer。每个Group的WDB都由单口SRAM构成，因此每个周期只能响应一个读或一个写请求。WDB被设定为读优先，因此上游在写入时可能会产生反压。
Write Data buffer深度暂定为64，与ROB深度一致
对于上游而言，Vector Cache和上游的接口被定义为写命令和写数据同时传输，因此上游即可能被Write Data Buffer反压，也可能被Tag Pipeline反压。（命令直接发往Cache Pipeline）。

对于每个WDB，反压的原因有两个：

1. 当前这个cycle，从tag pipeline发来了读WDB的指令，SRAM被占用。
2. WDB已满。

WDB的空满计数使用一个counter完成，再pre-alloc一个位置之后+1,在收到tag pipeline发来的读WDB指令并执行后-1。




### Read Data Buffer

Read Data Buffer(RDB)和WDB类似，在每个方向上与每个Sram Group保持一一对应，采用单口Sram实现，与Sram Group的交互有最高优先级（即永远写优先）。
为避免SRAM写RDB高优先级的设定下会出现RDB不能及时读出返回上游，将RDB分为0/1两个部分，采用乒乓方式读写两块RDB，
目前每块RDB深度暂定为32，考虑SRAM面效比，可能调整为64。
对于Read Data Buffer来说，在收到数据写入时，也会同步收到一个指令。这个指令指明了如何将数据发往Master。在数据从SRAM写入RDB的下一拍读出返回上游。在发送完成后，向ROB发送完成信号，并release。

##RDB内部的实现其实是一个ROB，以及受ROB控制的单口SRAM。SRAM发来的命令除了会写入单口SRAM，也会写入ROB的一个entry中。随后该entry会举手请求从SRAM中读取数据并往Master侧发送。在发送完成后，向ROB发送完成信号，并release。


### Evict Data Buffer

Evict Data Buffer(EVDB)和也跟随SRAM哈希分为4个Group，不分方向，采用单口SRAM实现，设定为与SRAM侧的交互为高优先级，EVDB深度与ROB对应，因此不需要pre allocate。

EVDB内部存在一个延迟控制，在evict请求从仲裁器发射出去后，经过某一个确定的读SRAM的延迟后会将数据写入到EVDB，该延迟控制模块用于存储请求信息并发起对EVDB的读写，写入后会向ROB返回写入完成的信号。在读出数据写入下游后向ROB返回evict完成的信号。


### Linefill Data Buffer

Linefill Data Buffer(LFDB)也跟随SRAM哈希分为4个Group，不分方向，采用单口SRAM实现，同样设定为与SRAM侧的交互为高优先级，LFDB深度与ROB对应，因此不需要pre allocate。

LFDB内部也存在一个延迟控制，用于实现在linefill write SRAM请求从仲裁器发射出去后，经过确定延时，发起对LFDB的读请求，写入SRAM完成后向ROB返回完成信号。

LFDB与下游的接口位宽与cache line size不要求一致，因此LFDB中存在一个计数器，记录下游可能分多次返回的数据，收到完整的cache line后向ROB返回写入LFDB完成信号



## Subordinate arbiter & decoder

### downstream 4to1 arbiter
用于实现4hash向下游请求的仲裁

### evict 4to1 arbiter
用于实现4hash向下游evict的仲裁

### bresp 1to4 decoder
用于实现下游返回的evict完成的响应信号向hash分组的decode

### linefill 1to4 decoder
用于实现下游返回的linefill数据向hash分组的decode


# DATA SRAM ARRAY
Vector cache memory总容量为8M，数据位宽为128Byte，8个读请求通道，8个写请求通道以及8个数据通道。最大带宽8*128Byte*2GHz
每个hash有2个通道，为了提升访问性能每个sram_bank中包含了每个hash的2块sram，
为支持tensor数据layout的特殊需求，sram的位宽选择为128bit；结合sram面积情况，深度选择为512bit。共1024块sram

对于每一个hash，sram排列都是4*4个sram_bank_group，双通道。
每个sram_bank_group由8个sram_bank组成，每次访问会覆盖纵列的4个sram_bank_group，一共是32个sram_bank，一共是128Byte数据.
考虑sram访问的延迟，sram_bank有2块sram，2通道之间有corssbar。

由于cache control的仲裁器完成了可发射请求的选择，sram array的访问不会出现冲突，无反压。

## SRAM bank group（4×4阵列）

为了访问延迟的对称均衡，对于每一个Hash组，SRAM排列为**4行×4列**的bank_group阵列：

- **行（ROW）**：4行，编号0-3
- **列（COL）**：4列，编号0-3
- **总共16个bank_group**
每次访问覆盖纵列的4个sram_bank_group，每个bank_group包含**8个bank（SRAM Bank）**。
考虑物理实现时走线空间和距离，8M SRAM分为4组，对应crtl部分的4hash，分布在这16个bank group，也可以说是这16个bank group是有4层。
考虑到物理实现时cache control部分至于左侧，所有command从左侧输入sram array，对角线上的bank_group可以实现数据和command方向的转换。

## SRAM bank
因为sram的访问频率和control部分时钟频率差异，每个hash都在sram——bank中有2块对应的sram，2块sram之间有crossbar，用于提升数据读写效率。
4个hash都有2块相应的sram，因此每个sram_bank包含8块sram。
每次访问的128Byte数据是来自32个sram_bank，分别存储或读出32bit数据

### sram inst

sram为单口sram，位宽为128bit，深度为512bit
因为tensor数据layout有两种模式，且sram的位宽为128bit，每个请求会有两种可能的数据访问模式：
    模式一：128bit数据中选择第1/2/3/4个“32bit”,，作为该thread的数据
    模式二：128bit数据每个“32bit”中选择一个Byte，组成32bit数据，作为该thread的数据


### mem_block
对于每个hash的读请求：
    sram读出的数据和channel上传递的数据存在3to1的选择仲裁，用于确定哪个数据是有效输出的，一共有8个
对于每个hash的写请求：
    channel上传递的数据存在1to3的分发，用于决定数据写入哪一个sram或者传递至下一个block，一共有8个



### xy_switch
由于读command都自左侧输入，读数据输入到各个方向的RDB，在读取到数据后需要分发至不同方向，数据转向点设定为统一在对角线上的block实现，
写操作command先从2stage arbiter发射到各个方向的WDB，然后读取wdata一起进入sram阵列，写数据的转向也由对角线的block实现



