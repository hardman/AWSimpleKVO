/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "NSObject+AWSimpleKVO.h"
#import <objc/runtime.h>
#import "AWSimpleKVO.h"

static char awSimpleKVOKey = 0;
static char awSimpleKVOIgnoreEqualValueKey = 0;

@implementation NSObject(AWSimpleKVO)

///是否忽略重复值
-(void)setAwSimpleKVOIgnoreEqualValue:(BOOL)awSimpleKVOIgnoreEqualValue{
    objc_setAssociatedObject(self, &awSimpleKVOIgnoreEqualValueKey, @(awSimpleKVOIgnoreEqualValue), OBJC_ASSOCIATION_COPY);
}

-(BOOL)awSimpleKVOIgnoreEqualValue{
    id value = objc_getAssociatedObject(self, &awSimpleKVOIgnoreEqualValueKey);
    if ([value respondsToSelector:@selector(boolValue)]) {
        return [value boolValue];
    }
    return NO;
}

///关联属性
-(void)setAwSimpleKVO:(AWSimpleKVO *)awSimpleKVO{
    objc_setAssociatedObject(self, &awSimpleKVOKey, awSimpleKVO, OBJC_ASSOCIATION_RETAIN);
}

-(AWSimpleKVO *)awSimpleKVO{
    AWSimpleKVO *simpleKVO = objc_getAssociatedObject(self, &awSimpleKVOKey);
    if (!simpleKVO) {
        @synchronized(self) {
            simpleKVO = objc_getAssociatedObject(self, &awSimpleKVOKey);
            if (!simpleKVO) {
                simpleKVO = [[AWSimpleKVO alloc] initWithObj:self];
                self.awSimpleKVO = simpleKVO;
            }
        }
    }
    return simpleKVO;
}

///增加属性监听
-(BOOL)awAddObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    return [self.awSimpleKVO addObserverForKeyPath:keyPath options:options context:context block:block];
}

///为多个属性添加监听
-(NSArray<NSString *> *)awAddObserverForKeyPaths:(NSArray<NSString *> *) keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    return [self.awSimpleKVO addObserverForKeyPaths:keyPaths options:options context:context block:block];
}

///移除属性监听
-(void)awRemoveObserverForKeyPath:(NSString *)keyPath context:(void *)context{
    [self.awSimpleKVO removeObserverForKeyPath:keyPath context:context];
}

///为多个属性移除属性监听
-(void)awRemoveObserverForKeyPaths:(NSArray<NSString *>*)keyPath context:(void *)context{
    [self.awSimpleKVO removeObserverForKeyPaths:keyPath context:context];
}
@end
