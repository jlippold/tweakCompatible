#import "CydiaHeaders/CYPackageController.h"
#import "CydiaHeaders/MIMEAddress.h"
#import "CydiaHeaders/Package.h"
#import "CydiaHeaders/Source.h"
#import <UIKit/UIAlertView+Private.h>

%hook CYPackageController

- (void)applyRightButton {
	%orig;

	if (self.rightButton && !self.isLoading) {
		Package *package = MSHookIvar<Package *>(self, "package_");

		if (package.source) {
			self.navigationItem.rightBarButtonItems = @[
				self.rightButton,
				[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAction target:self action:@selector(_compat_check:)] autorelease]
			];
		}
	}
}

%new - (void)_compat_check:(UIBarButtonItem *)sender {

	Package *package = MSHookIvar<Package *>(self, "package_");
    NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];

	NSURL *url = [NSURL URLWithString:
                         [NSString stringWithFormat:@"https://raw.githubusercontent.com/jlippold/tweakCompatible/%@/compatibilty.json", iOSVersion]];

	
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError)
     {
		 NSString *isCompat = @"Unknown";
         if (data.length > 0 && connectionError == nil) {
             NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
             
             if (json[@"packages"]) {
                 for (id item in json[@"packages"]) {
					NSString *itemId = [NSString stringWithFormat:@"%@", [item objectForKey:@"id"]];
					//NSString *itemVersion = [NSString stringWithFormat:@"%@", [item objectForKey:@"version"]];
					NSString *itemStatus = [NSString stringWithFormat:@"%@", [item objectForKey:@"status"]];

					if ([itemId isEqualToString:package.id]) {
						isCompat = itemStatus;
					}
				 }
             }

			NSString *message = [NSString stringWithFormat:@"Sorry, no compatibility found for: %@", package.name];
			if ([isCompat isEqualToString:@"Compatible"]) {
				message = [NSString stringWithFormat:@"%@ is compatible with iOS %@! ", package.name, iOSVersion];
			}
			if ([isCompat isEqualToString:@"Incompatible"]) {
				message = [NSString stringWithFormat:@"%@ is not compatible with iOS %@! ", package.name, iOSVersion];
			}

			UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Compatibilty Check"
									message:message
									preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"Got it!" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) {}];
					
			[alert addAction:defaultAction];
			[self.navigationController presentViewController:alert animated:YES completion:nil];
         } else {

			UIAlertController *error = [UIAlertController alertControllerWithTitle:@"Error"
									message:@"Your iOS version is not yet supported"
									preferredStyle:UIAlertControllerStyleAlert];

			UIAlertAction *defaultAction = [UIAlertAction actionWithTitle:@"Ok" style:UIAlertActionStyleDefault
											handler:^(UIAlertAction * action) {}];
					
			[error addAction:defaultAction];
			[self.navigationController presentViewController:error animated:YES completion:nil];
		 }
	}];
}

%end