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
// CRUNMVTPINBALL : movement pinball
//
//----------------------------------------------------------------------------------
#import "CRunMvtpinball.h"
#import "CObject.h"
#import "CAnim.h"
#import "CRCom.h"
#import "CRun.h"
#import "CFile.h"
#import "CRunFrame.h"
#import "CPoint.h"
#import "CColMask.h"

@implementation CRunMvtpinball

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_dwInitialSpeed = [file readAInt];
	m_dwDeceleration = [file readAInt];
	m_dwGravity = [file readAInt];
	m_dwInitialDir = [file readAInt];
	m_dwFlags = [file readAInt];
	
	// Initialisations
	m_X = ho->hoX;
	m_Y = ho->hoY;
	ho->roc->rcSpeed = m_dwInitialSpeed;
	
	// Finds the initial direction
	ho->roc->rcDir = [self dirAtStart:m_dwInitialDir];
	double angle = (ho->roc->rcDir * 2 * M_PI) / 32.0;
	
	// Calculates the vectors
	m_gravity = m_dwGravity;
	m_deceleration = m_dwDeceleration;
	m_xVector = ho->roc->rcSpeed * cos(angle);
	m_yVector = -ho->roc->rcSpeed * sin(angle);
	
	// Move at start
	m_flags = 0;
	if ((m_dwFlags & EFLAG_MOVEATSTART) == 0)
	{
		m_flags |= MPINFLAG_STOPPED;
	}
}

-(double)getAngle:(double)vX withVY:(double)vY
{
	double vector = sqrt(vX * vX + vY * vY);
	if (vector == 0.0)
	{
		return 0.0;
	}
	double angle = acos(vX / vector);
	if (vY > 0.0)
	{
		angle = 2.0 * M_PI - angle;
	}
	return angle;
}

-(double)getVector:(double)vX withVY:(double)vY
{
	return sqrt(vX * vX + vY * vY);
}

-(BOOL)move
{
	// Stopped?
	if ((m_flags & MPINFLAG_STOPPED) != 0)
	{
		[self animations:ANIMID_STOP];
		[self collisions];
		return NO;
	}
	
	// Increase Y speed
	m_yVector += m_gravity / 10.0;
	
	// Get the current vector of the ball
	double angle = [self getAngle:m_xVector withVY:m_yVector];	// Get the angle and vector
	double vector = [self getVector:m_xVector withVY:m_yVector];
	double calculs = m_deceleration;
	if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
	{
		calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
	}
	vector -= calculs / 50.0;
	if (vector < 0.0)
	{
		vector = 0.0;
	}
	m_xVector = vector * cos(angle);					// Restores X and Y speeds
	m_yVector = -vector * sin(angle);
	
	// Calculate the new position
	calculs = m_xVector;
	if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
	{
		calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
	}
	m_X = m_X + (calculs / 10.0);
	calculs = m_yVector;
	if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
	{
		calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
	}
	m_Y = m_Y + (calculs / 10.0);
	
	// Performs the animation
	ho->roc->rcSpeed = (int) vector;
	if (ho->roc->rcSpeed > 100)
	{
		ho->roc->rcSpeed = 100;
	}
	ho->roc->rcDir = (int) ((angle * 32) / (2.0 * M_PI));
	[self animations:ANIMID_WALK];
	
	// detects the collisions
	ho->hoX = (int) m_X;
	ho->hoY = (int) m_Y;
	[self collisions];
	
	// The object has been moved
	return YES;
}

-(void)setPosition:(int)x withY:(int)y
{
	ho->hoX = (int) x;
	ho->hoY = (int) y;
	m_X = x;
	m_Y = y;
}

-(void)setXPosition:(int)x
{
	ho->hoX = (int) x;
	m_X = x;
}

-(void)setYPosition:(int)y
{
	ho->hoY = (int) y;
	m_Y = y;
}

-(void)stop:(BOOL)bCurrent
{
	m_flags |= MPINFLAG_STOPPED;
}

-(void)bounce:(BOOL)bCurrent
{
	if (!bCurrent)
	{
		m_xVector = -m_xVector;
		m_yVector = -m_yVector;
		return;
	}
	
	// Takes the object against the obstacle
	
	CApproach ap = [self approachObject:ho->hoX withDestY:ho->hoY andOriginX:ho->roc->rcOldX andOriginY:ho->roc->rcOldY andFoot:0 andPlane:CM_TEST_PLATFORM];
	ho->hoX = m_X = ap.point.x;
	ho->hoY = m_Y = ap.point.y;
	
	// Get the current vector of the ball
	double angle = [self getAngle:m_xVector withVY:m_yVector];
	double vector = [self getVector:m_xVector withVY:m_yVector];
	
	// Finds the shape of the obstacle
	double a;
	double aFound = -1000;
	for (a = 0.0; a < 2.0 * M_PI; a += M_PI / 32.0)
	{
		double xVector = 16 * cos(angle + a);
		double yVector = -16 * sin(angle + a);
		double x = m_X + xVector;
		double y = m_Y + yVector;
		
		if ([self testPosition:(int)x withY:(int)y andFoot:0 andPlane:CM_TEST_PLATFORM andFlag:NO])
		{
			aFound = a;
			break;
		}
	}
	
	// If nothing is found, simply go backward
	if (aFound == -1000)
	{
		m_xVector = -m_xVector;
		m_yVector = -m_yVector;
	}
	else
	{
		// The angle is found, proceed with the bounce
		angle += aFound * 2;
		if (angle > 2.0 * M_PI)
		{
			angle -= 2.0 * M_PI;
		}
		ho->roc->rcDir = (int) ((angle * 32) / (2.0 * M_PI));
		
		// Restores the speed vectors
		m_xVector = vector * cos(angle);
		m_yVector = -vector * sin(angle);
	}
}

-(void)reverse
{
	m_xVector = -m_xVector;
	m_yVector = -m_yVector;
}

-(void)start
{
	m_flags &= ~MPINFLAG_STOPPED;
}

-(void)setSpeed:(int)speed
{
	ho->roc->rcSpeed = speed;
	
	// Gets the current speed vector
	double angle = [self getAngle:m_xVector withVY:m_yVector];
//	double vector = [self getVector:m_xVector withVY:m_yVector];
	
	// Changes the current x and y vectors
	m_xVector = speed * cos(angle);
	m_yVector = -speed * sin(angle);
}

-(void)setDir:(int)dir
{
	ho->roc->rcDir = dir;
	
	// Get the current speed vector
	double angle;	//= [self getAngle:m_xVector withVY:m_yVector];
	double vector = [self getVector:m_xVector withVY:m_yVector];
	
	// Converts the angle in 32 directions to a angle in radian
	angle = dir * 2.0 * M_PI / 32.0;
	
	// Changes the speeds
	m_xVector = vector * cos(angle);
	m_yVector = -vector * sin(angle);
}

-(void)setGravity:(int)gravity
{
	m_gravity = gravity;
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
		default:		// SET_INVADERS_SPEED = 3745,
			m_gravity = [self getParamDouble];
			break;
	}
	return 0;
}

-(int)getSpeed
{
	return ho->roc->rcSpeed;
}

-(int)getDeceleration
{
	return (int) m_deceleration;
}

-(int)getGravity
{
	return (int) m_gravity;
}

/*
public int loadPosition(DataInputStream stream)
{
	try
	{
		m_gravity = stream.readDouble();
		m_xVector = stream.readDouble();
		m_yVector = stream.readDouble();
		m_angle = stream.readDouble();
		m_X = stream.readDouble();
		m_Y = stream.readDouble();
		m_deceleration = stream.readDouble();
		m_flags = stream.readInt();
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
		stream.writeDouble(m_gravity);
		stream.writeDouble(m_xVector);
		stream.writeDouble(m_yVector);
		stream.writeDouble(m_angle);
		stream.writeDouble(m_X);
		stream.writeDouble(m_Y);
		stream.writeDouble(m_deceleration);
		stream.writeInt(m_flags);
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/
@end
