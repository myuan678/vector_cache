




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

对于读响应（即读数据），与写请求相反，每个xbar的输入为4，输出为N。可能受到上游的反压。

### Write Response Hash Xbar

对于写响应，与写请求相反，每个Xbar的输入为4，输出为N。可能受到上游反压。


## Tag Pipeline Req Xbar & Tag Pipeline Rsp Xbar

经过第一层Requset Xbar之后，对于每个Hash后的Tag pipeline而言，会从4个方向上分别收到1个read request,一个write requset，共计8个请求。

Tag pipeline本身为双发射，因此在Tag pipeline输入端，需要一个8x2 xbar。这个xbar可以反压。

对应地，Tag pipeline给各个Master的写响应信号，也有对应的2 to 4 xbar。这个xbar可以反压。 




## Tag Pipeline Issue Arbiter


这个仲裁器是ROB中最核心的仲裁逻辑，它的目的是从ROB的所有entry中仲裁出当前能够执行的对SRAM的读/写。

这个仲裁器要解决的核心问题是，对于不同方向的读和写，执行延迟都不同。即从这个命令从Tag Pipeline发出后，到实际作用在Sram之上，它的延迟是不同的。

为了解决这个问题，我们把仲裁器设置为2级。

Stage 1: 先从所有的ROB中分别选出候选的4个读+4个写（分别来自于4个方向）+1个evict+1个linefill。
Stage 2: 根据延迟信息，判断每个方向的读/写当前能不能够被发射，在所有能发射的候选者中选出2个发射。

### Delay Recorder

每个指令发射后，都要经过一段时间才能抵达SRAM，并且不同的地址会对应不同的SRAM，不同方向上的指令会对应不同的延迟。

因此我们需要......个Delay Recorder来记录延迟信息。



## Data Buffer


Vector Cache哈希为4个Group，针对每个Group，在每个方向（WSNE）上，都放置了Write Data Buffer(WDB)和Read Data Buffer(RDB)。在去往下游的一个方向上，还对应每个Group放置了Evict Data Buffer(EVDB)和Linefill Data Buffer(LFDB)。

如果一个系统里有M个Master，有N个哈希后的Slave(Sram Group)。那么从Master到Slave总存在一个MxN的cross bar，Master在随机访问多个Hash Slave的时候一定会出现冲突。为了缓解冲突，肯定需要放置Data Buffer，而放置Data Buffer的策略有两种，一种是在贴近Master侧放置M个DB，另一种是在贴近Slave侧放置N个DB。

在Vector Cache的设计中，我们选择了在Slave侧放置N个DB，这样做有几个原因：

1. 按照Slave侧配置更匹配实际带宽，不会出现浪费。有时候多个Master接入的总带宽是大于Slave能承受的带宽的，Master是在时分复用地使用带宽。按照每个Master配置Data Buffer是显著过剩的，并且随着Master接入数量的变动，Vector Cache的面积/Floorplan也要持续调整。而按照Slave配置则相对稳定并且保证不浪费面积的情况下获得满带宽。

2. 由于物理实现上的约束，Vector Cache能够接入的Master是环绕在四周的。如果每个Data Buffer当前是否能够和SRAM Group交换数据是不能保证的（即往SRAM读写数据的仲裁器是需要参考Data Buffer状态的），那么这个仲裁将会非常难实现，我们需要一个中心化的仲裁器能够实时观测到所有Data Buffer当前是否能够响应读写请求。为了避开这个问题，我们把Data Buffer设定为永远优先响应SRAM侧的请求，即WDB永远优先被读，RDB永远优先被写。SRAM分为4个Group，为了保证这点，每个Group在每个方向上都配置一个WDB和RDB。

### Write Data Buffer

在每个方向上，Wrrite Data Buffer(WDB)跟随SRAM哈希分为4个Group。上游Master的写请求会经过一个N x 4 crossbar访问到Write Data Buffer。每个Group的WDB都由单口SRAM构成，因此每个周期只能响应一个读或一个写请求。WDB被设定为读优先，因此上游在写入时可能会产生反压。

对于上游而言，Vector Cache和上游的接口被定义为写命令和写数据同时传输，因此上游即可能被Write Data Buffer反压，也可能被Tag Pipeline反压。（命令直接发往Cache Pipeline）。

对于每个WDB，反压的原因有两个：

1. 当前这个cycle，从tag pipeline发来了读WDB的指令，SRAM被占用。
2. WDB已满。

WDB的空满计数使用一个counter完成，再pre-alloc一个位置之后+1,在收到tag pipeline发来的读WDB指令并执行后-1。




### Read Data Buffer

Read Data Buffer(RDB)和WDB类似，在每个方向上与每个Sram Group保持一一对应，采用单口Sram实现，与Sram Group的交互有最高优先级（即永远写优先）。

对于Read Data Buffer来说，在收到数据写入时，也会同步收到一个指令。这个指令指明了如何将数据发往Master。

RDB内部的实现其实是一个ROB，以及受ROB控制的单口SRAM。Sram发来的命令除了会写入单口SRAM，也会写入ROB的一个entry中。随后该entry会举手请求从SRAM中读取数据并往Master侧发送。在发送完成后，向ROB发送完成信号，并release。



