#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <mach-o/dyld-interposing.h>

// 1. تعيين إحداثيات الموقع المزيف الذي تريده (الرياض كمثال)
static double const kFakeLatitude = 24.7136;
static double const kFakeLongitude = 46.6753;

// 2. الدالة البديلة الخاصة بنا
CLLocationCoordinate2D custom_coordinate(CLLocation *self, SEL _cmd) {
    CLLocationCoordinate2D fakeCoord;
    fakeCoord.latitude = kFakeLatitude;
    fakeCoord.longitude = kFakeLongitude;
    return fakeCoord;
}

// 3. جدول الـ Interposing لتبديل الدالة الرسمية بالدالة البديلة
DYLD_INTERPOSE(custom_coordinate, -[CLLocation coordinate]);
