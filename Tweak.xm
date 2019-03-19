#define RESOURCE_PATH @"/Library/Application Support/bz.jed.tweakcompatible.bundle"
#define SETTINGS_PATH @"/var/mobile/Library/Preferences/bz.jed.tweakcompatible.prefbundle.plist"

#import "CydiaHeaders/CYPackageController.h"
#import "CydiaHeaders/CyteWebView.h"
#import "CydiaHeaders/CydiaWebViewController.h"
#import "CydiaHeaders/CyteWebViewController.h"
#import "CydiaHeaders/MIMEAddress.h"
#import "CydiaHeaders/Package.h"
#import "CydiaHeaders/PackageCell.h"
#import "CydiaHeaders/PackageListController.h"
#import "CydiaHeaders/PackageSettingsController.h"
#import "CydiaHeaders/Database.h"
#import "CydiaHeaders/Source.h"
#import "CydiaHeaders/SourcesController.h"
#import "CydiaHeaders/CydiaDelegate.h"
#import <sys/utsname.h> 
#import <UIKit/UIAlertView+Private.h>

Package *package;

NSMutableDictionary *all_packages;
UIBarButtonItem *btnStatus;

NSString *workingURL = nil;
NSString *notWorkingURL = nil;
NSString *tweakURL = nil;
NSString *detailedStatus;

UIColor *redColor;
UIColor *greenColor;
UIColor *blueColor;
UIColor *yellowColor;
UIColor *backgroundColor;
UIColor *navigationBarColor;
UIColor *titleColor;

//settings
BOOL useIcons;
BOOL hideUnknown;
NSString *overrideVersion;
NSMutableDictionary *allItems;


static void loadPrefs() {
	NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
	useIcons = [settings objectForKey:@"showIcon"] ? [[settings objectForKey:@"showIcon"] boolValue] : YES;
	hideUnknown = [settings objectForKey:@"hideUnknown"] ? [[settings objectForKey:@"hideUnknown"] boolValue] : NO;
	overrideVersion = [settings objectForKey:@"iOSVersion"] ? [settings objectForKey:@"iOSVersion"] : @"";

	if ([overrideVersion isEqualToString:@""]) {
		overrideVersion = [[UIDevice currentDevice] systemVersion];
	}
	
	//NSLog(@"darkMode: %d", darkMode);
	//NSLog(@"startMinimized: %d", startMinimized);
	//NSLog(@"useIcons: %d", useIcons);
	//NSLog(@"overrideVersion: %@", overrideVersion);
	
}

static void fullList() {
	if (!all_packages) {
		all_packages = [[NSMutableDictionary alloc] init];
		NSURL *url =  [NSURL URLWithString:[NSString 
										stringWithFormat:@"https://jlippold.github.io/tweakCompatible/json/iOS/%@.json", 
											overrideVersion
										]];
		NSURLRequest *request = [[NSURLRequest alloc] initWithURL:url];
			[NSURLConnection sendAsynchronousRequest:request queue:[NSOperationQueue mainQueue] completionHandler:^(NSURLResponse* response, NSData* data, NSError* error) {
			if (data) {
				NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

				if (!all_packages) {
					all_packages = [[NSMutableDictionary alloc] init];
				}
				for (id package in json[@"packages"]) {
					NSString *packageId = [NSString stringWithFormat:@"%@", [package objectForKey:@"id"]];
					NSData *packageData = [NSJSONSerialization dataWithJSONObject:package options:kNilOptions error:nil];
					
					if ( ![[all_packages allKeys] containsObject:packageId] ) {
						[all_packages setObject:packageData forKey:packageId];
					}
				}
			}
			NSLog(@"Package list count: %lu", (long)[[all_packages allKeys] count]);
		}];
	}
}

%ctor {
    loadPrefs();
    CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)loadPrefs, CFSTR("bundleID/saved"), NULL, CFNotificationSuspensionBehaviorCoalesce);

    fullList();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, (CFNotificationCallback)fullList, CFSTR("bundleID/saved"), NULL, CFNotificationSuspensionBehaviorCoalesce);
}

%hook PackageCell

/*
%new - (void)layoutSubviews {
	if (self.imageView.superview.bounds.size.height < 38) { //search view
		self.imageView.frame = CGRectMake(16,16,16,16);
	} else {
		cell.imageView.frame = CGRectMake(28,28,16,16);
		cell.imageView.bounds = CGRectMake(28,28,16,16);
		self.imageView.contentMode = UIViewContentModeScaleAspectFit;
	}
}
*/

%end

%hook PackageListController


%new - (void) tableView:(UITableView *)tableView willDisplayCell:(PackageCell *) cell forRowAtIndexPath:(NSIndexPath *)indexPath {
		
		if (!useIcons) {
			return;
		}
		Database *database = MSHookIvar<Database *>(self, "database_");
		Package *package([database packageWithName:[[self packageAtIndexPath:indexPath] id]]);

		if (!package || !cell || !all_packages) {
			return;
		}

		if ([[all_packages allKeys] count] < 1) {
			return;
		}
		
		NSBundle *bundle = [[NSBundle alloc] initWithPath:RESOURCE_PATH];
		NSString *imagePath = [bundle pathForResource:@"unknown" ofType:@"png"];
		NSString *packageId = [NSString stringWithFormat:@"%@", package.id];
		
		if ( [[all_packages allKeys] containsObject:packageId] ) {

			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:[all_packages objectForKey:packageId] options:0 error:NULL];

			for (id version in json[@"versions"]) {
				
				NSString *thisTweakVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"tweakVersion"]];
				NSString *thisiOSVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"iOSVersion"]];
				NSString *packageVersion = package.latest;

				if ([thisTweakVersion isEqualToString:packageVersion] && [thisiOSVersion isEqualToString:overrideVersion]) {
					NSString *status = version[@"outcome"][@"calculatedStatus"];
					status = [[status stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
					imagePath = [bundle pathForResource:status ofType:@"png"];
					break;
				}
			}
		}

		UIImageView *iv;
		UIImage *icon = [UIImage imageWithContentsOfFile:imagePath];
		if ((iv = [cell viewWithTag:2727])) {
			iv.image = icon;
		} 

		else if ((iv = [[UIImageView alloc] initWithImage:icon])) {

			iv.tag = 2727;
			//NSLog(@"height: %ld", (long)cell.bounds.size.height);
			//NSLog(@"%@", NSStringFromClass(cell));

			if ([imagePath isEqualToString:[bundle pathForResource:@"unknown" ofType:@"png"]] && hideUnknown) {
				return;
			}

			if ((long)cell.bounds.size.height == 38) { //search view
				iv.frame = CGRectMake(16,16,16,16);
			} else {
				iv.frame = CGRectMake(28,28,16,16);
			}
			
			iv.autoresizingMask = UIViewAutoresizingFlexibleRightMargin | UIViewAutoresizingFlexibleTopMargin;
			iv.contentMode = UIViewContentModeScaleAspectFit;
			[cell.contentView addSubview:iv];	
		}
}


%end

%hook SourcesController

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger) section {
	if (section == 0) {
		return 2; 	
	} else {
		return %orig;
	}
}


- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row == 1) {
		UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"tweakCompat"];
		
		if (cell == nil) {
			cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"tweakCompat"];

			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"Tweak Compatible";
			cell.detailTextLabel.text = @"View tweak compatible website";
			cell.detailTextLabel.textColor = [UIColor grayColor];
			[cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
			
			NSBundle *bundle = [[NSBundle alloc] initWithPath:RESOURCE_PATH];
			NSString *path = [bundle pathForResource:@"working" ofType:@"png"];
			UIImage *theImage = [UIImage imageWithContentsOfFile:path];
			cell.imageView.image = theImage;

			CGSize itemSize = CGSizeMake(30, 30);
			UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
			CGRect imageRect = CGRectMake(0, 0, itemSize.width, itemSize.height);
			[cell.imageView.image drawInRect:imageRect];
			cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();	
			
			
		}
		return cell;
	}
	return %orig;
}


%new - (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	NSString *url = [[request URL] absoluteString];
	//HBLogDebug(@"URL: %@",url);

	if ([url containsString:@"/tweakCompatible/package.html"]) {

		NSString *packageName = [url stringByReplacingOccurrencesOfString:@"https://jlippold.github.io/tweakCompatible/package.html#!/" withString:@""];
		packageName = [packageName componentsSeparatedByString:@"/"][0];
		Database *database = MSHookIvar<Database *>(self, "database_");
		Package *package = [database packageWithName:packageName];
		//HBLogDebug(@"PackageName: %@", packageName);
		if (!package) {
			url = [url stringByReplacingOccurrencesOfString:@"/package.html" withString:@"/cydia.html"];
			UIViewController *webViewController = [[UIViewController alloc] init];
			UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: webView.frame];
			uiWebView.scrollView.contentInset = UIEdgeInsetsMake(0,0,120,0);
			[uiWebView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: url]]];
			[webViewController.view addSubview: uiWebView];
			uiWebView.delegate = self;
			
			[self.navigationController pushViewController: webViewController animated:YES];
		} else {
			CYPackageController *view = [[%c(CYPackageController) alloc] initWithDatabase:database forPackage:[package id] withReferrer:@""];
			[view setDelegate:self.delegate];
			[[self navigationController] pushViewController:view animated:YES];
		}
		return NO;
	}

	if ([url hasPrefix:@"https://cydia.saurik.com/api/share#?source"]) {
		
		UIApplication *application = [UIApplication sharedApplication];
		[application openURL:[request URL] options:@{} completionHandler:nil];

		return NO;
	}
	
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row == 1) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		UIViewController *webViewController = [[UIViewController alloc] init];
		UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: tableView.frame];
		uiWebView.delegate = self;
		uiWebView.scrollView.contentInset = UIEdgeInsetsMake(0,0,120,0);
		webViewController.title = @"tweakCompatible";
		[uiWebView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"https://jlippold.github.io/tweakCompatible/#cydia"]]];
		[webViewController.view addSubview: uiWebView];
		
		[self.navigationController pushViewController: webViewController animated:YES];

	} else {
		%orig;
	}
}

%end

%hook CYPackageController 

- (void)applyRightButton {
	%orig;

	if (self.rightButton && !self.isLoading) {
		package = MSHookIvar<Package *>(self, "package_");	
		[self performSelector:@selector(createToolbar)];	
		[self performSelector:@selector(pullPackageInfo)];	
	}
}

- (void)viewWillAppear:(BOOL)animated {
	%orig;
    [self.navigationController setToolbarHidden:NO animated:NO];
}

- (void)viewWillDisappear:(BOOL)animated {
    [self.navigationController setToolbarHidden:YES animated:NO];
}

%new - (void)createToolbar {

	redColor = [UIColor colorWithRed:0.894 green:0.302 blue:0.259 alpha:1];
	greenColor = [UIColor colorWithRed:0.224 green:0.792 blue:0.459 alpha:1];
	blueColor = [UIColor colorWithRed:0.227 green:0.6 blue:0.847 alpha:1];
	yellowColor = [UIColor colorWithRed:0.941 green:0.765 blue:0.188 alpha:1];
	backgroundColor = [UIColor colorWithRed:0.953 green:0.949 blue:0.969 alpha:1];
	navigationBarColor = [UIColor colorWithRed:0.969 green:0.969 blue:0.976 alpha:1];
	titleColor = self.navigationController.navigationBar.tintColor;

	self.navigationController.toolbar.translucent = YES;
	self.navigationController.toolbar.backgroundColor = self.navigationController.navigationBar.backgroundColor;
	self.navigationController.toolbar.tintColor = self.navigationController.navigationBar.tintColor;
    self.navigationController.toolbar.barTintColor = self.navigationController.navigationBar.barTintColor;
    
	[self.navigationController setToolbarHidden:NO animated:NO];
    
    UIBarButtonItem *search = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemSearch target:self action:@selector(_loadInfoBtn:)];
	UIBarButtonItem *submit = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(_addReview:)];
    btnStatus = [[UIBarButtonItem alloc] initWithTitle:@"Unknown" style: UIBarButtonItemStyleBordered target:self action:@selector(_showDetails:)];
	UIBarButtonItem *info = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemOrganize target:self action:@selector(_showDetails:)];

	info.tintColor = blueColor;
	submit.tintColor = blueColor;
	search.tintColor = blueColor;
	btnStatus.tintColor = titleColor;

    UIBarButtonItem *flexibleSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
	//UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithTitle:@" " style: UIBarButtonItemStyleBordered target:self action:nil];
	UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
	fixedSpace.width = 22;
    self.toolbarItems = [NSArray arrayWithObjects:info, btnStatus, flexibleSpace, search, fixedSpace, submit, nil];
 
}

%new - (void)_hide:(UIBarButtonItem *)sender {
	[self.navigationController setToolbarHidden:YES animated:NO];
}

%new - (void)_show:(UIBarButtonItem *)sender {
	[self.navigationController setToolbarHidden:NO animated:NO];
}


%new - (void)_markWorking {
	if (workingURL != nil) {
		NSURL *url = [NSURL URLWithString:workingURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"You can't mark this as working, unless you install it first"];
	}
}

%new - (void)_markNotWorking {
	if (notWorkingURL != nil) {
		NSURL *url = [NSURL URLWithString:notWorkingURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"An error occured while marking this tweak"];
	}
}

%new - (void)_loadInfoBtn:(UIBarButtonItem *)sender {
	if (tweakURL != nil) {
		NSURL *url = [NSURL URLWithString:tweakURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"There is no additional information available for this tweak"];
	}
}
%new - (void)_loadInfoBtn {
	if (tweakURL != nil) {
		NSURL *url = [NSURL URLWithString:tweakURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"There is no additional information available for this tweak"];
	}
}

%new - (void)_versions {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible"
                                                                   message:@"Status against other major iOS versions"
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
	for (NSString *iosVersion in [allItems allKeys]) {
		UIAlertAction *version = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"iOS %@: %@", iosVersion, allItems[iosVersion]]
																		style:UIAlertActionStyleDefault
																	handler:^(UIAlertAction * action) {}];
		[alert addAction:version];
	}
	
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Close"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {}];
	[alert addAction:cancel];
	alert.popoverPresentationController.sourceView = self.view;
	[self.navigationController presentViewController:alert animated:YES completion:nil];
}


%new - (void)_showDetails:(UIBarButtonItem *)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Status"
                                                                   message:detailedStatus
                                                            preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *versions = [UIAlertAction actionWithTitle:[NSString stringWithFormat:@"Show Other Versions (%lu)", (unsigned long)[[allItems allKeys] count]]
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
		[self performSelector:@selector(_versions)];	
	}];
    UIAlertAction *reviews = [UIAlertAction actionWithTitle:@"Show Reviews"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
		[self performSelector:@selector(_loadInfoBtn)];	
	}];
	UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Close"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {}];
	if ([[allItems allKeys] count] > 1) {
		[alert addAction:versions];
	}
	if (tweakURL) {
		[alert addAction:reviews];
	}
	[alert addAction:ok];
	alert.popoverPresentationController.sourceView = self.view;
	[self.navigationController presentViewController:alert animated:YES completion:nil];

}

%new - (void)_addReview:(UIBarButtonItem *)sender {
    UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Submit Review"
                                                                   message:@""
                                                            preferredStyle:UIAlertControllerStyleActionSheet];
    
    UIAlertAction *working = [UIAlertAction actionWithTitle:@"Working"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
		[self performSelector:@selector(_markWorking)];	
	}];
    UIAlertAction *notworking = [UIAlertAction actionWithTitle:@"Not working"
                                                            style:UIAlertActionStyleDefault
                                                          handler:^(UIAlertAction * action) {
		[self performSelector:@selector(_markNotWorking)];	
	}];
	UIAlertAction *cancel = [UIAlertAction actionWithTitle:@"Cancel"
                                                            style:UIAlertActionStyleDestructive
                                                          handler:^(UIAlertAction * action) {}];
	[alert addAction:working];
	[alert addAction:notworking];
	[alert addAction:cancel];
	alert.popoverPresentationController.sourceView = self.view;
	[self.navigationController presentViewController:alert animated:YES completion:nil];

}

%new - (void)pullPackageInfo {

	detailedStatus = @"A matching version of this tweak for this iOS version could not be found. "
					"Please submit a review if you choose to install.";

	if (!package.id) {
		return;
	}

	//pull package info
	NSString *packageUrl = [NSString stringWithFormat:@"http://cydia.saurik.com/package/%@/", package.id];	
	NSString *packageVersion = package.latest;
	NSString *packageVersionInstalled = @"";
	NSString *packageName = package.name;
	NSString *packageId = [NSString stringWithFormat:@"%@", package.id];
	NSString *packageDescription = package.shortDescription;
	NSString *packageSection = package.section;
	NSString *packageRepository = [NSString stringWithFormat:@"%@", [package.source name]];
	NSString *packageAuthor = [NSString stringWithFormat:@"%@", package.author.name];
	
	NSString *systemVersion = [[UIDevice currentDevice] systemVersion];

	NSURL *url = [NSURL URLWithString:[NSString 
									stringWithFormat:@"https://jlippold.github.io/tweakCompatible/json/packages/%@.json", 
									package.id]];

	NSData *data = [NSData dataWithContentsOfURL:url];

	//Load up other ios versions for scroll view
	NSMutableArray *allIOSVersions = [[NSMutableArray alloc] init];
	[allIOSVersions addObject:systemVersion];

	if (data) {
		NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];
		for (id version in json[@"versions"]) {
			NSString *thisTweakVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"tweakVersion"]];
			NSString *thisiOSVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"iOSVersion"]];
			NSString *thisMajor = [thisiOSVersion componentsSeparatedByString:@"."][0];
			NSString *myMajor = [systemVersion componentsSeparatedByString:@"."][0];

			if ([thisTweakVersion isEqualToString:packageVersion] && ![thisiOSVersion isEqualToString:systemVersion] && [myMajor isEqualToString:thisMajor]) {
				[allIOSVersions addObject:thisiOSVersion];
			}
		}
	}
	
	BOOL packageInstalled = NO;
	if (package.installed) {
		packageInstalled = YES;
		packageVersionInstalled = [NSString stringWithFormat:@"%@", package.installed];
	}
	BOOL commercial = NO;
	if (package.isCommercial) {
		commercial = YES;
	}
	package = nil;
	
	//calc device type: https://stackoverflow.com/a/20062141
    struct utsname systemInfo;
    uname(&systemInfo);
    NSString *deviceId = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];

	//determine if 32 bit architecture
	BOOL arch32 = NO;
	NSString *archDescription = @"";
	if (sizeof(void*) == 4) {
		arch32 = YES;
		archDescription = @" 32bit";
	}

	id foundItem = nil; //package on website
	id allVersions = nil; //all versions on website
	id foundVersion = nil; //version on website
	
	BOOL packageExists = NO; 
	BOOL versionExists = NO;

	int i = 0;
	NSDictionary *userInfo;
	allItems = [[NSMutableDictionary alloc] init]; 

	for (i = [allIOSVersions count] - 1; i >= 0; i--) {
		
		foundVersion = nil;
		NSString *iOSVersion = [allIOSVersions objectAtIndex:i];

		// NSLog(@"tweakCompat iOSVersion: %@", iOSVersion);
		NSString *packageStatus = @"Unknown";
		NSString *packageStatusExplaination = @"This tweak has not been reviewed. Please submit a review if you choose to install.";

		if (data) {
			NSDictionary *json = [NSJSONSerialization JSONObjectWithData:data options:0 error:NULL];

			foundItem = json;
			packageExists = YES;

			id allVersions = foundItem[@"versions"];
			for (id version in allVersions) {
				NSString *thisTweakVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"tweakVersion"]];
				NSString *thisiOSVersion = [NSString stringWithFormat:@"%@", [version objectForKey:@"iOSVersion"]];
				if ([thisTweakVersion isEqualToString:packageVersion] && 
					[thisiOSVersion isEqualToString:iOSVersion]) {
					foundVersion = version;
					versionExists = YES;
					break;
				}
			}
		}

		//calculate status of tweak
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
								packageName,
								thisTweakVersion,
								packageVersion,
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

		if (!allItems[iOSVersion]) {
			allItems[iOSVersion] = packageStatus; 
		}
		
		//Mini status
		if (foundVersion && [overrideVersion isEqualToString:iOSVersion]) {
			
			btnStatus.title = packageStatus;
		
			detailedStatus = [NSString stringWithFormat:@"iOS %@ %@: %@", iOSVersion, packageStatus, packageStatusExplaination];
			if ([packageStatus isEqualToString:@"Working"]) {
				btnStatus.tintColor = greenColor;
			}
			if ([packageStatus isEqualToString:@"Likely working"]) {
				btnStatus.tintColor = yellowColor;
			}
			if ([packageStatus isEqualToString:@"Not working"]) {
				btnStatus.tintColor = redColor;
			}
		}

		//build a dict with all found properties
		userInfo = @{
			@"deviceId" : deviceId, 
			@"iOSVersion" : systemVersion,
			@"tweakCompatVersion": @"0.1.5",
			@"packageIndexed": @(packageExists),
			@"packageVersionIndexed": @(versionExists),
			@"packageStatus": packageStatus,
			@"packageStatusExplaination": packageStatusExplaination,
			@"packageId": packageId,
			@"id": packageId,
			@"name": packageName,
			@"packageName": packageName,
			@"latest": packageVersion,
			@"installed": packageVersionInstalled,
			@"commercial": @(commercial),
			@"category": packageSection,
			@"shortDescription": packageDescription,
			@"packageInstalled": @(packageInstalled),
			@"arch32": @(arch32),
			@"repository": packageRepository,
			@"author": packageAuthor,
			@"url": packageUrl
		};


	}


	//gather user info for post to github
	NSError *error; 
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:kNilOptions error:&error];
	NSString *userInfoJson = @"";
	NSString *userInfoBase64 = @"";
	if(!jsonData && error){
		return;
	} else {
		userInfoJson = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
		userInfoBase64 = [jsonData base64EncodedStringWithOptions:0];
	}

	//determine what buttons will be displayed
	BOOL showViewPackage = NO; //Allow the user to open in safari
	BOOL showRequestReview = NO; //Allow the user to request a review
	BOOL showAddWorkingReview = NO; //Allow to user to submit a new working review
	BOOL showAddNotWorkingReview = NO; //Allow to user to submit a new not working review

	showAddNotWorkingReview = YES; //always allow not working review
	if ([[userInfo objectForKey:@"packageInstalled"] boolValue] == true) {
		showAddWorkingReview = YES; //can only submit working review if tweak is installed
	}

	if ([[userInfo objectForKey:@"packageIndexed"] boolValue] == true) {
		showViewPackage = YES;
	} else {
		showRequestReview = YES;
	}
	tweakURL = nil;
	workingURL = nil;
	notWorkingURL = nil;
	
	NSString *baseURI = @"https://jlippold.github.io/tweakCompatible/";
	if (showViewPackage) {
		tweakURL = [NSString stringWithFormat:@"%@cydia.html#!/%@/details/%@", 
				baseURI, userInfo[@"packageId"], userInfo[@"packageVersion"]];
	}

	if (showAddWorkingReview) {
		workingURL = [NSString stringWithFormat:@"%@submit.html#!/%@/working/%@", 
				baseURI, userInfo[@"packageId"], userInfoBase64];
	}

	if (showAddNotWorkingReview) {
		notWorkingURL = [NSString stringWithFormat:@"%@submit.html#!/%@/notworking/%@", 
			baseURI, userInfo[@"packageId"], userInfoBase64];
	}
	
}


%new - (void)showAlert:(NSString *)message {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible" 
	message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	[alert addAction:ok];
	alert.popoverPresentationController.sourceView = self.view;
	[self presentViewController:alert animated:YES completion:nil];
}
%end



