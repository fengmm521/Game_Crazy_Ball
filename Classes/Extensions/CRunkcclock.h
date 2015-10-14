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
// CRunkcclock: date & time object
//
//----------------------------------------------------------------------------------



@class CCndExtension;
@class CActExtension;
@class CTextSurface;
@class CFont;

#import "CRunExtension.h"
#import "CPoint.h"
#import "CoreMath.h"

@interface CRunkcclock : CRunExtension
{
	short ADJ;
    short sType;
    short sClockMode;
    BOOL sClockBorder;
    BOOL sAnalogClockLines;
    short sAnalogClockMarkerType;
    CFontInfo* sFont;
	CFont* hFont;
    int crFont;
    BOOL sAnalogClockSeconds;
    int crAnalogClockSeconds;
    BOOL sAnalogClockMinutes;
    int crAnalogClockMinutes;
    BOOL sAnalogClockHours;
    int crAnalogClockHours;
    short sDigitalClockType;
    short sCalendarType;
    short sCalendarFormat;
	
    short sMinWidth;
    short sMinHeight;
    BOOL sVisible;
	
	NSDate* initialTimer;
    NSDate* startTimer;
	NSDate* stopTimer;
	NSTimeInterval countdownStart;
	NSCalendar* currentCalendar;

    BOOL sDisplay;
    short sEventCount;
	Vec2f vCenter;
	Vec2f vLocalCenter;
	Vec2f vHour;
	Vec2f vMinute;
	Vec2f vSecond;
	CTextSurface* textSurface;
	BOOL updateAnalog;
	
	NSInteger prevSecond;
	NSInteger prevMinute;
	NSInteger prevHour;
	NSInteger prevDay;
	NSInteger prevMonth;
	NSInteger prevYear;
	
	NSString* tmpString;
	NSInteger tmpSecond;
	NSInteger tmpMinute;
	NSInteger tmpHour;
	NSInteger tmpDay;
	NSInteger tmpMonth;
	NSInteger tmpYear;
}

-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(NSDate*)getCurrentTime;
-(double)getChronoFromDate:(NSDate*)date;
-(NSTimeInterval)chronoTimeInterval;
-(void)changeTime:(NSDate*)date;
-(int)handleRunObject;
-(void)displayRunObject:(CRenderer*)renderer;
-(void)runDisplayAnalogTime:(CRenderer*)renderer andHour:(int)sHour andMinutes:(int)sMinutes andSeconds:(int)sSeconds andRect:(CRect)rc andBoundRect:(CRect)bRect;
-(void)runDisplayDigitalTime:(CRenderer*)renderer andString:(NSString*)szTime andRect:(CRect) rc;
-(NSString*)computeDate:(short)sYear andMonth:(short)sMonth andDayOfMonth:(short)sDayOfMonth andDayOfWeek:(short)sDayOfWeek andDateFormat:(NSDateFormatter*)df;
-(void)runDisplayCalendar:(CRenderer*)renderer andString:(NSString*)szDate andRect:(CRect)rc;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;


// Conditions
// --------------------------------------------------
-(BOOL)CmpChrono:(CCndExtension*)cnd;
-(BOOL)NewSecond;
-(BOOL)CmpCountdown:(CCndExtension*)cnd;	
-(BOOL)IsVisible;

// Actions
// -------------------------------------------------
-(void)SetCentiemes:(int)hundredths;
-(void)SetSeconds:(int)secs;
-(void)SetMinutes:(int)mins;
-(void)SetHours:(int)hours;
-(void)SetDayOfWeek:(int)day;
-(void)SetDayOfMonth:(int)day;
-(void)SetMonth:(int)month;
-(void)SetYear:(int)year;
-(void)ResetChrono;
-(void)StartChrono;
-(void)StopChrono;
-(void)Show;
-(void)Hide;
-(void)SetPositionX:(int)x andY:(int)y;
-(void)SetCountdown:(int)time;
-(void)StartCountdown;
-(void)StopCountdown;
-(void)SetXPosition:(int)x;
-(void)SetYPosition:(int)y;
-(void)SetXSize:(int)w;
-(void)SetYSize:(int)h;

// Expressions
// --------------------------------------------
-(CValue*)GetCentiemes;
-(CValue*)GetSeconds;
-(CValue*)GetMinutes;
-(CValue*)GetHours;
-(CValue*)GetDayOfWeek;
-(CValue*)GetDayOfMonth;
-(CValue*)GetMonth;
-(CValue*)GetYear;
-(CValue*)GetChrono;
-(CValue*)GetCentreX;
-(CValue*)GetCentreY;
-(CValue*)GetHourX;
-(CValue*)GetHourY;
-(CValue*)GetMinuteX;
-(CValue*)GetMinuteY;
-(CValue*)GetSecondX;
-(CValue*)GetSecondY;
-(CValue*)GetCountdown;
-(CValue*)GetXPosition;
-(CValue*)GetYPosition;
-(CValue*)GetXSize;
-(CValue*)GetYSize;
@end
