@interface CydiaOperation : NSObject

- (NSString *)operator; // operator is a reserved word!
@property (nonatomic, retain, readonly) NSString *value;

@end
