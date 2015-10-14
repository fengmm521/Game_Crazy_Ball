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
// CRUNMVTINVADERS
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_invaders.h"
#import "CObject.h"
#import "CRun.h"
#import "CRCom.h"
#import "CAnim.h"
#import "CFile.h"
#import "CRAni.h"
#import "CArrayList.h"

@implementation CRunMvtclickteam_invaders

-(void)initialize:(CFile*)file
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data == nil)
	{
		[file skipBytes:1];
		int m_dwFlagMoveAtStart = [file readAInt];
		int m_dwFlagAutoSpeed = [file readAInt];
		int m_dwInitialDirection = [file readAInt];
		int m_dwDX = [file readAInt];
		int m_dwDY = [file readAInt];
		int m_dwSpeed = [file readAInt];
//		int m_dwGroup 
		[file readAInt];
		
		data = [[CRunMvtInvaderData alloc] init];
		data->count = 0;
		
		if (m_dwFlagMoveAtStart == 1)
		{
			data->isMoving = YES;
		}
		else
		{
			data->isMoving = NO;
		}
		
		data->autoSpeed = m_dwFlagAutoSpeed == 1;
		data->dx = m_dwDX;
		data->dy = m_dwDY;
		data->minX = 0;
		data->maxX = ho->hoAdRunHeader->rhLevelSx;
		data->initialSpeed = m_dwSpeed;
		if (m_dwInitialDirection == 0)
		{
			data->cdx = -data->dx;
		}
		else
		{
			data->cdx = data->dx;
		}
		data->speed = 101 - data->initialSpeed;
		
		data->myList = [[CArrayList alloc] init];
		[rh addStorage:data withID:IDENTIFIER];
	}
	//*** Adds this object to the end of our list
	data->count++;
	[data->myList addInt:[ho fixedValue]];
}

-(void)kill
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*) [rh getStorage:IDENTIFIER];
	if (data != nil)
	{
		int n;
		for (n = 0; n < [data->myList size]; n++)
		{
			CObject* obj = (CObject*)[data->myList get:n];
			if (obj == (CObject*) ho)
			{
				[data->myList removeIndex:n];
				break;
			}
		}
		data->count--;
		if (data->count == 0)
		{
			[data release];
			[rh delStorage:IDENTIFIER];
		}
	}
}

-(BOOL)move
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data != nil)
	{
		if (!data->isMoving)
		{
			return NO;
		}
		
		CObject* myObject = [ho getObjectFromFixed:[data->myList getInt:0]];
		while(myObject == nil)
		{
			[data->myList removeIndex:0];
			if([data->myList size]>0)
				myObject = [ho getObjectFromFixed:[data->myList getInt:0]];
			else
				return NO;
		}
		
		if (myObject == ho)
		{
			data->frames++;
			if (data->frames % data->speed == 0)
			{
				data->cdy = 0;
				
				//*** Loop over all objects to ensure non have left the playing field
				int index;
				CObject* hoPtr;
				
				//Remove deleted objects from the list
				for (index = 0; index < [data->myList size]; index++)
				{
					hoPtr = [ho getObjectFromFixed:[data->myList getInt:index]];
					if(hoPtr == nil || (hoPtr->hoFlags & HOF_DESTROYED) != 0)
					{
						[data->myList removeIndex:index];
						index -= 1;
						continue;
					}
				}
				
				for (index = 0; index < [data->myList size]; index++)
				{
					hoPtr = [ho getObjectFromFixed:[data->myList getInt:index]];
					if ((hoPtr->hoX < data->minX + hoPtr->hoImgXSpot) && data->cdx < 0)
					{
						data->cdx = data->dx;
						data->cdy = data->dy;
						break;
					}
					else if (hoPtr->hoX > (data->maxX + hoPtr->hoImgXSpot - hoPtr->hoImgWidth) && data->cdx > 0)
					{
						data->cdx = -data->dx;
						data->cdy = data->dy;
						break;
					}
				}
				
				//*** Loop over all objects and move them
				for (index = 0; index < [data->myList size]; index++)
				{
					hoPtr = [ho getObjectFromFixed:[data->myList getInt:index]];
					if (data->cdy != 0)
					{
						hoPtr->hoY = (hoPtr->hoY + data->cdy);
						ho->roc->rcAnim = ANIMID_WALK;
						if (hoPtr->roa!=nil)
						{
							[hoPtr->roa animations];
						}
						[self moveIt];
					}
					else
					{
						hoPtr->hoX = (hoPtr->hoX + data->cdx);
						ho->roc->rcAnim = ANIMID_WALK;
						if (hoPtr->roa!=nil)
						{
							[hoPtr->roa animations];
						}
						[self moveIt];
					}
				}
			}
		}
		//*** Objects have been moved return true
		if (data->frames % data->speed == 0)
		{
			return YES;
		}
	}
	//** The object has not been moved
	return NO;
}

-(void)setPosition:(int)x withY:(int)y
{
	ho->hoX = x;
	ho->hoY = y;
}

-(void)setXPosition:(int)x
{
	ho->hoX = x;
}

-(void)setYPosition:(int)y
{
	ho->hoY = y;
}

-(void)stop:(BOOL)bCurrent
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data != nil)
	{
		data->isMoving = NO;
	}
}

-(void)reverse
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data != nil)
	{
		data->cdx *= -1;
	}
}

-(void)start
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data != nil)
	{
		data->isMoving = YES;
	}
}

-(void)setSpeed:(int)speed
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data != nil)
	{
		data->speed = 101 - speed;
		if (data->speed < 1)
		{
			data->speed = 1;
		}
	}
}

-(double)actionEntry:(int)action
{
	CRunMvtInvaderData* data = (CRunMvtInvaderData*)[rh getStorage:IDENTIFIER];
	if (data == nil)
	{
		return 0;
	}
	
	int param;
	switch (action)
	{
/*            // Load / save position
		case 0x1010:	// MVTACTION_SAVEPOSITION:
			return savePosition(getOutputStream());
		case 0x1011:	// MVTACTION_LOADPOSITION:
			return loadPosition(getInputStream());
*/			
		case 3745:		// SET_INVADERS_SPEED = 3745,
			param = (int)[self getParamDouble];
			data->speed = param;
			if (data->speed < 1)
			{
				data->speed = 1;
			}
			break;
		case 3746:		// SET_INVADERS_STEPX,
			param = (int)[self getParamDouble];
			data->dx = param;
			break;
		case 3747:		// SET_INVADERS_STEPY,
			param = (int)[self getParamDouble];
			data->dy = param;
			break;
		case 3748:		// SET_INVADERS_LEFTBORDER,
			param = (int)[self getParamDouble];
			data->minX = param;
			break;
		case 3749:		// SET_INVADERS_RIGHTBORDER,
			param = (int)[self getParamDouble];
			data->maxX = param;
			break;
		case 3750:		// GET_INVADERS_SPEED,
			return data->speed;
		case 3751:		// GET_INVADERS_STEPX,
			return data->dx;
		case 3752:		// GET_INVADERS_STEPY,
			return data->dy;
		case 3753:		// GET_INVADERS_LEFTBORDER,
			return data->minX;
		case 3754:		// GET_INVADERS_RIGHTBORDER,
			return data->maxX;
	}
	return 0;
}

/*
public int loadPosition(DataInputStream stream)
{
	try
	{
		CRunMvtInvaderData data = (CRunMvtInvaderData) rh.getStorage(IDENTIFIER);
		if (data != null)
		{
			data.isMoving = stream.readBoolean();
			data.autoSpeed = stream.readBoolean();
			data.initialSpeed = stream.readInt();
			data.count = stream.readInt();
			data.dx = stream.readInt();
			data.dy = stream.readInt();
			data.cdx = stream.readInt();
			data.cdy = stream.readInt();
			data.speed = stream.readInt();
			data.frames = stream.readInt();
			data.minX = stream.readInt();
			data.maxX = stream.readInt();
			data.tillSpeedIncrease = stream.readInt();
		}
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}

public int savePosition(DataOutputStream stream)
{
	try
	{
		CRunMvtInvaderData data = (CRunMvtInvaderData) rh.getStorage(IDENTIFIER);
		if (data != null)
		{
			stream.writeBoolean(data.isMoving);
			stream.writeBoolean(data.autoSpeed);
			stream.writeInt(data.initialSpeed);
			stream.writeInt(data.count);
			stream.writeInt(data.dx);
			stream.writeInt(data.dy);
			stream.writeInt(data.cdx);
			stream.writeInt(data.cdy);
			stream.writeInt(data.speed);
			stream.writeInt(data.frames);
			stream.writeInt(data.minX);
			stream.writeInt(data.maxX);
			stream.writeInt(data.tillSpeedIncrease);
		}
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/
@end

@implementation CRunMvtInvaderData

-(id)init
{
	count = 0;
    tillSpeedIncrease = 0;
    dx = 1;
    dy = 0;
    cdx = 0;
    cdy = 0;
    speed = 0;
    frames = 0;
    initialSpeed = 0;
    minX = 0;
    maxX = 640;
	myList=nil;
	
	return self;
}
-(void)dealloc
{
	if (myList!=nil)
	{
		[myList release];
	}
	[super dealloc];
}

@end
