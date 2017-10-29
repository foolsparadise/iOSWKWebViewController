
## about iOSWKWebViewController  
A Demo for WKWebView in ViewController  
URL File type support: all WKwebView support  
Encoding support: UTF-8, GB15030, GBK, GB2312  

## Usage:  
add 1 row in plist : App Transport Security Settings(2row: Allow Arbitrary Loads:YES, Allow Arbitrary Loads in Web Content:YES)  
add Framework: WebKit.framework  
import "iOSWKWebViewController.h"  
iOSWKWebViewController * vc = [[iOSWKWebViewController alloc] init];  
vc.webURLstring = @"https://iOS.com";  
[self.navigationController pushViewController:vc animated:YES];  

## FBKVOController  
Simple, modern, thread-safe key-value observing for iOS and OS X  
fork from https://github.com/facebook/KVOController.git  

## Masonry  
AutoLayout using Objective-C  
fork from https://github.com/SnapKit/Masonry.git  

## MJRefresh  
An easy way to use pull-to-refresh  
fork from https://github.com/CoderMJLee/MJRefresh.git  


## MIT  
