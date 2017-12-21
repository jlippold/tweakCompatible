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
    //NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];

	NSURL *url = [NSURL URLWithString:@"https://jlippold.github.io/tweakCompatible/tweaks.json"];

	
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError)
     {
		 
         if (data.length > 0 && connectionError == nil) {
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

			id foundItem = nil;
			if (json[@"packages"]) {
				for (id item in json[@"packages"]) {
					NSString *thisPackageId = [NSString stringWithFormat:@"%@", [item objectForKey:@"id"]];
					if ([thisPackageId isEqualToString:package.id]) {
						foundItem = item;
						break;
					}
				}
			}

			if (foundItem) {

				NSString *message = @"";
				NSString *testedVersion = [NSString stringWithFormat:@"%@", [foundItem objectForKey:@"latest"]];
				if (![package.latest isEqualToString:testedVersion]) {
					message = [message stringByAppendingString:
						[NSString stringWithFormat:@"⚠️ Warning: The last reviewed version was %@" 
									", version %@ in cydia has not yet been reviewed by the community. "
									"Here are the older results for version %@ \n", testedVersion, package.latest, testedVersion]];
				}

				id status = foundItem[@"status"];
				if (status[@"good"]) {
					for (id item in status[@"good"]) {
						message = [message stringByAppendingString:
							[NSString stringWithFormat:@"✅ Works on %@ running %@ \n\n", item[@"device"], item[@"iOS"]]];
					}
				}
				
				if (status[@"bad"]) {
					for (id item in status[@"bad"]) {
						message = [message stringByAppendingString:
							[NSString stringWithFormat:@"🚫 Not Working on %@ running %@ \n\n", item[@"device"], item[@"iOS"]]];
					}
				}
				
				if (status[@"partial"]) {
					for (id item in status[@"partial"]) {
						message = [message stringByAppendingString:
							[NSString stringWithFormat:@"⚠️ Partially Working on %@ running %@ \n", item[@"device"], item[@"iOS"]]];
						if (item[@"notes"]) {
							message = [message stringByAppendingString:[NSString stringWithFormat:@"Notes: %@ \n", item[@"notes"]]];
						}
					}
				}

				UIAlertController *results = 
					[UIAlertController alertControllerWithTitle:@"tweakCompatible Results"
						message:message
						preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction *defaultAction = 
					[UIAlertAction actionWithTitle:@"Ok" 
						style:UIAlertActionStyleDefault
						handler:^(UIAlertAction * action) {}];
						
				[results addAction:defaultAction];
				[self.navigationController presentViewController:results 
					animated:YES completion:nil];

			} else {
				UIAlertController *notFoundMessage = 
					[UIAlertController alertControllerWithTitle:@"tweakCompatible 404"
						message:@"This package has not yet been reviewed by the community"
						preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction *defaultAction = 
					[UIAlertAction actionWithTitle:@"Ok" 
						style:UIAlertActionStyleDefault
						handler:^(UIAlertAction * action) {}];
						
				[notFoundMessage addAction:defaultAction];
				[self.navigationController presentViewController:notFoundMessage 
					animated:YES completion:nil];
			}
         } else {
				UIAlertController *downloadErrorMessage = 
					[UIAlertController alertControllerWithTitle:@"tweakCompatible 500"
						message:@"Error downloading compatible tweak list"
						preferredStyle:UIAlertControllerStyleAlert];

				UIAlertAction *defaultAction = 
					[UIAlertAction actionWithTitle:@"Ok" 
						style:UIAlertActionStyleDefault
						handler:^(UIAlertAction * action) {}];
						
				[downloadErrorMessage addAction:defaultAction];
				[self.navigationController presentViewController:downloadErrorMessage 
					animated:YES completion:nil];
		 }
	}];
}

%end