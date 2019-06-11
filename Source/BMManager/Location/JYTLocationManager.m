//
//  JYTLocationManager.m
//  JingYitong
//
//  Created by XHY on 16/5/26.
//  Copyright © 2016年 XHY. All rights reserved.
//

#import "JYTLocationManager.h"
#import <CoreLocation/CoreLocation.h>
#import "TransformCLLocation.h"
#import <UIKit/UIKit.h>

@interface JYTLocationManager () <AMapLocationManagerDelegate>
{
    AMapLocationManager *_locationManager;
    NSTimer *_timer;
}
@property (nonatomic, strong) AMapLocationManager *locationManager;
@property (nonatomic, copy) CurrentLocationBlock currentLocationBlock;
@property (nonatomic, copy) LocationBlock locationBlock;

@property (nonatomic, copy) NSString *cacheLng;
@property (nonatomic, copy) NSString *cacheLat;
@property (nonatomic, strong) AMapLocationReGeocode *cacheReGeocode;

@end

@implementation JYTLocationManager


+ (instancetype)shareInstance
{
    static JYTLocationManager *_instance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        if (!_instance) {
            _instance = [[JYTLocationManager alloc] init];
        }
    });
    return _instance;
}

- (CLLocationManager *)locationManager
{
    if (!_locationManager) {
        //定位管理器
        _locationManager=[[AMapLocationManager alloc]init];
        //设置代理
        _locationManager.delegate = self;
        //设置定位精度
        _locationManager.desiredAccuracy=kCLLocationAccuracyBest;
        
    }
    return _locationManager;
}

- (void)updateCurrentLocation
{
    [self.locationManager requestLocationWithReGeocode:YES completionBlock:^(CLLocation *location, AMapLocationReGeocode *regeocode, NSError *error) {
        
        if (error)
        {
            NSLog(@"locError:{%ld - %@};", (long)error.code, error.localizedDescription);
            
            if (error.code == AMapLocationErrorLocateFailed)
            {
                return;
            }
        }
        
        //定位信息
        NSLog(@"location:%@", location);
        
        //逆地理信息
        if (regeocode)
        {
            NSLog(@"reGeocode:%@", regeocode);
        }
        
        [self callBackWithLongitude:[NSString stringWithFormat:@"%ld",location.coordinate.longitude] latitude:[NSString stringWithFormat:@"%ld",location.coordinate.latitude] reGeocode:regeocode];
    }];
}

- (void)timerAction
{
    [self updateCurrentLocation];
}

#pragma mark - CLLocationManagerDelegate
- (void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray<CLLocation *> *)locations
{
    CLLocation *location = [locations firstObject]; //取出第一个位置
    
    /* 将gps坐标系转换成gcj-02坐标系 */
    CLLocationCoordinate2D coordinate = [TransformCLLocation wgs84ToGcj02:location.coordinate];
    [self.locationManager stopUpdatingLocation];
    
    [self callBackWithLongitude:[NSString stringWithFormat:@"%f",coordinate.longitude] latitude:[NSString stringWithFormat:@"%f",coordinate.latitude]];
}


/**
 *  回调方法把经纬度通过block回传
 *
 *  @param lng 经度
 *  @param lat 纬度
 */
- (void)callBackWithLongitude:(NSString *)lng latitude:(NSString *)lat
{
    // 缓存位置信息
    self.cacheLng = lng;
    self.cacheLat = lat;
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if (self.currentLocationBlock) {
        self.currentLocationBlock(lng, lat);
        _currentLocationBlock = nil;
    }
}

- (void)callBackWithLongitude:(NSString *)lng latitude:(NSString *)lat reGeocode:(AMapLocationReGeocode *)reGeocode
{
    // 缓存位置信息
    self.cacheLng = lng;
    self.cacheLat = lat;
    self.cacheReGeocode = reGeocode;
    
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    if (self.locationBlock) {
        self.locationBlock(lng, lat, reGeocode);
        //        _locationBlock = nil;
    }
}

#pragma mark Public Method
- (void)getCurrentLocation:(CurrentLocationBlock)block
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(timerAction) userInfo:nil repeats:NO];
    
    self.currentLocationBlock = block;
    [self updateCurrentLocation];
}

- (void)getCacheLocation:(CurrentLocationBlock)block
{
    // 判断如果有缓存信息直接返回，无缓存则实时获取一次
    if (self.cacheLng && self.cacheLng.length > 0 && self.cacheLat && self.cacheLat.length > 0) {
        block(self.cacheLng,self.cacheLat);
    } else {
        [self getCurrentLocation:block];
    }
}

- (void)getLocation:(LocationBlock)block
{
    if (_timer) {
        [_timer invalidate];
        _timer = nil;
    }
    
    _timer = [NSTimer scheduledTimerWithTimeInterval:3.0 target:self selector:@selector(timerAction) userInfo:nil repeats:NO];
    
    self.locationBlock = block;
    [self updateCurrentLocation];
}

- (void)getCacheLocation:(LocationBlock)block
{
    // 判断如果有缓存信息直接返回，无缓存则实时获取一次
    if (self.cacheLng && self.cacheLng.length > 0 && self.cacheLat && self.cacheLat.length > 0) {
        block(self.cacheLng,self.cacheLat,self.cacheReGeocode);
    } else {
        [self getLocation:block];
    }
}

#pragma mark -- AMapLocationManagerDelegate
- (void)amapLocationManager:(AMapLocationManager *)manager doRequireLocationAuth:(CLLocationManager *)locationManager{
    [locationManager requestAlwaysAuthorization];
}


@end
