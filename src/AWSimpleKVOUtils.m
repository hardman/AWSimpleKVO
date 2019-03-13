//
//  AWSimpleKVOUtils.m
//  AWSimpleKVO
//
//  Created by hongyuwang on 2019/3/13.
//

#import "AWSimpleKVOUtils.h"

@implementation AWSimpleKVOUtils

///根据key获取setter方法名
+(NSString *)setterSelWithKeyPath:(NSString *)keyPath{
    if(keyPath.length == 0){
        return nil;
    }else{
        NSString *uppercase = [[[keyPath substringToIndex:1] uppercaseString] stringByAppendingString:[keyPath substringFromIndex:1]];
        return [NSString stringWithFormat:@"set%@:",uppercase];
    }
}

///根据setterSel获取key
+(NSString *)keyPathWithSetterSel:(NSString *)sel{
    if (sel.length <= 4) {
        return nil;
    }else{
        NSString *uppercase = [sel substringWithRange:NSMakeRange(3, sel.length - 4)];
        return [[[uppercase substringToIndex:1] lowercaseString] stringByAppendingString:[uppercase substringFromIndex:1]];
    }
}

@end
