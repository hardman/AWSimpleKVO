/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

@interface AWSimpleKVOCounter: NSObject

///实例
+(instancetype) sharedInstance;

///增加引用计数
-(void) increaceForClassName:(NSString *)name;

///减少引用计数
-(void) reduceForClassName:(NSString *)name;

///获取计数
-(NSInteger) countForClassName:(NSString *)name;
@end
