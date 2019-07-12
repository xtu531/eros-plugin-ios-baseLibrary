//
//  JYTLocationManager.h
//  JingYitong
//
//  Created by XHY on 16/5/26.
//  Copyright © 2016年 XHY. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AMapFoundationKit/AMapFoundationKit.h>
#import <AMapLocationKit/AMapLocationKit.h>

typedef void(^CurrentLocationBlock)(NSString *lon, NSString *lat);

typedef void(^LocationBlock)(NSString *lon, NSString *lat,AMapLocationReGeocode *reGeocode);

@interface JYTLocationManager : NSObject

+ (instancetype)shareInstance;

/**
 *  获取当前坐标
 *
 *  @param block 返回经纬度
 */
- (void)getCurrentLocation:(CurrentLocationBlock)block;

/**
 *  获取上一次定位信息
 *
 *  @param block 返回上一次定位的信息
 */
- (void)getCacheLocation:(CurrentLocationBlock)block;

- (void)getLocation:(LocationBlock)block;

- (void)getCurrentCacheLocation:(LocationBlock)block;

@end
