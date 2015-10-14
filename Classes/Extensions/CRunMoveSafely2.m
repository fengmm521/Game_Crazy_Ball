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
// CRunMoveSafely2 : MoveSafely2 object
// 
//----------------------------------------------------------------------------------
#import "CRunMoveSafely2.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"
#import "CObjectCommon.h"
#import "CMoveDef.h"
#import "CMoveDefExtension.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CMoveDefList.h"
#import "CRMvt.h"
#import "CServices.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CObject.h"
#import "CExtension.h"
#import "CLayer.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CArrayList.h"
#import "CObjInfo.h"
#import "CRVal.h"
#import "CEventProgram.h"


@implementation CRunMoveSafely2

-(int)getNumberOfConditions
{
	return 1;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	Dist = 1;
	mypointer = [[MoveSafely2myclass alloc] init];
	return YES;
}
-(void)destroyRunObject:(BOOL)bFast
{
	[mypointer release];
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	if (num == CID_OnSafety)
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
		case AID_Prepare:
			[self Prepare];
			break;
		case AID_Start:
			[self Start];
			break;
		case AID_Stop:
			[self Stop];
			break;
		case AID_SetObject:
			[self SetObject:[act getParamObject:rh withNum:0]  withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_Stop2:
			[self Stop2];
			break;
		case AID_Setdist:
			[self SetDist:[act getParamExpression:rh withNum:0]];
			break;
		case AID_Reset:
			[self Reset];
			break;
	}
}

-(void)Prepare
{
	for (int i = 0; i < [mypointer->Mirrorvector size]; i++)
	{
		mypointer->iterator = (MoveSafely2CloneObjects*)[mypointer->Mirrorvector get:i];
		mypointer->iterator->OldX = mypointer->iterator->obj->hoX;
		mypointer->iterator->OldY = mypointer->iterator->obj->hoY;
	}
}

-(void)Start
{
	for (int i = 0; i < [mypointer->Mirrorvector size]; i++)
	{
		mypointer->iterator = (MoveSafely2CloneObjects*)[mypointer->Mirrorvector get:i];
		mypointer->iterator->NewX = mypointer->iterator->obj->hoX;
		mypointer->iterator->NewY = mypointer->iterator->obj->hoY;
		X = mypointer->iterator->OldX;
		Y = mypointer->iterator->OldY;
		mypointer->iterator->obj->hoX = X;
		mypointer->iterator->obj->hoY = Y;
	}
	for (int i = 0; i < [mypointer->Mirrorvector size]; i++)
	{
		Loopindex = 0;
		mypointer->iterator = (MoveSafely2CloneObjects*)[mypointer->Mirrorvector get:i];
		NewX = mypointer->iterator->NewX;
		NewY = mypointer->iterator->NewY;
		Temp = MAX(abs(mypointer->iterator->OldX - NewX), abs(mypointer->iterator->OldY - NewY));
		if (Temp != 0)
		{
			Temp2 = 1;
			BOOL first = YES;
			last = NO;
			BOOL doit = YES;
			while (YES)
			{
				if (!first)
				{
					Temp2 += mypointer->iterator->Dist;
				}
				if (first)
				{
					first = NO;
				}
				if (Temp2 < Temp)
				{
					doit = YES;
				}
				if (Temp2 >= Temp)
				{
					doit = NO;
				}
				
				if (!doit && !last)
				{
					last = YES;
					doit = YES;
					Temp2 = Temp;
				}
				if (!doit)
				{
					break;
				}
				int x = NewX - mypointer->iterator->OldX;
				int y = NewY - mypointer->iterator->OldY;
				X = mypointer->iterator->OldX + x * Temp2 / Temp;
				Y = mypointer->iterator->OldY + y * Temp2 / Temp;
				mypointer->iterator->obj->hoX = X;
				mypointer->iterator->obj->hoY = Y;
				
				Debug++;
				[ho generateEvent:CID_OnSafety withParam:[ho getEventParam]];
				Loopindex++;
			}
		}
		//get rid of the stopped or other objects will be piseed off :)
		hasstopped = NO;
	}
}

-(void)Stop
{
	//If the below happens, we are using the 'push out of obsticle' ruitine.
	if (hasstopped)
	{
		inobstacle = YES;
		return;
	}
	//If the below happens, then we have specified for a 'push out of obstacle' routine.
	
	//I will need to make a loop, if the 'has stopped' is true, then you are still in an obstacle
	//if it's false, then you CAN stop the object moving :D
	hasstopped = YES;
	inobstacle = YES;
	int loop = 0;
	if (mypointer->iterator != nil)
	{
		while (inobstacle)
		{
			loop++;
			inobstacle = NO;
			
			int x = NewX - mypointer->iterator->OldX;
			int y = NewY - mypointer->iterator->OldY;
			X = mypointer->iterator->OldX + x * (Temp2 - loop) / Temp;
			Y = mypointer->iterator->OldY + y * (Temp2 - loop) / Temp;
			mypointer->iterator->obj->hoX = X;
			mypointer->iterator->obj->hoY = Y;
			[ho generateEvent:CID_OnSafety withParam:[ho getEventParam]];
		}
		//stop movin
		Temp2 = Temp;
		last = YES;
		mypointer->iterator->obj->roc->rcChanged = YES;
	}
}

-(void)SetObject:(CObject*)object withParam1:(int)distance
{
	if (object != nil)
	{
		[mypointer->Mirrorvector add:[[MoveSafely2CloneObjects alloc] initWithParam:object andParam1:distance]];
	}
}

-(void)Stop2
{
	//If the below happens, we are using the 'push out of obsticle' ruitine.
	if (hasstopped)
	{
		inobstacle = YES;
		return;
	}
	//stop movin
	Temp2 = Temp;
	if (mypointer->iterator != nil)
	{
		mypointer->iterator->obj->roc->rcChanged = YES;
	}
}

-(void)SetDist:(int)dist
{
	Dist = dist;
}

-(void)Reset
{
	[mypointer->Mirrorvector clearRelease];
	mypointer->iterator = nil;
}



// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EID_GetX:
			return [rh getTempValue:X];
		case EID_GetY:
			return [rh getTempValue:Y];
		case EID_Getfixed:
			return [self Getfixed];
		case EID_GetNumber:
			return [rh getTempValue:(int)[mypointer->Mirrorvector size]];
		case EID_GetIndex:
			return [rh getTempValue:Loopindex];
		case EID_Getdist:
			return [rh getTempValue:Debug];
	}
	return [rh getTempValue:0];//won't be used
}

-(CValue*)Getfixed
{
	if (mypointer->iterator != nil)
	{
		return [rh getTempValue:(mypointer->iterator->obj->hoCreationId << 16) + mypointer->iterator->obj->hoNumber];
	}
	return [rh getTempValue:0];
}
				
@end

// Classes accessoires ///////////////////////////////////////////////////////////
@implementation MoveSafely2CloneObjects

-(id)initWithParam:(CObject*)o andParam1:(int)d
{
	obj = o;
	Dist = d;
	return self;
}

@end

@implementation MoveSafely2myclass

-(id)init
{
	if(self = [super init])
	{
		Mirrorvector=[[CArrayList alloc] init]; //MoveSafely2CloneObjects
	}
	return self;
}
-(void)dealloc
{
	[Mirrorvector clearRelease];
	[Mirrorvector release];
	[super dealloc];
}

@end
