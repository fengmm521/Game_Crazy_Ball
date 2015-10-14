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
// CRunMoveSafely2 : MoveSafely2 object
// 
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CObject;
@class CRun;
@class CActExtension;
@class CCndExtension;
@class CBitmap;
@class CCreateObjectInfo;
@class CSprite;
@class CSortData;
@class CObjInfo;
@class CValue;
@class MoveSafely2myclass;
@class CArrayList;

#define CID_OnSafety  0
#define AID_Prepare  0
#define AID_Start  1
#define AID_Stop  2
#define AID_SetObject  3
#define AID_Stop2  4
#define AID_Setdist  5
#define AID_Reset  6
#define EID_GetX  0
#define EID_GetY  1
#define EID_Getfixed  2
#define EID_GetNumber  3
#define EID_GetIndex  4
#define EID_Getdist  5

@interface CRunMoveSafely2 : CRunExtension
{
    MoveSafely2myclass* mypointer;
    int X;
    int Y;
    int NewX;
    int NewY;
    int Debug;
    int Temp;
    int Temp2;
    int Loopindex;
    int Dist;
    BOOL hasstopped;
    BOOL inobstacle;
    BOOL last;
	
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(void)Prepare;
-(void)Start;
-(void)Stop;
-(void)SetObject:(CObject*)object withParam1:(int)distance;
-(void)Stop2;
-(void)SetDist:(int)dist;
-(void)Reset;
-(CValue*)Getfixed;

@end

@interface MoveSafely2CloneObjects : NSObject
{
@public 
	CObject* obj;
	int OldX;
	int OldY;
	int NewX;
	int NewY;
	int Dist;
}
-(id)initWithParam:(CObject*)object andParam1:(int)param;
@end

@interface MoveSafely2myclass : NSObject
{
@public
    CArrayList* Mirrorvector; //MoveSafely2CloneObjects	
    MoveSafely2CloneObjects* iterator;
}
-(id)init;
-(void)dealloc;
@end
