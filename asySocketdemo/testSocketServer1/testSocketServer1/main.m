//
//  main.m
//  testSocketServer1
//
//  Created by neo on 15/8/21.
//  Copyright (c) 2015年 justlike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

@interface server : NSObject<AsyncSocketDelegate>{
	AsyncSocket *asyncSocket;
}
@property (nonatomic ,retain)AsyncSocket *asyncSocket;
@property (nonatomic ,retain)AsyncSocket *clientAsycSocket;

@end

@implementation server
@synthesize asyncSocket;


-(void)start{
	asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
	NSError *err = nil;
	if (![asyncSocket acceptOnPort:8080 error:&err]) {
		return;
	}
	NSLog(@"开始监听");
}

- (void)onSocket:(AsyncSocket *)sock didAcceptNewSocket:(AsyncSocket *)newSocket
{
	NSLog(@"%s", __func__);
	
	self.clientAsycSocket = newSocket;

}


- (void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port{
	NSLog(@"%s",__func__);
	
	[sock readDataWithTimeout:-1 tag:0];
	
	NSData *aData=[@"Hi there  server" dataUsingEncoding:NSUTF8StringEncoding];
	[sock writeData:aData withTimeout:-1 tag:0];
}


//读取数据
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSString *aStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"aStr==%@",aStr);
	
	
}

//是否加密
-(void)onSocketDidSecure:(AsyncSocket *)sock
{
	NSLog(@"onSocket:%p did go a secure line:YES",sock);
}

//遇到错误时关闭连接
-(void)onSocket:(AsyncSocket *)sock willDisconnectWithError:(NSError *)err
{
	NSLog(@"onSocket:%p will disconnect with error:%@",sock,err);
}

//断开连接
-(void)onSocketDidDisconnect:(AsyncSocket *)sock
{
	NSLog(@"onSocketDidDisconnect:%p",sock);
	
}

- (void )dealloc
{
	NSLog(@"%s", __func__);
}


@end


int main(int argc, const char * argv[]) {

	server *sv =[[server alloc]init];
	[sv start];
	
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:60*60*3]];
	
	
	[NSTimer scheduledTimerWithTimeInterval:6*60 target:sv selector:@selector(description) userInfo:nil repeats:NO];
	

	
	
	@autoreleasepool {
	    // insert code here...
	    NSLog(@"Hello, World!");
	}
    return 0;
}
