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
// CRunkcedit
//
//----------------------------------------------------------------------------------
#import "CRunkcedit.h"
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

#define CND_VISIBLE 0
#define CND_ENABLE 1
#define CND_CANUNDO 2
#define CND_MODIFIED 3
#define CND_HAVEFOCUS 4
#define CND_ISNUMBER 5
#define CND_ISSELECTED 6
#define CND_LAST 7
#define ACT_LOADTEXT 0
#define ACT_LOADTEXTSELECT 1
#define ACT_SAVETEXT 2
#define ACT_SAVETEXTSELECT 3
#define ACT_SETTEXT 4
#define ACT_REPLACESELECTION 5
#define ACT_CUT 6
#define ACT_COPY 7
#define ACT_PASTE 8
#define ACT_CLEAR 9
#define ACT_UNDO 10
#define ACT_CLEARUNDOBUFFER 11
#define ACT_SHOW 12
#define ACT_HIDE 13
#define ACT_SETFONTSELECT 14
#define ACT_SETCOLORSELECT 15
#define ACT_ACTIVATE 16
#define ACT_ENABLE 17
#define ACT_DISABLE 18
#define ACT_READONLYON 19
#define ACT_READONLYOFF 20
#define ACT_TEXTMODIFIED 21
#define ACT_TEXTNOTMODIFIED 22
#define ACT_LIMITTEXTSIZE 23
#define ACT_SETPOSITION 24
#define ACT_SETXPOSITION 25
#define ACT_SETYPOSITION 26
#define ACT_SETSIZE 27
#define ACT_SETXSIZE 28
#define ACT_SETYSIZE 29
#define ACT_DESACTIVATE 30
#define ACT_SCROLLTOTOP 31
#define ACT_SCROLLTOLINE 32
#define ACT_SCROLLTOEND 33
#define ACT_SETCOLOR 34
#define ACT_SETBKDCOLOR 35
#define ACT_LAST 36
#define EXP_GETTEXT 0
#define EXP_GETSELECTION 1
#define EXP_GETXPOSITION 2
#define EXP_GETYPOSITION 3
#define EXP_GETXSIZE 4
#define EXP_GETYSIZE 5
#define EXP_GETVALUE 6
#define EXP_GETFIRSTLINE 7
#define EXP_GETLINECOUNT 8
#define EXP_GETCOLOR 9
#define EXP_GETBKDCOLOR 10
#define EXP_LAST 11

#define EDIT_HSCROLLBAR 0x0001
#define EDIT_HSCROLLAUTOSCROLL 0x0002
#define EDIT_VSCROLLBAR 0x0004
#define EDIT_VSCROLLAUTOSCROLL 0x0008
#define EDIT_READONLY 0x0010
#define EDIT_MULTILINE 0x0020
#define EDIT_PASSWORD 0x0040
#define EDIT_BORDER 0x0080
#define EDIT_HIDEONSTART 0x0100
#define EDIT_UPPERCASE 0x0200
#define EDIT_LOWERCASE 0x0400
#define EDIT_TABSTOP 0x0800
#define EDIT_SYSCOLOR 0x1000
#define EDIT_3DLOOK 0x2000
#define EDIT_TRANSP 0x4000
#define EDIT_ALIGN_HCENTER 0x00010000
#define EDIT_ALIGN_RIGHT 0x00020000

void funcVal(NSString* pString, CValue* pValue);


@implementation CRunkcedit

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    ho->hoImgWidth = [file readAShort];
    ho->hoImgHeight = [file readAShort];
    if (file->bUnicode==NO)
    {
        font=[file readLogFont16];
    }
    else
    {
        font=[file readLogFont];
    }
    [file skipBytes:4 * 16]; // Skip custom colours
    textColor = [file readAColor];
    backColor = [file readAColor];
    [file skipStringOfLength:40];
    flags = [file readAInt];
    gotoX=-1;
    gotoY=-1;
    gotoSpeed=75;
    
    textView=nil;
    textField=nil;
    CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);

	int border=0;
	if (flags&EDIT_BORDER)
		border=1;

    if ((flags&EDIT_MULTILINE)==0)
    {
        textField = [[UITextField alloc] initWithFrame:frame];
		if (flags&EDIT_3DLOOK)
			border=2;
        textField.borderStyle = border;
        textField.textColor = getUIColor(textColor);
        textField.font = [font createFont];
		textField.secureTextEntry = ((flags&EDIT_PASSWORD) != 0);
        textField.placeholder = @"";
        textField.backgroundColor = getUIColor(backColor);
        textField.autocorrectionType = 0;	// no auto correction support	
        textField.keyboardType = 0;	// use the default type input method (entire keyboard)
        textField.returnKeyType = 0;	
        textField.clearButtonMode = 0;	// has a clear 'x' button to the right
        textField.text=@"";

        if (flags&EDIT_HIDEONSTART)
        {
            textField.hidden=YES;
        }
        else 
        {
            textField.hidden=NO;
        }
        textField.delegate = self;
		
		[rh->rhApp positionUIElement:textField withObject:ho];
        [ho->hoAdRunHeader->rhApp->runView addSubview:textField];
    }
    else
    {
        textView = [[UITextView alloc] initWithFrame:frame];
        textView.textColor = getUIColor(textColor);
        textView.font = [font createFont];
        textView.backgroundColor = getUIColor(backColor);
        textView.keyboardType = 0;	// use the default type input method (entire keyboard)
        textView.returnKeyType = 0;	
        textView.text=@"";	 
        textView.secureTextEntry=((flags&EDIT_PASSWORD)!=0);

		if(border > 0)
		{
			textView.layer.borderWidth = border;
			textView.layer.borderColor = [[UIColor grayColor] CGColor];
			if (flags&EDIT_3DLOOK)
				textView.layer.cornerRadius = 5.0f;
		}

        if (flags&EDIT_HIDEONSTART)
        {
            textView.hidden=YES;
        }
        else 
        {
            textView.hidden=NO;
        }
        if (flags&EDIT_VSCROLLBAR)
        {
            textView.scrollEnabled=YES;
            textView.showsVerticalScrollIndicator=YES;
        }
        else 
        {
            textView.scrollEnabled=NO;
        }
        if (flags&EDIT_READONLY)
        {
            textView.editable=NO;
        }
        else 
        {
            textView.editable=YES;
        }
        textView.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed

		[rh->rhApp positionUIElement:textView withObject:ho];
        [ho->hoAdRunHeader->rhApp->runView addSubview:textView];
		
    }
	return YES;
}
-(void)destroyRunObject:(BOOL)bFast
{
    if (textView!=nil)
    {
		textView.delegate = nil;
        [textView removeFromSuperview];
        [textView release];
    }
    if (textField!=nil)
    {
		textField.delegate = nil;
        [textField removeFromSuperview];
        [textField release];        
    }
	[font release];
}

- (BOOL)textFieldShouldReturn:(UITextField *)tf
{
	// the user pressed the "Done" button, so dismiss the keyboard
	[tf resignFirstResponder];
	return YES;
}

-(void)textFieldDidBeginEditing:(UITextField *)tf
{
	CRunApp* app = ho->hoAdRunHeader->rhApp;
	{
		gotoSavedX = ho->hoX;
		gotoSavedY = ho->hoY;
		if (gotoX==-1)
		{
			gotoEndX = MAX(0, app->gaCxWin/2 - ho->hoImgWidth/2) + ho->hoAdRunHeader->rhWindowX;
		}
		else
		{
			gotoEndX = gotoX;
		}
		if (gotoY==-1)
		{
			gotoEndY = MAX(0,ho->hoAdRunHeader->rhApp->gaCyWin/4 - ho->hoImgHeight/2) + ho->hoAdRunHeader->rhWindowY;
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
}
- (void)textFieldDidEndEditing:(UITextField *)tf
{
	{
		gotoEndX=gotoSavedX;
		gotoEndY=gotoSavedY;
		gotoStartX=ho->hoX;
		gotoStartY=ho->hoY;
		gotoPosition=0;
		bGoto=YES;	
        bModified=YES;
	}
}

-(void)textViewDidBeginEditing:(UITextView *)tv
{
	CRunApp* app = ho->hoAdRunHeader->rhApp;
	{
		gotoSavedX=ho->hoX;
		gotoSavedY=ho->hoY;
		if (gotoX==-1)
		{
			gotoEndX = MAX(0,app->gaCxWin/2 - ho->hoImgWidth/2) + ho->hoAdRunHeader->rhWindowX;
		}
		else
		{
			gotoEndX = gotoX;
		}
		if (gotoY==-1)
		{
			gotoEndY = MAX(0,app->gaCyWin/4 - ho->hoImgHeight/2) + ho->hoAdRunHeader->rhWindowY;
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
        bEditing=YES;
	}
}
- (void)textViewDidEndEditing:(UITextView *)tv
{
	{
		gotoEndX=gotoSavedX;
		gotoEndY=gotoSavedY;
		gotoStartX=ho->hoX;
		gotoStartY=ho->hoY;
		gotoPosition=0;
		bGoto=YES;	
	}
	bModified=YES;
    bEditing=NO;
}

-(int)handleRunObject
{
	if (textView!=nil && bEditing==YES && rh->rhApp->mouseClick>0)
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
    if (textField!=nil)
    {
        [rh->rhApp positionUIElement:textField withObject:ho];
    }
    if (textView!=nil)
    {
        [rh->rhApp positionUIElement:textView withObject:ho];        
    }
}

-(CFontInfo*)getRunObjectFont
{
	return font;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[font release];
	font = [CFontInfo fontInfoFromFontInfo:fi];
    if (textView!=nil)
    {
        textView.font = [font createFont];
    }
    else if (textField!=nil)
    {
        textField.font = [font createFont];
    }
	
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
    if (textView!=nil)
    {
        textView.textColor = getUIColor(textColor);
    }
    else if (textField!=nil)
    {
        textField.textColor = getUIColor(textColor);
    }
}

// Conditions
// --------------------------------------------------
-(BOOL)cndIsVisible
{
    if (textField!=nil)
    {
        return !textField.hidden;
    }
    return !textView.hidden;
}
-(BOOL)cndIsEnabled
{
    if (textField!=nil)
    {
        return textField.enabled;
    }
    return YES;
}
-(BOOL)cndIsNumber
{
    NSString* text;
    if (textField!=nil)
    {
        text=textField.text;
    }
    else
    {
        text=textView.text;
    }
	if ([text length]==0)
	{
		return NO;
	}
    int nText = 0;
	while(nText<[text length] && [text characterAtIndex:nText]==32) nText++;
    if (nText<[text length])
    {
        return NO;
    }
	char c=[text characterAtIndex:nText];
    if (c>='0' && c<='9')
    {
        return YES;
    }
    if (c!='+' && c!='-')
    {
        return NO;
    }
    nText++;
	while(nText<[text length] && [text characterAtIndex:nText]==32) nText++;
	c=[text characterAtIndex:nText];
    if (c>='0' && c<='9')
    {
        return YES;
    }
    return NO;
}
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
        case CND_VISIBLE:
            return [self cndIsVisible];
        case CND_ENABLE:
            return [self cndIsEnabled];
        case CND_CANUNDO:
            return NO;
        case CND_MODIFIED:
            return bModified;
        case CND_HAVEFOCUS:
            return bEditing;
        case CND_ISNUMBER:
            return [self cndIsNumber];
        case CND_ISSELECTED:
            return NO;
    }
    return NO;
}


// Actions
// -------------------------------------------------
-(void)actSaveText:(CActExtension*)act
{
    NSString* fileName = [rh->rhApp getPathForWriting:[act getParamFilename:rh withNum:0]];
    NSString* text=nil;
    if (textView!=nil)
        text=textView.text;
    if (textField!=nil)
        text=textField.text;
	
	//Fix for Edit object writing faulty data for some encodings
	NSError* error = nil;
	[text writeToFile:fileName atomically:NO encoding:NSUTF8StringEncoding error:&error];
	if(error != nil)
		NSLog(@"Text file write error: %@", error);
}

-(void)actLoadText:(CActExtension*)act
{
    NSString* fileName=[act getParamFilename:rh withNum:0];
    NSData* myData = [rh->rhApp loadResourceData:fileName];
	
    if (myData != nil && [myData length]!=0)
    {
		NSString* string = [rh->rhApp stringGuessingEncoding:myData];
		if(string != nil)
		{		
			if (textView!=0)
			{
				textView.text=string;
				[rh->rhApp positionUIElement:textView withObject:ho];
			}
			if (textField!=nil)
			{
				textField.text=string;
				[rh->rhApp positionUIElement:textField withObject:ho];
			}
		}
    }
	else
	{
		if (textView!=0)
		{
			textView.text=@"";
			[rh->rhApp positionUIElement:textView withObject:ho];
		}
		if (textField!=nil)
		{
			textField.text=@"";
			[rh->rhApp positionUIElement:textField withObject:ho];
		}
	}

}

-(void)actSETTEXT:(CActExtension*)act
{
    NSString* text=[act getParamExpString:rh withNum:0];
    if (textField!=nil)
    {
        textField.text=text;
    }
    else
    {
		textView.clipsToBounds = YES;
		textView.contentInset = UIEdgeInsetsZero;
		textView.contentMode = UIViewContentModeTop;
        textView.text=text;
		[rh->rhApp positionUIElement:textView withObject:ho];
    }
}
-(void)actCLEAR
{
    if (textField!=nil)
    {
        textField.text=@"";
		[rh->rhApp positionUIElement:textField withObject:ho];
    }
    else
    {
        textView.text=@"";
		[rh->rhApp positionUIElement:textView withObject:ho];
    }
}
-(void)actHIDE
{
    if (textField!=nil)
    {
        textField.hidden=YES;
    }
    else
    {
        textView.hidden=YES;
    }
}
-(void)actSHOW
{
    if (textField!=nil)
    {
        textField.hidden=NO;
    }
    else
    {
        textView.hidden=NO;
    }
}
-(void)actENABLE
{
    if (textField!=nil)
    {
        textField.enabled=YES;
    }
}
-(void)actDISABLE
{
    if (textField!=nil)
    {
        textField.enabled=NO;
    }
}
-(void)actREADONLYON
{
    if (textView!=nil)
    {
        textView.editable=NO;
    }
}
-(void)actREADONLYOFF
{
    if (textView!=nil)
    {
        textView.editable=YES;
    }
}
-(void)actSETPOSITION:(CActExtension*)act
{
    LPPOS pos=[act getParamPosition:rh withNum:0];
    ho->hoX=pos->posX-rh->rhWindowX;
    ho->hoY=pos->posY-rh->rhWindowY;
    [ho redraw];
}
-(void)actSETXPOSITION:(CActExtension*)act
{
    int x=[act getParamExpression:rh withNum:0];
    ho->hoX=x-rh->rhWindowX;
    [ho redraw];
}
-(void)actSETYPOSITION:(CActExtension*)act
{
    int y=[act getParamExpression:rh withNum:0];
    ho->hoY=y-rh->rhWindowY;
    [ho redraw];
}
-(void)actSETCOLOR:(CActExtension*)act
{
    textColor = ABGRtoRGB([act getParamColour:rh withNum:0]);
    if (textField!=nil)
    {
        textField.textColor=getUIColor(textColor);
    }
    else
    {
        textView.textColor=getUIColor(textColor);
    }
}
-(void)actSETBKDCOLOR:(CActExtension*)act
{
    backColor = ABGRtoRGB([act getParamColour:rh withNum:0]);
    if (textField!=nil)
    {
        textField.backgroundColor=getUIColor(backColor);
    }
    else
    {
        textView.backgroundColor=getUIColor(backColor);
    }
}
-(void)actSETSIZE:(CActExtension*)act
{
    ho->hoImgWidth=[act getParamExpression:rh withNum:0];
    ho->hoImgHeight=[act getParamExpression:rh withNum:0];
    CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
    if (textField!=nil)
    {
        [textField setFrame:frame];
    }
    else
    {
        [textView setFrame:frame];
    }
}
-(void)actSETXSIZE:(CActExtension*)act
{
    ho->hoImgWidth=[act getParamExpression:rh withNum:0];
    CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
    if (textField!=nil)
    {
        [textField setFrame:frame];
    }
    else
    {
        [textView setFrame:frame];
    }
}
-(void)actSETYSIZE:(CActExtension*)act
{
    ho->hoImgHeight=[act getParamExpression:rh withNum:0];
    CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
    if (textField!=nil)
    {
        [textField setFrame:frame];
    }
    else
    {
        [textView setFrame:frame];
    }
}
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{        
        case ACT_LOADTEXT:
            [self actLoadText:act];
            break;
        case ACT_LOADTEXTSELECT:
            break;
        case ACT_SAVETEXT:
            [self actSaveText:act];
            break;
        case ACT_SAVETEXTSELECT:
            break;
        case ACT_SETTEXT:
            [self actSETTEXT:act];
            break;
        case ACT_REPLACESELECTION:
            break;
        case ACT_CUT:
            break;
        case ACT_COPY:
            break;
        case ACT_PASTE:
            break;
        case ACT_CLEAR:
            [self actCLEAR];
            break;
        case ACT_UNDO:
            break;
        case ACT_CLEARUNDOBUFFER:
            break;
        case ACT_SHOW:
            [self actSHOW];
            break;
        case ACT_HIDE:
            [self actHIDE];
            break;
        case ACT_SETFONTSELECT:
            break;
        case ACT_SETCOLORSELECT:
            break;
        case ACT_ACTIVATE:
            break;
        case ACT_ENABLE:
            [self actENABLE];
            break;
        case ACT_DISABLE:
            [self actDISABLE];
            break;
        case ACT_READONLYON:
            [self actREADONLYON];
            break;
        case ACT_READONLYOFF:
            [self actREADONLYOFF];
            break;
        case ACT_TEXTMODIFIED:
            bModified=YES;
            break;
        case ACT_TEXTNOTMODIFIED:
            bModified=NO;
            break;
        case ACT_LIMITTEXTSIZE:
            break;
        case ACT_SETPOSITION:
            [self actSETPOSITION:act];
            break;
        case ACT_SETXPOSITION:
            [self actSETXPOSITION:act];
            break;
        case ACT_SETYPOSITION:
            [self actSETYPOSITION:act];
            break;
        case ACT_SETSIZE:
            [self actSETSIZE:act];
            break;
        case ACT_SETXSIZE:
            [self actSETXSIZE:act];
            break;
        case ACT_SETYSIZE:
            [self actSETYSIZE:act];
            break;
        case ACT_DESACTIVATE:
            break;
        case ACT_SCROLLTOTOP:
            break;
        case ACT_SCROLLTOLINE:
            break;
        case ACT_SCROLLTOEND:
            break;
        case ACT_SETCOLOR:
            [self actSETCOLOR:act];
            break;
        case ACT_SETBKDCOLOR:
            [self actSETBKDCOLOR:act];
            break;
    }
}


// Expressions
// --------------------------------------------
-(CValue*)expGETTEXT
{
    if (textField!=nil)
	{
		return [rh getTempString:textField.text];
	}
	return [rh getTempString:textView.text];
}
-(CValue*)expGetValue
{
    NSString* text;
    CValue* ret=[rh getTempValue:0];
    if (textField!=nil)
    {
        text=textField.text;
    }
    else
    {
        text=textView.text;
    }
    funcVal(text, ret);
    return ret;
}
-(CValue*)expression:(int)num
{
    switch (num)
    {
        case EXP_GETTEXT:
            return [self expGETTEXT];
        case EXP_GETSELECTION:
            return [rh getTempValue:0];
        case EXP_GETXPOSITION:
            return [rh getTempValue:ho->hoX];
        case EXP_GETYPOSITION:
            return [rh getTempValue:ho->hoY];
        case EXP_GETXSIZE:
            return [rh getTempValue:ho->hoImgWidth];
        case EXP_GETYSIZE:
            return [rh getTempValue:ho->hoImgHeight];
        case EXP_GETVALUE:
            return [self expGetValue];
        case EXP_GETFIRSTLINE:
            return [rh getTempValue:0];
        case EXP_GETLINECOUNT:
            return [rh getTempValue:1];
        case EXP_GETCOLOR:
            return [rh getTempValue:textColor];
        case EXP_GETBKDCOLOR:
            return [rh getTempValue:backColor];
    }
    return [rh getTempValue:0];
}

@end
