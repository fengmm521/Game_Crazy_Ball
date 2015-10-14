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
// CRUNLOCATION : iPhone GPS
//
//----------------------------------------------------------------------------------
#import "CRunLocation.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"

@implementation CRunLocation

-(int)getNumberOfConditions
{
	return 2;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	distance=[file readAInt];
	accuracy=[file readAInt];
	
	bEnabled=NO;
	locationManager=[[CLLocationManager alloc] init];
	if ([CLLocationManager locationServicesEnabled])
	{
		bEnabled=YES;
		locationManager.delegate=self;
		locationManager.desiredAccuracy=accuracy;
		locationManager.distanceFilter=distance;
		[locationManager startUpdatingLocation];
	}
	return YES;
}

-(void)destroyRunObject:(BOOL)bFast
{
	if (bEnabled)
	{
		[locationManager stopUpdatingLocation];
	}
	[locationManager release];
}

-(int)handleRunObject
{
	return REFLAG_ONESHOT;
}

-(void)locationManager:(CLLocationManager*)manager didUpdateToLocation:(CLLocation *)newLocation fromLocation:(CLLocation *)oldLocation
{
	altitude=newLocation.altitude;
	latitude=newLocation.coordinate.latitude;
	longitude=newLocation.coordinate.longitude;
	course=newLocation.course;
	speed=newLocation.speed;
	newLocationCount=[ho getEventCount];
	[ho pushEvent:CND_NEWLOCATION withParam:0];
    NSDate* eventDate = newLocation.timestamp;
    deltaTime = (int)[eventDate timeIntervalSinceNow]*1000;	
}

-(void)locationManager:(CLLocationManager *)manager didUpdateLocations:(NSArray *)locations
{
	for (CLLocation* newLocation in locations)
	{
		altitude=newLocation.altitude;
		latitude=newLocation.coordinate.latitude;
		longitude=newLocation.coordinate.longitude;
		course=newLocation.course;
		speed=newLocation.speed;
		newLocationCount=[ho getEventCount];
		NSDate* eventDate = newLocation.timestamp;
		deltaTime = (int)[eventDate timeIntervalSinceNow]*1000;
		[ho generateEvent:CND_NEWLOCATION withParam:0];
	}
}

#ifdef __IPHONE_8_0
-(void)locationManager:(CLLocationManager *)manager didFailWithError:(NSError *)error
{
	NSLog(@"Location error: %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didFinishDeferredUpdatesWithError:(NSError *)error
{
	NSLog(@"Finnished deferred locations with error: %@", error);
}

-(void)locationManager:(CLLocationManager *)manager didChangeAuthorizationStatus:(CLAuthorizationStatus)status
{
	if(status == kCLAuthorizationStatusAuthorizedWhenInUse || status == kCLAuthorizationStatusAuthorizedAlways)
		[locationManager startUpdatingLocation];
}
#endif

// Conditions
// -----------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_NEWLOCATION:
			return [self cndNewLocation];
		case CND_LOCENABLED:
			return [self cndEnabled];
	}
	return NO;
}
-(BOOL)cndNewLocation
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == newLocationCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)cndEnabled
{
	return bEnabled;
}

// Actions
// --------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch(num)
	{
		case ACT_GETLOCATION:
			[self actGetLocation];
			break;
		case ACT_SETDISTANCEFILTER:
			[self actSetDistance:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETACCURACY:
			[self actSetAccuracy:[act getParamExpression:rh withNum:0]];
			break;
	}
}
-(void)actGetLocation
{
	if (bEnabled)
	{
		[locationManager stopUpdatingLocation];
#ifdef __IPHONE_8_0
		if([locationManager respondsToSelector:@selector(requestWhenInUseAuthorization)])
			[locationManager requestWhenInUseAuthorization];
#endif

		[locationManager startUpdatingLocation];
	}
}
-(void)actSetDistance:(int)d
{
	distance=d;
	if (distance>=1)
	{
		if (bEnabled)
		{
			locationManager.distanceFilter=d;
		}
	}
}
-(void)actSetAccuracy:(int)acc
{
	if (acc>=0 && acc<=4)
	{
		accuracy=acc;
		if (bEnabled)
		{
			locationManager.desiredAccuracy=acc;
		}
	}
	
}
// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_LATITUDE:
			return [self expLatitude];
		case EXP_LONGITUDE:
			return [self expLongitude];
		case EXP_ALTITUDE:
			return [self expAltitude];
		case EXP_COURSE:
			return [self expCourse];
		case EXP_SPEED:
			return [self expSpeed];
		case EXP_TIMELAST:
			return [rh getTempValue:deltaTime];
		case EXP_DISTANCEFILTER:
			return [rh getTempValue:distance];
		case EXP_ACCURACY:
			return [rh getTempValue:accuracy];
	}
	return nil;
}
-(CValue*)expLatitude
{
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:latitude];
	return ret;
}
-(CValue*)expLongitude
{
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:longitude];
	return ret;
}
-(CValue*)expAltitude
{
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:altitude];
	return ret;
}
-(CValue*)expCourse
{
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:course];
	return ret;
}
-(CValue*)expSpeed
{
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:speed];
	return ret;
}

@end
