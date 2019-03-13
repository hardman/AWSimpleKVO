/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "TestSimpleKVO.h"
#import "NSObject+AWSimpleKVO.h"

#import <objc/runtime.h>

@interface TestSimpleKVO()
@property (nonatomic, unsafe_unretained) int i;
@property (atomic, strong) NSObject *o;
@property (nonatomic, copy) NSString *s;
@property (nonatomic, weak) NSObject *w;
@end

@implementation TestSimpleKVO

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context{
    NSLog(@"");
}

+(void) testSrc{
    TestSimpleKVO *testObj = [[TestSimpleKVO alloc] init];
    
    [testObj addObserver:testObj forKeyPath:@"s" options:NSKeyValueObservingOptionNew context:nil];
    
    testObj.s = @"123";
}

+(void) testCommon{
    TestSimpleKVO *testObj = [[TestSimpleKVO alloc] init];
    ///1. 添加监听
    NSLog(@"--before 添加监听");
    [testObj awAddObserverForKeyPath:@"i" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        NSLog(@"keyPath=%@, changed=%@", keyPath, change);
    }];
    [testObj awAddObserverForKeyPaths:@[@"o", @"s", @"w"] options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        NSLog(@"keyPath=%@, changed=%@", keyPath, change);
    }];
    NSLog(@"--after 添加监听");
    
    testObj.i = 12030;
    testObj.o = [[NSObject alloc]init];
    testObj.s = @"66666";
    
    ///2. setValue:forKey:
    NSLog(@"--before setValue:ForKey");
    [testObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after setValue:ForKey");
    
    ///3. 忽略相同赋值
    NSLog(@"--before awSimpleKVOIgnoreEqualValue to YES");
    testObj.awSimpleKVOIgnoreEqualValue = YES;
    [testObj setValue:@12304 forKey:@"i"];
    [testObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after awSimpleKVOIgnoreEqualValue to YES");
    
    NSLog(@"--before awSimpleKVOIgnoreEqualValue to NO");
    testObj.awSimpleKVOIgnoreEqualValue = NO;
    [testObj setValue:@12304 forKey:@"i"];
    [testObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after awSimpleKVOIgnoreEqualValue to NO");
    
    ///4. 移除监听
    NSLog(@"--before 移除监听");
    [testObj awRemoveObserverForKeyPath:@"o" context:nil];
    testObj.o = [[NSObject alloc] init];
    NSLog(@"--after 移除监听");
}

+(void) testAsync{
    TestSimpleKVO *testObj = [[TestSimpleKVO alloc] init];
    NSArray *arr = @[@"i", @"o", @"s", @"w"];
    int limit = 100;
    dispatch_queue_t queue = dispatch_queue_create("label", DISPATCH_QUEUE_CONCURRENT);
    for (int i = 0; i < limit; i++) {
        dispatch_async(queue, ^{
            [testObj awAddObserverForKeyPath:arr[arc4random() % 4] options:NSKeyValueObservingOptionNew|NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
                NSLog(@"keyPath=%@, changed=%@", keyPath, change);
            }];
        });
    }
    
    dispatch_barrier_async(queue, ^{
        NSLog(@"--------------");
    });
    
    for (int j = 0; j < limit; j++) {
        dispatch_async(queue, ^{
            testObj.i = arc4random();
            testObj.o = [[NSObject alloc]init];
            testObj.s = [NSString stringWithFormat:@"%ld", (long)arc4random()];
        });
    }
}

+(void) testSimpleKVO{
//    [self testCommon];
//    [self testAsync];
    [self testSrc];
}

- (void)dealloc {
    NSLog(@"testObj释放");
}

@end
