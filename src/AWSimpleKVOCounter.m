/*
 copyright 2018 wanghongyu.
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
-(void) increaceForClassName:(NSString *)name{
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
}

///减少计数
-(void) reduceForClassName:(NSString *)name{
    @synchronized(self){
        AWSimpleKVOCounterItem *item = self.items[name];
        NSAssert(item != nil, @"错误");
        item.count --;
        if (item.count <= 0) {
            self.items[name] = nil;
        }
    }
}

///获取数量
-(NSInteger) countForClassName:(NSString *)name {
    @synchronized(self) {
        AWSimpleKVOCounterItem *item = self.items[name];
        if (item) {
            return item.count;
        }else{
            return 0;
        }
    }
}

@end