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
//  MPMovieView+FMReady.h
//  FoneMonkey
//
//  Created by Kyle Balogh on 9/9/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MediaPlayer/MediaPlayer.h>
@class MPMoviePlayerController;

@protocol MPMovieViewDelegate;

@interface MPMovieView : UIView {
@private
	id<MPMovieViewDelegate> _delegate;
}
@property(assign, nonatomic) id<MPMovieViewDelegate> delegate;
-(void)willMoveToWindow:(id)window;
-(void)didMoveToWindow;
@end
@interface MPMovieView (FMReady)

@end

@interface MPFullScreenTransportControls
@end
@interface MPFullScreenTransportControls (FMDisable)

@end

@interface MPFullScreenVideoOverlay
@end
@interface MPFullScreenVideoOverlay (FMDisable)

@end

@interface MPVideoBackgroundView
@end
@interface MPVideoBackgroundView (FMDisable)

@end

@interface MPSwipableView
@end
@interface MPSwipableView (FMDisable)

@end

@interface MPTransportButton
@end
@interface MPTransportButton (FMDisable)

@end