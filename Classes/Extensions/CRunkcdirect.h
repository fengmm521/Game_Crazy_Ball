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
// CRunkcdirect: Direction Calculator object
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

#define ACT_SET_TURN  0
#define ACT_TURN_DIRECTIONS  1
#define ACT_TURN_POS  2
#define ACT_ADD_DIR  3
#define ACT_DIR_SET  4
#define EXP_XY_TO_DIR  0
#define EXP_XY_TO_SPD  1
#define EXP_DIR_TO_X  2
#define EXP_DIR_TO_Y  3
#define EXP_TURN_TOWARD  4

@interface CRunkcdirect : CRunExtension
{
    int angle_to_turn;
    int speed1;
    int speed2;
    int dir_to_add;
}
-(id)init;
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)SetTurn:(int)v;
-(void)TurnToDirection:(int)dir withParam1:(CObject*)object;
-(void)TurnToPosition:(CObject*)object withParam1:(unsigned int)position;
-(void)AddDir_act:(int)speed withParam1:(CObject*)object;
-(void)AngleSet:(int)angle;
-(CValue*)XYtoDir;
-(CValue*)XyToSpeed;
-(CValue*)DirectionToX;
-(CValue*)DirectionToY;
-(CValue*)TurnToward;

@end
