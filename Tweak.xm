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

UIView *overlay;
UIView *miniOverlay;
UITextView *miniTextView;
UIImageView *miniImageView;
UIScrollView *scrollView;
UIPageControl *pageControl;
NSMutableDictionary *all_packages;

NSString *workingURL = nil;
NSString *notWorkingURL = nil;
NSString *tweakURL = nil;

//settings
BOOL darkMode;
BOOL startMinimized;
BOOL useIcons;
BOOL hideUnknown;
NSString *overrideVersion;

static void loadPrefs() {
	NSMutableDictionary *settings = [[NSMutableDictionary alloc] initWithContentsOfFile:SETTINGS_PATH];
	darkMode = [settings objectForKey:@"dark"] ? [[settings objectForKey:@"dark"] boolValue] : NO;
	startMinimized = [settings objectForKey:@"mini"] ? [[settings objectForKey:@"mini"] boolValue] : NO;
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

		if (!package || !cell) {
			return;
		}

		if ([[all_packages allKeys] count] < 1) {
			return;
		}
		
		NSBundle *bundle = [[[NSBundle alloc] initWithPath:RESOURCE_PATH] autorelease];
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

		UIImageView *iv = [[[UIImageView alloc] initWithImage:[UIImage imageWithContentsOfFile:imagePath]] autorelease];
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
		
		iv.autoresizingMask = UIViewAutoresizingFlexibleLeftMargin | UIViewAutoresizingFlexibleRightMargin;
		iv.contentMode = UIViewContentModeScaleAspectFit;
		[cell.contentView addSubview:iv];	



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
			cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:@"tweakCompat"] autorelease];

			cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
			cell.textLabel.text = @"Tweak Compatible";
			cell.detailTextLabel.text = @"View tweak compatible website";
			cell.detailTextLabel.textColor = [UIColor grayColor];
			[cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
			
			NSBundle *bundle = [[[NSBundle alloc] initWithPath:RESOURCE_PATH] autorelease];
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
			UIViewController *webViewController = [[UIViewController alloc] autorelease];
			UIWebView *uiWebView = [[[UIWebView alloc] initWithFrame: webView.frame] autorelease];
			uiWebView.scrollView.contentInset = UIEdgeInsetsMake(0,0,120,0);
			[uiWebView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: url]]];
			[webViewController.view addSubview: uiWebView];
			uiWebView.delegate = self;
			
			[self.navigationController pushViewController: webViewController animated:YES];
		} else {
			CYPackageController *view = [[[%c(CYPackageController) alloc] initWithDatabase:database forPackage:[package id] withReferrer:@""] autorelease];
			[view setDelegate:self.delegate];
			[[self navigationController] pushViewController:view animated:YES];
		}
		return NO;
	}

	if ([url hasPrefix:@"https://cydia.saurik.com/api/share#?source"]) {
		
		UIApplication *application = [UIApplication sharedApplication];
		[application openURL:[request URL] options:@{} completionHandler:nil];

/*
		NSString *href = [url stringByReplacingOccurrencesOfString:@"tweakcompat://repo/?" withString:@""];

		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible" 
			message:@"The repo address will be copied to the clipboard" preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *ok = [UIAlertAction actionWithTitle:@"Add source" style:UIAlertActionStyleDefault handler:^(UIAlertAction * action) {
			UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
			pasteboard.string = href;
            [self performSelector:@selector(showAddSourcePrompt)];	
        }];
		UIAlertAction* cancel = [UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleDefault handler:nil];
		[alert addAction:ok];
		[alert addAction:cancel];
		[self presentViewController:alert animated:YES completion:nil];
*/
		return NO;
	}
	
	return YES;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row == 1) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		UIViewController *webViewController = [[UIViewController alloc] autorelease];
		UIWebView *uiWebView = [[[UIWebView alloc] initWithFrame: tableView.frame] autorelease];
		uiWebView.delegate = self;
		uiWebView.scrollView.contentInset = UIEdgeInsetsMake(0,0,120,0);

		[uiWebView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"https://jlippold.github.io/tweakCompatible/#cydia"]]];
		[webViewController.view addSubview: uiWebView];
		
		[self.navigationController pushViewController: webViewController animated:YES];

	} else {
		%orig;
	}
}

%end

%hook CYPackageController 

%new - (void)scrollViewDidScroll:(UIScrollView *)sv {
    float fractionalPage = scrollView.contentOffset.x / scrollView.frame.size.width;
    NSInteger page = lround(fractionalPage);
    pageControl.currentPage = page;
}

- (void)applyRightButton {
	%orig;

	if (self.rightButton && !self.isLoading) {
		package = MSHookIvar<Package *>(self, "package_");	

		if ([self.view viewWithTag:987] == nil) {
			[self performSelector:@selector(addToolbar)];	
			[self performSelector:@selector(pullPackageInfo)];	
		}
	}
}

%new - (void)addToolbar {
	overlay = [[UIView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 160, [[UIScreen mainScreen] bounds].size.width, 160)];

	overlay.tag = 987;
	overlay.hidden = YES;

	miniOverlay = [[UIView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 80, [[UIScreen mainScreen] bounds].size.width, 80)];
	
	if (darkMode) {
		overlay.backgroundColor = [UIColor colorWithRed:0.18 green:0.20 blue:0.20 alpha:1.0];
		miniOverlay.backgroundColor = [UIColor colorWithRed:0.18 green:0.20 blue:0.20 alpha:1.0];
	} else {
		overlay.backgroundColor = [UIColor whiteColor];
		miniOverlay.backgroundColor = [UIColor whiteColor];
	}
	
	miniTextView = [[UITextView alloc] init];
	miniTextView.text = @"";	 	
	miniTextView.editable = NO;
	miniTextView.backgroundColor = [UIColor clearColor];
	[miniTextView setUserInteractionEnabled:NO];
	[miniTextView setFont:[UIFont fontWithName:@"Helvetica" size:14]];
	miniTextView.frame = CGRectMake(20, -2, [[UIScreen mainScreen] bounds].size.width, 80);
	miniTextView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
	[miniOverlay addSubview:miniTextView];

	NSBundle *bundle = [[[NSBundle alloc] initWithPath:RESOURCE_PATH] autorelease];
	miniImageView = [[UIImageView alloc] init];
	miniImageView.image = [UIImage imageWithContentsOfFile:[bundle pathForResource:@"unknown" ofType:@"png"]];
	miniImageView.frame = CGRectMake(4, 4, 24, 24);
	[miniOverlay addSubview:miniImageView];

	miniOverlay.hidden = YES;

	UISwipeGestureRecognizer *swipeUp = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_show:)];
	swipeUp.direction = UISwipeGestureRecognizerDirectionUp;
	[miniOverlay addGestureRecognizer:swipeUp];

	UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_show:)];
	[miniOverlay addGestureRecognizer:singleFingerTap];

	UISwipeGestureRecognizer *swipeDown = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(_hide:)];
	swipeDown.direction = UISwipeGestureRecognizerDirectionDown;
	[overlay addGestureRecognizer:swipeDown];
	

	UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil ];

	UIToolbar *bar = [[UIToolbar alloc] init];
	[bar setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

	bar.clipsToBounds = YES;
	bar.frame = CGRectMake(0, -4, [[UIScreen mainScreen] bounds].size.width, 40);
	
	UIBarButtonItem *tweakWorking = [[UIBarButtonItem alloc] initWithTitle:@"Works" style:UIBarButtonItemStylePlain target:self action:@selector(_markWorking:)];
	UIBarButtonItem *tweakNotWorking = [[UIBarButtonItem alloc] initWithTitle:@"Broken" style:UIBarButtonItemStylePlain target:self action:@selector(_markNotWorking:)];
	UIBarButtonItem *tweakInfo = [[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStylePlain target:self action:@selector(_loadInfo:)];
	UIBarButtonItem *tweakHide = [[UIBarButtonItem alloc] initWithTitle:@"Hide" style:UIBarButtonItemStylePlain target:self action:@selector(_hide:)];
	
	if (darkMode) {
		UIColor *dark = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
		miniTextView.textColor = dark;
		[tweakWorking setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: dark, NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
		[tweakNotWorking setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: dark, NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
		[tweakInfo setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: dark, NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
		[tweakHide setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys: dark, NSForegroundColorAttributeName,nil] forState:UIControlStateNormal];
	}

	NSArray *btn = [NSArray arrayWithObjects: tweakWorking, flex, tweakNotWorking, flex, tweakInfo, nil];
	[bar setItems:btn animated:NO];

	self.webView.scrollView.contentInset = UIEdgeInsetsMake(85,0,160,0);

	scrollView = [[UIScrollView alloc] initWithFrame:CGRectMake(0, 22, [[UIScreen mainScreen] bounds].size.width, 90)];
	scrollView.pagingEnabled = YES;
	scrollView.showsHorizontalScrollIndicator = NO;
	scrollView.delegate = self;

	UITapGestureRecognizer *singleFingerTap2 = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(_hide:)];
	[scrollView addGestureRecognizer:singleFingerTap2];

	pageControl = [[UIPageControl alloc] initWithFrame:CGRectMake(0, 97, [[UIScreen mainScreen] bounds].size.width, 10)];

	if (darkMode) {
		pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
		pageControl.currentPageIndicatorTintColor = [UIColor whiteColor];
	} else {
		pageControl.pageIndicatorTintColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];;
		pageControl.currentPageIndicatorTintColor = [UIColor blackColor];
	}
	pageControl.currentPage = 0;
	pageControl.hidden = YES;
	
	[overlay addSubview:scrollView];
	[overlay addSubview:bar];
	[overlay addSubview:pageControl];

	UIView *topBorder = [UIView new];

	topBorder.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];;
	topBorder.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 1);
	[overlay addSubview:topBorder];

	UIView *miniTopBorder = [UIView new];

	miniTopBorder.backgroundColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];;
	miniTopBorder.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 1);
	[miniOverlay addSubview:miniTopBorder];

	[self.view addSubview:overlay];
	[self.view addSubview:miniOverlay];
}

%new - (void)_hide:(UIBarButtonItem *)sender {
	overlay.hidden = YES;
	miniOverlay.hidden = NO;
}

%new - (void)_show:(UIBarButtonItem *)sender {
	overlay.hidden = NO;
	miniOverlay.hidden = YES;
}


%new - (void)_markWorking:(UIBarButtonItem *)sender {
	if (workingURL != nil) {
		NSURL *url = [NSURL URLWithString:workingURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"You can't mark this as working, unless you install it first"];
	}
}

%new - (void)_markNotWorking:(UIBarButtonItem *)sender {
	if (notWorkingURL != nil) {
		NSURL *url = [NSURL URLWithString:notWorkingURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"An error occured while marking this tweak"];
	}
}

%new - (void)_loadInfo:(UIBarButtonItem *)sender {
	if (tweakURL != nil) {
		NSURL *url = [NSURL URLWithString:tweakURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		[self performSelector:@selector(showAlert:) 
			withObject:@"There is no additional information available for this tweak"];
	}
}


%new - (void)addLabels:(NSData *)data foriOSVersions:(NSMutableArray *)allIOSVersions {
	scrollView.contentSize = CGSizeMake([[UIScreen mainScreen] bounds].size.width * [allIOSVersions count], scrollView.frame.size.height);
	scrollView.backgroundColor = [UIColor clearColor];

	pageControl.numberOfPages = scrollView.contentSize.width/scrollView.frame.size.width;
	if (pageControl.numberOfPages > 1) {
		pageControl.hidden = NO;
	}
	int i = 0;
	for (i = 0; i < [allIOSVersions count]; i++) {
		NSString *iOSVersion = [allIOSVersions objectAtIndex:i];
		UITextView *textView = [[UITextView alloc] init];
		textView.text = iOSVersion;	 
		textView.tag = i+300;
		textView.editable = NO;
		textView.backgroundColor = [UIColor clearColor];
		if (darkMode) {
			textView.textColor = [UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0];
		}
		[textView setUserInteractionEnabled:NO];
		[textView setFont:[UIFont fontWithName:@"Helvetica" size:14]];
		textView.frame = CGRectMake([[UIScreen mainScreen] bounds].size.width * i, 0, [[UIScreen mainScreen] bounds].size.width, 80);
		textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);

		UIView *indicator = [UIView new];
		indicator.backgroundColor = [UIColor grayColor];
		indicator.frame = CGRectMake(([[UIScreen mainScreen] bounds].size.width * i) + 10, 88, [[UIScreen mainScreen] bounds].size.width - 20, 1);
		indicator.tag = i+400;
		
		[scrollView addSubview:textView];
		[scrollView addSubview:indicator];
	}



	
}

%new - (void)pullPackageInfo {
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

	NSURL *url =  [NSURL URLWithString:[NSString 
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
	
	[self performSelector:@selector(addLabels:foriOSVersions:) 
									withObject:data 
									withObject:allIOSVersions];


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
	
	miniTextView.text = [NSString stringWithFormat:@"TweakCompatible %@ Status: Unknown", overrideVersion];
	
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

		
		NSString *desc = [NSString stringWithFormat:@"iOS %@ %@: %@", iOSVersion, packageStatus, packageStatusExplaination];
		//NSLog(@"tweakCompat: %@", desc);
		UITextView *thisLabel = [self.view viewWithTag:i+300];

		NSMutableAttributedString *attString=[[NSMutableAttributedString alloc] initWithString:desc];

		NSRange boldRange = [desc rangeOfString:[NSString stringWithFormat:@"iOS %@ %@", iOSVersion, packageStatus]];
		NSRange regularRange = [desc rangeOfString:packageStatusExplaination];

		[attString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica-Bold" size:14.0] range:boldRange];
		[attString addAttribute:NSFontAttributeName value:[UIFont fontWithName:@"Helvetica" size:14.0] range:regularRange];
	
		UIView *indicator = [self.view viewWithTag:i+400];
		if ([packageStatus isEqualToString:@"Working"]) {
			UIColor *green = [UIColor colorWithRed:0.16 green:0.65 blue:0.27 alpha:1.0];
			indicator.backgroundColor = green;
    		[attString addAttribute:NSForegroundColorAttributeName value:green range:boldRange];
		} else if ([packageStatus isEqualToString:@"Not working"]) {
			UIColor *red = [UIColor colorWithRed:0.86 green:0.21 blue:0.27 alpha:1.0];
			indicator.backgroundColor = red;
    		[attString addAttribute:NSForegroundColorAttributeName value:red range:boldRange];
		} else if ([packageStatus isEqualToString:@"Likely working"]) {
			UIColor *yellow = [UIColor colorWithRed:1.00 green:0.76 blue:0.03 alpha:1.0];
			indicator.backgroundColor = yellow;
    		[attString addAttribute:NSForegroundColorAttributeName value:yellow range:boldRange];
		} else {
			if (darkMode) {
				[attString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0] range:boldRange];
			}
		}

		if (darkMode) {
			[attString addAttribute:NSForegroundColorAttributeName value:[UIColor colorWithRed:0.80 green:0.80 blue:0.80 alpha:1.0] range:regularRange];
		}

		[thisLabel setAttributedText:attString];

		//Mini status
		if (foundVersion && [overrideVersion isEqualToString:iOSVersion]) {
			miniTextView.text = [NSString stringWithFormat:@"TweakCompatible %@ Status: %@", overrideVersion, packageStatus];
			
			NSBundle *bundle = [[[NSBundle alloc] initWithPath:RESOURCE_PATH] autorelease];
			NSString *status = packageStatus;
			status = [[status stringByReplacingOccurrencesOfString:@" " withString:@""] lowercaseString];
			NSString *imagePath = [bundle pathForResource:status ofType:@"png"];
			miniImageView.image = [UIImage imageWithContentsOfFile:imagePath];
		}

		//build a dict with all found properties
		userInfo = @{
			@"deviceId" : deviceId, 
			@"iOSVersion" : systemVersion,
			@"tweakCompatVersion": @"0.1.0",
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
		tweakURL = [[NSString stringWithFormat:@"%@cydia.html#!/%@/details/%@", 
				baseURI, userInfo[@"packageId"], userInfo[@"packageVersion"]] retain];
	}

	if (showAddWorkingReview) {
		workingURL = [[NSString stringWithFormat:@"%@submit.html#!/%@/working/%@", 
				baseURI, userInfo[@"packageId"], userInfoBase64] retain];
	}

	if (showAddNotWorkingReview) {
		notWorkingURL = [[NSString stringWithFormat:@"%@submit.html#!/%@/notworking/%@", 
			baseURI, userInfo[@"packageId"], userInfoBase64] retain];
	}

	if (startMinimized) {
		overlay.hidden = YES;
		miniOverlay.hidden = NO;
	} else {
		overlay.hidden = NO;
		miniOverlay.hidden = YES;
	}
}


%new - (void)showAlert:(NSString *)message {
	UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible" 
	message:message preferredStyle:UIAlertControllerStyleAlert];
	UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
	[alert addAction:ok];
	[self presentViewController:alert animated:YES completion:nil];
}
%end



