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
// CRunWargameMap: Wargame Map object
// fin 29/01/09
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;

#define SETS_OPEN_SET 1
#define SETS_CLOSED_SET 2
#define INF_TILE_COST 99

#define CND_COMPARETILECOST  0
#define CND_TILEIMPASSABLE  1
#define CND_PATHEXISTS  2
#define CND_COMPAREPATHCOST  3
#define CND_COMPAREPATHLENGTH  4
#define CND_COMPARECOSTTOPOINT  5
#define CND_COMPAREPOINTDIRECTION  6
#define CND_COMPARECOSTTOCURRENT  7
#define CND_COMPARECURRENTDIRECTION  8
#define CND_EXTENDOFPATH  9
#define ACT_EXTSETWIDTH  0
#define ACT_EXTSETHEIGHT  1
#define ACT_SETCOST  2
#define ACT_CALCULATEPATH  3
#define ACT_NEXTPOINT  4
#define ACT_PREVPOINT  5
#define ACT_RESETPOINT  6
#define ACT_CALCULATELOS  7
#define EXP_EXTGETWIDTH  0
#define EXP_EXTGETHEIGHT  1
#define EXP_GETTILECOST  2
#define EXP_GETPATHCOST  3
#define EXP_GETPATHLENGTH  4
#define EXP_GETCOSTTOPOINT  5
#define EXP_GETPOINTDIRECTION  6
#define EXP_GETPOINTX  7
#define EXP_GETPOINTY  8
#define EXP_GETSTARTX  9
#define EXP_GETSTARTY  10
#define EXP_GETDESTX  11
#define EXP_GETDESTY  12
#define EXP_GETCURRENTINDEX  13
#define EXP_GETCOSTTOCURRENT  14
#define EXP_GETCURRENTDIRECTION  15
#define EXP_GETCURRENTX  16
#define EXP_GETCURRENTY  17
#define EXP_GETCOSTATPOINT  18
#define EXP_GETCOSTATCURRENT  19



@interface WargameMapPathPoint : NSObject
{
@public
	int x;
	int y;
	int cumulativeCost;	
}
-(id)initParams:(int)xx withParam1:(int)yy andParam2:(int)cc;
@end

@interface CRunWargameMap : CRunExtension
{
    int mapWidth;
	int mapHeight;
    BOOL oddColumnsHigh;
    unsigned char* map;
    CArrayList* path; //WargameMapPathPoint
    int iterator;
    int startX;
	int startY;
	int destX;
	int destY;	
}

@end
