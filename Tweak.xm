#import "CydiaHeaders/CYPackageController.h"
#import "CydiaHeaders/MIMEAddress.h"
#import "CydiaHeaders/Package.h"
#import "CydiaHeaders/Source.h"
#import <UIKit/UIAlertView+Private.h>
#import <sys/utsname.h> 

%hook CYPackageController

- (void)applyRightButton {
	%orig;

	if (self.rightButton && !self.isLoading) {
		Package *package = MSHookIvar<Package *>(self, "package_");

		if (package.source) {
			self.navigationItem.rightBarButtonItems = @[
				self.rightButton,
				[[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(_compat_check:)] autorelease]
			];
		}
	}
}




%new - (void)_compat_check:(UIBarButtonItem *)sender {

	Package *package = MSHookIvar<Package *>(self, "package_");
    
	//calc device type: https://stackoverflow.com/a/20062141
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceId = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];
	NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
	
	//download tweak list
	//NSURL *url = [NSURL URLWithString:@"https://jlippold.github.io/tweakCompatible/tweaks.json"];
	NSURL *url = [NSURL URLWithString:@"https://raw.githubusercontent.com/jlippold/tweakCompatible/dev/docs/tweaks.json"];
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError)
     {
		 
         if (data.length > 0 && connectionError == nil) {
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
			
			//Check if package in on the website
			id foundItem = nil;
			BOOL exists = NO;
			if (json[@"packages"]) {
				for (id item in json[@"packages"]) {
					NSString *thisPackageId = [NSString stringWithFormat:@"%@", [item objectForKey:@"id"]];
					if ([thisPackageId isEqualToString:package.id]) {
						foundItem = item;
						exists = YES;
						break;
					}
				}
			}
			
			//is it installed in cydia
			BOOL installed = NO;
			if (package.installed) {
				installed = YES;
			}
			
			//pull the package homepage url
			NSArray *BuiltInRepositories = @[
				@"http://apt.saurik.com/",
				@"http://apt.thebigboss.org/repofiles/cydia/",
				@"http://apt.modmyi.com/",
				@"http://cydia.zodttd.com/repo/cydia/"
			];

			NSURL *url;
			if ([BuiltInRepositories containsObject:package.source.rooturi]) {
				url = [NSURL URLWithString:[NSString stringWithFormat:@"http://cydia.saurik.com/package/%@/", package.id]];
			} else if (package.homepage && ![package.homepage isEqualToString:@"http://myrepospace.com/"]) {
				url = [NSURL URLWithString:package.homepage];
			} else {
				url = [NSURL URLWithString:package.source.rooturi];
			}

			//check if iOS Version can be submitted
			BOOL allowediOSVersion = NO;
			if (json[@"iOSVersions"]) {
				for (NSString *thisIOSVersion in json[@"iOSVersions"]) {
					if ([thisIOSVersion isEqualToString:iOSVersion]) {
						allowediOSVersion = YES;
						break;
					}
				}
			}

			//check if category can be submitted
			BOOL allowedCategory = NO;
			if (json[@"categories"]) {
				for (NSString *thisCategory in json[@"categories"]) {
					if ([thisCategory isEqualToString:package.section]) {
						allowedCategory = YES;
						break;
					}
				}
			}
			//build a dict with all found properties
			NSDictionary *userInfo = @{
				@"deviceId" : deviceId, 
				@"iOSVersion" : iOSVersion,
				@"indexed": @(exists),
				@"packageId": package.id,
				@"packageName": package.name,
				@"packageLatest": package.latest,
				@"packageCommercial": @(package.isCommercial),
				@"packageCategory": package.section,
				@"packageDepiction": package.shortDescription,
				@"iOSVersionAllowed": @(allowediOSVersion),
				@"packageCategoryAllowed": @(allowedCategory),
				@"packageInstalled": @(installed),
				@"packageRepo": [package.source name],
				@"packageAuthor": package.author.name,
				@"packageHomepage": [NSString stringWithFormat:@"%@", url],
			};
			
			//create json string of all properties
			NSString *userInfoJson = @"";
			NSString *message = @"";
			NSError *jsonError; 
			NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:kNilOptions error:&jsonError];
			if (!jsonData) {
				NSLog(@"Got a json error: %@", jsonError);
				message = [NSString stringWithFormat:@"Got a json error: %@", jsonError];
			} else {
				userInfoJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
				message = [NSString stringWithFormat:@"%@ \n\n", userInfoJson];
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
			return;

			if (foundItem) {

				
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


