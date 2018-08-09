/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */


#import "AWSimpleKVO.h"

#import <objc/runtime.h>
#import <objc/message.h>

#import <UIKit/UIKit.h>

#import "NSObject+AWSimpleKVO.h"

#import "AWSimpleKVOCounter.h"

#pragma mark - 私有方法

@interface NSObject(AWSimpleKVOPrivate)
-(AWSimpleKVO *)awSimpleKVO;
@end

#pragma mark - common methods

///根据key获取setter方法名
static NSString *_getSetterSelWithKeyPath(NSString *keyPath){
    if(keyPath.length == 0){
        return nil;
    }else{
        NSString *uppercase = [[[keyPath substringToIndex:1] uppercaseString] stringByAppendingString:[keyPath substringFromIndex:1]];
        return [NSString stringWithFormat:@"set%@:",uppercase];
    }
}

///根据setterSel获取key
static NSString *_getKeyPathWithSetterSel(NSString *sel){
    if (sel.length <= 4) {
        return nil;
    }else{
        NSString *uppercase = [sel substringWithRange:NSMakeRange(3, sel.length - 4)];
        return [[[uppercase substringToIndex:1] lowercaseString] stringByAppendingString:[uppercase substringFromIndex:1]];
    }
}

///根据typeEncode获取结构体名字
static NSString *_getStructTypeWithTypeEncode(NSString *typeEncode){
    if (typeEncode.length < 3) {
        return nil;
    }
    NSRange locate = [typeEncode rangeOfString:@"="];
    if (locate.length == 0) {
        return nil;
    }
    return [typeEncode substringWithRange: NSMakeRange(1, locate.location - 1)];
}

///固定前缀
#define AWSIMPLEKVOPREFIX @"AWSimpleKVO_"

#pragma mark - supported types

///支持的key类型
typedef enum : NSUInteger {
    AWSimpleKVOSupportedIvarTypeUnSupport,
    
    AWSimpleKVOSupportedIvarTypeChar,
    AWSimpleKVOSupportedIvarTypeInt,
    AWSimpleKVOSupportedIvarTypeShort,
    AWSimpleKVOSupportedIvarTypeLong,
    AWSimpleKVOSupportedIvarTypeLongLong,
    AWSimpleKVOSupportedIvarTypeUChar,
    AWSimpleKVOSupportedIvarTypeUInt,
    AWSimpleKVOSupportedIvarTypeUShort,
    AWSimpleKVOSupportedIvarTypeULong,
    AWSimpleKVOSupportedIvarTypeULongLong,
    AWSimpleKVOSupportedIvarTypeFloat,
    AWSimpleKVOSupportedIvarTypeDouble,
    AWSimpleKVOSupportedIvarTypeBool,
    
    AWSimpleKVOSupportedIvarTypeObject,
    
    AWSimpleKVOSupportedIvarTypeCGSize,
    AWSimpleKVOSupportedIvarTypeCGPoint,
    AWSimpleKVOSupportedIvarTypeCGRect,
    AWSimpleKVOSupportedIvarTypeCGVector,
    AWSimpleKVOSupportedIvarTypeCGAffineTransform,
    AWSimpleKVOSupportedIvarTypeUIEdgeInsets,
    AWSimpleKVOSupportedIvarTypeUIOffset,
} AWSimpleKVOSupportedIvarType;

#pragma mark - KVOItem

@interface AWSimpleKVOItem: NSObject
///监听的key
@property (nonatomic, copy) NSString *keyPath;
///context用于区分监听者，可实现多处监听同一个对象的同一个key
@property (nonatomic, strong) NSMutableDictionary *contextToBlocks;

///保存的旧值
@property (nonatomic, strong) id oldValue;

///key的类型
@property (nonatomic, unsafe_unretained) AWSimpleKVOSupportedIvarType ivarType;
///key的typeCoding
@property (nonatomic, copy) NSString *ivarTypeCode;

//监听选项
@property (nonatomic, unsafe_unretained) NSKeyValueObservingOptions options;

#pragma inner properties

///当前key对应的addMethod添加的方法
@property (nonatomic, unsafe_unretained) IMP _childMethod;
///当前key对应的源类中的方法
@property (nonatomic, unsafe_unretained) IMP _superMethod;
///当前key对应的setter selector
@property (nonatomic, unsafe_unretained) SEL _setSel;
///childMethod的typeCoding
@property (nonatomic, copy) NSString *_childMethodTypeCoding;

#pragma inner property属性
//是否有copy属性
@property (nonatomic, unsafe_unretained) BOOL isCopy;
//是否有nonatomic属性
@property (nonatomic, unsafe_unretained) BOOL isNonAtomic;
@end

#define AWSIMPLEKVO_DEFAULT_CONTEXT @"AWSIMPLEKVO_DEFAULT_CONTEXT"

@implementation AWSimpleKVOItem

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

///items 容器
@interface AWSimpleKVOItemContainer: NSObject
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

#pragma mark - KVO declaration

@interface AWSimpleKVO()
///监听的真实对象
@property (nonatomic, weak) NSObject *obj;
///保存所有监听数据
@property (nonatomic, strong) AWSimpleKVOItemContainer *itemContainer;
///新类的类名
@property (nonatomic, copy) NSString *simpleKVOChildClassName;
///新的类
@property (nonatomic, weak) Class simpleKVOChildClass;
///源类
@property (nonatomic, weak) Class simpleKVOSuperClass;

///是否已计数
@property (atomic, unsafe_unretained) BOOL isCounted;
@end

#pragma mark - child methods 用于替换源类中的方法

///根据sel获取kvoItem
static AWSimpleKVOItem * _childSetterKVOItem(id obj, SEL sel) {
    NSString *str = NSStringFromSelector(sel);
    NSString *keyPath = _getKeyPathWithSetterSel(str);
    AWSimpleKVO *simpleKVO = [obj awSimpleKVO];
    return [simpleKVO.itemContainer itemWithKeyPath: keyPath];
}

///当值已经改变，触发block通知
static void _childSetterNotify(AWSimpleKVOItem *item, id obj, NSString *keyPath, id valueNew){
    if (item) {
        NSMutableDictionary *change = [[NSMutableDictionary alloc] init];
        if (item.options & NSKeyValueObservingOptionOld) {
            change[@"old"] = item.oldValue;
        }
        if (item.options & NSKeyValueObservingOptionNew) {
            change[@"new"] = valueNew;
        }
        if (!item.isNonAtomic) {
            @synchronized(item) {
                item.oldValue = valueNew;
            }
        }else{
            item.oldValue = valueNew;
        }
        
        NSDictionary *ctxToBlks = nil;
        @synchronized(item) {
            ctxToBlks = item.contextToBlocks.copy;
        }
        for (id ctx in ctxToBlks.allKeys) {
            id block = ctxToBlks[ctx];
            if (block) {
                ((void (^)(NSObject *, NSString *, NSDictionary *, void *))block)(obj, keyPath, change, (__bridge void *)ctx);
            }
        }
    }
}

///当key类型为对象(id)时，key的setter方法会指向此方法。
static void _childSetterObj(id obj, SEL sel, id v) {
    AWSimpleKVOItem *item = _childSetterKVOItem(obj, sel);
    if([obj awSimpleKVOIgnoreEqualValue] && item.oldValue == v ) {
        return;
    }
    
    id value = v;
    if (item.isCopy) {
        value = [value copy];
    }
    
    if (!item.isNonAtomic) {
        @synchronized(item) {
            ((void (*)(id, SEL, id))item._superMethod)(obj, sel, value);
        }
    }else{
        ((void (*)(id, SEL, id))item._superMethod)(obj, sel, value);
    }
    
    _childSetterNotify(item, obj, item.keyPath, value);
}

///为数值key定义通用宏，结构同_childSetterObj只是类型不同。
#define CHILD_SETTER_NUMBER(type, TypeSet, typeGet) \
static void _childSetter##TypeSet(id obj, SEL sel, type v){ \
    AWSimpleKVOItem *item = _childSetterKVOItem(obj, sel); \
    if([obj awSimpleKVOIgnoreEqualValue] && [item.oldValue typeGet##Value] == v) { \
        return; \
    } \
    if(!item.isNonAtomic) { \
        @synchronized(item) { \
            ((void (*)(id, SEL, type))item._superMethod)(obj, sel, v); \
        } \
    }else{ \
        ((void (*)(id, SEL, type))item._superMethod)(obj, sel, v); \
    } \
    _childSetterNotify(item, obj, item.keyPath, [NSNumber numberWith##TypeSet:v]); \
}

CHILD_SETTER_NUMBER(char, Char, char)
CHILD_SETTER_NUMBER(int, Int, int)
CHILD_SETTER_NUMBER(short, Short, short)
CHILD_SETTER_NUMBER(long, Long, long)
CHILD_SETTER_NUMBER(long long, LongLong, longLong)
CHILD_SETTER_NUMBER(unsigned char, UnsignedChar, unsignedChar)
CHILD_SETTER_NUMBER(unsigned int, UnsignedInt, unsignedInt)
CHILD_SETTER_NUMBER(unsigned short, UnsignedShort, unsignedShort)
CHILD_SETTER_NUMBER(unsigned long, UnsignedLong, unsignedLong)
CHILD_SETTER_NUMBER(unsigned long long, UnsignedLongLong, unsignedLongLong)
CHILD_SETTER_NUMBER(float, Float, float)
CHILD_SETTER_NUMBER(double, Double, double)
CHILD_SETTER_NUMBER(bool, Bool, bool)

///为结构体key定义通用宏，结构同_childSetterObj只是类型不同。
#define CHILD_SETTER_STRUCTURE(type, equalMethod) \
static void _childSetter##type(id obj, SEL sel, type v) { \
    AWSimpleKVOItem *item = _childSetterKVOItem(obj, sel); \
    if([obj awSimpleKVOIgnoreEqualValue] && equalMethod([item.oldValue type##Value], v)){ \
        return; \
    } \
    if(!item.isNonAtomic) { \
        @synchronized(item) { \
            ((void (*)(id, SEL, type))item._superMethod)(obj, sel, v); \
        } \
    }else{ \
        ((void (*)(id, SEL, type))item._superMethod)(obj, sel, v); \
    } \
    _childSetterNotify(item, obj, item.keyPath, [NSValue valueWith##type: v]); \
}

CHILD_SETTER_STRUCTURE(CGPoint, CGPointEqualToPoint)
CHILD_SETTER_STRUCTURE(CGSize, CGSizeEqualToSize)
CHILD_SETTER_STRUCTURE(CGRect, CGRectEqualToRect)

static BOOL _CGVectorIsEqualToVector(CGVector vector, CGVector vector1) {
    return vector.dx == vector1.dx && vector.dy == vector1.dy;
}
CHILD_SETTER_STRUCTURE(CGVector, _CGVectorIsEqualToVector)
CHILD_SETTER_STRUCTURE(CGAffineTransform, CGAffineTransformEqualToTransform)
CHILD_SETTER_STRUCTURE(UIEdgeInsets, UIEdgeInsetsEqualToEdgeInsets)
CHILD_SETTER_STRUCTURE(UIOffset, UIOffsetEqualToOffset)

#pragma mark - KVO implementation

@implementation AWSimpleKVO

#pragma mark - 初始化

///初始化
-(instancetype)initWithObj:(NSObject *)obj{
    if (!obj) {
        return nil;
    }
    
    if(self = [super init]) {
        @synchronized(self) {
            self.obj = obj;
            self.itemContainer = [[AWSimpleKVOItemContainer alloc] init];
            NSString *classNewName = NSStringFromClass(obj.class);
            if ([classNewName hasPrefix:AWSIMPLEKVOPREFIX]) {
                self.simpleKVOChildClassName = classNewName;
            }else{
                self.simpleKVOChildClassName = [AWSIMPLEKVOPREFIX stringByAppendingString:classNewName];
            }
        }
    }
    return self;
}

#pragma mark - 相关属性

///是否正在观察
-(BOOL)isObserving{
    return [NSStringFromClass(self.safeThreadGetClass) hasPrefix:AWSIMPLEKVOPREFIX];
}

///安全设置当前class
-(void) safeThreadSetClass:(Class) cls {
    if(cls == self.safeThreadGetClass) {
        return;
    }
    @synchronized(self.obj) {
        object_setClass(self.obj, cls);
    }
}

///安全获取当前class
-(Class) safeThreadGetClass{
    @synchronized(self.obj) {
        return object_getClass(self.obj);
    }
}

///获取新类
-(Class) simpleKVOChildClass{
    if (!_simpleKVOChildClass) {
        @synchronized(self) {
            if (!_simpleKVOChildClass) {
                _simpleKVOChildClass = NSClassFromString(self.simpleKVOChildClassName);
            }
        }
    }
    return _simpleKVOChildClass;
}

///获取源类
-(Class) simpleKVOSuperClass{
    if ([self isObserving]) {
        if (!_simpleKVOSuperClass) {
            @synchronized(self) {
                if (!_simpleKVOSuperClass) {
                    _simpleKVOSuperClass = class_getSuperclass(self.simpleKVOChildClass);
                }
            }
        }
        return _simpleKVOSuperClass;
    }else{
        return self.safeThreadGetClass;
    }
}

#pragma mark - 开始观察

///获取属性的copy和atomic
-(void) _getPropertyInfoForItem:(AWSimpleKVOItem *) item{
    objc_property_t property = class_getProperty(self.simpleKVOSuperClass, item.keyPath.UTF8String);
    if (property == NULL) {
        return;
    }
    unsigned int attrCount;
    objc_property_attribute_t *propertyAttributes = property_copyAttributeList(property, &attrCount);
    for (int i = 0; i < attrCount; i++) {
        objc_property_attribute_t propertyAttr = propertyAttributes[i];
        switch (*propertyAttr.name) {
            case 'N':{
                item.isNonAtomic = YES;
            }
                break;
            case 'C':{
                item.isCopy = YES;
            }
                break;
            default:
                break;
        }
    }
    free(propertyAttributes);
}

///收集传入参数，生成KVOItem
-(AWSimpleKVOItem *)_genKvoItemWithKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    
    ///是否已经存在
    AWSimpleKVOItem *existsItem = [self.itemContainer itemWithKeyPath:keyPath];
    if (existsItem) {
        [existsItem addContext:context block:block];
        return existsItem;
    }
    
    AWSimpleKVOSupportedIvarType ivarType =  AWSimpleKVOSupportedIvarTypeUnSupport;
    ///通过property获取的typeCoding无法在swift中使用，这里获取的是getter方法的typecoding
    ///所以我们如果只有setter方法没有getter方法是无法成功监听的。
    const char * ivTypeCode = method_getTypeEncoding(class_getInstanceMethod([self simpleKVOSuperClass], NSSelectorFromString(keyPath)));
    
    if (!ivTypeCode) {
        //NSAssert(NO, @"不支持的ivar类型");
        return nil;
    }
    
    IMP childMethod = NULL;
    NSString *childMethodTypeCoding = nil;
    
    ///根据keypath的不同类型，对应不同的方法实现
    switch (*ivTypeCode) {
        case 'c':
            ivarType = AWSimpleKVOSupportedIvarTypeChar;
            childMethod = (IMP)_childSetterChar;
            childMethodTypeCoding = @"v@:c";
            break;
        case 'i':
            ivarType = AWSimpleKVOSupportedIvarTypeInt;
            childMethod = (IMP)_childSetterInt;
            childMethodTypeCoding = @"v@:i";
            break;
        case 's':
            ivarType = AWSimpleKVOSupportedIvarTypeShort;
            childMethod = (IMP)_childSetterShort;
            childMethodTypeCoding = @"v@:s";
            break;
        case 'l':
            ivarType = AWSimpleKVOSupportedIvarTypeLong;
            childMethod = (IMP)_childSetterLong;
            childMethodTypeCoding = @"v@:l";
            break;
        case 'q':
            ivarType = AWSimpleKVOSupportedIvarTypeLongLong;
            childMethod = (IMP)_childSetterLongLong;
            childMethodTypeCoding = @"v@:q";
            break;
        case 'C':
            ivarType = AWSimpleKVOSupportedIvarTypeUChar;
            childMethod = (IMP)_childSetterUnsignedChar;
            childMethodTypeCoding = @"v@:C";
            break;
        case 'I':
            ivarType = AWSimpleKVOSupportedIvarTypeUInt;
            childMethod = (IMP)_childSetterUnsignedInt;
            childMethodTypeCoding = @"v@:I";
            break;
        case 'S':
            ivarType = AWSimpleKVOSupportedIvarTypeUShort;
            childMethod = (IMP)_childSetterUnsignedShort;
            childMethodTypeCoding = @"v@:S";
            break;
        case 'L':
            ivarType = AWSimpleKVOSupportedIvarTypeULong;
            childMethod = (IMP)_childSetterUnsignedLong;
            childMethodTypeCoding = @"v@:L";
            break;
        case 'Q':
            ivarType = AWSimpleKVOSupportedIvarTypeULongLong;
            childMethod = (IMP)_childSetterUnsignedLongLong;
            childMethodTypeCoding = @"v@:Q";
            break;
        case 'f':
            ivarType = AWSimpleKVOSupportedIvarTypeFloat;
            childMethod = (IMP)_childSetterFloat;
            childMethodTypeCoding = @"v@:f";
            break;
        case 'd':
            ivarType = AWSimpleKVOSupportedIvarTypeDouble;
            childMethod = (IMP)_childSetterDouble;
            childMethodTypeCoding = @"v@:d";
            break;
        case 'B':
            ivarType = AWSimpleKVOSupportedIvarTypeBool;
            childMethod = (IMP)_childSetterBool;
            childMethodTypeCoding = @"v@:B";
            break;
        case '@':
            ivarType = AWSimpleKVOSupportedIvarTypeObject;
            childMethod = (IMP)_childSetterObj;
            childMethodTypeCoding = @"v@:@";
            break;
        case '{':{
            NSString *typeEncode = [NSString stringWithUTF8String:ivTypeCode];
            NSString *structType = _getStructTypeWithTypeEncode(typeEncode);
            if ([structType isEqualToString: @"CGSize"]) {
                ivarType = AWSimpleKVOSupportedIvarTypeCGSize;
                childMethod = (IMP)_childSetterCGSize;
                childMethodTypeCoding = @"v@:{CGSize=dd}";
            }else if([structType isEqualToString: @"CGPoint" ]) {
                ivarType = AWSimpleKVOSupportedIvarTypeCGPoint;
                childMethod = (IMP)_childSetterCGPoint;
                childMethodTypeCoding = @"v@:{CGPoint=dd}";
            }else if([structType isEqualToString: @"CGRect" ]) {
                ivarType = AWSimpleKVOSupportedIvarTypeCGRect;
                childMethod = (IMP)_childSetterCGRect;
                childMethodTypeCoding = @"v@:{CGRect={CGPoint=dd}{CGSize=dd}}";
            }else if([structType isEqualToString: @"CGVector"]) {
                ivarType = AWSimpleKVOSupportedIvarTypeCGVector;
                childMethod = (IMP)_childSetterCGVector;
                childMethodTypeCoding = @"v@:{CGVector=dd}";
            }else if([structType isEqualToString: @"CGAffineTransform"]) {
                ivarType = AWSimpleKVOSupportedIvarTypeCGAffineTransform;
                childMethod = (IMP)_childSetterCGAffineTransform;
                childMethodTypeCoding = @"v@:{CGAffineTransform=dddddd}";
            }else if([structType isEqualToString: @"UIEdgeInsets"]) {
                ivarType = AWSimpleKVOSupportedIvarTypeUIEdgeInsets;
                childMethod = (IMP)_childSetterUIEdgeInsets;
                childMethodTypeCoding = @"v@:{UIEdgeInsets=dddd}";
            }else if([structType isEqualToString: @"UIOffset"]) {
                ivarType = AWSimpleKVOSupportedIvarTypeUIOffset;
                childMethod = (IMP)_childSetterUIOffset;
                childMethodTypeCoding = @"v@:{UIOffset=dd}";
            }
        }
            break;
        default:
            break;
    }
    
    if (ivarType ==  AWSimpleKVOSupportedIvarTypeUnSupport){
        return nil;
    }
    
    AWSimpleKVOItem *item = [[AWSimpleKVOItem alloc] init];
    [item addContext:context block:block];
    item.keyPath = keyPath;
    item.ivarType = ivarType;
    item.ivarTypeCode = [[NSString stringWithFormat:@"%s", ivTypeCode] substringToIndex: 1];
    item.options = options;
    
    item._childMethod = childMethod;
    item._childMethodTypeCoding = childMethodTypeCoding;
    
    SEL setSel = NSSelectorFromString(_getSetterSelWithKeyPath(keyPath));
    IMP superMethod = class_getMethodImplementation(self.isObserving ? self.simpleKVOSuperClass: self.safeThreadGetClass, setSel);
    item._setSel = setSel;
    item._superMethod = superMethod;
    
    ///检查是否存在copy和nonAtomic属性
    [self _getPropertyInfoForItem: item];
    
    return item;
}

///一旦生成KVOItem，则表示这是一个正确的监听，接下来就要添加新类，并添加方法了。
-(BOOL)_addClassAndMethodForItem:(AWSimpleKVOItem *)item {
    Class childClass = [self addChildObserverClass:self.safeThreadGetClass keyPath:item.keyPath item:item];
    NSAssert(childClass != nil, @"replce method failed");
    if(childClass == nil) {
        return NO;
    }
    
    [self safeThreadSetClass:childClass];
    
    return YES;
}

///添加监听方法
-(BOOL)addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    ///检查参数
    NSAssert(self.obj != nil, @"observer is nil");
    if(!self.obj) {
        return NO;
    }
    
    ///检查参数
    NSAssert([keyPath isKindOfClass:[NSString class]], @"keyPath is invalid");
    if (![keyPath isKindOfClass:[NSString class]]) {
        return NO;
    }
    
    ///检查参数
    NSAssert(block != nil, @"block is invalid");
    if (!block) {
        return NO;
    }
    
    ///检查是否有setter方法
    NSAssert([self.obj respondsToSelector: NSSelectorFromString(_getSetterSelWithKeyPath(keyPath))], @"setter method is need");
    if(![self.obj respondsToSelector: NSSelectorFromString(_getSetterSelWithKeyPath(keyPath))]){
        return NO;
    }
    
    ///生成并保存item
    AWSimpleKVOItem *item = nil;
    
    @synchronized(self){
        item = [self _genKvoItemWithKeyPath:keyPath options:options context:context block:block];
        [self.itemContainer addItem:item];
    }
    
    ///生成
    return [self _addClassAndMethodForItem:item];
}

///开始观察多个keyPaths
-(BOOL)addObserverForKeyPaths:(NSArray<NSString *> *) keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    NSAssert(self.obj != nil, @"observer is nil");
    if (self.obj == nil) {
        return NO;
    }
    NSAssert(block != nil, @"block is invalid");
    if (block == nil) {
        return NO;
    }
    NSMutableArray *items = [[NSMutableArray alloc] init];
    @synchronized(self) {
        for (NSString *keyPath in keyPaths) {
            if ([keyPath isKindOfClass:[NSString class]]) {
                AWSimpleKVOItem *item = [self _genKvoItemWithKeyPath:keyPath options:options context:context block:block];
                if (item) {
                    [self.itemContainer addItem:item];
                    [items addObject:item];
                }
            }
        }
    }
    
    NSInteger failedCount = 0;
    for (AWSimpleKVOItem *item in items) {
        if(![self _addClassAndMethodForItem:item]){
            failedCount++;
        }
    }
    
    return failedCount > 0;
}

///注册新类
-(Class) addChildObserverClass:(Class) c keyPath:(NSString *)keyPath item:(AWSimpleKVOItem *)item {
    Class classNew = self.simpleKVOChildClass;
    if (!classNew) {
        @synchronized(self.class) {
            classNew = self.simpleKVOChildClass;
            if(!classNew) {
                NSString *classNewName = self.simpleKVOChildClassName;
                classNew = objc_allocateClassPair(c, classNewName.UTF8String, 0);
                objc_registerClassPair(classNew);
                self.simpleKVOChildClass = classNew;
                self.simpleKVOSuperClass = c;
            }
        }
    }
    
    BOOL needReplace = YES;
    Method currMethod = class_getInstanceMethod(classNew, item._setSel);
    if (currMethod != NULL) {
        IMP currIMP = method_getImplementation(currMethod);
        needReplace = currIMP != item._childMethod;
    }
    if (needReplace) {
        class_replaceMethod(classNew, item._setSel, item._childMethod, item._childMethodTypeCoding.UTF8String);
    }
    
    if (!self.isCounted) {
        [[AWSimpleKVOCounter sharedInstance] increaceForClassName: self.simpleKVOChildClassName];
        self.isCounted = YES;
    }
    return classNew;
}

#pragma mark - 停止观察
///停止观察属性
-(void) _removeObserverForKeyPath:(NSString *)keyPath context:(void *)context{
    AWSimpleKVOItem *item = [self.itemContainer itemWithKeyPath:keyPath];
    if (item) {
        [item removeContext:context];
        if ([item contextsCount] <= 0) {
            [self.itemContainer removeItemWithKeyPath:keyPath];
            ///恢复method，没有removeMethod方法，可以使用replaceMethod达到相同的目的
            class_replaceMethod(self.simpleKVOChildClass, item._setSel, item._superMethod, item._childMethodTypeCoding.UTF8String);
        }
    }
}

///停止观察keyPath属性
-(void)removeObserverForKeyPath:(NSString *)keyPath context:(void *)context{
    [self _removeObserverForKeyPath:keyPath context: context];
}

///停止观察多个keyPath属性
-(void)removeObserverForKeyPaths:(NSArray<NSString *>*)keyPaths context:(void *)context{
    for(NSString *keyPath in keyPaths){
        [self _removeObserverForKeyPath:keyPath context: context];
    }
}

///移除所有监听
-(void) removeAllObservers {
    __block id tmp = self.itemContainer;
    dispatch_async(dispatch_get_global_queue(0, 0), ^{
        tmp = nil;
    });
}

#pragma mark - 释放
///释放
-(void)dealloc{
    [self removeAllObservers];
    
    __block NSString *className = [_simpleKVOChildClassName copy];
    __block Class childClass = self.simpleKVOChildClass;
    if (childClass) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            AWSimpleKVOCounter *counter = [AWSimpleKVOCounter sharedInstance];
            [counter reduceForClassName: className];
            if ([counter countForClassName:className] <= 0) {
                @synchronized(counter) {
                    if ([counter countForClassName:className] <= 0) {
                        objc_disposeClassPair(childClass);
                    }
                }
            }
        });
    }
}

@end
