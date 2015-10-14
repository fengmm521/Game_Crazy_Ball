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
// CRunkcbutton
//
//----------------------------------------------------------------------------------
#import "CRunkcbutton.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CImageBank.h"
#import "CServices.h"
#import "CFontInfo.h"
#import <AudioToolbox/AudioToolbox.h>

#define CND_BOXCHECK 0
#define CND_CLICKED 1
#define CND_BOXUNCHECK 2
#define CND_VISIBLE 3
#define CND_ISENABLED 4
#define CND_ISRADIOENABLED 5
#define CND_LAST 6
#define ACT_CHANGETEXT 0
#define ACT_SHOW 1
#define ACT_HIDE 2
#define ACT_ENABLE 3
#define ACT_DISABLE 4
#define ACT_SETPOSITION 5
#define ACT_SETXSIZE 6
#define ACT_SETYSIZE 7
#define ACT_CHGRADIOTEXT 8
#define ACT_RADIOENABLE 9
#define ACT_RADIODISABLE 10
#define ACT_SELECTRADIO 11
#define ACT_SETXPOSITION 12
#define ACT_SETYPOSITION 13
#define ACT_CHECK 14
#define ACT_UNCHECK 15
#define ACT_SETCMDID 16
#define ACT_SETTOOLTIP 17
#define ACT_LAST 18
#define EXP_GETXSIZE 0
#define EXP_GETYSIZE 1
#define EXP_GETX 2
#define EXP_GETY 3
#define EXP_GETSELECT 4
#define EXP_GETTEXT 5
#define EXP_GETTOOLTIP 6
#define EXP_LAST 7
#define BTNTYPE_PUSHTEXT 0
#define BTNTYPE_CHECKBOX 1
#define BTNTYPE_RADIOBTN 2
#define BTNTYPE_PUSHBITMAP 3
#define BTNTYPE_PUSHTEXTBITMAP 4
#define ALIGN_ONELINELEFT 0
#define ALIGN_CENTER 1
#define ALIGN_CENTERINVERSE 2
#define ALIGN_ONELINERIGHT 3
#define BTN_HIDEONSTART 0x0001
#define BTN_DISABLEONSTART 0x0002
#define BTN_TEXTONLEFT 0x0004
#define BTN_TRANSP_BKD 0x0008
#define BTN_SYSCOLOR 0x0010

@implementation CRunkcbutton

-(int)getNumberOfConditions
{
	return CND_LAST;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    // Read in edPtr values
    ho->hoImgWidth = [file readAShort];
    ho->hoImgHeight = [file readAShort];
    buttonType = [file readAShort];
    buttonCount = [file readAShort];
    flags = [file readAInt];
    fontInfo = [file readLogFont];
    foreColour = [file readAColor];
    backColour = [file readAColor];
	text = nil;
	button = nil;
	bswitch = nil;
    
    int i;
    for (i = 0; i < 3; i++)
    {
        buttonImages[i] = [file readAShort];
    }
	
	switch(buttonType)
	{
		case BTNTYPE_PUSHTEXT:
		{
			button=[UIButton buttonWithType:1];
			break;
		}
		case BTNTYPE_PUSHTEXTBITMAP:
		{
			[ho loadImageList:buttonImages withLength:3];
			button=[UIButton buttonWithType:0];
			break;
		}
		case BTNTYPE_PUSHBITMAP:
		{
			[ho loadImageList:buttonImages withLength:3];
			button=[UIButton buttonWithType:0];
			ho->hoImgWidth = 1;
			ho->hoImgHeight = 1;
			for (i = 0; i < 3; i++)
			{
				if (buttonImages[i]!=-1)
				{
					CImage* image=[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:buttonImages[i]];
					ho->hoImgWidth = MAX(ho->hoImgWidth, image->width);
					ho->hoImgHeight = MAX(ho->hoImgHeight, image->height);
				}
			}
			break;
		}
		case BTNTYPE_CHECKBOX:
		{
			bswitch = [[UISwitch alloc] initWithFrame:CGRectMake(ho->hoX, ho->hoY, ho->hoImgWidth, ho->hoImgHeight)];
			break;
		}
		case BTNTYPE_RADIOBTN:	//Not supported yet (PickerView?)
			return YES;
	}

    [file readAShort]; // fourth word in img array
    [file readAInt]; // ebtnSecu
    alignImageText = [file readAShort];    
    text=[file readAString];
    	
	if(button != nil)
	{
		control = button;
		button.backgroundColor = [UIColor clearColor];
		button.contentVerticalAlignment = UIControlContentVerticalAlignmentCenter;
		button.contentHorizontalAlignment = UIControlContentHorizontalAlignmentCenter;
		if (buttonType!=BTNTYPE_PUSHBITMAP)
		{
			[button setTitle:text forState:UIControlStateNormal];
			[button setTitle:text forState:UIControlStateHighlighted];
			[button setTitle:text forState:UIControlStateSelected];
		}
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateNormal];
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateHighlighted];
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateSelected];
		[button.titleLabel setFont:[fontInfo createFont]];
		
		[rh->rhApp positionUIElement:button withObject:ho];
		
		CImage* img;
		UIImage* uiImg;
		if (buttonImages[0]>=0)
		{
			img=[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:buttonImages[0]];
			uiImg=[img getUIImage];
			[button setImage:uiImg forState:UIControlStateNormal];
		}
		if (buttonImages[1]>=0)
		{
			img=[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:buttonImages[1]];
			uiImg=[img getUIImage];
			[button setImage:uiImg forState:UIControlStateHighlighted];
		}
		if (buttonImages[2]>=0)
		{
			img=[ho->hoAdRunHeader->rhApp->imageBank getImageFromHandle:buttonImages[2]];
			uiImg=[img getUIImage];
			[button setImage:uiImg forState:UIControlStateDisabled];
		}
		if ((flags&BTN_HIDEONSTART)!=0)
		{
			button.hidden=YES;
		}
		if ((flags&BTN_DISABLEONSTART)!=0)
		{
			button.enabled=NO;
		}
		
		[button addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
		[ho->hoAdRunHeader->rhApp->runView addSubview:button];
	}
	
	if(bswitch != nil)
	{
		control = bswitch;
		[bswitch addTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
		[ho->hoAdRunHeader->rhApp->runView addSubview:bswitch];
		[bswitch release];
	}
    
    clickedEvent=-1;
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	if(button != nil)
	{
		[button removeTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
		[button removeFromSuperview];
	}
	if(bswitch != nil)
	{
		[bswitch removeTarget:self action:@selector(buttonClicked:) forControlEvents:UIControlEventTouchUpInside];
		[bswitch removeFromSuperview];
	}
	if(fontInfo != nil)
		[fontInfo release];
	if(text != nil)
		[text release];
}

-(void)displayRunObject:(CRenderer*)renderer
{
	[rh->rhApp positionUIElement:control withObject:ho];
}

- (void)buttonClicked:(id)sender 
{
	[rh resume];
	if (rh->rh2PauseCompteur==0)
	{
		clickedEvent=[ho getEventCount];
		[ho pushEvent:CND_CLICKED withParam:0];
	}
}

// Conditions
// --------------------------------------------------
-(BOOL)cndClicked
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0 || [ho getEventCount] == clickedEvent)
	{
		rh->rhApp->lastInteraction = control.frame;
		return YES;
	}
	return NO;
}
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_CLICKED:
			return [self cndClicked];
        case CND_VISIBLE:
			return !control.hidden;
        case CND_ISENABLED:
            return control.enabled;
		case CND_BOXCHECK:
		{
			if(bswitch != nil)
			{
				return bswitch.on;
			}
		}
		case CND_ISRADIOENABLED:
			return NO;
	}
	return NO;
}

// Actions
// -------------------------------------------------
-(void)actChangeText:(CActExtension*)act
{
    [text release];
    text=[[NSString alloc] initWithString:[act getParamExpString:rh withNum:0]];
	
	if(button != nil)
	{
		[button setTitle:text forState:UIControlStateNormal];
		[button setTitle:text forState:UIControlStateHighlighted];
		[button setTitle:text forState:UIControlStateSelected];
	}
}
-(void)actSetPosition:(CActExtension*)act
{
    unsigned int pos=[act getParamPosition:rh withNum:0];
    ho->hoX=HIWORD(pos);
    ho->hoY=LOWORD(pos);
	[rh->rhApp positionUIElement:control withObject:ho];
}
-(void)actSetXPosition:(CActExtension*)act
{
    ho->hoX=[act getParamExpression:rh withNum:0];
	[rh->rhApp positionUIElement:control withObject:ho];
}
-(void)actSetYPosition:(CActExtension*)act
{
    ho->hoY=[act getParamExpression:rh withNum:0];
	[rh->rhApp positionUIElement:control withObject:ho];
}
-(void)actSetXSize:(CActExtension*)act
{
    ho->hoImgWidth=[act getParamExpression:rh withNum:0];
	[rh->rhApp positionUIElement:control withObject:ho];
}
-(void)actSetYSize:(CActExtension*)act
{
    ho->hoImgHeight=[act getParamExpression:rh withNum:0];
	[rh->rhApp positionUIElement:control withObject:ho];
}
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_ENABLE:
			control.enabled = YES;
			break;
		case ACT_DISABLE:
			control.enabled = NO;
			break;
        case ACT_CHANGETEXT:
            [self actChangeText:act];
            break;
        case ACT_SHOW:
            control.hidden=NO;
            break;
        case ACT_HIDE:
            control.hidden=YES;
            break;
        case ACT_SETPOSITION:
            [self actSetPosition:act];
            break;
        case ACT_SETXSIZE:
            [self actSetXSize:act];
            break;
        case ACT_SETYSIZE:
            [self actSetYSize:act];
            break;
        case ACT_SETXPOSITION:
            [self actSetXPosition:act];
            break;
        case ACT_SETYPOSITION:
            [self actSetYPosition:act];
            break;
		case ACT_CHECK:
			if(bswitch != nil)
				[bswitch setOn:YES animated:YES];
			break;
		case ACT_UNCHECK:
            if(bswitch != nil)
				[bswitch setOn:NO animated:YES];
			break;
    }
}

// Expressions
// ------------------------------------------------------------
-(CValue*)expression:(int)num
{
    switch(num)
    {
        case EXP_GETXSIZE:
            return [rh getTempValue:ho->hoImgWidth];
        case EXP_GETYSIZE:
            return [rh getTempValue:ho->hoImgHeight];
        case EXP_GETX:
            return [rh getTempValue:ho->hoX];
        case EXP_GETY:
            return [rh getTempValue:ho->hoY];
        case EXP_GETTEXT:
		{
			[ho getExpParam];
			if(text != nil)
				return [rh getTempString:text];
			else
				return [rh getTempString:@""];
		}
    }
    return nil;
}



-(CFontInfo*)getRunObjectFont
{
	return fontInfo;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[fontInfo release];
	fontInfo = fi;

	if(button != nil)
		[button.titleLabel setFont:[fontInfo createFont]];
}

-(int)getRunObjectTextColor
{
	return foreColour;
}

-(void)setRunObjectTextColor:(int)rgb
{
	foreColour = rgb;
	if(button != nil)
	{
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateNormal];
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateHighlighted];
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateSelected];
		[button setTitleColor:getUIColor(foreColour) forState:UIControlStateDisabled];
	}
}

@end
