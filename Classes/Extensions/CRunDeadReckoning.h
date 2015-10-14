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

#import <Foundation/Foundation.h>
#import "CRunExtension.h"


@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;
@class CObject;
@class ObjectSelection;

enum {
	INTERPOLATION_LINEAR = 0,
	INTERPOLATION_CUBIC = 1
};

enum {
	WRAP_LINEAR = 0,
	WRAP_CIRCULAR = 1
};



#define AVERAGEWINDOW		8

@interface CRunDeadReckoning : CRunExtension
{
@public
	int				time;
	int				extrapolationMethod;
	bool			useAcceleration;
	float			XSmoothing;
	float			YSmoothing;
	float			DirSmoothing;
	float			AngleSmoothing;
	bool			hwa;
	bool			isInObstacle;
	NSMutableDictionary*	objects;
	CObject*		objectToPush;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

-(int)wrapInt:(int)value intoRange:(int)range;
-(float)wrapFloat:(float)value intoRange:(float)range;

@end



@interface DRValue : NSObject
{
@public
	float	currentPos;			//The object's actual current position.
	float	stepPos;			//The currently interpolated value (ideal position, currentPos will approach this value each step)
	float	posAtUpdate;		//The position at the last update (used for correcting errors)
	float	diffAtUpdate;		//The latest value difference
	
	float	oldPos;				//Position at last update
	float	oldSpeed;			//Speed at last update
	
	float	prevPos;			//The previous value; used in cubic extrapolation
	float	nextPos;			//Guessed next position
	
	bool	doSpeedOverride;	//If the next update should override it's speed calculation
	float	speedOverride;		//The speed to override with;
	
	//Timing data
	int	lastUpdate;
	int	currentStep;
	int	timeDeltaIndex;
	int	numDeltas;
	size_t	timeDeltas[AVERAGEWINDOW];	//Circular array of timeDeltas for calculating the average update interval.
	float	averageUpdateInterval;
	
	//Settings
	bool	useAcceleration;
	int		extrapolationMode;
	float	smoothing;
	bool	wrapMode;
	float	wrapValue;
}

-(void)reset;
-(void)updateValue:(float)newValue atTime:(int)time;
-(void)setValue:(float)value;
-(void)setSpeed:(float)speed;
-(void)doStep;
-(float)cubicInterpolation:(float)y0 y1:(float)y1 y2:(float)y2 y3:(float)y3 mu:(float)mu;
-(void)updateAverageInterval:(size_t)timeDelta;
-(float)circularDifference:(float)angleA angleB:(float)angleB wrap:(float)wrapValue;

@end


@interface DRObj : NSObject
{
@public
	int fixedValue;
	float previousAngle;
	int oldX;
	int oldY;
	
	DRValue* xPosition;
	DRValue* yPosition;
	DRValue* direction;
	DRValue* angle;
}

-(id)init;
-(void)reset;

@end
