//
//  Singleton.h
//  InterfaceTest
//
//  Created by yunzhihui on 15/12/21.
//
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"
#import "SocketTestVCASY.h"
enum{
    SocketOfflineByServer,// 服务器掉线，默认为0
    SocketOfflineByUser,  // 用户主动cut
};

@interface Singleton : NSObject
@property(nonatomic,strong) SocketTestVCASY *svc;
@property (nonatomic, strong) AsyncSocket    *socket;       // socket
@property (nonatomic, copy  ) NSString       *socketHost;   // socket的Host
@property (nonatomic, assign) UInt16         socketPort;    // socket的prot

@property (nonatomic, retain) NSTimer        *connectTimer; // 计时器

+(Singleton *) sharedInstance;

-(void)socketConnectHost;// socket连接

-(void)cutOffSocket; // 断开socket连接

-(void)sendMsg;
@end
