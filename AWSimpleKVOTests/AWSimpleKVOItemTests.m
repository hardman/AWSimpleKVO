/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <XCTest/XCTest.h>
#import <objc/runtime.h>
#import "AWSimpleKVOItem.h"

@interface AWSimpleKVOItemTests : XCTestCase

@end

@implementation AWSimpleKVOItemTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testItem {
    // This is an example of a functional test case.
    // Use XCTAssert and related functions to verify your tests produce the correct results.
    AWSimpleKVOItem *item = [[AWSimpleKVOItem alloc] init];
    NSObject *ctx = [[NSObject alloc] init];
    BOOL succ = [item addContext:(__bridge void *)ctx block:^{}];
    XCTAssertTrue(succ, @"添加context错误");
    XCTAssertEqual([item contextsCount], 1, @"添加context错误");
    
    succ = [item addContext:(__bridge void *)ctx block:^{}];
    XCTAssertFalse(succ, @"添加context错误");
    
    XCTAssertTrue([item containsContext:(__bridge void *)ctx], @"containsContext 错误");
    
    [item removeContext:((__bridge void *)ctx)];
    XCTAssertEqual([item contextsCount], 0, @"移除context错误");
    XCTAssertTrue(![item containsContext:(__bridge void *)ctx], @"containsContext 错误");
}

- (void)testItemAsync{
    XCTestExpectation *expection = [self expectationWithDescription:@"异步添加item"];
    
    AWSimpleKVOItem *item = [[AWSimpleKVOItem alloc] init];
    NSArray *srcCtxs = @[@"1", @"2", @"3", @"4", @"5"];
    
    //测试添加
    NSMutableArray *ctxs = srcCtxs.mutableCopy;
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
        while (ctxs.count) {
            NSInteger idx = arc4random() % ctxs.count;
            NSString *ctx = ctxs[idx];
            [item addContext:(__bridge void *)(ctx) block:^NSString*{
                return ctx;
            }];
            [ctxs removeObjectAtIndex:idx];
        }
    });
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        for (NSString *ctx in srcCtxs) {
            id block = [item blockWithContext:(__bridge void *)ctx];
            NSString *v = ((NSString *(^)(void))block)();
            XCTAssertEqualObjects(ctx, v, @"异步添加context错误");
        }
        
        [expection fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        XCTAssert(!error, @"不应有错误发生");
    }];
    
    expection = [self expectationWithDescription:@"异步删除item"];
    //测试移除
    NSInteger count = [item contextsCount];
    for (NSInteger i = 0; i < count; i++) {
        dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
            [item removeContext:(__bridge void *)srcCtxs[i]];
        });
    }
    
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        XCTAssertEqual([item contextsCount], 0, @"全部移除后应该为0");
        [expection fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        XCTAssert(!error, @"不应有错误发生");
    }];
}

- (void)testContainer {
    XCTestExpectation *expectation = [self expectationWithDescription:@"container 测试"];
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("test.queue", DISPATCH_QUEUE_CONCURRENT);
    
    AWSimpleKVOItemContainer *container = [[AWSimpleKVOItemContainer alloc] init];
    NSArray *keyPaths = @[@"a", @"b", @"c", @"d", @"e"];
    for (NSString *kp in keyPaths) {
        AWSimpleKVOItem *item = [[AWSimpleKVOItem alloc] init];
        item.keyPath = kp;
        dispatch_group_async(group, queue, ^{
            [container addItem:item];
        });
    }
    
    dispatch_barrier_async(queue, ^{
        for (NSString *kp in keyPaths) {
            XCTAssertEqualObjects(kp, [container itemWithKeyPath:kp].keyPath, @"异步添加应该成功") ;
        }
    });
    
    for (NSString *kp in keyPaths) {
        dispatch_group_async(group, queue, ^{
            [container removeItemWithKeyPath:kp];
        });
    }
    
    dispatch_group_notify(group, queue, ^{
        for (NSString *kp in keyPaths) {
            XCTAssertNil([container itemWithKeyPath:kp], @"应该全部删除成功") ;
        }
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"不该有错误");
    }];
}

@end
