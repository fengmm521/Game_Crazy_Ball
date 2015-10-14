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
//  FillViewController.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 3/24/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "MainViewController.h"
#import "CRunApp.h"
#import "CRunView.h"
#import "MainView.h"

@implementation MainViewController

-(id)initWithRunApp:(CRunApp*)rApp
{
	if(self = [super init])
	{
		runApp = rApp;
	}
	return self;
}

- (void)loadView
{
	screenRect = runApp->screenRect;
	appRect = CGRectMake(0, 0, runApp->gaCxWin, runApp->gaCyWin);
	
	mainView = [[MainView alloc] initWithFrame:screenRect andRunApp:runApp];

	mainView.contentMode = UIViewContentModeScaleAspectFill;
	mainView.autoresizingMask = UIViewAutoresizingNone;
	mainView.backgroundColor = [UIColor blackColor];
	mainView.opaque = YES;

	self.view = mainView;
	[mainView release];
}

-(NSUInteger)supportedInterfaceOrientations
{
	return [runApp supportedOrientations];
}

-(BOOL)shouldAutorotate
{
	return YES;
}

-(BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)toInterfaceOrientation
{
	return [runApp supportsOrientation:toInterfaceOrientation];
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	UIInterfaceOrientation uiOrientation = [UIApplication sharedApplication].statusBarOrientation;
	switch (uiOrientation) {
		default:
		case UIInterfaceOrientationPortrait:
			runApp->actualOrientation = ORIENTATION_PORTRAIT;
			break;
		case UIInterfaceOrientationLandscapeLeft:
			runApp->actualOrientation = ORIENTATION_LANDSCAPELEFT;
			break;
		case UIInterfaceOrientationLandscapeRight:
			runApp->actualOrientation = ORIENTATION_LANDSCAPERIGHT;
			break;
		case UIInterfaceOrientationPortraitUpsideDown:
			runApp->actualOrientation = ORIENTATION_PORTRAITUPSIDEDOWN;
			break;
	}
}

-(void)presentViewController:(UIViewController *)viewControllerToPresent animated:(BOOL)flag
{
	if([self respondsToSelector:@selector(presentViewController:animated:completion:)])
		[self presentViewController:viewControllerToPresent animated:flag completion:nil];
#ifndef __IPHONE_6_0
	else if([self respondsToSelector:@selector(presentModalViewController:animated:)])
		[self presentModalViewController:viewControllerToPresent animated:flag];
#endif
}

-(void)dismissViewControllerAnimated:(BOOL)flag
{
	if([self respondsToSelector:@selector(dismissViewControllerAnimated:completion:)])
		[self dismissViewControllerAnimated:flag completion:nil];
#ifndef __IPHONE_6_0
	else if([self respondsToSelector:@selector(dismissModalViewControllerAnimated:)])
		[self dismissModalViewControllerAnimated:flag];
#endif
}

@end
