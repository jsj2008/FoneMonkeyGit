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
//  FMConnectWebView.m
//  FoneMonkey
//
//  Created by Kyle Balogh on 9/16/11.
//  Copyright 2011 Gorilla Logic, Inc. All rights reserved.
//

#import "FMConnectWebView.h"
#import "FMUtils.h"
#import "FoneMonkeyAPI.h"
#import "FoneMonkey.h"

@interface FMConnectWebView(Private)
- (void) jsFunction:(NSString *)function args:(NSArray *)args;
- (void) playCommands:(NSArray *)args;
- (void) getValue:(NSArray *)args;
- (void) writeResultsToXml:(NSArray *)args;
- (void) finishWritingXml:(NSArray *)args;
@end

@implementation FMConnectWebView

@synthesize xmlString,xmlFileName,jsVariables;

- (id)initWithFrame:(CGRect)frame 
{
    if (self = [super initWithFrame:frame]) {
        
        self.delegate = self;
        sbJson = [ SBJSONFM new ];
        NSString *script = @"";
        
        // Set script string to FM_ENABLE_QUNIT environment var
        if (getenv("FM_ENABLE_QUNIT"))
            script = [NSString stringWithUTF8String:getenv("FM_ENABLE_QUNIT")];
        
        // Build html path
        NSString *htmlPath = [[NSBundle mainBundle] pathForResource:@"FMObjConnect" ofType:@"html"];
        NSString *apiPath = [[NSBundle mainBundle] pathForResource:@"FMQunitAPI" ofType:@"jslib"];
        NSString *dirPath = [htmlPath stringByDeletingLastPathComponent];
        
        htmlPath = [htmlPath stringByAppendingFormat:@"?jsfile=%@",
                    [[FMUtils scriptsLocation] stringByAppendingPathComponent:script]];
        
        htmlPath = [htmlPath stringByAppendingFormat:@"&connectfile=%@",
                    [[NSBundle mainBundle] pathForResource:@"FMObjConnect" ofType:@"jslib"]];
        
        htmlPath = [htmlPath stringByAppendingFormat:@"&dirpath=%@", 
                    dirPath];
        
        htmlPath = [htmlPath stringByAppendingFormat:@"&apifile=%@", 
                    apiPath];
        
        NSURL *url = [NSURL URLWithString: [htmlPath stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]];
        
        // Load url with script paths
        [self loadRequest:[NSURLRequest requestWithURL:url]];
        
    }
    return self;
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.scalesPageToFit = YES;
}

- (BOOL) webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSString *req = [[request URL] absoluteString];
    
    if ([req hasPrefix:@"objconnect:"]) {
        NSArray *parameters = [req componentsSeparatedByString:@":"];
        
        NSString *function = [NSString stringWithFormat:@"%@",[parameters objectAtIndex:1]];
        NSString *args = [NSString stringWithFormat:@"%@",[[parameters objectAtIndex:2] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
        NSArray *argsArray = [NSArray arrayWithArray:[sbJson objectWithString:args error:nil]];
        
        [self jsFunction:function args:argsArray];
        
        return NO;
    }
    return YES;
}

- (void)qResult:(NSString *)result event:(FMCommandEvent *)commandEvent function:(NSString *)function
{
    if ([function isEqualToString:FMCommandDataDrive]) {
        [self returnFunction:function args:result,nil];
    } else if (![function isEqualToString:@"FMPlayCommands"]) {
        
        if (commandEvent.args && [jsVariables objectForKey:[NSString stringWithFormat:@"${%@}",[commandEvent.args objectAtIndex:1]]])
            [self performSelectorOnMainThread:@selector(returnValueForCommand:) withObject:commandEvent waitUntilDone:YES];
    } else
    {
        [self returnFunction:function args:result,nil];
    }
}

- (void)returnFunction:(NSString *)function args:(id)argument, ...;
{
    if ([function length] == 0) return;
    
    va_list args;
    NSMutableArray *results = [[NSMutableArray alloc] init];
    
    if(argument != nil){
        [results addObject:argument];
        va_start(args, argument);
        while((argument = va_arg(args, id)) != nil)
            [results addObject:argument];
        va_end(args);
    }
    
    NSString * js = [NSString stringWithFormat:@"FMObjConnect.result('%@',%@);",function,[sbJson stringWithObject:results allowScalar:YES error:nil]];
    
    [self performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:js waitUntilDone:NO];
    
    [results release];
}

- (void) jsFunction:(NSString *)function args:(NSArray *)args
{
    // Call Obj-C function relating to js
    if ([function isEqualToString:@"FMPlayCommands"])
    {
        [self playCommands:args];
    }
    else if ([function isEqualToString:@"FMGetValue"])
    {
        [self getValue:args];
    }
    else if ([function isEqualToString:@"FMWriteResults"])
    {
        [self writeResultsToXml:args];
    }
    else if ([function isEqualToString:@"FMWriteResultsDone"])
    {
        [self finishWritingXml:args];
    }
    else {        
        // Do something if function doesn't exist
        
        //NSLog(@"Tap: %@",function);
    }
}

- (void)returnValueForCommand:(FMCommandEvent *)commandEvent
{
    NSString* value = [FMGetVariableCommand execute:commandEvent];
    NSString* jsVariable = [commandEvent.args objectAtIndex:1];
    NSString *objectVariable = [NSString stringWithFormat:@"${%@}",jsVariable];
    
    // Set custom variable to property value
    [jsVariables setValue:value forKey:objectVariable];
    
    // Set variable in js
    [self performSelectorOnMainThread:@selector(stringByEvaluatingJavaScriptFromString:) withObject:[NSString stringWithFormat:@"var %@ = \"%@\";",jsVariable,value] waitUntilDone:YES];
    
    [self returnFunction:commandEvent.monkeyID args:value,nil];
}

- (void) playCommands:(NSArray *)args
{
    NSMutableArray *commands = (NSMutableArray *)args;
    NSMutableArray* array = [[NSMutableArray alloc] initWithCapacity:[commands count]];
    
    for (int i = 0; i < [commands count]; i++) {
        
        NSString *command = [[commands objectAtIndex:i] objectAtIndex:0];
        NSString *className = [[commands objectAtIndex:i] objectAtIndex:1];
        NSString *monkeyId = [[commands objectAtIndex:i] objectAtIndex:2];
        
        NSString *playback = nil;
        NSString *timeout = nil;
        
        NSMutableArray *args = nil;
        
        if ([[commands objectAtIndex:i] count] == 4)
        {
            args = (NSMutableArray *)[[commands objectAtIndex:i] objectAtIndex:3];
        } else if ([[commands objectAtIndex:i] count] == 6)
        {
            playback = [[commands objectAtIndex:i] objectAtIndex:3];
            timeout = [[commands objectAtIndex:i] objectAtIndex:4];
            args = (NSMutableArray *)[[commands objectAtIndex:i] objectAtIndex:5];
        }
        
        // If args do not have any values, set to nil
        if ([[NSString stringWithFormat:@"%@", args] rangeOfString:@"null"].location != NSNotFound)
            args = nil;
        
        if (args && [command isEqualToString:FMCommandGetVariable])
            [self getValue:args];
        
        [array addObject:[FMCommandEvent command:command className:className monkeyID:monkeyId delay:playback timeout:timeout args:args]];
    }
    
    [FoneMonkeyAPI playCommands:array];
    
    [array release];
}

- (void) getValue:(NSArray *)args
{
    NSString *variable = [NSString stringWithFormat:@"${%@}", [args objectAtIndex:1]];
    
    if (!jsVariables)
        jsVariables = [[NSMutableDictionary alloc] init];
    
    [jsVariables setValue:@"" forKey:variable];
}

- (void) writeResultsToXml:(NSArray *)args
{ 
    // While tests are running, populate xml string
    NSString *module = (NSString *)[args objectAtIndex:0];
    NSString *testCase = (NSString *)[args objectAtIndex:1];
    NSString *resultMessage = (NSString *)[args objectAtIndex:2];
    
    if ([self.xmlString length] == 0)
        self.xmlString = [NSString stringWithFormat:@"<?xml version=\"1.0\"?>%@",[FMUtils stringForQunitTest:testCase inModule:module withResult:resultMessage]];
    else
    {
        self.xmlString = [self.xmlString stringByAppendingString:[FMUtils stringForQunitTest:testCase inModule:module withResult:resultMessage]];
    }
}

- (void) finishWritingXml:(NSArray *)args
{ 
    // Write xml to file when test is completed
    NSString *testCount = (NSString *)[args objectAtIndex:0];
    NSString *failCount = (NSString *)[args objectAtIndex:1];
    NSString *runTime = (NSString *)[args objectAtIndex:2];
    
    if ([self.xmlFileName length] == 0)
        self.xmlFileName = [NSString stringWithFormat:@"FM_QUNIT_LOG-%@.xml", [FMUtils timeStamp]];
    
    [FMUtils writeQunitToXmlWithString:self.xmlString testCount:testCount failCount:failCount runTime:runTime fileName:self.xmlFileName];
}

-(void)dealloc
{
    [xmlString release];
    [xmlFileName release];
    [jsVariables release];
    [super dealloc];
}


@end
