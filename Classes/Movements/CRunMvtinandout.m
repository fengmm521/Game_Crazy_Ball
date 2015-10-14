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
// CRUNMVTINANDOUT : Movement inandout!
//
//----------------------------------------------------------------------------------
#import "CRunMvtinandout.h"
#import "CObject.h"
#import "CRun.h"
#import "CFile.h"
#import "CRCom.h"
#import "CAnim.h"

@implementation CRunMvtinandout

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_type=[file readAInt];
	m_direction=[file readAInt];
	m_speed=[file readAInt];
	m_flags=[file readAInt];
	m_destX=[file readAInt];
	m_destY=[file readAInt];
	m_angle=(m_direction*M_PI)/180.0;
	m_maxPente=0;
	
	if ((m_flags&MFLAG_MOVEATSTART)!=0)
	{
		if ((m_flags&MFLAG_OUTATSTART)==0)
		{
			m_moveStatus=MOVESTATUS_PREPAREOUT;
		}
		else
		{
			m_moveStatus=MOVESTATUS_PREPAREIN;
		}
		m_flags&=~MFLAG_STOPPED;
	}
	else
	{
		if ((m_flags&MFLAG_OUTATSTART)==0)
		{
			m_moveStatus=MOVESTATUS_WAITIN;
		}
		else
		{
			m_moveStatus=MOVESTATUS_WAITOUT;
		}
	}
}

-(BOOL)move
{
	// Calcule la position de sortie
	if (m_maxPente==0)
	{
		double maxPente;
		int x=0, y=0, rightX, bottomY;
		m_startX=ho->hoX;
		m_startY=ho->hoY;
		
		if (m_destX!=0 || m_destY!=0)
		{
			int vX=m_destX-m_startX;
			int vY=m_destY-m_startY;
			maxPente=sqrt(vX*vX+vY*vY);
			if (maxPente==0.0)
			{
				m_angle=0.0;
			}
			else
			{
				m_angle=acos(vX/maxPente);
				if (m_destY>m_startY)
				{
					m_angle=2.0*M_PI-m_angle;
				}
			}
		}
		else
		{
			for (maxPente=0; maxPente<100000; maxPente+=5)
			{
				x=(int)(cos(m_angle)*maxPente+m_startX);
				y=(int)(-sin(m_angle)*maxPente+m_startY);
				rightX=x+ho->hoImgWidth;
				bottomY=y+ho->hoImgHeight;
				if (x>ho->hoAdRunHeader->rhLevelSx)
				{
					break;
				}
				if (y>ho->hoAdRunHeader->rhLevelSy)
				{
					break;
				}
				if (rightX<0)
				{
					break;
				}
				if (bottomY<0)
				{
					break;
				}
			}
			m_destX=x;
			m_destY=y;
		}
		if (maxPente==0)
		{
			maxPente=5;
		}
		m_maxPente=maxPente;
	}
	
	BOOL bRet=NO;
	if ((m_flags&MFLAG_OUTATSTART)!=0)
	{
		m_flags&=~MFLAG_OUTATSTART;
		ho->hoX=m_destX;
		ho->hoY=m_destY;
		bRet=YES;
	}
	
	// Stopped?
	if ((m_flags&MFLAG_STOPPED)!=0)
	{
		[self animations:ANIMID_STOP];
		[self collisions];
		return ho->roc->rcChanged;
	}
	
	switch(m_moveStatus)
	{
        case MOVESTATUS_PREPAREOUT:
            ho->hoX=m_startX;
            ho->hoY=m_startY;
            m_moveTimerStart=ho->hoAdRunHeader->rhTimer;
            m_moveStatus=MOVESTATUS_MOVEOUT;
            break;
        case MOVESTATUS_MOVEOUT:
		{
			int deltaTime=(int)(ho->hoAdRunHeader->rhTimer-m_moveTimerStart);
			if (deltaTime>=m_speed)
			{
				ho->hoX=m_destX;
				ho->hoY=m_destY;
				m_moveStatus=MOVESTATUS_WAITOUT;
			}
			else
			{
				switch (m_type)
				{
                    case MOVETYPE_LINEAR:
					{
						double pente=(m_maxPente*((double)deltaTime/(double)m_speed));
						ho->hoX=(int)(cos(m_angle)*pente+m_startX);
						ho->hoY=(int)(-sin(m_angle)*pente+m_startY);
					}
                        break;
                    case MOVETYPE_SMOOTH:
					{
						double pente=m_maxPente-cos(M_PI/2*((double)deltaTime/(double)m_speed))*m_maxPente;
						ho->hoX=(int)(cos(m_angle)*pente+m_startX);
						ho->hoY=(int)(-sin(m_angle)*pente+m_startY);
					}
                    break;
				}
			}
			ho->roc->rcDir=(int)((m_direction*32)/360);
			ho->roc->rcSpeed=100;
			[self animations:ANIMID_WALK];
			bRet=YES;
		}
            break;
        case MOVESTATUS_WAITOUT:
            [self animations:ANIMID_STOP];
			bRet=ho->roc->rcChanged;
            break;
        case MOVESTATUS_POSITIONOUT:
            ho->hoX=m_destX;
            ho->hoY=m_destY;
            m_moveStatus=MOVESTATUS_WAITOUT;
            bRet=YES;
            break;
        case MOVESTATUS_PREPAREIN:
            ho->hoX=m_destX;
            ho->hoY=m_destY;
            m_moveTimerStart=ho->hoAdRunHeader->rhTimer;
            m_moveStatus=MOVESTATUS_MOVEIN;
            break;
        case MOVESTATUS_MOVEIN:
		{
			int deltaTime=(int)(ho->hoAdRunHeader->rhTimer-m_moveTimerStart);
			if (deltaTime>=m_speed)
			{
				ho->hoX=m_startX;
				ho->hoY=m_startY;
				m_moveStatus=MOVESTATUS_WAITIN;
			}
			else
			{
				switch (m_type)
				{
                    case MOVETYPE_LINEAR:
					{
						double pente=(m_maxPente-(m_maxPente*((double)deltaTime/(double)m_speed)));
						ho->hoX=(int)(cos(m_angle)*pente+m_startX);
						ho->hoY=(int)(-sin(m_angle)*pente+m_startY);
					}
                        break;
                    case MOVETYPE_SMOOTH:
					{
						double pente=m_maxPente-sin(M_PI/2*((double)deltaTime/(double)m_speed))*m_maxPente;
						ho->hoX=(int)(cos(m_angle)*pente+m_startX);
						ho->hoY=(int)(-sin(m_angle)*pente+m_startY);
					}
                        break;
				}
			}
			ho->roc->rcDir=((int)((m_direction*32)/360+16))%32;
			ho->roc->rcSpeed=100;
			[self animations:ANIMID_WALK];
			bRet=YES;
		}
            break;
        case MOVESTATUS_WAITIN:
            [self animations:ANIMID_STOP];
			bRet=ho->roc->rcChanged;
            break;
        case MOVESTATUS_POSITIONIN:
            ho->hoX=m_startX;
            ho->hoY=m_startY;
            m_moveStatus=MOVESTATUS_WAITIN;
            bRet=YES;
            break;
	}
	
	// detects the collisions
	[self collisions];
	
	// The object has been moved
	return bRet;
}

-(void)stop:(BOOL)bCurrent
{
	m_flags|=MFLAG_STOPPED;
	m_stopTimer=ho->hoAdRunHeader->rhTimer;
}

-(void)start
{
	if ((m_flags&MFLAG_STOPPED)!=0)
	{
		m_flags&=~MFLAG_STOPPED;
		m_moveTimerStart+=ho->hoAdRunHeader->rhTimer-m_stopTimer;
	}
	if (m_moveStatus==MOVESTATUS_WAITOUT)
	{
		m_moveStatus=MOVESTATUS_PREPAREIN;
	}
	else if (m_moveStatus==MOVESTATUS_WAITIN)
	{
		m_moveStatus=MOVESTATUS_PREPAREOUT;
	}
}

-(double)actionEntry:(int)action
{
	switch (action)
	{
/*            // Load / save position
		case 0x1010:	// MVTACTION_SAVEPOSITION:
			return savePosition(getOutputStream());
		case 0x1011:	// MVTACTION_LOADPOSITION:
			return loadPosition(getInputStream());
*/			
		case ACTION_POSITIONIN:
			m_moveStatus=MOVESTATUS_POSITIONIN;
			m_flags&=~MFLAG_STOPPED;
			break;
		case ACTION_POSITIONOUT:
			m_moveStatus=MOVESTATUS_POSITIONOUT;
			m_flags&=~MFLAG_STOPPED;
			break;
		case ACTION_MOVEIN:
			m_moveStatus=MOVESTATUS_PREPAREIN;
			m_flags&=~MFLAG_STOPPED;
			break;
		case ACTION_MOVEOUT:
			m_moveStatus=MOVESTATUS_PREPAREOUT;
			m_flags&=~MFLAG_STOPPED;
			break;
		default:
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
		m_direction=stream.readInt();
		m_speed=stream.readInt();
		m_flags=stream.readInt();
		m_moveStatus=stream.readInt();
		m_angle=stream.readDouble();
		m_maxPente=stream.readDouble();
		m_moveTimerStart=stream.readLong();
		m_stopTimer=stream.readLong();
		m_type=stream.readInt();
		m_startX=stream.readInt();
		m_startY=stream.readInt();
		m_destX=stream.readInt();
		m_destY=stream.readInt();
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
		stream.writeInt(m_direction);
		stream.writeInt(m_speed);
		stream.writeInt(m_flags);
		stream.writeInt(m_moveStatus);
		stream.writeDouble(m_angle);
		stream.writeDouble(m_maxPente);
		stream.writeLong(m_moveTimerStart);
		stream.writeLong(m_stopTimer);
		stream.writeInt(m_type);
		stream.writeInt(m_startX);
		stream.writeInt(m_startY);
		stream.writeInt(m_destX);
		stream.writeInt(m_destY);
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/

@end
