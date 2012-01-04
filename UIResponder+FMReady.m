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
//  UIResponder+FMReady.m
//  FoneMonkey
//
//  Created by Kyle Balogh on 8/10/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "UIResponder+FMReady.h"
#import "FoneMonkey.h"
#import "FMCommandEvent.h"
#import "FMUtils.h"
#import <objc/runtime.h>
#import "FMUtils.h"
#import "UIView+FMReady.h"


@implementation UIResponder (FMReady)

+ (void)load {
    if (self == [UIResponder class]) {
		
        Method originalMethod = class_getInstanceMethod(self, @selector(becomeFirstResponder));
        Method replacedMethod = class_getInstanceMethod(self, @selector(fmbecomeFirstResponder));
        method_exchangeImplementations(originalMethod, replacedMethod);
    }
}

- (BOOL)fmbecomeFirstResponder
{
    if ([self class] == [UITextField class])
    {
        UITextField *view = (UITextField *)self;
        
        if (view != nil)
            [view fmAssureAutomationInit];
    } else if ([self class] == [UITextView class])
    {
        UITextView *view = (UITextView *)self;
        
        if (view != nil)
            [view fmAssureAutomationInit];
    }
    
    [self fmbecomeFirstResponder];
    return YES;
}

@end
