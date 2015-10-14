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
// CRuniPhoneSingleEdit
//
//----------------------------------------------------------------------------------
#import "CRuniOSSingleEdit.h"
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
#import "CFontInfo.h"
#import "CRect.h"
#import "CRunView.h"


@implementation CRuniOSSingleEdit

-(int)getNumberOfConditions
{
	return 4;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoImgWidth=[file readAInt];
	ho->hoImgHeight=[file readAInt];
	border=[file readAShort];
	backColor=[file readAColor];
	textColor=[file readAColor];
	keyboard=[file readAShort];
	correction=[file readAShort];
	clear=[file readAShort];
	ret=[file readAShort];
	align=[file readAShort];
	flags=[file readAShort];
	gotoX=[file readAInt];
	gotoY=[file readAInt];
	gotoSpeed=[file readAShort];
	font=[file readLogFont];
    [file skipStringOfLength:40];
	text=[file readAString];
	placeHolder=[file readAString];
    bBlockEvents=NO;
		
	CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
	textField = [[UITextField alloc] initWithFrame:frame];
	
	textField.borderStyle = border;
	textField.textColor = getUIColor(textColor);
	textField.font = [font createFont];
	textField.placeholder = placeHolder;
	textField.backgroundColor = getUIColor(backColor);
	textField.autocorrectionType = correction;	// no auto correction support	
	textField.keyboardType = keyboard;	// use the default type input method (entire keyboard)
	textField.returnKeyType = ret;	
	textField.clearButtonMode = clear;	// has a clear 'x' button to the right
	textField.text=text;
	textField.textAlignment = align;
	
	if(textField.keyboardType == UIKeyboardTypeNumberPad &&
	   UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPhone)
	{
		UIToolbar* accesory = [[[UIToolbar alloc] initWithFrame:CGRectZero] autorelease];
		CGSize size = [accesory sizeThatFits:CGSizeZero];
		accesory.frame = CGRectMake(0, 0, size.width, size.height);
		UIBarButtonItem* dismiss = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemDone target:textField action:@selector(resignFirstResponder)];
		accesory.items = [NSArray arrayWithObjects:[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil], dismiss, nil];
		textField.inputAccessoryView = accesory;
	}
	
    if ((flags&SEFLAG_PASSWORD)!=0)
    {
        textField.secureTextEntry=YES;
    }
	
	[rh->rhApp positionUIElement:textField withObject:ho];
	
	if (flags&SEFLAG_TFVISIBLE)
	{
		textField.hidden=NO;
	}
	else 
	{
		textField.hidden=YES;
	}

		
//	textFieldNormal.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
	
	textField.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed

	[ho->hoAdRunHeader->rhApp->runView addSubview:textField];
	
	enterEditCount=-1;
	quitEditCount=-1;

	return YES;
}	

- (BOOL)textFieldShouldReturn:(UITextField *)tf
{
	// the user pressed the "Done" button, so dismiss the keyboard
	[tf resignFirstResponder];
	return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)tf
{
	if (flags&SEFLAG_TFGOTOON)
	{
		CRunApp* app = ho->hoAdRunHeader->rhApp;
		gotoSavedX=ho->hoX;
		gotoSavedY=ho->hoY;
		if (gotoX==-1)
		{
			gotoEndX = MAX(0, app->gaCxWin/2 - ho->hoImgWidth/2) + rh->rhWindowX;
		}
		else
		{
			gotoEndX = gotoX;
		}
		if (gotoY==-1)
		{
			gotoEndY = MAX(0, app->gaCyWin/4 - ho->hoImgHeight/2) + rh->rhWindowY;
		}
		else
		{
			gotoEndY=gotoY;			
		}		
		if (gotoSpeed<1)
		{
			gotoSpeed=1;
		}
		if (gotoSpeed>=100)
		{
			gotoSpeed=99;
		}
		gotoPlusPosition=(M_PI/2)/(100-gotoSpeed);
		gotoStartX=ho->hoX;
		gotoStartY=ho->hoY;
		gotoPosition=0;
		bGoto=YES;
	}
    if (!bBlockEvents)
    {
        [ho pushEvent:CND_TFENTEREDIT withParam:0];
        enterEditCount=[ho getEventCount];
    }
}
- (void)textFieldDidEndEditing:(UITextField *)tf
{
	if (flags&SEFLAG_TFGOTOON)
	{
		gotoEndX=gotoSavedX;
		gotoEndY=gotoSavedY;
		gotoStartX=ho->hoX;
		gotoStartY=ho->hoY;
		gotoPosition=0;
		bGoto=YES;	
	}    
    if (!bBlockEvents)
    {
        [ho pushEvent:CND_TFQUITEDIT withParam:0];
        quitEditCount=[ho getEventCount];
    }
}

-(int)handleRunObject
{
	if (bGoto)
	{
		gotoPosition+=gotoPlusPosition;
		if (gotoPosition>M_PI/2)
		{
			ho->hoX=gotoEndX;
			ho->hoY=gotoEndY;
			bGoto=NO;
		}
		else
		{
			int delta=gotoEndX-gotoStartX;
			ho->hoX=gotoStartX+delta*sinf(gotoPosition);
			delta=gotoEndY-gotoStartY;
			ho->hoY=gotoStartY+delta*sinf(gotoPosition);
		}
		return REFLAG_DISPLAY;
	}
	return 0;  
}

-(void)displayRunObject:(CRenderer*)g2
{
	[rh->rhApp positionUIElement:textField withObject:ho];
}
-(void)destroyRunObject:(BOOL)bFast
{
    bBlockEvents=YES;
	[textField removeFromSuperview];
	[textField release];
	[font release];
	[text release];
	[placeHolder release];
}

-(CFontInfo*)getRunObjectFont
{
	return font;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[font release];
	font = [CFontInfo fontInfoFromFontInfo:fi];
	textField.font = [font createFont];

	if (!rc.isNil())
	{
		[ho setWidth:(int)rc.right];
		[ho setHeight:(int)rc.bottom];
	}
	[ho redraw];	
}

-(int)getRunObjectTextColor
{
	return textColor;
}

-(void)setRunObjectTextColor:(int)rgb
{
	textColor = rgb;
	textField.textColor = getUIColor(textColor);	
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_TFENABLED:
			return textField.enabled;
		case CND_TFENTEREDIT:
			return [self cndEnterEdit];
		case CND_TFQUITEDIT:
			return [self cndQuitEdit];
		case CND_TFISVISIBLE:
			return !textField.hidden;
	}        
	return NO;
}
-(BOOL)cndEnterEdit
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == enterEditCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)cndQuitEdit
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == quitEditCount)
	{
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
		case ACT_TFENABLE:
			textField.enabled=YES;
			break;
		case ACT_TFDISABLE:
			textField.enabled=NO;
			break;
		case ACT_TFBACKCOLOR:
			[self actBackColor:[act getParamColour:rh withNum:0]];
			break;
		case ACT_TFSHOW:
			textField.hidden=NO;
			break;
		case ACT_TFHIDE:
			textField.hidden=YES;
			break;
		case ACT_TFSETTEXT:
			textField.text=[act getParamExpString:rh withNum:0];
			break;
	}
}
-(void)actBackColor:(int)color
{
	textField.backgroundColor=getUIColor(ABGRtoRGB(color));
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	if (num==EXP_TFGETTEXT)
	{
		CValue* r=[rh getTempValue:0];
		[r forceString:textField.text];
		return r;
	}
	return nil;
}	
@end
