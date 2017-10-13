//
//  iOSWKWebViewController .h
//
//
//  Created by foolsparadise on 10/10/17.
//  Copyright © 2016 github.com/foolsparadise All rights reserved.
//

#import <UIKit/UIKit.h>

/**
 ## Usage:
 #import "iOSWKWebViewController.h"
 iOSWKWebViewController *vc = [[iOSWKWebViewController alloc] init];
 vc.webURLstring = @"https://iOS.com";
 [self.navigationController pushViewController:vc animated:YES];
 */
@interface iOSWKWebViewController : UIViewController
/**
 NSString *_webURLstring such as
 url
 http://iOS.com/xxx.file.txt
 local mac
 /Users/iOS/Library/Developer/CoreSimulator/Devices/.....
 local iOS
 /var/mobile/Containers/Data/Application/...
 */
@property (nonatomic, strong) NSString *            webURLstring;

@end
