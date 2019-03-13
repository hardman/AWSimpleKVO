/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <XCTest/XCTest.h>

#import <objc/runtime.h>

#import "NSObject+AWSimpleKVO.h"

#import "AWSimpleKVOCounter.h"

#define WEAKSELF \
__weak typeof(self) weakSelf = self

@interface AWSimpleKVOTestsDeallocObj : NSObject
@property (nonatomic, unsafe_unretained) NSInteger i;
@end

@implementation AWSimpleKVOTestsDeallocObj
@end

@interface AWSimpleKVOTests : XCTestCase
@property (nonatomic, unsafe_unretained) NSInteger i;
@property (nonatomic, copy) NSString *s;
@property (nonatomic, strong) NSObject *o;
@property (nonatomic, weak) NSObject *w;
@end

@implementation AWSimpleKVOTests

- (void)testAddObserver {
    //参数检查
    BOOL succ = [self awAddObserverForKeyPath:@"1" options:NSKeyValueObservingOptionNew context:NULL block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {}];
    XCTAssertFalse(succ, @"参数错误");
    succ = [self awAddObserverForKeyPath:@"abc" options:NSKeyValueObservingOptionNew context:NULL block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {}];
    XCTAssertFalse(succ, @"参数错误");
    succ = [self awAddObserverForKeyPath:(NSString *)@1 options:NSKeyValueObservingOptionNew context:NULL block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {}];
    XCTAssertFalse(succ, @"参数错误");
    succ = [self awAddObserverForKeyPath:@"i" options:0 context:NULL block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {}];
    XCTAssertFalse(succ, @"参数错误");
    succ = [self awAddObserverForKeyPath:@"i" options:NSKeyValueObservingOptionNew context:NULL block:nil];
    XCTAssertFalse(succ, @"参数错误");
    
    WEAKSELF;
    
    //测试i
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"测试i"];
        NSInteger valueI = 1023;
        NSString *okeyPath = @"i";
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"1" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"1", @"应该相等");
        }];
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"2" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"2", @"应该相等");
            [expectation fulfill];
        }];
        
        self.i = valueI;
        
        [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
            XCTAssertTrue(!error, @"没有错误");
        }];
    }
    
    //测试s
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"测试s"];
        NSString *valueS = @"1023";
        NSString *okeyPath = @"s";
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"1" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqualObjects(valueS, change[@"new"], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"1", @"应该相等");
        }];
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"2" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqualObjects(valueS, change[@"new"], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"2", @"应该相等");
            [expectation fulfill];
        }];
        
        self.s = valueS;
        
        [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
            XCTAssertTrue(!error, @"没有错误");
        }];
    }
    
    //测试o
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"测试o"];
        NSObject *valueO = [[NSObject alloc] init];
        NSString *okeyPath = @"o";
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"1" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqualObjects(valueO, change[@"new"], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"1", @"应该相等");
        }];
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"2" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqualObjects(valueO, change[@"new"], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"2", @"应该相等");
            [expectation fulfill];
        }];
        
        self.o = valueO;
        
        [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
            XCTAssertTrue(!error, @"没有错误");
        }];
    }
    
    //测试w
    {
        XCTestExpectation *expectation = [self expectationWithDescription:@"测试o"];
        NSObject *valueW = [[NSObject alloc] init];
        NSString *okeyPath = @"w";
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"1" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqualObjects(valueW, change[@"new"], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"1", @"应该相等");
        }];
        
        [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:@"2" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqualObjects(valueW, change[@"new"], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, @"2", @"应该相等");
            [expectation fulfill];
        }];
        
        self.w = valueW;
        
        [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
            XCTAssertTrue(!error, @"没有错误");
        }];
    }
}

-(void) testAddObserverAsync{
    XCTestExpectation *expectation = [self expectationWithDescription:@"测试异步添加i"];
    NSInteger valueI = 1023;
    NSString *okeyPath = @"i";
    
    NSInteger limit = 10;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("test.addobserver.async", DISPATCH_QUEUE_CONCURRENT);
    
    __block NSInteger count = 0;
    
    WEAKSELF;
    
    for (NSInteger i = 0; i < limit; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", i];
        dispatch_group_async(group, queue, ^{
            BOOL succ = [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)ctx block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
                XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
                XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
                XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
                XCTAssertEqualObjects((__bridge id)context, ctx, @"应该相等");
                @synchronized (weakSelf) {
                    count++;
                }
            }];
            XCTAssertTrue(succ, @"应该为true");
        });
    }
    
    dispatch_barrier_async(queue, ^{
        self.i = valueI;
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(count, limit, @"应该相等");
        XCTAssertTrue(!error, @"没有错误");
    }];
}

-(void) testRemoveObserver{
    NSInteger valueI = 1023;
    NSString *okeyPath = @"i";
    
    NSInteger limit = 10;
    
    __block NSInteger count = 0;
    
    __block NSMutableArray *leftArray = @[].mutableCopy;
    
    WEAKSELF;
    
    for (NSInteger i = 0; i < limit; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", i];
        BOOL succ = [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)ctx block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
            XCTAssertEqualObjects((__bridge id)context, ctx, @"应该相等");
            @synchronized (weakSelf) {
                [leftArray addObject:ctx];
                count++;
            }
        }];
        XCTAssertTrue(succ, @"应该为true");
    }
    
    NSInteger removeCount = 5;
    
    NSInteger removeArr[] = {1,3,4,6,8};
    for (NSInteger i = 0; i < removeCount; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", removeArr[i]];
        [self awRemoveObserverForKeyPath:okeyPath context:(__bridge void *)ctx];
    }
    
    self.i = valueI;
    
    XCTAssertEqual(count, limit - removeCount, @"应该相等");
    NSArray *shouldLeft = @[@"0", @"2", @"5", @"7", @"9"];
    NSArray *sortedLeftArray = [leftArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
        return [obj1 integerValue] > [obj2 integerValue];
    }];
    XCTAssertEqualObjects(sortedLeftArray, shouldLeft, @"应该相等");
}

-(void) testRemoveObserverAsync{
    XCTestExpectation *expectation = [self expectationWithDescription:@"测试异步删除i"];
    NSInteger valueI = 1023;
    NSString *okeyPath = @"i";
    
    NSInteger limit = 10;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("test.removeobserver.async", DISPATCH_QUEUE_CONCURRENT);
    
    __block NSInteger count = 0;
    
    __block NSMutableArray *leftArray = @[].mutableCopy;
    
    WEAKSELF;
    
    for (NSInteger i = 0; i < limit; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", i];
        dispatch_group_async(group, queue, ^{
            BOOL succ = [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew context:(__bridge void *)ctx block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
                XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
                XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
                XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
                XCTAssertEqualObjects((__bridge id)context, ctx, @"应该相等");
                @synchronized (weakSelf) {
                    [leftArray addObject:ctx];
                    count++;
                }
            }];
            XCTAssertTrue(succ, @"应该为true");
        });
    }
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"---添加完成后再删除");
    });
    
    NSInteger removeCount = 5;
    
    NSInteger removeArr[] = {1,3,4,6,8};
    for (NSInteger i = 0; i < removeCount; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", removeArr[i]];
        dispatch_group_async(group, queue, ^{
            [self awRemoveObserverForKeyPath:okeyPath context:(__bridge void *)ctx];
        });
    }
    
    dispatch_barrier_async(queue, ^{
        self.i = valueI;
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(count, limit - removeCount, @"应该相等");
        NSArray *shouldLeft = @[@"0", @"2", @"5", @"7", @"9"];
        NSArray *sortedLeftArray = [leftArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 integerValue] > [obj2 integerValue];
        }];
        XCTAssertEqualObjects(sortedLeftArray, shouldLeft, @"应该相等");
        XCTAssertTrue(!error, @"没有错误");
    }];
}

-(void)testMutipleAddRemoveKeyPaths{
    XCTestExpectation *expectation = [self expectationWithDescription:@"测试批量添加删除"];
    NSInteger valueI = 1023;
    NSString *valueS = @"1024";
    NSString *okeyPathi = @"i";
    NSString *okeyPaths = @"s";
    
    NSInteger limit = 10;
    
    NSInteger keypathCounts = 2;
    
    dispatch_group_t group = dispatch_group_create();
    dispatch_queue_t queue = dispatch_queue_create("test.removeobserver.async", DISPATCH_QUEUE_CONCURRENT);
    
    __block NSInteger count = 0;
    
    __block NSMutableArray *leftArray = @[].mutableCopy;
    
    WEAKSELF;
    
    for (NSInteger i = 0; i < limit; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", i];
        dispatch_group_async(group, queue, ^{
            NSArray *retArr = [self awAddObserverForKeyPaths:@[okeyPathi, okeyPaths] options:NSKeyValueObservingOptionNew context:(__bridge void *)ctx block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
                XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
                if ([keyPath isEqualToString:okeyPathi]) {
                    XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
                }else if([keyPath isEqualToString:okeyPaths]){
                    XCTAssertEqual(valueS, change[@"new"], @"应该相等");
                }else{
                    XCTAssertTrue(NO, @"keypath错误");
                }
                XCTAssertEqualObjects((__bridge id)context, ctx, @"应该相等");
                @synchronized (weakSelf) {
                    [leftArray addObject:ctx];
                    count++;
                }
            }];
            XCTAssertEqual(retArr.count, 2, @"应该返回2个值");
        });
    }
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"---添加完成后再删除");
    });
    
    NSInteger removeCount = 5;
    
    NSInteger removeArr[] = {1,3,4,6,8};
    for (NSInteger i = 0; i < removeCount; i++) {
        NSString *ctx = [NSString stringWithFormat:@"%ld", removeArr[i]];
        dispatch_group_async(group, queue, ^{
            [self awRemoveObserverForKeyPaths:@[okeyPathi, okeyPaths] context:(__bridge void *)ctx];
        });
    }
    
    dispatch_barrier_async(queue, ^{
        self.i = valueI;
        self.s = valueS;
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertEqual(count, (limit - removeCount) * keypathCounts, @"应该相等");
        NSArray *shouldLeft = @[@"0", @"0", @"2", @"2", @"5", @"5", @"7", @"7", @"9", @"9"];
        NSArray *sortedLeftArray = [leftArray sortedArrayUsingComparator:^NSComparisonResult(id  _Nonnull obj1, id  _Nonnull obj2) {
            return [obj1 integerValue] > [obj2 integerValue];
        }];
        XCTAssertEqualObjects(sortedLeftArray, shouldLeft, @"应该相等");
        XCTAssertTrue(!error, @"没有错误");
    }];
}

-(void) testOldValue{
    XCTestExpectation *expectation = [self expectationWithDescription:@"测试OldValue"];
    NSInteger oldValueI = 1023;
    NSInteger newValueI = 1024;
    NSString *okeyPath = @"i";
    
    self.i = oldValueI;
    
    WEAKSELF;
    
    [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"1" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
        XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
        XCTAssertEqual(oldValueI, [change[@"old"] integerValue], @"应该相等");
        XCTAssertEqual(newValueI, [change[@"new"] integerValue], @"应该相等");
        XCTAssertEqualObjects((__bridge id)context, @"1", @"应该相等");
    }];
    
    [self awAddObserverForKeyPath:okeyPath options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:@"2" block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        XCTAssertEqualObjects(observer, weakSelf, @"应该相等");
        XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
        XCTAssertEqual(oldValueI, [change[@"old"] integerValue], @"应该相等");
        XCTAssertEqual(newValueI, [change[@"new"] integerValue], @"应该相等");
        XCTAssertEqualObjects((__bridge id)context, @"2", @"应该相等");
        [expectation fulfill];
    }];
    
    self.i = newValueI;
    
    [self waitForExpectationsWithTimeout:1 handler:^(NSError * _Nullable error) {
        XCTAssertTrue(!error, @"没有错误");
    }];
}

-(void) testClassAndDealloc{
    NSInteger valueI = 1023;
    NSString *okeyPath = @"i";
    NSString * AWSIMPLEKVOPREFIX = @"AWSimpleKVO_";
    AWSimpleKVOCounter *counter = [AWSimpleKVOCounter sharedInstance];
    NSString *newClsStr = nil;
    
    @autoreleasepool {
        AWSimpleKVOTestsDeallocObj *deallocObj = [[AWSimpleKVOTestsDeallocObj alloc] init];
        
        Class srcCls = [deallocObj class];
        NSString *srcClsStr = NSStringFromClass(srcCls);
        XCTAssertEqualObjects(srcClsStr, @"AWSimpleKVOTestsDeallocObj", @"应该相等");
        
        __weak AWSimpleKVOTestsDeallocObj *weakDeallocObj = deallocObj;
        
        [deallocObj awAddObserverForKeyPath:@"i" options:NSKeyValueObservingOptionNew context:NULL block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
            XCTAssertEqualObjects(observer, weakDeallocObj, @"应该相等");
            XCTAssertEqualObjects(keyPath, okeyPath, @"应该相等");
            XCTAssertEqual(valueI, [change[@"new"] integerValue], @"应该相等");
        }];
        
        deallocObj.i = valueI;
        
        //class
        XCTAssertEqualObjects([deallocObj class], srcCls, @"应该相等");
        
        //new class
        Class newCls = object_getClass(deallocObj);
        newClsStr = NSStringFromClass(newCls);
        XCTAssertEqualObjects(newClsStr, [AWSIMPLEKVOPREFIX stringByAppendingString:srcClsStr], @"应该相等");
        XCTAssertEqualObjects(class_getSuperclass(newCls), srcCls, @"应该相等");
        
        XCTAssertEqual([counter countForClassName:newClsStr], 1, @"引用数量为1");
        
        deallocObj = nil;
    }
    
    XCTestExpectation *expectation = [self expectationWithDescription:@"等待dealloc完成"];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [expectation fulfill];
    });
    
    [self waitForExpectationsWithTimeout:3 handler:^(NSError * _Nullable error) {
        XCTAssertNil(error, @"不该有错误");
        XCTAssertEqual([counter countForClassName:newClsStr], 0, @"引用数量为0");
    }];
}

@end
