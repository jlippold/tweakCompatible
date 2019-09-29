@interface CydiaRelation : NSObject

@property (nonatomic, retain, readonly) NSString *relationship;
@property (nonatomic, retain, readonly) NSArray *clauses;

@end
