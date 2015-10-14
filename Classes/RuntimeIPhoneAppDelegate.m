/* Copyright (c) 1996-2014 Clickteam
*
* This source code is part of the iOS exporter for Clickteam Multimedia Fusion 2
* and Clickteam Fusion 2.5.
* 
* Permission is hereby granted to any person obtaining a legal copy 
* of Clickteam Multimedia Fusion 2 or Clickteam Fusion 2.5 to use or modify this source 
* code for debugging, optimizing, or customizing applications created with 
* Clickteam Multimedia Fusion 2 and/or Clickteam Fusion 2.5. 
* Any other use of this source code is prohibited.
*
* THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
* IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
* FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
* AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
* LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
* FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
* IN THE SOFTWARE.
*/
//
//  RuntimeIPhoneAppDelegate.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 08/10/09.
//  Copyright Clickteam 2012. All rights reserved.
//

#import "RuntimeIPhoneAppDelegate.h"
#import "Services/CFile.h"	
#import "CRunApp.h"
#import "CRun.h"
#import "CIAdViewController.h"
#import "MainViewController.h"
#import "CRunViewController.h"
#import "CRunView.h"
#import "MainView.h"
#import "CALPlayer.h"
#import "CRun.h"
#import "CSoundPlayer.h"
#import "CArrayList.h"
#import "CIni.h"

#import <AVFoundation/AVFoundation.h>

#ifdef __IPHONE_7_0
#import <GameController/GameController.h>
#endif

void uncaughtExceptionHandler(NSException *exception)
{
    NSLog(@"CRASH: %@", exception);
    NSLog(@"Stack Trace: %@", [exception callStackSymbols]);
}

@implementation RuntimeIPhoneAppDelegate
@synthesize window;


-(NSUInteger)application:(UIApplication *)application supportedInterfaceOrientationsForWindow:(UIWindow *)window
{
	return [runApp supportedOrientations] | 2;
	//The "| 2" part is a workaround for UIPopoverController crash in iOS6.0.x (Fixed in iOS6.1)
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
	[[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
	
	appPath=[[NSBundle mainBundle] pathForResource: @"Application" ofType:@"cci"];
	runApp=[[CRunApp alloc] initWithPath:appPath];
	[CRunApp setRunApp:runApp];
	runApp->appDelegate = self;
	eventSubscribers = [[CArrayList alloc] init];
	[runApp load];
	
	[UIApplication sharedApplication].statusBarHidden = (runApp->bStatusBar==NO);
	
	// Set up the window and content view
    window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	runApp->window = window;

	mainViewController = [[MainViewController alloc] initWithRunApp:runApp];
	runViewController=[[CRunViewController alloc] initWithApp:runApp];
	
	MainView* mainView = (MainView*)[mainViewController view];
	CRunView* runView = (CRunView*)[runViewController view];
	[mainView addSubview:runView];
	
	[window setRootViewController:mainViewController];
	[window layoutIfNeeded];
	[window makeKeyAndVisible];

	iAdViewController=nil;
	if (runApp->hdr2Options&AH2OPT_ENABLEIAD)
		iAdViewController=[[CIAdViewController alloc] initWithApp:runApp andView:mainView];

	[runApp setIAdViewController:iAdViewController];
	[runApp setMainViewController:mainViewController];
	[runView initApplication:runApp];
	[runView setNeedsDisplay];
	return YES;
}

-(void)dealloc
{
	[appPath release];
	[runApp release];
	[runViewController release];
	[mainViewController release];
    [window release];
	[eventSubscribers release];
    [super dealloc];
}

-(void)applicationDidReceiveMemoryWarning:(UIApplication*)application
{
	if(runApp == nil || runApp->run == nil)
		return;
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(applicationDidReceiveMemoryWarning:)])
			[dlgobj applicationDidReceiveMemoryWarning:application];
	}
		
	if (runApp->iOSObject!=nil)
		[runApp->run callEventExtension:runApp->iOSObject withCode:3 andParam:0];
	[runApp cleanMemory];
}

-(void)applicationWillResignActive:(UIApplication *)application
{
	if(runApp == nil || runApp->run == nil)
		return;

	[CIni saveAllOpenINIfiles];
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(applicationWillResignActive:)])
			[dlgobj applicationWillResignActive:application];
	}
	
	if (runApp->run!=nil && runApp->run->rhObjectList != nil)
	{
        if (runApp->iOSObject!=nil)
        {
            [runApp->run callEventExtension:runApp->iOSObject withCode:2 andParam:0];
        }
        [runApp->run doRunLoop];
		[runApp->runView drawNoUpdate];
		[runApp->run pause];
		[runApp->ALPlayer beginInterruption];
	}
	[runViewController->runView pauseTimer];
}

-(void)applicationDidEnterBackground:(UIApplication *)application
{
	if(runApp == nil || runApp->run == nil)
		return;

	[CIni saveAllOpenINIfiles];
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(applicationDidEnterBackground:)])
			[dlgobj applicationDidEnterBackground:application];
	}
}

-(void)applicationWillEnterForeground:(UIApplication *)application
{
	if(runApp == nil || runApp->run == nil)
		return;
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(applicationWillEnterForeground:)])
			[dlgobj applicationWillEnterForeground:application];
	}
}

-(void)applicationDidBecomeActive:(UIApplication *)application
{
	if(runApp == nil)
		return;
	
	if (runApp->run!=nil)
	{
		[runApp->ALPlayer endInterruption];
		[runApp->run resume];

        [runApp->ALPlayer resetSources];
        if (runApp->iOSObject!=nil)
        {
            [runApp->run callEventExtension:runApp->iOSObject withCode:1 andParam:0];
        }
	}
	if(runViewController != nil && runViewController->runView != nil)
		[runViewController->runView resumeTimer];
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(applicationDidBecomeActive:)])
			[dlgobj applicationDidBecomeActive:application];
	}
}

-(void)applicationWillTerminate:(UIApplication *)application
{
	if(runApp == nil)
		return;

	[CIni saveAllOpenINIfiles];
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(applicationWillTerminate:)])
			[dlgobj applicationWillTerminate:application];
	}
	
	if (runApp->run!=nil)
		[runApp->run killRunLoop:0 keepSounds:NO];
	
	[[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
	[runApp endApplication];
	[runApp release];
	runApp=nil;
}

-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken
{
	if(runApp == nil || runApp->run == nil)
		return;
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(application:didRegisterForRemoteNotificationsWithDeviceToken:)])
			[dlgobj application:application didRegisterForRemoteNotificationsWithDeviceToken:deviceToken];
	}
}

-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error
{
	if(runApp == nil || runApp->run == nil)
		return;
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(application:didFailToRegisterForRemoteNotificationsWithError:)])
			[dlgobj application:application didFailToRegisterForRemoteNotificationsWithError:error];
	}
}

-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo
{
	if(runApp == nil || runApp->run == nil)
		return;
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(application:didReceiveRemoteNotification:)])
			[dlgobj application:application didReceiveRemoteNotification:userInfo];
	}
}

-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification
{
	if(runApp == nil || runApp->run == nil)
		return;
	
	int eventCount = [eventSubscribers size];
	for(int i=0; i<eventCount; ++i)
	{
		id<UIApplicationDelegate> dlgobj = (id<UIApplicationDelegate>)[eventSubscribers get:i];
		if([dlgobj respondsToSelector:@selector(application:didReceiveLocalNotification:)])
			[dlgobj application:application didReceiveLocalNotification:notification];
	}
}

@end
