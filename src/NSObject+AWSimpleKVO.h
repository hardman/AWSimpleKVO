/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

/*
 限制如下：
 1. options只能使用 NSKeyValueObservingOptionOld和NSKeyValueObservingOptionNew
 2.
 
 */

@class AWSimpleKVO;
@interface NSObject(AWSimpleKVO)
///增加属性监听
-(void)awAddObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block;

///为多个属性添加监听
-(void)awAddObserverForKeyPaths:(NSArray<NSString *> *) keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block;

///移除属性监听
-(void)awRemoveObserverForKeyPath:(NSString *)keyPath context:(void *)context;

///为多个属性移除属性监听
-(void)awRemoveObserverForKeyPaths:(NSArray<NSString *>*)keyPath context:(void *)context;

///是否忽略重复值，默认忽略
@property (nonatomic, unsafe_unretained) BOOL awSimpleKVOIgnoreEqualValue;

@end
