//
//  AWSimpleKVOUtils.h
//  AWSimpleKVO
//
//  Created by hongyuwang on 2019/3/13.
//

#import <Foundation/Foundation.h>

@interface AWSimpleKVOUtils : NSObject

///根据key获取setter方法名
+(NSString *)setterSelWithKeyPath:(NSString *)keyPath;
///根据setterSel获取key
+(NSString *)keyPathWithSetterSel:(NSString *)sel;

@end
