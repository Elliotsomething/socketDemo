//
//  main.m
//  CSocketServer
//
//  Created by neo on 15/8/28.
//  Copyright (c) 2015年 justlike. All rights reserved.
//

#import <Foundation/Foundation.h>
#include <arpa/inet.h>

CFWriteStreamRef outputStream;
@interface CSocketServer : NSObject<NSStreamDelegate>
@property (nonatomic, assign) CFSocketRef socket;
@property (nonatomic) NSInteger port;


@end

@implementation CSocketServer

-(int)setupSocket
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
							 kCFSocketAcceptCallBack, // 触发回调函数的socket消息类型，具体见Callback Types
							 SocketConnectionAcceptedCallBack, // 上面情况下触发的回调函数
							 &sockContext // 一个持有CFSocket结构信息的对象，可以为nil
							 );
	if (NULL == _socket) {
		NSLog(@"Cannot create socket!");
		return 0;
	}
	
	int optval = 1;
	setsockopt(CFSocketGetNative(_socket), SOL_SOCKET, SO_REUSEADDR, // 允许重用本地地址和端口
			   (void *)&optval, sizeof(optval));
	
	struct sockaddr_in addr4;
	memset(&addr4, 0, sizeof(addr4));
	addr4.sin_len = sizeof(addr4);
	addr4.sin_family = AF_INET;
	addr4.sin_port = htons(8080);
	addr4.sin_addr.s_addr = htonl(INADDR_ANY);
	CFDataRef address = CFDataCreate(kCFAllocatorDefault, (UInt8 *)&addr4, sizeof(addr4));
	
	if (kCFSocketSuccess != CFSocketSetAddress(_socket, address))
	{
		NSLog(@"Bind to address failed!");
		if (_socket)
			CFRelease(_socket);
		_socket = NULL;
		return 0;
	}
	
	CFRunLoopRef cfRunLoop = CFRunLoopGetCurrent();
	CFRunLoopSourceRef source = CFSocketCreateRunLoopSource(kCFAllocatorDefault, _socket, 0);
	CFRunLoopAddSource(cfRunLoop, source, kCFRunLoopCommonModes);
	CFRunLoopRun();
	CFRelease(source);
	
	return 1;
}

-(void) SendMessage
{
	char *str = "你好 Client";
	uint8_t * uin8b = (uint8_t *)str;
	if (outputStream != NULL)
	{
		CFWriteStreamWrite(outputStream, uin8b, strlen(str) + 1);
	}
	else {
		NSLog(@"Cannot send data!");
	}
	
}

//回调
static void SocketConnectionAcceptedCallBack(CFSocketRef socket,
											 CFSocketCallBackType type,
											 CFDataRef address,
											 const void *data, void *info) {
	
	
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
 C语言  socket
 */
	struct sockaddr_in server_addr;
	server_addr.sin_len = sizeof(struct sockaddr_in);
	server_addr.sin_family = AF_INET;//Address families AF_INET互联网地址簇
	server_addr.sin_port = htons(11332);
	server_addr.sin_addr.s_addr = inet_addr("127.0.0.1");
	bzero(&(server_addr.sin_zero),8);

	//创建socket
	int server_socket = socket(AF_INET, SOCK_STREAM, 0);//SOCK_STREAM 有连接
	if (server_socket == -1) {
		perror("socket error");
		return 1;
	}
	
	//绑定socket：将创建的socket绑定到本地的IP地址和端口，此socket是半相关的，只是负责侦听客户端的连接请求，并不能用于和客户端通信
	int bind_result = bind(server_socket, (struct sockaddr *)&server_addr, sizeof(server_addr));
	if (bind_result == -1) {
		perror("bind error");
		return 1;
	}
	
	//listen侦听 第一个参数是套接字，第二个参数为等待接受的连接的队列的大小，在connect请求过来的时候,完成三次握手后先将连接放到这个队列中，直到被accept处理。如果这个队列满了，且有新的连接的时候，对方可能会收到出错信息。
	if (listen(server_socket, 5) == -1) {
		perror("listen error");
		return 1;
	}
	
	struct sockaddr_in client_address;
	socklen_t address_len;
	int client_socket = accept(server_socket, (struct sockaddr *)&client_address, &address_len);
	//返回的client_socket为一个全相关的socket，其中包含client的地址和端口信息，通过client_socket可以和客户端进行通信。
	if (client_socket == -1) {
		perror("accept error");
		return -1;
	}
	
	char recv_msg[1024];
	char reply_msg[1024];
	
	while (1) {
		bzero(recv_msg, 1024);
		bzero(reply_msg, 1024);
		
		printf("reply:");
		scanf("%s",reply_msg);
		send(client_socket, reply_msg, 1024, 0);
		
		long byte_num = recv(client_socket,recv_msg,1024,0);
		recv_msg[byte_num] = '\0';
		printf("client said:%s\n",recv_msg);
		
	}
	

	
	
	
	
	CSocketServer *server = [[CSocketServer alloc]init];
	[server setupSocket];
	while (1) {
		//[server SendMessage];
	}
	
	@autoreleasepool {
	    // insert code here...
	    NSLog(@"Hello, World!");
	}
    return 0;
}




