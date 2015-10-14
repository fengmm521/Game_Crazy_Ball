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
// CRunAdvDir: Advanced Direction object
// fin 
//
//----------------------------------------------------------------------------------
#import "CRunAdvDir.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CPoint.h"
#import "CArrayList.h"
#import "CFile.h"
#import "CServices.h"
#import "CCndExtension.h"
#import "CActExtension.h"
#import "CObject.h"
#import "CExtension.h"
#import "CValue.h"

@implementation CRunAdvDir

-(int)getNumberOfConditions
{
	return 2;
}
/*
-(NSString*)fixString:(NSString*)input
{
	for (int i = 0; i < [input length]; i++)
	{
		if ([input characterAtIndex:i] < 10)
		{
			return [[input substringToIndex:i] retain];
		}
	}
	return input;
}
*/
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	[file setUnicode:NO];
	[file skipBytes:8];
	EventCount = -1;
	NSString* pString=[file readAStringWithSize:32];
	NumDir = [pString intValue];
	Distance=[[CArrayList alloc] init];
	FFixed=[[CArrayList alloc] init];
	return YES;
}

-(void)killRunObject:(BOOL)bFast
{
	[Distance clearRelease];
	[Distance release];
	[FFixed clearRelease];
	[FFixed release];
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_COMPDIST:
			return [self CompDist:[cnd getParamPosition:rh withNum:0] withPos:[cnd getParamPosition:rh withNum:1] andParam:[cnd getParamExpression:rh withNum:2]];
		case CND_COMPDIR:
			return [self CompDir:[cnd getParamPosition:rh withNum:0] withPos:[cnd getParamPosition:rh withNum:1] andParam:[cnd getParamExpression:rh withNum:2] andParam2:[cnd getParamExpression:rh withNum:3]];
	}
	return NO;
}

-(BOOL)CompDist:(LPPOS)p1 withPos:(LPPOS)p2 andParam:(int)v
{
	int x1 = p1->posX;
	int y1 = p1->posY;
	int x2 = p2->posX;
	int y2 = p2->posY;
	
	if ((int) sqrt(((x1 - x2) * (x1 - x2)) + ((y1 - y2) * (y1 - y2))) <= v)
	{
		return YES;
	}
	return NO;
}

-(int)lMin:(int)v1 withV2:(int)v2 andV3:(int)v3
{
	return MIN(v1, MIN(v2, v3));
}

-(BOOL)CompDir:(LPPOS)p1 withPos:(LPPOS)p2 andParam:(int)dir andParam2:(int)offset
{
	int x1 = p1->posX;
	int y1 = p1->posY;
	int x2 = p2->posX;
	int y2 = p2->posY;
	
	while (dir >= NumDir)
	{
		dir -= NumDir;
	}
	while (dir < 0)
	{
		dir += NumDir;
	}
	
	int dir2 = (int) (((((atan2(y2 - y1, x2 - x1) * 180) / M_PI) * -1) / 360) * NumDir);
	
	while (dir2 >= NumDir)
	{
		dir2 -= NumDir;
	}
	while (dir2 < 0)
	{
		dir2 += NumDir;
	}
	
	if ([self lMin:abs(dir - dir2) withV2:abs(dir - dir2 - NumDir) andV3:abs(dir - dir2 + NumDir)]<offset)
	{
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
		case ACT_SETNUMDIR:
			[self SetNumDir:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_GETOBJECTS:
			[self GetObjects:[act getParamObject:rh withNum:0] withParam:[act getParamPosition:rh withNum:1]];
			break;
		case ACT_ADDOBJECTS:
			[self AddObjects:[act getParamObject:rh withNum:0]];
			break;
		case ACT_RESET:
			CurrentObject = 0;
			break;
	}
}
-(void)SetNumDir:(int)n
{
	NumDir = n;
}

-(void)GetObjects:(CObject*)object withParam:(int)position
{
	if(object == nil)
		return;

	CRun* rhPtr = ho->hoAdRunHeader;
	//resetting if another event
	if (EventCount != rhPtr->rh4EventCount)
	{
		CurrentObject = 0;
		EventCount = rhPtr->rh4EventCount;
	}
	int x1 = LOWORD(position);
	int y1 = HIWORD(position);
	Last.x = x1;
	Last.y = y1;
	int x2 = object->hoX;
	int y2 = object->hoY;
	while (CurrentObject >= [Distance size])
	{
		[Distance add:nil];
		[FFixed add:nil];
	}
	CFloat* fl=[[CFloat alloc] init];
	fl->value=((float)sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)));
	[Distance set:CurrentObject object:fl];
	CInt* it=[[CInt alloc] init];
	it->value=((object->hoCreationId << 16) + object->hoNumber);
	[FFixed set:CurrentObject object:it];
	CurrentObject++;
}

-(void)AddObjects:(CObject*)object
{
	if(object == nil)
		return;

	int x1 = Last.x;
	int y1 = Last.y;
	int x2 = object->hoX;
	int y2 = object->hoY;
	while (CurrentObject >= [Distance size])
	{
		[Distance add:nil];
		[FFixed add:nil];
	}
	CFloat* fl=[[CFloat alloc] init];
	fl->value=((float) sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)));
	[Distance set:CurrentObject object:fl];
	CInt* it=[[CInt alloc] init];
	it->value=((object->hoCreationId << 16) + object->hoNumber);
	[FFixed set:CurrentObject object:it];
	CurrentObject++;
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETNUMDIR:
			return [rh getTempValue:NumDir];
		case EXP_DIRECTION:
			return [self Direction];
		case EXP_DISTANCE:
			return [self Distance];
		case EXP_DIRECTIONLONG:
			return [self LongDir];
		case EXP_DISTANCELONG:
			return [self LongDist];
		case EXP_ROTATE:
			return [self Rotate];
		case EXP_DIRDIFFABS:
			return [self DirDiffAbs];
		case EXP_DIRDIFF:
			return [self DirDiff];
		case EXP_GETFIXEDOBJ:
			return [self GetFixedObj:[[ho getExpParam] getInt]];
		case EXP_GETDISTOBJ:
			return [self GetDistObj:[[ho getExpParam] getInt]];
		case EXP_XMOV:
			return [self XMov];
		case EXP_YMOV:
			return [self YMov];
		case EXP_DIRBASE:
			return [self DirBase];
	}
	return [rh getTempValue:0];//won't be used
}

-(CValue*)Direction
{
	int x1=[[ho getExpParam] getInt];
	int y1=[[ho getExpParam] getInt];
	int x2=[[ho getExpParam] getInt];
	int y2=[[ho getExpParam] getInt];
	//Just doing simple math now.
	float r = (float) (((((atan2(y2 - y1, x2 - x1) * 180) / M_PI) * -1) / 360) * NumDir);
	
	while (r >= NumDir)
	{
		r -= NumDir;
	}
	while (r < 0)
	{
		r += NumDir;
	}
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:r];
	return ret;
}

-(CValue*)Distance
{
	int x1=[[ho getExpParam] getInt];
	int y1=[[ho getExpParam] getInt];
	int x2=[[ho getExpParam] getInt];
	int y2=[[ho getExpParam] getInt];
	float r = (float) sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2));
	return [rh getTempDouble:r];
}

-(CValue*)LongDir
{
	int x1=[[ho getExpParam] getInt];
	int y1=[[ho getExpParam] getInt];
	int x2=[[ho getExpParam] getInt];
	int y2=[[ho getExpParam] getInt];
	//Just doing simple math now.
	float r = (float) (((((atan2(y2 - y1, x2 - x1) * 180) / M_PI) * -1) / 360) * NumDir);
	if ((int) r < NumDir / 2)
	{
		r += 0.5;
	}
	if ((int) r > NumDir / 2)
	{
		r -= 0.5;
	}
	while (r >= NumDir)
	{
		r -= NumDir;
	}
	while (r < 0)
	{
		r += NumDir;
	}
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:r];
	return ret;
}

-(CValue*)LongDist
{
	int x1=[[ho getExpParam] getInt];
	int y1=[[ho getExpParam] getInt];
	int x2=[[ho getExpParam] getInt];
	int y2=[[ho getExpParam] getInt];
	int r=((int) sqrt((x1 - x2) * (x1 - x2) + (y1 - y2) * (y1 - y2)));
	return [rh getTempValue:r];
}

-(CValue*)Rotate
{
	int angle=[[ho getExpParam] getInt];
	int angletgt=[[ho getExpParam] getInt];
	int rotation=[[ho getExpParam] getInt];
	if (rotation < 0)
	{
		rotation *= -1;
		angletgt += NumDir / 2;
	}
	
	while (angletgt < 0)
	{
		angletgt += NumDir;
	}
	while (angletgt >= NumDir)
	{
		angletgt -= NumDir;
	}
	
	if (abs((int) (angle - angletgt)) <= rotation)
	{
		angle = angletgt;
	}
	if (abs((int) (angle - angletgt - NumDir)) <= rotation)
	{
		angle = angletgt;
	}
	if (abs((int) (angle - angletgt + NumDir)) <= rotation)
	{
		angle = angletgt;
	}
	
	if (angletgt != angle)
	{
		if (angle - angletgt >= 0 && angle - angletgt < NumDir / 2)
		{
			angle -= rotation;
		}
		if (angle - angletgt >= NumDir / 2)
		{
			angle += rotation;
		}
		if (angle - angletgt <= 0 && angle - angletgt > NumDir / -2)
		{
			angle += rotation;
		}
		if (angle - angletgt <= NumDir / -2)
		{
			angle -= rotation;
		}
	}
	
	while (angle >= NumDir)
	{
		angle -= NumDir;
	}
	while (angle < 0)
	{
		angle += NumDir;
	}
	
	return [rh getTempValue:angle];
}

-(int)lSMin:(int)v1 withV2:(int)v2 andV3:(int)v3
{
	if (abs(v1) <= abs(v2) && abs(v1) <= abs(v3))
	{
		return v1;
	}
	if (abs(v2) <= abs(v1) && abs(v2) <= abs(v3))
	{
		return v2;
	}
	if (abs(v3) <= abs(v1) && abs(v3) <= abs(v2))
	{
		return v3;
	}
	return 0;
}

-(CValue*)DirDiffAbs
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	return [rh getTempValue:[self lMin:abs(p1 - p2) withV2:abs(p1 - p2 - NumDir) andV3:abs(p1 - p2 + NumDir)]];
}

-(CValue*)DirDiff
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	return [rh getTempValue:[self lSMin:p1 - p2 withV2:p1 - p2 - NumDir andV3:p1 - p2 + NumDir]];
}

-(CValue*)GetFixedObj:(int)p1
{
	if (p1 >= CurrentObject || p1 < 0)
	{
		p1 = CurrentObject - 1;
	}
	int r = 0;
	if (CurrentObject > 0)
	{
		CArrayList* Fixes = [[[CArrayList alloc] init] autorelease];
		for (int i = 0; i < CurrentObject; i++)
		{
			[Fixes add:[FFixed get:i]];
		}
		for (int i = 0; i <= p1; i++)
		{
			int ClosestID = -1;
			for (int k = 0; k < CurrentObject; k++)
			{
				if ([Fixes get:k] != nil)
				{
					if (ClosestID == -1)
					{
						ClosestID = k;
					}
					else
					{
						float dAtK = ((CFloat*)[Distance get:k])->value;
						float dAtClosestID = ((CFloat*)[Distance get:ClosestID])->value;
						if (dAtK < dAtClosestID)
						{
							ClosestID = k;
						}
					}
				}
			}
			if (ClosestID != -1)
			{
				[Fixes set:ClosestID object:nil];
				r = ((CInt*)[FFixed get:ClosestID])->value;
			}
		}
	}
	return [rh getTempValue:r];
}

-(CValue*)GetDistObj:(int)p1
{
	if (p1 >= CurrentObject || p1 < 0)
	{
		p1 = CurrentObject - 1;
	}
	int r = 0;
	if (CurrentObject > 0)
	{
		CArrayList* Fixes=[[[CArrayList alloc] init] autorelease];
		for (int i = 0; i < CurrentObject; i++)
		{
			[Fixes add:[FFixed get:i]];
		}
		for (int i = 0; i <= p1; i++)
		{
			int ClosestID = -1;
			for (int k = 0; k < CurrentObject; k++)
			{
				if ([Fixes get:k] != nil)
				{
					if (ClosestID == -1)
					{
						ClosestID = k;
					}
					else
					{
						float dAtK = ((CFloat*)[Distance get:k])->value;
						float dAtClosestID = ((CFloat*)[Distance get:ClosestID])->value;
						if (dAtK < dAtClosestID)
						{
							ClosestID = k;
						}
					}
				}
			}
			if (ClosestID != -1)
			{
				[Fixes set:ClosestID object:nil];
				r = (int) ((CFloat*)[Distance get:ClosestID])->value;
			}
		}
	}
	return [rh getTempValue:r];
}

-(CValue*)XMov
{
	int dir=[[ho getExpParam] getInt];
	int speed=[[ho getExpParam] getInt];
	float r;
	dir = ((dir * 360) / NumDir);
	if (dir == 270 || dir == 90)
	{
		r = 0;
	}
	else
	{
		float angle = (float) ((dir * M_PI * 2) / 360);
		r = (float) (cos(angle * -1) * speed);
	}
	return [rh getTempValue:r];
}

-(CValue*)YMov
{
	int dir=[[ho getExpParam] getInt];
	int speed=[[ho getExpParam] getInt];
	float r;
	dir = ((dir * 360) / NumDir);
	if (dir == 180 || dir == 0)
	{
		r = 0;
	}
	else
	{
		float angle = (float) ((dir *M_PI * 2) / 360);
		r = sinf(angle * -1) * speed;
	}
	CValue* ret=[rh getTempValue:0];
	[ret forceDouble:r];
	return ret;
}

-(CValue*)DirBase
{
	int p1=[[ho getExpParam] getInt];
	int p2=[[ho getExpParam] getInt];
	return [rh getTempDouble:(float)((p1 * p2) / NumDir)];
}

@end

@implementation CFloat
@end

@implementation CInt
@end
