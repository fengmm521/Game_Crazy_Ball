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
// CRunkcwctrl
//
//----------------------------------------------------------------------------------
#import "CRunkcwctrl.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CActExtension.h"
#import "CRunApp.h"


#define CND_ISICONIC 0
#define CND_ISMAXIMIZED 1
#define CND_ISVISIBLE 2
#define CND_ISAPPACTIVE 3
#define CND_HASFOCUS 4
#define CND_ISATTACHEDTODESKTOP 5
#define CND_LAST 6

#define ACT_SETBACKCOLOR 23

#define EXP_GETXPOSITION 0
#define EXP_GETYPOSITION 1
#define EXP_GETXSIZE 2
#define EXP_GETYSIZE 3
#define EXP_GETSCREENXSIZE 4
#define EXP_GETSCREENYSIZE 5
#define EXP_GETSCREENDEPTH 6
#define EXP_GETCLIENTXSIZE 7
#define EXP_GETCLIENTYSIZE 8
#define EXP_GETTITLE 9
#define EXP_GETBACKCOLOR 10
#define EXP_GETXFRAME 11
#define EXP_GETYFRAME 12
#define EXP_GETWFRAME 13
#define EXP_GETHFRAME 14

@implementation CRunkcwctrl

-(int)getNumberOfConditions
{
	return CND_LAST;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    return YES;
}
-(int)handleRunObject
{
    return REFLAG_ONESHOT;
}
-(void)destroyRunObject:(BOOL)bFast
{
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension *)cnd
{
    switch(num)
    {
        case CND_ISICONIC:
            return NO;
        case CND_ISMAXIMIZED:
            return YES;
        case CND_ISVISIBLE:
            return YES;
        case CND_ISAPPACTIVE:
            return YES;
        case CND_HASFOCUS:
            return YES;
        case CND_ISATTACHEDTODESKTOP:
            return NO;
    }
    return NO;
}

-(void)action:(int)num withActExtension:(CActExtension *)act
{
    if (num==ACT_SETBACKCOLOR)
    {        
        rh->rhApp->gaBorderColour=[act getParamColour:rh withNum:0];
    }
}

-(CValue*)expression:(int)num
{
    int ret=0;
    switch (num)
    {
        case EXP_GETXPOSITION:
            break;
        case EXP_GETYPOSITION:
            break;
        case EXP_GETXSIZE:
            ret = rh->rhApp->gaCxWin;
            break;
        case EXP_GETYSIZE:
            ret = rh->rhApp->gaCyWin;
            break;
        case EXP_GETSCREENXSIZE:
            ret = [rh->rhApp screenSize].width;
            break;
        case EXP_GETSCREENYSIZE:
            ret = [rh->rhApp screenSize].height;
            break;
        case EXP_GETSCREENDEPTH:
            ret=32;
            break;
        case EXP_GETCLIENTXSIZE:
            ret = rh->rhApp->gaCxWin;
            break;
        case EXP_GETCLIENTYSIZE:
            ret = rh->rhApp->gaCyWin;
            break;
        case EXP_GETTITLE:
			return [rh getTempString:@""];
        case EXP_GETBACKCOLOR:
            ret=rh->rhApp->gaBorderColour;
            break;
        case EXP_GETXFRAME:
            ret=0;
            break;            
        case EXP_GETYFRAME:
            ret=0;
            break;            
        case EXP_GETWFRAME:
            ret = rh->rhApp->gaCxWin;
            break;
        case EXP_GETHFRAME:
            ret = rh->rhApp->gaCyWin;
            break;
    }
    return [rh getTempValue:ret];
}

@end
