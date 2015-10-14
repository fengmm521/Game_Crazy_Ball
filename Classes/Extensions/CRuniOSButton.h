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
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CFontInfo;
@class CBitmap;
class CRenderer;

#define CND_BTNCLICK 0
#define CND_BTNENABLED 1
#define CND_BTNVISIBLE 2
#define ACT_BTNENABLE 0
#define ACT_BTNDISABLE 1
#define ACT_BTNSETTEXT 2
#define ACT_BTNSHOW 3
#define ACT_BTNHIDE 4
#define EXP_BTNGETTEXT 0

@interface CRuniOSButton : CRunExtension
{
	CFontInfo* fontInfo;
	int	fontColor;
	UIButton* button;
	NSString* text;
	int type;
	int vAlign;
	int hAlign;
	short images[4];
	int clickCount;
    short flags;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)buttonClicked:(id)sender;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)cndClick;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)displayRunObject:(CRenderer*)renderer;
-(void)setText:(CActExtension*)act;

@end
