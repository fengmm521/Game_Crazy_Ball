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
// CRUNMVTSINWAVE
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_sinewave.h"
#import "CObject.h"
#import "CAnim.h"
#import "CRun.h"
#import "CRunFrame.h"
#import "CRCom.h"
#import "CServices.h"
#import "CFile.h"

@implementation CRunMvtclickteam_sinewave

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_dwFlags = [file readAInt];
	m_dwSpeed = [file readAInt];
	m_dwFinalX = [file readAInt];
	m_dwFinalY = [file readAInt];
	m_dwAmp = [file readAInt];
	m_dwAngVel = [file readAInt];
	m_dwStartAngle = [file readAInt];
	m_dwOnEnd = [file readAInt];
	
	r_StartX = ho->hoX;
	r_StartY = ho->hoY;
	r_FinalX = m_dwFinalX;
	r_FinalY = m_dwFinalY;
	r_CurrentX = r_StartX;
	r_CurrentY = r_StartY;
	r_Amp = m_dwAmp;
	r_AngVel = (m_dwAngVel * (M_PI / 180.0)) / 50.0;
	r_CurrentAngle = m_dwStartAngle * (M_PI / 180.0);
	//	r_Stopped = (bool)( 1 - m_pMvt->m_dwFlags);
	r_Stopped = ((m_dwFlags & MFLAGSIN_MOVEATSTART) == 0);
	r_OnEnd = m_dwOnEnd;
	
	//*** Linear motion components;
	r_Speed = m_dwSpeed;
	ho->roc->rcSpeed = r_Speed;
	
	if (r_Speed != 0)
	{
		r_Angle = atan2((r_FinalY - r_StartY), (r_FinalX - r_StartX));
		
		r_Cx = cos(r_Angle + M_PI * 0.5);
		r_Cy = sin(r_Angle + M_PI * 0.5);
		
		r_Dx = cos(r_Angle) * (r_Speed / 50.0);
		r_Dy = sin(r_Angle) * (r_Speed / 50.0);
		
		if (absDouble(r_Dx) > 0.0001)
		{
			r_Steps = absDouble((r_FinalX - r_StartX) / r_Dx);
		}
		else if (absDouble(r_Dy) > 0.0001)
		{
			r_Steps = absDouble((r_FinalY - r_StartY) / r_Dy);
		}
		else
		{
			r_Steps = 0.0;
		}
	}
	else
	{
		r_Dx = 0;
		r_Dy = 0;
		r_Steps = 0.0;
	}
}

-(BOOL)move
{
	//*** Object needs to be moved?
	if (r_Speed != 0 && !r_Stopped)
	{
		if (r_Steps > 0.0)
		{
			double calculs;
			
			//*** Ensure angle is in the range 0 to 360 degrees
			if (r_CurrentAngle < 0)
			{
				r_CurrentAngle += 2 * M_PI;
			}
			else if (r_CurrentAngle >= 2 * M_PI)
			{
				r_CurrentAngle -= 2 * M_PI;
			}
			
			double angVel = r_AngVel;
			if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
			{
				angVel = angVel * ho->hoAdRunHeader->rh4MvtTimerCoef;
			}
			double dx = r_Dx;
			if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
			{
				dx = dx * ho->hoAdRunHeader->rh4MvtTimerCoef;
			}
			double dy = r_Dy;
			if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
			{
				dy = dy * ho->hoAdRunHeader->rh4MvtTimerCoef;
			}
			
			if (r_Steps > 1.0)
			{
				//*** This is not the final section of movement
				r_CurrentX += dx;
				r_CurrentY += dy;
				r_CurrentAngle -= angVel;
				calculs = 1.0;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				r_Steps -= calculs;
				if (r_Steps<0.1)
				{
					r_Steps=0.1;
				}
			}
			else
			{
				//**** Final section of movement, handle movement completion
				r_CurrentX += r_Steps * dx;
				r_CurrentY += r_Steps * dy;
				r_CurrentAngle -= r_Steps * angVel;
				calculs = 1.0;
				if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
				{
					calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
				}
				r_Steps -= calculs;
				if (r_Steps<0.1)
				{
					r_Steps=0.1;
				}
				
				[self animations:ANIMID_WALK];
				
				if (r_OnEnd == ONEND_STOP)
				{
					double amp = r_Amp * sin(r_CurrentAngle);
					
					//*** Move object, run animation and collision detection
					ho->hoX = (int) (r_CurrentX + r_Cx * amp);
					ho->hoY = (int) (r_CurrentY + r_Cy * amp);
					r_Stopped = YES;
				}
				else if (r_OnEnd == ONEND_RESET)
				{
					[self reset];
				}
				else if (r_OnEnd == ONEND_BOUNCE)
				{
					[self bounce:NO];
				}
				else if (r_OnEnd == ONEND_REVERSE)
				{
					[self reverse];
				}
				
				[self collisions];
				return YES;
			}
			
			//*** Sine motion amplitude
			double amp = r_Amp * sin(r_CurrentAngle);
			
			//*** Move object, run animation and collision detection
			[self animations:ANIMID_WALK];
			ho->hoX = (int) (r_CurrentX + r_Cx * amp);
			ho->hoY = (int) (r_CurrentY + r_Cy * amp);
			[self collisions];
			
			//*** Indicate the object has been moved
			return YES;
		}
	}
	[self animations:ANIMID_STOP];
	[self collisions];
	
	//*** The object has not been moved
	return NO;
}

-(void)reset
{
	ho->hoX = r_StartX;
	ho->hoY = r_StartY;
	
	r_CurrentX = r_StartX;
	r_CurrentY = r_StartY;
	r_CurrentAngle = (m_dwStartAngle) * (M_PI / 180.0);
	
	if (r_Speed != 0)
	{
		r_Angle = atan2((r_FinalY - r_StartY), (r_FinalX - r_StartX));
		
		r_Cx = cos(r_Angle + M_PI / 2);
		r_Cy = sin(r_Angle + M_PI / 2);
		
		r_Dx = cos(r_Angle) * (r_Speed / 50.0);
		r_Dy = sin(r_Angle) * (r_Speed / 50.0);
		
		if (absDouble(r_Dx) > 0.0001)
		{
			r_Steps = absDouble((r_FinalX - r_StartX) / r_Dx);
		}
		else if (std::abs(r_Dy) > 0.0001)
		{
			r_Steps = absDouble((r_FinalY - r_StartY) / r_Dy);
		}
		else
		{
			r_Steps = 0.0;
		}
	}
	else
	{
		r_Steps = 0.0;
	}
}

-(void)setPosition:(int)x withY:(int)y
{
	r_CurrentX -= ho->hoX - x;
	r_CurrentY -= ho->hoY - y;
	
	ho->hoX = x;
	ho->hoY = y;
}

-(void)setXPosition:(int)x
{
	r_CurrentX -= ho->hoX - x;
	ho->hoX = x;
}

-(void)setYPosition:(int)y
{
	r_CurrentY -= ho->hoY - y;
	ho->hoY = y;
}

-(void)stop:(BOOL)bCurrent
{
	r_Stopped = YES;
}

-(void)bounce:(BOOL)bCurrent
{
	double amp = r_Amp * sin(r_CurrentAngle);
	ho->hoX = (int) (r_CurrentX + r_Cx * amp);
	ho->hoY = (int) (r_CurrentY + r_Cy * amp);
	
	int tmpX = r_FinalX;
	int tmpY = r_FinalY;
	
	r_FinalX = r_StartX;
	r_FinalY = r_StartY;
	
	r_StartX = tmpX;
	r_StartY = tmpY;
	
	r_Angle += M_PI;
	
	if (r_Speed != 0)
	{
		r_Dx *= -1;
		r_Dy *= -1;
		
		if (absDouble(r_Dx) > 0.0001)
		{
			r_Steps = absDouble((r_FinalX - r_CurrentX) / r_Dx);
		}
		else if (absDouble(r_Dy) > 0.0001)
		{
			r_Steps = absDouble((r_FinalY - r_CurrentY) / r_Dy);
		}
		else
		{
			r_Steps = 0.0;
		}
	}
	else
	{
		r_Dx = 0;
		r_Dy = 0;
		r_Steps = 0.0;
	}
}

-(void)reverse
{
	//*** Finish moving the object first *****
	double amp = r_Amp * sin(r_CurrentAngle);
	ho->hoX = (int) (r_CurrentX + r_Cx * amp);
	ho->hoY = (int) (r_CurrentY + r_Cy * amp);
	
	int tmpX = r_FinalX;
	int tmpY = r_FinalY;
	
	r_FinalX = r_StartX;
	r_FinalY = r_StartY;
	
	r_StartX = tmpX;
	r_StartY = tmpY;
	
	r_AngVel *= -1;
	r_Angle += M_PI;
	
	if (r_Speed != 0)
	{
		r_Dx *= -1;
		r_Dy *= -1;
		
		if (absDouble(r_Dx) > 0.0001)
		{
			r_Steps = absDouble((r_FinalX - r_CurrentX) / r_Dx);
		}
		else if (absDouble(r_Dy) > 0.0001)
		{
			r_Steps = absDouble((r_FinalY - r_CurrentY) / r_Dy);
		}
		else
		{
			r_Steps = 0.0;
		}
	}
	else
	{
		r_Dx = 0;
		r_Dy = 0;
		r_Steps = 0.0;
	}
}

-(void)start
{
	r_Stopped = NO;
}

-(void)setSpeed:(int)speed
{
	if (speed < 0)
	{
		speed = 0; //** Do not allow negative speed
	}
	//*** Linear motion components;
	r_Speed = speed;
	ho->roc->rcSpeed = r_Speed;
	
	if (r_Speed != 0)
	{
		r_Dx = cos(r_Angle) * (r_Speed / 50.0);
		r_Dy = sin(r_Angle) * (r_Speed / 50.0);
		
		if (absDouble(r_Dx) > 0.0001)
		{
			r_Steps = absDouble((r_FinalX - r_CurrentX) / r_Dx);
		}
		else if (absDouble(r_Dx) > 0.0001)
		{
			r_Steps = absDouble((r_FinalY - r_CurrentY) / r_Dy);
		}
		else
		{
			r_Steps = 0.0;
		}
	}
	else
	{
		r_Dx = 0;
		r_Dy = 0;
		r_Steps = 0.0;
	}
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
		case 3545:	    // SET_SINEWAVE_SPEED = 3545,
			param = (int)[self getParamDouble];
			[self setSpeed:param];
			break;
		case 3546:	    // SET_SINEWAVE_STARTX,
			param = (int)[self getParamDouble];
			r_StartX = param;
			break;
		case 3547:	    // SET_SINEWAVE_STARTY,
			param = (int)[self getParamDouble];
			r_StartY = param;
			break;
		case 3548:	    // SET_SINEWAVE_FINALX,
			param = (int)[self getParamDouble];
			r_FinalX = param;
			break;
		case 3549:	    // SET_SINEWAVE_FINALY,
			param = (int)[self getParamDouble];
			r_FinalY = param;
			break;
		case 3550:	    // SET_SINEWAVE_AMPLITUDE,
			param = (int)[self getParamDouble];
			r_Amp = MAX(param, 0);
			break;
		case 3551:	    // SET_SINEWAVE_ANGVEL,
			param = (int)[self getParamDouble];
			r_AngVel = param * (M_PI / 180.0) / 50.0;
		case 3552:	    // SET_SINEWAVE_STARTANG,
			param = (int)[self getParamDouble];
			m_dwStartAngle = (int) MAX(param * (M_PI / 180.0), 0);
			break;
		case 3553:	    // SET_SINEWAVE_CURRENTANGLE,
			param = (int)[self getParamDouble];
			r_CurrentAngle = MAX(param * (M_PI / 180.0), 0);
			break;
		case 3554:	    // GET_SINEWAVE_SPEED,
			return ho->roc->rcSpeed;
		case 3555:	    // GET_SINEWAVE_STARTX,
			return r_Cx;
		case 3556:	    // GET_SINEWAVE_STARTY,
			return r_StartY;
		case 3557:	    // GET_SINEWAVE_FINALX,
			return r_FinalX;
		case 3558:	    // GET_SINEWAVE_FINALY,
			return r_FinalY;
		case 3559:	    // GET_SINEWAVE_AMPLITUDE,
			return r_Amp;
		case 3560:	    // GET_SINEWAVE_ANGVEL,
			return r_AngVel * 50.0 * (180.0 / M_PI);
		case 3561:	    // GET_SINEWAVE_STARTANG,
			return m_dwStartAngle;
		case 3562:	    // GET_SINEWAVE_CURRENTANGLE,
			return r_CurrentAngle * (180.0 / M_PI);
		case 3563:	    // RESET_SINEWAVE,
			[self reset];
			break;
		case 3564:	    // SET_SINEWAVE_ONCOMPLETION
			param = (int) [self getParamDouble];
			int option = param;
			if (option == ONEND_STOP)
			{
				r_OnEnd = ONEND_STOP;
			}
			else if (option == ONEND_RESET)
			{
				r_OnEnd = ONEND_RESET;
			}
			else if (option == ONEND_BOUNCE)
			{
				r_OnEnd = ONEND_BOUNCE;
			}
			else if (option == ONEND_REVERSE)
			{
				r_OnEnd = ONEND_REVERSE;
			}
			break;
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
 r_CurrentX = stream.readDouble();
 r_CurrentY = stream.readDouble();
 r_Stopped = stream.readBoolean();
 r_OnEnd = stream.readInt();
 r_Speed = stream.readInt();
 r_StartX = stream.readInt();
 r_StartY = stream.readInt();
 r_FinalX = stream.readInt();
 r_FinalY = stream.readInt();
 r_Dx = stream.readDouble();
 r_Dy = stream.readDouble();
 r_Steps = stream.readDouble();
 r_Angle = stream.readDouble();
 r_Amp = stream.readDouble();
 r_AngVel = stream.readDouble();
 r_CurrentAngle = stream.readDouble();
 r_Cx = stream.readDouble();
 r_Cy = stream.readDouble();
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
 stream.writeDouble(r_CurrentX);
 stream.writeDouble(r_CurrentY);
 stream.writeBoolean(r_Stopped);
 stream.writeInt(r_OnEnd);
 stream.writeInt(r_Speed);
 stream.writeInt(r_StartX);
 stream.writeInt(r_StartY);
 stream.writeInt(r_FinalX);
 stream.writeInt(r_FinalY);
 stream.writeDouble(r_Dx);
 stream.writeDouble(r_Dy);
 stream.writeDouble(r_Steps);
 stream.writeDouble(r_Angle);
 stream.writeDouble(r_Amp);
 stream.writeDouble(r_AngVel);
 stream.writeDouble(r_CurrentAngle);
 stream.writeDouble(r_Cx);
 stream.writeDouble(r_Cy);
 }
 catch (IOException e)
 {
 return 1;
 }
 return 0;
 }
 */

@end
