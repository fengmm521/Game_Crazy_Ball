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
//  CRunMvtbox2daxial.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 07/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtbox2daxial.h"
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

#define FREQUENCYMULT (m_pHo->hoAdRunHeader->rhApp->m_hdr.gaFrameRate/(2.0f*10.0f))
void CRunBox2DAxial::Initialize(LPHO pHo, CFile* file)
{
    LPRH rhPtr = pHo->hoAdRunHeader;
	m_mBase = nil;
	m_pHo = pHo;
	m_base = nil;
	m_fixture = nil;
    
    [file skipBytes:1];
	m_angle=(float)(((float)[m_movement dirAtStart:[file readAInt]]*180.0)/16.0);
    m_friction=(float)([file readAInt]/100.0);
    m_gravity=(float)([file readAInt]/100.0);
    m_density=(float)([file readAInt]/100.0);
    m_restitution=(float)([file readAInt]/100.0);
    m_flags=[file readAInt];
    m_shape=[file readAShort];
    m_length=[file readAInt];
    m_elasticity=(float)([file readAInt]/100.0);
    m_frequency=(float)([file readAInt]/100.0*rhPtr->rhApp->gaFrameRate/(2.0*10.0));
    m_offsetX=[file readAInt];
    m_offsetY=[file readAInt];
    m_torque=(float)([file readAInt]/100.0*35);
    m_damping=(float)([file readAInt]/100.0);
    m_identifier = [file readAInt];
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
	m_previousAngle=-1;
    m_started = NO;
	m_base=GetBase();
}
void CRunBox2DAxial::Delete()
{
	LPRDATABASE pBase=GetBase();
	if (pBase!=nil && m_mBase != nil)
	{
		pBase->pDestroyBody(pBase, m_bodyAxe);
		pBase->pDestroyBody(pBase, m_mBase->m_body);
        delete m_mBase;
	}
    [m_jointName release];
    [m_jointObject release];
}

LPRDATABASE CRunBox2DAxial::GetBase()
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

BOOL CRunBox2DAxial::CreateBody(LPHO pHo)
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
    
	m_mBase->m_body = m_base->pCreateBody(m_base, b2_dynamicBody, pHo->hoX, pHo->hoY, m_angle, m_gravity, (void*)m_mBase, 0, 0);
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
	int x=(int)(pHo->hoX-m_length*cos(m_angle*b2_pi/180.0f));
	int y=(int)(pHo->hoY+m_length*sin(m_angle*b2_pi/180.0f));
	m_bodyAxe=m_base->pCreateBody(m_base, b2_staticBody, x, y, 0, 0, nil, 0, 0);
	m_base->pBodyCreateBoxFixture(m_base, m_bodyAxe, nil, x, y, 16, 16, 0, 0, 0);
	int xOffset=(int)(m_offsetX*cos(m_angle)-m_offsetY*sin(m_angle));
	int yOffset=(int)(m_offsetX*sin(m_angle)+m_offsetY*cos(m_angle));
	m_base->pCreateDistanceJoint(m_base, m_mBase->m_body, m_bodyAxe, m_elasticity, m_frequency, xOffset, yOffset);		// TODO faire la rotation
	m_base->pBodySetAngularVelocity(m_base, m_mBase->m_body, -m_torque);
	m_base->pBodySetAngularDamping(m_base, m_mBase->m_body, m_damping);
    
	return YES;
}
void CRunBox2DAxial::CreateFixture(LPHO pHo)
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
void CRunBox2DAxial::CreateJoint(LPHO pHo)
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
BOOL CRunBox2DAxial::Move(LPHO pHo)
{
	if (!CreateBody(pHo))
		return NO;
      
	// Scale changed?
	if (pHo->roc->rcScaleX != m_scaleX || pHo->roc->rcScaleY != m_scaleY)
		CreateFixture(pHo);
    
	m_base->pBodyAddVelocity(m_base, m_mBase->m_body, m_mBase->m_addVX, m_mBase->m_addVY);
	m_mBase->ResetAddVelocity();
    
	int x, y;
	m_base->pGetBodyPosition(m_base, m_mBase->m_body, &x, &y, &m_mBase->m_currentAngle);
	if (x!=pHo->hoX || y!=pHo->hoY)
	{
		pHo->hoX=x;
		pHo->hoY=y;
        m_started = YES;
		pHo->roc->rcChanged=1;
	}
    SetCurrentAngle(m_mBase->m_currentAngle);
    
	int anim=ANIMID_STOP;
	[m_movement animations:anim];
    if (m_flags & AXFLAG_FINECOLLISIONS)
        [m_movement collisions];
    
	// The object has been moved
	return pHo->roc->rcChanged;
}

void CRunBox2DAxial::SetCurrentAngle(float angle)
{
	if (angle!=m_previousAngle)
	{
		m_previousAngle=angle;
		m_pHo->roc->rcChanged=YES;
		if (m_flags&AXFLAG_ROTATE)
		{
			m_pHo->roc->rcAngle=angle;
			m_pHo->roc->rcDir=0;
		}
		else
		{
			m_pHo->roc->rcDir=(int)(angle/11.25f);
            while(m_pHo->roc->rcDir < 0)
                m_pHo->roc->rcDir += 32;
            while(m_pHo->roc->rcDir >= 32)
                m_pHo->roc->rcDir -= 32;
		}
	}
}

// Changes both X and Y position
// -----------------------------
void CRunBox2DAxial::SetPos(LPHO pHo, int x, int y)
{
	float angle;
	int xBody, yBody, xAxe, yAxe;
	m_base->pGetBodyPosition(m_base, m_mBase->m_body, &xBody, &yBody, &angle);
	m_base->pGetBodyPosition(m_base, m_bodyAxe, &xAxe, &yAxe, &angle);
	int deltaX=xAxe-xBody;
	int deltaY=yAxe-yBody;
	if (x==POSDEFAULT)
		x=xBody;
	if (y==POSDEFAULT)
		y=yBody;
	m_base->pBodySetPosition(m_base, m_mBase->m_body, x, y);
	m_base->pBodySetPosition(m_base, m_bodyAxe, x+deltaX, y+deltaY);
    if (!m_started)
    {
        m_pHo->hoX = x;
        m_pHo->hoY = y;
    }
    
}
void CRunBox2DAxial::SetFriction(int friction)
{
	m_friction=maxd((float)(((float)friction)/100.0), 0);
	m_fixture->SetFriction(m_friction);
}
void CRunBox2DAxial::SetGravity(int gravity)
{
	m_gravity=maxd((float)(((float)gravity)/100.0), 0);
	m_base->pBodySetGravityScale(m_base, m_mBase->m_body, m_gravity);
}
void CRunBox2DAxial::SetDensity(int density)
{
	m_density=maxd((float)(((float)density)/100.0), 0);
	m_fixture->SetDensity(m_density);
	m_base->pBodyResetMassData(m_base, m_mBase->m_body);
}
void CRunBox2DAxial::SetRestitution(int restitution)
{
	m_restitution=maxd((float)(((float)restitution)/100.0), 0);
	m_base->pFixtureSetRestitution(m_base, m_fixture, m_restitution);
}
void CRunBox2DAxial::SetAngle(float angle)
{
	m_base->pBodySetAngle(m_base, m_mBase->m_body, angle);
    if (!m_started)
        SetCurrentAngle(angle);
}
float CRunBox2DAxial::GetAngle()
{
	if (m_flags&AXFLAG_ROTATE)
	{
		return m_mBase->m_currentAngle;
	}
	return ANGLE_MAGIC;
}


DWORD CRunBox2DAxial::GetFriction()
{
	return (DWORD)(m_friction * 100.0);
}
DWORD CRunBox2DAxial::GetDensity()
{
	return (DWORD)(m_density*100.0);
}
DWORD CRunBox2DAxial::GetRestitution()
{
	return (DWORD)(m_restitution * 100.0);
}

void CRunBox2DAxial::SetPosition(LPHO pHo, int x, int y)
{
	if (x!=pHo->hoX || y!=pHo->hoY)
		SetPos(pHo, x, y);
}

// Changes X position
// ------------------
void CRunBox2DAxial::SetXPosition(LPHO pHo, int x)
{
	if (x!=pHo->hoX)
		SetPos(pHo, x, POSDEFAULT);
}

// Changes Y position
// ------------------
void CRunBox2DAxial::SetYPosition(LPHO pHo, int y)
{
	if (y!=pHo->hoY)
		SetPos(pHo, POSDEFAULT, y);
}

// Stops the object
// ----------------
void CRunBox2DAxial::Stop(LPHO pHo, BOOL bCurrent)
{
	m_mBase->SetStopFlag(YES);
	if (m_mBase->m_eventCount!=pHo->hoAdRunHeader->rh4EventCount)
	{
		m_base->pBodySetLinearVelocityAdd(m_base, m_mBase->m_body, 0, 0, 0, 0);
	}
}

// Bounces the object
// ------------------
void CRunBox2DAxial::Bounce(LPHO pHo, BOOL bCurrent)
{
}

// Go in reverse
// -------------
void CRunBox2DAxial::Reverse(LPHO pHo)
{
}

// Restart the movement
// --------------------
void CRunBox2DAxial::Start(LPHO pHo)
{
}

// Changes the speed
// -----------------
void CRunBox2DAxial::SetSpeed(LPHO pHo, int speed)
{
}

// Changes the maximum speed
// -------------------------
void CRunBox2DAxial::SetMaxSpeed(LPHO pHo, int speed)
{
}

// Changes the direction
// ---------------------
void CRunBox2DAxial::SetDir(LPHO pHo, int dir)
{
	m_base->pBodySetAngle(m_base, m_mBase->m_body, (float)(dir*11.25));
    if (!m_started)
        SetCurrentAngle((float)(dir*11.25));
}
int CRunBox2DAxial::GetDir(LPHO pHo)
{
	if (m_flags&AXFLAG_ROTATE)
		return (int)(m_mBase->m_currentAngle/11.25f);
	else
		return pHo->roc->rcDir;
}

// Changes the acceleration
// ------------------------
void CRunBox2DAxial::SetAcc(LPHO pHo, int acc)
{
}

// Changes the deceleration
// ------------------------
void CRunBox2DAxial::SetDec(LPHO pHo, int dec)
{
}

// Changes the rotation speed
// --------------------------
void CRunBox2DAxial::SetRotSpeed(LPHO pHo, int speed)
{
}

// Changes the authorised directions out of 8
// ------------------------------------------
void CRunBox2DAxial::Set8Dirs(LPHO pHo, int dirs)
{
}

// Changes the gravity
// -------------------
void CRunBox2DAxial::SetGravity(LPHO pHo, int gravity)
{
	m_gravity=(float)(((float)gravity)/100.0);
	m_base->pBodySetGravityScale(m_base, m_mBase->m_body, m_gravity);
}

// Returns the speed
// -----------------
int CRunBox2DAxial::GetSpeed(LPHO pHo)
{
	return pHo->roc->rcSpeed;
}

// Returns the acceleration
// ------------------------
int CRunBox2DAxial::GetAcceleration(LPHO pHo)
{
	return 0;
}

// Returns the deceleration
// ------------------------
int CRunBox2DAxial::GetDeceleration(LPHO pHo)
{
	return 0;
}

// Returns the gravity
// -------------------
int CRunBox2DAxial::GetGravity(LPHO pHo)
{
	return (int)(m_gravity*100.0);
}


// Extension Actions entry
// -----------------------
double CRunBox2DAxial::ActionEntry(LPHO pHo, int action, double param1, double param2)
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


////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunMvtbox2daxial

-(void)initialize:(CFile*)file
{
    m_object = new CRunBox2DAxial();
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
