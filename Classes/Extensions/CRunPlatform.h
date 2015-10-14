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
// CRunPlatform: Platform Movement object
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
@class PlatformCOL;
@class PlatformMove;
@class CFile;

#define CID_ObstacleTest  0
#define CID_JumpThroughTest  1
#define CID_IsOnGround  2
#define CID_IsJumping  3
#define CID_IsFalling  4
#define CID_IsPaused  5
#define CID_IsMoving  6
#define AID_ColObstacle  0
#define AID_ColJumpThrough  1
#define AID_SetObjectP  2
#define AID_MoveRight  3
#define AID_MoveLeft  4
#define AID_Jump  5
#define AID_SetXVelocity  6
#define AID_SetYVelocity  7
#define AID_SetMaxXVelocity  8
#define AID_SetMaxYVelocity  9
#define AID_SetXAccel  10
#define AID_SetXDecel  11
#define AID_SetGravity  12
#define AID_SetJumpStrength  13
#define AID_SetJumpHoldHeight  14
#define AID_SetStepUp  15
#define AID_JumpHold  16
#define AID_Pause  17
#define AID_UnPause  18
#define AID_SetSlopeCorrection  19
#define AID_SetAddXVelocity  20
#define AID_SetAddYVelocity  21
#define EID_GetXVelocity  0
#define EID_GetYVelocity  1
#define EID_GetMaxXVelocity  2
#define EID_GetMaxYVelocity  3
#define EID_GetXAccel  4
#define EID_GetXDecel  5
#define EID_GetGravity  6
#define EID_GetJumpStrength  7
#define EID_GetJumpHoldHeight  8
#define EID_GetStepUp  9
#define EID_GetSlopeCorrection  10
#define EID_GetAddXVelocity  11
#define EID_GetAddYVelocity  12

@interface CRunPlatform : CRunExtension
{
    int ObjFixed;
	BOOL hasObject;
    int ObjShortCut;
    PlatformCOL* Col;
    PlatformMove* PFMove;	
}
-(int)getNumberOfConditions;
-(int)readStringNumber:(CFile*)file withLength:(int)l;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)IsOverObstacle;
-(BOOL)IsOverJumpThrough;
-(int)handleRunObject;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(void)SetObject:(CObject*)object;

@end

@interface PlatformCOL : NSObject
{
@public
	BOOL Obstacle, JumpThrough, JumpThroughColTop, EnableJumpThrough;	
}
@end

@interface PlatformMove : NSObject
{
@public
	int XVelocity, YVelocity,MaxXVelocity, MaxYVelocity,AddXVelocity, AddYVelocity,XMoveCount, YMoveCount,XAccel, XDecel,Gravity,JumpStrength,JumpHoldHeight,StepUp,SlopeCorrection;
	BOOL OnGround,RightKey,LeftKey,Paused;
}
@end
