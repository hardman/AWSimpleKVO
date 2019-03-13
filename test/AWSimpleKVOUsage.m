/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWSimpleKVOUsage.h"
#import "NSObject+AWSimpleKVO.h"

#import <objc/runtime.h>

@interface AWSimpleKVOUsage()
@property (nonatomic, unsafe_unretained) int i;
@property (atomic, strong) NSObject *o;
@property (nonatomic, copy) NSString *s;
@property (nonatomic, weak) NSObject *w;
@end

@implementation AWSimpleKVOUsage

+(void) usage{
    AWSimpleKVOUsage *usageObj = [[AWSimpleKVOUsage alloc] init];
    ///1. 添加监听
    NSLog(@"--before 添加监听");
    [usageObj awAddObserverForKeyPath:@"i" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        NSLog(@"keyPath=%@, changed=%@", keyPath, change);
    }];
    [usageObj awAddObserverForKeyPaths:@[@"o", @"s", @"w"] options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        NSLog(@"keyPath=%@, changed=%@", keyPath, change);
    }];
    NSLog(@"--after 添加监听");
    
    //2. 赋值触发
    usageObj.i = 12030;
    usageObj.o = [[NSObject alloc]init];
    usageObj.s = @"66666";
    
    ///2. setValue:forKey:
    NSLog(@"--before setValue:ForKey");
    [usageObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after setValue:ForKey");
    
    ///3. 忽略相同赋值
    NSLog(@"--before awSimpleKVOIgnoreEqualValue to YES");
    usageObj.awSimpleKVOIgnoreEqualValue = YES;
    [usageObj setValue:@12304 forKey:@"i"];
    [usageObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after awSimpleKVOIgnoreEqualValue to YES");
    
    NSLog(@"--before awSimpleKVOIgnoreEqualValue to NO");
    usageObj.awSimpleKVOIgnoreEqualValue = NO;
    [usageObj setValue:@12304 forKey:@"i"];
    [usageObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after awSimpleKVOIgnoreEqualValue to NO");
    
    ///4. 移除监听
    NSLog(@"--before 移除监听");
    [usageObj awRemoveObserverForKeyPath:@"o" context:nil];
    usageObj.o = [[NSObject alloc] init];
    NSLog(@"--after 移除监听");
}

- (void)dealloc {
    NSLog(@"usageObj释放");
}

@end
