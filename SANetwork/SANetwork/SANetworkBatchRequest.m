//
//  SANetworkBatchRequest.m
//  ECM
//
//  Created by 学宝 on 16/1/18.
//  Copyright © 2016年 浙江网仓科技有限公司. All rights reserved.
//

#import "SANetworkBatchRequest.h"
#import "SANetworkResponseProtocol.h"
#import "SANetworkRequest.h"
#import "SANetworkAgent.h"
#import "SANetworkResponse.h"

@interface SANetworkBatchRequest ()<SANetworkResponseProtocol>

@property (nonatomic) NSInteger completedCount;
@property (nonatomic, strong) NSArray<SANetworkRequest *> *requestArray;
@property (nonatomic, strong) NSMutableArray *accessoryArray;
@property (nonatomic, strong) NSMutableArray<SANetworkResponse *> *responseArray;

@end

@implementation SANetworkBatchRequest{
    BOOL _isHandleDoneWhenNoContinueByFailResponse;
}

- (instancetype)initWithRequestArray:(NSArray<SANetworkRequest *> *)requestArray {
    self = [super init];
    if (self) {
        _requestArray = requestArray;
        _responseArray = [NSMutableArray array];
        _completedCount = 0;
        _isContinueByFailResponse = YES;
        _isHandleDoneWhenNoContinueByFailResponse = NO;
    }
    return self;
}
- (void)startBatchRequest {
    if (self.completedCount > 0 ) {
        NSLog(@"批量请求正在进行，请勿重复启动  !");
        return;
    }
    
    [self accessoryWillStart];
    for (SANetworkRequest *networkRequest in self.requestArray) {
        networkRequest.responseDelegate = self;
        [[SANetworkAgent sharedInstance] addRequest:networkRequest];
    }
    [self accessoryDidStart];
}

- (void)stopBatchRequest {
    _delegate = nil;
    for (SANetworkRequest *networkRequest in self.requestArray) {
        [[SANetworkAgent sharedInstance] removeRequest:networkRequest];
    }
    [self accessoryDidStop];
}



#pragma mark-
#pragma mark-SANetworkResponseProtocol

- (void)networkRequest:(SANetworkRequest *)networkRequest succeedByResponse:(SANetworkResponse *)response{
    if (response.networkStatus == SANetworkResponseDataCacheStatus) {
        return;
    }
    self.completedCount++;
    [self.responseArray addObject:response];
    if (self.completedCount == self.requestArray.count) {
        [self accessoryFinishByStatus:SANetworkAccessoryFinishStatusSuccess];
        [self networkBatchRequestCompleted];
    }
}

- (void)networkRequest:(SANetworkRequest *)networkRequest failedByResponse:(SANetworkResponse *)response {
    if (response.networkStatus == SANetworkResponseDataCacheStatus) {
        return;
    }
    [self.responseArray addObject:response];
    
    if (self.isContinueByFailResponse) {
        self.completedCount++;
        if (self.completedCount == self.requestArray.count) {
            [self accessoryFinishByStatus:SANetworkAccessoryFinishStatusFailure];
            [self networkBatchRequestCompleted];
        }
    }else if(_isHandleDoneWhenNoContinueByFailResponse == NO){
        for (SANetworkRequest *networkRequest in self.requestArray) {
            [networkRequest stopRequest];
        }
        [self accessoryFinishByStatus:SANetworkAccessoryFinishStatusFailure];
        [self networkBatchRequestCompleted];
        _isHandleDoneWhenNoContinueByFailResponse = YES;
    }
}



- (void)networkBatchRequestCompleted{
    [self accessoryDidStop];
    if ([self.delegate respondsToSelector:@selector(networkBatchRequest:completedByResponseArray:)]) {
        [self.delegate networkBatchRequest:self completedByResponseArray:self.responseArray];
    }
    self.completedCount = 0;
}

- (void)dealloc {
    [self stopBatchRequest];
}
#pragma mark-
#pragma mark-Accessory

- (void)addNetworkAccessoryObject:(id<SANetworkAccessoryProtocol>)accessoryDelegate {
    if (!_accessoryArray) {
        _accessoryArray = [NSMutableArray array];
    }
    [self.accessoryArray addObject:accessoryDelegate];
}

- (void)accessoryWillStart {
    for (id<SANetworkAccessoryProtocol>accessory in self.accessoryArray) {
        if ([accessory respondsToSelector:@selector(networkRequestAccessoryWillStart)]) {
            [accessory networkRequestAccessoryWillStart];
        }
    }
}

- (void)accessoryDidStart {
    for (id<SANetworkAccessoryProtocol>accessory in self.accessoryArray) {
        if ([accessory respondsToSelector:@selector(networkRequestAccessoryDidStart)]) {
            [accessory networkRequestAccessoryDidStart];
        }
    }
}

- (void)accessoryDidStop {
    for (id<SANetworkAccessoryProtocol>accessory in self.accessoryArray) {
        if ([accessory respondsToSelector:@selector(networkRequestAccessoryDidStop)]) {
            [accessory networkRequestAccessoryDidStop];
        }
    }
}

- (void)accessoryFinishByStatus:(SANetworkAccessoryFinishStatus)finishStatus {
    for (id<SANetworkAccessoryProtocol>accessory in self.accessoryArray) {
        if ([accessory respondsToSelector:@selector(networkRequestAccessoryByStatus:)]) {
            [accessory networkRequestAccessoryByStatus:finishStatus];
        }
    }
}

@end
