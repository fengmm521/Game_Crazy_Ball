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
#import "CRuniOSMultipleEdit.h"
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


@implementation CRuniOSMultipleEdit

-(int)getNumberOfConditions
{
	return 4;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoImgWidth=[file readAInt];
	ho->hoImgHeight=[file readAInt];
	backColor=[file readAColor];
	textColor=[file readAColor];
	keyboard=[file readAShort];
	ret=[file readAShort];
	align=[file readAShort];
	flags=[file readAShort];
	gotoX=[file readAInt];
	gotoY=[file readAInt];
	gotoSpeed=[file readAShort];
	font=[file readLogFont];
	[file skipStringOfLength:40];
	text=[file readAString];
    bBlockEvents=NO;
		
	CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
	
	textView = [[UITextView alloc] initWithFrame:frame];
	textView.textColor = getUIColor(textColor);
	textView.font = [font createFont];
	textView.backgroundColor = getUIColor(backColor);
	textView.keyboardType = keyboard;	// use the default type input method (entire keyboard)
	textView.returnKeyType = ret;	
	textView.text=text;
	textView.textAlignment = align;
    if ((flags&MEFLAG_PASSWORD)!=0)
    {
        textView.secureTextEntry=YES;
    }
	if (flags&MEFLAG_TVVISIBLE)
	{
		textView.hidden=NO;
	}
	else 
	{
		textView.hidden=YES;
	}
	if (flags&MEFLAG_TVSCROLL)
	{
		textView.scrollEnabled=YES;
		textView.showsVerticalScrollIndicator=YES;
	}
	else 
	{
		textView.scrollEnabled=NO;
	}
	if (flags&MEFLAG_TVEDITABLE)
	{
		textView.editable=YES;
	}
	else 
	{
		textView.editable=NO;
	}
	
	
	//	textFieldNormal.tag = kViewTag;		// tag this control so we can remove it later for recycled cells
	
	textView.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed

	[rh->rhApp positionUIElement:textView withObject:ho];
	[ho->hoAdRunHeader->rhApp->runView addSubview:textView];
	
	enterEditCount=-1;
	quitEditCount=-1;
	bEditing=NO;
	return YES;
}	

-(void)textViewDidBeginEditing:(UITextView *)tv
{
	if (flags&MEFLAG_TVGOTOON)
	{
		gotoSavedX=ho->hoX;
		gotoSavedY=ho->hoY;
		if (gotoX==-1)
		{
			gotoEndX=MAX(0,ho->hoAdRunHeader->rhApp->gaCxWin/2-ho->hoImgWidth/2) + rh->rhWindowX;
		}
		else
		{
			gotoEndX=gotoX;			
		}
		if (gotoY==-1)
		{
			gotoEndY=MAX(0,ho->hoAdRunHeader->rhApp->gaCyWin/4-ho->hoImgHeight/2) + rh->rhWindowY;
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
        [ho pushEvent:CND_TVENTEREDIT withParam:0];
        enterEditCount=[ho getEventCount];
    }
	bEditing=YES;
}
- (void)textViewDidEndEditing:(UITextView *)tv
{
	if (flags&MEFLAG_TVGOTOON)
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
        [ho pushEvent:CND_TVQUITEDIT withParam:0];
        quitEditCount=[ho getEventCount];
    }
	bEditing=NO;
}

-(int)handleRunObject
{
	if (bEditing==YES && rh->rhApp->mouseClick>0)
	{
		[textView resignFirstResponder];		
	}
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
	[rh->rhApp positionUIElement:textView withObject:ho];
}
-(void)destroyRunObject:(BOOL)bFast
{
    bBlockEvents=YES;
	[textView removeFromSuperview];
	[textView release];
	[font release];
	[text release];
}

-(CFontInfo*)getRunObjectFont
{
	return font;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[font release];
	font = [CFontInfo fontInfoFromFontInfo:fi];
	textView.font = [font createFont];
	
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
	textView.textColor = getUIColor(textColor);	
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_TVENTEREDIT:
			return [self cndEnterEdit];
		case CND_TVQUITEDIT:
			return [self cndQuitEdit];
		case CND_TVISVISIBLE:
			return !textView.hidden;
		case CND_TVEDITABLE:
			return textView.editable;
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
		case ACT_TVBACKCOLOR:
			[self actBackColor:[act getParamColour:rh withNum:0]];
			break;
		case ACT_TVSHOW:
			textView.hidden=NO;
			break;
		case ACT_TVHIDE:
			textView.hidden=YES;
			break;
		case ACT_TVEDITABLE:
			textView.editable=YES;
			break;
		case ACT_TVNOTEDITABLE:
			textView.editable=NO;
			break;
		case ACT_TVSETTEXT:
		{
			NSString* newtext = [act getParamExpString:rh withNum:0];
			textView.text = newtext;
			[rh->rhApp positionUIElement:textView withObject:ho];
			break;
		}
	}
}
-(void)actBackColor:(int)color
{
	textView.backgroundColor=getUIColor(ABGRtoRGB(color));
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	if (num==EXP_TVGETTEXT)
	{
		CValue* r=[rh getTempValue:0];
		[r forceString:textView.text];
		return r;
	}
	return nil;
}	

@end
