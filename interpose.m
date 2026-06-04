#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>

// تعريف هيكل البيانات القياسي لـ DYLD Interposing
typedef struct dyld_interpose_tuple {
    const void* replacement;
    const void* original;
} dyld_interpose_tuple;

// تعيين إحداثيات الموقع المزيف (الرياض كمثال)
static double const kFakeLatitude = 24.7136;
static double const kFakeLongitude = 46.6753;

// الدالة البديلة التي تعطي الإحداثيات المزيفة
CLLocationCoordinate2D my_coordinate(CLLocation *self, SEL _cmd) {
    CLLocationCoordinate2D fakeCoord;
    fakeCoord.latitude = kFakeLatitude;
    fakeCoord.longitude = kFakeLongitude;
    return fakeCoord;
}

// مصفوفة الـ Interpose الرسمية المتوافقة مع معايير آبل للترجمة المباشرة
__attribute__((used)) static const dyld_interpose_tuple interposing_map[] \
__attribute__((section("__DATA,__interpose"))) = {
    { (const void*)my_coordinate, (const void*)-[CLLocation coordinate] }
};
