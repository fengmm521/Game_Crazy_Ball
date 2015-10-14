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
//
//  CRunMvtbox2dplatform.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 08/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtbox2dplatform.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CRun.h"
#import "CRunApp.h"
#import "CImageBank.h"
#import "CImage.h"
#import "CAnim.h"
#import "CServices.h"
#import "CEvents.h"
#import "CMove.h"
#import "CObject.h"
#import "CExtension.h"


// Initialize the movement
// -----------------------
#define PLACCMULT 1.0f
#define PLDECMULT 1.0f
void CRunBox2DPlatform::Initialize(LPHO pHo, CFile* file)
{
	m_mBase = nil;
	m_pHo = pHo;
	m_base=GetBase();
	m_fixture = nil;
    
    [file skipBytes:1];
    m_angle=[file readAInt];
    m_strength2=(float)([file readAInt]/100.0*25.0);
    m_gravity=(float)([file readAInt]/100.0);
    m_density=(float)([file readAInt]/100.0);
    m_restitution=(float)([file readAInt]/100.0);
    m_flags=[file readAInt];
    int speed = [file readAInt];
    m_speed=(float)(speed/100.0*10.0);
    m_acceleration=(float)([file readAInt]/(100.0*PLACCMULT));
    m_deceleration=(float)([file readAInt]/(100.0*PLDECMULT));
    m_strength=(float)([file readAInt]/100.0*25.0);
    m_jumps=[file readAInt];
    m_control=[file readAShort];
    m_crouchSpeed = (float)([file readAInt] / 100.0 * 10.0);
    m_friction=0;
    m_player = [file readAInt];
    m_identifier=[file readAInt];
    m_climbingSpeed = (float)([file readAInt] / 100.0 * 10.0);
    m_maskWidth = (float)([file readAInt] / 100.0);
    m_currentSpeed = 0;
	m_previousJump=NO;
	m_jump=0;
	pHo->roc->rcMinSpeed=0;
	pHo->roc->rcMaxSpeed=speed;
	m_previousAngle=-1;
	m_debug = 0;
	m_platformUnder = nil;
    m_previousLadder = FALSE;
	m_previousLadderDir = 0;
	m_onLadder = 0;
    m_noStop = NO;
    m_falling = 0;
}

void CRunBox2DPlatform::Delete()
{
	LPRDATABASE pBase=GetBase();
	if (pBase!=nil && m_mBase != nil)
	{
        pBase->pDestroyBody(pBase, m_mBase->m_body);
        delete m_mBase;
	}
}


// Moves the object
// ----------------
LPRDATABASE CRunBox2DPlatform::GetBase()
{
    LPRH rhPtr = m_pHo->hoAdRunHeader;
    int pOL = 0;
    int nObjects;
	for (nObjects=0; nObjects<rhPtr->rhNObjects; pOL++, nObjects++)
	{
		while(rhPtr->rhObjectList[pOL]==nil) pOL++;
		CObject* pBase=rhPtr->rhObjectList[pOL];
		if (pBase->hoType>=32)
		{
			if (pBase->hoCommon->ocIdentifier==BASEIDENTIFIER)
			{
                CExtension* pExtension = (CExtension*)pBase;
				LPRDATABASE pEngine=(LPRDATABASE)((CRunBox2DParent*)pExtension->ext)->m_object;
				if (pEngine->identifier==m_identifier)
				{
					return pEngine;
				}
			}
		}
	}
	return nil;
}
BOOL CRunBox2DPlatform::CreateBody(LPHO pHo)
{
	if (m_mBase != nil && m_mBase->m_body!=nil)
		return YES;
    
	if ((pHo->hoOEFlags & OEFLAG_ANIMATIONS) == 0)
		return NO;
    
	if (m_base==nil)
	{
		m_base=GetBase();
	}
    
	if (m_base==nil)
		return NO;
    
	m_mBase = new CRunMBase(m_base, pHo, MTYPE_OBJECT);
	m_mBase->m_movement = this;
	m_mBase->m_identifier = m_identifier;
	m_mBase->m_platform = YES;
    
	pHo->roc->rcDir=(m_angle&31/16)*16;
	pHo->roc->rcSpeed=0;
	[m_movement animations:ANIMID_STOP];
	m_mBase->m_body = m_base->pCreateBody(m_base, b2_dynamicBody, pHo->hoX, pHo->hoY, 0, m_gravity, (void*)m_mBase, 0, 0);
	m_base->pBodySetFixedRotation(m_base, m_mBase->m_body, YES);
	m_mBase->m_image = pHo->roc->rcImage;
	CreateFixture(pHo);
    
	return YES;
}

void CRunBox2DPlatform::CreateFixture(LPHO pHo)
{
	if (m_fixture != NULL)
	{
		m_base->pBodyDestroyFixture(m_base, m_mBase->m_body, m_fixture);
	}
    
	m_scaleX = pHo->roc->rcScaleX;
	m_scaleY = pHo->roc->rcScaleY;
    
	int offsetX;
	int offsetY;
	m_offsetX = 0;
	m_offsetY = 0;
	m_base->pBodyCreatePlatformFixture(m_base, m_mBase->m_body, m_mBase, (WORD)m_mBase->m_image, 0, 0, m_density, m_friction, m_restitution, &m_fixture, &offsetX, &offsetY, m_scaleX, m_scaleY, m_maskWidth);
}

BOOL CRunBox2DPlatform::check_Ladder(LPHO pHo, int nLayer, int x, int y, int& yTop)
{
//    x-=pHo->hoAdRunHeader->rhWindowX;
//    y-=pHo->hoAdRunHeader->rhWindowY;
	CRect prc = [pHo->hoAdRunHeader y_GetLadderAt:-1 withX:x andY:y];
	if (!prc.isNil())
	{
        yTop = (int)prc.top;
		return YES;
	}
	return NO;
}

BOOL CRunBox2DPlatform::Move(LPHO pHo)
{
	if (!CreateBody(pHo))
		return NO;
    
    LPRH rhPtr = pHo->hoAdRunHeader;
    
	// Scale changed?
	if (pHo->roc->rcScaleX != m_scaleX || pHo->roc->rcScaleY != m_scaleY)
		CreateFixture(pHo);
    
	// Get the joystick
	unsigned char joyDir=rhPtr->rhPlayer;
	int anim=ANIMID_STOP;
	BOOL flag=NO;
	b2Vec2 velocity=m_base->pBodyGetLinearVelocity(m_base, m_mBase->m_body);
    
	// Previous position
	b2Vec2 position=m_mBase->m_body->GetPosition();
	m_deltaX=(position.x-m_previousX)*m_base->factor;
	m_deltaY=(position.y-m_previousY)*m_base->factor;
	m_previousX=position.x;
	m_previousY=position.y;
    
    int x, y;
	float angle;
	m_base->pGetBodyPosition(m_base, m_mBase->m_body, &x, &y, &angle);
	if (x!=pHo->hoX || y!=pHo->hoY)
	{
		pHo->hoX=x + m_offsetX;
		pHo->hoY=y + m_offsetY;
		pHo->roc->rcChanged=YES;
	}
	if (m_mBase->m_currentAngle!=m_previousAngle)
	{
		m_previousAngle=m_mBase->m_currentAngle;
		pHo->roc->rcChanged=YES;
	}
    pHo->roc->rcDir=(int)(m_mBase->m_currentAngle/11.25f);

	BOOL bCrouching=NO;
    int yLadder;
	BOOL bLadder=check_Ladder(pHo, pHo->hoLayer, pHo->hoX, pHo->hoY, yLadder);
	float ySpeed=0;
	float speed=m_speed;
	int ladderDir = 0;
	int ladderEnd = 0;
    
	if (m_jump == 0)
		m_jumpCounter = m_jumps;
    
			if (joyDir&2 && m_jump==0)
			{
				if (!bLadder)
				{
					if (m_flags&MPFLAG_ALLOWCROUCH)
					{
						speed=m_crouchSpeed;
						bCrouching=YES;
					}
				}
				else
				{
                    int y;
                    if (check_Ladder(pHo, pHo->hoLayer, pHo->hoX, pHo->hoY + 2, y))
                    {
                        ySpeed=-m_climbingSpeed;
                        ladderDir = 24;
                        m_onLadder = YES;
                    }
				}
			}
			if (joyDir&1 && m_jump==0)
			{
                if (bLadder)
                {
                    int y;
                    if (check_Ladder(pHo, pHo->hoLayer, pHo->hoX, pHo->hoY - 2, y))
                    {
                        ySpeed=m_climbingSpeed;
                        ladderDir = 8;
                        m_onLadder = YES;
                    }
                }
                else
                {
                    if (std::abs(velocity.x) < 0.01 && m_previousLadder)
                    {
                        m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, m_previousLadderEnd);
                        velocity.y = 0;
                    }
                }
			}
			if (bLadder)
			{
                ladderEnd = yLadder;
				if (m_jump==0)
				{
					m_mBase->m_body->SetGravityScale(0);
					velocity.y=ySpeed;
				}
				else
				{
					if (m_deltaY>0)
						m_mBase->m_body->SetGravityScale(m_gravity);
					else
					{
						velocity.y=0;
						m_mBase->m_body->SetGravityScale(0);
						m_jump=0;
					}
				}
			}
			else
			{
				m_mBase->m_body->SetGravityScale(m_gravity);
                m_onLadder = NO;
			}
            
			flag=NO;
			if ((joyDir&(4|8))!=0)			// Gauche
			{
                m_onLadder = NO;
				if (m_jump==0 || (m_jump>0 && (m_flags&MPFLAG_CONTROLJUMP)!=0))
				{
					if ((m_flags & MPFLAG_ACCMOVEMENTS) == 0)
					{
						if (m_currentSpeed<speed)
						{
							m_currentSpeed+=m_acceleration;
						}
						if (m_currentSpeed>speed)
						{
							m_currentSpeed-=m_deceleration;
						}
						if (joyDir&4)
						{
							m_mBase->m_currentAngle=180.0f;
							velocity.x=-m_currentSpeed;
							flag=YES;
						}
						if (joyDir&8)
						{
							m_mBase->m_currentAngle=0.0f;
							velocity.x=m_currentSpeed;
							flag=YES;
						}
					}
					else
					{
						if (velocity.x == 0)
							m_currentSpeed = 0;
						if (joyDir&4)
						{
							if (m_mBase->m_currentAngle == 180.0f)
							{
								m_currentSpeed += m_acceleration;
								m_currentSpeed = mind(speed, m_currentSpeed);
								velocity.x = -m_currentSpeed;
							}
							else
							{
								m_currentSpeed -= m_deceleration;
								if (m_currentSpeed < 0)
								{
									m_mBase->m_currentAngle=180.0f;
									m_currentSpeed = 0;
								}
								velocity.x=m_currentSpeed;
							}
							flag = YES;
						}
						if (joyDir&8)
						{
							if (m_mBase->m_currentAngle == 0.0f)
							{
								m_currentSpeed += m_acceleration;
								m_currentSpeed = mind(speed, m_currentSpeed);
								velocity.x = m_currentSpeed;
							}
							else
							{
								m_currentSpeed -= m_deceleration;
								if (m_currentSpeed < 0)
								{
									m_mBase->m_currentAngle=0.0f;
									m_currentSpeed = 0;
								}
								velocity.x=-m_currentSpeed;
							}
							flag = YES;
						}
					}
					anim=ANIMID_WALK;
				}
			}
			if (!flag)
			{
				if (m_jump==0)
				{
					if (m_currentSpeed>0)
					{
						m_currentSpeed-=m_deceleration;
						m_currentSpeed=maxd(m_currentSpeed, 0);
					}
					if (m_mBase->m_currentAngle==180.0f)
						velocity.x=-m_currentSpeed;
					else
						velocity.x=m_currentSpeed;
                    if (m_currentSpeed != 0)
                        anim = ANIMID_WALK;
				}
			}
            else
                m_previousLadder = 0;
    
			// En train de tomber?
			if (bLadder == NO && abs((int)(pHo->hoAdRunHeader->rhLoopCount - m_loopCollision)) > 5)
			{
				if (velocity.y < -0.5f)
				{
					m_falling = 2;
				}
			}
            
			// Teste le saut
			BOOL bJump=NO;
			int j=m_control;
			if (j!=0)
			{
				j--;
				if (j==0)
				{
					if ( (joyDir&5)==5 )
						bJump=YES;							// Haut gauche
					if ( (joyDir&9)==9 )
						bJump=YES;							// Haut droite
				}
				else
				{
					j<<=4;
					if (joyDir&j)
						bJump=YES;
				}
			}
			float jumpVY=0;
			if (bCrouching && (m_flags&MPFLAG_JUMPCROUCHED) == 0)
				bJump = NO;
			if (m_falling > 0 && m_jumps <= 1)
				bJump = NO;
			if (bJump)
			{
				if (!m_previousJump)
				{
					m_previousJump=YES;
					if (m_jump==0)
					{
						m_jump=4;
						jumpVY=m_strength;
						m_jumpCounter=m_jumps - 1;
					}
					else
					{
						if (m_jumpCounter>=0)
						{
							m_jumpCounter--;
							if (m_jumpCounter>=0)
							{
								jumpVY=m_strength2;
							}
						}
					}
				}
			}
			else
			{
				m_previousJump=NO;
			}
			if (jumpVY!=0)
				velocity.y = jumpVY;
			m_base->pBodySetLinearVelocityVector(m_base, m_mBase->m_body, velocity);
			m_base->pBodyAddVelocity(m_base, m_mBase->m_body, m_mBase->m_addVX+m_mBase->m_setVX, m_mBase->m_addVY+m_mBase->m_setVY);
            m_mBase->ResetAddVelocity();
    
			if (m_platformUnder != nil && bJump == 0)
			{
				if (m_platformUnder != m_previousPlatformUnder)
				{
					m_previousPlatformUnder = m_platformUnder;
					m_platformPositionX = m_platformUnder->m_pHo->hoX;
				}
				b2Vec2 positionChar = m_base->pBodyGetPosition(m_base, m_mBase->m_body);
				positionChar.x += (m_platformUnder->m_pHo->hoX - m_platformPositionX) / m_base->factor;
				float angle = m_base->pBodyGetAngle(m_base, m_mBase->m_body);
				m_base->pBodySetTransform(m_base, m_mBase->m_body, positionChar, angle);
				m_platformPositionX = m_platformUnder->m_pHo->hoX;
			}
			else
			{
				m_previousPlatformUnder = nil;
			}
			m_platformUnder = nil;

	m_previousLadder = bLadder;
	m_previousLadderEnd = ladderEnd;
    
	if (bCrouching)
		anim=ANIMID_CROUCH;
	if (bLadder)
	{
		if (ladderDir != 0)
		{
			anim=ANIMID_CLIMB;
			pHo->roc->rcDir = ladderDir;
			m_previousLadderDir = ladderDir;
		}
		else if (m_onLadder && m_previousLadder)
		{
			anim=ANIMID_CLIMB;
			pHo->roc->rcDir = m_previousLadderDir;
		}
	}
    
	if (m_jump>0)
    {
		anim=ANIMID_JUMP;
        m_previousLadder = NO;
    }
	if (m_falling > 0)
    {
		anim = ANIMID_FALL;
        m_previousLadder = NO;
        m_falling--;
    }
	double length=sqrt(m_deltaX*m_deltaX+m_deltaY*m_deltaY);
	pHo->roc->rcSpeed=(int)((50.0f*length/7.0f)*rhPtr->rh4MvtTimerCoef);
	pHo->roc->rcSpeed=MIN(pHo->roc->rcSpeed, 250);
	[m_movement animations:anim];
    if (m_flags & MPFLAG_FINECOLLISIONS)
    {
        m_noStop = YES;
        [m_movement collisions];
        m_noStop = NO;
    }
    
	// The object has been moved
	return pHo->roc->rcChanged;
}

// Changes both X and Y position
// -----------------------------
void CRunBox2DPlatform::SetPosition(LPHO pHo, int x, int y)
{
	if (x!=pHo->hoX || y!=pHo->hoY)
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, y);
}

// Changes X position
// ------------------
void CRunBox2DPlatform::SetXPosition(LPHO pHo, int x)
{
	if (x!=pHo->hoX)
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, POSDEFAULT);
}

// Changes Y position
// ------------------
void CRunBox2DPlatform::SetYPosition(LPHO pHo, int y)
{
	if (y!=pHo->hoY)
		m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, y);
}

void CRunBox2DPlatform::SetFriction(int friction)
{
	m_friction=maxd((((float)friction)/100.0), 0);
	m_fixture->SetFriction(m_friction);
}
void CRunBox2DPlatform::SetGravity(int gravity)
{
	m_gravity=maxd((float)(((float)gravity)/100.0), 0);
	m_mBase->m_body->SetGravityScale(m_gravity);
}
void CRunBox2DPlatform::SetDensity(int density)
{
	m_density=maxd((float)(((float)density)/100.0), 0);
	m_fixture->SetDensity(m_density);
	m_base->pBodyResetMassData(m_base, m_mBase->m_body);
}
void CRunBox2DPlatform::SetRestitution(int restitution)
{
	m_restitution=maxd((float)(((float)restitution)/100.0), 0);
	m_fixture->SetRestitution(m_restitution);
}
void CRunBox2DPlatform::SetAngle(float angle)
{
}
float CRunBox2DPlatform::GetAngle()
{
	return 0;
}

DWORD CRunBox2DPlatform::GetFriction()
{
	return (DWORD)(m_friction * 100.0);
}
DWORD CRunBox2DPlatform::GetDensity()
{
	return (DWORD)(m_density*100.0);
}
DWORD CRunBox2DPlatform::GetRestitution()
{
	return (DWORD)(m_restitution * 100.0);
}

// Stops the object
// ----------------
void CRunBox2DPlatform::SetCollidingObject(CRunMBase* object)
{
	m_collidingObject = object;
}
void CRunBox2DPlatform::Stop(LPHO pHo, BOOL bCurrent)
{
	if (m_mBase->m_eventCount==pHo->hoAdRunHeader->rh4EventCount)
	{
        if (m_noStop)
            return;
        
		int x, y;
		BOOL bLadder=check_Ladder(pHo, pHo->hoLayer, pHo->hoX, pHo->hoY, y);
		if (!bLadder)
		{
			m_mBase->SetStopFlag(YES);
		}
        
		float angle;
		m_base->pGetBodyPosition(m_base, m_collidingObject->m_body, &x, &y, &angle);
		int left = (int)(x + m_collidingObject->rc.left);
		int right = (int)(x + m_collidingObject->rc.right);
		int bottom = (int)(y + m_collidingObject->rc.bottom);
// 		int top = (int)(y + m_collidingObject->rc.top);
        
        if (m_collidingObject->m_subType == MSUBTYPE_BOTTOM)
        {
            m_loopCollision = pHo->hoAdRunHeader->rhLoopCount;
            m_jump = MAX(m_jump-1, 0);
        }
        else if ((pHo->hoX >=left && pHo->hoX <= right && pHo->hoY <= bottom))
        {
            m_loopCollision = pHo->hoAdRunHeader->rhLoopCount;
            m_jump = MAX(m_jump-1, 0);
            if (m_collidingObject->m_type == MTYPE_FAKEOBJECT)
                m_platformUnder = m_collidingObject;
        }
	}
	else
	{
		m_base->pBodySetLinearVelocityAdd(m_base, m_mBase->m_body, 0, 0, 0, 0);
	}
    
}

// Bounces the object
// ------------------
void CRunBox2DPlatform::Bounce(LPHO pHo, BOOL bCurrent)
{
}

// Go in reverse
// -------------
void CRunBox2DPlatform::Reverse(LPHO pHo)
{
}

// Restart the movement
// --------------------
void CRunBox2DPlatform::Start(LPHO pHo)
{
}

// Changes the speed
// -----------------
void CRunBox2DPlatform::SetSpeed(LPHO pHo, int speed)
{
	m_currentSpeed=(float)(((float)speed)/100.0)*10.0f;
}

// Changes the maximum speed
// -------------------------
void CRunBox2DPlatform::SetMaxSpeed(LPHO pHo, int speed)
{
}

// Changes the direction
// ---------------------
void CRunBox2DPlatform::SetDir(LPHO pHo, int dir)
{
	if (dir>16 && dir<24)
		pHo->roc->rcDir=16;
	else
		pHo->roc->rcDir=0;
}
int CRunBox2DPlatform::GetDir(LPHO pHo)
{
	return pHo->roc->rcDir;
}

// Changes the acceleration
// ------------------------
void CRunBox2DPlatform::SetAcc(LPHO pHo, int acc)
{
	m_acceleration=(float)(((float)acc)/(100.0*PLACCMULT));
}

// Changes the deceleration
// ------------------------
void CRunBox2DPlatform::SetDec(LPHO pHo, int dec)
{
	m_deceleration=(float)(((float)dec)/(100.0*PLDECMULT));
}

// Changes the rotation speed
// --------------------------
void CRunBox2DPlatform::SetRotSpeed(LPHO pHo, int speed)
{
}

// Changes the authorised directions out of 8
// ------------------------------------------
void CRunBox2DPlatform::Set8Dirs(LPHO pHo, int dirs)
{
}

// Changes the gravity
// -------------------
void CRunBox2DPlatform::SetGravity(LPHO pHo, int gravity)
{
	m_gravity=(float)(((float)gravity)/100.0);
	m_mBase->m_body->SetGravityScale(m_gravity);
}

// Returns the speed
// -----------------
int CRunBox2DPlatform::GetSpeed(LPHO pHo)
{
	return pHo->roc->rcSpeed;
}

// Returns the acceleration
// ------------------------
int CRunBox2DPlatform::GetAcceleration(LPHO pHo)
{
	return (int)(m_acceleration*(100.0f*PLACCMULT));
}

// Returns the deceleration
// ------------------------
int CRunBox2DPlatform::GetDeceleration(LPHO pHo)
{
	return (int)(m_deceleration*(100.0f*PLDECMULT));
}

// Returns the gravity
// -------------------
int CRunBox2DPlatform::GetGravity(LPHO pHo)
{
	return (int)(m_gravity*100.0);
}


// Extension Actions entry
// -----------------------
double CRunBox2DPlatform::ActionEntry(LPHO pHo, int action, double param1, double param2)
{
	switch (action)
	{
        case ACT_EXTSETGRAVITYSCALE:	
            SetGravity(param1);
            break;
        case ACT_EXTSETFRICTION:	
            SetFriction(param1);
            break;
        case ACT_EXTSETELASTICITY:
            SetRestitution(param1);
            break;
        case ACT_EXTSETDENSITY:
            SetDensity(param1);
            break;
        case EXP_EXTGETFRICTION:	
            return GetFriction();
        case EXP_EXTGETRESTITUTION:
            return GetRestitution();
        case EXP_EXTGETDENSITY:
            return GetDensity();
        case EXP_EXTGETVELOCITY:
		{
			b2Vec2 v = m_base->pBodyGetLinearVelocity(m_base, m_mBase->m_body);
			return sqrt(v.x * v.x + v.y * v.y)*100.0f/SETVELOCITY_MULT;
            break;
		}
        case EXP_EXTGETANGLE:
		{
			b2Vec2 v = m_base->pBodyGetLinearVelocity(m_base, m_mBase->m_body);
			double angle = atan2(v.y, v.x)*180.0f/3.141592653589f;
			if (angle<0)
				angle=360+angle;
			return angle;
		}
        default:
            break;
	}
	return 0;
}


////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunMvtbox2dplatform

-(void)initialize:(CFile*)file
{
    m_object = new CRunBox2DPlatform();
    m_movement = m_object;
    m_object->m_movement = self;
    m_object->Initialize(ho, file);
}
-(void)kill
{
    m_object->Delete();
    delete m_object;
}
-(BOOL)move
{
	return m_object->Move(ho);
}
-(void)setPosition:(int)x withY:(int)y
{
    m_object->SetPosition(ho, x, y);
}
-(void)setXPosition:(int)x
{
    m_object->SetXPosition(ho, x);
}
-(void)setYPosition:(int)y
{
    m_object->SetYPosition(ho, y);
}
-(void)stop:(BOOL)bCurrent
{
    m_object->Stop(ho, bCurrent);
}
-(void)bounce:(BOOL)bCurrent
{
    m_object->Bounce(ho, bCurrent);
}
-(void)start
{
    m_object->Start(ho);
}
-(void)setSpeed:(int)speed
{
    m_object->SetSpeed(ho, speed);
}
-(void)setMaxSpeed:(int)speed
{
    m_object->SetMaxSpeed(ho, speed);
}
-(void)setDir:(int)dir
{
    m_object->SetDir(ho, dir);
}
-(void)setAcc:(int)acc
{
    m_object->SetAcc(ho, acc);
}
-(void)setDec:(int)dec
{
    m_object->SetDec(ho, dec);
}
-(void)setRotSpeed:(int)speed
{
    m_object->SetRotSpeed(ho, speed);
}
-(void)setGravity:(int)gravity
{
    m_object->SetGravity(ho, gravity);
}
-(double)actionEntry:(int)action
{
	return m_object->ActionEntry(ho, action, [self getParam1], [self getParam2]);
}
-(int)getSpeed
{
	return m_object->GetSpeed(ho);
}
-(int)getAcceleration
{
	return m_object->GetAcceleration(ho);
}
-(int)getDeceleration
{
	return m_object->GetDeceleration(ho);;
}
-(int)getGravity
{
	return m_object->GetGravity(ho);
}
-(int)getDir
{
	return m_object->GetDir(ho);
}

@end
