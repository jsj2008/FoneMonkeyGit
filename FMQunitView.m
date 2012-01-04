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
//  FMQunitView.m
//  FoneMonkey
//
//  Created by Kyle Balogh on 8/24/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "FMQunitView.h"

@interface FMQunitView()
- (void) hideView;
@end

@implementation FMQunitView

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        // Initialization code
        if ([[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeLeft ||
            [[UIApplication sharedApplication] statusBarOrientation] == UIDeviceOrientationLandscapeRight)
            self.frame = CGRectMake(self.frame.origin.x, self.frame.origin.y, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width-20);
        
        self.backgroundColor = [UIColor blackColor];
        
        UIToolbar *qToolBar = [[UIToolbar alloc] initWithFrame:CGRectMake(0, 0, self.frame.size.width, 44)];
        qToolBar.tintColor = [UIColor colorWithRed:.498 green:0 blue:.0 alpha:1];
        
        UIBarButtonItem *fixedSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFixedSpace target:self action:nil];
        fixedSpace.width = 62.0;
        UIBarButtonItem *flexSpace = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:self action:nil];
        UIBarButtonItem *gorillaButton = [[UIBarButtonItem alloc] initWithImage:[UIImage imageNamed:@"gorilla-32"] style:UIBarButtonItemStylePlain target:self action:nil];
        UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done" style:UIBarButtonItemStyleDone target:self action:@selector(hideView)];
        
        doneButton.title = @"Done";
        
        qToolBar.items = [NSArray arrayWithObjects:fixedSpace, flexSpace, gorillaButton, flexSpace, doneButton, nil];
        
        [self addSubview:qToolBar];
        
        [fixedSpace release];
        [flexSpace release];
        [gorillaButton release];
        [doneButton release];
    }
    return self;
}

- (void) hideView
{
	[UIView beginAnimations:nil context:nil];
	[UIView setAnimationDuration:0.5];
    self.frame = CGRectMake(self.frame.origin.x, self.frame.size.height, self.frame.size.width, self.frame.size.height);
	self.alpha = 0.0;
	[UIView setAnimationDelegate:self];
	[UIView commitAnimations];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect
{
    // Drawing code
}
*/

- (void)dealloc
{
    [super dealloc];
}

@end
