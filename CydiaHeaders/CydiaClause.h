@class CydiaOperation;

@interface CydiaClause : NSObject

@property (nonatomic, retain, readonly) NSString *package;
@property (nonatomic, retain, readonly) CydiaOperation *version;

@end
