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
//  FMConnectWebView.h
//  FoneMonkey
//
//  Created by Kyle Balogh on 9/16/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "SBJSONFM.h"
#import <UIKit/UIWebView.h>
#import "FMCommandEvent.h"
#import "FMGetVariableCommand.h"

@interface FMConnectWebView : UIWebView <UIWebViewDelegate> {
    SBJSONFM *sbJson;
    
    NSString *xmlString;
    NSString *xmlFileName;
    NSMutableDictionary *jsVariables;
}

@property(nonatomic,retain)NSString *xmlString;
@property(nonatomic,retain)NSString *xmlFileName;
@property(nonatomic,retain)NSMutableDictionary *jsVariables;

- (void)qResult:(NSString *)result event:(FMCommandEvent *)commandEvent function:(NSString *)callBack;
- (void)returnFunction:(NSString *)function args:(id)argument, ...;
- (void)returnValueForCommand:(FMCommandEvent *)commandEvent;

@end
