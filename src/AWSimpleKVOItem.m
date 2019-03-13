//
//  AWSimpleKVOItem.m
//  AWSimpleKVO
//
//  Created by hongyuwang on 2019/3/13.
//

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
            self.contextToBlocks = [[NSMutableDictionary alloc] init];
        }else if(self.contextToBlocks[idCtx]){
            return NO;
        }
        self.contextToBlocks[idCtx] = block;
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
        return self.contextToBlocks[[self idWithContext: context]] != nil;
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
    @synchronized(self) {
        return self.observerDict[keyPath];
    }
}

///加入item
-(BOOL) addItem:(AWSimpleKVOItem *)item {
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
    @synchronized(self) {
        self.observerDict[keyPath] = nil;
    }
}

@end
