#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import <CoreLocation/CoreLocation.h>
#import <objc/runtime.h>

// متغيرات التحكم العامة بداخل ملف ثنائي واحد
static BOOL isLocationSpoofed = NO;
static double spoofedLatitude = 0.0;
static double spoofedLongitude = 0.0;

// واجهة الخريطة والتحكم
@interface TestMapViewController : UIViewController <MKMapViewDelegate, UISearchBarDelegate>
@property (nonatomic, strong) MKMapView *mapView;
@property (nonatomic, strong) UISearchBar *searchBar;
@property (nonatomic, strong) UILabel *coordinatesLabel;
@end

@implementation TestMapViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    CGFloat w = self.view.bounds.size.width;
    CGFloat h = self.view.bounds.size.height;
    
    self.searchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0, 40, w, 50)];
    self.searchBar.delegate = self;
    self.searchBar.placeholder = @"ابحث عن الموقع هنا...";
    [self.view addSubview:self.searchBar];
    
    CGFloat mapH = (h - 90) * 0.80;
    self.mapView = [[MKMapView alloc] initWithFrame:CGRectMake(0, 90, w, mapH)];
    self.mapView.delegate = self;
    [self.view addSubview:self.mapView];
    
    UILongPressGestureRecognizer *lp = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(handleMapPress:)];
    lp.minimumPressDuration = 0.5;
    [self.mapView addGestureRecognizer:lp];
    
    CGFloat sY = 90 + mapH + 10;
    self.coordinatesLabel = [[UILabel alloc] initWithFrame:CGRectMake(20, sY, w - 40, 30)];
    self.coordinatesLabel.textAlignment = NSTextAlignmentCenter;
    self.coordinatesLabel.text = @"الإحداثيات: حدد موقعاً";
    [self.view addSubview:self.coordinatesLabel];
    
    CGFloat bY = sY + 40;
    CGFloat bW = (w - 50) / 2;
    
    UIButton *btnOn = [[UIButton alloc] initWithFrame:CGRectMake(20, bY, bW, 40)];
    [btnOn setTitle:@"تفعيل" forState:UIControlStateNormal];
    [btnOn setBackgroundColor:[UIColor greenColor]];
    [btnOn setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnOn.layer.cornerRadius = 8;
    [btnOn addTarget:self action:@selector(startSpoof) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnOn];
    
    UIButton *btnOff = [[UIButton alloc] initWithFrame:CGRectMake(20 + bW + 10, bY, bW, 40)];
    [btnOff setTitle:@"إيقاف" forState:UIControlStateNormal];
    [btnOff setBackgroundColor:[UIColor redColor]];
    [btnOff setTitleColor:[UIColor whiteColor] forState:UIControlStateNormal];
    btnOff.layer.cornerRadius = 8;
    [btnOff addTarget:self action:@selector(stopSpoof) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btnOff];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [searchBar resignFirstResponder];
    MKLocalSearchRequest *req = [[MKLocalSearchRequest alloc] init];
    req.naturalLanguageQuery = searchBar.text;
    MKLocalSearch *s = [[MKLocalSearch alloc] initWithRequest:req];
    [s startWithCompletionHandler:^(MKLocalSearchResponse *res, NSError *err) {
        if (res.mapItems.count > 0) {
            CLLocationCoordinate2D coord = res.mapItems.firstObject.placemark.coordinate;
            spoofedLatitude = coord.latitude;
            spoofedLongitude = coord.longitude;
            [self.mapView setCenterCoordinate:coord animated:YES];
            [self updateOverlay];
        }
    }];
}

- (void)handleMapPress:(UILongPressGestureRecognizer *)g {
    if (g.state == UIGestureRecognizerStateBegan) {
        CGPoint tp = [g locationInView:self.mapView];
        CLLocationCoordinate2D coord = [self.mapView convertPoint:tp toCoordinateFromView:self.mapView];
        spoofedLatitude = coord.latitude;
        spoofedLongitude = coord.longitude;
        [self updateOverlay];
    }
}

- (void)updateOverlay {
    [self.mapView removeAnnotations:self.mapView.annotations];
    MKPointAnnotation *ann = [[MKPointAnnotation alloc] init];
    CLLocationCoordinate2D coord;
    coord.latitude = spoofedLatitude;
    coord.longitude = spoofedLongitude;
    ann.coordinate = coord;
    [self.mapView addAnnotation:ann];
    self.coordinatesLabel.text = [NSString stringWithFormat:@"Lat: %.5f, Lon: %.5f", spoofedLatitude, spoofedLongitude];
}

- (void)startSpoof { isLocationSpoofed = YES; }
- (void)stopSpoof { isLocationSpoofed = NO; }
@end


// --- دمج واعتراض الكود بشكل رسمي بدون أوسمة ثيوس المعقدة ---
static CLLocation* (*orig_location)(id, SEL);

CLLocation* hooked_location(id self, SEL _cmd) {
    if (isLocationSpoofed) {
        return [[CLLocation alloc] initWithLatitude:spoofedLatitude longitude:spoofedLongitude];
    }
    return orig_location(self, _cmd);
}

static void (*orig_viewDidAppear)(id, SEL, BOOL);

void hooked_viewDidAppear(UIViewController *self, SEL _cmd, BOOL animated) {
    orig_viewDidAppear(self, _cmd, animated);
    
    // لمستين لفتح الخريطة
    for (UIGestureRecognizer *rec in self.view.gestureRecognizers) {
        if ([rec isKindOfClass:[UITapGestureRecognizer class]] && ((UITapGestureRecognizer *)rec).numberOfTapsRequired == 2) {
            return;
        }
    }
    
    UITapGestureRecognizer *tg = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(triggerCustomMap_Amer)];
    tg.numberOfTapsRequired = 2;
    [self.view addGestureRecognizer:tg];
}

// دالة النظام المسؤولة عن تبديل العمليات تلقائياً عند التشغيل
__attribute__((constructor)) static void init() {
    @autoreleasepool {
        // اعتراض ميكانيكية الموقع
        Method originalMethod = class_getInstanceMethod([CLLocationManager class], @selector(location));
        orig_location = (CLLocation* (*)(id, SEL))method_getImplementation(originalMethod);
        method_setImplementation(originalMethod, (IMP)hooked_location);
        
        // اعتراض الشاشات لإضافة مستشعر اللمستين
        Method origMethodView = class_getInstanceMethod([UIViewController class], @selector(viewDidAppear:));
        orig_viewDidAppear = (void (*)(id, SEL, BOOL))method_getImplementation(origMethodView);
        method_setImplementation(origMethodView, (IMP)hooked_viewDidAppear);
        
        // إضافة الدالة الجديدة لفتح الخريطة برمجياً
        Class uiVC = [UIViewController class];
        SEL newSel = sel_registerName("triggerCustomMap_Amer");
        IMP newImp = imp_implementationWithBlock(^(UIViewController *vc) {
            TestMapViewController *mapVC = [[TestMapViewController alloc] init];
            mapVC.modalPresentationStyle = UIViewControllerModalPresentationFullScreen;
            [vc presentViewController:mapVC animated:YES completion:nil];
        });
        class_addMethod(uiVC, newSel, newImp, "v@:");
    }
}