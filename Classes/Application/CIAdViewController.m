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
//----------------------------------------------------------------------------------
//
// CIADVIEWCONTROLLER
//
//----------------------------------------------------------------------------------
#import "CIAdViewController.h"
#import "CRunApp.h"
#import "CRunView.h"
#import "CRunViewController.h"
#import "CRun.h"
#import "MainView.h"

@implementation CIAdViewController

-(id)initWithApp:(CRunApp*)a andView:(MainView*)rView
{
	if ((self=[super init]))
	{
		app=a;
		mainView=rView;
		adView=[[ADBannerView alloc] initWithAdType:ADAdTypeBanner];
		adView.delegate=self;
		bShown=NO;
		bAdAuthorised=NO; //Changed so no frame that isn't iAD authorized will show any adds.
		
		[self positioniAD];
		[rView addSubview:adView];
	}
	return self;
}

-(void)positioniAD
{
	switch(app->actualOrientation)
	{
		case ORIENTATION_PORTRAIT:
		case ORIENTATION_PORTRAITUPSIDEDOWN:
			adView.requiredContentSizeIdentifiers=[NSSet setWithObject:ADBannerContentSizeIdentifierPortrait];
			adView.currentContentSizeIdentifier=ADBannerContentSizeIdentifierPortrait;
			break;
		case ORIENTATION_LANDSCAPERIGHT:
		case ORIENTATION_LANDSCAPELEFT:
			adView.requiredContentSizeIdentifiers=[NSSet setWithObject:ADBannerContentSizeIdentifierLandscape];
			adView.currentContentSizeIdentifier=ADBannerContentSizeIdentifierLandscape;
			break;
	}

	CGSize ad = [self getiADSize];
	CGSize screen = [app windowSize];

	if (app->hdr2Options&AH2OPT_IADBOTTOM)
	{
		outPoint = CGPointMake(screen.width/2, screen.height+ad.height/2);
		inPoint = CGPointMake(screen.width/2, screen.height-ad.height/2);
	}
	else
	{
		outPoint = CGPointMake(screen.width/2, -ad.height/2);
		inPoint = CGPointMake(screen.width/2, ad.height/2);
	}
	
	if(bShown)
		adView.center = inPoint;
	else
		adView.center = outPoint;
}

-(CGSize)getiADSize
{
	//Always get the iAD dimensions in landscape mode
	CGSize ad = adView.bounds.size;
	if(ad.height > ad.width)
		return CGSizeMake(ad.height, ad.width);
	return ad;
}


-(void)bannerViewDidLoadAd:(ADBannerView*)banner
{
	bAdOK=YES;
	if (bShown==NO && bAdAuthorised==YES)
	{
		[UIView beginAnimations:@"animateAdBannerOff" context:NULL];
		adView.center = inPoint;
		[UIView commitAnimations];
		bShown=YES;
	}
}
-(void)bannerView:(ADBannerView*)banner didFailToReceiveAdWithError:(NSError*)error
{
	bAdOK=NO;
	if (bShown)
	{
		[UIView beginAnimations:@"animateAdBannerOff" context:NULL];
		adView.center = outPoint;
		[UIView commitAnimations];
		bShown=NO;
	}
}
-(void)setAdAuthorised:(BOOL)bAuthorised
{
	if (bAuthorised!=bAdAuthorised)
	{
		bAdAuthorised=bAuthorised;
		if (bAdAuthorised)
		{
			if (bShown==NO && bAdOK==YES)
			{			
				[self bannerViewDidLoadAd:nil];
			}
		}
		else
		{
			if (bShown)
			{
				BOOL oldBAdOK=bAdOK;
				[self bannerView:nil didFailToReceiveAdWithError:nil];
				bAdOK=oldBAdOK;
			}
		}
	}
}
-(BOOL)bannerViewActionShouldBegin:(ADBannerView*)banner willLeaveApplication:(BOOL)willLeave
{
	if (!willLeave)
	{
		if (app->run!=nil)
		{
			[app->run pause];
		}
		[app->runView pauseTimer];		
	}
	return YES;
}
-(void)bannerViewActionDidFinish:(ADBannerView *)banner
{
	if (app->run!=nil)
	{
		[app->run resume];
	}
	[app->runView resumeTimer];
}
@end
