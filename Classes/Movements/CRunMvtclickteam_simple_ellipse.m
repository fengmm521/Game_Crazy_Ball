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
// CRUNMVTSIMPLEELLIPSE
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_simple_ellipse.h"
#import "CAnim.h"
#import "CObject.h"
#import "CRun.h"
#import "CRunFrame.h"
#import "CRCom.h"
#import "CServices.h"
#import "CFile.h"

@implementation CRunMvtclickteam_simple_ellipse

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_dwCX = [file readAInt];
	m_dwCY = [file readAInt];
	m_dwRadiusX = [file readAInt];
	m_dwRadiusY = [file readAInt];
	m_dwStartAngle = [file readAInt];
	m_dwFlags = [file readAInt];
	m_dwAngVel = [file readAInt];
	m_dwOffset = [file readAInt];
	
	r_Stopped = ((m_dwFlags & MFLAGEL_MOVEATSTART) == 0);
	
	r_CX = m_dwCX;
	r_CY = m_dwCY;
	r_AngVel = m_dwAngVel / 50.0 * (M_PI / 180.0);
	r_Offset = m_dwOffset * (M_PI / 180.0);
	r_CurrentAngle = m_dwStartAngle * (M_PI / 180.0);
	r_radiusX = m_dwRadiusX;
	r_radiusY = m_dwRadiusY;
	
	ho->roc->rcSpeed = m_dwAngVel;
}

-(BOOL)move
{
	//*** Object needs to be moved?
	if (!r_Stopped)
	{
		float x = r_radiusX * cosf(r_CurrentAngle);
		float y = r_radiusY * sinf(r_CurrentAngle);
		
		//*** Carry out 2D transform if needed
		if (absDouble(r_Offset) > 0.0001)
		{
			float xprime = cos(r_Offset) * x - y * sinf(r_Offset);
			float yprime = sin(r_Offset) * x + y * cosf(r_Offset);
			
			x = xprime;
			y = yprime;
		}
		
		double calculs = r_AngVel;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		
		r_CurrentAngle += calculs;
		
		if (r_CurrentAngle < 0)
		{
			r_CurrentAngle += 2 * M_PI;
		}
		else if (r_CurrentAngle > 2 * M_PI)
		{
			r_CurrentAngle -= 2 * M_PI;
		}
		
		[self animations:ANIMID_WALK];
		ho->hoX = (int) (r_CX + x);
		ho->hoY = (int) (r_CY - y);
		[self collisions];
		
		//*** Indicate the object has been moved
		return YES;
	}
	[self animations:ANIMID_STOP];
	[self collisions];
	
	//*** The object has not been moved
	return NO;
}

-(void)reset
{
	r_CX = m_dwCX;
	r_CY = m_dwCY;
	r_AngVel = m_dwAngVel / 50.0f * (M_PI / 180.0f);
	r_Offset = m_dwOffset * (M_PI / 180.0f);
	r_CurrentAngle = m_dwStartAngle * (M_PI / 180.0f);
	r_radiusX = m_dwRadiusX;
	r_radiusY = m_dwRadiusY;
}

-(void)setPosition:(int)x withY:(int)y
{
	r_CX -= ho->hoX - x;
	r_CY -= ho->hoY - y;
	
	ho->hoX = x;
	ho->hoY = y;
}

-(void)setXPosition:(int)x
{
	r_CX -= ho->hoX - x;
	ho->hoX = x;
}

-(void)setYPosition:(int)y
{
	r_CY -= ho->hoY - y;
	ho->hoY = y;
}

-(void)stop:(BOOL)bCurrent
{
	r_Stopped = YES;
}

-(void)reverse
{
	r_AngVel *= -1;
}

-(void)start
{
	r_Stopped = NO;
}

-(void)setSpeed:(int)speed
{
	//*** Linear motion components;
	r_AngVel = (speed) / 50.0f * (M_PI / 180.0f);
	ho->roc->rcSpeed = speed;
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
		case 3645:	    // SET_CENTRE_X = 3645,
			param = (int) [self getParamDouble];
			r_CX = param;
			break;
		case 3646:	    // SET_CENTRE_Y,
			param = (int) [self getParamDouble];
			r_CY = param;
			break;
		case 3647:	    // SET_RADIUS_X,
			param = (int) [self getParamDouble];
			r_radiusX = param;
			break;
		case 3648:	    // SET_RADIUS_Y,
			param = (int) [self getParamDouble];
			r_radiusY = param;
			break;
		case 3649:	    // SET_ANGSPEED,
			param = (int) [self getParamDouble];
			r_AngVel = param / 50.0 * (M_PI / 180.0);
			ho->roc->rcSpeed = param;
			break;
		case 3650:	    // SET_CURRENTANGLE,
			param = (int) [self getParamDouble];
			r_CurrentAngle = param * (M_PI / 180.0);
			break;;
		case 3651:	    // SET_OFFSETANGLE,
			param = (int) [self getParamDouble];
			r_Offset = param * (M_PI / 180.0);
			break;
		case 3652:	    // GET_CENTRE_X,
			return r_CX;
		case 3653:	    // GET_CENTRE_Y,
			return r_CY;
		case 3654:	    // GET_RADIUS_X,
			return r_radiusX;
		case 3655:	    // GET_RADIUS_Y,
			return r_radiusY;
		case 3656:	    // GET_ANGSPEED,
			return r_AngVel * 50.0 * (180.0 / M_PI);
		case 3657:	    // GET_CURRENTANGLE,
			return r_CurrentAngle * (180 / M_PI);
		case 3658:	    // GET_OFFSETANGLE
			return r_Offset * (180 / M_PI);
	}
	return 0;
}

-(int)getSpeed
{
	return ho->roc->rcSpeed;
}

/*
public int loadPosition(DataInputStream stream)
{
	try
	{
		r_Stopped = stream.readBoolean();
		r_CX = stream.readInt();
		r_CY = stream.readInt();
		r_radiusX = stream.readInt();
		r_radiusY = stream.readInt();
		r_AngVel = stream.readDouble();
		r_Offset = stream.readDouble();
		r_CurrentAngle = stream.readDouble();
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
		stream.writeInt(r_CX);
		stream.writeInt(r_CY);
		stream.writeInt(r_radiusX);
		stream.writeInt(r_radiusY);
		stream.writeDouble(r_AngVel);
		stream.writeDouble(r_Offset);
		stream.writeDouble(r_CurrentAngle);
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/

@end
