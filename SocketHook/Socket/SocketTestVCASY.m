//
//  SocketTestVCASY.m
//  Jiankongbao
//
//  Created by yunzhihui on 16/2/17.
//  Copyright © 2016年 YunZhiHui. All rights reserved.
//

#import "SocketTestVCASY.h"
#import "Singleton.h"
#import "AppDelegate.h"
@interface SocketTestVCASY ()
{
    CFSocketRef _socket;
}
@property(nonatomic,strong)UILabel *ipLabel;
@property(nonatomic,strong)UITextField *ipField;
@property(nonatomic,strong)UITextField *portField;

@property(nonatomic,strong)UIButton *connectBtn;
@property(nonatomic,strong)UIButton *sendBtn;
@property(nonatomic,strong)UIButton *cancelBtn;

@end

@implementation SocketTestVCASY
-(void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    

}
- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.view.backgroundColor = [UIColor lightGrayColor];
    
    self.ipLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 80, 70, 30)];
    ;
    _ipLabel.text = @"serverIP";
    [self.view addSubview:_ipLabel];
    
    self.ipField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_ipLabel.frame), 80, 200, 30)];
    self.ipField.text = @"towel.blinkenlights.nl";
    self.ipField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_ipField];
    
    self.portField = [[UITextField alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_ipField.frame), 80, 65, 30)];
    self.portField.text = @"23";
    self.portField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:_portField];
    
    self.connectBtn = [[UIButton alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(_ipLabel.frame)+10, 100, 30)];
    [self.connectBtn setTitle:@"connect" forState:UIControlStateNormal];
    [self.connectBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    _connectBtn.backgroundColor = [UIColor redColor];
    
    [self.connectBtn addTarget:self action:@selector(connect:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_connectBtn];
    
    self.sendBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_connectBtn.frame)+10, CGRectGetMaxY(_ipLabel.frame)+10, 100, 30)];
    [self.sendBtn setTitle:@"send" forState:UIControlStateNormal];
    [self.sendBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    _sendBtn.backgroundColor = [UIColor redColor];
    [self.sendBtn addTarget:self action:@selector(send:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_sendBtn];
    
    self.cancelBtn = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetMaxX(_sendBtn.frame)+10, CGRectGetMaxY(_ipLabel.frame)+10, 100, 30)];
    [self.cancelBtn setTitle:@"cancel" forState:UIControlStateNormal];
    [self.cancelBtn setTitleColor:[UIColor lightGrayColor] forState:UIControlStateHighlighted];
    _cancelBtn.backgroundColor = [UIColor redColor];
    [self.cancelBtn addTarget:self action:@selector(cancel:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:_cancelBtn];
    
    self.textView = [[UITextView alloc] initWithFrame:CGRectMake(10, CGRectGetMaxY(_connectBtn.frame)+20, 300, 300)];
    [self.view addSubview:_textView];
    _textView.editable = NO;
    _textView.backgroundColor = [UIColor whiteColor];

}
-(void)connect:(UIButton *)btn
{
    [Singleton sharedInstance].svc = self;
    [Singleton sharedInstance].socketHost =  self.ipField.text;//@"94.142.241.111";// host设定
    [Singleton sharedInstance].socketPort = [self.portField.text integerValue];// port设定
    
    // 在连接前先进行手动断开
    [Singleton sharedInstance].socket.userData = SocketOfflineByUser;
    [[Singleton sharedInstance] cutOffSocket];
    
    // 确保断开后再连，如果对一个正处于连接状态的socket进行连接，会出现崩溃
    [Singleton sharedInstance].socket.userData = SocketOfflineByServer;
    [[Singleton sharedInstance] socketConnectHost];

}

-(void)send:(UIButton *)btn
{
   [[Singleton sharedInstance] sendMsg];
}

-(void)cancel:(UIButton *)btn
{
    [[Singleton sharedInstance] cutOffSocket];
}
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    [_ipField resignFirstResponder];
    [_portField resignFirstResponder];
}
- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}



@end
