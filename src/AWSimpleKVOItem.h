/*
 copyright 2018-2019 wanghongyu.
 The project page：https://github.com/hardman/AWSimpleKVO
 My blog page: http://www.jianshu.com/u/1240d2400ca1
 */

#import <Foundation/Foundation.h>

@interface AWSimpleKVOItem : NSObject
///监听的key
@property (nonatomic, copy) NSString *keyPath;
///context用于区分监听者，可实现多处监听同一个对象的同一个key
@property (nonatomic, strong) NSMapTable *contextToBlocks;
///保存的旧值
@property (nonatomic, strong) id oldValue;
///监听选项
@property (nonatomic, unsafe_unretained) NSKeyValueObservingOptions options;
///原setterSEL
@property (nonatomic, unsafe_unretained) SEL setterSel;
///原setterIMP
@property (nonatomic, unsafe_unretained) IMP setterImp;

///将id转为context
-(void *)contextFromId:(id)ctx;
///将context转为id
-(id) idWithContext:(void *)context;
///保存context和block 一一对应
-(BOOL) addContext:(void *)context block:(id)block;
///移除context
-(void) removeContext:(void *)context;
///是否包含context
-(BOOL) containsContext:(void *)context;
///获取block
-(id) blockWithContext:(void *)context;
///包含的context数量
-(NSInteger) contextsCount;

@end

///items 容器
@interface AWSimpleKVOItemContainer: NSObject
///获取item
-(AWSimpleKVOItem *) itemWithKeyPath:(NSString *)keyPath;
///加入item
-(BOOL) addItem:(AWSimpleKVOItem *)item;
///移除item
-(void) removeItemWithKeyPath:(NSString *) keyPath;
@end
