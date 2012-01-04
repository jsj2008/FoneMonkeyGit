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
//  FMUtils.h
//  FoneMonkey
//
//  Created by Stuart Stern on 11/7/09.
//  Copyright 2009 Gorilla Logic, Inc.. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "FMCommandEvent.h"

#define FMOptionsLiveSwitch @"FMLiveSwitch"
#define FMOptionsLive @"FMLive"
#define FMOptionsFixed @"FMFixed"
#define FMOptionsTimeout @"FMTimeout"

// Set default pause to 1/2 sec between commands
#define DEFAULT_PLAYBACK 500
// Set default timeout (before retry gives up)
#define DEFAULT_TIMEOUT 100

@interface FMUtils : NSObject {

}

+ (UIWindow*) rootWindow;
+ (UIView*) viewWithMonkeyID:(NSString*)mid startingFromView:(UIView*)current havingClass:(Class)class;
+ (UIView*) viewWithMonkeyID:(NSString*)mid startingFromView:(UIView*)current havingClass:(Class)class swapsOK:(BOOL)swapsOK;
+ (NSInteger) ordinalForView:(UIView*)view;
+ (UIView*) findFirstMonkeyView:(UIView*)current;
+ scriptPathForFilename:(NSString*) fileName;
+ (BOOL)writeApplicationData:(NSData *)data toFile:(NSString *)fileName;
+ (BOOL)writeString:(NSString *)string toFile:(NSString *)fileName;
+ (NSData *)applicationDataFromFile:(NSString *)fileName;
+ (NSString*) scriptsLocation;
+ (void) navLeft:(UIView*)view to:(UIView*)to;
+ (void) navRight:(UIView*)view from:(UIView*)from;
+ (void) slideOut:(UIView*) view;
+ (void) slideIn:(UIView*) view;
+ (void) dismissKeyboard;
+ (void) shake;
+ (BOOL) isKeyboard:(UIView*)view;
+ (NSString*) stringByJsEscapingQuotesAndNewlines:(NSString*) unescapedString;
+ (NSString*) stringByOcEscapingQuotesAndNewlines:(NSString*) unescapedString;
+ (NSString*) stringForQunitTest:(NSString*)testCase inModule:(NSString *)module withResult:(NSString *)resultMessage;
+ (void) writeQunitToXmlWithString:(NSString*)xmlString testCount:(NSString *)testCount failCount:(NSString *)failCount runTime:(NSString *)runTime fileName:(NSString *)fileName;
+ (void) setShouldRecordMonkeyTouch:(BOOL)shouldRecord forView:(UIView*)view;
+ (NSString*) className:(NSObject*)ob;
+ (void) rotate:(UIInterfaceOrientation)orientation;
+ (void) interfaceChanged:(UIView *)view;
+ (void)rotateInterface:(UIView *)view degrees:(NSInteger)degrees frame:(CGRect)frame;
+ (NSString *)timeStamp;
+ (NSArray *) replaceArgForCommand:(NSArray *)commandArgs variables:(NSDictionary *)jsVariable;
+ (NSString *) replaceMonkeyIdForCommand:(NSString *)monkeyId variables:(NSDictionary *)jsVariable;
+ (NSString *) replaceString:(NSString *)origString variables:(NSDictionary *)jsVariable;
+ (NSMutableDictionary *) addVarsFrom:(FMCommandEvent *)event to:(NSMutableDictionary *)dict;
+ (void) saveUserDefaults:(NSString*)value forKey:(NSString*)key;
+ (NSString *) retrieveUserDefaultsForKey:(NSString*)key;
+ (double) playbackSpeedForCommand:(FMCommandEvent *)nextCommandToRun isLive:(BOOL)isLive retryCount:(int)retryCount;
+ (double) timeoutForCommand:(FMCommandEvent *)nextCommandToRun;
@end
