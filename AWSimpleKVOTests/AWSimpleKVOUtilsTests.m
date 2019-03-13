/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <XCTest/XCTest.h>

#import "AWSimpleKVOUtils.h"

@interface AWSimpleKVOUtilsTests : XCTestCase

@end

@implementation AWSimpleKVOUtilsTests

- (void)setUp {
    // Put setup code here. This method is called before the invocation of each test method in the class.
}

- (void)tearDown {
    // Put teardown code here. This method is called after the invocation of each test method in the class.
}

- (void)testSetterSelWithKeyPath {
    XCTAssert([AWSimpleKVOUtils setterSelWithKeyPath:nil] == nil, @"传nil返回nil");
    XCTAssert([AWSimpleKVOUtils setterSelWithKeyPath:(NSString *)@123] == nil, @"传非字符串返回空");
    XCTAssert([AWSimpleKVOUtils setterSelWithKeyPath:@""] == nil, @"传空字符串返回空");
    XCTAssert([AWSimpleKVOUtils setterSelWithKeyPath:@"@@"] == nil, @"传非法字符串返回空");
    XCTAssert([AWSimpleKVOUtils setterSelWithKeyPath:@"_adfs"] == nil, @"传非ascii字符开头返回空");
    XCTAssert([AWSimpleKVOUtils setterSelWithKeyPath:@"1_adfs"] == nil, @"传数字开头返回空");
    XCTAssert([[AWSimpleKVOUtils setterSelWithKeyPath:@"adfs124f"] isEqualToString:@"setAdfs124f:"], @"adfs124f=setAdfs124f:");
    XCTAssert([[AWSimpleKVOUtils setterSelWithKeyPath:@"adfs_124f"] isEqualToString:@"setAdfs_124f:"], @"adfs_124f=setAdfs_124f:");
}

-(void)testKeyPathWithSetterSel{
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:nil] == nil, @"传nil返回nil");
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:(NSString *)@123] == nil, @"传非字符串返回空");
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:@""] == nil, @"传空字符串返回空");
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:@"@@"] == nil, @"传非法字符串返回空");
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:@"xsetxx:"] == nil, @"传非setXX:形式的参数返回空");
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:@"setxx:"] == nil, @"传第四位不是大写字母的参数返回空");
    XCTAssert([AWSimpleKVOUtils keyPathWithSetterSel:@"setAalfksj:_124:"] == nil, @"传入参数包含多个:");
    XCTAssert([[AWSimpleKVOUtils keyPathWithSetterSel:@"setAalfksj_124:"] isEqualToString:@"aalfksj_124"], @"setAalfksj_124:=aalfksj_124");
}

@end
