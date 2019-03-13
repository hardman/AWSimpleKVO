/*
 copyright 2018 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */


#import "AWSimpleKVO.h"

#import <UIKit/UIKit.h>

#import <objc/runtime.h>
#import <objc/message.h>

#import "NSObject+AWSimpleKVO.h"
#import "AWSimpleKVOCounter.h"
#import "AWSimpleKVOItem.h"
#import "AWSimpleKVOUtils.h"

///固定前缀
#define AWSIMPLEKVOPREFIX @"AWSimpleKVO_"

#pragma mark - 私有方法

@interface NSObject(AWSimpleKVOPrivate)
-(AWSimpleKVO *)awSimpleKVO;
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
@property (nonatomic, unsafe_unretained) BOOL isCounted;
@end

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
                self.simpleKVOSuperClass = class_getSuperclass(obj.class);
            }else{
                self.simpleKVOChildClassName = [AWSIMPLEKVOPREFIX stringByAppendingString:classNewName];
                self.simpleKVOSuperClass = obj.class;
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

#pragma mark - 开始观察

///收集传入参数，生成KVOItem
-(AWSimpleKVOItem *)_genKvoItemWithKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    
    ///是否已经存在
    AWSimpleKVOItem *existsItem = [self.itemContainer itemWithKeyPath:keyPath];
    if (existsItem) {
        [existsItem addContext:context block:block];
        return existsItem;
    }
    
    AWSimpleKVOItem *item = [[AWSimpleKVOItem alloc] init];
    [item addContext:context block:block];
    item.keyPath = keyPath;
    item.options = options;
    
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
    NSAssert([self.obj respondsToSelector: NSSelectorFromString([AWSimpleKVOUtils setterSelWithKeyPath:keyPath])], @"setter method is need");
    if(![self.obj respondsToSelector: NSSelectorFromString([AWSimpleKVOUtils setterSelWithKeyPath:keyPath])]){
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
-(NSArray<NSString *> *)addObserverForKeyPaths:(NSArray<NSString *> *) keyPaths options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    NSAssert(self.obj != nil, @"observer is nil");
    if (self.obj == nil) {
        return nil;
    }
    NSAssert(block != nil, @"block is invalid");
    if (block == nil) {
        return nil;
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
    
    NSMutableArray *succArray = [[NSMutableArray alloc] init];
    for (AWSimpleKVOItem *item in items) {
        if([self _addClassAndMethodForItem:item]){
            [succArray addObject:item.keyPath];
        }else{
            [self.itemContainer removeItemWithKeyPath:item.keyPath];
        }
    }
    
    return [succArray copy];
}

-(Class)_MyClass{
    AWSimpleKVO *this = [self awSimpleKVO];
    return this.simpleKVOSuperClass;
}

-(void)_MyForwardInvocation:(NSInvocation *)anInvocation{
    AWSimpleKVO *this = [self awSimpleKVO];
    SEL setterSel = anInvocation.selector;
    SEL realSel = sel_registerName([NSString stringWithFormat:@"%@%s", AWSIMPLEKVOPREFIX, sel_getName(setterSel)].UTF8String);
    [anInvocation setSelector:realSel];
    [anInvocation invoke];
    AWSimpleKVOItem *item = [this.itemContainer itemWithKeyPath:[AWSimpleKVOUtils keyPathWithSetterSel:[NSString stringWithFormat:@"%s", sel_getName(setterSel)]]];
    if(!item){
        return;
    }
    id oldValue = [this.obj valueForKey:item.keyPath];
    id newValue = [this.obj valueForKey:item.keyPath];
    if(this.obj.awSimpleKVOIgnoreEqualValue && [newValue isEqual:oldValue]){
        return;
    }
    
    NSMutableDictionary *change = [NSMutableDictionary new];
    if(item.options & NSKeyValueObservingOptionOld){
        change[@"old"] = oldValue;
    }
    if(item.options & NSKeyValueObservingOptionNew){
        change[@"new"] = newValue;
    }
    if(change.count <= 0){
        return;
    }
    
    for (id ctx in item.contextToBlocks.allKeys) {
        id block = item.contextToBlocks[ctx];
        if(block){
            ((void (^)(NSObject *, NSString *, NSDictionary *, void *))block)(this.obj, item.keyPath, [change copy], [item contextFromId:ctx]);
        }
    }
}

-(IMP) _replaceMethodWithClass:(Class)clazz sel:(SEL)sel nSel:(SEL)nSel{
    Method method = class_getInstanceMethod(clazz, sel);
    IMP imp = method_getImplementation(method);
    
    Method nMethod = class_getInstanceMethod(self.class, nSel);
    IMP nImp = method_getImplementation(nMethod);
    
    if(imp != nImp){
        class_replaceMethod(clazz, sel, nImp, method_getTypeEncoding(method));
        return imp;
    }
    return NULL;
}

///注册新类
-(Class) addChildObserverClass:(Class) c keyPath:(NSString *)keyPath item:(AWSimpleKVOItem *)item {
    Class classNew = self.simpleKVOChildClass;
    if (!classNew) {
        @synchronized(c) {
            classNew = self.simpleKVOChildClass;
            if(!classNew) {
                NSString *classNewName = self.simpleKVOChildClassName;
                classNew = objc_allocateClassPair(c, classNewName.UTF8String, 0);
                objc_registerClassPair(classNew);
                self.simpleKVOChildClass = classNew;
                self.simpleKVOSuperClass = c;
                
                //hook forwardInvocation
                IMP forwardInvocationImp = [self _replaceMethodWithClass:classNew sel:@selector(forwardInvocation:) nSel:@selector(_MyForwardInvocation:)];
                if(!forwardInvocationImp){
                    return nil;
                }
                
                //hook class
                IMP classImp = [self _replaceMethodWithClass:classNew sel:@selector(class) nSel:@selector(_MyClass)];
                if(!classImp){
                    return nil;
                }
            }
        }
    }
    
    //保存setter方法，让原方法指向_objc_msgForward
    if(!item.setterImp){
        SEL setterSel = item.setterSel;
        if (!setterSel) {
            NSString *setterSelStr = [AWSimpleKVOUtils setterSelWithKeyPath: keyPath];
            setterSel = sel_registerName(setterSelStr.UTF8String);
            item.setterSel = setterSel;
        }
        
        Method setterMethod = class_getInstanceMethod(classNew, setterSel);
        IMP setterImp = method_getImplementation(setterMethod);
        item.setterImp = setterImp;
        if(setterImp != _objc_msgForward){
            @synchronized (classNew) {
                if(setterImp != _objc_msgForward){
                    class_replaceMethod(classNew, setterSel, _objc_msgForward, method_getTypeEncoding(setterMethod));
                    class_replaceMethod(classNew, sel_registerName([NSString stringWithFormat:@"%@%s", AWSIMPLEKVOPREFIX, sel_getName(setterSel)].UTF8String), setterImp, method_getTypeEncoding(setterMethod));
                }
            }
        }
    }
    
    if (!self.isCounted) {
        @synchronized (self) {
            if (!self.isCounted) {
                [[AWSimpleKVOCounter sharedInstance] increaceForClassName: self.simpleKVOChildClassName];
                self.isCounted = YES;
            }
        }
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
-(void) removeAllObservers{
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
            BOOL reduceSucc = [counter reduceForClassName: className];
            if(reduceSucc){
                if ([counter countForClassName:className] <= 0) {
                    objc_disposeClassPair(childClass);
                }
            }
        });
    }
}

@end
