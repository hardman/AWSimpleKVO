![](https://upload-images.jianshu.io/upload_images/1334370-e2e51dbedf21a6b7.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/700)

前几天写了一篇blog（[点这里](https://www.jianshu.com/p/2a2a03681814)），分析了系统KVO可能的实现方式。并添加了简单代码验证。

既然系统KVO不好用，我们完全可以根据之前的思路，再造一个可以在项目中使用的KVO的轮子。

# 1. 功能介绍

支持如下功能：

- 支持`block`回调
- 支持一次添加多参数
- 不需要`removeObserver`，监听会随对象自动删除
- 可设置忽略重复值
- 线程安全
- 仅支持下列类型的监听：
	- 所有OC对象
	- 基本数据类型：`char`, `int`, `short`, `long`, `long long`, `unsigned char`, `unsigned int`, `unsigned short`, `unsigned long`, `unsigned long long`, `float`, `double`, `bool`
	- 结构体：`CGSize`, `CGPoint`, `CGRect`, `CGVector`, `CGAffineTransform`, `UIEdgeInsets`, `UIOffset`

不支持如下功能：

- 仅支持 `NSKeyValueObservingOptionNew` 和 `NSKeyValueObservingOptionOld`，不支持其他options
- 不支持多级`keyPath`，如 `"a.b.c"`
- 不支持`weak`变量自动置空监听
- `context`需使用OC对象
- 不支持只有`setter`没有`getter`的属性

## 1.1 引用方法

首先在你的工程`Podfile`中添加：

```
target 'TargetName' do
 pod 'AWSimpleKVO'
end
```

然后在命令行中执行：

```
pod install
```

打开你的 `ProjectName.xcworkspace` 就可以使用了。

## 1.2 使用方法

`api`同系统`KVO`基本一致，可以看源码`demo`中的例子，[点这里看demo]()。

```oc
//1. 首先引入头文件
#import <AWSimpleKVO/NSObject+AWSimpleKVO.h>


@interface TestSimpleKVO()
@property (nonatomic, unsafe_unretained) int i;
@property (atomic, strong) NSObject *o;
@property (nonatomic, copy) NSString *s;
@property (nonatomic, weak) NSObject *w;
@end

@implementation TestSimpleKVO

+(void) testCommon{
    TestSimpleKVO *testObj = [[TestSimpleKVO alloc] init];
    ///1. 添加监听
    NSLog(@"--before 添加监听");
    [testObj awAddObserverForKeyPath:@"i" options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        NSLog(@"keyPath=%@, changed=%@", keyPath, change);
    }];
    [testObj awAddObserverForKeyPaths:@[@"o", @"s", @"w"] options:NSKeyValueObservingOptionNew | NSKeyValueObservingOptionOld context:nil block:^(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context) {
        NSLog(@"keyPath=%@, changed=%@", keyPath, change);
    }];
    NSLog(@"--after 添加监听");
    
    testObj.i = 12030;
    testObj.o = [[NSObject alloc]init];
    testObj.s = @"66666";
    
    ///2. setValue:forKey:
    NSLog(@"--before setValue:ForKey");
    [testObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after setValue:ForKey");
    
    ///3. 忽略相同赋值
    NSLog(@"--before awSimpleKVOIgnoreEqualValue to YES");
    testObj.awSimpleKVOIgnoreEqualValue = YES;
    [testObj setValue:@12304 forKey:@"i"];
    [testObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after awSimpleKVOIgnoreEqualValue to YES");
    
    NSLog(@"--before awSimpleKVOIgnoreEqualValue to NO");
    testObj.awSimpleKVOIgnoreEqualValue = NO;
    [testObj setValue:@12304 forKey:@"i"];
    [testObj setValue:@12304 forKey:@"i"];
    NSLog(@"--after awSimpleKVOIgnoreEqualValue to NO");
    
    ///4. 移除监听
    NSLog(@"--before 移除监听");
    [testObj awRemoveObserverForKeyPath:@"o" context:nil];
    testObj.o = [[NSObject alloc] init];
    NSLog(@"--after 移除监听");
}

@end
```

# 2. 代码解析

## 2.1 基本思路

代码的基本思路同我之前写的这篇文章 [=> iOS的KVO实现剖析]([点这里](https://www.jianshu.com/p/2a2a03681814))。

指导思想如下：

- 收集传入参数，保存在字典中
- 动态创建当前类的子类，并把当前对象的`class`设为子类。这样我们调用对象的方法时，会先在子类中查找
- 为子类添加当前监听参数的`setter`方法，这个`setter`方法指向一个我们自己编写的C函数。这样我们调用对象的`setter`方法时，就会调用我们自定义的C函数
- 在C函数中，调用父类的相同的`setter`方法。然后调用通知`block`

## 2.2 具体实现细节

### 2.2.1 收集参数

添加属性变化监听是调用的 `NSObject(AWSimpleKVO)` 这个扩展里的方法`awAddObserverForKeyPath:options:context:block:`。在它内部，其实调用的是`AWSimpleKVO`的同名方法。

我们主要功能都是在类`AWSimpleKVO`中实现的，`NSObject(AWSimpleKVO)` 只是提供了一个包装。

```oc
//AWSimpleKVO.m

-(BOOL)addObserverForKeyPath:(NSString *)keyPath options:(NSKeyValueObservingOptions)options context:(void *)context block:(void (^)(NSObject *observer, NSString *keyPath, NSDictionary *change, void *context)) block{
    ///1. 检查参数
    ...
    
    ///生成并保存item
    AWSimpleKVOItem *item = nil;
    
    @synchronized(self){
        if ([self.itemContainer itemWithKeyPath:keyPath context:context] != nil) {
            return NO;
        }
        
        item = [self _genKvoItemWithKeyPath:keyPath options:options context:context block:block];
    
        [self.itemContainer addItem:item forKeyPath:keyPath context:context];
    }
    
    ///生成
    return [self _addClassAndMethodForItem:item];
}

```

从上述代码中可以看出，我们通过 `_genKvoItemWithKeyPath`方法生成了一个`AWSimpleKVOItem `的实例`item`，然后将`item`存入`itemContainer`中。

`AWSimpleKVOItem`会将`keyPath`，`options`, `context`, `block` 这些参数保存起来，然后放入`itemContainer`中。

```oc
@interface AWSimpleKVOItem: NSObject///监听的key
@property (nonatomic, copy) NSString *keyPath;
///context用于区分监听者，可实现多处监听同一个对象的同一个key
@property (nonatomic, strong) NSMutableDictionary *contextToBlocks;

///保存的旧值
@property (nonatomic, strong) id oldValue;

///key的类型
@property (nonatomic, unsafe_unretained) AWSimpleKVOSupporedIvarType ivarType;
///key的typeCoding
@property (nonatomic, copy) NSString *ivarTypeCode;

//监听选项
@property (nonatomic, unsafe_unretained) NSKeyValueObservingOptions options;

... ...

@end

```

从`AWSimpleKVOItem`的代码中可以看出，这个类没有方法，全是属性，它就是一个存储数据的model类。当然除了传入参数之外，这个类也会存储一些计算过程中生成的变量。

`AWSimpleKVOItemContainer` 仅仅对`NSDictionary`的一个封装。

下面的伪代码描述了`AWSimpleKVOItemContainer `和`AWSimpleKVOItem`中的`contextToBlocks`的结构。

```oc
AWSimpleKVOItemContainer.observerDict = {
	keyPath0: AWSimpleKVOItem0 {
		contextToBlocks:{
			context0: notifyBlock0,
			context1: notifyBlock1
			... ...	
		}
	},
	keyPath1: AWSimpleKVOItem1 {
		contextToBlocks:{
			context0: notifyBlock0,
			context1: notifyBlock1
			... ...	
		}
	},
	... ...
}
```

从上面的结构可知，一个`keyPath`可以注册多个监听，可使用`context`区分不同的`block`。

这就是说，我们可以为同一个对象，同一个`keyPath`添加多个监听，只要令`context`不同即可。

我们可以从`AWSimpleKVOItemContainer`中获取到已经添加了监听的所有`items`。

### 2.2.2 动态添加子类


添加子类的代码很简单，最主要的代码只需要2行：`objc_allocateClassPair` 和 `objc_registerClassPair `。

```
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
    ... ...
    return classNew;
}
```

添加子类之后，我们需要将当前对象的`class`设置为新创建的子类。这需要调用 `object_setClass` 方法。

```oc
-(void) safeThreadSetClass:(Class) cls {
    if(cls == self.safeThreadGetClass) {
        return;
    }
    @synchronized(self.obj) {
        object_setClass(self.obj, cls);
    }
}
```

这样我们的对象，如果再调用`setter`方法时，就会先在我们创建的子类中查找方法了。

### 2.2.3 为子类添加setter方法

```oc
-(Class) addChildObserverClass:(Class) c keyPath:(NSString *)keyPath item:(AWSimpleKVOItem *)item {
	
	... ...
    
    BOOL needReplace = YES;
    Method currMethod = class_getInstanceMethod(classNew, item._setSel);
    if (currMethod != NULL) {
        IMP currIMP = method_getImplementation(currMethod);
        needReplace = currIMP != item._childMethod;
    }
    if (needReplace) {
        class_replaceMethod(classNew, item._setSel, item._childMethod, item._childMethodTypeCoding.UTF8String);
    }
    
    ... ...
    
    return classNew;
}
```

由于`runtime.h`中没有找到类似`removeMethod`或`deleteMethod`方法，考虑重入等因素。
我们可以使用`replaceMethod`来代替`addMethod`和`removeMethod`的功能。

上面的`_childMethod`即我们子类`setter`方法所指向的C函数。

`_childMethod` 生成和 `replaceMethod`的使用，都需要对`iOS`的`TypeEncoding`有所了解，可以看[这里的介绍](https://www.jianshu.com/p/2a2a03681814)。

### 2.2.4 setter方法对应的C函数

C函数要做2件事：

- 调用父类的`setter`方法
- 调用`AWSimpleKVOItem `中保存的`block`

我们的代码中为不同的变量类型分别添加了不同的c函数。它们的逻辑相同，只是参数类型不同。
我们这里只看`keyPath`类型为`OC`对象的函数实现。

```oc
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
```

最主要的代码就是

```
///调用父类方法
((void (*)(id, SEL, id))item._superMethod)(obj, sel, value);
///触发为keyPath添加的所有block回调
_childSetterNotify(item, obj, item.keyPath, value);
```

# 3. 总结

到这里，我们就完成了一个自己写的KVO，它的功能和系统KVO完全相同，完全可以替代系统的KVO使用。

如果遇到问题，可以留言一起讨论。

如果觉得对自己有帮助，或者学到了东西，请帮忙点赞转发+评论，[github+star](https://github.com/hardman/AWSimpleKVO)。


