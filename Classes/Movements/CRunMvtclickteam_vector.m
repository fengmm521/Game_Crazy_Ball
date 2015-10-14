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
// CRUNMVTVECTOR
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_vector.h"
#import "CAnim.h"
#import "CObject.h"
#import "CRCom.h"
#import "CRun.h"
#import "CRunFrame.h"
#import "CFile.h"

@implementation CRunMvtclickteam_vector

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	m_dwFlags = [file readAInt];
	m_dwVel = [file readAInt];
	m_dwVelAngle = [file readAInt];
	m_dwAcc = [file readAInt];
	m_dwAccAngle = [file readAInt];
	
	//*** General variables
	r_Stopped = ((m_dwFlags & MOVEATSTARTVECT) == 0);
	handleDirection = ((m_dwFlags & HANDLE_DIRECTION) != 0);
	
	double vel = m_dwVel;
	double velAngle = m_dwVelAngle * ToRadians;
	
	double acc = m_dwAcc * 0.01;
	double accAngle = m_dwAccAngle * ToRadians;
	
	posX = ho->hoX;
	posY = ho->hoY;
	
	velX = vel * cos(velAngle);
	velY = -vel * sin(velAngle);
	
	accX = acc * cos(accAngle);
	accY = -acc * sin(accAngle);
	
	minSpeed=-1;
	maxSpeed=-1;
}

-(BOOL)move
{
	//*** Object needs to be moved?
	if (!r_Stopped)
	{
		//*** Update internal variables
		double calculs;
		calculs = accX;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		velX += calculs;
		calculs = accY;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		velY += calculs;
		calculs = velX;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		posX += calculs * 0.01;
		calculs = velY;
		if ((ho->hoAdRunHeader->rhFrame->leFlags & LEF_TIMEDMVTS) != 0)
		{
			calculs = calculs * ho->hoAdRunHeader->rh4MvtTimerCoef;
		}
		posY += calculs * 0.01;
		
		//*** Code the handle the min / max speed control
		[self checkSpeed];
		
		//*** Calculate the current direction
		angle = atan2(-velY, velX);
		if (angle < 0)
		{
			angle += 2 * M_PI;
		}
		
		if (handleDirection)
		{
			ho->roc->rcDir = ((int) (((angle + (M_PI / 32)) * 32) / (2 / M_PI))) % 32;
		}
		
		//*** Update MMF2 with the new position
		[self animations:ANIMID_WALK];
		ho->hoX = (int) (posX + 0.5);
		ho->hoY = (int) (posY + 0.5);
		[self collisions];
		
		//*** Indicate the object has been moved
		return YES;
	}
	[self animations:ANIMID_STOP];
	[self collisions];
	return NO;
}

-(void)reset
{
	double vel = m_dwVel;
	double velAngle = m_dwVelAngle * ToRadians;
	
	double acc = m_dwAcc / 100.0;
	double accAngle = m_dwAccAngle * ToRadians;
	
	posX = ho->hoX;
	posY = ho->hoY;
	
	velX = vel * cos(velAngle);
	velY = -vel * sin(velAngle);
	
	accX = acc * cos(accAngle);
	accY = -acc * sin(accAngle);
}

-(BOOL)checkSpeed
{
	//*** Code the handle the min / max speed control
	if (maxSpeed != -1)
	{
		if (velX * velX + velY * velY > maxSpeed * maxSpeed)
		{
			[self recalculateAngle];
			//*** Recalculate velocity components
			velX = maxSpeed * cos(angle);
			velY = -maxSpeed * sin(angle);
			return YES;
		}
	}
	else if (minSpeed != -1)
	{
		if (velX * velX + velY * velY < minSpeed * minSpeed)
		{
			[self recalculateAngle];
			//*** Recalculate velocity components
			velX = minSpeed * cos(angle);
			velY = -minSpeed * sin(angle);
			return YES;
		}
	}
	return NO;
}

-(void)recalculateAngle
{
	angle = atan2(-velY, velX);
	if (angle < 0)
	{
		angle += 2 * M_PI;
	}
}

-(void)setPosition:(int)x withY:(int)y
{
	posX -= ho->hoX - x;
	posY -= ho->hoY - y;
	
	ho->hoX = x;
	ho->hoY = y;
}

-(void)setXPosition:(int)x
{
	posX -= ho->hoX - x;
	ho->hoX = x;
}

-(void)setYPosition:(int)y
{
	posY -= ho->hoY - y;
	ho->hoY = y;
}

-(void)stop:(BOOL)bCurrent
{
	r_Stopped = YES;
}

-(void)reverse
{
	velX *= -1;
	velY *= -1;
	[self recalculateAngle];
}

-(void)start
{
	r_Stopped = NO;
}

-(void)setSpeed:(int)speed
{
	velX = speed * cos(angle);
	velY = -speed * sin(angle);
	
	if ([self checkSpeed])
	{
		[self recalculateAngle];
	}
}

-(void)setMaxSpeed:(int)speed
{
	maxSpeed = speed;
	if ([self checkSpeed])
	{
		[self recalculateAngle];
	}
}

-(void)setGravity:(int)gravity
{
	double accAngle = atan2(-accY, accX);
	double acc = gravity * 0.01;
	
	accX = acc * cos(accAngle);
	accY = -acc * sin(accAngle);
}

-(double)actionEntry:(int)action
{
	int param;
	double vel;
	double accAngle;
	double acc;
	double flo;
	switch (action)
	{
/*			
            // Load / save position
		case 0x1010:	// MVTACTION_SAVEPOSITION:
			return savePosition(getOutputStream());
		case 0x1011:	// MVTACTION_LOADPOSITION:
			return loadPosition(getInputStream());
*/			
		case 3845:	    // SET_Vector_X = 3845,
			param = (int)[self getParamDouble];
			posX = param;
			break;
		case 3846:	    // SET_Vector_Y,
			param = (int)[self getParamDouble];
			posY = param;
			break;
		case 3847:	    // SET_Vector_XY,
			param = (int)[self getParamDouble];
			break;
		case 3848:	    // SET_Vector_AddDistX,
			param = (int)[self getParamDouble];
			posX += 0.01 * param;
			break;
		case 3849:	    // SET_Vector_AddDistY,
			param = (int)[self getParamDouble];
			posY -= 0.01 * param;
			break;
		case 3850:	    // SET_Vector_Dir,
			param = (int)[self getParamDouble];
			angle = ((int) param) * ToRadians;
			vel = sqrt(velX * velX + velY * velY);
			velX = vel * cos(angle);
			velY = -vel * sin(angle);
			break;
		case 3851:	    // SET_Vector_RotateTowardsAngle,
			param = (int)[self getParamDouble];
			break;
		case 3852:	    // SET_Vector_RotateTowardsPoint,
			param = (int)[self getParamDouble];
			break;
		case 3853:	    // SET_Vector_RotateTowardsObject,
			param = (int)[self getParamDouble];
			break;
		case 3854:	    // SET_Vector_Speed,
			param = (int)[self getParamDouble];
			vel = param;
			velX = vel * cos(angle);
			velY = -vel * sin(angle);
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3855:	    // SET_Vector_SpeedX,
			param = (int)[self getParamDouble];
			velX = param;
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3856:	    // SET_Vector_SpeedY,
			param = (int)[self getParamDouble];
			velY = param;
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3857:	    // SET_Vector_AddSpeedX,
			param = (int)[self getParamDouble];
			velX += 0.01 * param;
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3858:	    // SET_Vector_AddSpeedY,
			param = (int)[self getParamDouble];
			velY -= 0.01 * param;
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3859:	    // SET_Vector_MinSpeed,
			param = (int)[self getParamDouble];
			minSpeed = param;
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3860:	    // SET_Vector_MaxSpeed,
			param = (int)[self getParamDouble];
			maxSpeed = param;
			if ([self checkSpeed])
			{
				[self recalculateAngle];
			}
			break;
		case 3861:	    // SET_Vector_Gravity,
			param = (int)[self getParamDouble];
			accAngle = atan2(-accY, accX);
			acc = param * 0.01;
			accX = acc * cos(accAngle);
			accY = -acc * sin(accAngle);
			break;
		case 3862:	    // SET_Vector_GravityDir,
			param = (int)[self getParamDouble];
			accAngle = param * ToRadians;
			acc = sqrt(accX * accX + accY * accY);
			accX = acc * cos(accAngle);
			accY = -acc * sin(accAngle);
			break;
		case 3863:	    // SET_Vector_BounceCoeff,
			param = (int)[self getParamDouble];
			break;
		case 3864:	    // SET_Vector_ForceBounce,
			param = (int)[self getParamDouble];
			angle = param * ToRadians * 2;
			posX -= velX * 0.01;
			posY -= velY * 0.01;
			angle -= atan2(-velY, velX);
			vel = sqrt(velX * velX + velY * velY);
			velX = vel * cos(angle);
			velY = -vel * sin(angle);
			break;
			
		case 3865:	    // GET_Vector_X,
			return posX;
		case 3866:	    // GET_Vector_Y,
			return posY;
		case 3867:	    // GET_Vector_Dir,
			flo = (angle * ToDegrees);
			if (flo < 0)
			{
				flo += 360;
			}
			return flo;
		case 3868:	    // GET_Vector_Speed,
			return sqrt(velX * velX + velY * velY);
		case 3869:	    // GET_Vector_SpeedX,
			return velX;
		case 3870:	    // GET_Vector_SpeedY,
			return velY;
		case 3871:	    // GET_Vector_MinSpeed,
			return minSpeed;
		case 3872:	    // GET_Vector_MaxSpeed,
			return maxSpeed;
		case 3873:	    // GET_Vector_Gravity,
			return (100 * sqrt(accX * accX + accY * accY));
		case 3874:	    // GET_Vector_GravityDir,
			flo = (atan2(-accY, accX) * ToDegrees);
			if (flo < 0)
			{
				flo += 360;
			}
			return flo;
		case 3875:	    // GET_Vector_BounceCoef
			return 0;
			
	}
	return 0;
}

-(int)getSpeed
{
	return (int) (sqrt(velX * velX + velY * velY));
}

-(int)getGravity
{
	return (int) (100 * sqrt(accX * accX + accY * accY));
}

/*
public int loadPosition(DataInputStream stream)
{
	try
	{
		r_Stopped = stream.readBoolean();
		handleDirection = stream.readBoolean();
		posX = stream.readDouble();
		posY = stream.readDouble();
		velX = stream.readDouble();
		velY = stream.readDouble();
		accX = stream.readDouble();
		accY = stream.readDouble();
		angle = stream.readDouble();
		minSpeed = stream.readDouble();
		maxSpeed = stream.readDouble();
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
		stream.writeBoolean(handleDirection);
		stream.writeDouble(posX);
		stream.writeDouble(posY);
		stream.writeDouble(velX);
		stream.writeDouble(velY);
		stream.writeDouble(accX);
		stream.writeDouble(accY);
		stream.writeDouble(angle);
		stream.writeDouble(minSpeed);
		stream.writeDouble(maxSpeed);
	}
	catch (IOException e)
	{
		return 1;
	}
	return 0;
}
*/

@end
