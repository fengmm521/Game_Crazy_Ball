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
// CRUNMVTREGPOLYGON : Movement polyone!
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_regpolygon.h"
#import "CFile.h"
#import "CObject.h"
#import "CRun.h"
#import "CRCom.h"
#import "CRunFrame.h"
#import "CAnim.h"
#import "CServices.h"

@implementation CRunMvtclickteam_regpolygon

-(void)initialize:(CFile*)file
{
	// Version number
	[file skipBytes:1];
	m_dwCX = [file readAInt];
	m_dwCY = [file readAInt];
	m_dwNumSides = [file readAInt];
	m_dwRadius = [file readAInt];
	m_dwFlags = [file readAInt];
	m_dwRotAng = [file readAInt];
	m_dwVel = [file readAInt];
	
	//*** General variables
	float r_StartAngle = m_dwRotAng * (M_PI / 180.0f);
	
	r_Stopped = ((m_dwFlags & MFLAG1_MOVEATSTART) == 0);
	r_CX = m_dwCX;
	r_CY = m_dwCY;
	r_Sides = m_dwNumSides;
	r_Vel = m_dwVel / 50.0f;
	r_Radius = m_dwRadius;
	
	r_CurrentX = r_CX + r_Radius * cosf(r_StartAngle);
	r_CurrentY = r_CY - r_Radius * sinf(r_StartAngle);
	r_SideSize = 2 * r_Radius * sinf(M_PI / r_Sides);
	r_TurnAngle = (2.0f / r_Sides) * M_PI;
	r_CurrentAngle = M_PI * (0.5f + (1.0f / r_Sides)) + r_StartAngle;
	r_SideRemainder = r_SideSize;
	
	ho->roc->rcSpeed = abs(m_dwVel);
	
	if (r_Vel < 0.0f)
	{
		r_CurrentAngle = r_CurrentAngle + M_PI * (1.0f - (2.0f / r_Sides));
		r_TurnAngle += 2 * M_PI * (1.0f - (2.0f / r_Sides));
		r_Vel *= -1;
	}
}

-(void)reset
{
	//*** General variables
	double r_StartAngle = m_dwRotAng * (M_PI / 180.0f);
	
	r_CX = m_dwCX;
	r_CY = m_dwCY;
	r_Sides = m_dwNumSides;
	r_Vel = m_dwVel / 50.0f;
	r_Radius = m_dwRadius;
	
	r_CurrentX = r_CX + r_Radius * cos(r_StartAngle);
	r_CurrentY = r_CY - r_Radius * sin(r_StartAngle);
	r_SideSize = 2 * r_Radius * sin(M_PI / r_Sides);
	r_TurnAngle = (2.0f / r_Sides) * M_PI;
	r_CurrentAngle = M_PI * (0.5f + (1.0f / r_Sides)) + r_StartAngle;
	r_SideRemainder = r_SideSize;
	
	if (r_Vel < 0.0f)
	{
		r_CurrentAngle = r_CurrentAngle + M_PI * (1.0f - (2.0f / r_Sides));
		r_TurnAngle += 2 * M_PI * (1.0f - (2.0f / r_Sides));
		r_Vel *= -1;
	}
}

-(BOOL)move
{
	//*** Object needs to be moved?
	if (!r_Stopped)
	{
		double toMove = r_Vel;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			toMove = toMove * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		
		BOOL complete = NO;
		
		while (complete == NO)
		{
			if (toMove >= r_SideRemainder)
			{
				//*** move to the next vertex and turn the angle ready to move along next section
				r_CurrentX += r_SideRemainder * cosf(r_CurrentAngle);
				r_CurrentY -= r_SideRemainder * sinf(r_CurrentAngle);
				toMove -= r_SideRemainder;
				r_SideRemainder = r_SideSize;
				r_CurrentAngle += r_TurnAngle;
			}
			else
			{
				//*** move along the side
				r_CurrentX += toMove * cosf(r_CurrentAngle);
				r_CurrentY -= toMove * sinf(r_CurrentAngle);
				r_SideRemainder -= toMove;
				complete = YES;
			}
		}
		//*** Move object, run animation and collision detection
		[self animations:ANIMID_WALK];
		ho->hoX = (int) r_CurrentX;
		ho->hoY = (int) r_CurrentY;
		[self collisions];
		
		//*** Indicate the object has been moved
		return YES;
	}
	[self animations:ANIMID_STOP];
	[self collisions];
	return NO;
}

-(void)setPosition:(int) x withY:(int)y
{
	r_CurrentX -= ho->hoX - x;
	r_CurrentY -= ho->hoY - y;
	
	r_CX -= ho->hoX - x;
	r_CY -= ho->hoY - y;
	
	ho->hoX = x;
	ho->hoY = y;
}

-(void)setXPosition:(int)x
{
	r_CurrentX -= ho->hoX - x;
	r_CX -= ho->hoX - x;
	
	ho->hoX = x;
}

-(void)setYPosition:(int)y
{
	r_CurrentY -= ho->hoY - y;
	r_CY -= ho->hoY - y;
	
	ho->hoY = y;
}

-(void)stop:(BOOL)bCurrent
{
	r_Stopped = YES;
}

-(void)reverse
{
	r_CurrentAngle += M_PI;
	r_TurnAngle = 2 * M_PI - r_TurnAngle;
	r_SideRemainder = r_SideSize - r_SideRemainder;
}

-(void)start
{
	r_Stopped = NO;
}

-(void)setSpeed:(int)speed
{
	r_Vel = abs(speed) / 50.0;
}

-(double)actionEntry:(int)action
{
	int param;
	switch (action)
	{
/*			
            // Load / save position
		case 0x1010:	// MVTACTION_SAVEPOSITION:
			return savePosition(getOutputStream());
		case 0x1011:	// MVTACTION_LOADPOSITION:
			return loadPosition(getInputStream());
*/			
		case 3445:	    // SET_CENTRE_X = 3445,
			param = (int) [self getParamDouble];
			r_CurrentX += param - r_CX;
			r_CX = param;
			break;
		case 3446:	    // SET_CENTRE_Y,
			param = (int) [self getParamDouble];
			r_CurrentY += param - r_CY;
			r_CY = param;
			break;
		case 3447:	    // SET_NUMSIDES,
			param = (int) [self getParamDouble];
			m_dwNumSides = MAX(param, 0);
			[self reset];
			break;
		case 3448:	    // SET_RADIUS,
			param = (int) [self getParamDouble];
			m_dwRadius = MAX(param, 0);
			[self reset];
			break;
		case 3449:	    // SET_ROTATION_ANGLE,
			param = (int) [self getParamDouble];
			m_dwRotAng = MAX(param, 0);
			[self reset];
			break;
		case 3450:	    // SET_VELOCITY,
			param = (int) [self getParamDouble];
			r_Vel = abs(param) / 50.0;
			break;
		case 3451:	    // GET_CENTRE_X,
			return r_CX;
		case 3452:	    // GET_CENTRE_Y,
			return r_CY;
		case 3453:	    // GET_NUMSIDES,
			return r_Sides;
		case 3454:	    // GET_RADIUS,
			return r_Radius;
		case 3455:	    // GET_ROTATION_ANGLE,
			return m_dwRotAng;
		case 3456:	    // GET_VELOCITY
			return r_Vel * 50;
	}
	return 0;
}

-(int)getSpeed
{
	return (int) (r_Vel * 50);
}

/*
public int loadPosition(DataInputStream stream)
{
	try
	{
		r_Stopped = stream.readBoolean();
		r_OnEnd = stream.readInt();
		r_CX = stream.readInt();
		r_CY = stream.readInt();
		r_Sides = stream.readInt();
		r_Vel = stream.readDouble();
		r_CurrentAngle = stream.readDouble();
		r_SideRemainder = stream.readDouble();
		r_Radius = stream.readDouble();
		r_CurrentX = stream.readDouble();
		r_CurrentY = stream.readDouble();
		r_SideSize = stream.readDouble();
		r_TurnAngle = stream.readDouble();
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
		stream.writeBoolean(r_Stopped);
		stream.writeInt(r_OnEnd);
		stream.writeInt(r_CX);
		stream.writeInt(r_CY);
		stream.writeInt(r_Sides);
		stream.writeDouble(r_Vel);
		stream.writeDouble(r_CurrentAngle);
		stream.writeDouble(r_SideRemainder);
		stream.writeDouble(r_Radius);
		stream.writeDouble(r_CurrentX);
		stream.writeDouble(r_CurrentY);
		stream.writeDouble(r_SideSize);
		stream.writeDouble(r_TurnAngle);
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/

@end
