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
// CRUNACCELEROMETER iPhone accelerometers
//
//----------------------------------------------------------------------------------
#import "CRunAccelerometer.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"

@implementation CRunAccelerometer

-(int)getNumberOfConditions
{
	return 1;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	orientationCount=-1;

	UIDevice* device=[UIDevice currentDevice];
	oldOrientation=device.orientation;

	motionManager = [[CMMotionManager alloc] init];

	acceleration.x = acceleration.y = acceleration.z = 0;
	if(motionManager.accelerometerAvailable)
		[motionManager startAccelerometerUpdates];
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[motionManager stopAccelerometerUpdates];
	[motionManager release];
}

-(int)handleRunObject
{
	CMAcceleration na = motionManager.accelerometerData.acceleration;
	switch (rh->rhApp->actualOrientation)
	{
		case ORIENTATION_PORTRAIT:
			acceleration = na;
			break;
		case ORIENTATION_PORTRAITUPSIDEDOWN:
			acceleration = na;
			acceleration.z *= -1;
			break;
		case ORIENTATION_LANDSCAPELEFT:
			acceleration.x = na.y;
			acceleration.y = -na.x;
			acceleration.z = na.z;
			break;
		case ORIENTATION_LANDSCAPERIGHT:
			acceleration.x = -na.y;
			acceleration.y = na.x;
			acceleration.z = na.z;
			break;
	}
	UIDevice* device=[UIDevice currentDevice];
	UIDeviceOrientation orientation=device.orientation;
	if (orientation!=oldOrientation)
	{
		oldOrientation=orientation;
		orientationCount=[ho getEventCount];
		[ho pushEvent:CND_ORIENTATIONCHANGED withParam:0];
	}
	return 0;
}
// Conditions
// -----------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	if (num==CND_ORIENTATIONCHANGED)
	{
		return [self orientationChanged];
	}
	return NO;
}
-(BOOL)orientationChanged
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == orientationCount)
	{
		return YES;
	}
	return NO;
}
// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	double ret=0.0;
	switch (num)
	{
		case EXP_XDIRECT:
			ret = acceleration.x;
			break;
		case EXP_YDIRECT:
			ret = acceleration.y;
			break;
		case EXP_ZDIRECT:
			ret = acceleration.z;
			break;
		case EXP_XGRAVITY:
			ret = acceleration.x;
			break;
		case EXP_YGRAVITY:
			ret = acceleration.y;
			break;
		case EXP_ZGRAVITY:
			ret = acceleration.z;
			break;
		case EXP_XINSTANT:
			ret = acceleration.x;
			break;
		case EXP_YINSTANT:
			ret = acceleration.y;
			break;
		case EXP_ZINSTANT:
			ret = acceleration.z;
			break;
		case EXP_ORIENTATION:
		{
			UIDevice* device=[UIDevice currentDevice];
			return [rh getTempValue:(int)device.orientation];
		}			
	}
	return [rh getTempDouble:ret];
}


@end
