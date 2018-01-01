#import "CydiaHeaders/CYPackageController.h"
#import "CydiaHeaders/CydiaWebViewController.h"
#import "CydiaHeaders/CyteWebView.h"
#import "CydiaHeaders/MIMEAddress.h"
#import "CydiaHeaders/Package.h"
#import "CydiaHeaders/Source.h"
#import <sys/utsname.h> 


Package *package;

%hook CYPackageController

- (BOOL) _allowJavaScriptPanel {
	return YES;
}

- (void)applyRightButton {
	%orig;

	if (self.rightButton && !self.isLoading) {
		package = MSHookIvar<Package *>(self, "package_");		
	}
}

%new - (void)_compat_check:(UIBarButtonItem *)sender {

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
	[package release];

	
	NSString *isSettingsPage = [webView stringByEvaluatingJavaScriptFromString:@"(document.getElementById('tweakStatus') ? 'YES' : 'NO')"];	
	if ([isSettingsPage isEqualToString:@"YES"]) { //already injected
		return;
	}

	NSString *baseInjection = @""
		"var actions = document.getElementById('actions');"
		"if (actions) {"
			"if (!document.getElementById('tweakDetails')) {"

				"var container = document.createElement('div'); "
				"var header = document.createElement('p'); "
				"header.setAttribute('style', 'font-size: 12px; color: #000; text-transform: uppercase');"
				"header.innerHTML = 'tweakCompatible Results';"
				"container.appendChild(document.createElement('br'));"
				"container.appendChild(header);"
				"container.appendChild(document.createElement('br'));"


				"var details = document.createElement('p'); "
				"details.id = 'tweakDetails'; "
				"details.setAttribute('style', 'font-size: 12px; color: #6d6d72; text-transform: uppercase');"
				"details.innerHTML = ''; "
				"container.appendChild(details);"
				"container.appendChild(document.createElement('br'));"

				"var fieldset = document.createElement('fieldset'); "
				
				"var a = document.createElement('A'); "
				"a.id = 'tweakStatus'; "
				"a.setAttribute('style', 'display: none; background-color: #fff; border-bottom: 1px solid #c8c7cc;');"
				"a.innerHTML = \"<img class='icon' src='https://jlippold.github.io/tweakCompatible/images/unknown.png'>"
					"<div><div style='background: none'>"
						"<label><p style='color: #000; font-size: 17px; font-weight: 400'>Tweak Status</p></label>"
						"<label style='float: right'><p style='color: #000; font-size: 17px; font-weight: 400'>&nbsp;</p></label>"
						"</div></div>\";"
				"fieldset.appendChild(a);"

				"var b = document.createElement('A'); "
				"b.id = 'tweakWork';"
				"b.setAttribute('style', 'display: none; background-color: #fff; border-bottom: 1px solid #c8c7cc;');"
				"b.innerHTML = \"<img class='icon' src='https://jlippold.github.io/tweakCompatible/images/working.png'>"
					"<div><div><label><p style='color: #000; font-size: 17px; font-weight: 400'>&nbsp;</p></label></div></div>\";"
				"fieldset.appendChild(b);"

				"var c = document.createElement('A'); "
				"c.id = 'tweakNoWork';"
				"c.setAttribute('style', 'display: none; background-color: #fff; border-bottom: 1px solid #c8c7cc;');"
				"c.innerHTML = \"<img class='icon' src='https://jlippold.github.io/tweakCompatible/images/notworking.png'>"
					"<div><div><label><p style='color: #000; font-size: 17px; font-weight: 400'>&nbsp;</p></label></div></div>\";"
				"fieldset.appendChild(c);"

				"var d = document.createElement('A'); "
				"d.id = 'tweakInfo';"
				"d.setAttribute('style', 'display: none; background-color: #fff; border-bottom: 1px solid #c8c7cc;');"
				"d.innerHTML = \"<img class='icon' src='https://jlippold.github.io/tweakCompatible/images/info.png'>"
					"<div><div><label><p style='color: #000; font-size: 17px; font-weight: 400'>&nbsp;</p></label></div></div>\";"
				"fieldset.appendChild(d);"

				"container.appendChild(fieldset);"
				"container.appendChild(document.createElement('br'));"

				"actions.parentNode.insertBefore(container, actions.nextSibling);"

			"}"
		"}";


	[webView stringByEvaluatingJavaScriptFromString:baseInjection];		
	
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
	
	//download tweak list
	NSURL *url = 
		[NSURL URLWithString:[NSString stringWithFormat:@"https://jlippold.github.io/tweakCompatible/json/packages/%@.json", packageId]];
	
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

			id allVersions = foundItem[@"versions"];
			if (allVersions) {
				packageExists = YES;
			}
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
			@"tweakCompatVersion": @"0.0.4",
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
			@"packageStatus": packageStatus,
			@"url": packageUrl
		};
		//[webView stringByEvaluatingJavaScriptFromString:@"alert(document.getElementById('actions').parentNode.innerHTML)"];
		
		

		//gather user info for post to github
		NSString *userInfoJson = @"";
		NSString *userInfoBase64 = @"";
		NSError *error; 
		NSData *jsonData = [NSJSONSerialization dataWithJSONObject:userInfo options:kNilOptions error:&error];
		
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
		
		NSString *baseURI = @"https://jlippold.github.io/tweakCompatible/";
		
		[webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@""
			"var a = document.getElementById('tweakStatus');"
			"if (a) {"
				"a.style.display = 'block';"
				"a.href = 'javascript:void(0)';"
				"a.getElementsByTagName('p')[1].innerHTML = '%@';"
			"}", packageStatus]
		];	
		
		[webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@""
			"document.getElementById('tweakDetails').innerHTML = '%@';", packageStatusExplaination]
		];	

		if (showViewPackage) {
		
			[webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@""
				"var a = document.getElementById('tweakInfo');"
				"if (a) {"
					"a.style.display = 'block';"
					"a.href = '%@package.html#!/%@/details/%@';"
					"a.getElementsByTagName('p')[1].innerHTML = 'More information';"
					"document.getElementById('tweakStatus').href = '%@package.html#!/%@/details/%@';"
				"}", baseURI, packageId, userInfoBase64, baseURI, packageId, userInfoBase64]
			];	
		
		}

		if (showAddWorkingReview) {
			[webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@""
				"var a = document.getElementById('tweakWork');"
				"if (a) {"
					"a.href = '%@submit.html#!/%@/working/%@';"
					"a.style.display = 'block';"
					"a.getElementsByTagName('p')[0].innerHTML = 'Report as working';"
				"}", baseURI, packageId, userInfoBase64]
			];	
		}

		if (showAddNotWorkingReview) {
			[webView stringByEvaluatingJavaScriptFromString: [NSString stringWithFormat:@""
				"var a = document.getElementById('tweakNoWork');"
				"if (a) {"
					"a.href = '%@submit.html#!/%@/notworking/%@';"
					"a.style.display = 'block';"
					"a.getElementsByTagName('p')[0].innerHTML = 'Report as not working';"
				"}", baseURI, packageId, userInfoBase64]
			];	
		}

		if (showRequestReview) {
			//tbd
		}

	
	}];

}

%end


