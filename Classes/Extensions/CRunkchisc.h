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
// CRunkchisc: Hiscore object
//
//----------------------------------------------------------------------------------



@class CCndExtension;
@class CActExtension;
@class CTextSurface;
@class CIni;
@class ModalInput;
class CRenderer;

#import "CRunExtension.h"
#import "CPoint.h"

@interface CRunkchisc : CRunExtension <UIAlertViewDelegate>
{
	BOOL sVisible;
	short NbScores;
	short NameSize;
	short Flags;
	CFontInfo* Logfont;
	int colorref;
	NSString* Names[20];
	int Scores[20];
	NSString* originalNames[20]; //used for reset action
	int originalScores[20];
	int scrPlayer[4]; //used for high score condition
	NSString* IniName;
	short started;
	CIni* ini;
	NSNumberFormatter* nformat;
	CTextSurface* textSurface;
	BOOL updated;
	int recordedScore;
	ModalInput* modalInput;
}

-(int)getNumberOfConditions;

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob  andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)handleRunObject;
-(void)displayRunObject:(CRenderer*)renderer;

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

-(void)saveHiScores;

//AlertView
-(void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex;

// Conditions
// --------------------------------------------------
-(BOOL)IsPlayerHiScore:(short)player;
-(BOOL)IsVisible;

// Actions
// -------------------------------------------------
-(BOOL)CheckScore:(int)player;
-(void)Hide;
-(void)Show;
-(void)Reset;
-(void)ChangeName:(int)i withName:(NSString*)name;
-(void)ChangeScore:(int)i andScore:(int)score;
-(void)SetPositionX:(int)x andY:(int)y;
-(void)SetXPosition:(int)x;
-(void)SetYPosition:(int)y;
-(void)InsertNewScore:(int)pScore andName:(NSString*)pName;
-(void)SetCurrentFile:(NSString*)fileName;

// Expressions
// --------------------------------------------
-(CValue*)GetValue:(int)i;
-(CValue*)GetName:(int)i;
-(CValue*)GetXPosition;
-(CValue*)GetYPosition;

@end