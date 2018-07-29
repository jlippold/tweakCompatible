#import "CyteViewController.h"

@interface PackageListController : CyteViewController

- (void) didSelectPackage:(Package *)package;
- (id) initWithDatabase:(Database *)database title:(NSString *)title;
- (Package *) packageAtIndexPath:(NSIndexPath *)path;
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;

@end
