@class Package;

@interface Database : NSObject

+ (instancetype)sharedInstance;

- (Package *)packageWithName:(NSString *)name;

@end
