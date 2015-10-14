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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;

#define SEFLAG_TFGOTOON 0x0001
#define SEFLAG_TFVISIBLE 0x0002
#define SEFLAG_UNICODE 0x0004
#define SEFLAG_PASSWORD 0x0008

#define CND_TFENABLED 0
#define CND_TFENTEREDIT 1
#define CND_TFQUITEDIT 2
#define CND_TFISVISIBLE 3
#define ACT_TFENABLE 0
#define ACT_TFDISABLE 1
#define ACT_TFBACKCOLOR 2
#define ACT_TFSHOW 3
#define ACT_TFHIDE 4
#define ACT_TFSETTEXT 5
#define EXP_TFGETTEXT 0

@interface CRuniOSSingleEdit : CRunExtension <UITextFieldDelegate>
{
	int border;
	int backColor;
	int textColor;
	int keyboard;
	int correction;
	int clear;
	int ret;
	int align;
	int gotoX;
	int gotoY;
	short flags;
	int gotoSpeed;
	CFontInfo* font;
	NSString* placeHolder;
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
	UITextField* textField;
}
-(void)actBackColor:(int)color;
-(BOOL)cndEnterEdit;
-(BOOL)cndQuitEdit;

@end
