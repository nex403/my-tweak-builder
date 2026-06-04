#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <mach-o/dyld.h>

// 1. هيكل البيانات الرسمي الخاص بـ DYLD Interposing من آبل
typedef struct dyld_interpose_tuple {
    const void* replacement;
    const void* original;
} dyld_interpose_tuple;

// 2. تعيين الإحداثيات المزيفة (الرياض)
static double const kFakeLatitude = 24.7136;
static double const kFakeLongitude = 46.6753;

// 3. الدالة البديلة التي ستستبدل دالة النظام الأصلية
CLLocationCoordinate2D my_coordinate(CLLocation *self, SEL _cmd) {
    CLLocationCoordinate2D fakeCoord;
    fakeCoord.latitude = kFakeLatitude;
    fakeCoord.longitude = kFakeLongitude;
    return fakeCoord;
}

// 4. مصفوفة الـ Interpose لحقن الدالة في قطاع الـ __DATA داخل الـ Binary
__attribute__((used)) static const dyld_interpose_tuple interposing_map[] \
__attribute__((section("__DATA,__interpose"))) = {
    { (const void*)(my_coordinate), (const void*)_sel_registerName("coordinate") }
};
