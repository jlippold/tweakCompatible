#import "CydiaHeaders/CYPackageController.h"
#import "CydiaHeaders/CyteWebView.h"
#import "CydiaHeaders/CydiaWebViewController.h"
#import "CydiaHeaders/MIMEAddress.h"
#import "CydiaHeaders/Package.h"
#import "CydiaHeaders/Source.h"
#import "CydiaHeaders/SourcesController.h"
#import <sys/utsname.h> 


Package *package;

UILabel *tweakStatus;
UIView *overlay;

NSString *workingURL = nil;
NSString *notWorkingURL = nil;
NSString *tweakURL = nil;

%hook UIWebView

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
	//NSString *url = [[request URL] absoluteString];
	//if ([url containsString:@"tony"]) {
		return NO;
	//}
	//return %orig;
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
			cell.detailTextLabel.text = @"list of all compatible tweaks";
			cell.detailTextLabel.textColor = [UIColor grayColor];
			[cell.textLabel setFont:[UIFont fontWithName:@"Helvetica" size:18]];
			
			NSString *path = [[NSBundle mainBundle] pathForResource:@"folder" ofType:@"png"];
			UIImage *theImage = [UIImage imageWithContentsOfFile:path];
			cell.imageView.image = theImage;

			CGSize itemSize = CGSizeMake(30, 30);
			UIGraphicsBeginImageContextWithOptions(itemSize, NO, UIScreen.mainScreen.scale);
			CGRect imageRect = CGRectMake(0.0, 0.0, itemSize.width, itemSize.height);
			[cell.imageView.image drawInRect:imageRect];
			cell.imageView.image = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();	
		}
		return cell;
	}
	return %orig;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == 0 && indexPath.row == 1) {
		[tableView deselectRowAtIndexPath:indexPath animated:YES];

		UIViewController *webViewController = [[UIViewController alloc] init];
		UIWebView *uiWebView = [[UIWebView alloc] initWithFrame: tableView.frame];
		
		[uiWebView loadRequest:[NSURLRequest requestWithURL: [NSURL URLWithString: @"https://jlippold.github.io/tweakCompatible/#cydia"]]];
		[webViewController.view addSubview: uiWebView];
		uiWebView.scrollView.contentInset = UIEdgeInsetsMake(0,0,0,0);
		[uiWebView release];
		
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


		if ([self.view viewWithTag:987] == nil) {
			[self performSelector:@selector(addToolbar)];	

		}

		[self performSelector:@selector(pullPackageInfo)];	
		
	}
}

%new - (void)addToolbar {
		overlay = [[UIView alloc] initWithFrame:CGRectMake(0, [[UIScreen mainScreen] bounds].size.height - 150, [[UIScreen mainScreen] bounds].size.width, 150)];
		overlay.backgroundColor = [UIColor whiteColor];
		overlay.tag = 987;
		overlay.hidden = YES;
		

	    UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleExtraLight];
		UIVisualEffectView *bluredEffectView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
		bluredEffectView.frame = [UIScreen mainScreen].bounds;		
		[overlay addSubview:bluredEffectView];


		tweakStatus = [[UILabel alloc] init];
		tweakStatus.text = @"";
		tweakStatus.lineBreakMode = NSLineBreakByTruncatingTail;
		tweakStatus.numberOfLines = 3;
		tweakStatus.adjustsFontSizeToFitWidth = YES;
		tweakStatus.frame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, 70);
		[tweakStatus setFont:[UIFont fontWithName:@"Helvetica" size:14]];
	

		UIBarButtonItem *flex = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil ];

		UIToolbar *bar = [[UIToolbar alloc] init];
		[bar setBackgroundImage:[UIImage new] forToolbarPosition:UIToolbarPositionAny barMetrics:UIBarMetricsDefault];

		bar.clipsToBounds = YES;
		bar.frame = CGRectMake(0, 60, [[UIScreen mainScreen] bounds].size.width, 40);
		
		UIBarButtonItem *tweakWorking = [[UIBarButtonItem alloc] initWithTitle:@"Works" style:UIBarButtonItemStyleBordered target:self action:@selector(_markWorking:)];
		UIBarButtonItem *tweakNotWorking = [[UIBarButtonItem alloc] initWithTitle:@"Broken" style:UIBarButtonItemStyleBordered target:self action:@selector(_markNotWorking:)];
		UIBarButtonItem *tweakInfo = [[UIBarButtonItem alloc] initWithTitle:@"Info" style:UIBarButtonItemStyleBordered target:self action:@selector(_loadInfo:)];
		
		NSArray *btn = [NSArray arrayWithObjects:  tweakWorking, flex, tweakNotWorking, flex, tweakInfo, nil];
		[bar setItems:btn animated:NO];
		self.webView.scrollView.contentInset = UIEdgeInsetsMake(75,0,150,0);

		[overlay addSubview:bar];
		[overlay addSubview:tweakStatus];
		[self.view addSubview:overlay];

}

%new - (void)_markWorking:(UIBarButtonItem *)sender {
	if (workingURL != nil) {
		NSURL *url = [NSURL URLWithString:workingURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		NSString *message = @"You can't mark this as working, unless you install it first";
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible" 
		message:message preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
		[alert addAction:ok];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

%new - (void)_markNotWorking:(UIBarButtonItem *)sender {
	if (notWorkingURL != nil) {
		NSURL *url = [NSURL URLWithString:notWorkingURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		NSString *message = @"An error occured while marking this tweak";
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible" 
		message:message preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
		[alert addAction:ok];
		[self presentViewController:alert animated:YES completion:nil];

	}
}

%new - (void)_loadInfo:(UIBarButtonItem *)sender {
	if (tweakURL != nil) {
		NSURL *url = [NSURL URLWithString:tweakURL];
		[self.webView loadRequest:[NSURLRequest requestWithURL:url]];
	} else {
		NSString *message = @"There is no additional information avaialble for this tweak";
		UIAlertController *alert = [UIAlertController alertControllerWithTitle:@"tweakCompatible" 
		message:message preferredStyle:UIAlertControllerStyleAlert];
		UIAlertAction *ok = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil];
		[alert addAction:ok];
		[self presentViewController:alert animated:YES completion:nil];
	}
}

%new - (void)pullPackageInfo {
	if (!package.id) {
		return;
	}

	//pull package info
	NSString *packageUrl = [NSString stringWithFormat:@"http://cydia.saurik.com/package/%@/", package.id];	
	NSString *packageVersion = package.latest;
	NSString *packageName = package.name;
	NSString *packageId = [NSString stringWithFormat:@"%@", package.id];
	NSString *packageDescription = package.shortDescription;
	NSString *packageSection = package.section;
	NSString *packageRepository = [NSString stringWithFormat:@"%@", [package.source name]];
	NSString *packageAuthor = [NSString stringWithFormat:@"%@", package.author.name];
	BOOL packageInstalled = NO;
	if (package.installed) {
		packageInstalled = YES;
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
	NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];

	//determine if 32 bit architecture
	BOOL arch32 = NO;
	NSString *archDescription = @"";
	if (sizeof(void*) == 4) {
		arch32 = YES;
		archDescription = @" 32bit";
	}
	

	NSURL *url =  [NSURL URLWithString:[NSString stringWithFormat:@"https://jlippold.github.io/tweakCompatible/json/packages/%@.json", packageId]];
	NSData *data = [NSData dataWithContentsOfURL:url];

	id foundItem = nil; //package on website
	id allVersions = nil; //all versions on website
	id foundVersion = nil; //version on website
	
	BOOL packageExists = NO; 
	BOOL versionExists = NO;

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

	//build a dict with all found properties
	NSDictionary *userInfo = @{
		@"deviceId" : deviceId, 
		@"iOSVersion" : iOSVersion,
		@"tweakCompatVersion": @"0.0.6",
		@"packageIndexed": @(packageExists),
		@"packageVersionIndexed": @(versionExists),
		@"packageStatus": packageStatus,
		@"packageStatusExplaination": packageStatusExplaination,
		@"packageId": packageId,
		@"id": packageId,
		@"name": packageName,
		@"packageName": packageName,
		@"latest": packageVersion,
		@"commercial": @(commercial),
		@"category": packageSection,
		@"shortDescription": packageDescription,
		@"packageInstalled": @(packageInstalled),
		@"arch32": @(arch32),
		@"repository": packageRepository,
		@"author": packageAuthor,
		@"url": packageUrl
	};

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
	if (packageInstalled) {
		showAddWorkingReview = YES; //can only submit working review if tweak is installed
	}

	if (packageExists) {
		showViewPackage = YES;
	} else {
		showRequestReview = YES;
	}
	tweakURL = nil;
	workingURL = nil;
	notWorkingURL = nil;
	
	NSString *baseURI = @"https://jlippold.github.io/tweakCompatible/";
	if (showViewPackage) {
		tweakURL = [[NSString stringWithFormat:@"%@package.html#!/%@/details/%@", 
				baseURI, packageId, packageVersion] retain];
	}

	if (showAddWorkingReview) {
		workingURL = [[NSString stringWithFormat:@"%@submit.html#!/%@/working/%@", 
				baseURI, packageId, userInfoBase64] retain];
	}

	if (showAddNotWorkingReview) {
		notWorkingURL = [[NSString stringWithFormat:@"%@submit.html#!/%@/notworking/%@", 
			baseURI, packageId, userInfoBase64] retain];
	}


	tweakStatus.text = [[NSString stringWithFormat:@"Status %@: %@", 
				packageStatus, packageStatusExplaination] retain]; 
	
	overlay.hidden = NO;
}
%end



