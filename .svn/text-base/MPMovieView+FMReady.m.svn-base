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
//  MPMovieView+FMReady.m
//  FoneMonkey
//
//  Created by Kyle Balogh on 9/9/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "MPMovieView+FMReady.h"
#import "FoneMonkey.h"
#import "FMCommandEvent.h"


@implementation MPMovieView (FMReady)

+ (void) load {
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(changed:) 
                                                 name:MPMoviePlayerPlaybackStateDidChangeNotification object:nil];
    
}

+ (void) changed:(NSNotification *)notification{
    MPMoviePlayerController* controller = (MPMoviePlayerController *)[notification object];
    
    MPMovieView *mpView = (MPMovieView *)controller.view;
    
    if ([controller playbackState] == MPMoviePlaybackStatePlaying)
        [FoneMonkey recordFrom:mpView command:FMCommandPlayMovie args:[NSArray arrayWithObject:[NSString stringWithFormat:@"%1.3f", controller.currentPlaybackTime]]];
    else if ([controller playbackState] == MPMoviePlaybackStatePaused)
        [FoneMonkey recordFrom:mpView command:FMCommandPauseMovie args:[NSArray arrayWithObject:[NSString stringWithFormat:@"%1.3f", controller.currentPlaybackTime]]];
}

- (void) playbackMonkeyEvent:(FMCommandEvent*)event {
    
	if ([event.command isEqual:FMCommandPlayMovie] || [event.command isEqual:FMCommandPauseMovie]) {
		if ([[event args] count] == 0) {
			event.lastResult = @"Requires 1 argument, but has %d", [event.args count];
			return;
		}
        
        MPMoviePlayerController *player = (MPMoviePlayerController *)self.delegate;
        
        NSTimeInterval time = [[event.args objectAtIndex:0] floatValue];
        
        
        [player setCurrentPlaybackTime:time];
        
        if ([event.command isEqualToString:FMCommandPlayMovie])
            [player pause];
        else if ([event.command isEqualToString:FMCommandPauseMovie])
            [player pause];
	} else {
		//[super playbackMonkeyEvent:event];
	}
}

@end

@implementation MPFullScreenTransportControls (FMDisable)

- (BOOL) isFMEnabled {
	return NO;
}

@end

@implementation MPFullScreenVideoOverlay (FMDisable)

- (BOOL) isFMEnabled {
	return NO;
}

@end

@implementation MPVideoBackgroundView (FMDisable)

- (BOOL) isFMEnabled {
	return NO;
}

@end

@implementation MPSwipableView (FMDisable)

- (BOOL) isFMEnabled {
	return NO;
}

@end

@implementation MPTransportButton (FMDisable)

- (BOOL) isFMEnabled {
	return NO;
}

@end