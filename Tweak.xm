#import "CydiaHeaders/CYPackageController.h"
#import "CydiaHeaders/CydiaWebViewController.h"
#import "CydiaHeaders/CyteWebView.h"
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

- (void) navigationURL {
	
	[self.webView stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"alert('%@')", @"Foo"]];

}

- (BOOL) _allowJavaScriptPanel {
	return YES;
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
	NSURL *url = 
		[NSURL URLWithString:[NSString stringWithFormat:@"https://jlippold.github.io/tweakCompatible/json/packages/%@.json", package.id]];
	
	[NSURLConnection sendAsynchronousRequest:[NSURLRequest requestWithURL:url]
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response,
                                               NSData *data,
                                               NSError *connectionError)
     {
		 

		id foundItem = nil; //package on website
		id allVersions = nil; //all versions on website
		id foundVersion = nil; //version on website
		
		BOOL packageExists = NO; 
		BOOL versionExists = NO;

		//download error
		if (data.length == 0 || connectionError) {
			//swallow 404's etc
			//and treat as un-indexed pacakge	
		} else {

			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

			foundItem = json;
			packageExists = YES;

			id allVersions = foundItem[@"versions"];
			for (id version in allVersions) {
				NSString *thisTweakVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"tweakVersion"]];
				NSString *thisiOSVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"iOSVersion"]];
				if ([thisTweakVersion isEqualToString:package.latest] && 
					[thisiOSVersion isEqualToString:iOSVersion]) {
					foundVersion = version;
					versionExists = YES;
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

		//check if iOS Version is allowed on website
		BOOL allowediOSVersion = YES;

		//check if category can be submitted on website
		BOOL allowedCategory = YES;

		//determine if 32 bit architecture
		BOOL arch32 = NO;
		NSString *archDescription = @"";
		if (sizeof(void*) == 4) {
			arch32 = YES;
			archDescription = @" 32bit";
		}

		//calculate status of tweak
		NSString *packageStatus = @"Unknown";
		NSString *packageStatusExplaination = @"This tweak has not been reviewed. Please submit a review if you choose to install.";
		id outcome = nil;
		if (foundVersion) { //pull exact match status from website

			outcome = foundVersion[@"outcome"];
			if (arch32) {
				outcome = foundVersion[@"outcome"][@"arch32"];
			}
			
			packageStatus = outcome[@"calculatedStatus"];

			packageStatusExplaination = [NSString stringWithFormat:
				@"This%@ package version has been marked as %@ based on feedback from users in the community. "
				"The current positive rating is %@%% with %@ working reports.", 
					archDescription,
					packageStatus,
					outcome[@"percentage"],
					outcome[@"good"]];

		} else {
			if (packageExists) {
				//check if other versions of this tweak have been reviewed against this iOS version
				for (id version in allVersions) {
					NSString *thisTweakVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"tweakVersion"]];
					NSString *thisiOSVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"iOSVersion"]];

					outcome = version[@"outcome"];
					if (arch32) {
						outcome = version[@"outcome"][@"arch32"];
					}
					
					NSString *thisStatus = outcome[@"calculatedStatus"];

					if ([thisiOSVersion isEqualToString:iOSVersion] && 
						([thisStatus isEqualToString:@"likely working"] || [thisStatus isEqualToString:@"working"])) {

						packageStatus = thisStatus;
						if ([packageStatus isEqualToString:@"working"]) { 
							//downgrade working to likely since it's an older match
							packageStatus = @"likely working";
						}

						packageStatusExplaination = [NSString stringWithFormat:
							@"A%@ review of %@ version %@ was not found, but version %@ "
							"has been marked as %@ based on feedback from users in the community. "
							"Install at your own risk, see website for further details", 
								archDescription,
								package.name,
								thisTweakVersion,
								package.latest,
								packageStatus];
						break;
					}
				}

				if ([packageStatus isEqualToString:@"Unknown"]) { 
					packageStatusExplaination = @"A matching version of this tweak for this iOS version could not be found. "
						"Please submit a review if you choose to install.";
				}
			}
		}

		//build a dict with all found properties
		NSDictionary *userInfo = @{
			@"deviceId" : deviceId, 
			@"iOSVersion" : iOSVersion,
			@"tweakCompatVersion": @"0.0.4",
			@"packageIndexed": @(packageExists),
			@"packageVersionIndexed": @(versionExists),
			@"packageStatus": packageStatus,
			@"packageStatusExplaination": packageStatusExplaination,
			@"packageId": package.id,
			@"id": package.id,
			@"name": package.name,
			@"packageName": package.name,
			@"latest": package.latest,
			@"commercial": @(package.isCommercial),
			@"category": package.section,
			@"depiction": package.shortDescription,
			@"shortDescription": package.shortDescription,
			@"iOSVersionAllowed": @(allowediOSVersion),
			@"packageCategoryAllowed": @(allowedCategory),
			@"packageInstalled": @(installed),
			@"arch32": @(arch32),
			@"repository": [package.source name],
			@"author": package.author.name,
			@"packageStatus": packageStatus,
			@"url": [NSString stringWithFormat:@"%@", url],
		};
		

		//gather user info for post to github
		NSString *userInfoJson = @"";
		NSString *userInfoBase64 = @"";
		NSError *jsonError; 
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:kNilOptions error:&jsonError];
		if (jsonData) {
			userInfoJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
			userInfoBase64 = [jsonData base64EncodedStringWithOptions:0];
		}
		
		//create message for user
		UIAlertController *results = 
			[UIAlertController 
				alertControllerWithTitle:[NSString stringWithFormat:@"Status: %@", packageStatus] 
				message:packageStatusExplaination
				preferredStyle:UIAlertControllerStyleAlert];


		//determine what buttons will be displayed
		BOOL showViewPackage = NO; //Allow the user to open in safari
		BOOL showRequestReview = NO; //Allow the user to request a review
		BOOL showAddWorkingReview = NO; //Allow to user to submit a new working review
		BOOL showAddNotWorkingReview = NO; //Allow to user to submit a new not working review

		showAddNotWorkingReview = YES; //always allow not working review
		if (installed) {
			showAddWorkingReview = YES; //can only submit working review if tweak is installed
		}
		if (packageExists) {
			showViewPackage = YES;
		} else {
			showRequestReview = YES;
		}
		NSString *baseURI = @"https://jlippold.github.io/tweakCompatible/";

		if (showViewPackage) {
			[results addAction:
				[UIAlertAction actionWithTitle:@"More information" 
				style:UIAlertActionStyleDefault
				handler:^(UIAlertAction * action) {
					[[UIApplication sharedApplication] 
						openURL:[NSURL URLWithString:[NSString stringWithFormat:
									@"%@package.html#!/%@/details/%@", 
									baseURI, 
									package.id,
									userInfoBase64
					]]];
				}]];
		}

		if (showAddWorkingReview) {
			[results addAction:
				[UIAlertAction actionWithTitle:@"This package works!" 
				style:UIAlertActionStyleDefault
				handler:^(UIAlertAction * action) {
					[[UIApplication sharedApplication] 
						openURL:[NSURL URLWithString:[NSString stringWithFormat:
									@"%@submit.html#!/%@/working/%@", 
									baseURI, 
									package.id,
									userInfoBase64
					]]];
				}]];
		}

		if (showAddNotWorkingReview) {
			[results addAction:
				[UIAlertAction actionWithTitle:@"This package doesn't work!" 
				style:UIAlertActionStyleDefault
				handler:^(UIAlertAction * action) {
					[[UIApplication sharedApplication] 
						openURL:[NSURL URLWithString:[NSString stringWithFormat:
									@"%@submit.html#!/%@/notworking/%@", 
									baseURI, 
									package.id,
									userInfoBase64
					]]];
				}]];
		}

		if (showRequestReview) {
			//tbd
		}

		//close button
		[results addAction:
			[UIAlertAction actionWithTitle:@"Close" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {}]];

		[self.navigationController presentViewController:results animated:YES completion:nil];
		
	}];
}


%end


%hook CyteWebViewController
- (BOOL) _allowJavaScriptPanel {
	return YES;
}
%end

%hook CyteWebView
- (void)webView:(UIWebView *)webView didFinishLoadForFrame:(id)frame {
	%orig;

				NSString *injection = @""
				"if (document.getElementById('actions')) {"
					"if (!document.getElementById('tweak')) {"
						"var a = document.createElement('A'); "
						"a.id = 'tweak';"
						"a.href = 'https://jlippold.github.io/tweakCompatible/';"
						"a.innerHTML = \"<img class='icon' src='settings.png'> "
						"<div><div><label><p>COMPATIBLE!"
						"</p></label></div></div>\";"
						"document.getElementById('actions').appendChild(a)"
					"}"
				"}";
	[webView stringByEvaluatingJavaScriptFromString:injection];	
}

%end


