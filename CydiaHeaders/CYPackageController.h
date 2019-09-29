#import "CydiaWebViewController.h"

@class Database;

@interface CYPackageController : CydiaWebViewController <UIScrollViewDelegate>

- (instancetype)initWithDatabase:(Database *)database forPackage:(NSString *)name withReferrer:(NSString *)referrer;

@end
