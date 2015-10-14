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
// CRunAdvDir: Advanced Direction object
// fin 
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CEvents.h"
#import "CPoint.h"

@class CRun;
@class CCreateObjectInfo;
@class CBitmap;
@class CArrayList;
@class CObject;

#define CND_COMPDIST 0
#define CND_COMPDIR 1
#define ACT_SETNUMDIR 0
#define ACT_GETOBJECTS 1
#define ACT_ADDOBJECTS 2
#define ACT_RESET 3
#define EXP_GETNUMDIR 0
#define EXP_DIRECTION 1
#define EXP_DISTANCE 2
#define EXP_DIRECTIONLONG 3
#define EXP_DISTANCELONG 4
#define EXP_ROTATE 5
#define EXP_DIRDIFFABS 6
#define EXP_DIRDIFF 7
#define EXP_GETFIXEDOBJ 8
#define EXP_GETDISTOBJ 9
#define EXP_XMOV 10
#define EXP_YMOV 11
#define EXP_DIRBASE 12

@interface CRunAdvDir : CRunExtension
{
    int CurrentObject;
    double EventCount;
    int NumDir;
    CArrayList* Distance; //Float
    CArrayList* FFixed; //Integer
    CPoint Last;
}
-(int)getNumberOfConditions;
//-(NSString*)fixString:(NSString*)input;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)killRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)CompDist:(LPPOS)p1 withPos:(LPPOS)p2 andParam:(int)v;
-(int)lMin:(int)v1 withV2:(int)v2 andV3:(int)v3;
-(BOOL)CompDir:(LPPOS)p1 withPos:(LPPOS)p2 andParam:(int)dir andParam2:(int)offset;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)SetNumDir:(int)n;
-(void)GetObjects:(CObject*)object withParam:(int)position;
-(void)AddObjects:(CObject*)object;
-(CValue*)expression:(int)num;
-(CValue*)Direction;
-(CValue*)Distance;
-(CValue*)LongDir;
-(CValue*)LongDist;
-(CValue*)Rotate;
-(int)lSMin:(int)v1 withV2:(int)v2 andV3:(int)v3;
-(CValue*)DirDiffAbs;
-(CValue*)DirDiff;
-(CValue*)GetFixedObj:(int)p1;
-(CValue*)GetDistObj:(int)p1;
-(CValue*)XMov;
-(CValue*)YMov;
-(CValue*)DirBase;

@end

@interface CFloat : NSObject
{
@public 
	float value;
}
@end

@interface CInt : NSObject
{
@public 
	int value;
}
@end