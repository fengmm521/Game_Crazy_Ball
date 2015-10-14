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
// CRuniPhoneButton
//
//----------------------------------------------------------------------------------
#import "CRuniOSButton.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CRunView.h"
#import "CServices.h"
#import "CImageBank.h"
#import "CImage.h"
#import "CObjectCommon.h"
#import "CFontInfo.h"


UIControlContentVerticalAlignment verticalAlign[4]=
{
	UIControlContentVerticalAlignmentTop, 
	UIControlContentVerticalAlignmentCenter, 
	UIControlContentVerticalAlignmentBottom,
	UIControlContentVerticalAlignmentFill
};
UIControlContentHorizontalAlignment horizontalAlign[4]=
{
	UIControlContentHorizontalAlignmentLeft, 
	UIControlContentHorizontalAlignmentCenter, 
	UIControlContentHorizontalAlignmentRight,
	UIControlContentHorizontalAlignmentFill
};



@implementation CRuniOSButton

-(int)getNumberOfConditions
{
	return 3;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoImgWidth=[file readAInt];
	ho->hoImgHeight=[file readAInt];
	type=[file readAShort];
    if (ho->hoCommon->ocVersion>=1)
    {
        flags=[file readAShort];
    }
	fontColor=[file readAColor];
	vAlign=[file readAShort];
	hAlign=[file readAShort];
	int n;
	for (n=0; n<4; n++)
	{
		images[n]=[file readAShort];
	}
	[ho loadImageList:images withLength:4];
	fontInfo=[file readLogFont];
	text=[file readAString];

	BOOL hasImages = (images[0] + images[1] + images[2] + images[3]) >= 0;

	if(hasImages)
		button=[UIButton buttonWithType:UIButtonTypeCustom];
	else
		button=[UIButton buttonWithType:type+1];

	button.backgroundColor = [UIColor clearColor];
	button.contentVerticalAlignment = verticalAlign[vAlign];
	button.contentHorizontalAlignment = horizontalAlign[hAlign];
	[button setTitle:text forState:UIControlStateNormal];
	[button setTitle:text forState:UIControlStateHighlighted];
	[button setTitle:text forState:UIControlStateSelected];
	[button setTitle:text forState:UIControlStateDisabled];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateNormal];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateHighlighted];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateSelected];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateDisabled];
	[button.titleLabel setFont:[fontInfo createFont]];

	[rh->rhApp positionUIElement:button withObject:ho];

	if (images[0]>=0)
	{
		UIImage* uiImg=[[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:images[0]] getUIImage];
		[button setImage:uiImg forState:UIControlStateNormal];
	}
	if (images[1]>=0)
	{
		UIImage* uiImg=[[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:images[1]] getUIImage];
		[button setImage:uiImg forState:UIControlStateHighlighted];
	}
	if (images[2]>=0)
	{
		UIImage* uiImg=[[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:images[2]] getUIImage];
		[button setImage:uiImg forState:UIControlStateSelected];
	}
	if (images[3]>=0)
	{
		UIImage* uiImg=[[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:images[3]] getUIImage];
		[button setImage:uiImg forState:UIControlStateDisabled];
	}
	
	clickCount=-1;
	[button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[ho->hoAdRunHeader->rhApp->runView addSubview:button];
	return YES;
}

- (void)buttonClicked:(id)sender 
{
	[rh resume];
	if (rh->rh2PauseCompteur==0)
	{
		clickCount=[ho getEventCount];
		[ho pushEvent:CND_BTNCLICK withParam:0];
	}
}

-(void)displayRunObject:(CRenderer*)renderer
{
	[rh->rhApp positionUIElement:button withObject:ho];
}
-(void)destroyRunObject:(BOOL)bFast
{
	[button removeTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
	[button removeFromSuperview];
	[fontInfo release];
	[text release];
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_BTNCLICK:
			return [self cndClick];
		case CND_BTNENABLED:
			return button.enabled;
		case CND_BTNVISIBLE:
			return !button.hidden;
	}        
	return NO;
}
-(BOOL)cndClick
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		rh->rhApp->lastInteraction = button.frame;
		return YES;
	}
	if ([ho getEventCount] == clickCount)
	{
		rh->rhApp->lastInteraction = button.frame;
		return YES;
	}
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{        
		case ACT_BTNENABLE:
			button.enabled=YES;
			break;
		case ACT_BTNDISABLE:
			button.enabled=NO;
			break;
		case ACT_BTNSETTEXT:
			[self setText:act];
			break;
		case ACT_BTNSHOW:
			button.hidden=NO;
			break;
		case ACT_BTNHIDE:
			button.hidden=YES;
			break;
	}
}
-(void)setText:(CActExtension*)act
{
	[text release];
	text=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]]; 
	[button setTitle:text forState:UIControlStateNormal];
	[button setTitle:text forState:UIControlStateHighlighted];
	[button setTitle:text forState:UIControlStateSelected];
	[button setTitle:text forState:UIControlStateDisabled];
}

// Actions
// -------------------------------------------------
-(CValue*)expression:(int)num
{
	if (num==EXP_BTNGETTEXT)
	{
		return [[CValue alloc] initWithString:text];
	}
	return nil;
}


//Fonts
-(CFontInfo*)getRunObjectFont
{
	return fontInfo;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[fontInfo release];
	fontInfo = fi;
	[button.titleLabel setFont:[fontInfo createFont]];
}

-(int)getRunObjectTextColor
{
	return fontColor;
}

-(void)setRunObjectTextColor:(int)rgb
{
	fontColor = rgb;
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateNormal];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateHighlighted];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateSelected];
	[button setTitleColor:getUIColor(fontColor) forState:UIControlStateDisabled];

}
	
@end
