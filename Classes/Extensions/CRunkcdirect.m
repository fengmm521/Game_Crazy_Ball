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
// ---------------------------------------------------------------------------------
#import "CRunkcdirect.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"
#import "CObjectCommon.h"
#import "CMoveDef.h"
#import "CMoveDefExtension.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CMoveDefList.h"
#import "CRMvt.h"
#import "CServices.h"

@implementation CRunkcdirect

-(id)init
{
    angle_to_turn = 1;
    speed1 = 20;
    speed2 = 20;
    dir_to_add = 16;
	return self;
}

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	return YES;
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_SET_TURN: //"Set the amount to rotate"
			[self SetTurn:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_TURN_DIRECTIONS: //"Rotate object toward a direction"
			[self TurnToDirection:[act getParamExpression:rh withNum:0]  withParam1:[act getParamObject:rh withNum:1]];
			break;
		case ACT_TURN_POS: //"Rotate object toward a position"
			[self TurnToPosition:[act getParamObject:rh withNum:0]  withParam1:[act getParamPosition:rh withNum:1]];
			break;
		case ACT_ADD_DIR: //"Add a directional speed to an object"
			[self AddDir_act:[act getParamExpression:rh withNum:0]  withParam1:[act getParamObject:rh withNum:1]];
			break;
		case ACT_DIR_SET: //"Set the direction to add"
			[self AngleSet:[act getParamExpression:rh withNum:0]];
			break;
	}
}

-(void)SetTurn:(int)v
{
	angle_to_turn = v;
}

-(void)TurnToDirection:(int)dir withParam1:(CObject*)object
{
	if (object==nil)
	{
		return;
	}
	int goal_angle, direction;
	int cc;
	int cl;
	int angle;
	
	direction = object->roc->rcDir;
	goal_angle = dir;
	
	goal_angle = goal_angle % 32;
	if (goal_angle < 0)
	{
		goal_angle += 32;
	}
	
	cc = goal_angle - direction;
	if (cc < 0)
	{
		cc += 32;
	}
	cl = direction - goal_angle;
	if (cl < 0)
	{
		cl += 32;
	}
	if (cc < cl)
	{
		angle = cc;
	}
	else
	{
		angle = cl;
	}
	if (angle > angle_to_turn)
	{
		angle = angle_to_turn;
	}
	if (cl < cc)
	{
		angle = -angle;
	}
	
	direction += angle;
	if (direction >= 32)
	{
		direction -= 32;
	}
	if (direction <= -1)
	{
		direction += 32;
	}
	object->roc->rcDir = (short) direction;
	
	object->roc->rcChanged = YES;
	object->roc->rcCheckCollides = YES;
}

-(void)TurnToPosition:(CObject*)object withParam1:(unsigned int)position
{
	if (object==nil)
	{
		return;
	}
	
	int goal_angle, direction;
	int cc;
	int cl;
	int angle;
	double look_angle;
	int l1, l2;
	direction = object->roc->rcDir;
	
	l1 = LOWORD(position);
	l2 = HIWORD(position);
	
	l1 -= object->hoX;
	l2 -= object->hoY;
	
	look_angle = atan2((double)-l2, (double)l1);
	if (look_angle < 0.0)
	{
		look_angle = look_angle + 2.0 * 3.1416;
	}
	
	goal_angle = (int) (look_angle * 32.0 / (2.0 * 3.1416) + 0.5);
	
	cc = goal_angle - direction;
	if (cc < 0)
	{
		cc += 32;
	}
	cl = direction - goal_angle;
	if (cl < 0)
	{
		cl += 32;
	}
	if (cc < cl)
	{
		angle = cc;
	}
	else
	{
		angle = cl;
	}
	if (angle > angle_to_turn)
	{
		angle = angle_to_turn;
	}
	if (cl < cc)
	{
		angle = -angle;
	}
	
	direction += angle;
	if (direction > 31)
	{
		direction -= 32;
	}
	if (direction < 0)
	{
		direction += 32;
	}
	object->roc->rcDir = (short) direction;
	object->roc->rcChanged = YES;
	object->roc->rcCheckCollides = YES;
}
	
-(void)AddDir_act:(int)speed withParam1:(CObject*)object
{
	if (object==nil)
	{
		return;
	}
	
	double angle1, angle2;
	double x1, y1;
	double x2, y2;
	double x2_delta, y2_delta;
	double look_angle;
	double diff_ang;
	int final_dir;
	int final_speed;
	int direction1;
	int object_speed;
	int add_speed;
	add_speed = speed;
	
	object_speed = object->roc->rcSpeed;
	direction1 = object->roc->rcDir;
	angle1 = (direction1 * 2 * 3.1416 / 32);
	angle2 = (dir_to_add * 2 * 3.1416 / 32);
	
	x1 = object_speed * cosf(angle1);
	y1 = object_speed * sinf(angle1);
	
	x2_delta = add_speed * cosf(angle2);
	y2_delta = add_speed * sinf(angle2);
	x2 = x1 + x2_delta;
	y2 = y1 + y2_delta;
	
	if ((abs(dir_to_add - direction1) % 32) != 16)
	{
		// Round the original angle of the object in the direction we are trying to
		//  move it.
		look_angle = atan2(y2 ,x2);
		diff_ang = look_angle - angle1;
		if (diff_ang > 3.1416)
		{
			diff_ang -= 2 * 3.1416;
		}
		else if (diff_ang < -3.1416)
		{
			diff_ang += 2 * 3.1416;
		}
		if (diff_ang < 0.0)
		{
			angle1 -= 3.1416 / 32;
		}
		else
		{
			angle1 += 3.1416 / 32;
		}
		
		x1 = object_speed * cos(angle1);
		y1 = object_speed * sin(angle1);
		
		x2 = x1 + x2_delta;
		y2 = y1 + y2_delta;
	}
	look_angle = atan2(y2, x2);
	if (look_angle < 0.0)
	{
		look_angle = look_angle + 2.0 * 3.1416;
	}
	final_dir = (int) (look_angle * 32.0 / (2.0 * 3.1416) + 0.5);
	if (final_dir >= 32)
	{
		final_dir -= 32;
	}
	object->roc->rcDir = (short) final_dir;
	final_speed = (int)( sqrt(x2 * x2 + y2 * y2) + 0.5);
	if (final_speed > 100)
	{
		final_speed = 100;
	}
	object->roc->rcSpeed = (short) final_speed;
	object->roc->rcChanged = YES;
	object->roc->rcCheckCollides = YES;
}
		
-(void)AngleSet:(int)angle
{
	dir_to_add = angle;
	dir_to_add = dir_to_add % 32;
	if (dir_to_add < 0)
	{
		dir_to_add += 32;
	}
}
		
// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_XY_TO_DIR:
			return [self XYtoDir];
		case EXP_XY_TO_SPD:
			return [self XyToSpeed];
		case EXP_DIR_TO_X:
			return [self DirectionToX];
		case EXP_DIR_TO_Y:
			return [self DirectionToY];
		case EXP_TURN_TOWARD:
			return [self TurnToward];
	}
	return [rh getTempValue:0];//won't be used
}

-(CValue*)XYtoDir
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	double angle;
	int iang;
	angle = atan2((double)-y, (double) x);
	if (angle < 0.0)
	{
		angle = angle + 2.0 * 3.1416;
	}
	iang = (int) (angle * 32.0 / (2.0 * 3.1416) + 0.5);
	return [rh getTempValue:iang];
}
	
-(CValue*)XyToSpeed
{
	int ispeed;
	double speed;

	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	
	speed = sqrt(x * x + y * y);
	ispeed = (int) (speed + (speed < 0.0 ? -0.5 : 0.5));
	
	return [rh getTempValue:ispeed];
}
	
-(CValue*)DirectionToX
{
	int x;
	double xval;

	int dir=[[ho getExpParam] getInt];
	int speed=[[ho getExpParam] getInt];
	
	dir = dir % 32;
	if (dir < 0)
	{
		dir += 32;
	}
	
	xval = speed * cos(dir * 2 * 3.1416 / 32);
	x = (int) (xval + (speed < 0 ? -0.5 : 0.5));
	return [rh getTempValue:x];
}
	
-(CValue*)DirectionToY
{
	int y;
	double yval;
	
	int dir=[[ho getExpParam] getInt];
	int speed=[[ho getExpParam] getInt];
	dir = dir % 32;
	if (dir < 0)
	{
		dir += 32;
	}
	
	yval = speed * sin(dir * 2 * 3.1416 / 32);
	y = (int) (yval + (speed < 0 ? -0.5 : 0.5));
	
	return [rh getTempValue:-y];
}
	
-(CValue*)TurnToward
{
	int cc;
	int cl;
	int angle;
	
	int direction=[[ho getExpParam] getInt];
	int goal_angle=[[ho getExpParam] getInt];

	goal_angle = goal_angle % 32;
	if (goal_angle < 0)
	{
		goal_angle += 32;
	}
	
	direction = direction % 32;
	if (direction < 0)
	{
		direction += 32;
	}
	
	cc = goal_angle - direction;
	if (cc < 0)
	{
		cc += 32;
	}
	cl = direction - goal_angle;
	if (cl < 0)
	{
		cl += 32;
	}
	if (cc < cl)
	{
		angle = cc;
	}
	else
	{
		angle = cl;
	}
	if (angle > angle_to_turn)
	{
		angle = angle_to_turn;
	}
	if (cl < cc)
	{
		angle = -angle;
	}
	direction += angle;
	return [rh getTempValue:direction];
}
	
@end
