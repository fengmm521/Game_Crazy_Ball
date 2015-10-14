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

#import "CRunDeadReckoning.h"
#import "CExtension.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CCreateObjectInfo.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CValue.h"
#import "CArrayList.h"
#import "ObjectSelection.h"
#import "CEventProgram.h"
#import "CServices.h"
#import "CRCom.h"
#import "CoreMath.h"

@implementation CRunDeadReckoning
	
#define CON_OBJECTISINOBSTACLE					0
#define CON_LAST								1

#define ACT_ADD_OBJECT							0
#define ACT_REMOVE_OBJECT						1
#define ACT_UPDATE_POSITION						2
#define ACT_UPDATE_X							3
#define ACT_UPDATE_Y							4
#define ACT_UPDATE_DIR							5
#define ACT_UPDATE_ANGLE						6
#define ACT_SET_X								7
#define ACT_SET_Y								8
#define ACT_SET_DIR								9
#define ACT_SET_ANGLE							10
#define ACT_SET_XSPEED							11
#define ACT_SET_YSPEED							12
#define ACT_SETDIRSPEED							13
#define ACT_SET_ANGLE_SPEED						14
#define ACT_OBJ_WAS_STOPPED						15
#define ACT_OBJ_BOUNCED							16
#define ACT_SET_OBJ_EXTRAPOLATION_MODE			17
#define ACT_SET_OBJ_ACCELERATION_MODE			18
#define ACT_SET_OBJ_SMOOTHING					19
#define ACT_SET_OBJ_X_EXTRAPOLATION_MODE		20
#define ACT_SET_OBJ_X_ACCELERATION_MODE			21
#define ACT_SET_OBJ_X_SMOOTHING					22
#define ACT_SET_OBJ_Y_EXTRAPOLATION_MODE		23
#define ACT_SET_OBJ_Y_ACCELERATION_MODE			24
#define ACT_SET_OBJ_Y_SMOOTHING					25
#define ACT_SET_OBJ_DIR_EXTRAPOLATION_MODE		26
#define ACT_SET_OBJ_DIR_ACCELERATION_MODE		27
#define ACT_SET_OBJ_DIR_SMOOTHING				28
#define ACT_SET_OBJ_ANGLE_EXTRAPOLATION_MODE	29
#define ACT_SET_OBJ_ANGLE_ACCELERATION_MODE		30
#define ACT_SET_OBJ_ANGLE_SMOOTHING				31
#define ACT_PUSH_OBJ_OUT_OF_OBSTACLE			32
#define ACT_OBJECT_IS_INSIDE_OBSTACLE			33

#define EXP_NUM_OBJECTS							0
#define EXP_PREDICTED_X							1
#define EXP_PREDICTED_Y							2
#define EXP_PREDICTED_DIR						3
#define EXP_PREDICTED_ANGLE						4
#define EXP_X_SPEED								5
#define EXP_Y_SPEED								6
#define EXP_DIR_SPEED							7
#define EXP_ANGLE_SPEED							8
#define EXP_X_SMOOTHING							9
#define EXP_Y_SMOOTHING							10
#define EXP_DIR_SMOOTHING						11
#define EXP_ANGLE_SMOOTHING						12
#define EXP_MOVESPEED							13
#define EXP_MOVED_DIRECTION						14
#define EXP_MOVED_ANGLE							15

-(int)getNumberOfConditions
{
	return CON_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	objects = [[NSMutableDictionary alloc] init];
	extrapolationMethod = [file readAInt];
	useAcceleration = ([file readAByte] != 0);
	[file skipBytes:3];
	XSmoothing = [file readAFloat];
	YSmoothing = [file readAFloat];
	DirSmoothing = [file readAFloat];
	AngleSmoothing = [file readAFloat];
	isInObstacle = NO;
	objectToPush = nil;
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[objects release];
}

-(int)wrapInt:(int)value intoRange:(int)range
{
	value = value % range;
	if(value < 0)
		value += range;
	return value;
}

-(float)wrapFloat:(float)value intoRange:(float)range
{
	value = fmodf(value, range);
	if(value < 0)
		value += range;
	return value;
}

-(int)handleRunObject
{
	//Loop through all elements to ensure it isn't added twice.
	NSEnumerator* enumerator = [objects objectEnumerator];
	id value;
	while ((value = [enumerator nextObject]))
	{
		DRObj* obj = (DRObj*)value;
		CObject* object = [ho getObjectFromFixed:obj->fixedValue];

		if(object != nil)
		{
			[obj->xPosition doStep];
			[obj->yPosition doStep];
			[obj->direction doStep];
			[obj->angle doStep];
			
			object->roc->rcCheckCollides = 1;
			obj->oldX = object->hoX;
			obj->oldY = object->hoY;
			
			int x = (int)(obj->xPosition->currentPos + 0.5f);
			int y = (int)(obj->yPosition->currentPos + 0.5f);
			
			[object setPosition:x withY:y];
			object->roc->rcDir = [self wrapInt:(int)obj->direction->currentPos intoRange:32];
			object->roc->rcAngle = [self wrapFloat:obj->angle->currentPos intoRange:360.0f];
			object->roc->rcChanged = YES;
		}
		else
		{
			[objects removeObjectForKey:value];
			continue;
		}
	}
	time++;
	return 0;
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
	if(objectToPush == nil)
		return false;
	
	[rh->objectSelection selectOneObject:objectToPush];
	return YES;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_ADD_OBJECT:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			int fixedValue = [object fixedValue];
			
			//Ensure it isn't added twice.
			if([objects objectForKey:[NSNumber numberWithInt:fixedValue]] != nil)
				break;
			
			DRObj* newObj = [[DRObj alloc] init];
			newObj->fixedValue = fixedValue;
			
			newObj->xPosition->lastUpdate = time;
			newObj->yPosition->lastUpdate = time;
			newObj->direction->lastUpdate = time;
			newObj->angle->lastUpdate = time;
			
			[newObj->xPosition setValue:(float)object->hoX];
			[newObj->yPosition setValue:(float)object->hoY];
			[newObj->direction setValue:(float)object->roc->rcDir];
			[newObj->angle setValue:(float)object->roc->rcAngle];
			
			newObj->xPosition->extrapolationMode = extrapolationMethod;
			newObj->yPosition->extrapolationMode = extrapolationMethod;
			newObj->direction->extrapolationMode = extrapolationMethod;
			newObj->angle->extrapolationMode = extrapolationMethod;
			
			newObj->xPosition->useAcceleration = useAcceleration;
			newObj->yPosition->useAcceleration = useAcceleration;
			newObj->direction->useAcceleration = useAcceleration;
			newObj->angle->useAcceleration = useAcceleration;
			
			newObj->xPosition->smoothing = XSmoothing;
			newObj->yPosition->smoothing = YSmoothing;
			newObj->direction->smoothing = DirSmoothing;
			newObj->angle->smoothing = AngleSmoothing;
			
			newObj->xPosition->wrapMode = WRAP_LINEAR;
			newObj->yPosition->wrapMode = WRAP_LINEAR;
			
			newObj->direction->wrapMode = WRAP_CIRCULAR;
			newObj->angle->wrapMode = WRAP_CIRCULAR;
			
			newObj->direction->wrapValue = 32.0f;
			newObj->angle->wrapValue = 360.0f;
			
			[objects setObject:newObj forKey:[NSNumber numberWithInt:fixedValue]];
			[newObj release];
			break;
		}
		case ACT_REMOVE_OBJECT:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			NSNumber* fixedNumber = [NSNumber numberWithInt:[object fixedValue]];
			if([objects objectForKey:fixedNumber] != nil)
				[objects removeObjectForKey:fixedNumber];
			break;
		}
		case ACT_UPDATE_POSITION:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float x = (float)[act getParamExpDouble:rh withNum:1];
			float y = (float)[act getParamExpDouble:rh withNum:2];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				[obj->xPosition updateValue:x atTime:time];
				[obj->yPosition updateValue:y atTime:time];
			}
			break;
		}
		case ACT_UPDATE_X:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float x = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->xPosition updateValue:x atTime:time];
			break;
		}
		case ACT_UPDATE_Y:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float y = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->yPosition updateValue:y atTime:time];
			break;
		}
		case ACT_UPDATE_DIR:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float dir = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->direction updateValue:dir atTime:time];
			break;
		}
		case ACT_UPDATE_ANGLE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float angle = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->angle updateValue:angle atTime:time];
			break;
		}
		case ACT_SET_X:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float x = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->xPosition setValue:x];
			break;
		}
		case ACT_SET_Y:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float y = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->yPosition setValue:y];
			break;
		}
		case ACT_SET_DIR:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float dir = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->direction setValue:dir];
			break;
		}
		case ACT_SET_ANGLE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float angle = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->angle setValue:angle];
			break;
		}
		case ACT_SET_XSPEED:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float x = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->xPosition setSpeed:x];
			break;
		}
		case ACT_SET_YSPEED:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float y = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->yPosition setSpeed:y];
			break;
		}
		case ACT_SETDIRSPEED:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float dir = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->direction setSpeed:dir];
			break;
		}
		case ACT_SET_ANGLE_SPEED:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float angle = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				[obj->angle setSpeed:angle];
			break;
		}
		case ACT_OBJ_WAS_STOPPED:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				[obj->xPosition setValue:(float)object->hoX];
				[obj->yPosition setValue:(float)object->hoY];
			}
			break;
		}
		case ACT_OBJ_BOUNCED:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				[obj->xPosition setValue:(float)object->hoX];
				[obj->yPosition setValue:(float)object->hoY];
				[obj->direction setValue:(float)object->roc->rcDir];
			}
			break;
		}
		case ACT_SET_OBJ_EXTRAPOLATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				int mode  = clamp([act getParamExpression:rh withNum:1], 0, 1);
				obj->xPosition->extrapolationMode = mode;
				obj->yPosition->extrapolationMode = mode;
				obj->direction->extrapolationMode = mode;
				obj->angle->extrapolationMode = mode;
			}
			break;
		}
		case ACT_SET_OBJ_ACCELERATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				BOOL mode = [act getParamExpression:rh withNum:1] == 1;
				obj->xPosition->useAcceleration = mode;
				obj->yPosition->useAcceleration = mode;
				obj->direction->useAcceleration = mode;
				obj->angle->useAcceleration = mode;
			}
			break;
		}
		case ACT_SET_OBJ_SMOOTHING:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float smoothing = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				obj->xPosition->smoothing = smoothing;
				obj->yPosition->smoothing = smoothing;
				obj->direction->smoothing = smoothing;
				obj->angle->smoothing = smoothing;
			}
			break;
		}
		case ACT_SET_OBJ_X_EXTRAPOLATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				int mode = clamp([act getParamExpression:rh withNum:1], 0, 1);
				obj->xPosition->extrapolationMode = mode;
			}
			break;
		}
		case ACT_SET_OBJ_X_ACCELERATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				BOOL mode = [act getParamExpression:rh withNum:1] == 1;
				obj->xPosition->useAcceleration = mode;
			}
			break;
		}
		case ACT_SET_OBJ_X_SMOOTHING:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float smoothing = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				obj->xPosition->smoothing = smoothing;
			break;
		}
		case ACT_SET_OBJ_Y_EXTRAPOLATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				int mode = clamp([act getParamExpression:rh withNum:1], 0, 1);
				obj->yPosition->extrapolationMode = mode;

			}
			break;
		}
		case ACT_SET_OBJ_Y_ACCELERATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				BOOL mode = [act getParamExpression:rh withNum:1] == 1;
				obj->yPosition->useAcceleration = mode;
			}
			break;
		}
		case ACT_SET_OBJ_Y_SMOOTHING:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float smoothing = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				obj->yPosition->smoothing = smoothing;
			break;
		}
		case ACT_SET_OBJ_DIR_EXTRAPOLATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				int mode = clamp([act getParamExpression:rh withNum:1], 0, 1);
				obj->direction->extrapolationMode = mode;
			}
			break;
		}
		case ACT_SET_OBJ_DIR_ACCELERATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				BOOL mode = [act getParamExpression:rh withNum:1] == 1;
				obj->direction->useAcceleration = mode;
			}
			break;
		}
		case ACT_SET_OBJ_DIR_SMOOTHING:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float smoothing = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				obj->direction->smoothing = smoothing;
			break;
		}
		case ACT_SET_OBJ_ANGLE_EXTRAPOLATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				int mode = clamp([act getParamExpression:rh withNum:1], 0, 1);
				obj->angle->extrapolationMode = mode;
			}
			break;
		}
		case ACT_SET_OBJ_ANGLE_ACCELERATION_MODE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
			{
				BOOL mode = [act getParamExpression:rh withNum:1] == 1;
				obj->angle->useAcceleration = mode;
			}
			break;
		}
		case ACT_SET_OBJ_ANGLE_SMOOTHING:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			float smoothing = (float)[act getParamExpDouble:rh withNum:1];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj != nil)
				obj->angle->smoothing = smoothing;
			break;
		}
		case ACT_PUSH_OBJ_OUT_OF_OBSTACLE:
		{
			CObject* object = [act getParamObject:rh withNum:0];
			if(object == nil)
				return;
			DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
			if(obj == nil)
				break;
				
			objectToPush = object;
			
			int x = object->hoX;
			int y = object->hoY;
			int oX = obj->oldX;
			int oY = obj->oldY;
			int dX = x - oX;
			int dY = y - oY;
			
			//No previous position recorded, cannot reliably push out
			if(dX == 0 && dY == 0)
				break;
			
			int distance = (int)ceil(sqrt((float)(dX*dX+dY*dY)));
			
			int lowerbound = 0;
			int upperbound = distance;
			int current = distance/2;
			float progress = 0.5f;
			object->roc->rcChanged = true;
			
			//Push out, maximum 20 iterations
			for(int i=0; i<20; ++i)
			{
				int nX = (int)(oX+dX*progress);
				int nY = (int)(oY+dY*progress);
				
				//If it's done pusing out
				if(object->hoX == nX && object->hoY == nY)
					break;
				
				object->hoX = nX;
				object->hoY = nY;
				object->roc->rcCheckCollides = 1;
				
				isInObstacle = false;
				[ho generateEvent:CON_OBJECTISINOBSTACLE withParam:0];
			
				if(isInObstacle)
					upperbound = current;
				else
					lowerbound = current;
				
				current = (upperbound+lowerbound)/2;
				progress = current/(float)distance;
			}
			
			[obj->xPosition setValue:(float)object->hoX];
			[obj->yPosition setValue:(float)object->hoY];
			
			objectToPush = nil;
			break;
		}
		case ACT_OBJECT_IS_INSIDE_OBSTACLE:
		{
			isInObstacle = true;
			break;
		}
	}
}


-(CValue*)expression:(int)num
{
	switch(num)
	{
		case EXP_NUM_OBJECTS:
			return [rh getTempValue:(int)[objects count]];
			break;
		case EXP_PREDICTED_X:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->xPosition->nextPos];
			}
			break;
		}
		case EXP_PREDICTED_Y:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->yPosition->nextPos];
			}
			break;
		}
		case EXP_PREDICTED_DIR:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->direction->nextPos];
			}
			break;
		}
		case EXP_PREDICTED_ANGLE:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->angle->nextPos];
			}
			break;
		}
		case EXP_X_SPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->xPosition->oldSpeed];
			}
			break;
		}
		case EXP_Y_SPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->yPosition->oldSpeed];
			}
			break;
		}
		case EXP_DIR_SPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->direction->oldSpeed];
			}
			break;
		}
		case EXP_ANGLE_SPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->angle->oldSpeed];
			}
			break;
		}
		case EXP_X_SMOOTHING:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->xPosition->smoothing];
			}
			break;
		}
		case EXP_Y_SMOOTHING:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->yPosition->smoothing];
			}
			break;
		}
		case EXP_DIR_SMOOTHING:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->direction->smoothing];
			}
			break;
		}
		case EXP_ANGLE_SMOOTHING:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
					return [rh getTempDouble:obj->angle->smoothing];
			}
			break;
		}
		case EXP_MOVESPEED:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
				{
					float speed = sqrt(obj->xPosition->oldSpeed*obj->xPosition->oldSpeed + obj->yPosition->oldSpeed*obj->yPosition->oldSpeed);
					return [rh getTempDouble:speed];
				}
			}
			break;
		}
		case EXP_MOVED_DIRECTION:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
				{
					if(obj->xPosition->oldSpeed < 0.001f && obj->yPosition->oldSpeed < 0.001f)
						return [rh getTempValue:(int)(obj->previousAngle/11.25f)];
					
					obj->previousAngle = 360.0f - radiansToDegrees(atan2(obj->yPosition->oldSpeed, obj->xPosition->oldSpeed));
					return [rh getTempValue:(int)(obj->previousAngle/11.25f)];
				}
			}
			break;
		}
		case EXP_MOVED_ANGLE:
		{
			int fixed = [[ho getExpParam] getInt];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object != nil)
			{
				DRObj* obj = [objects objectForKey:[NSNumber numberWithInt:[object fixedValue]]];
				if(obj != nil)
				{
					if(obj->xPosition->oldSpeed < 0.001f && obj->yPosition->oldSpeed < 0.001f)
						return [rh getTempDouble:obj->previousAngle];
					
					obj->previousAngle = 360.0f - radiansToDegrees(atan2(obj->yPosition->oldSpeed, obj->xPosition->oldSpeed));
					return [rh getTempDouble:obj->previousAngle];
				}
			}
			break;
		}
	}
	return [rh getTempValue:0];
}
@end


@implementation DRValue

-(void)reset
{
	currentPos = stepPos = posAtUpdate = prevPos = oldPos = oldSpeed = nextPos = averageUpdateInterval = 0;
	lastUpdate = currentStep = timeDeltaIndex = numDeltas = 0;
	smoothing = speedOverride = 0;
	extrapolationMode = 0;
	doSpeedOverride = false;
	useAcceleration = false;
	wrapMode = WRAP_LINEAR;
	wrapValue = 0;
	for(int i=0; i<AVERAGEWINDOW; i++)
		timeDeltas[i]=0;
}

-(void)updateValue:(float)newValue atTime:(int)time
{
	float speed;
	int timeDelta = time - lastUpdate;
	if(timeDelta == 0)
		return;
	
	//If the value is circular, map it down into a linear value
	if(wrapMode == WRAP_CIRCULAR)
	{
		diffAtUpdate = [self circularDifference:newValue angleB:oldPos wrap:wrapValue];
		newValue = oldPos + diffAtUpdate;
	}
	else
		diffAtUpdate = newValue-oldPos;
	
	[self updateAverageInterval:timeDelta];
	
	if(!doSpeedOverride)
		speed = diffAtUpdate/timeDelta;
	else
	{
		speed = oldSpeed = speedOverride;
		doSpeedOverride = false;
	}
	
	//If the object changes direction
	if((speed>0 && oldSpeed<0) || (speed<0 && oldSpeed>0))
		oldSpeed = 0;
	
	if(useAcceleration)
	{
		float acceleration = speed - oldSpeed;
		
		float increaseFactor = 1.0f;
		//The increasefactor can kinda be seen as the acceleration of the acceleration.
		if(oldSpeed != 0)
			increaseFactor = clamp(speed/oldSpeed, 0.0f, 1.0f);
		else
			increaseFactor = 0;
		
		//Predict the next position
		nextPos = newValue + (speed + acceleration*increaseFactor) * averageUpdateInterval;
	}
	else
		nextPos = newValue + speed * averageUpdateInterval;
	
	//Store values for next update
	currentStep = 0;
	
	prevPos = oldPos;
	oldPos = newValue;
	
	lastUpdate = time;
	oldSpeed = speed;
	posAtUpdate = currentPos;
	timeDeltaIndex = (timeDeltaIndex+1) % AVERAGEWINDOW;
}

-(void)setValue:(float)value
{
	currentPos = prevPos = posAtUpdate = stepPos = nextPos = oldPos = value;
}

-(void)setSpeed:(float)speed
{
	//Recalculate movement
	doSpeedOverride = true;
	speedOverride = speed;
	oldPos = currentPos;
	nextPos = currentPos + speed * averageUpdateInterval;
}

-(void)doStep
{
	int timespan = (int)averageUpdateInterval;
	if(currentStep >= timespan)
		return;
	
	currentStep++;
	
	float mu = 1.0f/averageUpdateInterval * currentStep;
	float secondGuess = nextPos + (nextPos-oldPos);
	
	switch(extrapolationMode)
	{
		case INTERPOLATION_CUBIC:
			stepPos = [self cubicInterpolation:prevPos y1:posAtUpdate y2:nextPos y3:secondGuess mu:mu];
			break;
		case INTERPOLATION_LINEAR:
			stepPos = posAtUpdate+(nextPos-posAtUpdate)*mu;
			break;
	}
	
	//Movement smoothing
	if(smoothing > 1)
		currentPos = currentPos + (stepPos-currentPos)/smoothing;
	else
		currentPos = stepPos;
}

-(float)cubicInterpolation:(float)y0 y1:(float)y1 y2:(float)y2 y3:(float)y3 mu:(float)mu
{
	float a0,a1,a2,a3,mu2;
	mu2 = mu*mu;
	a0 = y3 - y2 - y0 + y1;
	a1 = y0 - y1 - a0;
	a2 = y2 - y0;
	a3 = y1;
	return a0*mu*mu2+a1*mu2+a2*mu+a3;
}

-(void)updateAverageInterval:(size_t)timeDelta
{
	timeDeltas[timeDeltaIndex] = timeDelta;
	if(numDeltas < AVERAGEWINDOW)
		numDeltas++;
	
	averageUpdateInterval = 0;
	int maxLoop = MIN(AVERAGEWINDOW, numDeltas);
	for(int i=0; i<maxLoop; i++)
		averageUpdateInterval += timeDeltas[i];
	averageUpdateInterval /= maxLoop;
}

-(float)circularDifference:(float)angleA angleB:(float)angleB wrap:(float)wrap
{
	float ret = fmod(angleA - angleB, wrap);
	float halfWrap = wrap / 2.0f;
	
	if(ret >= halfWrap)
		return ret-wrap;
	else if(ret < -halfWrap)
		return ret+wrap;
	else
		return ret;
}

@end

@implementation DRObj

-(id)init
{
	if((self = [super init]))
	{
		xPosition = [[DRValue alloc] init];
		yPosition = [[DRValue alloc] init];
		direction = [[DRValue alloc] init];
		angle = [[DRValue alloc] init];
		[self reset];
	}
	return self;
}
-(void)dealloc
{
	[xPosition release];
	[yPosition release];
	[direction release];
	[angle release];
	[super dealloc];
}
-(void)reset
{
	[xPosition reset];
	[yPosition reset];
	[direction reset];
	[angle reset];
}

@end
