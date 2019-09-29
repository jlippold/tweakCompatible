
#import "CyteViewController.h"

@interface PackageSettingsController : CyteViewController

@property (nonatomic, retain, readonly) Package *package_;

- (NSInteger) numberOfSectionsInTableView:(UITableView *)tableView;
- (NSInteger) tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section;

@end


