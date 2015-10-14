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
// CRuniPhoneMultipleEdit
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;

#define MEFLAG_TVGOTOON 0x0001
#define MEFLAG_TVVISIBLE 0x0002
#define MEFLAG_TVSCROLL 0x0004
#define MEFLAG_TVEDITABLE 0x0008
#define MEFLAG_UNICODE 0x0010
#define MEFLAG_PASSWORD 0x0020

#define CND_TVENTEREDIT 0
#define CND_TVQUITEDIT 1
#define CND_TVISVISIBLE 2
#define CND_TVEDITABLE 3
#define ACT_TVBACKCOLOR 0
#define ACT_TVSHOW 1
#define ACT_TVHIDE 2
#define ACT_TVEDITABLE 3
#define ACT_TVNOTEDITABLE 4
#define ACT_TVSETTEXT 5
#define EXP_TVGETTEXT 0

@interface CRuniOSMultipleEdit : CRunExtension <UITextViewDelegate> 
{
	int backColor;
	int textColor;
	int keyboard;
	int ret;
	int align;
	int gotoX;
	int gotoY;
	short flags;
	int gotoSpeed;
	CFontInfo* font;
	NSString* text;
	
	int gotoStartX;
	int gotoStartY;
	int gotoEndX;
	int gotoEndY;
	int gotoSavedX;
	int gotoSavedY;	
	double gotoPlusPosition;
	double gotoPosition;
	BOOL bGoto;
    BOOL bBlockEvents;
	
	int enterEditCount;
	int quitEditCount;
	BOOL bEditing;
	UITextView* textView;	
}
-(void)actBackColor:(int)color;
-(BOOL)cndEnterEdit;
-(BOOL)cndQuitEdit;

@end
