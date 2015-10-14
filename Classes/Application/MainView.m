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
//  MainView.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 3/30/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "MainView.h"
#import "CRunView.h"
#import "CRunApp.h"

@implementation MainView

-(id)initWithFrame:(CGRect)rect andRunApp:(CRunApp*)rApp
{
	if(self = [super initWithFrame:rect])
	{
		screenRect = rect;
		runApp = rApp;
		return self;
	}
	return nil;
}

-(BOOL)pointInside:(CGPoint)point withEvent:(UIEvent *)event
{
	return YES;
}

-(void)layoutSubviews
{
	if([self.subviews count] == 0)
		return;
		
	CRunView* runView = (CRunView*)[self.subviews objectAtIndex:0];
	CRunApp* rhApp = runView->pRunApp;
	
	if(rhApp == nil)
		return;
	
	CGSize s = [rhApp windowSize];
	CGSize z = screenRect.size;	
	CGSize a = runView->appRect.size;
	float scale = MIN(z.width/a.width, z.height/a.height);
	
	//Center in screen
	viewScaleX = viewScaleY = scale;
	CGAffineTransform t = CGAffineTransformMakeScale(viewScaleX, viewScaleY);
	
	if(rhApp->viewMode == VIEWMODE_STRETCH)
	{
		viewScaleX = z.width/a.width;
		viewScaleY = z.height/a.height;
		t = CGAffineTransformMakeScale(viewScaleX, viewScaleY);
	}
	runView.center = CGPointMake(s.width/2.0, s.height/2.0);
	
	//Set status bar orientation (fix for Q&A UIAlertViews showing in wrong orientation)
	UIInterfaceOrientation orientation = UIInterfaceOrientationPortrait;
	switch (runApp->actualOrientation)
	{
		case ORIENTATION_PORTRAIT:
			orientation = UIInterfaceOrientationPortrait; break;
		case ORIENTATION_PORTRAITUPSIDEDOWN:
			orientation = UIInterfaceOrientationPortraitUpsideDown; break;
		case ORIENTATION_LANDSCAPELEFT:
			orientation = UIInterfaceOrientationLandscapeLeft; break;
		case ORIENTATION_LANDSCAPERIGHT:
			orientation = UIInterfaceOrientationLandscapeRight; break;
	}
	[UIApplication sharedApplication].statusBarOrientation = orientation;
	
	NSString* systemVersion = [UIDevice currentDevice].systemVersion;
	if([systemVersion hasPrefix:@"4"])
	{
	    int sWidth=(int)(s.width*[UIScreen mainScreen].scale);
		if (sWidth==640)
		{
			switch(rhApp->actualOrientation)
			{
				case ORIENTATION_PORTRAIT:
				case ORIENTATION_PORTRAITUPSIDEDOWN:
					if((int)a.width == 768)
					{
						t=CGAffineTransformTranslate(t, 0, -3);
					}
					break;
				case ORIENTATION_LANDSCAPELEFT:
					if((int)a.width == 1024)
					{
						t=CGAffineTransformTranslate(t, 326, -840);                        
					}
					break;
				case ORIENTATION_LANDSCAPERIGHT:
					if((int)a.width == 1024)
					{
						t=CGAffineTransformTranslate(t, -328, 844);                        
					}
					break;
			}
		}
		else if (sWidth==768)
		{
			switch(rhApp->actualOrientation)
			{
				case ORIENTATION_PORTRAIT:
				case ORIENTATION_PORTRAITUPSIDEDOWN:
					switch((int)a.width)
                {
                    case 320:
                        t=CGAffineTransformTranslate(t, 2, 0);
                        break;
                    case 640:
                        t=CGAffineTransformTranslate(t, 2, 0);
                        break;
                }
					break;
				case ORIENTATION_LANDSCAPELEFT:
					switch((int)a.width)
                {
                    case 480:
                        t=CGAffineTransformTranslate(t, -3, 3);
                        break;
                    case 960:
                        t=CGAffineTransformTranslate(t, -180, -86);
                        break;
                    case 1024:
                    default:
                        runView.center = CGPointMake(s.width/2.0, s.height/2.0);
                        break;
                }
					break;
				case ORIENTATION_LANDSCAPERIGHT:
					switch((int)a.width)
                {
                    case 480:
                        t=CGAffineTransformTranslate(t, 164, -70);
                        break;
                    case 960:
                        t=CGAffineTransformTranslate(t, 180, 96);
                        break;
                }
					break;
			}
		}
		else if (sWidth==960)
		{
			switch(rhApp->actualOrientation)
			{
				case ORIENTATION_PORTRAIT:
				case ORIENTATION_PORTRAITUPSIDEDOWN:
					switch((int)a.width)
                {
                    case 320:
                        t=CGAffineTransformTranslate(t, 2, 0);
                        break;
                    case 640:
                        t=CGAffineTransformTranslate(t, 2, 0);
                        break;
                }
					break;
				case ORIENTATION_LANDSCAPELEFT:
					switch((int)a.width)
                {
                    case 1024:
                        t=CGAffineTransformTranslate(t, -3, 0);
                        break;
                    default:
                        break;
                }
					break;
				case ORIENTATION_LANDSCAPERIGHT:
					switch((int)a.width)
                {
                    case 1024:
                        t=CGAffineTransformTranslate(t, -3, 0);
                        break;
                    default:
                        break;
                }
					break;
			}
		}
		else if (sWidth==1024)
		{
			switch(rhApp->actualOrientation)
			{
				case ORIENTATION_PORTRAIT:
				case ORIENTATION_PORTRAITUPSIDEDOWN:
					switch((int)a.width)
                {
                    case 320:
                        t=CGAffineTransformTranslate(t, 2, 0);
                        break;
                    case 640:
                        t=CGAffineTransformTranslate(t, 2, 0);
                        break;
                }
					break;
				case ORIENTATION_LANDSCAPELEFT:
					switch((int)a.width)
                {
                    case 480:
                        t=CGAffineTransformTranslate(t, 0, -3);
                        break;
                    case 960:
                        t=CGAffineTransformTranslate(t, 0, -3);
                        break;
                    case 1024:
                    default:
                        runView.center = CGPointMake(s.width/2.0, s.height/2.0);
                        break;
                }
					break;
				case ORIENTATION_LANDSCAPERIGHT:
					switch((int)a.width)
                {
                    case 480:
                        t=CGAffineTransformTranslate(t, 0, -3);
                        break;
                    case 960:
                        t=CGAffineTransformTranslate(t, 0, -2);
                        break;
                }
					break;
			}
		}
    }
	runView.transform = t;
}



@end
