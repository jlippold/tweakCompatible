@interface CyteViewController : UIViewController

- (void)reloadData;
- (void)unloadData;

- (void)releaseSubviews;

- (void)setPageColor:(UIColor *)color;

@property (nonatomic, retain, readonly) NSURL *navigationURL;
@property (nonatomic, retain) id delegate;
@property (readonly) BOOL hasLoaded;

@end
