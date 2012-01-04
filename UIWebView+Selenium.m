/* This file is part of FoneMonkey.
 
 FoneMonkey is free software: you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation, either version 3 of the License, or
 (at your option) any later version.
 
 FoneMonkey is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 
 You should have received a copy of the GNU General Public License
 along with FoneMonkey.  If not, see <http://www.gnu.org/licenses/>.  */
//
//  UIWebView+Selenium.m
//  WebViewTest
//
//  Created by Kyle Balogh on 10/20/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "UIWebView+Selenium.h"
#import "FMWebViewController.h"
#import <objc/runtime.h>


@interface FMDefaultWebViewDelegate : NSObject <UIWebViewDelegate>
@end
@implementation FMDefaultWebViewDelegate
@end

@implementation UIWebView (Selenium)
+(void) load
{
    if (self == [UIWebView class]) {
        Method originalMethod = class_getInstanceMethod(self, @selector(setDelegate:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(fmSetDelegate:));
        method_exchangeImplementations(originalMethod, replacedMethod);
    }
}

- (void) fmAssureAutomationInit {
	[super fmAssureAutomationInit];
	if (!self.delegate) {
		self.delegate = [[FMDefaultWebViewDelegate alloc] init];
	}
}

- (void) fmSetDelegate:(NSObject <UIWebViewDelegate>*) del {
    
    if ([self.delegate class] != [FMWebViewController class]) {
        FMWebViewController *webController = [[[FMWebViewController alloc] init] autorelease];
        
        // Set delController to call original delegate methods from webController
        webController.delController = del;
        
        // Set webView delegate to webController
        [self fmSetDelegate:webController];
        
        self.accessibilityLabel = @"webView";
        
        // Set webController webView to user's webView
        webController.webView = self;
    }
}

@end
