@class MIMEAddress, Source;

@interface Package : NSObject

@property (nonatomic, retain, readonly) NSString *id;
@property (nonatomic, retain, readonly) NSString *name;
@property (nonatomic, retain, readonly) MIMEAddress *author;
@property (nonatomic, retain, readonly) NSString *installed;
@property (nonatomic, retain, readonly) Source *source;
@property (nonatomic, retain, readonly) NSArray *relations;
@property (nonatomic, retain, readonly) NSString *homepage;

@property (readonly) BOOL isCommercial;
@property (nonatomic, retain, readonly) NSString *latest;
@property (nonatomic, retain, readonly) NSString *section;
@property (nonatomic, retain, readonly) NSString *shortDescription;

@end
