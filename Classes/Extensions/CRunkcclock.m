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
// CRUNKCCLOCK
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import <CoreLocation/CoreLocation.h>
#import "CRunkcclock.h"

#import "CActExtension.h"
#import "CCndExtension.h"

#import "CExtension.h"
#import "CPoint.h"
#import "CCreateObjectInfo.h"
#import "CFile.h"
#import "CFontInfo.h"
#import "CRenderer.h"

#import "CRect.h"
#import "CRunApp.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CServices.h"
#import "CTextSurface.h"
#import "CFont.h"
#import "CFontInfo.h"

double months_duration[] =
{
	0.0,
	267840000.0,
	509760000.0,
	777600000.0,
	1123200000.0,
	1304640000.0,
	1563840000.0,
	1831680000.0,
	2099520000.0,
	2358720000.0,
	2626560000.0,
	2885760000.0,
};

NSString* szRoman[] = {@"I",@"II",@"III",@"IV",@"V",@"VI",@"VII",@"VIII",@"IX",@"X",@"XI",@"XII"};
NSString* szNumbers[] = {@"1",@"2",@"3",@"4",@"5",@"6",@"7",@"8",@"9",@"10",@"11",@"12"};
NSString* FORMAT[] =
{
	@"dd/MM/yy",
	@"d MMMM yyyy",
	@"d MMMM, yyyy",
	@"MMMM d, yyyy",
	@"dd-MMM-yy",
	@"MMMM, yy",
	@"MMM-yy"
};

//CONDITIONS
#define CND_CMPCHRONO 0
#define CND_NEWSECOND 1
#define CND_NEWMINUTE 2
#define CND_NEWHOUR 3
#define CND_NEWDAY 4
#define CND_NEWMONTH 5
#define CND_NEWYEAR 6
#define CND_CMPCOUNTDOWN 7
#define CND_VISIBLE 8

//ACTIONS
#define ACT_SETCENTIEMES 0
#define ACT_SETSECONDES 1
#define ACT_SETMINUTES 2
#define ACT_SETHOURS 3
#define ACT_SETDAYOFWEEK 4
#define ACT_SETDAYOFMONTH 5
#define ACT_SETMONTH 6
#define ACT_SETYEAR 7
#define ACT_RESETCHRONO 8
#define ACT_STARTCHRONO 9
#define ACT_STOPCHRONO 10
#define ACT_SHOW 11
#define ACT_HIDE 12
#define ACT_SETPOSITION 13
#define ACT_SETCOUNTDOWN 14
#define ACT_STARTCOUNTDOWN 15
#define ACT_STOPCOUNTDOWN 16
#define ACT_SETXPOSITION 17
#define ACT_SETYPOSITION 18
#define ACT_SETXSIZE 19
#define ACT_SETYSIZE 20

//EXPRESSIONS	
#define EXP_GETCENTIEMES 0
#define EXP_GETSECONDES 1
#define EXP_GETMINUTES 2
#define EXP_GETHOURS 3
#define EXP_GETDAYOFWEEK 4
#define EXP_GETDAYOFMONTH 5
#define EXP_GETMONTH 6
#define EXP_GETYEAR 7
#define EXP_GETCHRONO 8
#define EXP_GETCENTERX 9
#define EXP_GETCENTERY 10
#define EXP_GETHOURX 11
#define EXP_GETHOURY 12
#define EXP_GETMINUTEX 13
#define EXP_GETMINUTEY 14
#define EXP_GETSECONDX 15
#define EXP_GETSECONDY 16
#define EXP_GETCOUNTDOWN 17
#define EXP_GETXPOSITION 18
#define EXP_GETYPOSITION 19
#define EXP_GETXSIZE 20
#define EXP_GETYSIZE 21

//Properties
#define ANALOG_CLOCK 0
#define DIGITAL_CLOCK 1
#define INVISIBLE 2
#define CALENDAR 3
#define CLOCK 0
#define STOPWATCH 1
#define COUNTDOWN 2
#define SHORTDATE 0
#define LONGDATE 1
#define FIXEDDATE 2

@implementation CRunkcclock

-(int)getNumberOfConditions
{
	return 9;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ADJ = 0;
	[ho setX:cob->cobX];
	[ho setY:cob->cobY];
	ho->hoImgXSpot = 0;
	ho->hoImgYSpot = 0;
	[ho setWidth:[file readAShort]];
	[ho setHeight:[file readAShort]];
	[file skipBytes:(4 * 16)];
	sType = [file readAShort];
	sClockMode = [file readAShort];
	sClockBorder = ([file readAShort] == 0) ? false : true;
	sAnalogClockLines = ([file readAShort] == 0) ? false : true;
	sAnalogClockMarkerType = [file readAShort];
	sFont = [file readLogFont];
	if ((sFont->lfHeight == 8) && ( [[sFont->lfFaceName uppercaseString] compare:@"SYSTEM"]))
	{
		sFont->lfHeight = 13; //c++ bug i think
		sFont->lfWeight = 700;//bold
	}
	hFont = [CFont createFromFontInfo:sFont];
    [hFont createFont];
	crFont = [file readAColor];
	[file skipStringOfLength:40];
	sAnalogClockSeconds = ([file readAShort] == 0) ? false : true;
	crAnalogClockSeconds = [file readAColor];
	sAnalogClockMinutes = ([file readAShort] == 0) ? false : true;
	crAnalogClockMinutes = [file readAColor];
	sAnalogClockHours = ([file readAShort] == 0) ? false : true;
	crAnalogClockHours = [file readAColor];
	sDigitalClockType = [file readAShort];
	sCalendarType = [file readAShort];
	sCalendarFormat = [file readAShort];
	[file skipStringOfLength:40];
	short sCountDownHours = [file readAShort];
	short sCountDownMinutes = [file readAShort];
	short sCountDownSeconds = [file readAShort];
	countdownStart = (sCountDownHours * 3600) + (sCountDownMinutes * 60) + sCountDownSeconds;
	sMinWidth = [file readAShort];
	sMinHeight = [file readAShort];
	sVisible = true;
	startTimer = nil;
	stopTimer = nil;
	sDisplay = true;
	
	textSurface = [[CTextSurface alloc] initWidthWidth:ho->hoImgWidth andHeight:ho->hoImgHeight];
	updateAnalog = YES;
	
	currentCalendar = [[NSCalendar currentCalendar] retain];	//Huge performance boost from caching this variable
#ifdef __IPHONE_8_0
	NSDateComponents* dc = [currentCalendar components:NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[NSDate date]];
#else
	NSDateComponents* dc = [currentCalendar components:NSYearCalendarUnit|NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[NSDate date]];
#endif

	prevYear = [dc year];
	prevMonth = [dc month];
	prevDay = [dc day];
	prevHour = [dc hour];
	prevMinute = [dc minute];
	prevSecond = [dc second];
	tmpString = [[NSString alloc] initWithString:@""];
	tmpSecond = -1;
	tmpMinute = -1;
	tmpHour = -1;
	return true;
}

-(void)destroyRunObject:(BOOL)bFast
{
	[textSurface release];
	[tmpString release];
	[currentCalendar release];
	
	if(hFont != nil)
		[hFont release];
	
	if(startTimer != nil)
		[startTimer release];
	
	if(stopTimer != nil)
		[stopTimer release];
}

//Date object representing the time ellapsed since the startTimer
-(NSDate*)getCurrentTime
{
	NSTimeInterval interval = [startTimer timeIntervalSinceNow];
	return [NSDate dateWithTimeIntervalSinceNow:-interval];
}

-(NSTimeInterval)chronoTimeInterval
{
	if(startTimer != nil && stopTimer != nil)
		return -[startTimer timeIntervalSinceDate:stopTimer];
	else if(startTimer != nil && stopTimer == nil)
		return -[startTimer timeIntervalSinceNow];
	else
		return (NSTimeInterval)0.0;
}

-(NSTimeInterval)currentCountdown
{
	if(stopTimer != nil)
	{
		NSTimeInterval interval = [stopTimer timeIntervalSinceNow];
		if(interval < 0)
		{
			[stopTimer release];
			stopTimer = nil;
			countdownStart = 0;
			return 0;
		}
		return interval;
	}
	else
		return countdownStart;
}

  
-(double)getChronoFromDate:(NSDate*)date
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:date];
#else
	NSDateComponents* comp = [currentCalendar components:NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:date];
#endif
	NSTimeInterval centimeInterval = [date timeIntervalSinceReferenceDate];
	double centimes = (ceil(centimeInterval)-centimeInterval)*100.0;
	return months_duration[[comp month]] + ([comp day]-1)*8640000 + [comp hour]*360000 + [comp minute]*6000 + [comp second]*100 + centimes;
}

-(void)changeTime:(NSDate*)date
{
	if(startTimer != nil)
		[startTimer release];
	startTimer = [[NSDate alloc] init];
}

-(int)handleRunObject
{
	short ret = 0;
	if (sDisplay)
	{
		sDisplay = false;
		ret = REFLAG_DISPLAY;
	}
	// If system time change
#ifdef __IPHONE_8_0
	NSDateComponents* dc = [currentCalendar components:NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[NSDate date]];
#else
	NSDateComponents* dc = [currentCalendar components:NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[NSDate date]];
#endif
	
	NSInteger lYea = [dc year];
	NSInteger lMon = [dc month];
	NSInteger lDay = [dc day];
	NSInteger lHou = [dc hour];
	NSInteger lMin = [dc minute];
	NSInteger lSec = [dc second];
	switch (sType)
	{
		case ANALOG_CLOCK:
		case DIGITAL_CLOCK:
		case INVISIBLE:
		{
			if (lSec != prevSecond)
			{
				sEventCount = (short)rh->rh4EventCount;
				[ho pushEvent:CND_NEWSECOND withParam:[ho getEventParam]];
				ret = REFLAG_DISPLAY;
				if (lMin != prevMinute)
				{
					sEventCount = (short)rh->rh4EventCount;
					[ho pushEvent:CND_NEWMINUTE withParam:[ho getEventParam]];
					if (lHou != prevHour)
					{
						sEventCount = (short)rh->rh4EventCount;
						[ho pushEvent:CND_NEWHOUR withParam:[ho getEventParam]];
					}
				}
			}
			break;
		}
		case CALENDAR:
		{	
			if (lDay != prevDay)
			{
				sEventCount = (short)rh->rh4EventCount;
				[ho pushEvent:CND_NEWDAY withParam:[ho getEventParam]];
				ret = REFLAG_DISPLAY;
				if (lMon != prevMonth)
				{
					sEventCount = (short)rh->rh4EventCount;
					[ho pushEvent:CND_NEWMONTH withParam:[ho getEventParam]];
					if (lYea != prevYear)
					{
						sEventCount = (short)rh->rh4EventCount;
						[ho pushEvent:CND_NEWYEAR withParam:[ho getEventParam]];
					}
				}
			}
			break;
		}
	}
	
	prevSecond = lSec;
	prevMinute = lMin;
	prevHour = lHou;
	prevDay = lDay;
	prevMonth = lMon;
	prevYear = lYea;
	
	return ret;
}

-(void)displayRunObject:(CRenderer*)renderer
{
	if (!sVisible)
		return;
		
	CRect rc;
	
	// Compute coordinates
	rc.left = ho->hoX;
	rc.right = rc.left + ho->hoImgWidth;
	rc.top = ho->hoY;
	rc.bottom = rc.top + ho->hoImgHeight;
	int ampm = 0; // ANDOS: lastRecordedTime.get(Calendar.AM_PM);
	
#ifdef __IPHONE_8_0
	NSDateComponents* dc = [currentCalendar components:NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitHour|NSCalendarUnitMinute|NSCalendarUnitSecond fromDate:[NSDate date]];
#else
	NSDateComponents* dc = [currentCalendar components:NSMonthCalendarUnit|NSDayCalendarUnit|NSHourCalendarUnit|NSMinuteCalendarUnit|NSSecondCalendarUnit fromDate:[NSDate date]];
#endif

	short year = [dc year];
	short month = [dc month];
	short day = [dc day];
	short hour = [dc hour];
	short minute = [dc minute];
	short second = [dc second];
	short dayofweek = [dc weekday]-1;
	
	switch (sType)
	{
		case ANALOG_CLOCK: // Analogue clock
		{
			if (CLOCK == sClockMode)
			{
				if (hour > 11)
					hour -= 12;
				if (sAnalogClockMarkerType != 2)
				{
					CRect rcNewRect;
					rcNewRect.left = rc.left + (sMinWidth / 2);
					rcNewRect.right = rc.right - (sMinWidth / 2);
					rcNewRect.top = rc.top + (sMinHeight / 2);
					rcNewRect.bottom = rc.bottom - (sMinHeight / 2);
					[self runDisplayAnalogTime:renderer andHour:hour andMinutes:minute andSeconds:second andRect:rcNewRect andBoundRect:rc];
				}
				else
				{
					[self runDisplayAnalogTime:renderer andHour:hour andMinutes:minute andSeconds:second andRect:rc andBoundRect:rc];
				}
			}
			else
			{
				NSTimeInterval currentChrono;
				int usHour, usMinute, usSecond;

				// Type
				if (COUNTDOWN == sClockMode)
					currentChrono = [self currentCountdown];
				else
					currentChrono = [self chronoTimeInterval];

				// Compute hours, minutes & seconds
				usHour = (int) (currentChrono / 3600);
				if (usHour > 11)
					usHour -= 12;
				usMinute = (int)((currentChrono - (usHour * 3600)) / 60);
				usSecond = (int)(currentChrono - (usHour * 3600) - (usMinute * 60));

				// Display
				if (sAnalogClockMarkerType != 2)
				{
					CRect rcNewRect;
					rcNewRect.left = rc.left + (sMinWidth / 2);
					rcNewRect.right = rc.right - (sMinWidth / 2);
					rcNewRect.top = rc.top + (sMinHeight / 2);
					rcNewRect.bottom = rc.bottom - (sMinHeight / 2);
					[self runDisplayAnalogTime:renderer andHour:usHour andMinutes:usMinute andSeconds:usSecond andRect:rcNewRect andBoundRect:rc];
				}
				else
				{
					[self runDisplayAnalogTime:renderer andHour:usHour andMinutes:usMinute andSeconds:usSecond andRect:rc andBoundRect:rc];
				}
			}
			break;
		}
		case DIGITAL_CLOCK: // Digital clock
		{
			switch (sDigitalClockType)
			{
				case 0:
					if (CLOCK == sClockMode)
					{
						if (hour > 11)
							hour -= 12;
						
						if(minute != tmpMinute || hour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d", hour, minute];
							tmpHour = hour; tmpMinute = minute;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					else
					{
						NSTimeInterval currentChrono;
						int usHour, usMinute;
						
						// Type
						if (COUNTDOWN == sClockMode)
							currentChrono = [self currentCountdown];
						else
							currentChrono = [self chronoTimeInterval];
						
						// Compute hours, minutes & seconds
						usHour = (int) (currentChrono / 3600);
						if (usHour > 11)
							usHour -= 12;
						usMinute = (int)((currentChrono - (usHour * 3600)) / 60);

						if(usMinute != tmpMinute || usHour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d", usHour, usMinute];
							tmpHour = usHour; tmpMinute = usMinute;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					break;
				case 1:
					if (CLOCK == sClockMode)
					{
						if (hour > 11)
							hour -= 12;
						
						if(second != tmpSecond || minute != tmpMinute || hour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d:%02d", hour, minute, second];
							tmpHour = hour; tmpMinute = minute; tmpSecond = second;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					else
					{
						NSTimeInterval currentChrono;
						int usHour, usMinute, usSecond;
						
						// Type
						if (COUNTDOWN == sClockMode)
							currentChrono = [self currentCountdown];
						else
							currentChrono = [self chronoTimeInterval];
						
						// Compute hours, minutes & seconds
						usHour = (int) (currentChrono / 3600);
						if (usHour > 11)
							usHour -= 12;
						usMinute = (int)((currentChrono - (usHour * 3600)) / 60);
						usSecond = (int)(currentChrono - (usHour * 3600) - (usMinute * 60));
						
						if(usSecond != tmpSecond || usMinute != tmpMinute || usHour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d:%02d", usHour, usMinute, usSecond];
							tmpHour = usHour; tmpMinute = usMinute; tmpSecond = usSecond;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					break;
				case 2:
					if (CLOCK == sClockMode)
					{
						if (ampm!=0 && hour<12)
							hour+=12;
						// Display
						if(minute != tmpMinute || hour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d", hour, minute];
							tmpHour = hour; tmpMinute = minute;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					else
					{
						NSTimeInterval currentChrono;
						int usHour, usMinute, usSecond;
						
						// Type
						if (COUNTDOWN == sClockMode)
							currentChrono = [self currentCountdown];
						else
							currentChrono = [self chronoTimeInterval];
						
						// Compute hours, minutes & seconds
						usHour = (int) (currentChrono / 3600);
						if (usHour > 11)
							usHour -= 12;
						usMinute = (int)((currentChrono - (usHour * 3600)) / 60);
						usSecond = (int)(currentChrono - (usHour * 3600) - (usMinute * 60));
						
						if(minute != tmpMinute || hour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d", hour, minute];
							tmpHour = hour; tmpMinute = minute;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					break;
				case 3:
				{
					if (CLOCK == sClockMode)
					{
						if (ampm!=0 && hour<12)
							hour+=12;
						
						if(second != tmpSecond || minute != tmpMinute || hour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d:%02d", hour, minute, second];
							tmpHour = hour; tmpMinute = minute; tmpSecond = second;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					else
					{
						NSTimeInterval currentChrono;
						int usHour, usMinute, usSecond;
						
						// Type
						if (COUNTDOWN == sClockMode)
							currentChrono = [self currentCountdown];
						else
							currentChrono = [self chronoTimeInterval];
						
						// Compute hours, minutes & seconds
						usHour = (int) (currentChrono / 3600);
						if (usHour > 11)
							usHour -= 12;
						usMinute = (int)((currentChrono - (usHour * 3600)) / 60);
						usSecond = (int)(currentChrono - (usHour * 3600) - (usMinute * 60));
						
						if(usSecond != tmpSecond || usMinute != tmpMinute || usHour != tmpHour)
						{
							[tmpString release];
							tmpString = [[NSString alloc] initWithFormat:@"%02d:%02d:%02d", usHour, usMinute, usSecond];
							tmpHour = usHour; tmpMinute = usMinute; tmpSecond = usSecond;
						}
						[self runDisplayDigitalTime:renderer andString:tmpString andRect:rc];
					}
					break;
				}
				default:
					break;
			}
			break;
		}
		case CALENDAR: // Calendar
		{
			if(tmpDay != day || tmpMonth != month || tmpYear != year)
			{
				tmpDay = day; tmpMonth = month; tmpYear = year;
				NSDateFormatter* sdf =  [[NSDateFormatter alloc] init];
				switch (sCalendarType)
				{
					case SHORTDATE:
						[sdf setDateStyle:NSDateFormatterShortStyle];
						break;
					case LONGDATE:
						[sdf setDateStyle:NSDateFormatterLongStyle];
						break;
					case FIXEDDATE:
						[sdf setDateFormat:FORMAT[sCalendarFormat]];
						break;
					default:
						break;
				}
				[tmpString release];
				tmpString = [[self computeDate:year andMonth:month andDayOfMonth:day andDayOfWeek:dayofweek andDateFormat:sdf] retain];
				[sdf release];
			}
			[self runDisplayCalendar:renderer andString:tmpString andRect:rc];
			break;
		}			
		default:
			break;
	}
}

-(void)runDisplayAnalogTime:(CRenderer*)renderer andHour:(int)sHour andMinutes:(int)sMinutes andSeconds:(int)sSeconds andRect:(CRect)rc andBoundRect:(CRect)bRect
{
	if(updateAnalog)
		[textSurface manualClear:crFont];

	int sRayon;
	// Set center
	vLocalCenter = Vec2f(bRect.width() / 2.0f, bRect.height() / 2.0f);
	vCenter = Vec2f(bRect.left, bRect.top) + vLocalCenter;

	// Set radius
	sRayon = (int)(MIN(rc.width(), rc.height()) / 2) - 1;

	float c12toDeg = 360.0f / 12.0f;
	float c60toDeg = 360.0f / 60.0f;

	// Display hours
	if (sAnalogClockHours)
	{
		float fractionOfHour = sMinutes * (12.0f / 360.0f) * 12.0f;
		float rad = degreesToRadians(sHour*c12toDeg-90 + fractionOfHour);
		vHour = vCenter + Vec2f(cosf(rad)*sRayon*0.6f, sinf(rad)*sRayon*0.6f);
		renderer->renderLine(vCenter, vHour, crAnalogClockHours, 2);
	}
	// Display minutes
	if (sAnalogClockMinutes)
	{
		float rad = degreesToRadians(sMinutes*c60toDeg-90);
		vMinute = vCenter + Vec2f(cosf(rad)*sRayon*0.95, sinf(rad)*sRayon*0.95);
		renderer->renderLine(vCenter, vMinute, crAnalogClockMinutes, 2);
	}
	// Display seconds
	if (sAnalogClockSeconds)
	{
		float rad = degreesToRadians(sSeconds*c60toDeg-90);
		vSecond = vCenter + Vec2f(cosf(rad)*sRayon*0.95, sinf(rad)*sRayon*0.95);
		renderer->renderLine(vCenter, vSecond, crAnalogClockSeconds, 1);
	}

	// Draw lines
	if (sAnalogClockLines)
	{
		for (int a = 1; a < 13; a++)
		{
			float rad = degreesToRadians(a*c12toDeg+90);
			float cosr = cosf(rad);
			float sinr = sinf(rad);
			Vec2f pA = Vec2f(cosr*sRayon*0.85f,	sinr*sRayon*0.85f);
			Vec2f pB = Vec2f(cosr*sRayon*0.95f,	sinr*sRayon*0.95f);
			renderer->renderLine(vCenter + pA, vCenter + pB, crFont, 2);
		}
	}

	// Draw markers
	if (updateAnalog && sAnalogClockMarkerType != 2)
	{
		updateAnalog = NO;
		NSString* szString;
		int textWidth;
		int textHeight;
		CRect rcFont;
		
		// Create font
		if (sFont == nil)
			return;
				
		// Display
		for (int a = 1; a <= 12; a++)
		{
			int x, y;
			if (!sAnalogClockMarkerType)
				szString = szNumbers[a - 1];
			else
				szString = szRoman[a - 1];

#ifdef __IPHONE_8_0
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			CGSize textSize;
			if([szString respondsToSelector:@selector(sizeWithAttributes:)])
				textSize = [szString sizeWithAttributes:@{NSFontAttributeName:hFont->font}];
			else
				textSize = [szString sizeWithFont:hFont->font];
#pragma clang diagnostic pop
#else
			CGSize textSize = [szString sizeWithFont:hFont->font];
#endif
			textWidth = textSize.width+2;
			textHeight = textSize.height;

			float rad = degreesToRadians(a*c12toDeg - 90);

			x = (int)(vLocalCenter.x + cosf(rad) * sRayon*1.02f);
			y = (int)(vLocalCenter.y + sinf(rad) * sRayon*1.02f);

			float corrX = (cosf(rad+M_PI)+1)*0.5f;
			float corrY = (sinf(rad+M_PI)+1)*0.5f;

			rcFont.left = x - corrX*textWidth;
			rcFont.top = y - corrY*textHeight;
			rcFont.right = rcFont.left + textWidth;
			rcFont.bottom = rcFont.top + textHeight;

			[textSurface manualDrawText:szString withFlags:0 andRect:rcFont andColor:crFont andFont:hFont];
		}
		[textSurface manualUploadTexture];
	}
	if(sAnalogClockMarkerType != 2)
	{
		[textSurface draw:renderer withX:bRect.left andY:bRect.top andEffect:0 andEffectParam:0];
	}
}

-(void)runDisplayDigitalTime:(CRenderer*)renderer andString:(NSString*)szTime andRect:(CRect)rc
{
	if (sFont == nil)
		return;

	[textSurface setText:szTime withFlags:DT_CENTER|DT_VCENTER andColor:crFont andFont:hFont];
	[textSurface draw:renderer withX:rc.left andY:rc.top andEffect:0 andEffectParam:0];
	
	// Draw border if needed
	// ANDOS TODO: Cannot yet draw outlines
	/*if (sClockBorder)
	{
		g.setStroke(new BasicStroke(2));
		g.setColor(crFont);
		g.drawRect(rc.left + 1, rc.top + 1, rc.right - rc.left, rc.bottom - rc.top);
	}*/
}

-(NSString*)computeDate:(short)sYear andMonth:(short)sMonth andDayOfMonth:(short)sDayOfMonth andDayOfWeek:(short)sDayOfWeek andDateFormat:(NSDateFormatter*)df
{
	NSDateComponents* cal = [[NSDateComponents alloc] init];
	[cal setYear:sYear];
	[cal setMonth:sMonth];
	[cal setDay:sDayOfMonth];
	[cal setWeekday:sDayOfWeek];
	NSDate* date = [currentCalendar dateFromComponents:cal];
	[cal release];
	return [df stringFromDate:date];
}

-(void)runDisplayCalendar:(CRenderer*)renderer andString:(NSString*)szDate andRect:(CRect)rc
{
	if (sFont == nil)
		return;
	
	[textSurface setText:szDate withFlags:DT_CENTER|DT_VCENTER andColor:crFont andFont:hFont];
	[textSurface draw:renderer withX:rc.left andY:rc.top andEffect:0 andEffectParam:0];
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_CMPCHRONO:
			return [self CmpChrono:cnd];
		case CND_NEWSECOND:
			return [self NewSecond];
		case CND_NEWMINUTE:
			return [self NewSecond];
		case CND_NEWHOUR:
			return [self NewSecond];
		case CND_NEWDAY:
			return [self NewSecond];
		case CND_NEWMONTH:
			return [self NewSecond];
		case CND_NEWYEAR:
			return [self NewSecond];
		case CND_CMPCOUNTDOWN:
			return [self CmpCountdown:cnd];
		case CND_VISIBLE:
			return [self IsVisible];
	}
	return false;//won't happen
}

-(BOOL)CmpChrono:(CCndExtension*)cnd
{
	return [cnd compareTime:rh withNum:0 andTime:[self chronoTimeInterval]*1000];
}

-(BOOL)NewSecond
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
		return YES;
	if (rh->rh4EventCount == sEventCount)
		return YES;
	return NO;
}

-(BOOL)CmpCountdown:(CCndExtension*)cnd
{
	NSTimeInterval currentChrono = [self currentCountdown];
	return [cnd compareTime:rh withNum:0 andTime:(int)(currentChrono*1000)];
}

-(BOOL)IsVisible
{
	return sVisible;
}


// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_SETCENTIEMES:
			[self SetCentiemes:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETSECONDES:
			[self SetSeconds:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETMINUTES:
			[self SetMinutes:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETHOURS:
			[self SetHours:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETDAYOFWEEK:
			[self SetDayOfWeek:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETDAYOFMONTH:
			[self SetDayOfMonth:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETMONTH:
			[self SetMonth:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETYEAR:
		   [self SetYear:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_RESETCHRONO:
			[self ResetChrono];
			break;
		case ACT_STARTCHRONO:
			[self StartChrono];
			break;
		case ACT_STOPCHRONO:
			[self StopChrono];
			break;
		case ACT_SHOW:
			[self Show];
			break;
		case ACT_HIDE:
			[self Hide];
			break;
		case ACT_SETPOSITION:
		{
			int point = [act getParamPosition:rh withNum:0];
			[self SetPositionX:LOWORD(point) andY:HIWORD(point)];
			break;
		}
		case ACT_SETCOUNTDOWN:
			[self SetCountdown:[act getParamTime:rh withNum:0]];
			break;
		case ACT_STARTCOUNTDOWN:
			[self StartCountdown];
			break;
		case ACT_STOPCOUNTDOWN:
			[self StopCountdown];
			break;
		case ACT_SETXPOSITION:
			[self SetXPosition:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETYPOSITION:
			[self SetYPosition:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETXSIZE:
			[self SetXSize:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETYSIZE:
			[self SetYSize:[act getParamExpression:rh withNum:0]];
			break;
	}
}


-(void)SetCentiemes:(int)hundredths
{
	if ((hundredths >= 0) && (hundredths < 100))
	{
		//ANDOS TODO: Cannot use milliseconds when using the NSDate classes, can only get them from NSTimeInterval
		
		/*NSDate* date = [self getCurrentTime];
		c.set(Calendar.MILLISECOND, hundredths * 10);
		changeTime(c.getTime());*/
			
		NSDate* date = [self getCurrentTime];
		[self changeTime:date];
		[ho redraw];
	}
}

-(void)SetSeconds:(int)secs
{
	if ((secs >= 0) && (secs < 60))
	{
		NSDate* date = [self getCurrentTime];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitSecond fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSSecondCalendarUnit fromDate:date];
#endif
		[comp setSecond:secs];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)SetMinutes:(int)mins
{
	if ((mins >= 0) && (mins < 60))
	{
		NSDate* date = [self getCurrentTime];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitMinute fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSMinuteCalendarUnit fromDate:date];
#endif
		[comp setMinute:mins];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)SetHours:(int)hours
{
	if ((hours >= 0) && (hours < 24))
	{
		NSDate* date = [self getCurrentTime];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitHour fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSHourCalendarUnit fromDate:date];
#endif
		[comp setHour:hours];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)SetDayOfWeek:(int)day
{
	if ((day >= 0) && (day < 7))
	{
		NSDate* date = [NSDate date];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitWeekday fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSWeekdayCalendarUnit fromDate:date];
#endif
		[comp setWeekday:day];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)SetDayOfMonth:(int)day
{
	if ((day >= 1) && (day < 32)) //1 based from c++
	{
		NSDate* date = [NSDate date];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitDay fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSDayCalendarUnit fromDate:date];
#endif
		[comp setDay:day];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)SetMonth:(int)month
{
	if ((month >= 1) && (month < 13)) //1 based from c++
	{
		NSDate* date = [self getCurrentTime];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitMonth fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSMonthCalendarUnit fromDate:date];
#endif
		[comp setMonth:month];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)SetYear:(int)year
{
	if ((year > 1979) && (year < 2100)) //y2.1k
	{
		NSDate* date = [self getCurrentTime];
#ifdef __IPHONE_8_0
		NSDateComponents* comp = [currentCalendar components:NSCalendarUnitYear fromDate:date];
#else
		NSDateComponents* comp = [currentCalendar components:NSYearCalendarUnit fromDate:date];
#endif
		[comp setYear:year];
		[self changeTime:[comp date]];
		[ho redraw];
	}
}

-(void)ResetChrono
{
	if(startTimer != nil)
		[startTimer release];

	if(stopTimer != nil)
		[stopTimer release];
	
	startTimer = nil;
	stopTimer = nil;
}

-(void)StartChrono
{
	//Set the starttimer back in time the amount it currently is on.
	if(startTimer != nil)
	{
		NSDate* newStartTimer= [[NSDate alloc] initWithTimeIntervalSinceNow:-[self chronoTimeInterval]];
		[startTimer release];
		startTimer = newStartTimer;
	}
	else 
		startTimer = [[NSDate alloc] init];
		
	if(stopTimer != nil)
		[stopTimer release];
	stopTimer = nil;
}

-(void)StopChrono
{
	if(stopTimer == nil)
		stopTimer = [[NSDate alloc] init];
}

-(void)Show
{
	if (!sVisible)
	{
		sVisible = true;
		[ho redraw];
	}
}

-(void)Hide
{
	if (sVisible)
	{
		sVisible = false;
		[ho redraw];
	}
}

-(void)SetPositionX:(int)x andY:(int)y
{
	[ho setPosition:x withY:y];
	[ho redraw];
}

-(void)SetCountdown:(int)time
{
	[self StopCountdown];	
	countdownStart = (NSTimeInterval)(time/1000.0);
	[ho redraw];
}

-(void)StartCountdown
{	
	if(stopTimer != nil)
		return;

	stopTimer = [[NSDate alloc] initWithTimeIntervalSinceNow:countdownStart];
}

-(void)StopCountdown
{
	countdownStart = [self currentCountdown];

	if(stopTimer != nil)
		[stopTimer release];
	stopTimer = nil;
}

-(void)SetXPosition:(int)x
{
	[ho setX:x];
	[ho redraw];
}

-(void)SetYPosition:(int)y
{
	[ho setY:y];
	[ho redraw];
}

-(void)SetXSize:(int)w
{
	updateAnalog = YES;
	[ho setWidth:w];
	[ho redraw];
}

-(void)SetYSize:(int)h
{
	updateAnalog = YES;
	[ho setHeight:h];
	[ho redraw];
}



// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETCENTIEMES:
			return [self GetCentiemes];
		case EXP_GETSECONDES:
			return [self GetSeconds];
		case EXP_GETMINUTES:
			return [self GetMinutes];
		case EXP_GETHOURS:
			return [self GetHours];
		case EXP_GETDAYOFWEEK:
			return [self GetDayOfWeek];
		case EXP_GETDAYOFMONTH:
			return [self GetDayOfMonth];
		case EXP_GETMONTH:
			return [self GetMonth];
		case EXP_GETYEAR:
			return [self GetYear];
		case EXP_GETCHRONO:
			return [self GetChrono];
		case EXP_GETCENTERX:
			return [self GetCentreX];
		case EXP_GETCENTERY:
			return [self GetCentreY];
		case EXP_GETHOURX:
			return [self GetHourX];
		case EXP_GETHOURY:
			return [self GetHourY];
		case EXP_GETMINUTEX:
			return [self GetMinuteX];
		case EXP_GETMINUTEY:
			return [self GetMinuteY];
		case EXP_GETSECONDX:
			return [self GetSecondX];
		case EXP_GETSECONDY:
			return [self GetSecondY];
		case EXP_GETCOUNTDOWN:
			return [self GetCountdown];
		case EXP_GETXPOSITION:
			return [self GetXPosition];
		case EXP_GETYPOSITION:
			return [self GetYPosition];
		case EXP_GETXSIZE:
			return [self GetXSize];
		case EXP_GETYSIZE:
			return [self GetYSize];
	}
	return [rh getTempValue:0];//won't happen
}


-(CValue*)GetCentiemes
{
	NSTimeInterval tmp = [[NSDate date] timeIntervalSinceReferenceDate];
	int centimes = 99-(int)((ceil(tmp)-tmp)*100.0);
	return [rh getTempValue:centimes];
}

-(CValue*)GetSeconds
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitSecond fromDate:[NSDate date]];
#else
	NSDateComponents* comp = [currentCalendar components:NSSecondCalendarUnit fromDate:[NSDate date]];
#endif
	return [rh getTempValue:(int)[comp second]];
}

-(CValue*)GetMinutes
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitMinute fromDate:[NSDate date]];
#else
	NSDateComponents* comp = [currentCalendar components:NSMinuteCalendarUnit fromDate:[NSDate date]];
#endif
	return [rh getTempValue:(int)[comp minute]];
}

-(CValue*)GetHours
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitHour fromDate:[NSDate date]];
#else
	NSDateComponents* comp = [currentCalendar components:NSHourCalendarUnit fromDate:[NSDate date]];
#endif

	int hour=(int)[comp hour];
	int ampm=0;
	if (ampm!=0 && hour<12)
	{
		hour+=12;
	}
	return [rh getTempValue:hour];
}

-(CValue*)GetDayOfWeek
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitWeekday fromDate:[NSDate date]];
#else
	NSDateComponents* comp = [currentCalendar components:NSWeekdayCalendarUnit fromDate:[NSDate date]];
#endif
	return [rh getTempValue:(int)[comp weekday]-1];
}

-(CValue*)GetDayOfMonth
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitDay fromDate:[NSDate date]];
#else
	NSDateComponents* comp = [currentCalendar components:NSDayCalendarUnit fromDate:[NSDate date]];
#endif
	return [rh getTempValue:(int)[comp day]];
}

-(CValue*)GetMonth
{
#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitMonth fromDate:[NSDate date]];
#else
	NSDateComponents* comp = [currentCalendar components:NSMonthCalendarUnit fromDate:[NSDate date]];
#endif
	return [rh getTempValue:(int)[comp month]];
}

-(CValue*)GetYear
{
	NSDate* date = [self getCurrentTime];


#ifdef __IPHONE_8_0
	NSDateComponents* comp = [currentCalendar components:NSCalendarUnitYear fromDate:date];
#else
	NSDateComponents* comp = [currentCalendar components:NSYearCalendarUnit fromDate:date];
#endif
	return [rh getTempValue:(int)[comp year]];
}

-(CValue*)GetChrono
{
	return [rh getTempValue:(int)([self chronoTimeInterval]*100)];
}

-(CValue*)GetCentreX
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vCenter.x];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetCentreY
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vCenter.y];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetHourX
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vHour.x];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetHourY
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vHour.y];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetMinuteX
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vMinute.x];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetMinuteY
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vMinute.y];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetSecondX
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vSecond.x];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetSecondY
{
	if (ANALOG_CLOCK == sType)
	{
		return [rh getTempValue:vSecond.y];
	}
	else
	{
		return [rh getTempValue:0];
	}
}

-(CValue*)GetCountdown
{
	return [rh getTempValue:(int)([self currentCountdown]*100)];
}

-(CValue*)GetXPosition
{
	return [rh getTempValue:[ho getX]];
}

-(CValue*)GetYPosition
{
	return [rh getTempValue:[ho getY]];
}

-(CValue*)GetXSize
{
	return [rh getTempValue:[ho getWidth]];
}

-(CValue*)GetYSize
{
	return [rh getTempValue:[ho getHeight]];
}

@end
