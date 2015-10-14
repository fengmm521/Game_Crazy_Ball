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
#import "CRunInAndOutController.h"
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

NSString* DLL_INANDOUT = @"InAndOut";

@implementation CRunInAndOutController

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	return YES;
}



// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
            //*** Set Object
		case ACT_SETOBJECT:
			[self Action_SetObject_Object:act];
			break;
		case ACT_SETOBJECTFIXED:
			[self Action_SetObject_FixedValue:act];
			break;
		case ACT_POSITIONIN:
			[self RACT_POSITIONIN:act];
			break;
		case ACT_POSITIONOUT:
			[self RACT_POSITIONOUT:act];
			break;
		case ACT_MOVEIN:
			[self RACT_MOVEIN:act];
			break;
		case ACT_MOVEOUT:
			[self RACT_MOVEOUT:act];
			break;
	}
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	return nil;
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

// ============================================================================
//
// ACTIONS ROUTINES
//
// ============================================================================

//*** Set Object
-(void)Action_SetObject_Object:(CActExtension*)act
{
	CObject* hoPtr = [act getParamObject:rh  withNum:0];
	if ((hoPtr->hoOEFlags & OEFLAG_MOVEMENTS) != 0)
	{
		if (hoPtr->roc->rcMovementType == MVTYPE_EXT)
		{
			currentObject = hoPtr;
		}
	}
}

-(void)Action_SetObject_FixedValue:(CActExtension*)act
{
	int fixed = [act getParamExpression:rh  withNum:0];
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
-(void)RACT_POSITIONIN:(CActExtension*)act
{
	CObject* object=[self getCurrentObject:DLL_INANDOUT];
	if (object!=nil)
		[ho callMovement:object  withAction:ACTION_POSITIONIN  andParam:0];
}
-(void)RACT_POSITIONOUT:(CActExtension*)act
{
	CObject* object=[self getCurrentObject:DLL_INANDOUT];
	if (object!=nil)
		[ho callMovement:object  withAction:ACTION_POSITIONOUT  andParam:0];
}
-(void)RACT_MOVEIN:(CActExtension*)act
{
	CObject* object=[self getCurrentObject:DLL_INANDOUT];
	if (object!=nil)
		[ho callMovement:object  withAction:ACTION_MOVEIN  andParam:0];
}
-(void)RACT_MOVEOUT:(CActExtension*)act
{
	CObject* object=[self getCurrentObject:DLL_INANDOUT];
	if (object!=nil)
		[ho callMovement:object  withAction:ACTION_MOVEOUT  andParam:0];
}

@end
