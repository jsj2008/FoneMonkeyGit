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
//  FMConsoleController.h
//  FoneMonkey
//
//  Created by Stuart Stern on 11/7/09.
//  Copyright 2009 Gorilla Logic, Inc.. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "FMConnectWebView.h"
#import "FMQunitView.h"


@interface FMConsoleController : UIViewController<UITextFieldDelegate> {
	UIView* moreView;
	UITableView* eventView;
	UISegmentedControl* controlBar;
    UIToolbar* toolBar;
    UIBarButtonItem *scriptButton;
    FMConnectWebView *connectWebView;
    FMQunitView *qUnitView;
    UIView *tableHeaderView;
    
    UITextField *liveTextField;
    UITextField *fixedTextField;
    UITextField *timeoutTextField;
    UISwitch *liveSwitch;
    UIButton *optionsButton;
}

@property (nonatomic, retain) IBOutlet UIView* moreView;
@property (nonatomic, retain) IBOutlet UITableView* eventView;
@property (nonatomic, retain) IBOutlet UISegmentedControl* controlBar;
@property (nonatomic, retain) IBOutlet UIToolbar* toolBar;
@property (nonatomic, retain) IBOutlet UIBarButtonItem *scriptButton;
@property (nonatomic, retain) FMConnectWebView *connectWebView;
@property (nonatomic, retain) FMQunitView *qUnitView;
@property (nonatomic, retain) IBOutlet UIView *tableHeaderView;
@property (nonatomic, retain) IBOutlet UITextField *liveTextField;
@property (nonatomic, retain) IBOutlet UITextField *fixedTextField;
@property (nonatomic, retain) IBOutlet UITextField *timeoutTextField;
@property (nonatomic, retain) IBOutlet UISwitch *liveSwitch;
@property (nonatomic, retain) UIButton *optionsButton;
- (IBAction) doMonkeyAction:(id)sender;
- (IBAction) save:(id)sender;
- (IBAction) open:(id)sender;
- (IBAction) gorilla:(id)sender;
- (IBAction) clear:(id)sender;
- (IBAction) editCommands:(id) sender;
- (IBAction) insertCommands:(id) sender;
- (IBAction)showView:(id)sender;
- (IBAction)showOptions:(id)sender;
- (IBAction) textInput:(id)sender;
- (IBAction) switchChanged:(id)sender;

- (void) monkeySuspended:(NSNotification*)notification;
-(void) refresh;
- (void) hideConsole;
- (void) showConsole;
- (void) hideConsoleQunit;
- (void) showConsoleQunit;

+ (FMConsoleController*) sharedInstance;
@end
