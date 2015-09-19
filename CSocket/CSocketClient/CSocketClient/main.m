//
//  main.m
//  CSocketClient
//
//  Created by neo on 15/8/28.
//  Copyright (c) 2015年 justlike. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <arpa/inet.h>

CFWriteStreamRef outputStream;

@interface ClientSocket : NSObject
@property(nonatomic, assign)CFSocketRef socket;

@end

@implementation ClientSocket

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
		addr4.sin_port = htons(8080);
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
	if (kCFSocketAcceptCallBack == type)
	{
		// 本地套接字句柄
		CFSocketNativeHandle nativeSocketHandle = *(CFSocketNativeHandle *)data;
		uint8_t name[SOCK_MAXADDRLEN];
		socklen_t nameLen = sizeof(name);
		if (0 != getpeername(nativeSocketHandle, (struct sockaddr *)name, &nameLen)) {
			NSLog(@"error");
			exit(1);
		}
		CFReadStreamRef iStream;
		CFWriteStreamRef oStream;
		// 创建一个可读写的socket连接
		CFStreamCreatePairWithSocket(kCFAllocatorDefault, nativeSocketHandle, &iStream, &oStream);
		if (iStream && oStream)
		{
			CFStreamClientContext streamContext = {0, info, NULL, NULL};
			if (!CFReadStreamSetClient(iStream, kCFStreamEventHasBytesAvailable,readStream, &streamContext))
			{
				exit(1);
			}
			
			if (!CFWriteStreamSetClient(oStream, kCFStreamEventCanAcceptBytes, writeStream, &streamContext))
			{
				exit(1);
			}
			CFReadStreamScheduleWithRunLoop(iStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
			CFWriteStreamScheduleWithRunLoop(oStream, CFRunLoopGetCurrent(), kCFRunLoopDefaultMode);
			CFReadStreamOpen(iStream);
			CFWriteStreamOpen(oStream);
		} else
		{
			close(nativeSocketHandle);
		}
	}
}

// 读取数据
void readStream(CFReadStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo)
{
	UInt8 buff[1024*4];
	
	NSMutableData *recvData = [NSMutableData data];
	
	while (1) {
		CFIndex count = CFReadStreamRead(stream, buff, 1024*4);
		if (count==0 || count == -1) {
			
		}else{
			[recvData appendBytes:buff length:count];
			if (!CFReadStreamHasBytesAvailable(stream)) {
				break;
			}
		}
	}
	NSString *recvString = [[NSString alloc]initWithData:recvData encoding:NSUTF8StringEncoding];
	///根据delegate显示到主界面去
	NSString *strMsg = [[NSString alloc]initWithFormat:@"客户端传来消息：%@",recvString];
	
	
	//	CSocketServer *info = (__bridge CSocketServer*)clientCallBackInfo;
	//	[info ShowMsgOnMainPage:strMsg];
	NSLog(@"%@",strMsg);
	
	//	char *str = "你好 Client";
	NSString *string = @"你好 Client\n";
	NSData *data = [string dataUsingEncoding:NSUTF8StringEncoding];
	
	
	NSMutableData *data1 = [NSMutableData dataWithData:data];
	//	uint8_t * uin8b = (uint8_t *)str;
	const uint8_t * uin8b = data1.bytes;
	if (outputStream != NULL)
	{
		
		while (1) {
			if (data1.length>0 && CFWriteStreamCanAcceptBytes(outputStream)) {
				CFIndex writeLength = CFWriteStreamWrite(outputStream, uin8b, data1.length);
				
				if (writeLength == 0 || writeLength == -1) {
					
				}else{
					[data1 replaceBytesInRange:NSMakeRange(0, writeLength) withBytes:NULL length:0];
					
				}
			}else{
				break;
			}
			
		}
	}
	else {
		NSLog(@"Cannot send data!");
	}
	
}
void writeStream (CFWriteStreamRef stream, CFStreamEventType eventType, void *clientCallBackInfo)
{
	outputStream = stream;
	
}

- (void) stream:(NSStream*)stream handleEvent:(NSStreamEvent)eventCode {
	switch (eventCode) {
		case NSStreamEventOpenCompleted: {
			break;
		}
		case NSStreamEventHasBytesAvailable: {
			break;
		}
		case NSStreamEventHasSpaceAvailable: {
			break;
		}
		case NSStreamEventEndEncountered: {
			break;
		}
		case NSStreamEventErrorOccurred: {
			break;
		}
		default:
			break;
	}
}



@end




int main(int argc, const char * argv[]) {
	
/*
 C语言 socket
 */
	struct sockaddr_in server_addr;
	server_addr.sin_len = sizeof(struct sockaddr_in);
	server_addr.sin_family = AF_INET;
	server_addr.sin_port = htons(11332);
	server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
	bzero(&(server_addr.sin_zero),8);

	int server_socket = socket(AF_INET, SOCK_STREAM, 0);
	if (server_socket == -1) {
		perror("socket error");
		return 1;
	}
	char recv_msg[1024];
	char reply_msg[1024];

	if (connect(server_socket, (struct sockaddr *)&server_addr, sizeof(struct sockaddr_in))==0)     {
		//connect 成功之后，其实系统将你创建的socket绑定到一个系统分配的端口上，且其为全相关，包含服务器端的信息，可以用来和服务器端进行通信。
		while (1) {
			bzero(recv_msg, 1024);
			bzero(reply_msg, 1024);
			long byte_num = recv(server_socket,recv_msg,1024,0);
			recv_msg[byte_num] = '\0';
			printf("server said:%s\n",recv_msg);
			
			printf("reply:");
			scanf("%s",reply_msg);
			if (send(server_socket, reply_msg, 1024, 0) == -1) {
				perror("send error");
			}
		}
		
	}

	
	
	
	
	
	@autoreleasepool {
	    // insert code here...
	    NSLog(@"Hello, World!");
	}
    return 0;
}
