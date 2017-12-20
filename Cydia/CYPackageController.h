#import "CydiaWebViewController.h"

@class Database;

@interface CYPackageController : CydiaWebViewController

- (instancetype)initWithDatabase:(Database *)database forPackage:(NSString *)name withReferrer:(NSString *)referrer;

@end
