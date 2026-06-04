#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>

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

// دالة تهيئة برمجية للحصول على الدالة الأصلية بشكل يقبله المترجم فوراً
__attribute__((constructor)) static void initialize() {
    Method originalMethod = class_getInstanceMethod([CLLocation class], @selector(coordinate));
    if (originalMethod) {
        method_setImplementation(originalMethod, (IMP)my_coordinate);
    }
}
