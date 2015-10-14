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
// CRuniOS
//
//----------------------------------------------------------------------------------
#import "CRuniOS.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CIAdViewController.h"
#import "CRunApp.h"
#import "Reachability.h"

#import <AudioToolbox/AudioToolbox.h>
#ifdef __IPHONE_7_0
#import <GameController/GameController.h>
#endif

#define CND_ADOK 0
#define CND_REACTIVATED 1
#define CND_DEACTIVATED 2
#define CND_MEMORYWARNING 3
#define CND_IADSHOWN 4

#define CND_ISCONNECTED 5
#define CND_ISCONNECTED_WWAN 6
#define CND_ISCONNECTED_WIFI 7
#define CND_ISCONNECTED_LOCALWIFI 8
#define CND_CANCONNECTTOHOST 9
#define CND_CANCONNECTTOHOST_WWAN 10
#define CND_CANCONNECTTOHOST_WIFI 11
#define CND_LAST 12

#define ACT_OPENURL 0
#define ACT_VIBRATE 1
#define ACT_AUTHORISEIAD 2

#define EXP_UNIQUEIDENTIFIER 0
#define EXP_NAME 1
#define EXP_SYSTEMNAME 2
#define EXP_SYSTEMVERSION 3
#define EXP_MODEL 4
#define EXP_LOCALIZEDMODEL 5
#define EXP_PREFERREEDLANGUAGE 6
#define EXP_NUMPREFERREDLANGUAGES 7

@implementation CRuniOS

-(int)getNumberOfConditions
{
	return CND_LAST;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    reactivatedCount=-1;
    ho->hoAdRunHeader->rhApp->iOSObject=ho;
    return YES;
}
-(int)handleRunObject
{
    return REFLAG_ONESHOT;
}
-(void)destroyRunObject:(BOOL)bFast
{
    ho->hoAdRunHeader->rhApp->iOSObject=nil;
}

// Conditions
// -------------------------------------------------
-(BOOL)reactivatedCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == reactivatedCount)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)memoryWarningCnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	return NO;    
}
-(BOOL)iAdShown
{
    if (rh->rhApp->iAdViewController!=nil)
    {
        return rh->rhApp->iAdViewController->bShown;
    }
    return NO;
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    switch(num)
    {
        case CND_ADOK:
            if (rh->rhApp->iAdViewController!=nil)
            {
                return rh->rhApp->iAdViewController->bAdOK;
            }
            return YES;
        case CND_REACTIVATED:
            return [self reactivatedCnd];
        case CND_DEACTIVATED:
            return YES;
		case CND_MEMORYWARNING:
			return [self memoryWarningCnd];
		case CND_IADSHOWN:
			return [self iAdShown];
		case CND_ISCONNECTED:
			return [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] != NotReachable;
		case CND_ISCONNECTED_WWAN:
			return [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWWAN;
		case CND_ISCONNECTED_WIFI:
			return [[Reachability reachabilityForInternetConnection] currentReachabilityStatus] == ReachableViaWiFi;
		case CND_ISCONNECTED_LOCALWIFI:
			return [[Reachability reachabilityForLocalWiFi] currentReachabilityStatus] != NotReachable;
		case CND_CANCONNECTTOHOST:
			return [[Reachability reachabilityWithHostName:[cnd getParamExpString:rh withNum:0]] currentReachabilityStatus] != NotReachable;
		case CND_CANCONNECTTOHOST_WWAN:
			return [[Reachability reachabilityWithHostName:[cnd getParamExpString:rh withNum:0]] currentReachabilityStatus] == ReachableViaWWAN;
		case CND_CANCONNECTTOHOST_WIFI:
			return [[Reachability reachabilityWithHostName:[cnd getParamExpString:rh withNum:0]] currentReachabilityStatus] == ReachableViaWiFi;
    }
    return NO;
}

-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_NAME:
			return [rh getTempString:[UIDevice currentDevice].name];
		case EXP_SYSTEMNAME:
			return [rh getTempString:[UIDevice currentDevice].systemName];
		case EXP_SYSTEMVERSION:
			return [rh getTempString:[UIDevice currentDevice].systemVersion];
		case EXP_MODEL:
			return [rh getTempString:[UIDevice currentDevice].model];
		case EXP_LOCALIZEDMODEL:
			return [rh getTempString:[UIDevice currentDevice].localizedModel];
			
		case EXP_PREFERREEDLANGUAGE:
		{
			NSArray* languages = [NSLocale preferredLanguages];
			int index = [[ho getExpParam] getInt];
			
			if(index < 0 || index >= languages.count)
				return [rh getTempString:@""];
				
			return [rh getTempString:[languages objectAtIndex:index]];		
		}
			
		case EXP_NUMPREFERREDLANGUAGES:
			return [rh getTempValue:(int)[NSLocale preferredLanguages].count];
	}
	return [rh getTempString:@""];
}

// Actions
// -------------------------------------------------

-(void)actOpenURL:(CActExtension*)act
{
    NSString* url=[act getParamExpString:rh withNum:0];
	if([url hasPrefix:@"fusion://"])
	{
		NSString* function = [url substringFromIndex:9];
#ifdef __IPHONE_7_0
		if([function isEqualToString:@"startWirelessControllerDiscovery"])
		{
			if(SYSTEM_VERSION_GREATER_THAN_OR_EQUAL_TO(@"7.0"))
			{
				[GCController startWirelessControllerDiscoveryWithCompletionHandler:^{
					NSLog(@"Wireless controller discovery ended");
				}];
			}
			return;
		}
#endif
		if([function isEqualToString:@"dismissKeyboard"])
		{
			NSArray* windows = [[UIApplication sharedApplication] windows];
			if(windows.count > 0)
				[[windows objectAtIndex:0] resignFirstResponder];
			return;
		}
	}
	else
		[[UIApplication sharedApplication] openURL:[NSURL URLWithString:url]];
}
-(void)actAuthoriseIAd:(CActExtension*)act
{
    BOOL bOn=[act getParamExpression:rh withNum:0];
    if (rh->rhApp->iAdViewController!=nil)
    {
        [rh->rhApp->iAdViewController setAdAuthorised:bOn];
    }
}
-(void)action:(int)num withActExtension:(CActExtension*)act
{
    switch(num)
    {
        case ACT_OPENURL:
            [self actOpenURL:act];
            break;
        case ACT_VIBRATE:
            AudioServicesPlaySystemSound(kSystemSoundID_Vibrate);
            break;
        case ACT_AUTHORISEIAD:
            [self actAuthoriseIAd:act];
            break;
    }
}
@end
