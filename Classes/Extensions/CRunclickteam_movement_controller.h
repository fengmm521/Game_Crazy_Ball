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
// MOVEMENT CONTROLLER: extension object
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

//*** Circular movement
#define SET_CIRCLE_CENTRE_X  3345
#define SET_CIRCLE_CENTRE_Y  3346
#define SET_CIRCLE_ANGSPEED  3347
#define SET_CIRCLE_CURRENTANGLE  3348
#define SET_CIRCLE_RADIUS  3349
#define SET_CIRCLE_SPIRALVEL  3350
#define SET_CIRCLE_MINRADIUS  3351
#define SET_CIRCLE_MAXRADIUS  3352
#define SET_CIRCLE_ONCOMPLETION  3353
#define GET_CIRCLE_CENTRE_X  3354
#define GET_CIRCLE_CENTRE_Y  3355
#define GET_CIRCLE_ANGSPEED  3356
#define GET_CIRCLE_CURRENTANGLE  3357
#define GET_CIRCLE_RADIUS  3358
#define GET_CIRCLE_SPIRALVEL  3359
#define GET_CIRCLE_MINRADIUS  3360
#define GET_CIRCLE_MAXRADIUS  3361
//*** Regular Polygon movement
#define SET_REGPOLY_CENTRE_X  3445
#define SET_REGPOLY_CENTRE_Y  3446
#define SET_REGPOLY_NUMSIDES  3447
#define SET_REGPOLY_RADIUS  3448
#define SET_REGPOLY_ROTATION_ANGLE  3449
#define SET_REGPOLY_VELOCITY  3450
#define GET_REGPOLY_CENTRE_X  3451
#define GET_REGPOLY_CENTRE_Y  3452
#define GET_REGPOLY_NUMSIDES  3453
#define GET_REGPOLY_RADIUS  3454
#define GET_REGPOLY_ROTATION_ANGLE  3455
#define GET_REGPOLY_VELOCITY  3456
//*** Sinewave movement
#define SET_SINEWAVE_SPEED  3545
#define SET_SINEWAVE_STARTX  3546
#define SET_SINEWAVE_STARTY  3547
#define SET_SINEWAVE_FINALX  3548
#define SET_SINEWAVE_FINALY  3549
#define SET_SINEWAVE_AMPLITUDE  3550
#define SET_SINEWAVE_ANGVEL  3551
#define SET_SINEWAVE_STARTANG  3552
#define SET_SINEWAVE_CURRENTANGLE  3553
#define GET_SINEWAVE_SPEED  3554
#define GET_SINEWAVE_STARTX  3555
#define GET_SINEWAVE_STARTY  3556
#define GET_SINEWAVE_FINALX  3557
#define GET_SINEWAVE_FINALY  3558
#define GET_SINEWAVE_AMPLITUDE  3559
#define GET_SINEWAVE_ANGVEL  3560
#define GET_SINEWAVE_STARTANG  3561
#define GET_SINEWAVE_CURRENTANGLE  3562
#define RESET_SINEWAVE  3563
#define SET_SINEWAVE_ONCOMPLETION  3564
//*** Simple Ellipse movement
#define SET_SIMPLEELLIPSE_CENTRE_X  3645
#define SET_SIMPLEELLIPSE_CENTRE_Y  3646
#define SET_SIMPLEELLIPSE_RADIUS_X  3647
#define SET_SIMPLEELLIPSE_RADIUS_Y  3648
#define SET_SIMPLEELLIPSE_ANGSPEED  3649
#define SET_SIMPLEELLIPSE_CURRENTANGLE  3650
#define SET_SIMPLEELLIPSE_OFFSETANGLE  3651
#define GET_SIMPLEELLIPSE_CENTRE_X  3652
#define GET_SIMPLEELLIPSE_CENTRE_Y  3653
#define GET_SIMPLEELLIPSE_RADIUS_X  3654
#define GET_SIMPLEELLIPSE_RADIUS_Y  3655
#define GET_SIMPLEELLIPSE_ANGSPEED  3656
#define GET_SIMPLEELLIPSE_CURRENTANGLE  3657
#define GET_SIMPLEELLIPSE_OFFSETANGLE  3658
//*** Invaders movement
#define SET_INVADERS_SPEED  3745
#define SET_INVADERS_STEPX  3746
#define SET_INVADERS_STEPY  3747
#define SET_INVADERS_LEFTBORDER  3748
#define SET_INVADERS_RIGHTBORDER  3749
#define GET_INVADERS_SPEED  3750
#define GET_INVADERS_STEPX  3751
#define GET_INVADERS_STEPY  3752
#define GET_INVADERS_LEFTBORDER  3753
#define GET_INVADERS_RIGHTBORDER  3754
//*** Vector movement
#define SET_Projectile_X  3845
#define SET_Projectile_Y  3846
#define SET_Projectile_XY  3847
#define SET_Projectile_AddDistX  3848
#define SET_Projectile_AddDistY  3849
#define SET_Projectile_Dir  3850
#define SET_Projectile_RotateTowardsAngle  3851
#define SET_Projectile_RotateTowardsPoint  3852
#define SET_Projectile_RotateTowardsObject  3853
#define SET_Projectile_Speed  3854
#define SET_Projectile_SpeedX  3855
#define SET_Projectile_SpeedY  3856
#define SET_Projectile_AddSpeedX  3857
#define SET_Projectile_AddSpeedY  3858
#define SET_Projectile_MinSpeed  3859
#define SET_Projectile_MaxSpeed  3860
#define SET_Projectile_Gravity  3861
#define SET_Projectile_GravityDir  3862
#define SET_Projectile_BounceCoeff  3863
#define SET_Projectile_ForceBounce  3864
#define GET_Projectile_X  3865
#define GET_Projectile_Y  3866
#define GET_Projectile_Dir  3867
#define GET_Projectile_Speed  3868
#define GET_Projectile_SpeedX  3869
#define GET_Projectile_SpeedY  3870
#define GET_Projectile_MinSpeed  3871
#define GET_Projectile_MaxSpeed  3872
#define GET_Projectile_Gravity  3873
#define GET_Projectile_GravityDir  3874
#define GET_Projectile_BounceCoef  3875
//*** Presentation movement
#define SET_PRESENTATION_Next  3945
#define SET_PRESENTATION_Prev  3946
#define SET_PRESENTATION_ToStart  3947
#define SET_PRESENTATION_ToEnd  3948
#define GET_PRESENTATION_Index  3949
#define GET_PRESENTATION_LastIndex  3950
#define SPACE_SETPOWER  0
#define SPACE_SETSPEED  1
#define SPACE_SETDIR  2
#define SPACE_SETDEC  3
#define SPACE_SETROTSPEED  4
#define SPACE_SETGRAVITY  5
#define SPACE_SETGRAVITYDIR  6
#define SPACE_APPLYREACTOR  7
#define SPACE_APPLYROTATERIGHT  8
#define SPACE_APPLYROTATELEFT  9
#define SPACE_GETGRAVITY  10
#define SPACE_GETGRAVITYDIR  11
#define SPACE_GETDECELERATION  12
#define SPACE_GETROTATIONSPEED  13
#define SPACE_GETTHRUSTPOWER  14

//*** Drag-drop movement
#define SET_DragDrop_Method  4145
#define SET_DragDrop_IsLimited 4146
#define SET_DragDrop_DropOutsideArea 4147
#define SET_DragDrop_ForceWithinLimits 4148
#define SET_DragDrop_AreaX 4149
#define SET_DragDrop_AreaY 4150
#define SET_DragDrop_AreaW 4151
#define SET_DragDrop_AreaH 4152
#define SET_DragDrop_SnapToGrid 4153
#define SET_DragDrop_GridX 4154
#define SET_DragDrop_GridY 4155
#define SET_DragDrop_GridW 4156
#define SET_DragDrop_GridH 4157

#define GET_DragDrop_AreaX 4158
#define GET_DragDrop_AreaY 4159
#define GET_DragDrop_AreaW 4160
#define GET_DragDrop_AreaH 4161
#define GET_DragDrop_GridX 4162
#define GET_DragDrop_GridY 4163
#define GET_DragDrop_GridW 4164
#define GET_DragDrop_GridH 4165

#define ToRadians 0.017453292519943295769236907684886
#define ToDegrees 57.295779513082320876798154814105

@interface CRunclickteam_movement_controller : CRunExtension
{
    CObject* currentObject;	
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(CObject*)getCurrentObject:(NSString*)dllName;
-(int)enumerateRuntimeObjects:(NSString*)dllName;
-(CObject*)findObject:(NSString*)dllName;
-(void)Action_SetObject_Object:(CActExtension*)act;
-(void)Action_SetObject_FixedValue:(CActExtension*)act;
-(void)Action_SET_CIRCLE_CENTRE_X:(CActExtension*)act;
-(void)Action_SET_CIRCLE_CENTRE_Y:(CActExtension*)act;
-(void)Action_SET_CIRCLE_ANGSPEED:(CActExtension*)act;
-(void)Action_SET_CIRCLE_CURRENTANGLE:(CActExtension*)act;
-(void)Action_SET_CIRCLE_RADIUS:(CActExtension*)act;
-(void)Action_SET_CIRCLE_SPIRALVEL:(CActExtension*)act;
-(void)Action_SET_CIRCLE_MINRADIUS:(CActExtension*)act;
-(void)Action_SET_CIRCLE_MAXRADIUS:(CActExtension*)act;
-(void)Action_SET_CIRCLE_ONEND1:(CActExtension*)act;
-(void)Action_SET_CIRCLE_ONEND2:(CActExtension*)act;
-(void)Action_SET_CIRCLE_ONEND3:(CActExtension*)act;
-(void)Action_SET_CIRCLE_ONEND4:(CActExtension*)act;
-(void)Action_SET_REGPOLY_CENTRE_X:(CActExtension*)act;
-(void)Action_SET_REGPOLY_CENTRE_Y:(CActExtension*)act;
-(void)Action_SET_REGPOLY_NUMSIDES:(CActExtension*)act;
-(void)Action_SET_REGPOLY_RADIUS:(CActExtension*)act;
-(void)Action_SET_REGPOLY_ROTATION_ANGLE:(CActExtension*)act;
-(void)Action_SET_REGPOLY_VELOCITY:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_SPEED:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_STARTX:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_STARTY:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_FINALX:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_FINALY:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_AMPLITUDE:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_ANGVEL:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_STARTANG:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_CURRENTANGLE:(CActExtension*)act;
-(void)Action_RESET_SINEWAVE:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_ONEND1:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_ONEND2:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_ONEND3:(CActExtension*)act;
-(void)Action_SET_SINEWAVE_ONEND4:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_CENTRE_X:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_CENTRE_Y:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_RADIUS_X:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_RADIUS_Y:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_ANGVEL:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_CURRENTANGLE:(CActExtension*)act;
-(void)Action_SET_SIMPLEELLIPSE_OFFSETANGLE:(CActExtension*)act;
-(void)Action_SET_INVADERS_SPEED:(CActExtension*)act;
-(void)Action_SET_INVADERS_STEPX:(CActExtension*)act;
-(void)Action_SET_INVADERS_STEPY:(CActExtension*)act;
-(void)Action_SET_INVADERS_LEFTBORDER:(CActExtension*)act;
-(void)Action_SET_INVADERS_RIGHTBORDER:(CActExtension*)act;
-(void)Action_SET_Projectile_X:(CActExtension*)act;
-(void)Action_SET_Projectile_Y:(CActExtension*)act;
-(void)Action_SET_Projectile_XY:(CActExtension*)act;
-(void)Action_SET_Projectile_MoveTowardsAngle:(CActExtension*)act;
-(void)Action_SET_Projectile_MoveTowardsPoint:(CActExtension*)act;
-(void)Action_SET_Projectile_MoveTowardsObject:(CActExtension*)act;
-(void)Action_SET_Projectile_Dir:(CActExtension*)act;
-(void)Action_SET_Projectile_DirToPoint:(CActExtension*)act;
-(void)Action_SET_Projectile_DirToObject:(CActExtension*)act;
-(void)Action_SET_Projectile_RotateTowardsAngle:(CActExtension*)act;
-(void)Action_SET_Projectile_RotateTowardsPoint:(CActExtension*)act;
-(void)Action_SET_Projectile_RotateTowardsObject:(CActExtension*)act;
-(void)Action_SET_Projectile_Speed:(CActExtension*)act;
-(void)Action_SET_Projectile_SpeedX:(CActExtension*)act;
-(void)Action_SET_Projectile_SpeedY:(CActExtension*)act;
-(void)Action_SET_Projectile_AddDirSpeedTowardsAngle:(CActExtension*)act;
-(void)Action_SET_Projectile_AddDirSpeedTowardsPoint:(CActExtension*)act;
-(void)Action_SET_Projectile_AddDirSpeedTowardsObject:(CActExtension*)act;
-(void)Action_SET_Projectile_MinSpeed:(CActExtension*)act;
-(void)Action_SET_Projectile_MaxSpeed:(CActExtension*)act;
-(void)Action_SET_Projectile_Gravity:(CActExtension*)act;
-(void)Action_SET_Projectile_GravityDir:(CActExtension*)act;
-(void)Action_SET_Projectile_GravityDirToPoint:(CActExtension*)act;
-(void)Action_SET_Projectile_GravityDirToObject:(CActExtension*)act;
-(void)Action_SET_Projectile_BounceCoeff:(CActExtension*)act;
-(void)Action_SET_Projectile_ForceBounce:(CActExtension*)act;
-(void)Action_SET_PRESENTATION_Next:(CActExtension*)act;
-(void)Action_SET_PRESENTATION_Prev:(CActExtension*)act;
-(void)Action_SET_PRESENTATION_ToStart:(CActExtension*)act;
-(void)Action_SET_PRESENTATION_ToEnd:(CActExtension*)act;
-(void)Action_SetPower:(CActExtension*)act;
-(void)Action_SetSpeed:(CActExtension*)act;
-(void)Action_SetDir:(CActExtension*)act;
-(void)Action_SetDec:(CActExtension*)act;
-(void)Action_SetRotSpeed:(CActExtension*)act;
-(void)Action_SetGravity:(CActExtension*)act;
-(void)Action_SetGravityDir:(CActExtension*)act;
-(void)Action_ApplyReactor:(CActExtension*)act;
-(void)Action_ApplyRotateRight:(CActExtension*)act;
-(void)Action_ApplyRotateLeft:(CActExtension*)act;
-(void)Action_DragDrop_Method1:(CActExtension*)act;
-(void)Action_DragDrop_Method2:(CActExtension*)act;
-(void)Action_DragDrop_Method3:(CActExtension*)act;
-(void)Action_DragDrop_Method4:(CActExtension*)act;
-(void)Action_DragDrop_Method5:(CActExtension*)act;
-(void)Action_DragDrop_IsLimited:(CActExtension*)act;
-(void)Action_DragDrop_IsLimitedOff:(CActExtension*)act;
-(void)Action_DragDrop_DropOutsideArea:(CActExtension*)act;
-(void)Action_DragDrop_DropOutsideAreaOff:(CActExtension*)act;
-(void)Action_DragDrop_ForceWithinLimits:(CActExtension*)act;
-(void)Action_DragDrop_ForceWithinLimitsOff:(CActExtension*)act;
-(void)Action_DragDrop_Area:(CActExtension*)act;
-(void)Action_DragDrop_AreaX:(CActExtension*)act;
-(void)Action_DragDrop_AreaY:(CActExtension*)act;
-(void)Action_DragDrop_AreaW:(CActExtension*)act;
-(void)Action_DragDrop_AreaH:(CActExtension*)act;
-(void)Action_DragDrop_SnapToGrid:(CActExtension*)act;
-(void)Action_DragDrop_SnapToGridOff:(CActExtension*)act;
-(void)Action_DragDrop_GridOrigin:(CActExtension*)act;
-(void)Action_DragDrop_GridX:(CActExtension*)act;
-(void)Action_DragDrop_GridY:(CActExtension*)act;
-(void)Action_DragDrop_GridW:(CActExtension*)act;
-(void)Action_DragDrop_GridH:(CActExtension*)act;
-(int)Expression_GET_CIRCLE_CENTRE_X;
-(int)Expression_GET_CIRCLE_CENTRE_Y;
-(int)Expression_GET_CIRCLE_ANGSPEED;
-(int)Expression_GET_CIRCLE_CURRENTANGLE;
-(int)Expression_GET_CIRCLE_RADIUS;
-(int)Expression_GET_CIRCLE_SPIRALVEL;
-(int)Expression_GET_CIRCLE_MINRADIUS;
-(int)Expression_GET_CIRCLE_MAXRADIUS;
-(int)Expression_GET_CIRCLE_COUNT;
-(int)Expression_GET_REGPOLY_CENTRE_X;
-(int)Expression_GET_REGPOLY_CENTRE_Y;
-(int)Expression_GET_REGPOLY_NUMSIDES;
-(int)Expression_GET_REGPOLY_RADIUS;
-(int)Expression_GET_REGPOLY_ROTATION_ANGLE;
-(int)Expression_GET_REGPOLY_VELOCITY;
-(int)Expression_GET_REGPOLY_COUNT;
-(int)Expression_GET_SINEWAVE_SPEED;
-(int)Expression_GET_SINEWAVE_STARTX;
-(int)Expression_GET_SINEWAVE_STARTY;
-(int)Expression_GET_SINEWAVE_FINALX;
-(int)Expression_GET_SINEWAVE_FINALY;
-(int)Expression_GET_SINEWAVE_AMPLITUDE;
-(int)Expression_GET_SINEWAVE_ANGVEL;
-(int)Expression_GET_SINEWAVE_STARTANG;
-(int)Expression_GET_SINEWAVE_CURRENTANGLE;
-(int)Expression_GET_SINEWAVE_COUNT;
-(int)Expression_GET_SIMPLEELLIPSE_CENTRE_X;
-(int)Expression_GET_SIMPLEELLIPSE_CENTRE_Y;
-(int)Expression_GET_SIMPLEELLIPSE_RADIUS_X;
-(int)Expression_GET_SIMPLEELLIPSE_RADIUS_Y;
-(int)Expression_GET_SIMPLEELLIPSE_ANGVEL;
-(int)Expression_GET_SIMPLEELLIPSE_CURRENTANGLE;
-(int)Expression_GET_SIMPLEELLIPSE_OFFSETANGLE;
-(int)Expression_GET_SIMPLEELLIPSE_COUNT;
-(int)Expression_GET_INVADERS_SPEED;
-(int)Expression_GET_INVADERS_STEPX;
-(int)Expression_GET_INVADERS_STEPY;
-(int)Expression_GET_INVADERS_LEFTBORDER;
-(int)Expression_GET_INVADERS_RIGHTBORDER;
-(int)Expression_GET_INVADERS_COUNT;
-(double)Expression_GET_Projectile_X;
-(double)Expression_GET_Projectile_Y;
-(double)Expression_GET_Projectile_Dir;
-(double)Expression_GET_Projectile_Speed;
-(double)Expression_GET_Projectile_SpeedX;
-(double)Expression_GET_Projectile_SpeedY;
-(double)Expression_GET_Projectile_MinSpeed;
-(double)Expression_GET_Projectile_MaxSpeed;
-(double)Expression_GET_Projectile_Gravity;
-(double)Expression_GET_Projectile_GravityDir;
-(double)Expression_GET_Projectile_BounceCoef;
-(int)Expression_GET_Projectile_Count;
-(int)Expression_GET_PRESENTATION_Index;
-(int)Expression_GET_PRESENTATION_LastIndex;
-(int)Expression_GET_PRESENTATION_Count;
-(int)Expression_SpaceShip_Gravity;
-(int)Expression_SpaceShip_GravityDir;
-(int)Expression_SpaceShip_Deceleration;
-(int)Expression_SpaceShip_RotationSpeed;
-(int)Expression_SpaceShip_ThrustPower;
-(int)Expression_SpaceShip_Count;
-(double)Expression_DistObjects;
-(double)Expression_DistPoints;
-(double)Expression_AngleObjects;
-(double)Expression_AnglePoints;
-(int)Expression_Angle2Dir;
-(double)Expression_Dir2Angle;
-(int)Expression_DragDrop_AreaX;
-(int)Expression_DragDrop_AreaY;
-(int)Expression_DragDrop_AreaW;
-(int)Expression_DragDrop_AreaH;
-(int)Expression_DragDrop_GridX;
-(int)Expression_DragDrop_GridY;
-(int)Expression_DragDrop_GridW;
-(int)Expression_DragDrop_GridH;


@end
