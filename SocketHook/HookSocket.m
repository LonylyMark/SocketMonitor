//
//  HookSocket.m
//
//  Created by Cloudwise-Cyan on 2017/5/3.
//  Copyright © 2017年 Cloudwise-Cyan Xu. All rights reserved.
//

#import "HookSocket.h"
#import <dlfcn.h>
#import <sys/socket.h>
#import "fishhook.h"
#import <arpa/inet.h>
#import <netdb.h>
#import <ifaddrs.h>
#import <CoreFoundation/CFSocket.h>

static NSMutableArray *streamClientCallBackArray;
//static CFReadStreamClientCallBack my_clientCB;
@interface testCallBackModel : NSObject

@property(nonatomic,assign)CFReadStreamRef stream;
@property(nonatomic,assign)CFReadStreamClientCallBack clientCB;

@end

@implementation testCallBackModel

@end


@implementation HookSocket
//定义静态方法  参数与监控的方法一样
static int (*orig_connect)(int, const struct sockaddr *, socklen_t);
static int (*orig_close)(int);
static int (*orig_socket)(int, int, int);
static ssize_t (*orig_recv)(int, void *, size_t, int);
static ssize_t (*orig_send)(int, const void *, size_t, int);
static ssize_t (*orig_sendto)(int, const void *, size_t,
                              int, const struct sockaddr *, socklen_t);
//static int	(*orig_getsockname)(int, struct sockaddr * __restrict, socklen_t * __restrict);
struct hostent	*(*orig_gethostbyname)(const char *);
struct hostent	*(*orig_gethostbyaddr)(const void *, socklen_t, int);

static CFSocketRef (*orig_CFSocketCreate)(CFAllocatorRef , SInt32 , SInt32 , SInt32 , CFOptionFlags , CFSocketCallBack , const CFSocketContext *);

static CFSocketError (*orig_CFSocketConnectToAddress)(CFSocketRef , CFDataRef , CFTimeInterval );

static CFIndex (*orig_CFWriteStreamWrite)(CFWriteStreamRef stream, const UInt8 *buffer, CFIndex bufferLength);

static CFIndex (*orig_CFReadStreamRead)(CFReadStreamRef stream, UInt8 *buffer, CFIndex bufferLength);
static Boolean (*orig_CFReadStreamSetClient)(CFReadStreamRef stream, CFOptionFlags streamEvents, CFReadStreamClientCallBack clientCB, CFStreamClientContext *clientContext);
static void (*orig_CFReadStreamClose)(CFReadStreamRef stream);

static void (*orig_CFReadStreamUnscheduleFromRunLoop)(CFReadStreamRef stream, CFRunLoopRef runLoop, CFStringRef runLoopMode);

//新增
//static Boolean (*orig_CFWriteStreamCanAcceptBytes)(CFWriteStreamRef stream);
//static Boolean (*orig_CFReadStreamHasBytesAvailable)(CFReadStreamRef stream);

void save_orignal_symbols(){
    orig_connect = dlsym(RTLD_DEFAULT, "connect");
    orig_close = dlsym(RTLD_DEFAULT, "close");
    orig_socket = dlsym(RTLD_DEFAULT, "socket");
    orig_recv = dlsym(RTLD_DEFAULT, "recv");
    orig_send = dlsym(RTLD_DEFAULT, "send");
    orig_sendto = dlsym(RTLD_DEFAULT, "sendto");
    // orig_getsockname = dlsym(RTLD_DEFAULT, "getsockname");
    orig_gethostbyname = dlsym(RTLD_DEFAULT, "gethostbyname");
    orig_gethostbyaddr = dlsym(RTLD_DEFAULT, "gethostbyaddr");
    
    orig_CFSocketCreate = dlsym(RTLD_DEFAULT, "CFSocketCreate");
    orig_CFSocketConnectToAddress = dlsym(RTLD_DEFAULT, "CFSocketConnectToAddress");
    
    
    orig_CFWriteStreamWrite = dlsym(RTLD_DEFAULT, "CFWriteStreamWrite");
    orig_CFReadStreamRead = dlsym(RTLD_DEFAULT, "CFReadStreamRead");
   
    orig_CFReadStreamSetClient = dlsym(RTLD_DEFAULT, "CFReadStreamSetClient");
    orig_CFReadStreamClose = dlsym(RTLD_DEFAULT, "CFReadStreamClose");
    orig_CFReadStreamUnscheduleFromRunLoop = dlsym(RTLD_DEFAULT, "CFReadStreamUnscheduleFromRunLoop");
}

struct hostent	*my_gethostbyaddr(const void *my_addr, socklen_t my_skt, int my_type)
{
    double beginTime = CFAbsoluteTimeGetCurrent();
    struct hostent *a = orig_gethostbyaddr(my_addr,my_skt,my_type);
    double endTime = CFAbsoluteTimeGetCurrent();
    double dur = endTime - beginTime;
    printf("DNS解析用时 %f \n",dur);
    return a;
    
}
struct hostent	*my_gethostbyname(const char * myHostName){
    
    double beginTime = CFAbsoluteTimeGetCurrent();
    struct hostent *a = orig_gethostbyname(myHostName);
    double endTime = CFAbsoluteTimeGetCurrent();
    double dur = endTime - beginTime;
    printf("DNS解析用时 %f \n",dur);
    return a;
    
}

//int	my_getsockname(int myInt, struct sockaddr * __restrict mySockaddr, socklen_t * __restrict mySocklen_t){
//
//    int a = orig_getsockname(myInt ,mySockaddr, mySocklen_t);
//
//    return a;
//}
//关闭socket连接
int	 my_close(int myInt){
    
    double beginTime = CFAbsoluteTimeGetCurrent();
    int rt = orig_close(myInt);
    double endTime = CFAbsoluteTimeGetCurrent();
    //close的耗时
    double dur = endTime - beginTime;
    
    NSLog(@"关闭socket %d\n",myInt);
    
    return rt;
}


//第一个参数即为客户端的socket描述字
//第二参数为服务器的socket地址
//第三个参数为socket地址的长度。客户端通过调用connect函数来建立与TCP服务器的连接。

int my_connect(int myInt, const struct sockaddr * myskaddr, socklen_t skt){
    
    
    NSLog(@"hook到了connect \n");
    
    double beginTime = CFAbsoluteTimeGetCurrent();
    
    int rt = orig_connect(myInt,myskaddr,skt);
    
    double endTime = CFAbsoluteTimeGetCurrent();
    
    double dur = endTime - beginTime;
    NSLog(@"连接用时 %f \n",dur);
    if (myskaddr && myskaddr->sa_family == AF_INET) {
        //        struct sockaddr_in sin;
        //        memcpy(&sin, myskaddr, sizeof(sin));
        //        NSString *ip = [NSString stringWithCString:inet_ntoa(sin.sin_addr) encoding:NSUTF8StringEncoding];
        //        int por = htons(sin.sin_port);
        //        NSLog(@"%@",ip);
        //        NSLog(@"%d",por);
        //获取IP和端口号
        char servHost[1024];
        char servPort[20];
        getnameinfo(myskaddr, sizeof(myskaddr), servHost, sizeof(servHost), servPort, sizeof(servPort), NI_NUMERICHOST | NI_NUMERICSERV);
        NSString * servIP = [NSString stringWithUTF8String:servHost];
        int sPort = [[NSString stringWithUTF8String:servPort] intValue];
        NSLog(@"%@\n%d",servIP,sPort);
        
        struct sockaddr_in clientAddr;
        unsigned int clientAddrLen = sizeof(clientAddr);
        char ipAddress[INET_ADDRSTRLEN];
        getsockname(myInt, (struct sockaddr*)&clientAddr, &clientAddrLen);
        const char *clientIP = inet_ntop(AF_INET, &clientAddr.sin_addr, ipAddress, sizeof(ipAddress));
        NSString *cIP = [NSString stringWithUTF8String:clientIP];
        int cPort = htons(clientAddr.sin_port);
        NSLog(@"client ip:%@ port:%d",cIP,cPort);
        printf("client:client ddress = %s:%d\n", inet_ntop(AF_INET, &clientAddr.sin_addr, ipAddress, sizeof(ipAddress)), ntohs(clientAddr.sin_port));
        
    }
    
    return rt;
}

//af、type、protocol
//参数af指定通信发生的区域，UNIX系统支持的地址族有：AF_UNIX、AF_INET、AF_NS等，而DOS、WINDOWS中仅支持AF_INET，它是网际网区域。因此，地址族与协议族相同.
//参数type 描述要建立的套接字的类型。
//参数protocol说明该套接字使用的特定协议，如果调用者不希望特别指定使用的协议，则置为0，使用默认的连接模式。
//返回-1出错
int my_socket(int addressFamily, int type, int protocol){
    
    int socket= orig_socket(addressFamily,type,protocol);
    
    if(socket < 0){
        int optval;
        unsigned int optlen = sizeof(int);
        getsockopt(socket, SOL_SOCKET, SO_TYPE, &optval, &optlen);
        printf("optval = %d\n", optval);
    }
    NSLog(@"hook到了socket %d 参数%d %d %d \n ",socket,addressFamily,type,protocol);
    return socket;
}

ssize_t	my_sendto(int sockfd , const void *msg, size_t len,
                  int flags, const struct sockaddr *to, socklen_t tolen){
    double beginTime = CFAbsoluteTimeGetCurrent();
    ssize_t rt = orig_sendto(sockfd,msg,len,flags,to,tolen);
    double endTime = CFAbsoluteTimeGetCurrent();
    double dur = endTime - beginTime;
    
    char servHost[1024];
    char servPort[20];
    getnameinfo(to, sizeof(to), servHost, sizeof(servHost), servPort, sizeof(servPort), NI_NUMERICHOST | NI_NUMERICSERV);
    NSString * servIP = [NSString stringWithUTF8String:servHost];
    int sPort = [[NSString stringWithUTF8String:servPort] intValue];
    NSLog(@"%@\n%d",servIP,sPort);
    
    struct sockaddr_in clientAddr;
    unsigned int clientAddrLen = sizeof(clientAddr);
    char ipAddress[INET_ADDRSTRLEN];
    getsockname(sockfd, (struct sockaddr*)&clientAddr, &clientAddrLen);
    const char *clientIP = inet_ntop(AF_INET, &clientAddr.sin_addr, ipAddress, sizeof(ipAddress));
    NSString *cIP = [NSString stringWithUTF8String:clientIP];
    int cPort = htons(clientAddr.sin_port);
    NSLog(@"client ip:%@ port:%d",cIP,cPort);
    
    NSLog(@"发送数据用时 %f socketFileDescriptor 是%d, 数据长度是 %zu---%zu\n",dur,sockfd,len,rt);
    return rt;
    
}

ssize_t	my_send(int socketFileDescriptor, const void *buffer, size_t length, int j){
    double beginTime = CFAbsoluteTimeGetCurrent();
    ssize_t rt = orig_send(socketFileDescriptor,buffer,length,j);
    double endTime = CFAbsoluteTimeGetCurrent();
    double dur = endTime - beginTime;
    
    NSLog(@"发送数据用时 %f socketFileDescriptor 是%d, 数据长度是 %zu内容：%@\n",dur,socketFileDescriptor,rt,[NSString stringWithUTF8String:buffer]);
    return rt;
    
    
}
ssize_t my_recv(int socketFileDescriptor, void *buffer, size_t length, int j){
    double beginTime = CFAbsoluteTimeGetCurrent();
    ssize_t rt = orig_recv(socketFileDescriptor,buffer,length,j);
    double endTime = CFAbsoluteTimeGetCurrent();
    
    double dur = endTime - beginTime;
    
    NSLog(@"获取数据用时 %f socketFileDescriptor 是%d, 数据长度是 %zu,内容：%@\n",dur,socketFileDescriptor,rt,[NSString stringWithUTF8String:buffer]);
    return rt;
}

#pragma mark -- CFSocket (CFNetwork框架创建)
CFSocketRef	my_CFSocketCreate(CFAllocatorRef allocator, SInt32 protocolFamily, SInt32 socketType, SInt32 protocol, CFOptionFlags callBackTypes, CFSocketCallBack callout, const CFSocketContext *context){
    
    CFSocketRef orig_socket = orig_CFSocketCreate( allocator,  protocolFamily,  socketType,  protocol,  callBackTypes,  callout, context);
    NSLog(@"创建socket %d",CFSocketGetNative(orig_socket));
    
    return orig_socket;
    
}

CFSocketError	my_CFSocketConnectToAddress(CFSocketRef s, CFDataRef address, CFTimeInterval timeout){
    CFSocketError orig_socketError = orig_CFSocketConnectToAddress( s,  address,  timeout);
    if (timeout>0 && orig_socketError == kCFSocketSuccess) {
        NSLog(@"连接成功");
    }
    
    //CFDataRef peeraddr = CFSocketCopyPeerAddress(theSocket);
    struct sockaddr *to = (struct sockaddr *)CFDataGetBytePtr(address);
    char servHost[1024];
    char servPort[20];
    getnameinfo(to, sizeof(to), servHost, sizeof(servHost), servPort, sizeof(servPort), NI_NUMERICHOST | NI_NUMERICSERV);
    NSString * servIP = [NSString stringWithUTF8String:servHost];
    int sPort = [[NSString stringWithUTF8String:servPort] intValue];
    NSLog(@"%@\n%d",servIP,sPort);
    
    struct sockaddr_in clientAddr;
    unsigned int clientAddrLen = sizeof(clientAddr);
    char ipAddress[INET_ADDRSTRLEN];
    getsockname(CFSocketGetNative(s), (struct sockaddr*)&clientAddr, &clientAddrLen);
    const char *clientIP = inet_ntop(AF_INET, &clientAddr.sin_addr, ipAddress, sizeof(ipAddress));
    NSString *cIP = [NSString stringWithUTF8String:clientIP];
    int cPort = htons(clientAddr.sin_port);
    NSLog(@"client ip:%@ port:%d",cIP,cPort);
    
    return orig_socketError;
}

CFIndex my_CFWriteStreamWrite(CFWriteStreamRef stream, const UInt8 *buffer, CFIndex bufferLength){
    
    CFIndex write = orig_CFWriteStreamWrite(stream,buffer,bufferLength);
    NSLog(@"发送数据的长度：%ld",write);
    return write;
}

CFIndex my_CFReadStreamRead(CFReadStreamRef stream, UInt8 *buffer, CFIndex bufferLength){
    
    CFIndex read = orig_CFReadStreamRead(stream,buffer,bufferLength);
    NSLog(@"收到数据的长度：%ld",read);
    return read;
    
}

Boolean my_CFReadStreamSetClient(CFReadStreamRef stream, CFOptionFlags streamEvents, CFReadStreamClientCallBack clientCB, CFStreamClientContext *clientContext){
    
     Boolean readClient = orig_CFReadStreamSetClient(stream,streamEvents,clientCB,clientContext);
    
    
    //my_clientCB = clientCB;
//    testCallBackModel *model = [[testCallBackModel alloc] init];
//    model.stream = stream;
//    model.clientCB = clientCB;
//    [streamClientCallBackArray addObject:model];
    
    return readClient;
}

void my_CFReadStreamClientCallBack(CFReadStreamRef stream, CFStreamEventType type, void *clientCallBackInfo){
   
//
//     int i = 0;
//     for (testCallBackModel *model in streamClientCallBackArray) {
//         i++;
//         if (model.stream == stream) {
//             model.clientCB(stream ,type,clientCallBackInfo);
//             NSLog(@" ----- %d",i);
//             break;
//             
//         }
//     }
     
}
//关闭读数据的流
void my_CFReadStreamClose(CFReadStreamRef stream){
    
    orig_CFReadStreamClose(stream);
    for (testCallBackModel *model in streamClientCallBackArray) {
        
        if (model.stream == stream) {
            [streamClientCallBackArray removeObject:model];
            NSLog(@"-----");
            break;
            
        }
    }

    return ;
}

void my_CFReadStreamUnscheduleFromRunLoop(CFReadStreamRef stream, CFRunLoopRef runLoop, CFStringRef runLoopMode)
{
    orig_CFReadStreamUnscheduleFromRunLoop(stream,runLoop,runLoopMode);
    return;
}
//放在appdelegate里面调用  启动对socket的监控
-(void)open
{
    streamClientCallBackArray = [NSMutableArray array];
    save_orignal_symbols();
    //动态替换成实现自定义功能的方法
    rebind_symbols((struct rebinding[15]){{"connect",my_connect,(void *)&orig_connect},
        {"close",my_close,(void *)&orig_close},
        {"socket",my_socket,(void *)&orig_socket},
        {"recv",my_recv,(void *)&orig_recv},
        {"send",my_send,(void *)&orig_send},
        {"sendto",my_sendto,(void *)&orig_sendto},
        {"gethostbyname",my_gethostbyname,(void *)&orig_gethostbyname},
        {"gethostbyaddr",my_gethostbyaddr,(void *)&orig_gethostbyaddr},
        {"CFSocketCreate",my_CFSocketCreate,(void *)&orig_CFSocketCreate},
        {"CFSocketConnectToAddress",my_CFSocketConnectToAddress,(void *)&orig_CFSocketConnectToAddress},
        {"CFWriteStreamWrite",my_CFWriteStreamWrite,(void *)&orig_CFWriteStreamWrite},
        {"CFReadStreamRead",my_CFReadStreamRead,(void *)&orig_CFReadStreamRead},
        {"CFReadStreamSetClient",my_CFReadStreamSetClient,(void *)&orig_CFReadStreamSetClient},
        {"CFReadStreamClose",my_CFReadStreamClose,(void *)&orig_CFReadStreamClose},
         {"CFReadStreamUnscheduleFromRunLoop",my_CFReadStreamUnscheduleFromRunLoop,(void *)&orig_CFReadStreamUnscheduleFromRunLoop}
    }, 15);
}

@end

