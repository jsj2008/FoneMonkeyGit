//
//  FMWebViewController.m
//  iWebDriver
//
//  Copyright 2009 Google Inc.
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "FMWebViewController.h"
#import "HTTPServerController.h"
#import "NSException+WebDriver.h"
#import "NSURLRequest+IgnoreSSL.h"
#import "UIResponder+SimulateTouch.h"
#import "WebDriverPreferences.h"
#import "WebDriverRequestFetcher.h"
#import "WebDriverUtilities.h"
#import "NSString+SBJSONFM.h"
#import <objc/runtime.h>
//#import "RootViewController.h"
#import <QuartzCore/QuartzCore.h>
#import <QuartzCore/CATransaction.h>
#import "GeoLocation.h"
#import "errorcodes.h"
#import "Element.h"
#import "Session.h"

#import "TFHpple.h"
#import "HTTPVirtualDirectory.h"
#import "HTTPVirtualDirectory+FindElement.h"
#import "FMUtils.h"

static const NSString* kGeoLocationKey = @"location";
static const NSString* kGeoLongitudeKey = @"longitude";
static const NSString* kGeoLatitudeKey = @"latitude";
static const NSString* kGeoAltitudeKey = @"altitude";
const int COLUMN_COUNT = 3;

@implementation FMWebViewController

typedef enum {
	COMMAND,
	ID,
    FIELD,
    ARGS
} fields;

@synthesize webView, delController, testComplete, errorIndex;

- (id) init {
    
    if ((self = [super init]))
    {
        [self setUp];
    }
    
    return self;
}

// Executed after the nib loads the interface.
// Configure the webview to match the mobile safari app.
- (void)viewDidLoad {
  [super viewDidLoad];
  
    [self setUp];
}

- (void) setUp
{
    [[self webView] setScalesPageToFit:NO];
    [[self webView] setDelegate:self];
    
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setMediaPlaybackRequiresUserAction)]) {
        [[self webView] setMediaPlaybackRequiresUserAction:NO];
    } else {
        //Too bad, though it seems iOS 3 supported this by default
    }
    
    lastJSResult_ = nil;
    
    // Creating a new session if auto-create is enabled
    //  if ([[RootViewController sharedInstance] isAutoCreateSession]) {
    [[HTTPServerController sharedInstance]
     httpResponseForQuery:@"/hub/session"
     method:@"POST"
     withData:[@"{\"browserName\":\"firefox\",\"platform\":\"ANY\","
               "\"javascriptEnabled\":false,\"version\":\"\"}"
               dataUsingEncoding:NSASCIIStringEncoding]];
    //  }
    
    WebDriverPreferences *preferences = [WebDriverPreferences sharedInstance];
    
    cachePolicy_ = [preferences cache_policy];
    NSURLCache *sharedCache = [NSURLCache sharedURLCache];
    [sharedCache setDiskCapacity:[preferences diskCacheCapacity]];
    [sharedCache setMemoryCapacity:[preferences memoryCacheCapacity]];
    
    if ([[preferences mode] isEqualToString: @"Server"]) {
        HTTPServerController* serverController = [HTTPServerController sharedInstance];
        [serverController setViewController:self];
        [self describeLastAction:[serverController status]];		
    } else {
        WebDriverRequestFetcher* fetcher = [WebDriverRequestFetcher sharedInstance]; 
        [fetcher setViewController:self];
        [self describeLastAction:[fetcher status]];		
    }
}

- (void)didReceiveMemoryWarning {
  NSLog(@"Memory warning recieved.");
  // TODO(josephg): How can we send this warning to the user? Maybe set the
  // displayed text; though that could be overwritten basically straight away.
  [super didReceiveMemoryWarning];
}

- (void)dealloc {
  [[self webView] setDelegate:nil];
//  [lastJSResult_ release];
  [super dealloc];
}

//- (UIWebView *)webView {
//  if (![[self view] isKindOfClass:[UIWebView class]]) {
//    NSLog(@"NIB error: FMWebViewController's view is not a UIWebView.");
//    return nil;
//  }
//  return (UIWebView *)[self view];
//}

- (BOOL)webView:(UIWebView *)webView2 
    shouldStartLoadWithRequest:(NSURLRequest *)request
    navigationType:(UIWebViewNavigationType)navigationType {
    
    if ([delController respondsToSelector:@selector(webView:shouldStartLoadWithRequest:navigationType:)])
        [delController webView:webView2 shouldStartLoadWithRequest:request navigationType:navigationType];

    [self runNextCommand];
    
  NSURL* url = [request URL];
  if ([[url scheme] isEqualToString:@"webdriver"]) {
//    NSLog(@"Received webdriver data from the current page: %@",
//        [url absoluteString]);

    NSString* action = [url host];
    if (action == nil) {
//      NSLog(@"No action specified; ignoring webdriver:// URL: %@",
//          [url absoluteString]);
      return NO;
    }

    NSString* jsonData = @"{}";
    if ([url query] != nil) {
      jsonData = [[url query]
          stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    }

    // TODO: catch malformed query data and broadcast an appropriate error.
    NSDictionary* data = (NSDictionary*) [jsonData JSONValue];
    [[NSNotificationCenter defaultCenter]
        postNotificationName:[NSString stringWithFormat:@"webdriver:%@", action]
                      object:self
                    userInfo:data];
    return NO;
  }

//  NSLog(@"shouldStartLoadWithRequest");
  return YES;
}

- (void)webViewDidStartLoad:(UIWebView *)webView2 {
    if ([delController respondsToSelector:@selector(webViewDidStartLoad:)])
        [delController webViewDidStartLoad:webView2];
//  NSLog(@"webViewDidStartLoad");
  [[NSNotificationCenter defaultCenter]
      postNotificationName:@"webdriver:pageLoad"
                    object:self];
  @synchronized(self) {
    numPendingPageLoads_ += 1;
  }
}

- (void)webViewDidFinishLoad:(UIWebView *)webView2 {
    if ([delController respondsToSelector:@selector(webViewDidFinishLoad:)])
        [delController webViewDidFinishLoad:webView2];
//  NSLog(@"finished loading");

  @synchronized(self) {
    numPendingPageLoads_ -= 1;
  }
}

- (void)webView:(UIWebView *)webView2 didFailLoadWithError:(NSError *)error {
  // This is a very troubled method. It can be called multiple times (for each
  // frame of webpage). It is sometimes called even when the page seems to have
  // loaded correctly.
  
  // Page loading errors are ignored because that's what WebDriver expects.
    if ([delController respondsToSelector:@selector(webView:didFailLoadWithError:)])
        [delController webView:webView2 didFailLoadWithError:error];
    
//  NSLog(@"*** WebView failed to load URL with error %@", error);
  if ([error code] == 101) {
    NSString *failingURLString = [[error userInfo] objectForKey:
                                  @"NSErrorFailingURLStringKey"];
    // This is an issue only with simulator due to lack of support for tel: url.
    if ([[failingURLString substringToIndex:4] isEqualToString:@"tel:"]) {
      @throw [NSException webDriverExceptionWithMessage:
              [NSString stringWithFormat:
               @"tel: url isn't supported in simulator"]
                                          andStatusCode:EUNHANDLEDERROR];
    }
  } else if (error.code == NSURLErrorCancelled) 
      return;

  @synchronized(self) {
    numPendingPageLoads_ -= 1;
  }
}

#pragma mark Web view controls

- (void)performSelectorOnWebView:(SEL)selector withObject:(id)obj {
  [[self webView] performSelector:selector withObject:obj];
}

- (void)waitForLoad {
  // TODO(josephg): Test sleep intervals on the device.
  // This delay should be long enough that the webview has isLoading
  // set correctly (but as short as possible - these delays slow down testing.)
  
  // - The problem with [view isLoading] is that it gets set in a separate
  // worker thread. So, right after asking the webpage to load a URL we need to
  // wait an unspecified amount of time before isLoading will correctly tell us
  // whether the page is loading content.
  
  [NSThread sleepForTimeInterval:0.2f];

  while ([[self webView] isLoading]) {
    // Yield.
    [NSThread sleepForTimeInterval:0.01f];
  }
  
  // The main view may be loaded, but there may be frames that are still
  // loading.
  while (true) {
    @synchronized(self) {
      if (numPendingPageLoads_ == 0) {
        break;
      }
    }
  }
}

// All method calls on the view need to be done from the main thread to avoid
// synchronization errors. This method calls a given selector in this class
// optionally with an argument.
//
// If called with waitUntilLoad:YES, we wait for a web page to be loaded in the
// view before returning.
- (void)performSelectorOnView:(SEL)selector
                   withObject:(id)value
                waitUntilLoad:(BOOL)wait {
  
  /* The problem with this method is that the UIWebView never gives us any clear
   * indication of whether or not it's loading and if so, when its done. Asking
   * it to load causes it to begin loading sometime later (isLoading returns NO
   * for awhile.) Even the |webViewDidFinishLoad:| method isn't a sure sign of
   * anything - it will be called multiple times, once for each frame of the
   * loaded page.
   * 
   * The result: The only effective method I can think of is nasty polling.
   */
  
  while ([[self webView] isLoading])
    [NSThread sleepForTimeInterval:0.01f];
  
  [[self webView] performSelectorOnMainThread:selector
                                   withObject:value
                                waitUntilDone:YES];
  
//  NSLog(@"loading %d", [[self webView] isLoading]);
  
  if (wait)
    [self waitForLoad];
}

// Get the specified URL and block until it's finished loading.
- (void)setURL:(NSDictionary *)urlMap {
  NSString *urlString = (NSString*) [urlMap objectForKey:@"url"];
  NSURLRequest *url = [NSURLRequest requestWithURL:[NSURL URLWithString:urlString]
                                       cachePolicy:cachePolicy_
                                   timeoutInterval:60];
  
  [self performSelectorOnView:@selector(loadRequest:)
                   withObject:url
                waitUntilLoad:YES];
}

- (void)back:(NSDictionary*)ignored {
  [self describeLastAction:@"back"];
  [self performSelectorOnView:@selector(goBack)
                   withObject:nil
                waitUntilLoad:YES];
}

- (void)forward:(NSDictionary*)ignored {
  [self describeLastAction:@"forward"];
  [self performSelectorOnView:@selector(goForward)
                   withObject:nil
                waitUntilLoad:YES];
}

- (void)refresh:(NSDictionary*)ignored {
  [self describeLastAction:@"refresh"];
  [self performSelectorOnView:@selector(reload)
                   withObject:nil
                waitUntilLoad:YES];
}

- (id)visible {
  // The WebView is always visible.
  return [NSNumber numberWithBool:YES];  
}

// Ignored.
- (void)setVisible:(NSNumber *)target {
}

// Execute js in the main thread and set lastJSResult_ appropriately.
// This function must be executed on the main thread. Its designed to be called
// using performSelectorOnMainThread:... which doesn't return a value - so
// the return value is passed back through a class parameter.
- (void)jsEvalInternal:(NSString *)script {
  // We wrap the eval command in a CATransaction so that we can explicitly
  // force any UI updates that might occur as a side effect of executing the
  // javascript to finish rendering before we return control back to the HTTP
  // server thread. We actually found some cases where the rendering was
  // finishing before control returned and so the core animation framework would
  // defer committing its implicit transaction until the next iteration of the
  // HTTP server thread's run loop. However, because you're only allowed to
  // update the UI on the main application thread, committing it on the HTTP
  // server thread would cause the whole application to crash.
  // This feels like it shouldn't be necessary but it was the only way we could
  // find to avoid the problem.
  [CATransaction begin];
//  [lastJSResult_ release];
  lastJSResult_ = nil;
  lastJSResult_ = [[[self webView]
                    stringByEvaluatingJavaScriptFromString:script] retain];
  [CATransaction commit];
  
  //NSLog(@"jsEval: %@ -> %@", script, lastJSResult_);
}

// Evaluate the given JS format string & arguments. Argument list is the same
// as [NSString stringWithFormat:...].
- (NSString *)jsEval:(NSString *)format, ... {
  if (format == nil) {
    [NSException raise:@"invalidArguments" format:@"Invalid arguments for jsEval"];
  }
  
  va_list argList;
  va_start(argList, format);
  NSString *script = [[[NSString alloc] initWithFormat:format
                                             arguments:argList]
                      autorelease];
  va_end(argList);
  
  [self performSelectorOnMainThread:@selector(jsEvalInternal:)
                         withObject:script
                      waitUntilDone:YES];
  
  return [[lastJSResult_ copy] autorelease];
}

- (NSString *)currentTitle {
  return [self jsEval:@"document.title"];
}

- (NSString *)source {
  return [self jsEval:@"new XMLSerializer().serializeToString(document);"];
}

// Takes a screenshot.
- (UIImage *)screenshot {
  UIGraphicsBeginImageContext([[self webView] bounds].size);
  [[self webView].layer renderInContext:UIGraphicsGetCurrentContext()];
  UIImage *viewImage = UIGraphicsGetImageFromCurrentImageContext();
  UIGraphicsEndImageContext();
  
  // dump the screenshot into a file for debugging
  //NSString *path = [[[NSSearchPathForDirectoriesInDomains
  //   (NSDocumentDirectory, NSUserDomainMask, YES) objectAtIndex:0]
  //  stringByAppendingPathComponent:@"screenshot.png"] retain];
  //[UIImagePNGRepresentation(viewImage) writeToFile:path atomically:YES];
  
  return viewImage;
}

- (NSString *)URL {
  return [self jsEval:@"window.location.href"];
}

- (void)describeLastAction:(NSString *)status {
  [statusLabel_ setText:status];
}

- (CGRect)viewableArea {
  CGRect area;
  area.origin.x = [[self jsEval:@"window.pageXOffset"] intValue];
  area.origin.y = [[self jsEval:@"window.pageYOffset"] intValue];
  area.size.width = [[self jsEval:@"window.innerWidth"] intValue];
  area.size.height = [[self jsEval:@"window.innerHeight"] intValue];
  return area;
}

- (BOOL)pointIsViewable:(CGPoint)point {
  return CGRectContainsPoint([self viewableArea], point);
}

// Scroll to make the given point centered on the screen (if possible).
- (void)scrollIntoView:(CGPoint)point {
  // Webkit will clip the given point if it lies outside the window.
  // It may be necessary at some stage to do this using touches.
  [self jsEval:@"window.scroll(%f - window.innerWidth / 2, %f - window.innerHeight / 2);", point.x, point.y];
}

// Translate pixels in webpage-space to pixels in view space.
- (CGPoint)translatePageCoordinateToView:(CGPoint)point {
  CGRect viewBounds = [[self webView] bounds];
  CGRect pageBounds = [self viewableArea];
  
  // ... And then its just a linear transformation.
  float scale = viewBounds.size.width / pageBounds.size.width;
  CGPoint transformedPoint;
  transformedPoint.x = (point.x - pageBounds.origin.x) * scale;
  transformedPoint.y = (point.y - pageBounds.origin.y) * scale;
  
  NSLog(@"%@ -> %@",
        NSStringFromCGPoint(point),
        NSStringFromCGPoint(transformedPoint));
  
  return transformedPoint;
}

- (void)clickOnPageElementAt:(CGPoint)point {
  if (![self pointIsViewable:point]) {
    [self scrollIntoView:point];
  }
  
  CGPoint pointInViewSpace = [self translatePageCoordinateToView:point];
  
  NSLog(@"simulating a click at %@", NSStringFromCGPoint(pointInViewSpace));
  [[self webView] simulateTapAt:pointInViewSpace];
}

// Gets the location
- (NSDictionary *)location {
  GeoLocation *locStorage = [GeoLocation sharedManager];
  CLLocationCoordinate2D coordinate = [locStorage getCoordinate];
  CLLocationDistance altitude = [locStorage getAltitude];

  return [NSDictionary dictionaryWithObjectsAndKeys:
          [NSDecimalNumber numberWithDouble:coordinate.longitude], kGeoLongitudeKey,
          [NSDecimalNumber numberWithDouble:coordinate.latitude], kGeoLatitudeKey, 
          [NSDecimalNumber numberWithFloat:altitude], kGeoAltitudeKey, nil];
}

// Sets the location
- (void)setLocation:(NSDictionary *)dict {
  NSDictionary *values = [dict objectForKey:kGeoLocationKey];
  NSDecimalNumber *altitude = [values objectForKey:kGeoAltitudeKey];
  NSDecimalNumber *longitude = [values objectForKey:kGeoLongitudeKey];
  NSDecimalNumber *latitude = [values objectForKey:kGeoLatitudeKey];
  
  GeoLocation *locStorage = [GeoLocation sharedManager];
  [locStorage setCoordinate:[longitude doubleValue]
                   latitude:[latitude doubleValue]];
  [locStorage setAltitude:[altitude doubleValue]];
}

// Finds out if browser connection is alive
- (NSNumber *)isBrowserOnline {
  BOOL onlineState = [[self jsEval:@"navigator.onLine"] isEqualToString:@"true"];
  return [NSNumber numberWithBool:onlineState];
}

#pragma mark - HTML Selenium

- (void)performSelectorOnElement:(Element *)element selector:(SEL)selector
                   withObject:(id)value
                waitUntilLoad:(BOOL)wait {
    
    /* The problem with this method is that the UIWebView never gives us any clear
     * indication of whether or not it's loading and if so, when its done. Asking
     * it to load causes it to begin loading sometime later (isLoading returns NO
     * for awhile.) Even the |webViewDidFinishLoad:| method isn't a sure sign of
     * anything - it will be called multiple times, once for each frame of the
     * loaded page.
     * 
     * The result: The only effective method I can think of is nasty polling.
     */
    
    while ([[self webView] isLoading])
        [NSThread sleepForTimeInterval:0.01f];
    
    [element performSelectorOnMainThread:selector
                                     withObject:value
                                  waitUntilDone:YES];
    
    if (wait)
        [self waitForLoad];
}

- (NSArray *) parseHtmlAtPath:(NSString *)path
{
    NSData *data = [[NSData alloc] initWithContentsOfFile:path];
    
    // Create parser
    TFHpple *xpathParser = [[TFHpple alloc] initWithHTMLData:data];
    
    //Get all the cells of the 2nd row of the 3rd table 
    NSArray *elements  = [xpathParser searchWithXPathQuery:@"//table[1]/tbody/tr"];
    int rowCount = [elements count];
    
    NSMutableArray *array = [[NSMutableArray alloc] init];
    
    for (int i = 1; i <= rowCount; i++) {
        NSString *query = [NSString stringWithFormat:@"//table[1]/tbody/tr[%i]/td",i];
        elements = [xpathParser searchWithXPathQuery:query];
        NSMutableArray *rowArray = [[NSMutableArray alloc] init];
        
        for (int j = 0; j < COLUMN_COUNT; j++) {
            TFHppleElement *element = [elements objectAtIndex:j];
            
            // Get the text within the cell tag
            NSString *content = [element content];  
            
            if (j == ID && content) {
                if ([content rangeOfString:@"//"].location != NSNotFound) {
                    [rowArray addObject:@"xpath"];
                    [rowArray addObject:content];
                } else if ([content rangeOfString:@"link="].location != NSNotFound) {
                    content = [content stringByReplacingOccurrencesOfString:@"link=" withString:@""];
                    [rowArray addObject:@"linkText"];
                    [rowArray addObject:content];
                } else if ([content rangeOfString:@"css="].location != NSNotFound) {
                    content = [content stringByReplacingOccurrencesOfString:@"css=" withString:@""];
                    [rowArray addObject:@"css"];
                    [rowArray addObject:content];
                }
                else if ([content rangeOfString:@"id="].location != NSNotFound) {
                    content = [content stringByReplacingOccurrencesOfString:@"id=" withString:@""];
                    [rowArray addObject:@"id"];
                    [rowArray addObject:content];
                } else {
                    [rowArray addObject:@"id"];
                    [rowArray addObject:content];
                }
            } else if (content)
                [rowArray addObject:content];
        }
        
        [array addObject:rowArray];
        [rowArray release];
    }

    return array;
    
    [xpathParser release];
    [data release];
}

- (void) seleniumFile:(NSString *)fileName speed:(double)speed timeout:(double)timeout
{
    
    NSString *tempSt = [NSString stringWithFormat:@"%@/%@", [FMUtils scriptsLocation], fileName];
    
    if (speed < 1000000)
        speed = 1000000;
    if (timeout < 1000000)
        timeout = 1000000;
    
    playbackSpeed = speed;
    playbackTimeout = timeout;
    
    commandList = [self parseHtmlAtPath:tempSt];
    commandIndex = 0;
    testComplete = nil;
    
    [self runCommandAtIndex:0];
}

- (void) performInBack:(NSString *)iString
{
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    if (playbackSpeed > 0)
        [NSThread sleepForTimeInterval:playbackSpeed/1000000];
    
    int i = [iString intValue];
    Session *session = [[[Session alloc] init] autorelease];
    HTTPVirtualDirectory *virtualDirectory = [[HTTPVirtualDirectory alloc] init];
    NSDictionary *response;
    Element *element;
    
    NSArray *commands = (NSArray *)[commandList objectAtIndex:i];
    
    NSDictionary *thisDict = [[NSMutableDictionary alloc] init];
    NSString *command = [commands objectAtIndex:COMMAND];
    NSString *commandId = [commands objectAtIndex:ID];
    NSString *field = [commands objectAtIndex:FIELD];
    NSString *args = nil;
    NSMutableDictionary *argsDict = nil;
    SEL selector = NSSelectorFromString([NSString stringWithFormat:@"%@:",command]);
    
    if ([commands count] == 4) {
        args = [commands objectAtIndex:ARGS];
        
        if ([command isEqualToString:@"type"])
            argsDict = [NSDictionary dictionaryWithObject:args forKey:@"value"];
    }
    
    [thisDict setValue:commandId forKey:@"using"];
    [thisDict setValue:field forKey:@"value"];
    
    
    NSDate* startTime = [NSDate dateWithTimeIntervalSinceNow:0];
    NSTimeInterval implicitWait = playbackTimeout/1000;
    response = [virtualDirectory findElement:thisDict root:nil implicitlyWait:0];
    
    while (![response objectForKey:@"ELEMENT"]) {
        response = [virtualDirectory findElement:thisDict root:nil implicitlyWait:0];
        
        NSDate* now = [NSDate dateWithTimeIntervalSinceNow:0];
        NSTimeInterval elapsedTime = [now timeIntervalSinceDate:startTime];
        
        if (elapsedTime > implicitWait) {
            [self throwScriptFailed:[field copy]];
            return;
        }
    }
    
    element = [Element elementWithId:[response objectForKey:@"ELEMENT"] andSession:session andFMWebViewController:self andCommandId:commandId];

    [element performSelectorOnMainThread:selector withObject:argsDict waitUntilDone:NO];
    
    commandIndex = i + 1;
    
    [thisDict release];
    [pool release];
}

- (void) runCommandAtIndex:(int)i
{
    [self performSelectorInBackground:@selector(performInBack:) withObject:[NSString stringWithFormat:@"%i",i]];
}

- (void) runNextCommand
{
    if (commandIndex == [commandList count])
        testComplete = @"YES";
    else
        testComplete = nil;
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
//        while ([webView isLoading]) {
//            usleep(5000);
//        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            if (commandIndex < [commandList count])
                [self runCommandAtIndex:commandIndex];
        }); 
    });
}

- (void) runAgain
{
    commandIndex -= 1;
    if (commandIndex < [commandList count])
        [self runCommandAtIndex:commandIndex];
}

- (void) throwScriptFailed:(NSString *)failureString
{
    errorIndex = commandIndex;
    testComplete = failureString;
    commandIndex = [commandList count];
}

@end
