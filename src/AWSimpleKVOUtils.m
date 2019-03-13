/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import "AWSimpleKVOUtils.h"

@implementation AWSimpleKVOUtils

///根据key获取setter方法名
+(NSString *)setterSelWithKeyPath:(NSString *)keyPath{
    //类型不对
    if (![keyPath isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    //长度不对
    if(keyPath.length <= 0){
        return nil;
    }
    
    //非字母开头
    if (![[NSCharacterSet letterCharacterSet] characterIsMember:keyPath.UTF8String[0]]) {
        return nil;
    }
    
    //包含非法字符
    NSMutableCharacterSet *charSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [charSet addCharactersInString:@"_"];
    if([keyPath stringByTrimmingCharactersInSet:charSet].length > 0){
        return nil;
    }
    
    NSString *uppercase = [[[keyPath substringToIndex:1] uppercaseString] stringByAppendingString:[keyPath substringFromIndex:1]];
    return [NSString stringWithFormat:@"set%@:",uppercase];
}

///根据setterSel获取key
+(NSString *)keyPathWithSetterSel:(NSString *)sel{
    //类型不对
    if (![sel isKindOfClass:[NSString class]]) {
        return nil;
    }
    
    //长度不对
    if (sel.length <= 4) {
        return nil;
    }
    
    //包含非法字符
    NSMutableCharacterSet *charSet = [[NSCharacterSet alphanumericCharacterSet] mutableCopy];
    [charSet addCharactersInString:@"_:"];
    if([[sel stringByTrimmingCharactersInSet:charSet] length] > 0){
        return nil;
    }
    
    //固定开头
    if (![sel hasPrefix:@"set"]) {
        return nil;
    }
    
    //固定结尾
    if(![sel hasSuffix:@":"]){
        return nil;
    }
    
    //第4位一定是大写字母
    if(![[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:sel.UTF8String[3]]){
        return nil;
    }
    
    //中间部分不包含:
    NSString *selMid = [sel substringWithRange:NSMakeRange(3, sel.length - 4)];
    if([selMid containsString:@":"]){
        return nil;
    }
    
    NSString *uppercase = [sel substringWithRange:NSMakeRange(3, sel.length - 4)];
    return [[[uppercase substringToIndex:1] lowercaseString] stringByAppendingString:[uppercase substringFromIndex:1]];
}

@end
