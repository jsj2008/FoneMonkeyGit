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
//  FMUtils.m
//  FoneMonkey
//
//  Created by Stuart Stern on 11/7/09.
//  Copyright 2009 Gorilla Logic, Inc.. All rights reserved.
//

#import <objc/runtime.h>

#import "FMUtils.h"
#import "UIView+FMReady.h"
#import <QuartzCore/QuartzCore.h>
#import "TouchSynthesis.h"
#import <objc/runtime.h>
#import "FMConsoleController.h"
#import "UIMotionEventProxy.h"
#import "FMWindow.h"
#import "FMGetVariableCommand.h"

@implementation FMUtils
+ (UIWindow*) rootWindow {
	UIWindow* keyWindow = [[UIApplication sharedApplication] keyWindow];
	return  keyWindow != nil ?  keyWindow : [[[UIApplication sharedApplication] windows] objectAtIndex:0];
}

+ (UIView*) viewWithMonkeyID:(NSString*)mid startingFromView:(UIView*)current havingClass:(Class)class {
	return [self viewWithMonkeyID:mid startingFromView:current havingClass:class swapsOK:NO];
}
	
+ (UIView*) viewWithMonkeyID:(NSString*)mid startingFromView:(UIView*)current havingClass:(Class)class swapsOK:(BOOL)swapsOK{

	// NSLog(@"Checking %@ == %@", current.monkeyID, mid);
	
	if (!current) {
		current =  [FMUtils rootWindow];
	}
	
	//NSLog(@"mid=%@  monkeyID=%@  accessibilityLabel=%@", mid, current.monkeyID, current.accessibilityLabel);
	if ((mid == nil || [mid length] == 0 || [[current monkeyID] isEqualToString:mid])
					||	(mid != nil && [mid length] >0 && [[current accessibilityLabel] isEqualToString:mid])) {
		//NSLog(@"Found %@", current.monkeyID);
		if (class == nil) { 
			return current;
		}
		
//		if ((class != nil) && (current != nil)) {
//			NSString *name = NSStringFromClass (class);
// NSLog(@"Class: %@", class);
// NSLog(@"Current: %@", [current class]);
//		}
		
		if ( (class != nil && [current isKindOfClass:class]) || (swapsOK && [current swapsWith:NSStringFromClass (class)]) ) {
			return current;
		}
	}
	
	if (!current.subviews) {
		return nil;
	}
	
	for (UIView* view in current.subviews) {
		UIView* result;
		if (result = [self viewWithMonkeyID:mid startingFromView:view havingClass:class swapsOK:swapsOK]) {
			return result;
		}
		
	}	
	
	
	
	return nil;
}


+ (UIView*) viewWithMonkeyID:(NSString*)mid havingClass:(NSString*)className withCommand:(NSString *)command{
	Class class = objc_getClass([className UTF8String]);
	
	if (!class) {
		if ([className length] && ![command isEqualToString:@"GetVariable"]) {
			NSLog(@"Warning: %@ is not a valid classname.", className);
		}
	}
	for (UIView* view in [[UIApplication sharedApplication] windows]) {
		if ([view isKindOfClass:[FMWindow class]]) {
			continue;
		}
		UIView* result = [self viewWithMonkeyID:mid startingFromView:view havingClass:class];
		if (result != nil) {
			return result;
		}
	}
	return nil;
}

static NSInteger foundSoFar;
+ (NSInteger) ordinalForView:(UIView*)view startingFromView:(UIView*)current {
	//NSLog(@"Checking %@ == %@", current.monkeyID, mid);
	if (!current) {
		current =  [FMUtils rootWindow];
	}
	
	if ([current isMemberOfClass:[view class]]) {
		if (current == view) { 
			return foundSoFar;
		}
		
		foundSoFar++;
		
	}
	
	if (!current.subviews) {
		return -1;
	}
	
	for (UIView* kid in current.subviews) {
		NSInteger result;
		if ((result = [self ordinalForView:view startingFromView:kid]) > -1) {
			return result;
		}
		
	}	
	
	
	
	return -1;
}

// Not Re-entrant!
+ (NSInteger) ordinalForView:(UIView*)view {
	foundSoFar = 0;
	return [self ordinalForView:view startingFromView:nil];
}

+ (UIView*) findFirstMonkeyView:(UIView*)current {
	if (current == nil) {
		return nil;
	}
	
	if ([current isFMEnabled]) { 
		return current;
	}
	
	return [FMUtils findFirstMonkeyView:[current superview]];
}

+ scriptPathForFilename:(NSString*) fileName {
	NSString *documentsDirectory = [FMUtils scriptsLocation];
    if (!documentsDirectory) {
        NSLog(@"Documents directory not found!");
       return nil;
    }
    return [documentsDirectory stringByAppendingPathComponent:fileName];
}

+ (BOOL)writeString:(NSString*) string toFile:(NSString*)fileName {
	NSString *path = [self scriptPathForFilename:fileName];
	if (!path) {
		return NO;
	}
	//NSLog(@"Writing %@", path);
	NSError* error;
    if (string != nil) {
        BOOL result = [string writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:&error];
        if (!result) {
            NSLog(@"Error writing to file %@: %@", fileName, [error localizedFailureReason]);
        }
        return result; 
    }
	return NO;
}



+ (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName {
	NSString *path = [self scriptPathForFilename:fileName];
	if (!path) {
		return NO;
	}	
    return ([data writeToFile:path atomically:YES]);
}


+ documentsLocation {
	NSString *documentsDirectory = [FMUtils scriptsLocation];
    if (!documentsDirectory) {
        NSLog(@"Documents directory not found!");
    }
	return documentsDirectory;

}

+ (NSData *)applicationDataFromFile:(NSString *)fileName {
    NSString *documentsDirectory = [FMUtils scriptsLocation];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:fileName];
	NSLog(@"Reading %@", appFile);
    NSData *myData = [[[NSData alloc] initWithContentsOfFile:appFile] autorelease];
    return myData;
}

+ (void) slideIn:(UIView*)view {
	CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type =  kCATransitionPush;
	transition.subtype  = kCATransitionFromBottom;
   // transition.delegate = self;
    [view.layer addAnimation:transition forKey:nil];
	view.alpha = 1.0;
	[[FMUtils rootWindow] bringSubviewToFront:view];
}

+ (void) slideOut:(UIView*) view {
	CATransition *transition = [CATransition animation];
    transition.duration = 0.5;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
	transition.type =  kCATransitionPush;
	transition.subtype  = kCATransitionFromTop;
    //transition.delegate = self;
    [view.layer addAnimation:transition forKey:nil];
	view.alpha = 0;
	[[FMUtils rootWindow] bringSubviewToFront:view];
}

+ (void) navRight:(UIView*)view from:(UIView*)from {
	CATransition *transition = [CATransition animation];
    transition.duration = .25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	transition.type =  kCATransitionPush;
	transition.subtype  = kCATransitionFromRight;
	// transition.delegate = self;
    [view.layer addAnimation:transition forKey:nil];
	view.alpha = 1.0;
//	[from.layer addAnimation:transition  forKey:nil];
//	from.alpha = 0.0;
	[[FMUtils rootWindow] bringSubviewToFront:view];
}


+ (void) navLeft:(UIView*)view to:(UIView*)to {
	CATransition *transition = [CATransition animation];
    transition.duration = .25;
    transition.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionLinear];
	transition.type =  kCATransitionPush;
	transition.subtype  = kCATransitionFromLeft;
	// transition.delegate = self;
    [view.layer addAnimation:transition forKey:nil];
	view.alpha = 0.0;
//	[to.layer addAnimation:transition  forKey:nil];
//	to.alpha = 1.0;	
//	[[FMUtils rootWindow] bringSubviewToFront:view];
}

+ (void) dismissKeyboard {	
	UIWindow *keyWindow = (UIWindow*)[FMConsoleController sharedInstance].view;
	UIView   *firstResponder = [keyWindow performSelector:@selector(firstResponder)];
	[firstResponder resignFirstResponder];
}

+ (NSString*) scriptsLocation {
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString* loc = [paths objectAtIndex:0];
	//loc = [loc stringByAppendingPathComponent:@"fonemonkey"];
	// NSLog(@"Scripts location: %@", loc);
    return loc;
}

+ (void) shake {
	// Although such legal wrangling is not necessary in the simulator, it is necessary to prevent dynamic linker errors on the actual iPhone
	UIMotionEventProxy* m = [[NSClassFromString(@"UIMotionEvent") alloc] _init];
	
	m->_subtype = UIEventSubtypeMotionShake;
	m->_shakeState = 1;
	//[[UIApplication sharedApplication] sendEvent:m]; // Works in simulator but not on device
	[[[UIApplication sharedApplication] keyWindow] motionBegan:UIEventSubtypeMotionShake withEvent:m];
	[[[UIApplication sharedApplication] keyWindow] motionEnded:UIEventSubtypeMotionShake withEvent:m];	
	[m release];
}

+ (void) rotate:(UIInterfaceOrientation)orientation {
	[[UIDevice currentDevice] setOrientation:orientation];
}

+(BOOL) isKeyboard:(UIView*)view {
	// It should go without saying that this is a hack
	Class cls = view.window ? [view.window class] : [view class];
	return [[NSString stringWithUTF8String:class_getName(cls)] isEqualToString:@"UITextEffectsWindow"];
}

+ (NSString*) stringByJsEscapingQuotesAndNewlines:(NSString*)unescapedString {
	return [FMUtils stringByOcEscapingQuotesAndNewlines:unescapedString];
}
+ (NSString*) stringByOcEscapingQuotesAndNewlines:(NSString*)unescapedString {
	NSString* escapedString = [unescapedString stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
	escapedString = [escapedString stringByReplacingOccurrencesOfString:@"\n" withString:@"\\n"];
	return escapedString;
}

+ (NSString*) stringForQunitTest:(NSString*)testCase inModule:(NSString *)module withResult:(NSString *)resultMessage
{
    NSString *xmlString = nil;
    
    if ([resultMessage rangeOfString:@"Test Successful"].location == NSNotFound)
    { // If result of testCase failed add failure detail to xml
        resultMessage = [resultMessage stringByReplacingOccurrencesOfString:@"\\" withString:@""];
        xmlString = [NSString stringWithFormat:@"<testcase name=\"-[%@ %@]\" modulename=\"%@\"><failure>%@</failure></testcase>",module,testCase,module,resultMessage];
    }
    else
        xmlString = [NSString stringWithFormat:@"<testcase name=\"-[%@ %@]\" modulename=\"%@\"/>",module,testCase,module];
    
    return  xmlString;
}

+ (void) writeQunitToXmlWithString:(NSString*)xmlString testCount:(NSString *)testCount failCount:(NSString *)failCount runTime:(NSString *)runTime fileName:(NSString *)fileName
{
    NSString *testSuite = [NSString stringWithFormat:@"<?xml version=\"1.0\"?><testsuite tests=\"%@\" failures=\"%@\" time=\"%@\">",testCount,failCount,runTime];
    NSString *finalXmlString = [xmlString stringByReplacingOccurrencesOfString:@"<?xml version=\"1.0\"?>" withString:testSuite];
    
    finalXmlString = [finalXmlString stringByAppendingString:@"</testsuite>"];
    
    if (getenv("FM_ENABLE_XML_REPORT") && strcmp(getenv("FM_ENABLE_XML_REPORT"),"NO") && getenv("FM_ENABLE_QUNIT"))
    {
        [self writeString:finalXmlString toFile:fileName];
    }
}

- (BOOL) recordMonkeyTouchesYes:(UITouch*)touch {
	return YES;
}
- (BOOL) recordMonkeyTouchesNo:(UITouch*)touch {
	return NO;
}
+ (void) setShouldRecordMonkeyTouch:(BOOL)shouldRecord forView:(UIView*)view {
	Class viewClass = [view class];
	Method currentMethod = class_getInstanceMethod(viewClass, @selector(shouldRecordMonkeyTouch:));	
	Method replaceMethod = class_getInstanceMethod([FMUtils class], 
												   shouldRecord ? @selector(recordMonkeyTouchesYes:)
																: @selector(recordMonkeyTouchesNo:));
	method_setImplementation(currentMethod,method_getImplementation(replaceMethod));
}

+ (NSString*) className:(NSObject*)ob {
	return [NSString stringWithUTF8String:class_getName([ob class])];
}

+ (void) saveScreenshot:(NSString*) filename {
//    UIImageWriteToSavedPhotosAlbum (
//                                    [FMUtils screenshot], nil, nil, nil
//);
    [FMUtils writeApplicationData:UIImagePNGRepresentation([FMUtils screenshot])  toFile:filename];
}

+ (UIImage*)screenshot 
{
    // Create a graphics context with the target size
    // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
    // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
    
    CGSize imageSize = [[UIScreen mainScreen] bounds].size;

    if (NULL != UIGraphicsBeginImageContextWithOptions)
        UIGraphicsBeginImageContextWithOptions(imageSize, NO, 0);
    else
        UIGraphicsBeginImageContext(imageSize);
    
    CGContextRef context = UIGraphicsGetCurrentContext();
    
    // Iterate over every window from back to front
    for (UIWindow *window in [[UIApplication sharedApplication] windows]) 
    {
        if (![window respondsToSelector:@selector(screen)] || [window screen] == [UIScreen mainScreen])
        {
            // -renderInContext: renders in the coordinate space of the layer,
            // so we must first apply the layer's geometry to the graphics context
            CGContextSaveGState(context);
            // Center the context around the window's anchor point
            CGContextTranslateCTM(context, [window center].x, [window center].y);
            // Apply the window's transform about the anchor point
            CGContextConcatCTM(context, [window transform]);
            // Offset by the portion of the bounds left of and above the anchor point
            CGContextTranslateCTM(context,
                                  -[window bounds].size.width * ([[window layer] anchorPoint].x),
                                  -[window bounds].size.height * [[window layer] anchorPoint].y);
            
            // Render the layer hierarchy to the current context
            [[window layer] renderInContext:context];
            
            // Restore the context
            CGContextRestoreGState(context);
        }
    }
    
    // Retrieve the screenshot image
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    
    UIGraphicsEndImageContext();
    
    return image;
}

+ (void) interfaceChanged:(UIView *)view
{
    UIInterfaceOrientation interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];
    CGRect portraitFrame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.width, [[UIScreen mainScreen] bounds].size.height);
    CGRect landscapeFrame = CGRectMake(0, 0, [[UIScreen mainScreen] bounds].size.height, [[UIScreen mainScreen] bounds].size.width);
    
    // Rotate and scale interface based on status bar orientation
    if (interfaceOrientation == UIDeviceOrientationPortrait)
        [self rotateInterface:view degrees:0 frame:portraitFrame];
    else if (interfaceOrientation == UIDeviceOrientationPortraitUpsideDown)
        [self rotateInterface:view degrees:180 frame:portraitFrame];
    else if (interfaceOrientation == UIDeviceOrientationLandscapeLeft)
        [self rotateInterface:view degrees:90 frame:landscapeFrame];
    else
        [self rotateInterface:view degrees:-90 frame:landscapeFrame];
}

+ (void)rotateInterface:(UIView *)view degrees:(NSInteger)degrees frame:(CGRect)frame
{
    //[UIView beginAnimations:nil context:nil];
    //[UIView setAnimationDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration]];
    //[UIView setAnimationTransition:UIViewAnimationTransitionNone forView:view cache:YES];
    //[UIView setAnimationDelegate:view];
    view.transform = CGAffineTransformIdentity;
    view.transform = CGAffineTransformMakeRotation(degrees * M_PI / 180);
    view.bounds = frame;
    //[UIView commitAnimations];
}

+ (NSString *)timeStamp
{
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"MM-dd-HH-mm-ss-SSS"];
    NSString *dateString = [dateFormatter stringFromDate:[NSDate date]];
    [dateFormatter release];
    return dateString;
}

+ (NSArray *) replaceArgForCommand:(NSArray *)commandArgs variables:(NSDictionary *)jsVariable
{
    if ([[commandArgs componentsJoinedByString:@","] rangeOfString:@"${"].location != NSNotFound)
    {
        NSMutableArray * mutableArgs = [NSMutableArray arrayWithArray:commandArgs];
        for (int i = 0; i < [commandArgs count]; i++) {
            NSString * argString = (NSString *)[commandArgs objectAtIndex:i];
            argString = [[self class] replaceString:argString variables:jsVariable];
            [mutableArgs replaceObjectAtIndex:i withObject:argString];
            commandArgs = mutableArgs;
        }
    }
    
    return commandArgs;
}

+ (NSString *) replaceMonkeyIdForCommand:(NSString *)monkeyId variables:(NSDictionary *)jsVariable
{
    monkeyId = [[self class] replaceString:monkeyId variables:jsVariable];
    
    return monkeyId;
}

+ (NSString *) replaceString:(NSString *)origString variables:(NSDictionary *)jsVariable {
    NSString *newString = origString;
    if ([origString rangeOfString:@"${"].location != NSNotFound && [origString rangeOfString:@"}"].location != NSNotFound) {
        NSUInteger count = 0, length = [origString length];
        NSRange range = NSMakeRange(0, length); 
        NSRange endRange = NSMakeRange(0, length);
        while(range.location != NSNotFound)
        {
            range = [origString rangeOfString: @"${" options:0 range:range];
            endRange = [origString rangeOfString: @"}" options:0 range:endRange];
            
            if (range.location <= [origString length])
            {
                NSString *replaceString = [origString substringWithRange:NSMakeRange(range.location, endRange.location - range.location + 1)];
                
                if ([jsVariable objectForKey:replaceString])
                {
                    newString = [newString stringByReplacingOccurrencesOfString:replaceString withString:[jsVariable objectForKey:replaceString]];
                    NSLog(@"Replacing %@ with %@",origString,newString);
                }
            }
            
            if(range.location != NSNotFound)
            {
                range = NSMakeRange(range.location + range.length, length - (range.location + range.length));
                endRange = NSMakeRange(endRange.location + endRange.length, length - (endRange.location + endRange.length));
                count++; 
            }
        }
    }
    
    return newString;
}

+ (NSMutableDictionary *) addVarsFrom:(FMCommandEvent *)event to:(NSMutableDictionary *)dict
{
    NSString *variable = [NSString stringWithFormat:@"${%@}", [event.args objectAtIndex:1]];
    NSString* value = [FMGetVariableCommand execute:event];
    
    [dict setValue:value forKey:variable];
    
    return dict;
}

+ (void) saveUserDefaults:(NSString*)value forKey:(NSString*)key
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
    
	if (standardUserDefaults) {
		[standardUserDefaults setObject:value forKey:key];
		[standardUserDefaults synchronize];
	}
}

+ (NSString *) retrieveUserDefaultsForKey:(NSString*)key
{
	NSUserDefaults *standardUserDefaults = [NSUserDefaults standardUserDefaults];
	NSString *value = nil;
	
	if (standardUserDefaults) 
		value = [standardUserDefaults objectForKey:key];
	
	return value;
}

+ (double) playbackSpeedForCommand:(FMCommandEvent *)nextCommandToRun isLive:(BOOL)isLive retryCount:(int)retryCount
{
    if ([nextCommandToRun.playbackDelay length] == 0)
        nextCommandToRun.playbackDelay = [NSString stringWithFormat:@"%i",DEFAULT_PLAYBACK];
    
    double commandPlaybackSpeed = 0;
    double perCommandPlayback = [nextCommandToRun.playbackDelay doubleValue]*1000;
    double globalLivePercent = [[FMUtils retrieveUserDefaultsForKey:FMOptionsLive] doubleValue]/100;
    double globalCommandPlayback = [[FMUtils retrieveUserDefaultsForKey:FMOptionsFixed] doubleValue]*1000;
    
    if (retryCount > 0)
        commandPlaybackSpeed = 0;
    else if (isLive)
        if ([[FMUtils retrieveUserDefaultsForKey:FMOptionsLive] length] > 0)
            commandPlaybackSpeed = perCommandPlayback * globalLivePercent;
        else
            commandPlaybackSpeed = perCommandPlayback;
    else
        if ([[FMUtils retrieveUserDefaultsForKey:FMOptionsFixed] length] > 0)
            commandPlaybackSpeed = globalCommandPlayback;
        else
            commandPlaybackSpeed = DEFAULT_PLAYBACK*1000;
    
    
//    else if ([[FMUtils retrieveUserDefaultsForKey:FMOptionsFixed] length] > 0)
//        commandPlaybackSpeed = globalCommandPlayback;
//    else if([nextCommandToRun.playbackDelay length] > 0)
//        commandPlaybackSpeed = perCommandPlayback;
//    else
//        commandPlaybackSpeed = DEFAULT_PLAYBACK;
    
    return commandPlaybackSpeed;
}

+ (double) timeoutForCommand:(FMCommandEvent *)nextCommandToRun
{
    int commandTimeout = 0;
    
    double perCommandTimeout = [nextCommandToRun.playbackTimeout intValue];
    double globalCommandTimeout = [[FMUtils retrieveUserDefaultsForKey:FMOptionsTimeout] intValue];
    
    if (globalCommandTimeout > 0)
        commandTimeout = globalCommandTimeout;
    else if([nextCommandToRun.playbackDelay length] > 0)
        commandTimeout = perCommandTimeout;
    else
        commandTimeout = DEFAULT_TIMEOUT;
    
    return commandTimeout;
}


@end
