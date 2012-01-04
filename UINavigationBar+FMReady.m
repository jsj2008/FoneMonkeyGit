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
//  UINavigationBar+FMReady.m
//  UICatalog
//
//  Created by Stuart Stern on 10/27/09.
//  Copyright 2009 Gorilla Logic, Inc.. All rights reserved.
//

#import "UINavigationBar+FMReady.h"
#import "TouchSynthesis.h"
#import "FoneMonkey.h"
#import "FMCommandEvent.h"
#import "UIView+FMReady.h"
#import <objc/runtime.h>


@implementation UINavigationBar (FMReady)

+ (void)load {
    if (self == [UINavigationBar class]) {
        Method originalMethod = class_getInstanceMethod(self, @selector(popNavigationItemAnimated:));
        Method replacedMethod = class_getInstanceMethod(self, @selector(fmpopNavigationItemAnimated:));
        method_exchangeImplementations(originalMethod, replacedMethod);
    }
}

- (NSString*) monkeyID {
	// Default identifier is the component tag
	NSString* title = [[self topItem] title];
	return title != nil ? [title copy] : [super monkeyID];
}

- (BOOL) shouldRecordMonkeyTouch:(UITouch*)touch {	
	return (touch.phase == UITouchPhaseBegan);
}

- (void) handleMonkeyTouchEvent:(NSSet*)touches withEvent:(UIEvent*)event {
	UITouch* touch = [touches anyObject];
	CGPoint loc = [touch locationInView:self];
	CGFloat width = [[touch view] bounds].size.width;
	
	if (loc.x/width < 0.33) {
		[FoneMonkey recordFrom:self command:FMCommandTouchLeft];
		return;
	}
	
	if (loc.x/width > 0.66) {
		[FoneMonkey recordFrom:self command:FMCommandTouchRight];
		return;
	}
}

- (void) playbackMonkeyEvent:(id)event {
	NSString* command = ((FMCommandEvent*)event).command;
	if ([command isEqual:FMCommandTouchLeft]) {
		[UIEvent performTouchLeftInView:self ];
		return;
	}
	if ([command isEqual:FMCommandTouchRight]) {
		[UIEvent performTouchRightInView:self ];
		return;
	}
	
	[super playbackMonkeyEvent:event];
	return;
}

+ (NSString*) uiAutomationCommand:(FMCommandEvent*)command {
	NSString* string;
	if ([command.command isEqualToString:FMCommandTouchLeft]) {
		string = [NSString stringWithFormat:@"FoneMonkey.elementNamed(\"%@\").leftButton().tap()", command.monkeyID];
	} else if ([command.command isEqualToString:FMCommandTouchRight]) {
		string = [NSString stringWithFormat:@"FoneMonkey.elementNamed(\"%@\").rightButton().tap()", command.monkeyID];
	} else {
		string = [super uiAutomationCommand:command];
	}
	return string;
}

- (UINavigationItem *) fmpopNavigationItemAnimated:(BOOL)animated
{
    if ([FoneMonkey sharedMonkey].commandSpeed != nil && [[FoneMonkey sharedMonkey].commandSpeed doubleValue] < 333333)
        animated = NO;
    
    [self fmpopNavigationItemAnimated:animated];
    
    return nil;
}

@end
