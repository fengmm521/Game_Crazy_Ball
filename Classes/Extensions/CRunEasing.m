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
//  CRunEasing.m
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 3/12/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "CRunEasing.h"
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
#import "ObjectSelection.h"

#define	CND_ANYOBJECTSTOPPED			0
#define CND_SPECIFICOBJECTSTOPPED		1
#define CND_ISOBJECTMOVING              2

#define ACT_MOVEOBJ						0
#define ACT_STOPOBJECT					1
#define ACT_STOPALLOBJECTS				2
#define ACT_REVERSEOBJECT				3
#define ACT_SETAMPLITUDE                4
#define ACT_SETOVERSHOOT                5
#define ACT_SETPERIOD                   6
#define ACT_SETOBJECTAMPLITUDE          7
#define ACT_SETOBJECTOVERSHOOT          8
#define ACT_SETOBJECTPERIOD             9
#define ACT_MOVEOBJNUMERIC				10

#define	EXP_GETNUMCONTROLLED			0
#define EXP_GETSTOPPEDFIXED				1
#define EXP_CALCULATE_EASEIN			2
#define EXP_CALCULATE_EASEOUT			3
#define EXP_CALCULATE_EASEINOUT			4
#define EXP_CALCULATE_EASEOUTIN			5
#define EXP_CALCULATEBETWEEN_EASEIN		6
#define EXP_CALCULATEBETWEEN_EASEOUT	7
#define EXP_CALCULATEBETWEEN_EASEINOUT	8
#define EXP_CALCULATEBETWEEN_EASEOUTIN	9
#define EXP_GETAMPLITUDE                10
#define EXP_GETOVERSHOOT                11
#define EXP_GETPERIOD                   12
#define EXP_GETDEFAULTAMPLITUDE         13
#define EXP_GETDEFAULTOVERSHOOT         14
#define EXP_GETDEFAULTPERIOD            15

#define	EASEIN		0
#define EASEOUT		1
#define EASEINOUT	2
#define	EASEOUTIN	3

double linear(double step, EaseVars vars)	{ return step; }
double quad(double step, EaseVars vars)		{ return pow(step, 2.0); }
double cubic(double step, EaseVars vars)	{ return pow(step, 3.0); }
double quart(double step, EaseVars vars)	{ return pow(step, 4.0); }
double quint(double step, EaseVars vars)	{ return pow(step, 5.0); }
double sine(double step, EaseVars vars)		{ return 1.0-sin((1-step)*90.0 * _PI/180.0); }
double expo(double step, EaseVars vars)		{ return pow(2.0, step*10.0)/1024.0; }
double circ(double step, EaseVars vars)		{ return 1.0f-sqrt(1.0-pow(step,2.0)); }
double back(double step, EaseVars vars)		{ return (vars.overshoot+1.0)* pow(step, 3.0) - vars.overshoot*pow(step, 2.0); }
double elastic(double step, EaseVars vars)
{
	step -= 1.0;
	float amp = MAX(1.0, vars.amplitude);
	float s = vars.period / (2.0 * _PI) * asin(1.0 / amp);
	return -(amp*pow(2.0,10*step) * sin((step-s)*(2*_PI)/vars.period));
}
double bounce(double step, EaseVars vars)
{
	step = 1-step;
	if (step < (8/22.0))
		return 1 - 7.5625*pow(step,2.0);
	else if (step < (16/22.0))
		return 1 - vars.amplitude * (7.5625*pow(step-(12/22.0), 2.0) + 0.75) - (1-vars.amplitude);
	else if (step < (20/22.0))
		return 1 - vars.amplitude * (7.5625*pow(step-(18/22.0), 2.0) + 0.9375) - (1-vars.amplitude);
	else
		return 1 - vars.amplitude * (7.5625*pow(step-(21/22.0), 2.0) + 0.984375) - (1-vars.amplitude);
}

double doFunction(int number, double step, EaseVars vars)
{
	switch(number)
	{
		default:
		case 0: return linear(step, vars);
		case 1: return quad(step, vars);
		case 2: return cubic(step, vars);
		case 3: return quart(step, vars);
		case 4: return quint(step, vars);
		case 5: return sine(step, vars);
		case 6: return expo(step, vars);
		case 7: return circ(step, vars);
		case 8: return back(step, vars);
		case 9: return elastic(step, vars);
		case 10: return bounce(step, vars);
	}
}

double easeIn(int function, double step, EaseVars vars)
{
	return doFunction(function, step, vars);
}

double easeOut(int function, double step, EaseVars vars)
{
	return 1.0-doFunction(function, 1.0-step, vars);
}

double easeInOut(int functionA, int functionB, double step, EaseVars vars)
{
	if(step < 0.5)
		return easeIn(functionA, step*2.0, vars)/2.0;
	else
		return easeOut(functionB, (step-0.5)*2.0, vars)/2.0 + 0.5;
}

double easeOutIn(int functionA, int functionB, double step, EaseVars vars)
{
	if(step < 0.5)
		return easeOut(functionA, step*2.0, vars)/2.0;
	else
		return easeIn(functionB, (step-0.5)*2.0, vars)/2.0 + 0.5;
}

double calculateEasingValue(int mode, int functionA, int functionB, double step, EaseVars vars)
{
	switch(mode)
	{
		default:
		case EASEIN:	return easeIn(functionA,step,vars);
		case EASEOUT:	return easeOut(functionA,step,vars);
		case EASEINOUT:	return easeInOut(functionA,functionB,step,vars);
		case EASEOUTIN:	return easeOutIn(functionA,functionB,step,vars);
	}
}


@implementation CRunEasing

-(int) getNumberOfConditions
{
	return 3;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	controlled = [[CArrayList alloc] init];
	deleted = [[CArrayList alloc] init];
	
	memset(&currentMoved, 0, sizeof(MoveStruct));
	
	int overshootI = [file readAInt];
	int amplitudeI = [file readAInt];
	int periodI = [file readAInt];
	
	easingVars.overshoot = *(float*)&overshootI;
	easingVars.amplitude = *(float*)&amplitudeI;
	easingVars.period = *(float*)&periodI;

	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[controlled freeRelease];
	[deleted freeRelease];
	[controlled release];
	[deleted release];
}

-(int)handleRunObject
{
	BOOL finnishedMoving = NO;
	float step;
	
	for(int i = 0; i<[controlled size]; i++)
	{
		CObject* object = nil;
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		
		if(i >= 0 && i < [controlled size])
		{
			object = [ho getObjectFromFixed:moved->mobject];
		}
		
		if (object != nil && (object->hoFlags & HOF_DESTROYED) == 0)
		{
			if(moved->timeMode == 0)
			{
				float seconds = moved->timespan / 1000.0f;
				NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
				NSTimeInterval diff = currentTime-moved->starttime;
				
 				step = diff / seconds;
				
				if(diff >= seconds)
					finnishedMoving = YES;
			}
			else
			{
				moved->eventloop_step++;
				step = moved->eventloop_step / (float)moved->timespan;
				
				if(moved->eventloop_step >= moved->timespan)
					finnishedMoving = YES;
			}
			
			float easeStep = calculateEasingValue(moved->easingMode, moved->functionA, moved->functionB, step, moved->vars);
			
			object->hoX = (int)(moved->startX + (moved->destX-moved->startX)*easeStep + 0.5f);
			object->hoY = (int)(moved->startY + (moved->destY-moved->startY)*easeStep + 0.5f);
			object->roc->rcChanged = YES;
			
			if(finnishedMoving)
			{
				finnishedMoving = NO;
				
				object->hoX = moved->destX;
				object->hoY = moved->destY;
				
				[deleted add:moved];
				[controlled removeIndex:i];
				i--;
			}
		}
		else
		{
			[controlled removeIndexFree:i];
			i--;
		}
		
	}
	
	//Trigger the 'Object stopped moving' events
	for(int d=0; d<[deleted size]; ++d)
	{
		currentMoved = *(MoveStruct*)[deleted get:d];
		[ho generateEvent:CND_SPECIFICOBJECTSTOPPED withParam:0];
		[ho generateEvent:CND_ANYOBJECTSTOPPED withParam:0];
	}
	[deleted freeRelease];
	return 0;
}

//Should it select the given object?
BOOL filterMoving(CObject* rdPtr, CObject* object)
{
	int fixed = [object fixedValue];
	CRunEasing* easing = (CRunEasing*)rdPtr;
	for( int i=0; i< [easing->controlled size]; ++i)
	{
		MoveStruct* moved = (MoveStruct*)[easing->controlled get:i];
		if(moved->mobject == fixed)
			return YES;
	}
	return NO;
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_ANYOBJECTSTOPPED:
			return YES;
		case CND_SPECIFICOBJECTSTOPPED:
		{
			short oi = [cnd getParamOi:rh withNum:0];
			CObject* object = [ho getObjectFromFixed:currentMoved.mobject];
			
			if(object != nil && [object isOfType:oi])
			{
				[rh->objectSelection selectOneObject:object];
				return YES;
			}
			return NO;
		}
		case CND_ISOBJECTMOVING:
		{
			LPEVP evt = [cnd getParamObject:rh withNum:0];
			LPEVT pe = (PEVT)(((LPBYTE)evt)-CND_SIZE);
			BOOL isNegated = (pe->evtFlags2 & EVFLAG2_NOT);
			short oi = [cnd getParamOi:rh withNum:0];
			
			BOOL ret = [rh->objectSelection filterObjects:(CObject*)self andOi:oi andNegate:isNegated andFilterFunction:&filterMoving];
			return ret;
		}
	}
	return NO;
}



-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_MOVEOBJ:
		{
			CFile* easeParam = [act getParamExtension:rh withNum:1];
			CFile* timeParam = [act getParamExtension:rh withNum:4];

			EasingParam easing;
			TimeModeParam time;

			easing.version = [easeParam readAByte];
			easing.method = [easeParam readAByte];
			easing.firstFunction = [easeParam readAByte];
			easing.secondFunction = [easeParam readAByte];

			time.type = [timeParam readAByte];


			[easeParam release];
			[timeParam release];

			[self moveObject:[act getParamObject:rh withNum:0] andParam:easing andX:[act getParamExpression:rh withNum:2] andY:[act getParamExpression:rh withNum:3] andTimeParam:time andTimeSpan:[act getParamExpression:rh withNum:5]];
			break;
		}
		case ACT_STOPOBJECT:
			[self stopObject:[act getParamObject:rh withNum:0]];
			break;
		case ACT_STOPALLOBJECTS:
		{
			[controlled freeRelease];
			break;
		}
		case ACT_REVERSEOBJECT:
			[self reverseObject:[act getParamObject:rh withNum:0]];
			break;
		case ACT_SETAMPLITUDE:
			easingVars.amplitude = [act getParamExpDouble:rh withNum:0];
			break;
		case ACT_SETOVERSHOOT:
			easingVars.overshoot = [act getParamExpDouble:rh withNum:0];
			break;
		case ACT_SETPERIOD:
			easingVars.period = [act getParamExpDouble:rh withNum:0];
			break;
		case ACT_SETOBJECTAMPLITUDE:
			[self setObjectAmplitude:[act getParamObject:rh withNum:0] andAmplitude:[act getParamExpDouble:rh withNum:1]];
			break;
		case ACT_SETOBJECTOVERSHOOT:
			[self setObjectOvershoot:[act getParamObject:rh withNum:0] andOvershoot:[act getParamExpDouble:rh withNum:1]];
			break;
		case ACT_SETOBJECTPERIOD:
			[self setObjectPeriod:[act getParamObject:rh withNum:0] andPeriod:[act getParamExpDouble:rh withNum:1]];
			break;
		case ACT_MOVEOBJNUMERIC:
		{
			int fixed = [act getParamExpression:rh withNum:0];
			CObject* object = [ho getObjectFromFixed:fixed];
			if(object == nil)
				break;

			EasingParam ease;
			TimeModeParam time;

			int method = [act getParamExpression:rh withNum:1];
			int funcA = [act getParamExpression:rh withNum:2];
			int funcB = ease.method = [act getParamExpression:rh withNum:3];

			ease.version = 6;
			ease.method = method;
			ease.firstFunction = funcA;
			ease.secondFunction = funcB;
			int x = [act getParamExpression:rh withNum:4];
			int y = [act getParamExpression:rh withNum:5];
			time.type = [act getParamExpression:rh withNum:6];
			int timespan = [act getParamExpression:rh withNum:7];

			[self moveObject:object andParam:ease andX:x andY:y andTimeParam:time andTimeSpan:timespan];
			break;
		}
	}
}

-(CValue*)expression:(int)num
{
	switch(num)
	{
		case EXP_GETNUMCONTROLLED:
			return [rh getTempValue:(int)[controlled size]];
		case EXP_GETSTOPPEDFIXED:
			return [rh getTempValue:currentMoved.mobject];
		case EXP_CALCULATE_EASEIN:
		{
			int function = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			return [rh getTempDouble:calculateEasingValue(EASEIN, function, 0, step, easingVars)];
		}
		case EXP_CALCULATE_EASEOUT:
		{
			int function = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			return [rh getTempDouble:calculateEasingValue(EASEOUT, function, 0, step, easingVars)];
		}
		case EXP_CALCULATE_EASEINOUT:
		{
			int functionA = [[ho getExpParam] getInt];
			int functionB = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			return [rh getTempDouble:calculateEasingValue(EASEINOUT, functionA, functionB, step, easingVars)];
		}
		case EXP_CALCULATE_EASEOUTIN:
		{
			int functionA = [[ho getExpParam] getInt];
			int functionB = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			return [rh getTempDouble:calculateEasingValue(EASEOUTIN, functionA, functionB, step, easingVars)];
		}
		case EXP_CALCULATEBETWEEN_EASEIN:
		{
			double valueA = [[ho getExpParam] getDouble];
			double valueB = [[ho getExpParam] getDouble];
			int function = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			double ease = calculateEasingValue(EASEIN, function, 0, step, easingVars);
			return [rh getTempDouble:valueA + (valueB-valueA)*ease];
		}
		case EXP_CALCULATEBETWEEN_EASEOUT:
		{
			double valueA = [[ho getExpParam] getDouble];
			double valueB = [[ho getExpParam] getDouble];
			int function = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			double ease = calculateEasingValue(EASEOUT, function, 0, step, easingVars);
			return [rh getTempDouble:valueA + (valueB-valueA)*ease];
		}
		case EXP_CALCULATEBETWEEN_EASEINOUT:
		{
			double valueA = [[ho getExpParam] getDouble];
			double valueB = [[ho getExpParam] getDouble];
			int functionA = [[ho getExpParam] getInt];
			int functionB = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			double ease = calculateEasingValue(EASEINOUT, functionA, functionB, step, easingVars);
			return [rh getTempDouble:valueA + (valueB-valueA)*ease];
		}
		case EXP_CALCULATEBETWEEN_EASEOUTIN:
		{
			double valueA = [[ho getExpParam] getDouble];
			double valueB = [[ho getExpParam] getDouble];
			int functionA = [[ho getExpParam] getInt];
			int functionB = [[ho getExpParam] getInt];
			double step = [[ho getExpParam] getDouble];
			double ease = calculateEasingValue(EASEOUTIN, functionA, functionB, step, easingVars);
			return [rh getTempDouble:valueA + (valueB-valueA)*ease];
		}
		case EXP_GETAMPLITUDE:
		{
			int fixed = [[ho getExpParam] getInt];
			for(int i=0; i<[controlled size]; ++i)
			{
				MoveStruct* moved = (MoveStruct*)[controlled get:i];
				if(moved->mobject == fixed)
					return [rh getTempDouble:moved->vars.amplitude];
			}
			return [rh getTempDouble:0];
		}
		case EXP_GETOVERSHOOT:
		{
			int fixed = [[ho getExpParam] getInt];
			for(int i=0; i<[controlled size]; ++i)
			{
				MoveStruct* moved = (MoveStruct*)[controlled get:i];
				if(moved->mobject == fixed)
					return [rh getTempDouble:moved->vars.overshoot];
			}
			return [rh getTempDouble:0];
		}
		case EXP_GETPERIOD:
		{
			int fixed = [[ho getExpParam] getInt];
			for(int i=0; i<[controlled size]; ++i)
			{
				MoveStruct* moved = (MoveStruct*)[controlled get:i];
				if(moved->mobject == fixed)
					return [rh getTempDouble:moved->vars.period];
			}
			return [rh getTempDouble:0];
		}
		case EXP_GETDEFAULTAMPLITUDE:
			return [rh getTempDouble:easingVars.amplitude];
		case EXP_GETDEFAULTOVERSHOOT:
			return [rh getTempValue:easingVars.overshoot];
		case EXP_GETDEFAULTPERIOD:
			return [rh getTempValue:easingVars.period];
	}
	return [rh getTempDouble:0];
}


-(void)moveObject:(CObject*)object andParam:(EasingParam)easing andX:(int)x andY:(int)y andTimeParam:(TimeModeParam)time andTimeSpan:(int)timespan
{
	if(object == nil)
		return;
	
	//Remove object if it exists
	int fixed = [object fixedValue];
	for(int i = 0; i < [controlled size]; ++i)
	{
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		if(moved->mobject == fixed)
		{
			[controlled removeIndexFree:i];
			break;
		}
	}
	
	MoveStruct* move = (MoveStruct*)malloc(sizeof(MoveStruct));
	move->startX = object->hoX;
	move->startY = object->hoY;
	move->mobject = [object fixedValue];
	move->destX = x;
	move->destY = y;
	move->starttime = nil;
	
	move->easingMode = easing.method;
	move->functionA = easing.firstFunction;
	move->functionB = easing.secondFunction;
	
	move->timeMode = time.type;
	move->timespan = timespan;
	move->eventloop_step = 0;
	
	if(move->timeMode == 0)
	{
		move->starttime = [NSDate timeIntervalSinceReferenceDate];
	}
	
	move->vars = easingVars;
	[controlled add:move];
}

-(void)stopObject:(CObject*)object
{
	int fixed = [object fixedValue];
	for(int i = 0; i < [controlled size]; i++)
	{
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		if(moved->mobject == fixed)
		{
			[controlled removeIndexFree:i];
			return;
		}
	}
}

-(void)reverseObject:(CObject*)object
{
	MoveStruct* reversed = (MoveStruct*)malloc(sizeof(MoveStruct));
	memset(reversed,0,sizeof(MoveStruct));
	int fixed = [object fixedValue];
	
	//Otherwise remove the object and reinsert it with new coordinates.
	for(int i = 0; i < [controlled size]; i++)
	{
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		if(moved->mobject == fixed)
		{
			memcpy(reversed, &moved, sizeof(MoveStruct));
			[controlled removeIndexFree:i];
			break;
		}
	}
	
	//If it was the object that was just stopped then use that one.
	if(reversed->mobject == 0)
	{
		if(currentMoved.mobject == fixed)
			memcpy(reversed, &currentMoved, sizeof(MoveStruct));
		else	//If no object found, abort
			return;
	}
	
	reversed->destX = reversed->startX;
	reversed->destY = reversed->startY;
	
	reversed->startX = object->hoX;
	reversed->startY = object->hoY;
	
	//Recalculate the time it should take moving to the previous position
	if(reversed->timeMode == 0)
	{
		NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
		NSTimeInterval timeSoFar = currentTime  - reversed->starttime;
		
		reversed->timespan = (int)(timeSoFar*1000);
		reversed->starttime = currentTime;
	}
	else
	{
		reversed->timespan = reversed->eventloop_step;
		reversed->eventloop_step = 0;
	}
	
	[controlled add:reversed];
}

-(void)setObjectAmplitude:(CObject*)object andAmplitude:(double)amplitude
{
	int fixed = [object fixedValue];
	for(int i=0; i<[controlled size]; ++i)
	{
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		if(moved->mobject == fixed)
		{
			moved->vars.amplitude = amplitude;
			return;
		}
	}
}

-(void)setObjectOvershoot:(CObject*)object andOvershoot:(double)overshoot
{
	int fixed = [object fixedValue];
	for(int i=0; i<[controlled size]; ++i)
	{
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		if(moved->mobject == fixed)
		{
			moved->vars.overshoot = overshoot;
			return;
		}
	}
}

-(void)setObjectPeriod:(CObject*)object andPeriod:(double)period
{
	int fixed = [object fixedValue];
	for(int i=0; i<[controlled size]; ++i)
	{
		MoveStruct* moved = (MoveStruct*)[controlled get:i];
		if(moved->mobject == fixed)
		{
			moved->vars.period = period;
			return;
		}
	}
}


@end
