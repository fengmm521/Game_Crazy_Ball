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
//  CRunEasing.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 3/12/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;
@class CObject;
@class MoveItItem;

//Custom action parameter structs
struct EasingParam
{
	unsigned char version;
	unsigned char method;
	unsigned char firstFunction;
	unsigned char secondFunction;
};
typedef struct EasingParam EasingParam;

struct TimeModeParam
{
	unsigned char type;
};
typedef struct TimeModeParam TimeModeParam;


//Easing parameter value struct
struct EaseVars
{
	float overshoot;
	float amplitude;
	float period;
};
typedef struct EaseVars EaseVars;

//Runtime structures:
struct MoveStruct
{
	int		mobject;
	int		startX;
	int		startY;
	int		destX;
	int		destY;
	
	EaseVars vars;
	
	unsigned char	easingMode;
	unsigned char	functionA;
	unsigned char	functionB;
	
	unsigned char	timeMode;
	NSTimeInterval	starttime;
	int				timespan;
	int				eventloop_step;
};
typedef struct MoveStruct MoveStruct;

double linear(double step, EaseVars vars);
double quad(double step, EaseVars vars);
double cubic(double step, EaseVars vars);
double quart(double step, EaseVars vars);
double quint(double step, EaseVars vars);
double sine(double step, EaseVars vars);
double expo(double step, EaseVars vars);
double circ(double step, EaseVars vars);
double back(double step, EaseVars vars);
double elastic(double step, EaseVars vars);
double bounce(double step, EaseVars vars);
double doFunction(int number, double step, EaseVars vars);
double easeIn(int function, double step, EaseVars vars);
double easeOut(int function, double step, EaseVars vars);
double easeInOut(int functionA, int functionB, double step, EaseVars vars);
double easeOutIn(int functionA, int functionB, double step, EaseVars vars);
double calculateEasingValue(int mode, int functionA, int functionB, double step, EaseVars vars);

@interface CRunEasing : CRunExtension
{
	CArrayList* controlled;
	MoveStruct	currentMoved;
	EaseVars	easingVars;
	CArrayList* deleted;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

-(void)moveObject:(CObject*)object andParam:(EasingParam)easeParam andX:(int)x andY:(int)y andTimeParam:(TimeModeParam)timeParam andTimeSpan:(int)timespan;
-(void)stopObject:(CObject*)object;
-(void)reverseObject:(CObject*)object;
-(void)setObjectAmplitude:(CObject*)object andAmplitude:(double)amplitude;
-(void)setObjectOvershoot:(CObject*)object andOvershoot:(double)overshoot;
-(void)setObjectPeriod:(CObject*)object andPeriod:(double)period;

@end

BOOL filterMoving(CObject* rdPtr, CObject* object);
