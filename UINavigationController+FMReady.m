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
//  UINavigationController+FMReady.m
//  FoneMonkey
//
//  Created by Kyle Balogh on 9/26/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "UINavigationController+FMReady.h"
#import <objc/runtime.h>
#import "FoneMonkey.h"

@implementation UINavigationController (FMReady)

+ (void)load {
    if (self == [UINavigationController class]) {
		
        Method originalMethod = class_getInstanceMethod(self, @selector(pushViewController:animated:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(fmpushViewController:animated:));
        method_exchangeImplementations(originalMethod, replacedMethod);
        
        Method originalMethod2 = class_getInstanceMethod(self, @selector(popViewControllerAnimated:));
        Method replacedMethod2 = class_getInstanceMethod(self, @selector(fmpopViewControllerAnimated:));
        method_exchangeImplementations(originalMethod2, replacedMethod2);
    }
}

- (void) fmpushViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([[FoneMonkey sharedMonkey].commandSpeed doubleValue] < 333333 && [FoneMonkey sharedMonkey].commandSpeed)
        animated = NO;
    
    [self fmpushViewController:viewController animated:animated];
}

- (UIViewController *) fmpopViewControllerAnimated:(BOOL)animated
{
    if ([FoneMonkey sharedMonkey].commandSpeed && [[FoneMonkey sharedMonkey].commandSpeed doubleValue] < 333333)
        animated = NO;

    [self fmpopViewControllerAnimated:animated];
    
    return self;
}

@end
