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
#import "CRunclickteam_movement_controller.h"
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
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CObject.h"
#import "CExtension.h"
#import "CLayer.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CArrayList.h"
#import "CObjInfo.h"
#import "CRVal.h"
#import "CEventProgram.h"
#import "CFile.h"

NSString* DLL_CIRCULAR = @"clickteam-circular";
NSString* DLL_INVADERS = @"clickteam-invaders";
NSString* DLL_PRESENTATION = @"clickteam-presentation";
NSString* DLL_REGPOLYGON = @"clickteam-regpolygon";
NSString* DLL_SIMPLE_ELLIPSE = @"clickteam-simple_ellipse";
NSString* DLL_SINEWAVE = @"clickteam-sinewave";
NSString* DLL_VECTOR = @"clickteam-vector";
NSString* DLL_SPACESHIP = @"spaceship";
NSString* DLL_DRAGDROP = @"clickteam-dragdrop";

@implementation CRunclickteam_movement_controller

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
            //*** Circular movement
		case 0:
			[self Action_SET_CIRCLE_CENTRE_X:act];
			break;
		case 1:
			[self Action_SET_CIRCLE_CENTRE_Y:act];
			break;
		case 2:
			[self Action_SET_CIRCLE_ANGSPEED:act];
			break;
		case 3:
			[self Action_SET_CIRCLE_CURRENTANGLE:act];
			break;
		case 4:
			[self Action_SET_CIRCLE_RADIUS:act];
			break;
		case 5:
			[self Action_SET_CIRCLE_SPIRALVEL:act];
			break;
		case 6:
			[self Action_SET_CIRCLE_MINRADIUS:act];
			break;
		case 7:
			[self Action_SET_CIRCLE_MAXRADIUS:act];
			break;
		case 8:
			[self Action_SET_CIRCLE_ONEND1:act];
			break;
		case 9:
			[self Action_SET_CIRCLE_ONEND2:act];
			break;
		case 10:
			[self Action_SET_CIRCLE_ONEND3:act];
			break;
		case 11:
			[self Action_SET_CIRCLE_ONEND4:act];
			break;
			
            //*** Regular Polygon movement
		case 12:
			[self Action_SET_REGPOLY_CENTRE_X:act];
			break;
		case 13:
			[self Action_SET_REGPOLY_CENTRE_Y:act];
			break;
		case 14:
			[self Action_SET_REGPOLY_NUMSIDES:act];
			break;
		case 15:
			[self Action_SET_REGPOLY_RADIUS:act];
			break;
		case 16:
			[self Action_SET_REGPOLY_ROTATION_ANGLE:act];
			break;
		case 17:
			[self Action_SET_REGPOLY_VELOCITY:act];
			break;
			
            //*** Sinewave movement
		case 18:
			[self Action_SET_SINEWAVE_SPEED:act];
			break;
		case 19:
			[self Action_SET_SINEWAVE_STARTX:act];
			break;
		case 20:
			[self Action_SET_SINEWAVE_STARTY:act];
			break;
		case 21:
			[self Action_SET_SINEWAVE_FINALX:act];
			break;
		case 22:
			[self Action_SET_SINEWAVE_FINALY:act];
			break;
		case 23:
			[self Action_SET_SINEWAVE_AMPLITUDE:act];
			break;
		case 24:
			[self Action_SET_SINEWAVE_ANGVEL:act];
			break;
		case 25:
			[self Action_SET_SINEWAVE_STARTANG:act];
			break;
		case 26:
			[self Action_SET_SINEWAVE_CURRENTANGLE:act];
			break;
		case 27:
			[self Action_RESET_SINEWAVE:act];
			break;
		case 28:
			[self Action_SET_SINEWAVE_ONEND1:act];
			break;
		case 29:
			[self Action_SET_SINEWAVE_ONEND2:act];
			break;
		case 30:
			[self Action_SET_SINEWAVE_ONEND3:act];
			break;
		case 31:
			[self Action_SET_SINEWAVE_ONEND4:act];
			break;
			
            //*** Simple Ellipse movement
		case 32:
			[self Action_SET_SIMPLEELLIPSE_CENTRE_X:act];
			break;
		case 33:
			[self Action_SET_SIMPLEELLIPSE_CENTRE_Y:act];
			break;
		case 34:
			[self Action_SET_SIMPLEELLIPSE_RADIUS_X:act];
			break;
		case 35:
			[self Action_SET_SIMPLEELLIPSE_RADIUS_Y:act];
			break;
		case 36:
			[self Action_SET_SIMPLEELLIPSE_ANGVEL:act];
			break;
		case 37:
			[self Action_SET_SIMPLEELLIPSE_CURRENTANGLE:act];
			break;
		case 38:
			[self Action_SET_SIMPLEELLIPSE_OFFSETANGLE:act];
			break;
			
            //*** Invaders movement
		case 39:
			[self Action_SET_INVADERS_SPEED:act];
			break;
		case 40:
			[self Action_SET_INVADERS_STEPX:act];
			break;
		case 41:
			[self Action_SET_INVADERS_STEPY:act];
			break;
		case 42:
			[self Action_SET_INVADERS_LEFTBORDER:act];
			break;
		case 43:
			[self Action_SET_INVADERS_RIGHTBORDER:act];
			break;
			
            //*** Vector movement
		case 44:
			[self Action_SET_Projectile_X:act];
			break;
		case 45:
			[self Action_SET_Projectile_Y:act];
			break;
		case 46:
			[self Action_SET_Projectile_XY:act];
			break;
		case 47:
			[self Action_SET_Projectile_MoveTowardsAngle:act];
			break;
		case 48:
			[self Action_SET_Projectile_MoveTowardsPoint:act];
			break;
		case 49:
			[self Action_SET_Projectile_MoveTowardsObject:act];
			break;
		case 50:
			[self Action_SET_Projectile_Dir:act];
			break;
		case 51:
			[self Action_SET_Projectile_DirToPoint:act];
			break;
		case 52:
			[self Action_SET_Projectile_DirToObject:act];
			break;
		case 53:
			[self Action_SET_Projectile_RotateTowardsAngle:act];
			break;
		case 54:
			[self Action_SET_Projectile_RotateTowardsPoint:act];
			break;
		case 55:
			[self Action_SET_Projectile_RotateTowardsObject:act];
			break;
		case 56:
			[self Action_SET_Projectile_Speed:act];
			break;
		case 57:
			[self Action_SET_Projectile_SpeedX:act];
			break;
		case 58:
			[self Action_SET_Projectile_SpeedY:act];
			break;
		case 59:
			[self Action_SET_Projectile_AddDirSpeedTowardsAngle:act];
			break;
		case 60:
			[self Action_SET_Projectile_AddDirSpeedTowardsPoint:act];
			break;
		case 61:
			[self Action_SET_Projectile_AddDirSpeedTowardsObject:act];
			break;
		case 62:
			[self Action_SET_Projectile_MinSpeed:act];
			break;
		case 63:
			[self Action_SET_Projectile_MaxSpeed:act];
			break;
		case 64:
			[self Action_SET_Projectile_Gravity:act];
			break;
		case 65:
			[self Action_SET_Projectile_GravityDir:act];
			break;
		case 66:
			[self Action_SET_Projectile_GravityDirToPoint:act];
			break;
		case 67:
			[self Action_SET_Projectile_GravityDirToObject:act];
			break;
		case 68:
			[self Action_SET_Projectile_BounceCoeff:act];
			break;
		case 69:
			[self Action_SET_Projectile_ForceBounce:act];
			break;
			
            //*** Presentation movement
		case 70:
			[self Action_SET_PRESENTATION_Next:act];
			break;
		case 71:
			[self Action_SET_PRESENTATION_Prev:act];
			break;
		case 72:
			[self Action_SET_PRESENTATION_ToStart:act];
			break;
		case 73:
			[self Action_SET_PRESENTATION_ToEnd:act];
			break;
			
            //*** Set Object
		case 74:
			[self Action_SetObject_Object:act];
			break;
		case 75:
			[self Action_SetObject_FixedValue:act];
			break;
			
            // Spaceship
		case 76:
			[self Action_SetPower:act];
			break;
		case 77:
			[self Action_SetSpeed:act];
			break;
		case 78:
			[self Action_SetDir:act];
			break;
		case 79:
			[self Action_SetDec:act];
			break;
		case 80:
			[self Action_SetRotSpeed:act];
			break;
		case 81:
			[self Action_SetGravity:act];
			break;
		case 82:
			[self Action_SetGravityDir:act];
			break;
		case 83:
			[self Action_ApplyReactor:act];
			break;
		case 84:
			[self Action_ApplyRotateRight:act];
			break;
		case 85:
			[self Action_ApplyRotateLeft:act];
			break;
        	//*** Drag-drop Object
		case 86:
			[self Action_DragDrop_Method1:act];
			break;
		case 87:
			[self Action_DragDrop_Method2:act];
			break;
		case 88:
			[self Action_DragDrop_Method3:act];
			break;
		case 89:
			[self Action_DragDrop_Method4:act];
			break;
		case 90:
			[self Action_DragDrop_Method5:act];
			break;
		case 91:
			[self Action_DragDrop_IsLimited:act];
			break;
		case 92:
			[self Action_DragDrop_IsLimitedOff:act];
			break;
		case 93:
			[self Action_DragDrop_DropOutsideArea:act];
			break;
		case 94:
			[self Action_DragDrop_DropOutsideAreaOff:act];
			break;
		case 95:
			[self Action_DragDrop_ForceWithinLimits:act];
			break;
		case 96:
			[self Action_DragDrop_ForceWithinLimitsOff:act];
			break;
		case 97:
			[self Action_DragDrop_Area:act];
			break;
		case 98:
			[self Action_DragDrop_AreaX:act];
			break;
		case 99:
			[self Action_DragDrop_AreaY:act];
			break;
		case 100:
			[self Action_DragDrop_AreaW:act];
			break;
		case 101:
			[self Action_DragDrop_AreaH:act];
			break;
		case 102:
			[self Action_DragDrop_SnapToGrid:act];
			break;
		case 103:
			[self Action_DragDrop_SnapToGridOff:act];
			break;
		case 104:
			[self Action_DragDrop_GridOrigin:act];
			break;
		case 105:
			[self Action_DragDrop_GridX:act];
			break;
		case 106:
			[self Action_DragDrop_GridY:act];
			break;
		case 107:
			[self Action_DragDrop_GridW:act];
			break;
		case 108:
			[self Action_DragDrop_GridH:act];
			break;
	}
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	int value = 0;
	double dValue = 0.0;
	BOOL bDouble = NO;
	
	switch (num)
	{
            //*** Circular movement
		case 0:
			value = [self Expression_GET_CIRCLE_CENTRE_X];
			break;
		case 1:
			value = [self Expression_GET_CIRCLE_CENTRE_Y];
			break;
		case 2:
			value = [self Expression_GET_CIRCLE_ANGSPEED];
			break;
		case 3:
			value = [self Expression_GET_CIRCLE_CURRENTANGLE];
			break;
		case 4:
			value = [self Expression_GET_CIRCLE_RADIUS];
			break;
		case 5:
			value = [self Expression_GET_CIRCLE_SPIRALVEL];
			break;
		case 6:
			value = [self Expression_GET_CIRCLE_MINRADIUS];
			break;
		case 7:
			value = [self Expression_GET_CIRCLE_MAXRADIUS];
			break;
		case 8:
			value = [self Expression_GET_CIRCLE_COUNT];
			break;
			
            //*** Regular Polygon movement
		case 9:
			value = [self Expression_GET_REGPOLY_CENTRE_X];
			break;
		case 10:
			value = [self Expression_GET_REGPOLY_CENTRE_Y];
			break;
		case 11:
			value = [self Expression_GET_REGPOLY_NUMSIDES];
			break;
		case 12:
			value = [self Expression_GET_REGPOLY_RADIUS];
			break;
		case 13:
			value = [self Expression_GET_REGPOLY_ROTATION_ANGLE];
			break;
		case 14:
			value = [self Expression_GET_REGPOLY_VELOCITY];
			break;
		case 15:
			value = [self Expression_GET_REGPOLY_COUNT];
			break;
			
            //*** Sinewave movement
		case 16:
			value = [self Expression_GET_SINEWAVE_SPEED];
			break;
		case 17:
			value = [self Expression_GET_SINEWAVE_STARTX];
			break;
		case 18:
			value = [self Expression_GET_SINEWAVE_STARTY];
			break;
		case 19:
			value = [self Expression_GET_SINEWAVE_FINALX];
			break;
		case 20:
			value = [self Expression_GET_SINEWAVE_FINALY];
			break;
		case 21:
			value = [self Expression_GET_SINEWAVE_AMPLITUDE];
			break;
		case 22:
			value = [self Expression_GET_SINEWAVE_ANGVEL];
			break;
		case 23:
			value = [self Expression_GET_SINEWAVE_STARTANG];
			break;
		case 24:
			value = [self Expression_GET_SINEWAVE_CURRENTANGLE];
			break;
		case 25:
			value = [self Expression_GET_SINEWAVE_COUNT];
			break;
			
            //*** Simple Ellipse movement
		case 26:
			value = [self Expression_GET_SIMPLEELLIPSE_CENTRE_X];
			break;
		case 27:
			value = [self Expression_GET_SIMPLEELLIPSE_CENTRE_Y];
			break;
		case 28:
			value = [self Expression_GET_SIMPLEELLIPSE_RADIUS_X];
			break;
		case 29:
			value = [self Expression_GET_SIMPLEELLIPSE_RADIUS_Y];
			break;
		case 30:
			value = [self Expression_GET_SIMPLEELLIPSE_ANGVEL];
			break;
		case 31:
			value = [self Expression_GET_SIMPLEELLIPSE_CURRENTANGLE];
			break;
		case 32:
			value = [self Expression_GET_SIMPLEELLIPSE_OFFSETANGLE];
			break;
		case 33:
			value = [self Expression_GET_SIMPLEELLIPSE_COUNT];
			break;
			
            //*** Invaders movement
		case 34:
			value = [self Expression_GET_INVADERS_SPEED];
			break;
		case 35:
			value = [self Expression_GET_INVADERS_STEPX];
			break;
		case 36:
			value = [self Expression_GET_INVADERS_STEPY];
			break;
		case 37:
			value = [self Expression_GET_INVADERS_LEFTBORDER];
			break;
		case 38:
			value = [self Expression_GET_INVADERS_RIGHTBORDER];
			break;
		case 39:
			value = [self Expression_GET_INVADERS_COUNT];
			break;
			
            //*** Vector movement
		case 40:
			dValue = [self Expression_GET_Projectile_X];
			bDouble = YES;
			break;
		case 41:
			dValue = [self Expression_GET_Projectile_Y];
			bDouble = YES;
			break;
		case 42:
			dValue = [self Expression_GET_Projectile_Dir];
			bDouble = YES;
			break;
		case 43:
			dValue = [self Expression_GET_Projectile_Speed];
			bDouble = YES;
			break;
		case 44:
			dValue = [self Expression_GET_Projectile_SpeedX];
			bDouble = YES;
			break;
		case 45:
			dValue = [self Expression_GET_Projectile_SpeedY];
			bDouble = YES;
			break;
		case 46:
			dValue = [self Expression_GET_Projectile_MinSpeed];
			bDouble = YES;
			break;
		case 47:
			dValue = [self Expression_GET_Projectile_MaxSpeed];
			bDouble = YES;
			break;
		case 48:
			dValue = [self Expression_GET_Projectile_Gravity];
			bDouble = YES;
			break;
		case 49:
			dValue = [self Expression_GET_Projectile_GravityDir];
			bDouble = YES;
			break;
		case 50:
			dValue = [self Expression_GET_Projectile_BounceCoef];
			break;
		case 51:
			dValue = [self Expression_GET_Projectile_Count];
			bDouble = YES;
			break;
			
            //*** Presentation movement
		case 52:
			value = [self Expression_GET_PRESENTATION_Index];
			break;
		case 53:
			value = [self Expression_GET_PRESENTATION_LastIndex];
			break;
		case 54:
			value = [self Expression_GET_PRESENTATION_Count];
			break;
			
            //*** General Expressions
		case 55:
			dValue = [self Expression_DistObjects];
			bDouble = YES;
			break;
		case 56:
			dValue = [self Expression_DistPoints];
			bDouble = YES;
			break;
		case 57:
			dValue = [self Expression_AngleObjects];
			bDouble = YES;
			break;
		case 58:
			dValue = [self Expression_AnglePoints];
			bDouble = YES;
			break;
		case 59:
			value = [self Expression_Angle2Dir];
			break;
		case 60:
			dValue = [self Expression_Dir2Angle];
			bDouble = YES;
			break;
			
            // Spaceship movement
		case 61:
			value = [self Expression_SpaceShip_Gravity];
			break;
		case 62:
			value = [self Expression_SpaceShip_GravityDir];
			break;
		case 63:
			value = [self Expression_SpaceShip_Deceleration];
			break;
		case 64:
			value = [self Expression_SpaceShip_RotationSpeed];
			break;
		case 65:
			value = [self Expression_SpaceShip_ThrustPower];
			break;
		case 66:
			value = [self Expression_SpaceShip_Count];
			break;
			
            //*** Drag-drop Object
		case 67:
			value=[self Expression_DragDrop_AreaX];
			break;
		case 68:
			value=[self Expression_DragDrop_AreaY];
			break;
		case 69:
			value=[self Expression_DragDrop_AreaW];
			break;
		case 70:
			value=[self Expression_DragDrop_AreaH];
			break;
		case 71:
			value=[self Expression_DragDrop_GridX];
			break;
		case 72:
			value=[self Expression_DragDrop_GridY];
			break;
		case 73:
			value=[self Expression_DragDrop_GridW];
			break;
		case 74:
			value=[self Expression_DragDrop_GridH];
			break;
			
	}
	
	CValue* ret = [rh getTempValue:0];
	if (bDouble == NO)
	{
		[ret forceInt:value];
	}
	else
	{
		[ret forceDouble:dValue];
	}
	
	return ret;
}


-(CObject*)getCurrentObject:(NSString*)dllName
{
	// No need to search for the object if it's null
	if (currentObject == nil)
	{
		return nil;
	}
	
	// Enumerate objects
	CObject* hoPtr;
	for (hoPtr = [ho getFirstObject]; hoPtr != nil; hoPtr = [ho getNextObject])
	{
		if (hoPtr == currentObject)
		{
			// Check if the object can have movements
			if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
			{
				// Test if the object has a movement and this movement is an extension
				if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
				{
					if (dllName != nil)
					{
						CObjectCommon* ocPtr = hoPtr->hoCommon;
						CMoveDefExtension* mvPtr = (CMoveDefExtension*) ocPtr->ocMovements->moveList[hoPtr->rom->rmMvtNum];
						if ([dllName caseInsensitiveCompare:mvPtr->moduleName] == 0)
						{
							return hoPtr;
						}
						else
						{
							return nil;
						}
					}
					else
					{
						return hoPtr;
					}
				}
				return nil;
			}
		}
	}
	currentObject = nil;
	return nil;
}

-(int)enumerateRuntimeObjects:(NSString*)dllName
{
	int count = 0;
	
	// Enumerate objects
	CObject* hoPtr;
	for (hoPtr = [ho getFirstObject]; hoPtr != nil; hoPtr = [ho getNextObject])
	{
		if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
		{
			// Test if the object has a movement and this movement is an extension
			if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
			{
				CObjectCommon* ocPtr = hoPtr->hoCommon;
				CMoveDefExtension* mvPtr = (CMoveDefExtension*) ocPtr->ocMovements->moveList[hoPtr->rom->rmMvtNum];
				if ([dllName caseInsensitiveCompare:mvPtr->moduleName] == 0)
				{
					count++;
				}
			}
		}
	}
	return count;
}

-(CObject*)findObject:(NSString*)dllName
{
	// Enumerate objects
	CObject* hoPtr;
	for (hoPtr = [ho getFirstObject]; hoPtr != nil; hoPtr = [ho getNextObject])
	{
		if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
		{
			// Test if the object has a movement and this movement is an extension
			if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
			{
				CObjectCommon* ocPtr = hoPtr->hoCommon;
				CMoveDefExtension* mvPtr = (CMoveDefExtension*) ocPtr->ocMovements->moveList[hoPtr->rom->rmMvtNum];
				if ([dllName caseInsensitiveCompare:mvPtr->moduleName] == 0)
				{
					return hoPtr;
				}
			}
		}
	}
	return nil;
}

// ============================================================================
//
// ACTIONS ROUTINES
// 
// ============================================================================

//*** Set Object
-(void)Action_SetObject_Object:(CActExtension*)act
{
	CObject* hoPtr = [act getParamObject:rh withNum:0];
	if ((hoPtr != nil) && (hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
	{
		if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
		{
			currentObject = hoPtr;
		}
	}
}

-(void)Action_SetObject_FixedValue:(CActExtension*)act
{
	int fixed = [act getParamExpression:rh withNum:0];
	CObject* hoPtr = [ho getObjectFromFixed:fixed];
	
	if (hoPtr != nil)
	{
		if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
		{
			if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
			{
				currentObject = hoPtr;
			}
		}
	}
}


//*** Circular movement
-(void)Action_SET_CIRCLE_CENTRE_X:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_CENTRE_X andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_CENTRE_Y:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_CENTRE_Y andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_ANGSPEED:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_ANGSPEED andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_CURRENTANGLE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_CURRENTANGLE andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_RADIUS:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_RADIUS andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_SPIRALVEL:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_SPIRALVEL andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_MINRADIUS:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_MINRADIUS andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_MAXRADIUS:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_CIRCLE_MAXRADIUS andParam:param1];
	}
}

-(void)Action_SET_CIRCLE_ONEND1:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_CIRCLE_ONCOMPLETION andParam:0];
	}
}

-(void)Action_SET_CIRCLE_ONEND2:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_CIRCLE_ONCOMPLETION andParam:1];
	}
}

-(void)Action_SET_CIRCLE_ONEND3:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_CIRCLE_ONCOMPLETION andParam:2];
	}
}

-(void)Action_SET_CIRCLE_ONEND4:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_CIRCULAR];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_CIRCLE_ONCOMPLETION andParam:3];
	}
}

//*** Regular Polygon movement
-(void)Action_SET_REGPOLY_CENTRE_X:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_REGPOLYGON];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_REGPOLY_CENTRE_X andParam:param1];
	}
}

-(void)Action_SET_REGPOLY_CENTRE_Y:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_REGPOLYGON];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_REGPOLY_CENTRE_Y andParam:param1];
	}
}

-(void)Action_SET_REGPOLY_NUMSIDES:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_REGPOLYGON];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_REGPOLY_NUMSIDES andParam:param1];
	}
}

-(void)Action_SET_REGPOLY_RADIUS:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_REGPOLYGON];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_REGPOLY_RADIUS andParam:param1];
	}
}

-(void)Action_SET_REGPOLY_ROTATION_ANGLE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_REGPOLYGON];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_REGPOLY_ROTATION_ANGLE andParam:param1];
	}
}

-(void)Action_SET_REGPOLY_VELOCITY:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_REGPOLYGON];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_REGPOLY_VELOCITY andParam:param1];
	}
}

//*** Sinewave movement
-(void)Action_SET_SINEWAVE_SPEED:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_SPEED andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_STARTX:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_STARTX andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_STARTY:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_STARTY andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_FINALX:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_FINALX andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_FINALY:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_FINALY andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_AMPLITUDE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_AMPLITUDE andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_ANGVEL:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_ANGVEL andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_STARTANG:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_STARTANG andParam:param1];
	}
}

-(void)Action_SET_SINEWAVE_CURRENTANGLE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SINEWAVE_CURRENTANGLE andParam:param1];
	}
}

-(void)Action_RESET_SINEWAVE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		[ho callMovement:object withAction:RESET_SINEWAVE andParam:0];
	}
}

-(void)Action_SET_SINEWAVE_ONEND1:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_SINEWAVE_ONCOMPLETION andParam:0];
	}
}

-(void)Action_SET_SINEWAVE_ONEND2:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_SINEWAVE_ONCOMPLETION andParam:1];
	}
}

-(void)Action_SET_SINEWAVE_ONEND3:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_SINEWAVE_ONCOMPLETION andParam:2];
	}
}

-(void)Action_SET_SINEWAVE_ONEND4:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SINEWAVE];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_SINEWAVE_ONCOMPLETION andParam:3];
	}
}

//*** Simple Ellipse movement
-(void)Action_SET_SIMPLEELLIPSE_CENTRE_X:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_CENTRE_X andParam:param1];
	}
}

-(void)Action_SET_SIMPLEELLIPSE_CENTRE_Y:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_CENTRE_Y andParam:param1];
	}
}

-(void)Action_SET_SIMPLEELLIPSE_RADIUS_X:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_RADIUS_X andParam:param1];
	}
}

-(void)Action_SET_SIMPLEELLIPSE_RADIUS_Y:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_RADIUS_Y andParam:param1];
	}
}

-(void)Action_SET_SIMPLEELLIPSE_ANGVEL:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_ANGSPEED andParam:param1];
	}
}

-(void)Action_SET_SIMPLEELLIPSE_CURRENTANGLE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_CURRENTANGLE andParam:param1];
	}
}

-(void)Action_SET_SIMPLEELLIPSE_OFFSETANGLE:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_SIMPLEELLIPSE_OFFSETANGLE andParam:param1];
	}
}

//*** Invaders movement
-(void)Action_SET_INVADERS_SPEED:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_INVADERS];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_INVADERS_SPEED andParam:param1];
	}
}

-(void)Action_SET_INVADERS_STEPX:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_INVADERS];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_INVADERS_STEPX andParam:param1];
	}
}

-(void)Action_SET_INVADERS_STEPY:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_INVADERS];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_INVADERS_STEPY andParam:param1];
	}
}

-(void)Action_SET_INVADERS_LEFTBORDER:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_INVADERS];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_INVADERS_LEFTBORDER andParam:param1];
	}
}

-(void)Action_SET_INVADERS_RIGHTBORDER:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_INVADERS];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_INVADERS_RIGHTBORDER andParam:param1];
	}
}

//*** Projectile movement
-(void)Action_SET_Projectile_X:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_X andParam:param1];
	}
}

-(void)Action_SET_Projectile_Y:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_Y andParam:param1];
	}
}

-(void)Action_SET_Projectile_XY:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int x = [act getParamExpression:rh withNum:0];
		int y = [act getParamExpression:rh withNum:1];
		[ho callMovement:object withAction:SET_Projectile_X andParam:x];
		[ho callMovement:object withAction:SET_Projectile_Y andParam:y];
	}
}

-(void)Action_SET_Projectile_MoveTowardsAngle:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double angle = [act getParamExpression:rh withNum:0] * ToRadians;
		int distance = [act getParamExpression:rh withNum:1];

		int addDistX = (int) (distance * cosf(angle) + 0.5);
		int addDistY = (int) (distance * sinf(angle) + 0.5);
		
		[ho callMovement:object withAction:SET_Projectile_AddDistX andParam:addDistX];
		[ho callMovement:object withAction:SET_Projectile_AddDistY andParam:addDistY];
	}
}

-(void)Action_SET_Projectile_MoveTowardsPoint:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		
		double fp3 = [act getParamExpDouble:rh withNum:0];
		double fp4 = [act getParamExpDouble:rh withNum:1];
		int distance = [act getParamExpression:rh withNum:2];
		
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		int addDistX = (int) (distance * cosf(angle) + 0.5);
		int addDistY = (int) (distance * sinf(angle) + 0.5);
		
		[ho callMovement:object withAction:SET_Projectile_AddDistX andParam:addDistX];
		[ho callMovement:object withAction:SET_Projectile_AddDistY andParam:addDistY];
	}
}

-(void)Action_SET_Projectile_MoveTowardsObject:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		CObject* p2 = [act getParamObject:rh withNum:0];
		if(p2 == nil)
			return;
		
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		
		double fp3 = (double) p2->hoX;
		double fp4 = (double) p2->hoY;
		int distance = [act getParamExpression:rh withNum:1];
		
		double angle = atan2(fp2 - fp4, fp3 - fp1);

		int addDistX = (int) (distance * cosf(angle) + 0.5);
		int addDistY = (int) (distance * sinf(angle) + 0.5);
		
		[ho callMovement:object withAction:SET_Projectile_AddDistX andParam:addDistX];
		[ho callMovement:object withAction:SET_Projectile_AddDistY andParam:addDistY];
	}
}

-(void)Action_SET_Projectile_Dir:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_Dir andParam:param1];
	}
}

-(void)Action_SET_Projectile_DirToPoint:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		
		double fp3 = [act getParamExpDouble:rh withNum:0];
		double fp4 = [act getParamExpDouble:rh withNum:1];
		
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		if (angle < 0)
		{
			angle += 6.283185;
		}
		angle *= ToDegrees;
		
		[ho callMovement:object withAction:SET_Projectile_Dir andParam:(int) angle];
	}
}

-(void)Action_SET_Projectile_DirToObject:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		CObject* p2 = [act getParamObject:rh withNum:0];
		if(p2 == nil)
			return;
		
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		
		double fp3 = p2->hoX;
		double fp4 = p2->hoY;
		
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		if (angle < 0)
		{
			angle += 6.283185;
		}
		angle *= ToDegrees;
		
		[ho callMovement:object withAction:SET_Projectile_Dir andParam:(int) angle];
	}
}

-(void)Action_SET_Projectile_RotateTowardsAngle:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		int param2 = [act getParamExpression:rh withNum:1];
		double newangleTow = (double) (param1 % 360);	// angle towards
		double newangleAdd = (double) (param2 % 360);	// angle to add
		
		double currentAngle = [ho callMovement:object withAction:GET_Projectile_Dir andParam:0];
		
		double difM = currentAngle - newangleTow;
		if (difM < 0)
		{
			difM += 360;
		}
		
		double difA = 360 - difM;
		
		if (difM <= difA)
		{
			if (difM < newangleAdd)
			{
				currentAngle -= difM;
			}
			else
			{
				currentAngle -= newangleAdd;
			}
		}
		else
		{
			if (difA < newangleAdd)
			{
				currentAngle += difA;
			}
			else
			{
				currentAngle += newangleAdd;
			}
		}
		[ho callMovement:object withAction:SET_Projectile_Dir andParam:(int) currentAngle];
	}
}

-(void)Action_SET_Projectile_RotateTowardsPoint:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		double currentAngle = [ho callMovement:object withAction:GET_Projectile_Dir andParam:0];
		
		double fp3 = [act getParamExpDouble:rh withNum:0];
		double fp4 = [act getParamExpDouble:rh withNum:1];
		
		double newangleAdd = ((int)[act getParamExpDouble:rh withNum:2]) % 360;
		double newangleTow = atan2(fp2 - fp4, fp3 - fp1) * ToDegrees;
		
		if (newangleTow < 0)
		{
			newangleTow += 360;
		}
		
		double difM = currentAngle - newangleTow;
		if (difM < 0)
		{
			difM += 360;
		}
		
		double difA = 360 - difM;
		
		if (difM <= difA)
		{
			if (difM < newangleAdd)
			{
				currentAngle -= difM;
			}
			else
			{
				currentAngle -= newangleAdd;
			}
		}
		else
		{
			if (difA < newangleAdd)
			{
				currentAngle += difA;
			}
			else
			{
				currentAngle += newangleAdd;
			}
		}
		[ho callMovement:object withAction:SET_Projectile_Dir andParam:(int) currentAngle];
	}
}

-(void)Action_SET_Projectile_RotateTowardsObject:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		CObject* p2 = [act getParamObject:rh withNum:0];
		if(p2 == nil)
			return;

		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		double currentAngle = [ho callMovement:object withAction:GET_Projectile_Dir andParam:0];
		double fp3 = p2->hoX;
		double fp4 = p2->hoY;
		double newangleAdd = ((int)[act getParamExpDouble:rh withNum:1]) % 360;
		double newangleTow = atan2(fp2 - fp4, fp3 - fp1) * ToDegrees;
		
		if (newangleTow < 0)
		{
			newangleTow += 360;
		}
		
		double difM = currentAngle - newangleTow;
		if (difM < 0)
		{
			difM += 360;
		}
		
		double difA = 360 - difM;
		
		if (difM <= difA)
		{
			if (difM < newangleAdd)
			{
				currentAngle -= difM;
			}
			else
			{
				currentAngle -= newangleAdd;
			}
		}
		else
		{
			if (difA < newangleAdd)
			{
				currentAngle += difA;
			}
			else
			{
				currentAngle += newangleAdd;
			}
		}
		[ho callMovement:object withAction:SET_Projectile_Dir andParam:(int) currentAngle];
	}
}

-(void)Action_SET_Projectile_Speed:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_Speed andParam:param1];
	}
}

-(void)Action_SET_Projectile_SpeedX:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_SpeedX andParam:param1];
	}
}

-(void)Action_SET_Projectile_SpeedY:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_SpeedY andParam:param1];
	}
}

-(void)Action_SET_Projectile_AddDirSpeedTowardsAngle:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double angle = [act getParamExpression:rh withNum:0] * ToRadians;
		int speed = [act getParamExpression:rh withNum:1];
		
		int addSpeedX = (int) (speed * cosf(angle) + 0.5);
		int addSpeedY = (int) (speed * sinf(angle) + 0.5);
		
		[ho callMovement:object withAction:SET_Projectile_AddSpeedX andParam:addSpeedX];
		[ho callMovement:object withAction:SET_Projectile_AddSpeedY andParam:addSpeedY];
	}
}

-(void)Action_SET_Projectile_AddDirSpeedTowardsPoint:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		double fp3 = [act getParamExpDouble:rh withNum:0];
		double fp4 = [act getParamExpDouble:rh withNum:1];
		int speed = [act getParamExpression:rh withNum:2];
		
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		int addSpeedX = (int) (speed * cosf(angle) + 0.5);
		int addSpeedY = (int) (speed * sinf(angle) + 0.5);
		
		[ho callMovement:object withAction:SET_Projectile_AddSpeedX andParam:addSpeedX];
		[ho callMovement:object withAction:SET_Projectile_AddSpeedY andParam:addSpeedY];
	}
}

-(void)Action_SET_Projectile_AddDirSpeedTowardsObject:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		CObject* p2 = [act getParamObject:rh withNum:0];
		if(p2 == nil)
			return;
		
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		double fp3 = p2->hoX;
		double fp4 = p2->hoY;
		int speed = [act getParamExpression:rh withNum:1];
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		int addSpeedX = (int) (speed * cosf(angle) + 0.5);
		int addSpeedY = (int) (speed * sinf(angle) + 0.5);
		
		[ho callMovement:object withAction:SET_Projectile_AddSpeedX andParam:addSpeedX];
		[ho callMovement:object withAction:SET_Projectile_AddSpeedY andParam:addSpeedY];
	}
}

-(void)Action_SET_Projectile_MinSpeed:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_MinSpeed andParam:param1];
	}
}

-(void)Action_SET_Projectile_MaxSpeed:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_MaxSpeed andParam:param1];
	}
}

-(void)Action_SET_Projectile_Gravity:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_Gravity andParam:param1];
	}
}

-(void)Action_SET_Projectile_GravityDir:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_GravityDir andParam:param1];
	}
}

-(void)Action_SET_Projectile_GravityDirToPoint:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		double fp3 = [act getParamExpDouble:rh withNum:0];
		double fp4 = [act getParamExpDouble:rh withNum:1];
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		if (angle < 0)
		{
			angle += 6.283185;
		}
		angle *= ToDegrees;
		
		[ho callMovement:object withAction:SET_Projectile_GravityDir andParam:(int) angle];
	}
}

-(void)Action_SET_Projectile_GravityDirToObject:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		CObject* p2 = [act getParamObject:rh withNum:0];
		if(p2 == nil)
			return;
		
		double fp1 = [ho callMovement:object withAction:GET_Projectile_X andParam:0];
		double fp2 = [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
		double fp3 = p2->hoX;
		double fp4 = p2->hoY;
		double angle = atan2(fp2 - fp4, fp3 - fp1);
		
		if (angle < 0)
		{
			angle += 6.283185;
		}
		angle *= ToDegrees;
		
		[ho callMovement:object withAction:SET_Projectile_GravityDir andParam:(int) angle];
	}
}

-(void)Action_SET_Projectile_BounceCoeff:(CActExtension*)act
{
	//callRunTimeFunction2(((LPRDATA)param1), RFUNCTION_CALLMOVEMENT, SET_Projectile_Y, param2);
}

-(void)Action_SET_Projectile_ForceBounce:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_VECTOR];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SET_Projectile_ForceBounce andParam:param1];
	}
}

//*** Presentation movement
-(void)Action_SET_PRESENTATION_Next:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_PRESENTATION];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_PRESENTATION_Next andParam:0];
	}
}

-(void)Action_SET_PRESENTATION_Prev:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_PRESENTATION];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_PRESENTATION_Prev andParam:0];
	}
}

-(void)Action_SET_PRESENTATION_ToStart:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_PRESENTATION];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_PRESENTATION_ToStart andParam:0];
	}
}

-(void)Action_SET_PRESENTATION_ToEnd:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_PRESENTATION];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_PRESENTATION_ToEnd andParam:0];
	}
}

// Spaceship movement
-(void)Action_SetPower:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETPOWER andParam:param1];
	}
}

-(void)Action_SetSpeed:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETSPEED andParam:param1];
	}
}

-(void)Action_SetDir:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETDIR andParam:param1];
	}
}

-(void)Action_SetDec:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETDEC andParam:param1];
	}
}

-(void)Action_SetRotSpeed:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETROTSPEED andParam:param1];
	}
}

-(void)Action_SetGravity:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETGRAVITY andParam:param1];
	}
}

-(void)Action_SetGravityDir:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		int param1 = [act getParamExpression:rh withNum:0];
		[ho callMovement:object withAction:SPACE_SETGRAVITYDIR andParam:param1];
	}
}

-(void)Action_ApplyReactor:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SPACE_APPLYREACTOR andParam:0];
	}
}

-(void)Action_ApplyRotateRight:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SPACE_APPLYROTATERIGHT andParam:0];
	}
}

-(void)Action_ApplyRotateLeft:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_SPACESHIP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SPACE_APPLYROTATELEFT andParam:0];
	}
}

//*** Drag-drop movement
-(void)Action_DragDrop_Method1:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_Method andParam:0];
	}
}

-(void)Action_DragDrop_Method2:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_Method andParam:1];
	}
}

-(void)Action_DragDrop_Method3:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_Method andParam:2];
	}
}
-(void)Action_DragDrop_Method4:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_Method andParam:3];
	}
}
-(void)Action_DragDrop_Method5:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_Method andParam:4];
	}
}

-(void)Action_DragDrop_IsLimited:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_IsLimited andParam:1];
	}
}

-(void)Action_DragDrop_IsLimitedOff:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_IsLimited andParam:0];
	}
}

-(void)Action_DragDrop_DropOutsideArea:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_DropOutsideArea andParam:1];
	}
}

-(void)Action_DragDrop_DropOutsideAreaOff:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_DropOutsideArea andParam:0];
	}
}

-(void)Action_DragDrop_ForceWithinLimits:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_ForceWithinLimits andParam:1];
	}
}

-(void)Action_DragDrop_ForceWithinLimitsOff:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_ForceWithinLimits andParam:0];
	}
}

-(void)Action_DragDrop_Area:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	short* area = [act getParamZone:rh withNum:0];
	
	if (object!=nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_AreaX andParam:*area];
		[ho callMovement:object withAction:SET_DragDrop_AreaY andParam:*(area+1)];
		[ho callMovement:object withAction:SET_DragDrop_AreaW andParam:*(area+2)-*area];
		[ho callMovement:object withAction:SET_DragDrop_AreaH andParam:*(area+3)-*(area+1)];
	}
}

-(void)Action_DragDrop_AreaX:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_AreaX andParam:param1];
	}
}

-(void)Action_DragDrop_AreaY:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_AreaY andParam:param1];
	}
}

-(void)Action_DragDrop_AreaW:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_AreaW andParam:param1];
	}
}

-(void)Action_DragDrop_AreaH:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_AreaH andParam:param1];
	}
}

-(void)Action_DragDrop_SnapToGrid:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_SnapToGrid andParam:1];
	}
}

-(void)Action_DragDrop_SnapToGridOff:(CActExtension*)act
{
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_SnapToGrid andParam:0];
	}
}

-(void)Action_DragDrop_GridOrigin:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_GridX andParam:param1&0xFFFF];
		[ho callMovement:object withAction:SET_DragDrop_GridY andParam:param1>>16];
	}
}

-(void)Action_DragDrop_GridX:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_GridX andParam:param1];
	}
}

-(void)Action_DragDrop_GridY:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_GridY andParam:param1];
	}
}

-(void)Action_DragDrop_GridW:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_GridW andParam:param1];
	}
}

-(void)Action_DragDrop_GridH:(CActExtension*)act
{
	int param1=[act getParamExpression:rh withNum:0];
	CObject* object = [self getCurrentObject:DLL_DRAGDROP];
	if (object != nil)
	{
		[ho callMovement:object withAction:SET_DragDrop_GridH andParam:param1];
	}
}



// ============================================================================
//
// EXPRESSIONS ROUTINES
// 
// ============================================================================

//*** Circular movement
-(int)Expression_GET_CIRCLE_CENTRE_X
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_CENTRE_X andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_CENTRE_Y
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_CENTRE_Y andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_ANGSPEED
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_ANGSPEED andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_CURRENTANGLE
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_CURRENTANGLE andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_RADIUS
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_RADIUS andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_SPIRALVEL
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_SPIRALVEL andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_MINRADIUS
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_MINRADIUS andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_MAXRADIUS
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_CIRCULAR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_CIRCLE_MAXRADIUS andParam:0];
	}
	return 0;
}

-(int)Expression_GET_CIRCLE_COUNT
{
	return [self enumerateRuntimeObjects:DLL_CIRCULAR];
}


//*** Regular Polygon movement
-(int)Expression_GET_REGPOLY_CENTRE_X
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_REGPOLYGON];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_REGPOLY_CENTRE_X andParam:0];
	}
	return 0;
}

-(int)Expression_GET_REGPOLY_CENTRE_Y
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_REGPOLYGON];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_REGPOLY_CENTRE_Y andParam:0];
	}
	return 0;
}

-(int)Expression_GET_REGPOLY_NUMSIDES
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_REGPOLYGON];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_REGPOLY_NUMSIDES andParam:0];
	}
	return 0;
}

-(int)Expression_GET_REGPOLY_RADIUS
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_REGPOLYGON];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_REGPOLY_RADIUS andParam:0];
	}
	return 0;
}

-(int)Expression_GET_REGPOLY_ROTATION_ANGLE
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_REGPOLYGON];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_REGPOLY_ROTATION_ANGLE andParam:0];
	}
	return 0;
}

-(int)Expression_GET_REGPOLY_VELOCITY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_REGPOLYGON];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_REGPOLY_VELOCITY andParam:0];
	}
	return 0;
}

-(int)Expression_GET_REGPOLY_COUNT
{
	return [self enumerateRuntimeObjects:DLL_REGPOLYGON];
}


//*** Sinewave movement
-(int)Expression_GET_SINEWAVE_SPEED
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_SPEED andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_STARTX
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_STARTX andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_STARTY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_STARTY andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_FINALX
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_FINALX andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_FINALY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_FINALY andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_AMPLITUDE
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_AMPLITUDE andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_ANGVEL
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_ANGVEL andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_STARTANG
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_STARTANG andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_CURRENTANGLE
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SINEWAVE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SINEWAVE_CURRENTANGLE andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SINEWAVE_COUNT
{
	return [self enumerateRuntimeObjects:DLL_SINEWAVE];
}


//*** Simple Ellipse movement
-(int)Expression_GET_SIMPLEELLIPSE_CENTRE_X
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_CENTRE_X andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_CENTRE_Y
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_CENTRE_Y andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_RADIUS_X
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_RADIUS_X andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_RADIUS_Y
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_RADIUS_Y andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_ANGVEL
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_ANGSPEED andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_CURRENTANGLE
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_CURRENTANGLE andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_OFFSETANGLE
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SIMPLE_ELLIPSE];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_SIMPLEELLIPSE_OFFSETANGLE andParam:0];
	}
	return 0;
}

-(int)Expression_GET_SIMPLEELLIPSE_COUNT
{
	return [self enumerateRuntimeObjects:DLL_SIMPLE_ELLIPSE];
}

//*** Invaders movement
-(int)Expression_GET_INVADERS_SPEED
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_INVADERS];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_INVADERS_SPEED andParam:0];
	}
	return 0;
}

-(int)Expression_GET_INVADERS_STEPX
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_INVADERS];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_INVADERS_STEPX andParam:0];
	}
	return 0;
}

-(int)Expression_GET_INVADERS_STEPY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_INVADERS];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_INVADERS_STEPY andParam:0];
	}
	return 0;
}

-(int)Expression_GET_INVADERS_LEFTBORDER
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_INVADERS];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_INVADERS_LEFTBORDER andParam:0];
	}
	return 0;
}

-(int)Expression_GET_INVADERS_RIGHTBORDER
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_INVADERS];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_INVADERS_RIGHTBORDER andParam:0];
	}
	return 0;
}

-(int)Expression_GET_INVADERS_COUNT
{
	return [self enumerateRuntimeObjects:DLL_INVADERS];
}

//*** Projectile movements
-(double)Expression_GET_Projectile_X
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_X andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_Y
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_Y andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_Dir
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_Dir andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_Speed
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_Speed andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_SpeedX
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_SpeedX andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_SpeedY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_SpeedY andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_MinSpeed
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_MinSpeed andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_MaxSpeed
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_MaxSpeed andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_Gravity
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_Gravity andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_GravityDir
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_GravityDir andParam:0];
	}
	return 0;
}

-(double)Expression_GET_Projectile_BounceCoef
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_VECTOR];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return [ho callMovement:object withAction:GET_Projectile_BounceCoef andParam:0];
	}
	return 0;
}

-(int)Expression_GET_Projectile_Count
{
	return [self enumerateRuntimeObjects:DLL_VECTOR];
}

//*** Presentation movement
-(int)Expression_GET_PRESENTATION_Index
{
	CObject* object = [self findObject:DLL_PRESENTATION];
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_PRESENTATION_Index andParam:0];
	}
	return -1;
}

-(int)Expression_GET_PRESENTATION_LastIndex
{
	CObject* object = [self findObject:DLL_PRESENTATION];
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_PRESENTATION_LastIndex andParam:0];
	}
	return -1;
}

-(int)Expression_GET_PRESENTATION_Count
{
	return [self enumerateRuntimeObjects:DLL_PRESENTATION];
}

//*** Spaceship movement
-(int)Expression_SpaceShip_Gravity
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SPACESHIP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:SPACE_GETGRAVITY andParam:0];
	}
	return -1;
}

-(int)Expression_SpaceShip_GravityDir
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SPACESHIP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:SPACE_GETGRAVITYDIR andParam:0];
	}
	return -1;
}

-(int)Expression_SpaceShip_Deceleration
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SPACESHIP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:SPACE_GETDECELERATION andParam:0];
	}
	return -1;
}

-(int)Expression_SpaceShip_RotationSpeed
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SPACESHIP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:SPACE_GETROTATIONSPEED andParam:0];
	}
	return -1;
}

-(int)Expression_SpaceShip_ThrustPower
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_SPACESHIP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:SPACE_GETTHRUSTPOWER andParam:0];
	}
	return -1;
}

-(int)Expression_SpaceShip_Count
{
	return [self enumerateRuntimeObjects:DLL_SPACESHIP];
}

//*** General Expressions
-(double)Expression_DistObjects
{
	int p1 = [[ho getExpParam] getInt];
	int p2 = [[ho getExpParam] getInt];
	
	CObject* object1;
	CObject* object2;
	if (p1 == 0)
	{
		object1 = [self getCurrentObject:nil];
	}
	else
	{
		object1 = [ho getObjectFromFixed:p1];
	}
	
	if (p2 == 0)
	{
		object2 = [self getCurrentObject:nil];
	}
	else
	{
		object2 = [ho getObjectFromFixed:p2];
	}
	
	if (object1 == nil || object2 == nil)
	{
		return -1;
	}
	
	double fp1 = object1->hoX;
	double fp2 = object1->hoY;
	double fp3 = object2->hoX;
	double fp4 = object2->hoY;
	return sqrt((fp1 - fp3) * (fp1 - fp3) + (fp2 - fp4) * (fp2 - fp4));
}
	
-(double)Expression_DistPoints
{
	double fp1 = [[ho getExpParam] getDouble];
	double fp2 = [[ho getExpParam] getDouble];
	double fp3 = [[ho getExpParam] getDouble];
	double fp4 = [[ho getExpParam] getDouble];
	
	return sqrt((fp1 - fp3) * (fp1 - fp3) + (fp2 - fp4) * (fp2 - fp4));
}
		
-(double)Expression_AngleObjects
{
	int p1 = [[ho getExpParam] getInt];
	int p2 = [[ho getExpParam] getInt];
	
	CObject* object1;
	CObject* object2;
	if (p1 == 0)
	{
		object1 = [self getCurrentObject:nil];
	}
	else
	{
		object1 = [ho getObjectFromFixed:p1];
	}
	
	if (p2 == 0)
	{
		object2 = [self getCurrentObject:nil];
	}
	else
	{
		object2 = [ho getObjectFromFixed:p2];
	}
	
	if (object1 == nil || object2 == nil)
	{
		return -1;
	}
	
	double fp1 = object1->hoX;
	double fp2 = object1->hoY;
	double fp3 = object2->hoX;
	double fp4 = object2->hoY;
	
	double fp5 = atan2(fp2 - fp4, fp3 - fp1);
	
	if (fp5 < 0)
	{
		fp5 += 6.283185;
	}
	fp5 *= ToDegrees;
	return fp5;
}

-(double)Expression_AnglePoints
{
	double fp1 = [[ho getExpParam] getDouble];
	double fp2 = [[ho getExpParam] getDouble];
	double fp3 = [[ho getExpParam] getDouble];
	double fp4 = [[ho getExpParam] getDouble];
	
	double fp5 = atan2(fp2 - fp4, fp3 - fp1);
	
	if (fp5 < 0)
	{
		fp5 += 6.283185;
	}
	fp5 *= ToDegrees;
	return fp5;
}

-(int)Expression_Angle2Dir
{
	int angle = [[ho getExpParam] getInt];
	int dir = ((int)(((angle + 5.625) / 11.25))) % 32;
	return dir;
}

-(double)Expression_Dir2Angle
{
	int p1 = [[ho getExpParam] getInt];
	double dir = ((p1 % 32) * 11.25);
	return dir;
}

//*** Drag-drop movement
-(int)Expression_DragDrop_AreaX
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_AreaX andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_AreaY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_AreaY andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_AreaW
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_AreaW andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_AreaH
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_AreaH andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_GridX
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_GridX andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_GridY
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_GridY andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_GridW
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_GridW andParam:0];
	}
	return 0;
}

-(int)Expression_DragDrop_GridH
{
	int p1 = [[ho getExpParam] getInt];
	CObject* object;
	if (p1 == 0)
	{
		object = [self getCurrentObject:DLL_DRAGDROP];
	}
	else
	{
		object = [ho getObjectFromFixed:p1];
	}
	
	if (object != nil)
	{
		return (int) [ho callMovement:object withAction:GET_DragDrop_GridH andParam:0];
	}
	return 0;
}

		





@end
