/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWSimpleKVOCounter.h"

#import <objc/runtime.h>

///保存计数
@interface AWSimpleKVOCounterItem: NSObject
@property (nonatomic, copy) NSString *className;
@property (nonatomic, unsafe_unretained) NSInteger count;
@end

@implementation AWSimpleKVOCounterItem
@end

///计数类
@interface AWSimpleKVOCounter()
@property (nonatomic, strong) NSMutableDictionary * items;
@end

@implementation AWSimpleKVOCounter

///实例
+(instancetype) sharedInstance{
    static AWSimpleKVOCounter *sCount = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sCount = [[AWSimpleKVOCounter alloc] init];
    });
    return sCount;
}

///保存记录
-(NSMutableDictionary *)items{
    if (!_items) {
        _items = [[NSMutableDictionary alloc] init];
    }
    return _items;
}

///增加计数
-(BOOL) increaceForClassName:(NSString *)name{
    if(![name isKindOfClass:[NSString class]]){
        return NO;
    }
    if (!NSClassFromString(name)) {
        return NO;
    }
    @synchronized(self){
        AWSimpleKVOCounterItem *item = self.items[name];
        if(!item){
            item = [[AWSimpleKVOCounterItem alloc] init];
            item.className = name;
            item.count = 0;
            self.items[name] = item;
        }
        item.count++;
    }
    return YES;
}

///减少计数
-(BOOL) reduceForClassName:(NSString *)name{
    if(![name isKindOfClass:[NSString class]]){
        return NO;
    }
    if (!NSClassFromString(name)) {
        return NO;
    }
    @synchronized(self){
        AWSimpleKVOCounterItem *item = self.items[name];
        NSAssert(item != nil, @"错误");
        if(item.count > 0){
            item.count --;
            if (item.count <= 0) {
                self.items[name] = nil;
            }
            return YES;
        }
        return NO;
    }
}

///获取数量
-(NSInteger) countForClassName:(NSString *)name {
    if(![name isKindOfClass:[NSString class]]){
        return 0;
    }
    if (!NSClassFromString(name)) {
        return 0;
    }
    @synchronized(self) {
        AWSimpleKVOCounterItem *item = self.items[name];
        if (item) {
            return item.count;
        }else{
            return 0;
        }
    }
}

///清空
-(void) clean{
    @synchronized(self) {
        self.items = nil;
    }
}

@end
