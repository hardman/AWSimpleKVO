/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWSimpleKVOItem.h"

#define AWSIMPLEKVO_DEFAULT_CONTEXT @"AWSIMPLEKVO_DEFAULT_CONTEXT"

@implementation AWSimpleKVOItem

///将id转为context
-(void *)contextFromId:(id)ctx{
    if (ctx) {
        return (__bridge void *)ctx;
    }else{
        return AWSIMPLEKVO_DEFAULT_CONTEXT;
    }
}

///将context转为id
-(id) idWithContext:(void *)context {
    if (context) {
        return (__bridge id)context;
    }else{
        return AWSIMPLEKVO_DEFAULT_CONTEXT;
    }
}

///保存context和block 一一对应
-(BOOL) addContext:(void *)context block:(id)block{
    @synchronized(self) {
        id idCtx = [self idWithContext: context];
        if (self.contextToBlocks == nil) {
            self.contextToBlocks = [[NSMapTable alloc] initWithKeyOptions:NSPointerFunctionsStrongMemory valueOptions:NSPointerFunctionsStrongMemory capacity:1];
        }else if([self.contextToBlocks objectForKey:idCtx]){
            return NO;
        }
        [self.contextToBlocks setObject:block forKey:idCtx];
        return YES;
    }
}

///移除context
-(void) removeContext:(void *)context{
    @synchronized(self) {
        [self.contextToBlocks removeObjectForKey:[self idWithContext: context]];
    }
}

///是否包含context
-(BOOL) containsContext:(void *)context{
    @synchronized(self) {
        return [self.contextToBlocks objectForKey:[self idWithContext: context]] != nil;
    }
}

///获取block
-(id) blockWithContext:(void *)context{
    @synchronized(self) {
        return [self.contextToBlocks objectForKey:[self idWithContext: context]];
    }
}

///包含的context数量
-(NSInteger) contextsCount {
    @synchronized(self) {
        return [self.contextToBlocks count];
    }
}

@end

@interface AWSimpleKVOItemContainer()
@property (nonatomic, strong) NSMutableDictionary *observerDict;
@end

@implementation AWSimpleKVOItemContainer

///构造
- (instancetype)init {
    self = [super init];
    if (self) {
        @synchronized(self) {
            self.observerDict = [[NSMutableDictionary alloc] init];
        }
    }
    return self;
}

///获取item
-(AWSimpleKVOItem *) itemWithKeyPath:(NSString *)keyPath {
    if (![keyPath isKindOfClass:[NSString class]]) {
        return nil;
    }
    @synchronized(self) {
        return self.observerDict[keyPath];
    }
}

///加入item
-(BOOL) addItem:(AWSimpleKVOItem *)item {
    if (![item isKindOfClass:[AWSimpleKVOItem class]]) {
        return NO;
    }
    @synchronized(self) {
        if (self.observerDict[item.keyPath]) {
            return NO;
        }
        
        self.observerDict[item.keyPath] = item;
    }
    
    return YES;
}

///移除item
-(void) removeItemWithKeyPath:(NSString *) keyPath {
    if (![keyPath isKindOfClass:[NSString class]]) {
        return;
    }
    @synchronized(self) {
        self.observerDict[keyPath] = nil;
    }
}

@end
