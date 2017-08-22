//
//  SocketTestVC.m
//  Jiankongbao
//
//  Created by yunzhihui on 16/2/17.
//  Copyright © 2016年 YunZhiHui. All rights reserved.
//

#import "SocketTestVC.h"
#import <sys/socket.h>
#import <netinet/in.h>
#import <arpa/inet.h>
#import <unistd.h>
#import "AppDelegate.h"

SocketTestVC *g_viewPage;

@interface SocketTestVC ()
{
    CFSocketRef _socket;
}
@property(nonatomic,strong)UILabel *ipLabel;
@property(nonatomic,strong)UITextField *ipField;

@property(nonatomic,strong)UIButton *connectBtn;
@property(nonatomic,strong)UIButton *sendBtn;
@property(nonatomic,strong)UIButton *cancelBtn;

@property(nonatomic,strong)UITextView *textView;


@end


@implementation SocketTestVC

-(void)viewDidLoad
{
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    
    self.ipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 100, 30)];
    ;
    _ipLabel.text = @"serverIP";
    [self.view addSubview:_ipLabel];
    
    self.ipField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_ipLabel.frame), 80, 200, 30)];
    self.ipField.text = @"10.0.5.216";
    self.ipField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_ipField];
    
    self.connectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_ipLabel.frame)+10, 100, 30)];
    [self.connectBtn setTitle:@"connect" forState:UIControlStateNormal];
    _connectBtn.backgroundColor = [UIColor redColor];
    [self.connectBtn addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_connectBtn];
    
    self.sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_connectBtn.frame)+10, CGRectGetMaxY(_ipLabel.frame)+10, 100, 30)];
    [self.sendBtn setTitle:@"send" forState:UIControlStateNormal];
    _sendBtn.backgroundColor = [UIColor redColor];
    [self.sendBtn addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_sendBtn];
    
    self.cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_sendBtn.frame)+10, CGRectGetMaxY(_ipLabel.frame)+10, 100, 30)];
    [self.cancelBtn setTitle:@"cancel" forState:UIControlStateNormal];
    _cancelBtn.backgroundColor = [UIColor redColor];
    [self.cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelBtn];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_connectBtn.frame)+20, 300, 300)];
    [self.view addSubview:_textView];
    _textView.backgroundColor = [UIColor whiteColor];
    _textView.editable = NO;
    
}

-(void)connect:(UIButton *)btn
{
    NSString *serverIp = self.ipField.text;
    [self CreateConnect:serverIp];}

-(void)send:(UIButton *)btn
{
    NSLog(@"hello Server");
    char *data = "\nhello Server\r\n";
    send(CFSocketGetNative(_socket), data, strlen(data) + 1, 0);
    [self.textView insertText:[NSString stringWithCString:data encoding:NSUTF8StringEncoding]];

    
}

-(void)cancel:(UIButton *)btn
{
    close(CFSocketGetNative(_socket));
}

-(void)CreateConnect:(NSString*)strAddress
{
    CFSocketContext sockContext = {0, // 结构体的版本，必须为0
        (__bridge void *)(self),
        NULL, // 一个定义在上面指针中的retain的回调， 可以为NULL
        NULL,
        NULL};
    _socket = CFSocketCreate(kCFAllocatorDefault, // 为新对象分配内存，可以为nil
                             PF_INET, // 协议族，如果为0或者负数，则默认为PF_INET
                             SOCK_STREAM, // 套接字类型，如果协议族为PF_INET,则它会默认为SOCK_STREAM
                             IPPROTO_TCP, // 套接字协议，如果协议族是PF_INET且协议是0或者负数，它会默认为IPPROTO_TCP
                             kCFSocketConnectCallBack, // 触发回调函数的socket消息类型，具体见Callback Types
                             TCPClientConnectCallBack, // 上面情况下触发的回调函数
                             &sockContext // 一个持有CFSocket结构信息的对象，可以为nil
                             );
    if(_socket != NULL)
    {
        struct sockaddr_in addr4;   // IPV4
        memset(&addr4, 0, sizeof(addr4));
        addr4.sin_len = sizeof(addr4);
        addr4.sin_family = AF_INET;
        addr4.sin_port = htons(8888);
        addr4.sin_addr.s_addr = inet_addr([strAddress UTF8String]);  // 把字符串的地址转换为机器可识别的网络地址
        
        // 把sockaddr_in结构体中的地址转换为Data
        CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
        
        CFSocketConnectToAddress(_socket, // 连接的socket
                                 address, // CFDataRef类型的包含上面socket的远程地址的对象
                                 -1  // 连接超时时间，如果为负，则不尝试连接，而是把连接放在后台进行，如果_socket消息类型为kCFSocketConnectCallBack，将会在连接成功或失败的时候在后台触发回调函数
                                 );
        
        
        
        
        CFRunLoopRef cRunRef = CFRunLoopGetCurrent();    // 获取当前线程的循环
        // 创建一个循环，但并没有真正加如到循环中，需要调用CFRunLoopAddSource
        CFRunLoopSourceRef sourceRef = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
        CFRunLoopAddSource(cRunRef, // 运行循环
                           sourceRef,  // 增加的运行循环源, 它会被retain一次
                           kCFRunLoopCommonModes  // 增加的运行循环源的模式
                           );
        CFRelease(sourceRef);
        NSLog(@"connect ok");
    }
}

// socket回调函数，同客户端
static void TCPClientConnectCallBack(CFSocketRef socket, CFSocketCallBackType type, CFDataRef address, const void *data, void *info)
{
    SocketTestVC *client = (__bridge SocketTestVC *)info;
    if (data != NULL)
    {
        NSLog(@"连接失败");
        [client.textView insertText:@"连接失败\n"];
        return;
    }
    else
    {
        NSLog(@"连接成功");
        [client.textView insertText:@"连接成功\n"];
        // 读取接收的数据
        g_viewPage = client;
        [client StartReadThread];
        
    }
}


-(void)StartReadThread
{
    
    NSThread *InitThread = [[NSThread alloc]initWithTarget:self selector:@selector(InitThreadFunc:) object:self];
    
    [InitThread start];
}
-(void)InitThreadFunc:(id)sender
{
    
    while (1) {
        // 读取接收的数据
        char buffer[1024];
        
        NSString *str = @"\n服务器发来数据：";
        ssize_t a = recv(CFSocketGetNative(_socket), buffer, sizeof(buffer), 0);
        if (a) {
            str = [str stringByAppendingString:[NSString stringWithUTF8String:buffer]];
        }else{
        
            break;
        }
        [self performSelectorOnMainThread:@selector(ShowMsg:) withObject:str waitUntilDone:NO];
    }

}


-(void)ShowMsg:(NSString *)str
{
  
    [self.textView insertText:str];
}


@end
