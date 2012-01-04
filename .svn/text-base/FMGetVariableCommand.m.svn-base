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
//  FMGetVariableCommand.m
//  FoneMonkey
//
//  Created by Kyle Balogh on 8/23/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#define RETRIES 10
#define RETRY 500

#import "FMGetVariableCommand.h"


@implementation FMGetVariableCommand

+ (NSString*) execute:(FMCommandEvent*) ev {
	UIView* source = ev.source;		
    
    NSString* value;
    @try {
        NSString *objectProperty = [ev.args objectAtIndex:0];
        
        value = [source valueForKeyPath:objectProperty];

    } @catch (NSException* e)
    {
        // Handle exception
    }
    
    return value;
}

@end
