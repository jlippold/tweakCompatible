#import "CyteViewController.h"
#import "CyteWebView.h"

@interface CyteWebViewController : CyteViewController

- (void)applyRightButton;

@property (nonatomic, retain) CyteWebView *webView;

@property (readonly) BOOL isLoading;

@property (nonatomic, retain, readonly) UIBarButtonItem *rightButton;

@end
