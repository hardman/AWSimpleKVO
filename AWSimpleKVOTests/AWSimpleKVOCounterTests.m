/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <XCTest/XCTest.h>

#import "AWSimpleKVOCounter.h"

@interface AWSimpleKVOCounterTests : XCTestCase

@end

@implementation AWSimpleKVOCounterTests

- (void)testIncrease {
    AWSimpleKVOCounter *counter = [AWSimpleKVOCounter sharedInstance];
    [counter clean];
    XCTAssertEqual(counter, [AWSimpleKVOCounter sharedInstance], @"单例测试");
    XCTAssertTrue(![counter increaceForClassName:(NSString *)@123], @"参数类型错误");
    XCTAssertTrue(![counter increaceForClassName:@"123"], @"不存在的类名");
    
    int limit = 10;
    
    NSArray *names = @[@"NSObject", @"NSArray", @"AWSimpleKVOUtils", @"AWSimpleKVO"];
    
    for (NSString *n in names) {
        for (int i = 0; i < limit; i++) {
            BOOL succ = [counter increaceForClassName:n];
            XCTAssertTrue(succ, @"increase错误");
        }
        
        XCTAssertEqual([counter countForClassName:@"NSObject"], limit, @"increase 错误");
    }
}

-(void)testReduce{
    AWSimpleKVOCounter *counter = [AWSimpleKVOCounter sharedInstance];
    [counter clean];
    
    int limit = 10;
    
    NSArray *names = @[@"NSObject", @"NSArray", @"AWSimpleKVOUtils", @"AWSimpleKVO"];
    
    for (NSString *n in names) {
        for (int i = 0; i < limit; i++) {
            [counter increaceForClassName:n];
        }
        
        XCTAssertEqual([counter countForClassName:n], limit, @"increase error for reduce test");
    }
    
    for (NSString *n in names) {
        while ([counter countForClassName:n] > 0) {
            NSInteger beforeReduce = [counter countForClassName:n];
            BOOL succ = [counter reduceForClassName:n];
            XCTAssertTrue(succ, @"reduce failed");
            XCTAssertEqual([counter countForClassName:n], beforeReduce - 1, @"reduce后数量错误");
        }
        
        XCTAssertEqual([counter countForClassName:n], 0, @"reduce完成后总量错误");
    }
    
    [counter clean];
}

-(void)testAsyncIncrease{
    AWSimpleKVOCounter *counter = [AWSimpleKVOCounter sharedInstance];
    [counter clean];
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步添加类"];
    int limit = 10;
    NSArray *names = @[@"NSObject", @"NSArray", @"AWSimpleKVOUtils", @"AWSimpleKVO"];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    for (NSString *n in names) {
        for (int i = 0; i < limit; i++) {
            dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
                [counter increaceForClassName:n];
            });
        }
    }
    dispatch_group_leave(group);
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        for (NSString *n in names) {
            XCTAssertEqual([counter countForClassName:n], limit, @"异步increase错误") ;
        }
        
        [counter clean];
    }];
}

-(void) testAsyncReduce{
    AWSimpleKVOCounter *counter = [AWSimpleKVOCounter sharedInstance];
    [counter clean];
    
    int limit = 10;
    
    NSArray *names = @[@"NSObject", @"NSArray", @"AWSimpleKVOUtils", @"AWSimpleKVO"];
    
    for (NSString *n in names) {
        for (int i = 0; i < limit; i++) {
            BOOL succ = [counter increaceForClassName:n];
            XCTAssertTrue(succ, @"increase错误");
        }
        
        XCTAssertEqual([counter countForClassName:@"NSObject"], limit, @"increase 错误");
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"异步删除"];
    dispatch_group_t group = dispatch_group_create();
    dispatch_group_enter(group);
    for (NSString *n in names) {
        for (int i = 0; i < limit; i++) {
            dispatch_group_async(group, dispatch_get_global_queue(0, 0), ^{
                [counter reduceForClassName:n];
            });
        }
    }
    dispatch_group_leave(group);
    dispatch_group_notify(group, dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        for (NSString *n in names) {
            XCTAssertEqual([counter countForClassName:n], 0, @"异步删除错误");
        }
    }];
}

@end
