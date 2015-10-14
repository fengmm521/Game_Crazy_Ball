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
// CRUNCALCRECT
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CCreateObjectInfo;
@class CFile;
@class CValue;
@class CBitmap;

#define ACT_SetFont 0
#define ACT_SetText 1
#define ACT_SetMaxWidth 2
#define ACT_CalcRect 3
#define EXP_GetWidth 0
#define EXP_GetHeight 1

@interface CRunCalcRect : CRunExtension
{
    NSString* text;
    NSString* fontName;
    int fontHeight;
    BOOL fontBold;
    BOOL fontItalic;
    BOOL fontUnderline;
    int maxWidth;
    int calcWidth;
    int calcHeight;	
}
-(void)dealloc;
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(void)CalcRect;
-(CValue*)GetHeight;
-(CValue*)GetWidth;
-(void)SetFont:(NSString*)name withParam1:(int)height andParam2:(int)style;
-(void)SetMaxWidth:(int)width;
-(void)SetText:(NSString*)text;

@end
