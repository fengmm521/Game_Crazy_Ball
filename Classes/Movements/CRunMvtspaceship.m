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
// CRUNMVTSPACESHIP : Movement spaceship!
//
//----------------------------------------------------------------------------------
#import "CRunMvtspaceship.h"
#import "CAnim.h"
#import "CObject.h"
#import "CRCom.h"
#import "CRun.h"
#import "CRunFrame.h"
#import "CAnim.h"
#import "CServices.h"
#import "CFile.h"
#import "CPoint.h"
#import "CColMask.h"

@implementation CRunMvtspaceship

-(void)initialize:(CFile*)file
{
	// Charge les donnÈes
	[file skipBytes:1];
	m_dwPower = [file readAInt];
	m_dwRotationSpeed = [file readAInt];
	m_dwInitialSpeed = [file readAInt];
	m_dwInitialDir = [file readAInt];
	m_dwDeceleration = [file readAInt];
	m_dwGravity = [file readAInt];
	m_dwGravityDir = [file readAInt];
	m_dwPlayer = [file readAInt];
	m_dwButton = [file readAInt];
	m_dwFlags = [file readAInt];
	
	// Initialisations
	m_X = ho->hoX;
	m_Y = ho->hoY;
	
	// Finds the initial speed vectors
	ho->roc->rcSpeed = m_dwInitialSpeed;
	ho->roc->rcDir = [self dirAtStart:m_dwInitialDir];
	double angle = (ho->roc->rcDir * 2 * M_PI) / 32.0;
	m_xVector = ho->roc->rcSpeed * cos(angle);
	m_yVector = -ho->roc->rcSpeed * sin(angle);
	
	// Calculates the vectors
	m_gravity = m_dwGravity;
	m_gravityAngle = [self dirAtStart:m_dwGravityDir];
	angle = (m_gravityAngle * 2 * M_PI) / 32.0;
	m_xGravity = m_gravity * cos(angle);
	m_yGravity = -m_gravity * sin(angle);
	
	// Other values
	m_deceleration = m_dwDeceleration;
	m_rotationSpeed = m_dwRotationSpeed;
	m_power = m_dwPower;
	m_button = m_dwButton;
	m_bStop = NO;
	ho->roc->rcPlayer = m_dwPlayer;
	m_rotCounter = 0;
	
	m_autoReactor = NO;
	m_autoRotateRight = NO;
	m_autoRotateLeft = NO;
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
	int anim = ANIMID_WALK;
	
	if (m_bStop == NO)
	{
		// Get the joystick
		unsigned char j = rh->rhPlayer;
		
		// Rotation of the ship
		if ((j & 15) != 0 || (m_autoRotateRight || m_autoRotateLeft))
		{
			int rotSpeed = m_rotationSpeed;
			if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
			{
				rotSpeed = (int) (((double) rotSpeed) * ho->hoAdRunHeader->rh4MvtTimerCoef);
			}
			m_rotCounter += rotSpeed;
			if (m_rotCounter >= 100)
			{
				m_rotCounter -= 100;
				if ((j & 0x04) != 0 || m_autoRotateLeft)
				{
					m_autoRotateLeft = NO;
					ho->roc->rcDir += 1;
					if (ho->roc->rcDir >= 32)
					{
						ho->roc->rcDir -= 32;
					}
				}
				if ((j & 0x08) != 0 || m_autoRotateRight)
				{
					m_autoRotateRight = NO;
					ho->roc->rcDir -= 1;
					if (ho->roc->rcDir < 0)
					{
						ho->roc->rcDir += 32;
					}
				}
			}
		}
		
		// Movement of the ship
		unsigned char mask = 0x01;
		switch (m_button)
		{
			case 0:
				mask = 0x01;
				break;
			case 1:
				mask = 0x10;
				break;
			case 2:
				mask = 0x20;
				break;
		}
		
		double calculs;
		if ((j & mask) != 0 || (m_autoReactor))
		{
			double angle = (ho->roc->rcDir * 2 * M_PI) / 32.0;
			
			calculs = m_power;
			if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
			{
				calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
			}
			
			double m_xPower = calculs * cos(angle);
			double m_yPower = -calculs * sin(angle);
			
			m_xVector += m_xPower / 150.0;
			m_yVector += m_yPower / 150.0;
			
			anim = ANIMID_JUMP;
			
			// switch off automatic reactor (as have applied it)
			m_autoReactor = NO;
		}
		
		// Gravity
		calculs = m_xGravity;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		m_xVector += calculs / 150.0;
		calculs = m_yGravity;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		m_yVector += calculs / 150.0;
		
		// Deceleration
		double angle = [self getAngle:m_xVector withVY:m_yVector];	// Get the angle and vector
		double vector = [self getVector:m_xVector withVY:m_yVector];	// Get the angle and vector
		calculs = m_deceleration;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		vector -= calculs / 250.0;
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
		
		ho->roc->rcSpeed = (int) vector;
	}
	
	// Performs the animation
	if (ho->roc->rcSpeed > 100)
	{
		ho->roc->rcSpeed = 100;
	}
	[self animations:anim];
	
	// detects the collisions
	ho->hoX = (int) m_X;
	ho->hoY = (int) m_Y;
	[self collisions];
	
	return YES;
}

-(double)fmodf:(double)value
{
	int i = (int) value;
	return value - i;
}

-(void)setPosition:(int)x withY:(int)y
{
	ho->hoX = x;
	ho->hoY = y;
	
	double frac;
	frac = [self fmodf:m_X];
	m_X = x + frac;
	frac = [self fmodf:m_Y];
	m_Y = y + frac;
}

-(void)setXPosition:(int)x
{
	ho->hoX = (short) x;
	double frac;
	frac = [self fmodf:m_X];
	m_X = x + frac;
}

-(void)setYPosition:(int)y
{
	ho->hoY = (short) y;
	double frac;
	frac = [self fmodf:m_Y];
	m_Y = y + frac;
}

-(void)stop:(BOOL)bCurrent
{
	m_bStop = YES;
}

-(void)bounce:(BOOL)bCurrent
{
	if (bCurrent)
	{
		CApproach ap = [self approachObject:ho->hoX withDestY:ho->hoY andOriginX:ho->roc->rcOldX andOriginY:ho->roc->rcOldY andFoot:0 andPlane:CM_TEST_PLATFORM];
		ho->hoX = m_X = ap.point.x;
		ho->hoY = m_Y = ap.point.y;
	}
	m_xVector = -m_xVector;
	m_yVector = -m_yVector;
}

-(void)reverse
{
	m_xVector = -m_xVector;
	m_yVector = -m_yVector;
}

-(void)start
{
	m_bStop = NO;
}

-(void)setSpeed:(int)speed
{
	if (speed < 0)
	{
		speed = 0;
	}
	if (speed > 100)
	{
		speed = 100;
	}
	
	double angle = (ho->roc->rcDir * 2 * M_PI) / 32.0;
	ho->roc->rcSpeed = speed;
	m_xVector = speed * cos(angle);
	m_yVector = -speed * sin(angle);
}

-(void)setDir:(int)dir
{
	double angle;	//= [self getAngle:m_xVector withVY:m_yVector];	// Get the angle and vector
	double vector = [self getVector:m_xVector withVY:m_yVector];
	angle = (dir * 2 * M_PI) / 32.0;
	ho->roc->rcDir = dir;
	m_xVector = vector * cos(angle);					// Restores X and Y speeds
	m_yVector = -vector * sin(angle);
}

-(void)setDec:(int)dec
{
	if (dec < 0)
	{
		dec = 0;
	}
	if (dec > 100)
	{
		dec = 100;
	}
	m_deceleration = dec;
}

-(void)setRotSpeed:(int)speed
{
	if (speed < 0)
	{
		speed = 0;
	}
	if (speed > 100)
	{
		speed = 100;
	}
	m_rotationSpeed = speed;
}

-(void)setGravity:(int)gravity
{
	if (gravity < 0)
	{
		gravity = 0;
	}
	if (gravity > 100)
	{
		gravity = 100;
	}
	
	m_gravity = gravity;
	double angle = (m_gravityAngle * 2 * M_PI) / 32.0;
	m_xGravity = m_gravity * cos(angle);
	m_yGravity = -m_gravity * sin(angle);
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
		case 0:		// SPACE_SETPOWER:
			param = (int)[self getParamDouble];
			if (param < 0)
			{
				param = 10;
			}
			if (param > 100)
			{
				param = 100;
			}
			m_power = param;
			break;
		case 1:		// SPACE_SETSPEED:
			param = (int)[self getParamDouble];
			[self setSpeed:param];
			break;
		case 2:		// SPACE_SETDIR:
			param = (int)[self getParamDouble];
			[self setDir:param];
			break;
		case 3:		// SPACE_SETDEC:
			param = (int)[self getParamDouble];
			[self setDec:param];
			break;
		case 4:		// SPACE_SETROTSPEED:
			param = (int)[self getParamDouble];
			[self setRotSpeed:param];
			break;
		case 5:		// SPACE_SETGRAVITY:
			param = (int)[self getParamDouble];
			[self setGravity:param];
			break;
		case 6:		// SPACE_SETGRAVITYDIR:
		{
			param = (int)[self getParamDouble];
			double angle2 = (param * 2 * M_PI) / 32.0;
			m_xGravity = m_gravity * cos(angle2);
			m_yGravity = -m_gravity * sin(angle2);
			break;
		}
		case 7:		// SPACE_APPLYREACTOR:
			m_autoReactor = YES;
			break;
		case 8:		// SPACE_APPLYROTATERIGHT:
			m_autoRotateRight = YES;
			break;
		case 9:		// SPACE_APPLYROTATELEFT:
			m_autoRotateLeft = YES;
			break;
		case 10:		// SPACE_GETGRAVITY:
			return (int) m_gravity;
		case 11:		// SPACE_GETGRAVITYDIR:
			return (int) m_gravityAngle;
		case 12:		// SPACE_GETDECELERATION:
			return (int) m_deceleration;
		case 13:		// PACE_GETROTATIONSPEED:
			return (int) m_rotationSpeed;
		case 14:		// SPACE_GETTHRUSTPOWER:
			return (int) m_power;
	}
	return 0;
}

-(int)getSpeed
{
	return ho->roc->rcSpeed;
}

-(int)getAcceleration
{
	return (int) m_power;
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
		m_X = stream.readDouble();
		m_Y = stream.readDouble();
		m_xVector = stream.readDouble();
		m_yVector = stream.readDouble();
		m_xGravity = stream.readDouble();
		m_yGravity = stream.readDouble();
		m_deceleration = stream.readDouble();
		m_power = stream.readDouble();
		m_button = stream.readInt();
		m_rotationSpeed = stream.readInt();
		m_rotCounter = stream.readInt();
		m_gravity = stream.readInt();
		m_gravityAngle = stream.readInt();
		m_bStop = stream.readBoolean();
		m_autoReactor = stream.readBoolean();
		m_autoRotateRight = stream.readBoolean();
		m_autoRotateLeft = stream.readBoolean();
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
		stream.writeDouble(m_X);
		stream.writeDouble(m_Y);
		stream.writeDouble(m_xVector);
		stream.writeDouble(m_yVector);
		stream.writeDouble(m_xGravity);
		stream.writeDouble(m_yGravity);
		stream.writeDouble(m_deceleration);
		stream.writeDouble(m_power);
		stream.writeInt(m_button);
		stream.writeInt(m_rotationSpeed);
		stream.writeInt(m_rotCounter);
		stream.writeInt(m_gravity);
		stream.writeInt(m_gravityAngle);
		stream.writeBoolean(m_bStop);
		stream.writeBoolean(m_autoReactor);
		stream.writeBoolean(m_autoRotateRight);
		stream.writeBoolean(m_autoRotateLeft);
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/

@end
