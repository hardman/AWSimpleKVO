/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

///KVO实现类
@interface AWSimpleKVO : NSObject

///初始化，引入被观察对象
-(instancetype) initWithObj:(NSObject *)obj;

///开始观察keyPath属性
-(BOOL)addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block;

///开始观察多个keyPaths，返回监听成功的keypath
-(NSArray<NSString *> *)addObserverForKeyPaths:(NSArray<NSString *> *) keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block;

///停止观察keyPath属性
-(void)removeObserverForKeyPath:(NSString *)keyPath context:(void *)context;

///停止观察多个keyPath属性
-(void)removeObserverForKeyPaths:(NSArray<NSString *>*)keyPaths context:(void *)context;

@end
