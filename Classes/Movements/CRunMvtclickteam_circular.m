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
// CRUNMVTCIRCULAR : Movement circular!
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_circular.h"
#import "CFile.h"
#import "CAnim.h"
#import "CObject.h"
#import "CRun.h"
#import "CRunFrame.h"
#import "CRCom.h"
#import "CServices.h"

@implementation CRunMvtclickteam_circular

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_dwCX = [file readAInt];
	m_dwCY = [file readAInt];
	m_dwRadius = [file readAInt];
	m_dwStartAngle = [file readAInt];
	m_dwRmin = [file readAInt];
	m_dwRmax = [file readAInt];
	m_dwFlags = [file readAInt];
	m_dwOnEnd = [file readAInt];
	m_dwAngVel = [file readAInt];
	m_dwSpiVel = [file readAInt];
	
	//*** General variables
	//	r_Stopped = (bool)( 1 - m_pMvt->m_dwFlags);
	r_Stopped = ((m_dwFlags & MFLAG1_MOVEATSTART) == 0);
	r_OnEnd = m_dwOnEnd;
	
	r_CX = m_dwCX;
	r_CY = m_dwCY;
	r_Rmin = m_dwRmin;
	r_Rmax = m_dwRmax;
	r_AngVel = m_dwAngVel / 50.0 * (M_PI / 180.0);
	r_SpiVel = m_dwSpiVel / 50.0;
	r_CurrentAngle = m_dwStartAngle * (M_PI / 180.0);
	r_CurrentRadius = m_dwRadius;
	ho->roc->rcSpeed = (int) m_dwAngVel;
}

-(BOOL)move
{
	double calculs;
	
	//*** Object needs to be moved?
	if (!r_Stopped)
	{
		[self animations:ANIMID_WALK];
		ho->hoX = (int) (r_CX + r_CurrentRadius * cosf(r_CurrentAngle));
		ho->hoY = (int) (r_CY - r_CurrentRadius * sinf(r_CurrentAngle));
		[self collisions];
		
		calculs = r_AngVel;
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
		
		if (absDouble(r_SpiVel) > 0.00001)
		{
			calculs = r_SpiVel;
			if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
			{
				calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
			}
			r_CurrentRadius += calculs;
			
			if (r_CurrentRadius < r_Rmin || r_CurrentRadius > r_Rmax)
			{
				if (r_OnEnd == ONEND_STOP)
				{
					r_Stopped = true;
				}
				else if (r_OnEnd == ONEND_REVERSE_VEL)
				{
					r_SpiVel *= -1;
				}
				else if (r_OnEnd == ONEND_REVERSE_DIR)
				{
					r_AngVel *= -1;
					r_SpiVel *= -1;
				}
				else if (r_OnEnd == ONEND_RESET)
				{
					[self reset];
				}
			}
		}
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
	r_Rmin = m_dwRmin;
	r_Rmax = m_dwRmax;
	r_AngVel = m_dwAngVel / 50.0 * (M_PI / 180.0);
	r_SpiVel = m_dwSpiVel / 50.0;
	r_CurrentAngle = m_dwStartAngle * (M_PI / 180.0);
	r_CurrentRadius = m_dwRadius;
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
	r_AngVel = (speed) / 50.0 * (M_PI / 180.0);
	ho->roc->rcSpeed = speed;
}

-(double)actionEntry:(int)action
{
	int param;
	switch (action)
	{
/*            // Load / save position
		case 0x1010:	// MVTACTION_SAVEPOSITION:
			return savePosition(getOutputStream());
		case 0x1011:	// MVTACTION_LOADPOSITION:
			return loadPosition(getInputStream());
*/			
		case 3345:		// SET_CENTRE_X = 3345,
			param = (int) [self getParamDouble];
			r_CX = param;
			return 0;
		case 3346:		// SET_CENTRE_Y,
			param = (int) [self getParamDouble];
			r_CY = param;
			return 0;
		case 3347:		// SET_ANGSPEED,
			param = (int) [self getParamDouble];
			r_AngVel = param / 50.0 * (M_PI / 180.0);
			ho->roc->rcSpeed = param;
			return 0;
		case 3348:		// SET_CURRENTANGLE,
			param = (int) [self getParamDouble];
			r_CurrentAngle = param * (M_PI / 180.0);
			return 0;
		case 3349:		// SET_RADIUS,
			param = (int) [self getParamDouble];
			r_CurrentRadius = MAX(param, 0);
			return 0;
		case 3350:		// SET_SPIRALVEL,
			param = (int) [self getParamDouble];
			r_SpiVel = param / 50.0;
			return 0;
		case 3351:		// SET_MINRADIUS,
			param = (int) [self getParamDouble];
			r_Rmin = MAX(param, 0);
			return 0;
		case 3352:		// SET_MAXRADIUS,
			param = (int) [self getParamDouble];
			r_Rmax = MAX(param, 0);
			return 0;
		case 3353:		// SET_ONCOMPLETION,
		{
			param = (int) [self getParamDouble];
			int onEnd = param;
			if (onEnd >= ONEND_STOP && onEnd <= ONEND_REVERSE_DIR)
			{
				r_OnEnd = onEnd;
			}
			return 0;
		}
		case 3354:		// GET_CENTRE_X,
			return r_CX;
		case 3355:		// GET_CENTRE_Y,
			return r_CY;
		case 3356:		// GET_ANGSPEED,
			return r_AngVel * 50.0 * (180.0 / M_PI);
		case 3357:		// GET_CURRENTANGLE,
			return r_CurrentAngle * (180 / M_PI);
		case 3358:		// GET_RADIUS,
			return r_CurrentRadius;
		case 3359:		// GET_SPIRALVEL,
			return r_SpiVel * 50;
		case 3360:		// GET_MINRADIUS,
			return r_Rmin;
		case 3361:		// GET_MAXRADIUS
			return r_Rmax;
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
		r_OnEnd = stream.readInt();
		r_CX = stream.readInt();
		r_CY = stream.readInt();
		r_Rmin = stream.readInt();
		r_Rmax = stream.readInt();
		r_AngVel = stream.readDouble();
		r_SpiVel = stream.readDouble();
		r_CurrentRadius = stream.readDouble();
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
		stream.writeInt(r_OnEnd);
		stream.writeInt(r_CX);
		stream.writeInt(r_CY);
		stream.writeInt(r_Rmin);
		stream.writeInt(r_Rmax);
		stream.writeDouble(r_AngVel);
		stream.writeDouble(r_SpiVel);
		stream.writeDouble(r_CurrentRadius);
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
