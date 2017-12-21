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
    NSString* code = [NSString stringWithCString:systemInfo.machine
                                        encoding:NSUTF8StringEncoding];

	NSDictionary *deviceNamesByCode = @{@"i386"      : @"Simulator",
                              @"x86_64"    : @"Simulator",
                              @"iPod1,1"   : @"iPod Touch",        // (Original)
                              @"iPod2,1"   : @"iPod Touch",        // (Second Generation)
                              @"iPod3,1"   : @"iPod Touch",        // (Third Generation)
                              @"iPod4,1"   : @"iPod Touch",        // (Fourth Generation)
                              @"iPod7,1"   : @"iPod Touch",        // (6th Generation)       
                              @"iPhone1,1" : @"iPhone",            // (Original)
                              @"iPhone1,2" : @"iPhone",            // (3G)
                              @"iPhone2,1" : @"iPhone",            // (3GS)
                              @"iPad1,1"   : @"iPad",              // (Original)
                              @"iPad2,1"   : @"iPad 2",            //
                              @"iPad3,1"   : @"iPad",              // (3rd Generation)
                              @"iPhone3,1" : @"iPhone 4",          // (GSM)
                              @"iPhone3,3" : @"iPhone 4",          // (CDMA/Verizon/Sprint)
                              @"iPhone4,1" : @"iPhone 4S",         //
                              @"iPhone5,1" : @"iPhone 5",          // (model A1428, AT&T/Canada)
                              @"iPhone5,2" : @"iPhone 5",          // (model A1429, everything else)
                              @"iPad3,4"   : @"iPad",              // (4th Generation)
                              @"iPad2,5"   : @"iPad Mini",         // (Original)
                              @"iPhone5,3" : @"iPhone 5c",         // (model A1456, A1532 | GSM)
                              @"iPhone5,4" : @"iPhone 5c",         // (model A1507, A1516, A1526 (China), A1529 | Global)
                              @"iPhone6,1" : @"iPhone 5s",         // (model A1433, A1533 | GSM)
                              @"iPhone6,2" : @"iPhone 5s",         // (model A1457, A1518, A1528 (China), A1530 | Global)
                              @"iPhone7,1" : @"iPhone 6 Plus",     //
                              @"iPhone7,2" : @"iPhone 6",          //
                              @"iPhone8,1" : @"iPhone 6S",         //
                              @"iPhone8,2" : @"iPhone 6S Plus",    //
                              @"iPhone8,4" : @"iPhone SE",         //
                              @"iPhone9,1" : @"iPhone 7",          //
                              @"iPhone9,3" : @"iPhone 7",          //
                              @"iPhone9,2" : @"iPhone 7 Plus",     //
                              @"iPhone9,4" : @"iPhone 7 Plus",     //
                              @"iPhone10,1": @"iPhone 8",          // CDMA
                              @"iPhone10,4": @"iPhone 8",          // GSM
                              @"iPhone10,2": @"iPhone 8 Plus",     // CDMA
                              @"iPhone10,5": @"iPhone 8 Plus",     // GSM
                              @"iPhone10,3": @"iPhone X",          // CDMA
                              @"iPhone10,6": @"iPhone X",          // GSM
                              @"iPad4,1"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Wifi
                              @"iPad4,2"   : @"iPad Air",          // 5th Generation iPad (iPad Air) - Cellular
                              @"iPad4,4"   : @"iPad Mini",         // (2nd Generation iPad Mini - Wifi)
                              @"iPad4,5"   : @"iPad Mini",         // (2nd Generation iPad Mini - Cellular)
                              @"iPad4,7"   : @"iPad Mini",         // (3rd Generation iPad Mini - Wifi (model A1599))
                              @"iPad6,7"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1584) 
                              @"iPad6,8"   : @"iPad Pro (12.9\")", // iPad Pro 12.9 inches - (model A1652) 
                              @"iPad6,3"   : @"iPad Pro (9.7\")",  // iPad Pro 9.7 inches - (model A1673)
                              @"iPad6,4"   : @"iPad Pro (9.7\")"   // iPad Pro 9.7 inches - (models A1674 and A1675)
                              };
    

    NSString* deviceName = [deviceNamesByCode objectForKey:code];
	NSString *iOSVersion = [[UIDevice currentDevice] systemVersion];
	
    if (!deviceName) {
    	deviceName = @"Unknown";
    }

	//download tweak list
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

				NSString *message = [NSString stringWithFormat:@"You are running %@ %@ \n\n", deviceName, iOSVersion];
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


