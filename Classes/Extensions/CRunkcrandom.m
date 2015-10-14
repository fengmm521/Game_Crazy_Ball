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
#import "CRunkcrandom.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"

@implementation CRunkcrandom

-(int)getNumberOfConditions
{
	return 3;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	currentGroupName=nil;
	lastSeed = [self newseed];
	return YES;
}
-(void)destroyRunObject:(BOOL)bFast
{
	if (currentGroupName!=nil)
	{
		[currentGroupName release];
	}
}

-(int)newseed
{
	return (int)time(NULL);
}
-(void)setseed:(int)pSeed
{
	srand(pSeed);
}
-(int)_random:(int)max
{
	return (rand()*RAND_MAX)/max;
}
-(int)randommm:(int)min withMax:(int)max
{
	return [self _random:max-min]+min;
}
	
// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_RAND_EVENT:
			return [self RandomEvent:cnd];
		case CND_RAND_EVENT_GROUP:
			return [self RandomEventGroup:cnd];
		case CND_RAND_EVENT_GROUP_CUST:
			return [self RandomEventGroupCustom:cnd];
	}
	return NO;//won't happen
}

-(BOOL)RandomEvent:(CCndExtension*)cnd
{
	int p=[cnd getParamExpression:rh withNum:0];
	if ([self _random:100] < p)
		return YES;
	return NO;
}
-(BOOL)RandomEventGroup:(CCndExtension*)cnd 
{
	int p=[cnd getParamExpression:rh withNum:0];
	globalPosition += p;
	if ((globalRandom >= globalPosition - p) &&
		(globalRandom < globalPosition))
		return YES;
	return NO;
}
-(BOOL)RandomEventGroupCustom:(CCndExtension*)cnd
{
	NSString* name=[cnd getParamExpString:rh withNum:0];
	int p=[cnd getParamExpression:rh withNum:1];
	if ([currentGroupName compare:name]==0) 
	{
		currentPosition += p;
		if ((currentRandom >= currentPosition - p) &&
			(currentRandom < currentPosition))
			return YES;
	}
	return NO;
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{        
		case ACT_NEW_SEED:
			lastSeed = [self newseed];
			break;        
		case ACT_SET_SEED:
			[self SetSeed:act];
			break;
		case ACT_TRIGGER_RAND_EVENT_GROUP:
			[self TriggerRandomEventGroup:act];
			break;
		case ACT_TRIGGER_RAND_EVENT_GROUP_CUST:
			[self TriggerRandomEventGroupCustom:act];
			break;
	}
}

-(void)SetSeed:(CActExtension*)act
{
	int pSeed=[act getParamExpression:rh withNum:0];
	lastSeed = pSeed;
	[self setseed:pSeed];
}

-(void)TriggerRandomEventGroup:(CActExtension*)act
{
	int pPercentMax=[act getParamExpression:rh withNum:0];
	globalPercentMax = pPercentMax;
	if (globalPercentMax <= 0){
		globalPercentMax = 100;
	}
	globalRandom = [self _random:globalPercentMax];
	globalPosition = 0;
	[ho generateEvent:CND_RAND_EVENT_GROUP withParam:[ho getEventParam]];
}

-(void)TriggerRandomEventGroupCustom:(CActExtension*)act
{
	NSString* name=[act getParamExpString:rh withNum:0];
	int pPercentMax=[act getParamExpression:rh withNum:1];
	int		lastPercentMax = currentPercentMax;
	int		lastRandom = currentRandom;
	int		lastPosition = currentPosition;
	NSString* lastGroupName = currentGroupName;
	
	currentGroupName = name;
	currentPercentMax = pPercentMax;
	if (currentPercentMax <= 0)
		currentPercentMax = 100;
	currentRandom = [self _random:currentPercentMax];
	currentPosition = 0;
	[ho generateEvent:CND_RAND_EVENT_GROUP_CUST withParam:[ho getEventParam]];
	currentPercentMax = lastPercentMax;
	currentRandom = lastRandom;
	currentPosition = lastPosition;
	currentGroupName = lastGroupName;
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_EXTRANDOM:
			return [rh getTempValue:[self _random:[[ho getExpParam] getInt]]];
		case EXP_RANDOM_MIN_MAX:
		{
			int p1=[[ho getExpParam] getInt];
			int p2=[[ho getExpParam] getInt];
			return [rh getTempValue:[self randommm:p1 withMax:p2]];
		}
		case EXP_GET_SEED:
			return [rh getTempValue:lastSeed];
		case EXP_RANDOM_LETTER:
			return [self GetRandomLetter];
		case EXP_RANDOM_ALPHANUM:
			return [self GetRandomAlphaNum];
		case EXP_RANDOM_CHAR:
			return [self GetRandomChar];
		case EXP_ASCII_TO_CHAR:
			return [self GetAsciiToChar:[[ho getExpParam] getInt]];
		case EXP_CHAR_TO_ASCII:
			return [self GetCharToAscii:[[ho getExpParam] getString]];
		case EXP_TO_UPPER:
			return [self toUpper];
		case EXP_TO_LOWER:
			return [self toLower];
	}
	return [rh getTempValue:0];//won't be used
}
-(CValue*)GetRandomLetter
{
	unsigned char buffer[1];
    NSString* pString;
    do 
    {
        buffer[0] = (unsigned char)[self randommm:97 withMax:122];
//        pString=[[[NSString alloc] initWithBytes:buffer length:1 encoding:NSWindowsCP1252StringEncoding] autorelease];
		pString=[[[NSString alloc] initWithBytes:buffer length:1 encoding:NSASCIIStringEncoding] autorelease];
    }while(pString==nil);
	CValue* ret=[rh getTempValue:0];
	[ret forceString:pString];
	return ret;
}
-(CValue*)GetRandomAlphaNum
{
	unsigned char b = (unsigned char)[self _random:36];
	if (b < 10)
	{
		b += 48;
	} 
	else 
	{
		b += 87;
	}
	unsigned char buffer[1];
	buffer[0] = b;
	NSString* pString=[[[NSString alloc] initWithBytes:buffer length:1 encoding:NSWindowsCP1252StringEncoding] autorelease];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:pString];
	return ret;
}
-(CValue*)GetRandomChar
{
	unsigned char b = (unsigned char)([self _random:254]+1);
	unsigned char buffer[1];
	buffer[0] = b;
	NSString* pString=[[[NSString alloc] initWithBytes:buffer length:1 encoding:NSWindowsCP1252StringEncoding] autorelease];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:pString];
	return ret;
}
-(CValue*)GetAsciiToChar:(int)ascii
{
	if (ascii==0)
	{
		ascii=32;
	}
	unsigned char buffer[1];
	buffer[0] = (unsigned char)ascii;
	NSString* pString=[[[NSString alloc] initWithBytes:buffer length:1 encoding:NSWindowsCP1252StringEncoding] autorelease];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:pString];
	return ret;
}
-(CValue*)GetCharToAscii:(NSString*)c 
{
	if ([c length] > 0)
	{
		return [rh getTempValue:(int)[c characterAtIndex:0]];
	}
	return [rh getTempValue:0];
}
-(CValue*)toUpper
{
	NSString* pString=[[ho getExpParam] getString];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:[pString uppercaseString]];
	return ret;
}
-(CValue*)toLower
{
	NSString* pString=[[ho getExpParam] getString];
	CValue* ret=[rh getTempValue:0];
	[ret forceString:[pString lowercaseString]];
	return ret;
}

@end
