@interface Source : NSObject

@property (nonatomic, retain, readonly) NSString *rooturi;
@property (nonatomic, retain, readonly) NSString *name;

@property (nonatomic, retain, readonly) NSString *host;
@property (nonatomic, retain, readonly) NSString *baseuri;
@property (nonatomic, retain, readonly) NSString *trusted;
@property (nonatomic, retain, readonly) NSString *key;

@end
