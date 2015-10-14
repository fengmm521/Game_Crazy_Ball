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
//  CRunMvtbox2dracecar.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtbox2dracecar.h"
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

#define RCACCMULT 1.0f
#define RCDECMULT 1.0f
#define RCROTMULT 15.0f
#define RCSPEEDMULT 0.20f

void CRunBox2DRaceCar::Initialize(LPHO pHo, CFile* file)
{
	m_mBase = nil;
	m_pHo = pHo;
	m_base=GetBase();
	m_fixture = nil;
    
    [file skipBytes:1];
    m_angleCalculation=(float)( [m_movement dirAtStart:[file readAInt]] * 180.0 / 16.0);
    m_friction=(float)([file readAInt]/100.0);
    m_gravity=0;
    [file skipBytes:4];
    m_density=(float)([file readAInt]/100.0);
    m_restitution=(float)([file readAInt]/100.0);
    m_flags=[file readAInt];
    m_shape=[file readAShort];
    int speed = [file readAInt];
    m_speed=(float)(speed*RCSPEEDMULT);
    m_acceleration=(float)([file readAInt]/(100.0*RCACCMULT));
    m_deceleration=(float)([file readAInt]/(100.0*RCDECMULT));
    m_angleSpeed=(float)([file readAInt]/100.0*RCROTMULT);
    m_identifier=[file readAInt];
    m_player = [file readAInt];
    m_jointType = [file readAShort];
    m_jointAnchor = [file readAShort];
    m_jointName = [file readAStringWithSize:MAX_JOINTNAME];
    m_jointObject = [file readAStringWithSize:MAX_JOINTOBJECT];
    m_rJointLLimit = (float)([file readAInt] * b2_pi / 180.0);
    m_rJointULimit = (float)([file readAInt] * b2_pi / 180.0);
    m_dJointFrequency = [file readAInt];
    m_dJointDamping = (float)([file readAInt] / 100.0);
    m_pJointLLimit = [file readAInt];
    m_pJointULimit = [file readAInt];
    
	pHo->roc->rcMinSpeed=0;
	pHo->roc->rcMinSpeed=speed;
	m_previousAngle=-1;
    m_started = NO;
}

void CRunBox2DRaceCar::Delete()
{
	LPRDATABASE pBase=GetBase();
	if (pBase!=nil && m_mBase != nil)
	{
		pBase->pDestroyBody(pBase, m_mBase->m_body);
        delete m_mBase;
	}
    [m_jointName release];
    [m_jointObject release];
}


// Moves the object
// ----------------
LPRDATABASE CRunBox2DRaceCar::GetBase()
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
BOOL CRunBox2DRaceCar::CreateBody(LPHO pHo)
{
	if (m_mBase != nil && m_mBase->m_body!=nil)
		return YES;
    
	if (m_base==nil)
	{
		m_base=GetBase();
	}
    
	if (m_base==nil)
		return NO;
    
	m_mBase = new CRunMBase(m_base, pHo, MTYPE_OBJECT);
	m_mBase->m_movement = this;
	m_mBase->m_identifier = m_identifier;
	m_mBase->m_currentAngle = m_setAngle;
    
	m_mBase->m_body = m_base->pCreateBody(m_base, b2_dynamicBody, pHo->hoX, pHo->hoY, m_angle, m_gravity, m_mBase, CBFLAG_FIXEDROTATION, 0);
	if ((pHo->hoOEFlags & OEFLAG_ANIMATIONS) == 0)
	{
		m_shape = 0;
		m_mBase->m_image = -1;
		m_imgWidth = pHo->hoImgWidth;
		m_imgHeight = pHo->hoImgHeight;
	}
	else
	{
		m_mBase->m_image = pHo->roc->rcImage;
        CImage* pImage;
        pImage = [m_pHo->hoAdRunHeader->rhApp->imageBank getImageFromHandle:m_mBase->m_image];
		m_imgWidth = pImage->width;
		m_imgHeight = pImage->height;
	}
	CreateFixture(pHo);
	b2Vec2 position=m_base->pBodyGetPosition(m_base, m_mBase->m_body);
	m_previousX=position.x;
	m_previousY=position.y;
    
	return YES;
}
void CRunBox2DRaceCar::CreateFixture(LPHO pHo)
{
	if (m_fixture != nil)
	{
		m_base->pBodyDestroyFixture(m_base, m_mBase->m_body, m_fixture);
	}
	m_scaleX = pHo->roc->rcScaleX;
	m_scaleY = pHo->roc->rcScaleY;
	switch(m_shape)
	{
        case 0:
            m_fixture=m_base->pBodyCreateBoxFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, (int)(m_imgWidth * m_scaleX), (int)(m_imgHeight * m_scaleY), m_density, m_friction, m_restitution);
            break;
        case 1:
            m_fixture=m_base->pBodyCreateCircleFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, (int)((m_imgWidth + m_imgHeight)/4 * (m_scaleX + m_scaleY) / 2), m_density, m_friction, m_restitution);
            break;
        case 2:
            m_fixture=m_base->pBodyCreateShapeFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, m_mBase->m_image, m_density, m_friction, m_restitution, m_scaleX, m_scaleY);
            break;
	}
}
void CRunBox2DRaceCar::CreateJoint(LPHO pHo)
{
	switch (m_jointType)
	{
        case JTYPE_REVOLUTE:
            m_base->pJointCreate(m_base, m_mBase, m_jointType, m_jointAnchor, m_jointName, m_jointObject, m_rJointLLimit, m_rJointULimit);
            break;
        case JTYPE_DISTANCE:
            m_base->pJointCreate(m_base, m_mBase, m_jointType, m_jointAnchor, m_jointName, m_jointObject, m_dJointFrequency, m_dJointDamping);
            break;
        case JTYPE_PRISMATIC:
            m_base->pJointCreate(m_base, m_mBase, m_jointType, m_jointAnchor, m_jointName, m_jointObject, m_pJointLLimit, m_pJointULimit);
            break;
        default:
            break;
	}
}
BOOL CRunBox2DRaceCar::Move(LPHO pHo)
{
	if (!CreateBody(pHo))
		return NO;
    
    LPRH rhPtr = pHo->hoAdRunHeader;
    
	// Scale changed?
	if (pHo->roc->rcScaleX != m_scaleX || pHo->roc->rcScaleY != m_scaleY)
		CreateFixture(pHo);
    
	// Get the joystick
	unsigned char j=rhPtr->rhPlayer;
    
	// Rotation of the ship
	int anim=ANIMID_STOP;
	if ((j&1)!=0)
	{
		if (m_currentSpeed<m_speed)
		{
			if (m_acceleration==1.0f)
				m_currentSpeed=m_speed;
			else
				m_currentSpeed=mind(m_speed, m_currentSpeed+m_acceleration);
		}
		anim=ANIMID_WALK;
	}
	if ((j&2)!=0)
	{
		float baseSpeed=0;
		if ((m_flags&RCFLAG_REVERSE)!=0)
			baseSpeed=-m_speed;
		if (m_currentSpeed>baseSpeed)
		{
			if (m_deceleration==1.0f)
				m_currentSpeed=baseSpeed;
			else
				m_currentSpeed=maxd(baseSpeed, m_currentSpeed-m_deceleration);
		}
	}
	if ((j&4)!=0)
	{
		m_angleCalculation+=m_angleSpeed;
		if (m_angleCalculation>360.0f)
			m_angleCalculation-=360.0f;
	}
	if ((j&8)!=0)
	{
		m_angleCalculation-=m_angleSpeed;
		if (m_angleCalculation<0.0f)
			m_angleCalculation+=360.0f;
	}
	m_mBase->m_currentAngle=m_angleCalculation;
	float angle=m_mBase->m_currentAngle;
	if (m_currentSpeed<0)
		angle+=180.0f;
	m_base->pBodySetLinearVelocity(m_base, m_mBase->m_body, m_currentSpeed, m_mBase->m_currentAngle);
	m_base->pBodyAddVelocity(m_base, m_mBase->m_body, m_mBase->m_addVX, m_mBase->m_addVY);
	m_mBase->ResetAddVelocity();
	m_base->pBodySetAngle(m_base, m_mBase->m_body, m_mBase->m_currentAngle);
    
	int x, y;
	m_base->pGetBodyPosition(m_base, m_mBase->m_body, &x, &y, &angle);
	if (x!=pHo->hoX || y!=pHo->hoY)
	{
		pHo->hoX=x;
		pHo->hoY=y;
        m_started = YES;
		pHo->roc->rcChanged=YES;
	}
    SetCurrentAngle();
    
	b2Vec2 position=m_base->pBodyGetPosition(m_base, m_mBase->m_body);
	float deltaX=(position.x-m_previousX)*m_base->factor;
	float deltaY=(position.y-m_previousY)*m_base->factor;
	m_previousX=position.x;
	m_previousY=position.y;
	double length=sqrt(deltaX*deltaX+deltaY*deltaY);
	pHo->roc->rcSpeed=(int)((50.0f*length/7.0f)*rhPtr->rh4MvtTimerCoef);
	pHo->roc->rcSpeed=MIN(pHo->roc->rcSpeed, 250);
	[m_movement animations:anim];
    if (m_flags & RCFLAG_FINECOLLISIONS)
        [m_movement collisions];
    
	// The object has been moved
	return pHo->roc->rcChanged;
}

void CRunBox2DRaceCar::SetCurrentAngle()
{
	if (m_mBase->m_currentAngle!=m_previousAngle)
	{
		m_previousAngle=m_mBase->m_currentAngle;
		m_pHo->roc->rcChanged=YES;
		if (m_flags&RCFLAG_ROTATE)
		{
			m_pHo->roc->rcAngle=m_mBase->m_currentAngle;
			m_pHo->roc->rcDir=0;
		}
		else
		{
			m_pHo->roc->rcDir=(int)(m_mBase->m_currentAngle/11.25f);
            while(m_pHo->roc->rcDir < 0)
                m_pHo->roc->rcDir += 32;
            while(m_pHo->roc->rcDir >= 32)
                m_pHo->roc->rcDir -= 32;
		}
	}
    
}
// Changes both X and Y position
// -----------------------------
void CRunBox2DRaceCar::SetPosition(LPHO pHo, int x, int y)
{
	if (x!=pHo->hoX || y!=pHo->hoY)
    {
        if (!m_started)
        {
            pHo->hoX = x;
            pHo->hoY = y;
        }
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, y);
    }
}

// Changes X position
// ------------------
void CRunBox2DRaceCar::SetXPosition(LPHO pHo, int x)
{
	if (x!=pHo->hoX)
    {
        if (!m_started)
            pHo->hoX = x;
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, POSDEFAULT);
    }
}

// Changes Y position
// ------------------
void CRunBox2DRaceCar::SetYPosition(LPHO pHo, int y)
{
	if (y!=pHo->hoY)
    {
        if (!m_started)
            pHo->hoY = y;
		m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, y);
    }
}

void CRunBox2DRaceCar::SetFriction(int friction)
{
	m_friction=maxd((float)(((float)friction)/100.0), 0);
	m_fixture->SetFriction(m_friction);
}
void CRunBox2DRaceCar::SetGravity(int gravity)
{
	m_gravity=maxd((float)(((float)gravity)/100.0), 0);
	m_base->pBodySetGravityScale(m_base, m_mBase->m_body, m_gravity);
}
void CRunBox2DRaceCar::SetDensity(int density)
{
	m_density=maxd((float)(((float)density)/100.0), 0);
	m_fixture->SetDensity(m_density);
	m_base->pBodyResetMassData(m_base, m_mBase->m_body);
}
void CRunBox2DRaceCar::SetRestitution(int restitution)
{
	m_restitution=maxd((float)(((float)restitution)/100.0), 0);
	m_base->pFixtureSetRestitution(m_base, m_fixture, m_restitution);
}
void CRunBox2DRaceCar::SetAngle(float angle)
{
	m_angleCalculation = angle;
    if (!m_started)
    {
        m_mBase->m_currentAngle = angle;
        SetCurrentAngle();
    }
}
float CRunBox2DRaceCar::GetAngle()
{
	if (m_flags&RCFLAG_ROTATE)
	{
		return m_mBase->m_currentAngle;
	}
	return ANGLE_MAGIC;
}

DWORD CRunBox2DRaceCar::GetFriction()
{
	return (DWORD)(m_friction * 100.0);
}
DWORD CRunBox2DRaceCar::GetDensity()
{
	return (DWORD)(m_density*100.0);
}
DWORD CRunBox2DRaceCar::GetRestitution()
{
	return (DWORD)(m_restitution * 100.0);
}

// Stops the object
// ----------------
void CRunBox2DRaceCar::Stop(LPHO pHo, BOOL bCurrent)
{
	m_mBase->SetStopFlag(YES);
	if (m_mBase->m_eventCount!=pHo->hoAdRunHeader->rh4EventCount)
	{
		m_base->pBodySetLinearVelocityAdd(m_base, m_mBase->m_body, 0, 0, 0, 0);
	}
}

// Bounces the object
// ------------------
void CRunBox2DRaceCar::Bounce(LPHO pHo, BOOL bCurrent)
{
}

// Go in reverse
// -------------
void CRunBox2DRaceCar::Reverse(LPHO pHo)
{
}

// Restart the movement
// --------------------
void CRunBox2DRaceCar::Start(LPHO pHo)
{
}

// Changes the speed
// -----------------
void CRunBox2DRaceCar::SetSpeed(LPHO pHo, int speed)
{
	float speedf = speed * RCSPEEDMULT;
	speedf = mind(m_speed, speedf);
	speedf = maxd(0, speedf);
	m_currentSpeed = speedf;
}

// Changes the maximum speed
// -------------------------
void CRunBox2DRaceCar::SetMaxSpeed(LPHO pHo, int speed)
{
}

// Changes the direction
// ---------------------
void CRunBox2DRaceCar::SetDir(LPHO pHo, int dir)
{
	m_angleCalculation=(float)(((float)dir*180.0)/16.0);
	m_mBase->m_currentAngle=((int)(m_angleCalculation/11.25f))*11.25f;
    if (!m_started)
        SetCurrentAngle();
}
int CRunBox2DRaceCar::GetDir(LPHO pHo)
{
	if (m_flags&RCFLAG_ROTATE)
		return (int)(m_mBase->m_currentAngle/11.25f);
	else
		return pHo->roc->rcDir;
}

// Changes the acceleration
// ------------------------
void CRunBox2DRaceCar::SetAcc(LPHO pHo, int acc)
{
	m_acceleration=(float)(((float)acc)/(100.0*RCACCMULT));
}

// Changes the deceleration
// ------------------------
void CRunBox2DRaceCar::SetDec(LPHO pHo, int dec)
{
	m_deceleration=(float)(((float)dec)/(100.0*RCDECMULT));
}

// Changes the rotation speed
// --------------------------
void CRunBox2DRaceCar::SetRotSpeed(LPHO pHo, int speed)
{
	m_angleSpeed=(float)(((float)speed)/100.0*RCROTMULT);
}

// Changes the authorised directions out of 8
// ------------------------------------------
void CRunBox2DRaceCar::Set8Dirs(LPHO pHo, int dirs)
{
}

// Changes the gravity
// -------------------
void CRunBox2DRaceCar::SetGravity(LPHO pHo, int gravity)
{
}

// Returns the speed
// -----------------
int CRunBox2DRaceCar::GetSpeed(LPHO pHo)
{
	return pHo->roc->rcSpeed;
}

// Returns the acceleration
// ------------------------
int CRunBox2DRaceCar::GetAcceleration(LPHO pHo)
{
	return (int)(m_acceleration*(100.0*RCACCMULT));
}

// Returns the deceleration
// ------------------------
int CRunBox2DRaceCar::GetDeceleration(LPHO pHo)
{
	return (int)(m_deceleration*(100.0*RCDECMULT));
}

// Returns the gravity
// -------------------
int CRunBox2DRaceCar::GetGravity(LPHO pHo)
{
	return 0;
}


// Extension Actions entry
// -----------------------
double CRunBox2DRaceCar::ActionEntry(LPHO pHo, int action, double param1, double param2)
{
	if (m_base == nil)
		return 0;
    
	switch (action)
	{
        case ACT_EXTSETGRAVITY:
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
        case ACT_EXTAPPLYIMPULSE:
		{
			float force=(float)((float)param1/100.0f*APPLYIMPULSE_MULT);
			float angle=(float)param2;
			m_base->pBodyApplyMMFImpulse(m_base, m_mBase->m_body, force, angle);
		}
            break;
        case ACT_EXTAPPLYFORCE:
		{
			float force=(float)((float)param1/100.0f*APPLYFORCE_MULT);
			float angle=(float)param2;
			m_base->pBodyApplyForce(m_base, m_mBase->m_body, force, angle);
		}
            break;
        case ACT_EXTSTOPFORCE:
		{
			m_base->pBodyStopForce(m_base, m_mBase->m_body);
		}
            break;
        case ACT_EXTSETLINEARVELOCITY:
		{
			float force=(float)((float)param1/100.0f*SETVELOCITY_MULT);
			float angle=(float)param2;
			m_base->pBodySetLinearVelocity(m_base, m_mBase->m_body, force, angle);
		}
            break;
        case EXP_EXTGETVELOCITY:
		{
			b2Vec2 v = m_base->pBodyGetLinearVelocity(m_base, m_mBase->m_body);
			double velocity = sqrt(v.x * v.x + v.y * v.y)*100.0f/SETVELOCITY_MULT;
			if (velocity < 0.001)
				velocity = 0;
			return velocity;
		}
        case EXP_EXTGETANGLE:
		{
			b2Vec2 v = m_base->pBodyGetLinearVelocity(m_base, m_mBase->m_body);
			if (std::abs(v.x) < 0.001 && std::abs(v.y) < 0.001)
				return -1;
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



/////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunMvtbox2dracecar

-(void)initialize:(CFile*)file
{
    m_object = new CRunBox2DRaceCar();
    m_object->m_movement = self;
    m_movement = m_object;
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