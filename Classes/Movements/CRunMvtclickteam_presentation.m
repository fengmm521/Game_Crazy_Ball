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
// CRUNMVTPRESENTAION
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_presentation.h"
#import "CAnim.h"
#import "CRCom.h"
#import "CRun.h"
#import "CFile.h"
#import "CRunFrame.h"
#import "CServices.h"
#import "CArrayList.h"
#import "CObject.h"
#import "CRunApp.h"


@implementation CRunMvtclickteam_presentation

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_dwEntranceType = [file readAInt];
	m_dwEntranceSpeed = [file readAInt];
	m_dwEntranceOrder = [file readAInt];
	m_dwExitType = [file readAInt];
	m_dwExitSpeed = [file readAInt];
	m_dwExitOrder = [file readAInt];
	m_dwFlagsGlobalSettings = [file readAInt];
	
	CGlobalPres* data = (CGlobalPres*) [rh getStorage:PRESIDENTIFIER];
	if (data == nil)
	{
		data = [[CGlobalPres alloc] init];
		[rh addStorage:data withID:PRESIDENTIFIER];
		data->myList = [[CArrayList alloc] init];
	}
	
	// Store pointer to edit data
	pLPHO = ho;
	initialX = ho->hoX;
	initialY = ho->hoY;
	isMoving = STOPPED;
	
	//*** Adds this object to the end of our list
	[data->myList add:self];
	
	data->autoControl = ((m_dwFlagsGlobalSettings & GLOBAL_AUTOCONTROL) != 0);
	data->autoFrameJump = ((m_dwFlagsGlobalSettings & GLOBAL_AUTOFRAMEJUMP) != 0);
	data->autoComplete = ((m_dwFlagsGlobalSettings & GLOBAL_AUTOCOMPLETE) != 0);
}

-(void)reset:(CGlobalPres*)data
{
	//*******************************************
	//*** Entrance parameters *******************
	//*******************************************
	entranceEffect = m_dwEntranceType;
	entranceOrder = m_dwEntranceOrder;
	
	if (entranceOrder == 0 && entranceEffect != FLYEFFECT_NONE)
	{
		isMoving = ENTRANCE;
	}
	
	if (entranceOrder > data->finalOrder && entranceEffect != FLYEFFECT_NONE)
	{
		data->finalOrder = entranceOrder;
	}
	
	switch (m_dwEntranceSpeed)
	{
		case 0:	    // SPEED_VERYSLOW:
			entranceSpeed = 1;
			break;
		case 1:	    // SPEED_SLOW:
			entranceSpeed = 2;
			break;
		case 2:	    // SPEED_MEDIUM:
			entranceSpeed = 4;
			break;
		case 3:	    // SPEED_FAST:
			entranceSpeed = 8;
			break;
		case 4:	    // SPEED_VERYFAST:
			entranceSpeed = 16;
			break;
	}
	
	switch (entranceEffect)
	{
		case 0:	    // FLYEFFECT_NONE:
			entranceOrder = -1;
			break;
		case 1:	    // FLYEFFECT_APPEAR:
			startEntranceX = initialX;
			startEntranceY = -10 - pLPHO->hoImgWidth + pLPHO->hoImgXSpot;
			entranceSpeedX = 0;
			entranceSpeedY = 0;
			break;
		case 2:	    // FLYEFFECT_BOTTOM:
			startEntranceX = initialX;
			startEntranceY = pLPHO->hoAdRunHeader->rhLevelSy + 10 - pLPHO->hoImgYSpot;
			entranceSpeedX = 0;
			entranceSpeedY = entranceSpeed;
			break;
		case 3:	    // FLYEFFECT_LEFT:
			startEntranceX = -10 - pLPHO->hoImgWidth + pLPHO->hoImgXSpot;
			startEntranceY = initialY;
			entranceSpeedX = entranceSpeed;
			entranceSpeedY = 0;
			break;
		case 4:	    // FLYEFFECT_RIGHT:
			startEntranceX = pLPHO->hoAdRunHeader->rhLevelSx + 10 - pLPHO->hoImgXSpot;
			startEntranceY = initialY;
			entranceSpeedX = entranceSpeed;
			entranceSpeedY = 0;
			break;
		case 5:	    // FLYEFFECT_TOP:
			startEntranceX = initialX;
			startEntranceY = -10 - pLPHO->hoImgHeight + pLPHO->hoImgYSpot;
			entranceSpeedX = 0;
			entranceSpeedY = entranceSpeed;
			break;
	}
	
	//*******************************************
	//*** Exit parameters ***********************
	//*******************************************
	exitEffect = m_dwExitType;
	exitOrder = m_dwExitOrder;
	
	if (exitOrder == 0 && exitEffect != FLYEFFECT_NONE)
	{
		isMoving = EXIT;
	}
	
	if (exitOrder > data->finalOrder && exitEffect != FLYEFFECT_NONE)
	{
		data->finalOrder = exitOrder;
	}
	
	switch (m_dwExitSpeed)
	{
		case 0:	    // SPEED_VERYSLOW:
			exitSpeed = 1;
			break;
		case 1:	    // SPEED_SLOW:
			exitSpeed = 2;
			break;
		case 2:	    // SPEED_MEDIUM:
			exitSpeed = 4;
			break;
		case 3:	    // SPEED_FAST:
			exitSpeed = 8;
			break;
		case 4:	    // SPEED_VERYFAST:
			exitSpeed = 16;
			break;
	}
	
	switch (exitEffect)
	{
		case 0:	    // FLYEFFECT_NONE:
			exitOrder = -1;
			break;
		case 1:	    // FLYEFFECT_APPEAR:
			finalExitX = initialX;
			finalExitY = -10 - pLPHO->hoImgHeight;
			exitSpeedX = 0;
			exitSpeedY = 0;
			break;
		case 2:	    // FLYEFFECT_BOTTOM:
			finalExitX = initialX;
			finalExitY = pLPHO->hoAdRunHeader->rhLevelSy + 10 - pLPHO->hoImgYSpot;
			exitSpeedX = 0;
			exitSpeedY = exitSpeed;
			break;
		case 3:	    // FLYEFFECT_LEFT:
			finalExitX = -10 - pLPHO->hoImgWidth + pLPHO->hoImgXSpot;
			finalExitY = initialY;
			exitSpeedX = exitSpeed;
			exitSpeedY = 0;
			break;
		case 4:	    // FLYEFFECT_RIGHT:
			finalExitX = pLPHO->hoAdRunHeader->rhLevelSx + 10 - pLPHO->hoImgXSpot;
			finalExitY = initialY;
			exitSpeedX = exitSpeed;
			exitSpeedY = 0;
			break;
		case 5:	    // FLYEFFECT_TOP:
			finalExitX = initialX;
			finalExitY = -10 - pLPHO->hoImgHeight + pLPHO->hoImgYSpot;
			exitSpeedX = 0;
			exitSpeedY = exitSpeed;
			break;
	}
	
	//**************************************
	//*** Calculate the initial position ***
	//**************************************
	if (exitOrder == -1)
	{
		if (entranceOrder != -1)
		{
			pLPHO->hoX = startEntranceX;
			pLPHO->hoY = startEntranceY;
			pLPHO->roc->rcChanged=YES;
		}
	}
	else if (entranceOrder != -1 && exitOrder != -1)
	{
		if (exitOrder > entranceOrder)
		{
			pLPHO->hoX = startEntranceX;
			pLPHO->hoY = startEntranceY;
			pLPHO->roc->rcChanged=YES;
		}
	}
}

-(void)moveToEnd
{
	if (entranceOrder != -1 && exitOrder == -1)
	{
		pLPHO->hoX = initialX;
		pLPHO->hoY = initialY;
		pLPHO->roc->rcChanged=YES;
	}
	else if (entranceOrder == -1 && exitOrder != -1)
	{
		pLPHO->hoX = finalExitX;
		pLPHO->hoY = finalExitY;
		pLPHO->roc->rcChanged=YES;
	}
	else if (entranceOrder != -1 && exitOrder != -1)
	{
		if (entranceOrder > exitOrder)
		{
			pLPHO->hoX = initialX;
			pLPHO->hoY = initialY;
		}
		else
		{
			pLPHO->hoX = finalExitX;
			pLPHO->hoY = finalExitY;
		}
		pLPHO->roc->rcChanged=YES;
	}
}

-(void)checkKeyPresses:(CGlobalPres*)data
{
/*	
	*** Has the user pressed a key so we need to increase / decrease the order?
	
	*******************************
	*** Check move foward keys    *
	*******************************
	if (data.keyNext == 0)
	{
		if (ho.hoAdRunHeader.rhApp.getKeyState(40))	    // VK_DOWN
		{
			data.keyNext = 40;			// VK_DOWN;
			moveForward();
		}
		else if (ho.hoAdRunHeader.rhApp.getKeyState(39))	// VK_RIGHT
		{
			data.keyNext = 39;			// VK_RIGHT;
			moveForward();
		}
	}
	else if (ho.hoAdRunHeader.rhApp.getKeyState(data.keyNext) == false)
	{
		data.keyNext = 0;
	}
	
	*******************************
	*** Check move backwards keys *
	*******************************
	if (data.keyPrev == 0)
	{
		if (ho.hoAdRunHeader.rhApp.getKeyState(38))	// VK_UP
		{
			data.keyPrev = 38;		// VK_UP;
			moveBack();
		}
		else if (ho.hoAdRunHeader.rhApp.getKeyState(37))	// VK_LEFT
		{
			data.keyPrev = 37;		// VK_LEFT;
			moveBack();
		}
	}
	else if (ho.hoAdRunHeader.rhApp.getKeyState(data.keyPrev) == false)
	{
		data.keyPrev = 0;
	}
 */
}

-(void)kill
{
    CGlobalPres* data = (CGlobalPres*) [rh getStorage:PRESIDENTIFIER];
    if (data != nil)
    {
        NSInteger idx = [data->myList indexOf:self];
        if ( idx >= 0 )
        {
            [data->myList removeIndex:idx];
            if ( [data->myList size] == 0 )
            {
                [data release];
                [rh delStorage:PRESIDENTIFIER];
            }
        }
    }
}

-(BOOL)move
{
	CGlobalPres* data = (CGlobalPres*) [rh getStorage:PRESIDENTIFIER];
	if (data == nil)
	{
		return NO;
	}
	
	//************************
	//*** Reset workaround ***
	//************************
	CRunMvtclickteam_presentation* p;
	if (data->reset)
	{
		if (ho->hoImgHeight != 0)
		{
			int index;
			for (index = 0; index < [data->myList size]; index++)
			{
				p = (CRunMvtclickteam_presentation*)[data->myList get:index];
				[p reset:data];
				if (data->resetToEnd)
				{
					[p moveToEnd];
				}
			}
			if (data->resetToEnd)
			{
				data->orderPosition = data->finalOrder;
			}
			data->reset = NO;
			data->resetToEnd = NO;
		}
		else
		{
			return NO;
		}
	}
	
	if ([data->myList size]> 0)
	{
		p = (CRunMvtclickteam_presentation*)[data->myList get:0];
		if (p == self)
		{
			[self checkKeyPresses:data];
		}
	}
	
	//************************
	//*** Move Object ********
	//************************
	double calculs;
	if (isMoving == ENTRANCE)
	{
		[self animations:ANIMID_WALK];
		
		//*** Entrance movement
		switch (entranceEffect)
		{
			case 1:	    // FLYEFFECT_APPEAR:
				ho->hoX = initialX;
				ho->hoY = initialY;
				isMoving = STOPPED;
				break;
			case 2:	    // FLYEFFECT_BOTTOM:
				calculs = entranceSpeedY;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoY -= MIN(calculs, abs(initialY - ho->hoY));
				if (ho->hoY == initialY)
				{
					isMoving = STOPPED;
				}
				break;
			case 3:	    // FLYEFFECT_LEFT:
				calculs = entranceSpeedX;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoX += MIN(calculs, abs(initialX - ho->hoX));
				if (ho->hoX == initialX)
				{
					isMoving = STOPPED;
				}
				break;
			case 4:	    // FLYEFFECT_RIGHT:
				calculs = entranceSpeedX;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoX -= MIN(calculs, abs(initialX - ho->hoX));
				if (ho->hoX == initialX)
				{
					isMoving = STOPPED;
				}
				break;
			case 5:	    // FLYEFFECT_TOP:
				calculs = entranceSpeedY;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoY += MIN(calculs, abs(initialY - ho->hoY));
				if (ho->hoY == initialY)
				{
					isMoving = STOPPED;
				}
				break;
		}
		[self collisions];
		return true;
	}
	else if (isMoving == EXIT)
	{
		[self animations:ANIMID_WALK];
		
		//*** Exit movement
		switch (exitEffect)
		{
			case 1:	    // FLYEFFECT_APPEAR:
				ho->hoY = finalExitY;
				isMoving = STOPPED;
				break;
			case 2:	    // FLYEFFECT_BOTTOM:
				calculs = exitSpeedY;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoY += MIN(calculs, abs(finalExitY - ho->hoY));
				if (ho->hoY >= finalExitY)
				{
					isMoving = STOPPED;
				}
				break;
			case 3:	    // FLYEFFECT_LEFT:
				calculs = exitSpeedX;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoX -= MIN(calculs, abs(finalExitX - ho->hoX));
				if (ho->hoX <= finalExitX)
				{
					isMoving = STOPPED;
				}
				break;
			case 4:	    // FLYEFFECT_RIGHT:
				calculs = exitSpeedX;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoX += MIN(calculs, abs(finalExitX - ho->hoX));
				if (ho->hoX >= finalExitX)
				{
					isMoving = STOPPED;
				}
				break;
			case 5:	    // FLYEFFECT_TOP:
				calculs = exitSpeedY;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				ho->hoY -= MIN(calculs, abs(finalExitY - ho->hoY));
				if (ho->hoY <= finalExitY)
				{
					isMoving = STOPPED;
				}
				break;
		}
		[self collisions];
		return YES;
	}
	[self animations:ANIMID_STOP];
	[self collisions];
	
	//** The object has not been moved
	return ho->roc->rcChanged;
}

-(void)moveForward
{
	CGlobalPres* data = (CGlobalPres*) [rh getStorage:PRESIDENTIFIER];
	if (data != nil)
	{
		int index;
		CRunMvtclickteam_presentation* p;
		for (index = 0; index < [data->myList size]; index++)
		{
			p = (CRunMvtclickteam_presentation*)[data->myList get:index];
			
			//*** Find any objects that did not complete from the last move and complete them!
			if (data->autoComplete)
			{
				if (p->entranceOrder == data->orderPosition && p->isMoving != STOPPED)
				{
					p->pLPHO->hoX = p->initialX;
					p->pLPHO->hoY = p->initialY;
					p->isMoving = STOPPED;
					p->pLPHO->roc->rcChanged=YES;
				}
				if (p->exitOrder == data->orderPosition && p->isMoving != STOPPED)
				{
					p->pLPHO->hoX = p->finalExitX;
					p->pLPHO->hoY = p->finalExitY;
					p->isMoving = STOPPED;
					p->pLPHO->roc->rcChanged=YES;
				}
			}
			
			//*** Find any objects to move at this order : Entrance
			if (p->entranceOrder == (data->orderPosition + 1))
			{
				p->pLPHO->hoX = p->startEntranceX;
				p->pLPHO->hoY = p->startEntranceY;
				p->isMoving = ENTRANCE;
				p->pLPHO->roc->rcChanged=YES;
			}
			//*** Find any objects to move at this order : Exit
			if (p->exitOrder == (data->orderPosition + 1))
			{
				p->isMoving = EXIT;
			}
		}
		data->orderPosition++;
		
		if (data->orderPosition > data->finalOrder && data->autoFrameJump == YES)
		{
			ho->hoAdRunHeader->rhQuit = LOOPEXIT_NEXTLEVEL;
		}
	}
}

-(void)moveBack
{
	CGlobalPres* data = (CGlobalPres*)[rh getStorage:PRESIDENTIFIER];
	if (data != nil)
	{
		int index;
		CRunMvtclickteam_presentation* p;
		for (index = 0; index < [data->myList size]; index++)
		{
			p = (CRunMvtclickteam_presentation*) [data->myList get:index];
			
			//*** Find any objects from the last move and reset them!
			if (p->entranceOrder == data->orderPosition)
			{
				p->pLPHO->hoX = p->startEntranceX;
				p->pLPHO->hoY = p->startEntranceY;
				p->isMoving = STOPPED;
				p->pLPHO->roc->rcChanged=YES;
			}
			if (p->exitOrder == data->orderPosition)
			{
				p->pLPHO->hoX = p->initialX;
				p->pLPHO->hoY = p->initialY;
				p->isMoving = STOPPED;
				p->pLPHO->roc->rcChanged=YES;
			}
		}
		data->orderPosition--;
		
		if (data->orderPosition < 0)
		{
			if (data->autoFrameJump && ho->hoAdRunHeader->rhApp->currentFrame != 0)
			{
				data->resetToEnd = YES;
				ho->hoAdRunHeader->rhQuit = LOOPEXIT_PREVLEVEL;
			}
			else
			{
				data->orderPosition = 0;
			}
		}
	}
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

-(double)actionEntry:(int)action
{
	CGlobalPres* data = (CGlobalPres*)[rh getStorage:PRESIDENTIFIER];
	if (data == nil)
	{
		return 0;
	}
	
//	int param;
	int index;
	CRunMvtclickteam_presentation* p;
	switch (action)
	{
/*            // Load / save position
		case 0x1010:	// MVTACTION_SAVEPOSITION:
			return savePosition(getOutputStream());
		case 0x1011:	// MVTACTION_LOADPOSITION:
			return loadPosition(getInputStream());
*/			
		case 3945:		// SET_PRESENTATION_Next = 3945,
			[self moveForward];
			break;
		case 3946:		// SET_PRESENTATION_Prev,
			[self moveBack];
			break;
		case 3947:		// SET_PRESENTATION_ToStart,
			for (index = 0; index < [data->myList size]; index++)
			{
				p = (CRunMvtclickteam_presentation*) [data->myList get:index];
				p->isMoving = STOPPED;
				[p reset:data];
			}
			data->orderPosition = 0;
			break;
		case 3948:		// SET_PRESENTATION_ToEnd,
			for (index = 0; index < [data->myList size]; index++)
			{
				p = (CRunMvtclickteam_presentation*) [data->myList get:index];
				p->isMoving = STOPPED;
				[p moveToEnd];
			}
			data->orderPosition = data->finalOrder;
			break;
		case 3949:		// GET_PRESENTATION_Index,
			return data->orderPosition;
		case 3950:		// GET_PRESENTATION_LastIndex
			return data->finalOrder;
	}
	return 0;
}

-(int)getSpeed
{
	return finalExitX;
}

/*
public int loadPosition(DataInputStream stream)
{
	try
	{
		CGlobalPres data = (CGlobalPres) rh.getStorage(IDENTIFIER);
		if (data != null)
		{
			initialX = stream.readInt();
			initialY = stream.readInt();
			startEntranceX = stream.readInt();
			startEntranceY = stream.readInt();
			entranceEffect = stream.readInt();
			entranceOrder = stream.readInt();
			entranceSpeed = stream.readInt();
			entranceSpeedX = stream.readDouble();
			entranceSpeedY = stream.readDouble();
			finalExitX = stream.readInt();
			finalExitY = stream.readInt();
			exitEffect = stream.readInt();
			exitOrder = stream.readInt();
			exitSpeed = stream.readInt();
			exitSpeedX = stream.readDouble();
			exitSpeedY = stream.readDouble();
			data.orderPosition = stream.readInt();
			data.finalOrder = stream.readInt();
			data.reset = stream.readBoolean();
			data.resetToEnd = stream.readBoolean();
			data.autoControl = stream.readBoolean();
			data.autoFrameJump = stream.readBoolean();
			data.autoComplete = stream.readBoolean();
			data.keyNext = stream.readInt();
			data.keyPrev = stream.readInt();
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
		CGlobalPres data = (CGlobalPres) rh.getStorage(IDENTIFIER);
		if (data != null)
		{
			stream.writeInt(initialX);
			stream.writeInt(initialY);
			stream.writeInt(startEntranceX);
			stream.writeInt(startEntranceY);
			stream.writeInt(entranceEffect);
			stream.writeInt(entranceOrder);
			stream.writeInt(entranceSpeed);
			stream.writeDouble(entranceSpeedX);
			stream.writeDouble(entranceSpeedY);
			stream.writeInt(finalExitX);
			stream.writeInt(finalExitY);
			stream.writeInt(exitEffect);
			stream.writeInt(exitOrder);
			stream.writeInt(exitSpeed);
			stream.writeDouble(exitSpeedX);
			stream.writeDouble(exitSpeedY);
			stream.writeInt(data.orderPosition);
			stream.writeInt(data.finalOrder);
			stream.writeBoolean(data.reset);
			stream.writeBoolean(data.resetToEnd);
			stream.writeBoolean(data.autoControl);
			stream.writeBoolean(data.autoFrameJump);
			stream.writeBoolean(data.autoComplete);
			stream.writeInt(data.keyNext);
			stream.writeInt(data.keyPrev);
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

@implementation CGlobalPres

-(id)init
{
    orderPosition = 0;
    finalOrder = -1;
    keyNext = 0;
    keyPrev = 0;
    reset = YES;
    resetToEnd = NO;
    autoControl = YES;
    autoFrameJump = YES;
    autoComplete = YES;
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

