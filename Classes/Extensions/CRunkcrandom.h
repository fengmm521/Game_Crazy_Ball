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
// CRunkcrandom: Randomizer object
// fin 26/09/09
//greyhill
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;

#define CND_RAND_EVENT		0
#define CND_RAND_EVENT_GROUP	 1
#define CND_RAND_EVENT_GROUP_CUST 	2
#define ACT_NEW_SEED		0
#define ACT_SET_SEED		1
#define ACT_TRIGGER_RAND_EVENT_GROUP		2
#define ACT_TRIGGER_RAND_EVENT_GROUP_CUST 	3
#define EXP_EXTRANDOM					0
#define EXP_RANDOM_MIN_MAX			1
#define EXP_GET_SEED				2
#define EXP_RANDOM_LETTER			3
#define EXP_RANDOM_ALPHANUM			4
#define EXP_RANDOM_CHAR				5
#define EXP_ASCII_TO_CHAR			6
#define EXP_CHAR_TO_ASCII			7
#define EXP_TO_UPPER				8
#define EXP_TO_LOWER				9

@interface CRunkcrandom : CRunExtension
{
    NSString*		currentGroupName;
    int				currentPercentMax;
    int				currentPosition;
    int				currentRandom;
    int				globalPercentMax;
    int				globalPosition;
    int				globalRandom;
    int				lastSeed;	
}
-(CValue*)toLower;
-(CValue*)toUpper;
-(CValue*)GetCharToAscii:(NSString*)c; 
-(CValue*)GetAsciiToChar:(int)ascii;
-(CValue*)GetRandomChar;
-(CValue*)GetRandomAlphaNum;
-(CValue*)GetRandomLetter;
-(CValue*)expression:(int)num;
-(void)TriggerRandomEventGroupCustom:(CActExtension*)act;
-(void)TriggerRandomEventGroup:(CActExtension*)act;
-(void)SetSeed:(CActExtension*)act;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(BOOL)RandomEventGroupCustom:(CCndExtension*)cnd;
-(BOOL)RandomEventGroup:(CCndExtension*)cnd ;
-(BOOL)RandomEvent:(CCndExtension*)cnd;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(int)randommm:(int)min withMax:(int)max;
-(int)_random:(int)max;
-(void)setseed:(int)pSeed;
-(int)newseed;
-(void)destroyRunObject:(BOOL)bFast;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)getNumberOfConditions;

@end
