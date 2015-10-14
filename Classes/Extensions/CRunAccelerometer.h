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
// CRUNIPHONEACC iPhone accelerometers
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import <CoreMotion/CoreMotion.h>
#import "CRunExtension.h"

#define EXP_XDIRECT 0
#define EXP_YDIRECT 1
#define EXP_ZDIRECT 2
#define EXP_XGRAVITY 3
#define EXP_YGRAVITY 4
#define EXP_ZGRAVITY 5
#define EXP_XINSTANT 6
#define EXP_YINSTANT 7
#define EXP_ZINSTANT 8
#define EXP_ORIENTATION 9
#define CND_ORIENTATIONCHANGED 0

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;

@interface CRunAccelerometer : CRunExtension
{
	int orientationCount;
	UIDeviceOrientation oldOrientation;
	CMMotionManager* motionManager;
	CMAcceleration acceleration;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(CValue*)expression:(int)num;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)orientationChanged;

@end
