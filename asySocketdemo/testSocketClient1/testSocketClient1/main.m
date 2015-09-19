//
//  main.m
//  testSocketClient1
//
//  Created by neo on 15/8/21.
//  Copyright (c) 2015年 justlike. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "AsyncSocket.h"

@interface client : NSObject<AsyncSocketDelegate>{
	AsyncSocket *asyncSocket;
}
@property (nonatomic ,retain)AsyncSocket *asyncSocket;
@end

@implementation client
@synthesize asyncSocket;



-(void)start{
	asyncSocket = [[AsyncSocket alloc] initWithDelegate:self];
	NSError *err = nil;
	if(![asyncSocket connectToHost:@"127.0.0.1" onPort:8080 error:&err])
	{
		NSLog(@"Error: %@", err);
	}
//	NSData *aData=[@"Hi there" dataUsingEncoding:NSUTF8StringEncoding];
//	[asyncSocket writeData:aData withTimeout:-1 tag:0];
}

//建立连接
-(void)onSocket:(AsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
	NSLog(@"onScoket:%p did connecte to host:%@ on port:%d",sock,host,port);
	
//	NSData *aData=[@"Hi there" dataUsingEncoding:NSUTF8StringEncoding];
//	[sock writeData:aData withTimeout:-1 tag:0];
	
	[sock readDataWithTimeout:-1 tag:0];
	
}

//读取数据
-(void)onSocket:(AsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
	NSString *aStr=[[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	NSLog(@"aStr==%@",aStr);
	
	NSData *aData=[@"Hi there" dataUsingEncoding:NSUTF8StringEncoding];
	[sock writeData:aData withTimeout:-1 tag:0];
	
	[sock readDataWithTimeout:-1 tag:0];
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


@end



int main(int argc, const char * argv[]) {
	

	
	
	client *cl = [[client alloc]init];
	[cl start];
	
	[[NSRunLoop currentRunLoop] runUntilDate:[NSDate dateWithTimeIntervalSinceNow:60*60*3]];
	[NSTimer scheduledTimerWithTimeInterval:6*60 target:cl selector:@selector(description) userInfo:nil repeats:NO];
	
	
	@autoreleasepool {
	    // insert code here...
	    NSLog(@"Hello, World!");
	}
    return 0;
}
