@class Package, UIProgressHUD;

@protocol CydiaDelegate

- (void)reloadDataWithInvocation:(NSInvocation *)invocation;
- (void)returnToCydia;
- (void)saveState;

- (void)retainNetworkActivityIndicator;
- (void)releaseNetworkActivityIndicator;

- (void)clearPackage:(Package *)package;
- (void)installPackage:(Package *)package;
- (void)installPackages:(NSArray *)packages;
- (void)removePackage:(Package *)package;
- (void)distUpgrade;

- (void)addSource:(NSDictionary *)source;
- (void)addTrivialSource:(NSString *)href;

- (void)beginUpdate;
- (BOOL)updating;
- (BOOL)requestUpdate;

- (void)loadData;
- (void)updateData;
- (void)_saveConfig;
- (void)syncData;

- (UIProgressHUD *)addProgressHUD;
- (void)removeProgressHUD:(UIProgressHUD *)hud;

- (void)showActionSheet:(UIActionSheet *)sheet fromItem:(UIBarButtonItem *)item;

@end
