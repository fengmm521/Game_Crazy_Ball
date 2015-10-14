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
// CRUNLOCATION
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CRunExtension.h"


@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;

#define CND_LOCENABLED 0
#define CND_NEWLOCATION 1
#define ACT_GETLOCATION 0
#define ACT_SETDISTANCEFILTER 1
#define ACT_SETACCURACY 2
#define EXP_LATITUDE 0
#define EXP_LONGITUDE 1
#define EXP_ALTITUDE 2
#define EXP_COURSE 3
#define EXP_SPEED 4
#define EXP_TIMELAST 5
#define EXP_DISTANCEFILTER 6
#define EXP_ACCURACY 7

@interface CRunLocation : CRunExtension <CLLocationManagerDelegate>
{
	int newLocationCount;
	int distance;
	int accuracy;
	BOOL locationUpdated;
	double altitude;
	double latitude;
	double longitude;
	double course;
	double speed;
	BOOL bEnabled;
	int deltaTime;
	CLLocationManager* locationManager;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation;
-(CValue*)expression:(int)num;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)cndNewLocation;
-(BOOL)cndEnabled;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)actGetLocation;
-(void)actSetDistance:(int)d;
-(void)actSetAccuracy:(int)acc;
-(CValue*)expLatitude;
-(CValue*)expLongitude;
-(CValue*)expAltitude;
-(CValue*)expCourse;
-(CValue*)expSpeed;

@end
