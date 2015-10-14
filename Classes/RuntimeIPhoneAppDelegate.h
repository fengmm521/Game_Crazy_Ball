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
//  RuntimeIPhoneAppDelegate.h
//  RuntimeIPhone
//
//  Created by Francois Lionet on 08/10/09.
//  Copyright Clickteam 2012. All rights reserved.
//

#import <UIKit/UIKit.h>

@class CRunView;
@class CRunApp;
@class CIAdViewController;
@class MainViewController;
@class CRunViewController;
@class CArrayList;

void uncaughtExceptionHandler(NSException *exception);

@interface RuntimeIPhoneAppDelegate : NSObject <UIApplicationDelegate>
{
	CRunApp* runApp;
    UIWindow* window;
	CRunViewController* runViewController;
	MainViewController* mainViewController;
	CIAdViewController* iAdViewController;
	NSString* appPath;

@public
	CArrayList* eventSubscribers;
}

-(BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions;
-(void)dealloc;
-(void)applicationDidReceiveMemoryWarning:(UIApplication*)application;
-(void)applicationWillResignActive:(UIApplication *)application;
-(void)applicationDidEnterBackground:(UIApplication *)application;
-(void)applicationWillEnterForeground:(UIApplication *)application;
-(void)applicationDidBecomeActive:(UIApplication *)application;
-(void)applicationWillTerminate:(UIApplication *)application;
-(void)application:(UIApplication *)application didRegisterForRemoteNotificationsWithDeviceToken:(NSData *)deviceToken;
-(void)application:(UIApplication *)application didFailToRegisterForRemoteNotificationsWithError:(NSError *)error;
-(void)application:(UIApplication *)application didReceiveRemoteNotification:(NSDictionary *)userInfo;
-(void)application:(UIApplication *)application didReceiveLocalNotification:(UILocalNotification *)notification;

@property (nonatomic, retain) IBOutlet UIWindow *window;

@end

