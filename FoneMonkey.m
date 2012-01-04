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
//  FoneMonkey.m
//  FoneMonkey
//
//  Created by Stuart Stern on 10/14/09.
//  Copyright (c) 2009 Gorilla Logic, Inc. All rights reserved.
//

#import <unistd.h>
#import <Foundation/Foundation.h>
#import "FoneMonkey.h"
#import "FMCommandEvent.h"
#import "UIView+FMReady.h"
#import <UIKit/UIView.h>
#import "UIView+FullDescription.h"
#import "FMUtils.h"
#import <objc/runtime.h>
#import "FMCommandEvent.h"
#import "FMConsoleController.h"
#import"FMWaitForCommand.h"
#import "FMParseCsv.h"
#import <QuartzCore/QuartzCore.h>
#import "FMWebViewController.h"

#import "FMBuildStamp.h"

// Pause 1/2 sec between commands. This needs to be a setting!
#define THINK_TIME 500000 
//#define UIAUTOMATION_PATH @"uiautomation"
#define UIAUTOMATION_PATH @""
//#define OCUNIT_PATH @"ocunit"
#define OCUNIT_PATH @""
//#define QUNIT_PATH @"qunit"
#define QUNIT_PATH @""

@implementation FoneMonkey
static FoneMonkey* _sharedMonkey = nil;

char* _enableScreenshot = nil;

FMCommandEvent* lastCommandPosted;
BOOL _lastCommandRecorded = YES;
FMCommandEvent* nextCommandToRun;

@synthesize commands, runTimeout, state, session, csvData, previousTime, commandSpeed;

NSMutableDictionary* _monkeyIDs;

FMConsoleController* _console;
UIDeviceOrientation _currentOrientation;

NSArray* emptyArray;

+(FoneMonkey*)sharedMonkey
{
	@synchronized([FoneMonkey class])
	{		
		if (!_sharedMonkey) {
			// Weird objective-c singleton code idiom. The alloc/init creates the singleton instance and resets self so that rest of method refers to instance variables (not static) variables.
			[[self alloc] init];
			// After executing the above alloc/init, we are no longer in a static method. We are now in the singleton instance! 
			_monkeyIDs = [[NSMutableDictionary alloc] init];
            
			
			if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
			{
                NSLog(@"Running on iPhone");
				// load the content controller object for Phone-based devices
				_console = [[FMConsoleController alloc] initWithNibName:@"FMConsoleController_iPhone" bundle:nil];
			}
			else
			{
                NSLog(@"Running on iPad");
				// load the content controller object for Pad-based devices
				_console = [[FMConsoleController alloc] initWithNibName:@"FMConsoleController_iPad" bundle:nil];
			}
			NSLog(@"Documents folder located at: %@",[FMUtils scriptsLocation]);
            
            // If we're running headless we might have to force creation of Documents directory
            [[NSFileManager defaultManager] createDirectoryAtPath:[FMUtils scriptsLocation] 
                                      withIntermediateDirectories:YES 
                                                       attributes:nil error:nil];            
			emptyArray = [[NSArray alloc] init];
		}
		return _sharedMonkey;
	}
	
	return nil;
}


+(id)alloc
{
	@synchronized([FoneMonkey class])
	{
		NSAssert(_sharedMonkey == nil, @"Attempted to allocate a second instance of FoneMonkey.");
		NSLog(STARTUP_MESSAGE);
		_sharedMonkey = [super alloc];
		_sharedMonkey.session = [NSMutableDictionary dictionary]; 		
		return _sharedMonkey;
	}
	
	return nil;
}


// Part of code to handle orientation events.
// This method is called by NSNotificationCenter when the device is rotated.
-(void) receivedRotate: (NSNotification*) notification
{
	UIWindow* _appWindow;
	UIDeviceOrientation interfaceOrientation = [[UIDevice currentDevice] orientation];
	
	if ((interfaceOrientation = UIDeviceOrientationLandscapeLeft) ||
		(interfaceOrientation = UIDeviceOrientationLandscapeRight)) {
		/*_landscape = YES;
         [_console hideConsole];
         _console = _console_landscape;
         [_console showConsole];
		 */
		// Rotates the view.
		CGAffineTransform transform = CGAffineTransformMakeRotation(-3.14159/2);
		_console.view.transform = transform;
		// Repositions and resizes the view.
		_appWindow = [FMUtils rootWindow];
		
		
		CGRect contentRect = [_appWindow bounds];
		if (contentRect.size.height > contentRect.size.width) {
			CGFloat temp = contentRect.size.height;
			contentRect.size.height = contentRect.size.width;
			contentRect.size.width = temp;
		}
		_console.view.bounds = contentRect;
		
	} else {
		CGAffineTransform transform = CGAffineTransformMakeRotation(3.14159/2);
		_console.view.transform = transform;
		// Repositions and resizes the view.
		_appWindow = [FMUtils rootWindow];
		
		
		CGRect contentRect = [_appWindow bounds];
		if (contentRect.size.height < contentRect.size.width) {
			CGFloat temp = contentRect.size.height;
			contentRect.size.height = contentRect.size.width;
			contentRect.size.width = temp;
		}
		_console.view.bounds = contentRect;
	}
	
}

- (NSString *) liveDelay
{
    NSDate *currentTime = [NSDate date];
    if (!previousTime) {
        previousTime = [currentTime copy];
        return [NSString stringWithFormat:@"%i",DEFAULT_PLAYBACK];
    }
    
    NSTimeInterval delay = [currentTime timeIntervalSinceDate:previousTime];
    delay = delay * 1000;
    
    previousTime = [currentTime copy];
    
    return [NSString stringWithFormat:@"%g",delay];
}

- (void) recordEvent:(FMCommandEvent*)event {
	if (state != FMStateRecording) {
		return;
	}
	
	NSString* accLbl = [[event source] accessibilityLabel];
	if (accLbl!=nil && [accLbl length]>0) {
		event.monkeyID = accLbl;
	}
    
    event.playbackDelay = [self liveDelay];
    event.playbackTimeout = [NSString stringWithFormat:@"%i",DEFAULT_TIMEOUT];
	
	//NSLog(@"\n\n< < < RECORDING > > > - source:%@\n%@\n%@ %@ %@\n\n",event.source, event.source.fullDescription, event.command, [event.source monkeyID], [event.args count] > 0 ? [event.args objectAtIndex:0] : @"");
	//NSLog(@"\n\n< < < RECORDING > > > - source:%@\n%@ %@ %@\n\n",[event.source class], event.command, [event.source monkeyID], event.args);	
	NSLog(@"\n\n< < < RECORDING > > > - source:%@\n%@ %@ %@\n\n",[[event source] class], [event command], event.monkeyID, [event args]);	
	[commands addObject:[NSMutableDictionary dictionaryWithDictionary:event.dict]];
	
}

//- (void) reportLastResult:(NSString*)result forCommandNumber:(NSInteger)index {
//
//}

+ (void) recordEvent:(FMCommandEvent*)event {
	[[self sharedMonkey] recordEvent:event];
}

- (void) recordLastCommand:(NSNotification*) notification {
	[self recordEvent:lastCommandPosted];
	_lastCommandRecorded = YES;
}

- (id)init {
	if ((self = [super init])) {
		self.commands = [NSMutableArray arrayWithCapacity:12];
		self.session = [NSMutableDictionary dictionary]; 
		lastCommandPosted = [[FMCommandEvent alloc] init];
		nextCommandToRun = [[FMCommandEvent alloc] init];		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(recordLastCommand:)
													 name:FMNotificationCommandPosted object:nil];			
		runTimeout = 2.5; // Should remember last user setting
	}
	
	UIDevice* dev = [UIDevice currentDevice];
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(recordRotation:)
												 name:@"UIDeviceOrientationDidChangeNotification" object:nil];
    
    _currentOrientation = [dev orientation];
    
    csvIndex = 0;
    
	
	[dev beginGeneratingDeviceOrientationNotifications];
    
    // Register for UITextField and UITextView DidBeginEditing
    // Fixes issue when delegate is not set for text field/view
    //    [[NSNotificationCenter defaultCenter] addObserver:self 
    //                                             selector:@selector(textEditingBegan:) 
    //                                                 name:UITextFieldTextDidBeginEditingNotification object:nil];
    //    [[NSNotificationCenter defaultCenter] addObserver:self 
    //                                             selector:@selector(textEditingBegan:) 
    //                                                 name:UITextViewTextDidBeginEditingNotification object:nil];
    
	
	//This is code to register for orientation events and then handle them.
	// CODE TO HANDLE DEVICE ROTATE - NEXT VERSION
	//[[NSNotificationCenter defaultCenter] addObserver: self selector: @selector(receivedRotate:) name: UIDeviceOrientationDidChangeNotification object: nil];
	
	return self;
}


- (void) recordRotation:(NSNotification *)notification
{	
    UIDeviceOrientation orientation =  [[UIDevice currentDevice] orientation];
    if (orientation == 0) {
        return;
    }
    
    if (orientation == _currentOrientation) {
        return;
    }
    _currentOrientation = orientation;
	[FoneMonkey recordFrom:nil command:FMCommandRotate args:[NSArray arrayWithObject:[NSString stringWithFormat:@"%d", orientation]]];
	
}

-(void)textEditingBegan:(NSNotification *)notification
{
    UIView* view = (UIView *)[notification object];
    view = [FMUtils findFirstMonkeyView:view];
    
    if (view != nil) {
        [view fmAssureAutomationInit];
    }
}

- (void) dealloc {
    [csvData release];
    [previousTime release];
    [replaceVars release];
	[commands release];
	[_monkeyIDs release];
	[session release];
	[super dealloc];
}


- (void) sendNotification:(NSString*) notificationName object:sender {
	NSNotification *myNotification =
    [NSNotification notificationWithName:notificationName object:sender];
	[[NSNotificationQueue defaultQueue]
	 enqueueNotification:myNotification
	 postingStyle:NSPostWhenIdle
	 coalesceMask:NSNotificationCoalescingOnName
	 forModes:nil];
}


+ (void) recordFrom:(UIView*)source command:(NSString*)command {
	[[self sharedMonkey] postCommandFrom:source command:command args:nil];
}


- (void) recordFrom:(UIView*)source command:(NSString*)command args:(NSArray*)args post:(BOOL)post {
    
    // ToDo: Better fix for Play Notification on Done
    if ([lastCommandPosted.monkeyID isEqualToString:@"Done"] && [command isEqualToString:FMCommandPlayMovie])
        return;
    
	if (state != FMStateRecording) {
		return;
	}
	if (post) {
		[self postCommandFrom:source command:command args:args];
	} else {
		[ FoneMonkey recordEvent:[[FMCommandEvent alloc]
								  init:command className:[NSString stringWithUTF8String:class_getName([source class])]
								  monkeyID:[source monkeyID]
								  args:args]];	
	}
}
+ (void) recordFrom:(UIView*)source command:(NSString*)command args:(NSArray*)args {
	[[FoneMonkey sharedMonkey] recordFrom:source command:command args:args post:YES];
}
- (void) recordFrom:(UIView*)source command:(NSString*)command  {
	[self postCommandFrom:source command:command args:nil];
}



//- (BOOL)sendAction:(SEL)action to:(id)target from:(id)sender forEvent:(UIEvent *)event {
//	NSLog(@"Got an action from %@ for %@ ", [sender description], [event description]);
//	return [super sendAction:action to:target from:sender forEvent:event];
//}

- (BOOL) isRecording {
	return (state == FMStateRecording);
}

+ (BOOL) isRecording {
	return [[self sharedMonkey] isRecording];
}

- (void) continueMonitoring {
	if (state == FMStateSuspended) {
		return;
	}
	[NSObject cancelPreviousPerformRequestsWithTarget:self];	
	[self performSelector:@selector(suspend) withObject:nil afterDelay:runTimeout];
}

- (void) pause {
	state = FMStatePaused;
	[self continueMonitoring];	
}



- (NSString*) lastResult {
	return [self firstErrorIndex] == -1 ? nil : [[self commandAt:[self firstErrorIndex]] lastResult];
}

- (void) play:(BOOL)waitUntilDone {
	state = FMStatePlaying;
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(runCommands) object:nil];
	[thread start];
	if (waitUntilDone) {
        if (!getenv("FM_ENABLE_QUNIT")) { // Skip loop if JS test running, otherwise it loops forever
            while (![thread isFinished]) {
            	usleep(100000);
            }
            
            while (isDriving) {
                usleep(100000);
            }
        } else {
            [_console hideConsoleQunit];
        }
	}
    
	return;
}

- (void) playFrom:(NSUInteger)index {
	state = FMStatePlaying;
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(runCommandsStartingFrom:) object:[NSNumber numberWithInteger:index]];
	[thread start];
	
}

- (void) playFrom:(NSUInteger)index numberOfCommands:(NSUInteger)count{
	state = FMStatePlaying;
	NSThread* thread = [[NSThread alloc] initWithTarget:self selector:@selector(runCommandRange:) object:[NSArray arrayWithObjects:[NSNumber numberWithInteger:index],[NSNumber numberWithInteger:count],nil]];
	[thread start];
	
}

- (NSString*) playAndWait {
	state = FMStatePlaying;	
	[_console performSelectorOnMainThread:@selector(hideConsoleAndThen:) withObject:nil waitUntilDone:YES];
	[self play:YES];
	return [self lastResult];	
}

- (NSString*) runScript:(NSString*)script { 
	[self open:script];
	return [self playAndWait];
}

- (void) play {
	[self play:NO];
}

- (void) record {
	state = FMStateRecording;
	[self continueMonitoring];
}

- (void) suspend {
	state = FMStateSuspended;
	[self sendNotification:FMNotificationMonkeySuspended object:self];	
}


- (void) playingDone {
    if (!getenv("FM_SHOW_CONSOLE_ALL_TIME")) {
	    state = FMStateSuspended;
        isDriving = NO;
        if (getenv("FM_ENABLE_QUNIT"))
        {
            [_console showConsoleQunit];
            [_console.connectWebView qResult:@"success" event:nextCommandToRun function:@"FMPlayCommands"];
            
            [_console performSelectorOnMainThread:@selector(showView:) withObject:nil waitUntilDone:NO];
        }
	    [self sendNotification:FMNotificationPlayingDone object:self];	
    }
}

- (void) clear {
	[self sendNotification:FMNotificationScriptOpened object:self];	
    
	[commands removeAllObjects];
}

- (void) handleEvent:(UIEvent*)event {
	if (state == FMStateSuspended || state == FMStatePlaying) {
		return;
	}
	
	BOOL eventHandled = NO;
    
	if (event.type == UIEventTypeTouches) {
		NSSet* touches = [event allTouches];
		UITouch* touch = [touches anyObject];
		UIView* view = touch.view;
		view = [FMUtils findFirstMonkeyView:view];
        
		if (view != nil) {
			[view fmAssureAutomationInit];
			if ([view shouldRecordMonkeyTouch:touch]) {
				[view handleMonkeyTouchEvent:touches withEvent:event];
				NSLog(@"FoneMonkey(state: %d) got an event\n%@", state, event);
				eventHandled = YES;
                
			} 
		} 
        //		else {
        //						NSLog(@"Nil view");
        //			UIWindow* window = [touch window];
        //			view = [window hitTest:[touch locationInView:window] withEvent:event];	
        //			view = [FMUtils findFirstMonkeyView:view];			
        //		}
	} else if (event.type == UIEventTypeMotion) {
		[[[UIApplication sharedApplication] keyWindow] handleMonkeyMotionEvent:event];
		eventHandled = YES;
	} 
	else {
		NSLog(@"Event has invalid type. Keyboard input?");
	}
    
	if (!eventHandled) {
		NSLog(@"No FMReady view to handle this event\n%@", event);
		
	}
	[self continueMonitoring];
	return;
    
}

- (void) addCommand:(FMCommandEvent*)cmd {
	[commands addObject:[cmd dict]];
}

- (void) loadCommands:(NSArray*) cmds {
	[commands removeAllObjects];
	int i;
	for (i = 0; i < [cmds count]; i++) {
		[self addCommand:[cmds objectAtIndex:i]];
	}
}

- (void) saveScreenshot:(FMCommandEvent*) command {
    NSString* fileName = [NSString stringWithFormat:@"FM_SCREENSHOT-%@-%@-%@-%@.png",
                          [FMUtils timeStamp],
                          command.command, 
                          command.className, 
                          command.monkeyID
                          ];
    
    NSLog(@"Screen image saved to %@",fileName);                                                                                                                                                                                         
    [FMUtils saveScreenshot:fileName];
}


- (char*) isScreenshotOn {
    if (!_enableScreenshot) {
        _enableScreenshot = getenv("FM_ENABLE_SCREENSHOT");
        if (!_enableScreenshot) {
            _enableScreenshot = "NONE";
        }
    }
    return _enableScreenshot;
}

- (BOOL) isScreenshotOnFailure {
    return !strcmp([self isScreenshotOn],"FAILURE");    
}

- (BOOL) isScreenshotOnAll {
    return !strcmp([self isScreenshotOn],"ALL");  
}

- (void) runCommandsStartingFrom:(NSInteger)start numberOfCommands:(NSInteger)count{
	// We're a thread
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	
	BOOL failure = NO;
	int i;	
	for (i = start; i < start + count; i++) {
		FMCommandEvent* nextCommandToRun = [self commandAt:i];
		nextCommandToRun.lastResult = nil;
        
        double commandPlaybackSpeed = [FMUtils playbackSpeedForCommand:nextCommandToRun isLive:_console.liveSwitch.on retryCount:retryCount];
        double commandTimeout = [FMUtils timeoutForCommand:nextCommandToRun];
        
        // If user is using recorded speed, set timeout to 0
        if (_console.liveSwitch.on)
            commandTimeout = 0;
        
        // Set 10 millisecond playback if speed is 0
        // Fixes issue causeing component not found when running script
        if (commandPlaybackSpeed == 0)
            commandPlaybackSpeed = 10000;
        
//        if ([commandSpeed isEqualToString:@"333333.333"]) {
//            commandPlaybackSpeed = 333333.333;
//            NSLog(@"Speed: %f",commandPlaybackSpeed);
//        }
        
        if ([self commandCount] > i+1) 
            commandSpeed = [NSString stringWithFormat:@"%f",[FMUtils playbackSpeedForCommand:nextCommandToRun isLive:_console.liveSwitch.on retryCount:retryCount]];
        
		if (failure) {
			continue;
		}
        if ([nextCommandToRun.command isEqualToString:FMCommandDataDrive]) {
            NSLog(@"Data driving with %@.csv at row %i",[nextCommandToRun.args objectAtIndex:0],csvIndex+1);
            isDriving = YES;
        }
        else
            NSLog(@"\n\n< < <Playing> > > %@ %@ \"%@\" %@\n\n", nextCommandToRun.command,
                  nextCommandToRun.className != nil ? nextCommandToRun.className : @"", nextCommandToRun.monkeyID, 
                  nextCommandToRun.args);		
        
		if ([nextCommandToRun.command isEqualToString:FMCommandPause]) {
			if ([nextCommandToRun.args count] < 1) {
				nextCommandToRun.lastResult = [NSString stringWithFormat:@"Requires 1 argument, but has %d", [nextCommandToRun.args count]];
			} else {
				NSInteger msecs = [((NSString*)[nextCommandToRun.args objectAtIndex:0]) intValue];
				usleep(msecs * 1000);
			}
		} else if ([nextCommandToRun.command isEqualToString:FMCommandWaitFor]) {
            // WaitFor, Shake, Rotate may need to be on main thread
			[FMWaitForCommand execute:nextCommandToRun];
			
		} else if ([nextCommandToRun.command isEqualToString:FMCommandShake]) {
			usleep(commandPlaybackSpeed);
			[FMUtils shake];
		} else if ([nextCommandToRun.command isEqualToString:FMCommandRotate]) {
			usleep(commandPlaybackSpeed);			
			[self performSelectorOnMainThread:@selector(rotate:) withObject:nextCommandToRun waitUntilDone:YES];
		} else if ([nextCommandToRun.command isEqualToString:FMCommandGetVariable]) {
            if (!replaceVars)
                replaceVars = [[NSMutableDictionary alloc] init];
            
            replaceVars = [FMUtils addVarsFrom:nextCommandToRun to:replaceVars];
            
            if (getenv("FM_ENABLE_QUNIT"))
                [_console.connectWebView qResult:@"success" event:nextCommandToRun function:nextCommandToRun.command];
        } else if ([nextCommandToRun.command isEqualToString:FMCommandDataDrive])
        {
            NSString *tempSt = [NSString stringWithFormat:@"%@/%@.csv",[FMUtils scriptsLocation],[nextCommandToRun.args objectAtIndex:0]];
            
            csvData = [FMParseCsv readFile:tempSt error:nil];
            csvIndex++;
            
            [_console.connectWebView qResult:[NSString stringWithFormat:@"%i", [csvData count]] event:nextCommandToRun function:FMCommandDataDrive];
        }
        else if ([nextCommandToRun.command isEqualToString:FMCommandRun])
        {
            //NSString *tempSt = [NSString stringWithFormat:@"%@/%@.html",[FMUtils scriptsLocation],[nextCommandToRun.args objectAtIndex:0]];
            
            UIWebView *webView = (UIWebView *)nextCommandToRun.source;
            FMWebViewController *webDriver = (FMWebViewController *)webView.delegate;
            NSString *htmlFile = [nextCommandToRun.args objectAtIndex:0];
            
            while (!webDriver) {
                usleep(5000);
                webView = (UIWebView *)nextCommandToRun.source;
                webDriver = (FMWebViewController *)webView.delegate;
            }
            
            dispatch_async(dispatch_get_main_queue(), ^{
                [webDriver seleniumFile:htmlFile speed:commandPlaybackSpeed timeout:commandTimeout];
            });
            webDriver.testComplete = nil;
            
            //[webDriver performSelectorOnMainThread:@selector(selenium) withObject:nil waitUntilDone:YES];
            
            while (!webDriver.testComplete)
                usleep(5000);
            
            if (![webDriver.testComplete isEqualToString:@"YES"])
            {
                nextCommandToRun.lastResult = [NSString stringWithFormat:@"%@ not found. Row: %i",webDriver.testComplete, webDriver.errorIndex+1];
            }
            
            // Reset test for next run
            webDriver.testComplete = nil;
        } else {		
			usleep(commandPlaybackSpeed); 
			//UIView* source = (UIView *)nextCommandToRun.source;
			//if (source != nil) {
            
            NSArray *origArgs = [NSArray arrayWithArray:nextCommandToRun.args];
            NSString *origID = nextCommandToRun.monkeyID;
            
            // Check if variables within command
            if (replaceVars)
            {
                nextCommandToRun.args = [FMUtils replaceArgForCommand:nextCommandToRun.args variables:replaceVars];
                nextCommandToRun.monkeyID = [FMUtils replaceMonkeyIdForCommand:nextCommandToRun.monkeyID variables:replaceVars];
            }
            
            if (csvData) {
                //NSMutableDictionary *tempDict = [csvData objectAtIndex:0];
                
                if (csvIndex-1 < [csvData count]) {
                    nextCommandToRun.args = [FMUtils replaceArgForCommand:nextCommandToRun.args variables:[csvData objectAtIndex:csvIndex-1]];
                }
                //[tempDict release];
            }
            
            [self performSelectorOnMainThread:@selector(playbackMonkeyEvent:) withObject:nextCommandToRun waitUntilDone:YES];
            
            nextCommandToRun.args = origArgs;
            nextCommandToRun.monkeyID = origID;
            
			//} else {
			//	nextCommandToRun.lastResult = [NSString stringWithFormat:@"No %@ found with monkeyID \"%@\"", nextCommandToRun.className, nextCommandToRun.monkeyID];
			//}
		}
		if ([nextCommandToRun lastResult]) {
            // Retry command based on values for command
            NSLog( @"WARNING: !!!!! Retry command params: retryCount = %i; commandTimeout/10 = %f", retryCount, (commandTimeout/10) );
            if (retryCount < commandTimeout/10 && ![nextCommandToRun.command isEqualToString:FMCommandWebDriver])
            {
                //NSLog(@"time: %@",[FMUtils timeStamp]);
                retryCount++;
                if (getenv("FM_DO_OLD_REPEATS")) {
                    [self playFrom:i];
                }
                else {
	                state = FMStatePlaying;
                    [self runCommandsStartingFrom:[NSNumber numberWithInteger:i]];
                }
                return;
            }
            
            NSLog(@"FoneMonkey Script Failure: %@\n", nextCommandToRun.lastResult);
            if (getenv("FM_ENABLE_QUNIT"))
                [_console.connectWebView qResult:nextCommandToRun.lastResult event:nextCommandToRun function:@"FMPlayCommands"];
            if ([self isScreenshotOnFailure] || [self isScreenshotOnAll]) {
                [self saveScreenshot:nextCommandToRun];
            }
			failure = YES;
		} else {
            if ([self isScreenshotOnAll]) {
                [self saveScreenshot:nextCommandToRun];
            } 
        }
        
        // Reset retry count for next command
        retryCount = 0;
	}
    previousTime = nil;
    commandSpeed = nil;
	usleep(500000); // When playback is done, wait a sec before dropping the curtain
    
    if (csvIndex < [csvData count] && !getenv("FM_ENABLE_QUNIT"))
        [self performSelectorOnMainThread:@selector(playFrom:) withObject:0 waitUntilDone:YES];
    else
        [self performSelectorOnMainThread:@selector(playingDone) withObject:nil waitUntilDone:YES];
    
    if (csvIndex == [csvData count] && csvIndex != 0)
        csvIndex = 0;
    
	//[self performSelectorOnMainThread:@selector(playingDone) withObject:nil waitUntilDone:YES];
	
    //if (csvIndex == [csvData count])
        //csvIndex = 0;

	[pool release];  
}

- (void) playbackMonkeyEvent:(FMCommandEvent*)command {
    UIView* source = command.source;
    if (source != nil) {
        [source playbackMonkeyEvent:command];
    } else {
        command.lastResult = [NSString stringWithFormat:@"No %@ found with monkeyID \"%@\"", command.className, command.monkeyID];
    }  
}


- (void) runCommandRange:(NSArray*)array {
	[self runCommandsStartingFrom:[[array objectAtIndex:0] intValue] numberOfCommands:[[array objectAtIndex:1] intValue]];
}


- (void) runCommands {      
	[self runCommandsStartingFrom:0 numberOfCommands:[commands count]];
}

- (void) runCommandsStartingFrom:(NSNumber*)start {
	[self runCommandsStartingFrom:[start intValue] numberOfCommands:([commands count] - [start intValue])];
}



- (IBAction) clear:(id)sender {
	[commands removeAllObjects];	 
}

- (void)rotate:(FMCommandEvent*)command {
	UIInterfaceOrientation orientation = 0;
	if ([command.args count] > 0) {
		orientation = [((NSString*)[command.args objectAtIndex:0]) intValue];
	}			
	[FMUtils rotate:orientation];
}

- (void) save:(NSString*)file {
	NSLog(@"saving script \"%@\" to %@",file,[FMUtils scriptsLocation]);
	NSString* error;
	NSData* pList = [NSPropertyListSerialization dataFromPropertyList:commands format:NSPropertyListXMLFormat_v1_0 errorDescription:&error];
	if (error) {
		NSLog(@"%@", error);
		[error release];
	}
	//[self assureScriptsLocation];
	if (![file hasSuffix:@".fm"]) {
		file = [file stringByAppendingString:@".fm"];
	}	
	[FMUtils writeApplicationData:pList toFile:file];
	if ([file hasSuffix:@".fm"]) {
		file = [file stringByDeletingPathExtension];	
	}
	NSString* ocunitPath = file;
	//NSString* ocunitPath = [[NSString stringWithString:OCUNIT_PATH] stringByAppendingPathComponent:file];
	[self saveOCScript:ocunitPath];
    
    if (getenv("FM_ENABLE_UIAUTOMATION")) {
        NSString* uiautomationPath = file;
        //NSString* uiautomationPath = [[NSString stringWithString:UIAUTOMATION_PATH] stringByAppendingPathComponent:file];
        [self saveUIAutomationScript:uiautomationPath];
    } else {
        NSString* qunitPath = file;
        //NSString* qunitPath = [[NSString stringWithString:QUNIT_PATH] stringByAppendingPathComponent:file];
        [self saveQUnitScript:qunitPath];
    }
}

- (void) open:(NSString*)file {
	NSData* data = [FMUtils applicationDataFromFile:file]; 
	NSString* errorString = [NSString string]; 
	NSArray* array = [NSPropertyListSerialization propertyListFromData:data mutabilityOption:0 format:nil errorDescription:&errorString];
	NSLog(@"%@", errorString);
	if (array) {
		NSMutableArray* mutie = [[[NSMutableArray alloc] initWithCapacity:[array count]] autorelease];
		[mutie addObjectsFromArray:array];
		self.commands = mutie;
	}
	
	[self sendNotification:FMNotificationScriptOpened object:nil];
    
	
}

- (void) postCommandFrom:(UIView*)sender command:(NSString*)command args:(NSArray*)args {
	if (self.state == FMStateSuspended) {
		return;
	}
	if (!_lastCommandRecorded && lastCommandPosted.monkeyID && lastCommandPosted.monkeyID != [sender monkeyID]) {
		[self recordEvent:lastCommandPosted];
	}
	_lastCommandRecorded = NO;
	lastCommandPosted.command = command;
	if (sender) {
		lastCommandPosted.monkeyID = [sender monkeyID];
		lastCommandPosted.className = [NSString stringWithUTF8String:class_getName([sender class])];
	} else {
		lastCommandPosted.monkeyID = nil;
		lastCommandPosted.className = nil;
	}
	lastCommandPosted.args = args;
	[self sendNotification:FMNotificationCommandPosted object:sender];
}

- (NSUInteger) commandCount {
	return [self.commands count];
}

- (NSArray*) scripts {
    NSString *scriptsLocation = [FMUtils scriptsLocation];
	NSError* errorString = nil;
	NSArray* paths;
	NSFileManager* fileManager = [NSFileManager defaultManager];
	if (![[NSFileManager defaultManager] fileExistsAtPath:scriptsLocation]) {
		return emptyArray;
	}
	paths = [fileManager contentsOfDirectoryAtPath:scriptsLocation error:&errorString];
	if (errorString) {
		NSLog(@"%@",errorString);
		[errorString release];	
	}
	
	// filter out directories
	if (paths) {
		NSMutableArray* filtered = [[[NSMutableArray alloc] init] autorelease];
		BOOL isDirectory;
		NSString* scriptsLocation = [FMUtils scriptsLocation];
		for (int i=0; i<[paths count]; i++) {
			NSString* path = [paths objectAtIndex:i];
			if ([path hasPrefix:@"."]) {
				continue;
			}
			NSString* fullPath = [scriptsLocation stringByAppendingPathComponent:path];
			if ([fileManager fileExistsAtPath:fullPath isDirectory:&isDirectory]) {
				if (!isDirectory && [fullPath hasSuffix:@".fm"]) {
					[filtered addObject:path];
				}
			}
		}
		paths = filtered;
	}
	
	return paths;
    
}

- (void) delete:(NSString*)file {
    NSString *documentsDirectory = [FMUtils scriptsLocation];
    NSString *appFile = [documentsDirectory stringByAppendingPathComponent:file];
	NSError* errorString = nil;
	[[NSFileManager defaultManager] removeItemAtPath:appFile error:&errorString];
	NSLog(@"%@", errorString);
	[errorString release];
	
}

- (FMCommandEvent*)commandAt:(NSInteger)index {
	NSMutableDictionary* dict = [commands objectAtIndex:index];
	return [[[FMCommandEvent alloc] initWithDict:dict] autorelease];
	
}

- (void) deleteCommand:(NSInteger) index {
	[commands removeObjectAtIndex:index];
}


- (void) insertCommand:(NSInteger) index {
	FMCommandEvent* command = [[FMCommandEvent alloc] init];
	FMCommandEvent* prev = [self commandAt:index - 1];
	command.command = @"Verify";
	command.className = prev.className;
	command.monkeyID = prev.monkeyID;
	[commands insertObject:[command dict] atIndex:index];
	[command release];
}

- (FMCommandEvent*) lastCommand {
	NSInteger index = [commands count] - 1;
	
	NSMutableDictionary* dict = nil;
	if (index > -1) {
		dict = [commands objectAtIndex:index];
		return [[[FMCommandEvent alloc] initWithDict:dict] autorelease];		
	}
	
	return nil;
}

- (FMCommandEvent*) popCommand {
	NSInteger index = [commands count] - 1;
	
	NSMutableDictionary* dict = nil;
	if (index > -1) {
		dict = [commands objectAtIndex:index];
		[self deleteCommand:index];
		return [[[FMCommandEvent alloc] initWithDict:dict] autorelease];			
	}
	
	return nil;
}

- (void) moveCommand:(NSInteger)from to:(NSInteger)to {
	NSDictionary* mover = [[commands objectAtIndex:from] retain];
	if (to > from) {
		to--;
	}
	[commands removeObjectAtIndex:from];
	[commands insertObject:mover atIndex:to];
	[mover release];
}

- (NSInteger) firstErrorIndex {
	int i;
	for (i = 0; i < [commands count]; i++) {
		if ([self commandAt:i].lastResult) {
			return i;
		}
	}
	return -1;
}

- (FMCommandEvent*) lastCommandPosted {
	return lastCommandPosted;
}

- (NSString*) monkeyIDfor:(UIView*)view {
	NSString* value;;
	NSValue* key;
	key = [NSValue valueWithPointer:view];
	if ((value = [_monkeyIDs objectForKey:key])) {
		return value;
	}
	value = [NSString stringWithFormat:@"#%d", [FMUtils ordinalForView:view]];
	[_monkeyIDs setValue:value forKey:(id)key];
	return value;
}

- (BOOL) isOCnitRunnerPresent {
    return [[FoneMonkey sharedMonkey] respondsToSelector:@selector(runAllTests)];
}

- (void) open {
	[_console showConsole];
    
    if ([self isOCnitRunnerPresent]) {
        //[[FoneMonkey sharedMonkey] performSelector:@selector(setupObserver)];
        if (!getenv("FM_DISABLE_AUTOSTART")) {            
            [[FoneMonkey sharedMonkey] performSelector:@selector(runAllTests)];
        }
    }
}

- (void) openConsole {
	[_console showConsole];
}

- (void) hideConsole {
	[_console hideConsole];
}

- (void) closeConsole {
	[_console hideConsoleAndThen:nil];
}

- (BOOL) assureScriptsLocation {
	NSString *dataPath = [FMUtils scriptsLocation];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return [[NSFileManager defaultManager] createDirectoryAtPath:dataPath 
										 withIntermediateDirectories:YES 
														  attributes:nil error:nil]; //Create folder
	}
	return YES;
}

- (BOOL) assureOCUnitScriptDirectory {
	NSString *dataPath = [[FMUtils scriptsLocation] stringByAppendingPathComponent:OCUNIT_PATH];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return [[NSFileManager defaultManager] createDirectoryAtPath:dataPath 
										 withIntermediateDirectories:YES 
														  attributes:nil error:nil]; //Create folder
	}
	return YES;
}

- (void) saveOCScript:(NSString* ) filename {
	[self assureOCUnitScriptDirectory];
	NSString *path = [[NSBundle mainBundle] pathForResource:
					  @"objc" ofType:@"template"];
	NSError* error;
	NSString* s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (!s) {
		NSLog(@"Unable to create objective-c file: Unable to read objc.template: %@", [error description]);
		return;
	}
	int i;
	NSMutableString* code = [[NSMutableString alloc] init];
	for (i = 0; i < [commands count]; i++) {
		FMCommandEvent* command = [self commandAt:i];
		Class c = NSClassFromString(command.className);
		NSString* occmd;
		if (c) {
			occmd = [c objcCommandEvent:command];
		} else {
			occmd = [UIView objcCommandEvent:command];
		}
		if ([occmd hasPrefix:@"//"]) {
			[code appendFormat:@"\t%@\n", occmd];
		} else {
			[code appendFormat:@"\t[array addObject:%@];\n", occmd];
		}
	}
	s = [s stringByReplacingOccurrencesOfString:@"${TESTNAME}" withString:filename];
	s = [s stringByReplacingOccurrencesOfString:@"${CODE}" withString:code];
    
	[FMUtils writeString:s toFile:[filename stringByAppendingString:@".m"]];
	[code release];	
	
}

- (BOOL) assureUIAutomationScriptDirectory {
	NSString *dataPath = [[FMUtils scriptsLocation] stringByAppendingPathComponent:UIAUTOMATION_PATH];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return [[NSFileManager defaultManager] createDirectoryAtPath:dataPath 
										 withIntermediateDirectories:YES 
														  attributes:nil error:nil]; //Create folder
	}
	return YES;
}

- (BOOL) assureUIAutomationScriptSupport {
	NSString *dataPath = UIAUTOMATION_PATH;
	NSString* supportScriptFile = [dataPath stringByAppendingPathComponent:@"FoneMonkey.js"];
	//NSData* jsLib = [FMUtils applicationDataFromFile:supportScriptFile];
	//if (jsLib==nil || [jsLib length]<1) {
    [self assureUIAutomationScriptDirectory];
    NSString *path = [[NSBundle mainBundle] pathForResource:
                      @"FoneMonkey" ofType:@"jslib"];
    NSError* error;
    NSString* s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
    if (!s) {
        NSLog(@"Unable to create uiautomation file: Unable to read FoneMonkey.js resource: %@", [error description]);
        return false;
    }	
    [FMUtils writeString:s toFile:supportScriptFile];
	//}
	return true;
}

- (void) saveUIAutomationScript:(NSString* ) filename {
	if (! [self assureUIAutomationScriptSupport]) {
		return;
	}
	
	NSString *path = [[NSBundle mainBundle] pathForResource:
					  @"uiautomation" ofType:@"template"];
	NSError* error;
	NSString* s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (!s) {
		NSLog(@"Unable to create UIAutomation js file: Unable to read uiautomation.template: %@", [error description]);
		return;
	}
	int i;
	NSMutableString* code = [[NSMutableString alloc] init];
	for (i = 0; i < [commands count]; i++) {
		FMCommandEvent* command = [self commandAt:i];
		NSString* jscmd;
		Class c = NSClassFromString(command.className);
		if (c) {
			jscmd = [c uiAutomationCommand:command];
		} else {
			jscmd = [UIView uiAutomationCommand:command];
		}
		[code appendFormat:@"%@\n", jscmd];
	}
	s = [s stringByReplacingOccurrencesOfString:@"${TESTNAME}" withString:filename];
	s = [s stringByReplacingOccurrencesOfString:@"${CODE}" withString:code];
    
	[FMUtils writeString:s toFile:[filename stringByAppendingString:@".js"]];
	[code release];	
	
}

- (BOOL) assureQUnitScriptDirectory {
	NSString *dataPath = [[FMUtils scriptsLocation] stringByAppendingPathComponent:QUNIT_PATH];
	if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]) {
		return [[NSFileManager defaultManager] createDirectoryAtPath:dataPath 
										 withIntermediateDirectories:YES 
														  attributes:nil error:nil]; //Create folder
	}
	return YES;
}

- (void) saveQUnitScript:(NSString* ) filename {
	[self assureQUnitScriptDirectory];
	NSString *path = [[NSBundle mainBundle] pathForResource:
					  @"qunit" ofType:@"template"];
	NSError* error;
	NSString* s = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
	if (!s) {
		NSLog(@"Unable to create QUnit file: Unable to read qunit.template: %@", [error description]);
		return;
	}
	int i;
	NSMutableString* code = [[NSMutableString alloc] init];
	for (i = 0; i < [commands count]; i++) {
		FMCommandEvent* command = [self commandAt:i];
		Class c = NSClassFromString(command.className);
		NSString* occmd;
		if (c) {
			occmd = [c qunitCommandEvent:command];
		} else {
			occmd = [UIView qunitCommandEvent:command];
		}
		if ([occmd hasPrefix:@"//"]) {
			[code appendFormat:@"\t%@\n", occmd];
		} else {
			[code appendFormat:@"\t\tFM.commandList.addRetry(%@);\n", occmd];
		}
	}
	s = [s stringByReplacingOccurrencesOfString:@"${TESTNAME}" withString:filename];
	s = [s stringByReplacingOccurrencesOfString:@"${CODE}" withString:code];
    
	[FMUtils writeString:s toFile:[filename stringByAppendingString:@".js"]];
	[code release];	
	
}

@end
