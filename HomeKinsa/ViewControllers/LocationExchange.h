//
//  LocationExchange.h
//  HomeKinsa
//
//  Created by Zhang guangchun on 15/5/24.
//  Copyright (c) 2015年 Mikai. All rights reserved.
//

#ifndef __HomeKinsa__LocationExchange__
#define __HomeKinsa__LocationExchange__

#include <stdio.h>
#include <errno.h>
#include <fcntl.h>
#include <unistd.h>
#include <stdint.h>
#include <assert.h>
//#include <cutils/log.h>
//#include <windows.h>
#include <wchar.h>
#include <string.h>
#include <dlfcn.h>

// 定义经纬度结构体
typedef struct {
    double lng;
    double lat;
} Location;

///
///  WGS-84 到 GCJ-02 的转换
///

static const double pi = 3.14159265358979324;

//
// Krasovsky 1940
//
// a = 6378245.0, 1/f = 298.3
// b = a * (1 - f)
// ee = (a^2 - b^2) / a^2;
static const double a = 6378245.0;
static const double ee = 0.00669342162296594323;

static bool outOfChina(double lat, double lon)
{
    if (lon < 72.004 || lon > 137.8347)
        return true;
    if (lat < 0.8293 || lat > 55.8271)
        return true;
    return false;
}

static double transformLat(double x, double y)
{
    double ret = -100.0 + 2.0 * x + 3.0 * y + 0.2 * y * y + 0.1 * x * y + 0.2 * sqrt(abs(x));
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 *sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(y * pi) + 40.0 * sin(y / 3.0 * pi)) * 2.0 / 3.0;
    ret += (160.0 * sin(y / 12.0 * pi) + 320 * sin(y * pi / 30.0)) * 2.0 / 3.0;
    return ret;
}

static double transformLon(double x, double y)
{
    double ret = 300.0 + x + 2.0 * y + 0.1 * x * x + 0.1 * x * y + 0.1 * sqrt(abs(x));
    ret += (20.0 * sin(6.0 * x * pi) + 20.0 * sin(2.0 * x * pi)) * 2.0 / 3.0;
    ret += (20.0 * sin(x * pi) + 40.0 * sin(x / 3.0 * pi)) * 2.0 / 3.0;
    ret += (150.0 * sin(x / 12.0 * pi) + 300.0 * sin(x / 30.0 * pi)) * 2.0 / 3.0;
    return ret;
}

/*static Location LocationMake(double lng, double lat) {
    Location loc;
    loc.lng = lng;
    loc.lat = lat;
    return loc;
}*/

///
///  GCJ-02 坐标转换成 BD-09 坐标
///

static const double x_pi = 3.14159265358979324 * 3000.0 / 180.0;
static Location bd_encrypt(Location gcLoc)
{
    double x = gcLoc.lng, y = gcLoc.lat;
    double z = sqrt(x * x + y * y) + 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) + 0.000003 * cos(x * x_pi);
//    return LocationMake(z * cos(theta) + 0.0065, z * sin(theta) + 0.006);
    Location location = {z * cos(theta) + 0.0065, z * sin(theta) + 0.006};
    return location;
}

///
///   BD-09 坐标转换成 GCJ-02坐标
///
///
static Location bd_decrypt(Location bdLoc)
{
    double x = bdLoc.lng - 0.0065, y = bdLoc.lat - 0.006;
    double z = sqrt(x * x + y * y) - 0.00002 * sin(y * x_pi);
    double theta = atan2(y, x) - 0.000003 * cos(x * x_pi);
//    return LocationMake(z * cos(theta), z * sin(theta));
    Location location = {z * cos(theta), z * sin(theta)};
    return location;
}

static Location transformFromWGSToGCJ(Location wgLoc)
{
    Location mgLoc;
    if (outOfChina(wgLoc.lat, wgLoc.lng))
    {
        mgLoc = wgLoc;
        return mgLoc;
    }
    double dLat = transformLat(wgLoc.lng - 105.0, wgLoc.lat - 35.0);
    double dLon = transformLon(wgLoc.lng - 105.0, wgLoc.lat - 35.0);
    double radLat = wgLoc.lat / 180.0 * pi;
    double magic = sin(radLat);
    magic = 1 - ee * magic * magic;
    double sqrtMagic = sqrt(magic);
    dLat = (dLat * 180.0) / ((a * (1 - ee)) / (magic * sqrtMagic) * pi);
    dLon = (dLon * 180.0) / (a / sqrtMagic * cos(radLat) * pi);
    mgLoc.lat = wgLoc.lat + dLat;
    mgLoc.lng = wgLoc.lng + dLon;
    
    return mgLoc;
}

#endif /* defined(__HomeKinsa__LocationExchange__) */
