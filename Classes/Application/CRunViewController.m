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
//  CRunViewController.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 02/04/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CRunViewController.h"
#import "CRunApp.h"

@implementation CRunViewController

-(id)initWithApp:(CRunApp*)pApp
{
	if (self=[super init])
	{
		runApp=pApp;
	}
	return self;
}

// Implement loadView to create a view hierarchy programmatically, without using a nib.
-(void)loadView
{
	appRect = CGRectMake(0, 0, runApp->gaCxWin, runApp->gaCyWin);
	screenRect = runApp->screenRect;
	
	runView = [[CRunView alloc] initWithFrame:appRect];
	
	//Smooth resizing option
	if((runApp->hdr2Options & AH2OPT_ANTIALIASED) == 0)
		runView.layer.magnificationFilter = kCAFilterNearest;
	
	runView.contentMode = UIViewContentModeScaleAspectFill;
	runView.autoresizingMask = UIViewAutoresizingNone;	
	runView.clipsToBounds = YES;
	
	self.view = runView;
	[runView release];
}

-(void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
}

-(void)dealloc 
{
	[runView release];	
    [super dealloc];
}

@end
