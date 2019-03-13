/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

@interface AWSimpleKVOUtils : NSObject

///根据key获取setter方法名
+(NSString *)setterSelWithKeyPath:(NSString *)keyPath;
///根据setterSel获取key
+(NSString *)keyPathWithSetterSel:(NSString *)sel;

@end
