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
//
//  CRunMoveIt.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 3/10/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "CRunMoveIt.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CObject.h"
#import "CRun.h"
#import "CArrayList.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"
#import "CRCom.h"
#import "CoreMath.h"

#define CND_ONFINNISHEDMOVING 0

#define ACT_MOVEWITHSPEED 0
#define ACT_MOVEWITHTIME 1
#define ACT_STOPMOVEMENTFIXED 2
#define ACT_STOPMOVEMENTINDEX 3
#define ACT_STOPMOVEMENTSELECTOR 4
#define ACT_ADDOBJECTS 5
#define ACT_CLEARQUEUE 6
#define ACT_STOPALL 7
#define ACT_FORCEMOVE 8

#define EXP_GETNUMMOVING 0
#define EXP_GETFIXED_INDEXVALUE 1
#define EXP_GETFIXED_TOTALDISTANCE 2
#define EXP_GETFIXED_REMAINING 3
#define EXP_GETFIXED_ANGLE 4
#define EXP_GETFIXED_DIRECTION 5
#define EXP_GETINDEX_FIXEDVALUE 6
#define EXP_GETINDEX_TOTALDISTANCE 7
#define EXP_GETINDEX_REMAINING 8
#define EXP_GETINDEX_ANGLE 9
#define EXP_GETINDEX_DIRECTION 10
#define EXP_GETONSTOPPEDFIXED 11

@implementation CRunMoveIt

-(int) getNumberOfConditions
{
	return 1;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	movingObjects = [[CArrayList alloc] init];
	queue = [[CArrayList alloc] init];
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[movingObjects clearRelease];
	[queue clear];
	[movingObjects release];
	[queue release];
}

-(int)handleRunObject
{
	[self act_doMoveStep];
	return 0;
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	return (num == CND_ONFINNISHEDMOVING);
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_MOVEWITHSPEED:
			[self act_moveObjectsWithSpeed:[act getParamExpression:rh withNum:0] andY:[act getParamExpression:rh withNum:1] andSpeed:[act getParamExpression:rh withNum:2]];
			break;
		case ACT_MOVEWITHTIME:
			[self act_moveObjectsWithTime:[act getParamExpression:rh withNum:0] andY:[act getParamExpression:rh withNum:1] andTime:[act getParamExpression:rh withNum:2]];
			break;
		case ACT_STOPMOVEMENTFIXED:
			[self act_stopByFixedValue:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_STOPMOVEMENTINDEX:
			[self act_stopByIndex:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_STOPMOVEMENTSELECTOR:
			[self act_stopByObjectSelector:[act getParamObject:rh withNum:0]];
			break;
		case ACT_ADDOBJECTS:
			[self act_addObjectToQueue:[act getParamObject:rh withNum:0]];
			break;
		case ACT_CLEARQUEUE:
			[self act_clearQueue];
			break;
		case ACT_STOPALL:
			[self act_stopAll];
			break;
		case ACT_FORCEMOVE:
			[self act_doMoveStep];
			break;
	}
}

-(CValue*)expression:(int)num
{
	switch(num)
	{
		case EXP_GETNUMMOVING:
			return [self exp_getNumberOfObjectsMoving];
		case EXP_GETFIXED_INDEXVALUE:
			return [self exp_fromFixedGetIndex];
		case EXP_GETFIXED_TOTALDISTANCE:
			return [self exp_fromFixedGetTotalDistance];
		case EXP_GETFIXED_REMAINING:
			return [self exp_fromFixedGetRemainingDistance];
		case EXP_GETFIXED_ANGLE:
			return [self exp_fromFixedGetAngle];
		case EXP_GETFIXED_DIRECTION:
			return [self exp_fromFixedGetDirection];
		case EXP_GETINDEX_FIXEDVALUE:
			return [self exp_fromIndexGetFixed];
		case EXP_GETINDEX_TOTALDISTANCE:
			return [self exp_fromIndexGetTotalDistance];
		case EXP_GETINDEX_REMAINING:
			return [self exp_fromIndexGetRemainingDistance];
		case EXP_GETINDEX_ANGLE:
			return [self exp_fromIndexGetAngle];
		case EXP_GETINDEX_DIRECTION:
			return [self exp_fromIndexGetDirection];
		case EXP_GETONSTOPPEDFIXED:
			return [self exp_onObjectFinnishedGetFixed];
	}
	return [rh getTempValue:0];
}

-(void)moveObject:(CObject*)object andX:(int)x andY:(int)y andCycles:(int)cycles
{
	//First check if the object added allready exist in MoveIt
	BOOL foundObject = NO;
	
	for(int i=0; i<[movingObjects size]; ++i)
	{
		MoveItItem* item = (MoveItItem*)[movingObjects get:i];
		if(object == item->mobject)
		{
			//If the object allready exists, then update the data
			foundObject = YES;
			[item moveToDstX:x andDstY:y andCycles:cycles];
		}
	}
		
	//If the object wasn't in the MoveIt object, then add it.
	if(!foundObject)
	{
		MoveItItem* item = [[MoveItItem alloc] initWithObject:object andDstX:x andDstY:y andCycles:MAX(cycles, 1)];
		[movingObjects add:(void*)item];
	}
}

-(void)act_moveObjectsWithSpeed:(int)x andY:(int)y andSpeed:(double)speed
{
	speed = speed / 10.0;
	if(speed <= 0)
		return;
	
	for(int i=0; i<[queue size]; ++i)
	{
		CObject* object = (CObject*)[queue get:i];
		double distance = sqrt(pow((double)(object->hoX-x),2.0)+pow((double)(object->hoY-y),2.0));
		int cycles = (int)(distance/speed);
		[self moveObject:object andX:x andY:y andCycles:cycles];
	}
	[queue clear];
}

-(void)act_moveObjectsWithTime:(int)x andY:(int)y andTime:(int)time
{
	for(int i=0; i<[queue size]; ++i)
	{
		CObject* object = (CObject*)[queue get:i];
		[self moveObject:object andX:x andY:y andCycles:time];
	}
	[queue clear];
}

-(void)act_stopByFixedValue:(int)fixed
{
	for(int i=0; i<[movingObjects size]; ++i)
	{
		MoveItItem* item = (MoveItItem*)[movingObjects get:i];
		CObject* obj = item->mobject;
		int objFixed = [obj fixedValue];
		if(fixed == objFixed)
		{
			[movingObjects removeIndexRelease:i];
			--i;
			break;
		}
	}
}

-(void)act_stopByIndex:(int)index
{
	if(index < 0 || index >= [movingObjects size])
		return;

	[movingObjects removeIndexRelease:index];
}

-(void)act_stopByObjectSelector:(CObject*)object
{
	if(object != nil)
		[movingObjects removeObject:(void*)object];
}

-(void)act_addObjectToQueue:(CObject*)object
{
	if(object != nil)
		[queue add:(void*)object];
}

-(void)act_clearQueue
{
	[queue clearRelease];
}

-(void)act_stopAll
{
	[movingObjects clearRelease];
}

-(void)act_doMoveStep
{
	for(int i=0; i<[movingObjects size]; ++i)
	{
		MoveItItem* item = (MoveItItem*)[movingObjects get:i];
		
		CObject* obj = item->mobject;
		if ( (obj->hoFlags & HOF_DESTROYED) != 0 )
		{
			[movingObjects removeIndexRelease:i];
			--i;
			continue;
		}
		
		int startX = item->sourceX;
		int startY = item->sourceY;
		int destX = item->destX;
		int destY = item->destY;
		item->step = item->step+1;
		int step = item->step;
		int cycles = item->cycles;
		
		obj->hoX = ((destX-startX)*step)/cycles + startX;
		obj->hoY = ((destY-startY)*step)/cycles + startY;
		obj->roc->rcChanged = YES;
		
		if(step >= cycles)
		{
			triggeredObject = obj;
			[movingObjects removeIndexRelease:i];
			--i;
			[ho generateEvent:CND_ONFINNISHEDMOVING withParam:0];
		}
	}
}


-(CValue*)exp_getNumberOfObjectsMoving
{
	return [rh getTempValue:(int)[movingObjects size]];
}

-(CValue*)exp_fromFixedGetIndex;
{
	return [rh getTempValue:0];
}

-(CValue*)exp_fromFixedGetTotalDistance;
{
	int fixed = [[ho getExpParam] getInt];
	MoveItItem* item = [self getItemFromFixed:fixed];
	
	if(item == nil)
		return [rh getTempValue:-1];
	
	int distance = sqrt(pow((item->sourceX - item->destX),2.0)+pow((item->sourceY - item->destY),2.0));
	return [rh getTempValue:distance];
}

-(CValue*)exp_fromFixedGetRemainingDistance;
{
	int fixed = [[ho getExpParam] getInt];
	MoveItItem* item = [self getItemFromFixed:fixed];
	
	if(item == nil)
		return [rh getTempValue:-1];
	
	CObject* object = item->mobject;
	int distance = sqrt(pow((object->hoX - item->destX),2.0)+pow((object->hoY - item->destY),2.0));
	return [rh getTempValue:distance];
}

-(CValue*)exp_fromFixedGetAngle;
{
	int fixed = [[ho getExpParam] getInt];
	MoveItItem* item = [self getItemFromFixed:fixed];

	if(item == nil)
		return [rh getTempValue:-1];
	
	int angle = atan2((item->destX-item->sourceX),(item->destY-item->sourceY))* 180/_PI +270;
	return [rh getTempValue:angle];
}

-(CValue*)exp_fromFixedGetDirection;
{
	int fixed = [[ho getExpParam] getInt];
	MoveItItem* item = [self getItemFromFixed:fixed];
	
	if(item == nil)
		return [rh getTempValue:-1];
	
	int dir = atan2((item->destX-item->sourceX),(item->destY-item->sourceY))* 16/_PI +24;
	return [rh getTempValue:dir];
}

-(CValue*)exp_fromIndexGetFixed;
{
	int index = [[ho getExpParam] getInt];
	if(index < 0 || index >= [movingObjects size])
		return [rh getTempValue:-1];
	
	MoveItItem* item = (MoveItItem*)[movingObjects get:index];
	return [rh getTempValue:[item->mobject fixedValue]];
}

-(CValue*)exp_fromIndexGetTotalDistance;
{
	int index = [[ho getExpParam] getInt];
	if(index < 0 || index >= [movingObjects size])
		return [rh getTempValue:-1];
	
	MoveItItem* item = (MoveItItem*)[movingObjects get:index];
	int distance = sqrt(pow((item->sourceX - item->destX),2.0)+pow((item->sourceY - item->destY),2.0));
	return [rh getTempValue:distance];
}

-(CValue*)exp_fromIndexGetRemainingDistance;
{
	int index = [[ho getExpParam] getInt];
	if(index < 0 || index >= [movingObjects size])
		return [rh getTempValue:-1];
	
	MoveItItem* item = (MoveItItem*)[movingObjects get:index];
	CObject* object = item->mobject;
	int distance = sqrt(pow((object->hoX - item->destX),2.0)+pow((object->hoY - item->destY),2.0));
	return [rh getTempValue:distance];
}

-(CValue*)exp_fromIndexGetAngle;
{
	int index = [[ho getExpParam] getInt];
	if(index < 0 || index >= [movingObjects size])
		return [rh getTempValue:-1];
	
	MoveItItem* item = (MoveItItem*)[movingObjects get:index];
	int angle = atan2((item->destX-item->sourceX),(item->destY-item->sourceY))* 180/_PI +270;
	return [rh getTempValue:angle];
}

-(CValue*)exp_fromIndexGetDirection;
{
	int index = [[ho getExpParam] getInt];
	if(index < 0 || index >= [movingObjects size])
		return [rh getTempValue:-1];
	
	MoveItItem* item = (MoveItItem*)[movingObjects get:index];
	int dir = atan2((item->destX-item->sourceX),(item->destY-item->sourceY))* 16/_PI +24;
	return [rh getTempValue:dir];
}

-(CValue*)exp_onObjectFinnishedGetFixed;
{
	if(triggeredObject != nil)
		return [rh getTempValue:[triggeredObject fixedValue]];
	else
		return [rh getTempValue:-1];
}

-(MoveItItem*)getItemFromFixed:(int)fixed
{
	for(int i=0; i<[movingObjects size]; ++i)
	{
		MoveItItem* item = (MoveItItem*)[movingObjects get:i];
		if([item->mobject fixedValue] == fixed)
			return item;
	}
	return nil;
}

-(MoveItItem*)getItemFromIndex:(int)index
{
	if(index < 0 || index >= [movingObjects size])
		return nil;
	return (MoveItItem*)[movingObjects get:index];
}

@end


@implementation MoveItItem

-(id)initWithObject:(CObject*)obj andDstX:(int)dstX andDstY:(int)dstY andCycles:(int)numCycles
{
	if((self = [super init]))
	{
		mobject = obj;
		sourceX = mobject->hoX;
		sourceY = mobject->hoY;
		destX = dstX;
		destY = dstY;
		cycles = MAX(numCycles,1);
		step = 0;
	}
	return self;
}

-(void)moveToDstX:(int)dstX andDstY:(int)dstY andCycles:(int)numCycles
{
	sourceX = mobject->hoX;
	sourceY = mobject->hoY;
	destX = dstX;
	destY = dstY;
	cycles = MAX(numCycles,1);
	step = 0;
}

@end



