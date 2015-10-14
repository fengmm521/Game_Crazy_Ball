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
//  CRunMvtbox2d8directions.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 07/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtbox2d8directions.h"
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

#define EDACCMULT 3.0f
#define EDDECMULT 0.05f
float CRunBox2D8Directions::Normalize(float angle)
{
	while(angle>360.0f)
		angle-=360.0f;
	while(angle<0.0f)
		angle+=360.0f;
	return angle;
}
float CRunBox2D8Directions::Minus(float angle)
{
	if (angle>180.0f)
		angle=angle-360.0f;
	return angle;
}
void CRunBox2D8Directions::Initialize(LPHO pHo, CFile* file)
{
	m_mBase = nil;
	m_pHo = pHo;
	m_base = nil;
	m_fixture = nil;

    [file skipBytes:1];
    m_angle=(float)( [m_movement dirAtStart:[file readAInt]] * 180.0 / 16.0);
    m_friction=(float)([file readAInt]/100.0);
    m_gravity=(float)([file readAInt]/100.0);
    m_density=(float)([file readAInt]/100.0);
    m_restitution=(float)([file readAInt]/100.0);
    m_flags=[file readAInt];
    m_shape=[file readAShort];
	pHo->roc->rcMinSpeed=0;
    pHo->roc->rcMaxSpeed=[file readAInt];
    m_speed=(float)(pHo->roc->rcMaxSpeed/100.0/2.0);
    m_acceleration=(float)([file readAInt]/(100.0*EDACCMULT));
    m_deceleration=(float)([file readAInt]*EDDECMULT);
    m_dirs=[file readAInt];
    m_identifier=[file readAInt];
    m_rotationSpeed=(float)([file readAInt]/100.0*20.0);
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
    
    m_started = NO;
	m_gotoSpeed=0;
	m_angle=Minus(m_angle);
	m_gotoAngle=m_angle;
	m_calculAngle=m_angle;
	m_numberOfSteps=0;
	m_previousAngle=-1;
}

void CRunBox2D8Directions::Delete()
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

LPRDATABASE CRunBox2D8Directions::GetBase()
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
BOOL CRunBox2D8Directions::CreateBody(LPHO pHo)
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
	m_mBase->m_currentAngle = m_angle;
    
	m_mBase->m_body = m_base->pCreateBody(m_base, b2_dynamicBody, pHo->hoX, pHo->hoY, m_angle, m_gravity, m_mBase, 0, 0);
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
	m_base->pBodySetLinearDamping(m_base, m_mBase->m_body, m_deceleration);
	b2Vec2 position=m_base->pBodyGetPosition(m_base, m_mBase->m_body);
	m_previousX=position.x;
	m_previousY=position.y;
    
	return YES;
}
void CRunBox2D8Directions::CreateFixture(LPHO pHo)
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
void CRunBox2D8Directions::CreateJoint(LPHO pHo)
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

BOOL CRunBox2D8Directions::Move(LPHO pHo)
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
	BOOL flag=NO;
	if ((j&15)!=0)
	{
		DWORD mask=1<<Joy2Dir[j&15];
		if (m_dirs&mask)
		{
			m_gotoAngle=(float)(Joy2Dir[j&15]*11.25f);
			m_gotoAngle=Minus(m_gotoAngle);
			m_calculAngle=Minus(m_calculAngle);
			float dir=m_gotoAngle-m_calculAngle;
			if (dir > 0 && std::abs(dir) <= 180)
				m_gotoSpeed=m_rotationSpeed;
			else if (dir > 0 && std::abs(dir) > 180)
				m_gotoSpeed=-m_rotationSpeed;
			else if (dir < 0 && std::abs(dir) <= 180)
				m_gotoSpeed=-m_rotationSpeed;
			else if (dir < 0 && std::abs(dir) > 180)
				m_gotoSpeed=m_rotationSpeed;
			if (std::abs(dir)<180)
				m_numberOfSteps=MAX(1, (int)(std::abs(dir)/m_rotationSpeed));
			else
				m_numberOfSteps=MAX(1, (int)((360.0f-std::abs(dir))/m_rotationSpeed));
			flag=YES;
		}
	}
	if (m_numberOfSteps>0)
	{
		m_calculAngle+=m_gotoSpeed;
		m_numberOfSteps--;
		if (m_numberOfSteps==0)
		{
			m_calculAngle=m_gotoAngle;
		}
		m_mBase->m_currentAngle=Normalize(m_calculAngle);
	}
	if (flag)
	{
        m_mBase->m_body->SetLinearDamping(0);
		m_base->pBodyAddLinearVelocity(m_base, m_mBase->m_body, m_acceleration, m_mBase->m_currentAngle);
	}
    else
    {
        m_mBase->m_body->SetLinearDamping(m_deceleration);
    }
    
	m_base->pBodySetAngle(m_base, m_mBase->m_body, m_mBase->m_currentAngle);
    
	m_base->pBodyAddVelocity(m_base, m_mBase->m_body, m_mBase->m_addVX, m_mBase->m_addVY);
	m_mBase->ResetAddVelocity();
    
    SetCurrentAngle(pHo);
    
	b2Vec2 position=m_base->pBodyGetPosition(m_base, m_mBase->m_body);
	float deltaX=(position.x-m_previousX)*m_base->factor;
	float deltaY=(position.y-m_previousY)*m_base->factor;
	m_previousX=position.x;
	m_previousY=position.y;
	double length=sqrt(deltaX*deltaX+deltaY*deltaY);
	pHo->roc->rcSpeed=(int)((50.0f*length/7.0f)*rhPtr->rh4MvtTimerCoef);
	pHo->roc->rcSpeed=MIN(pHo->roc->rcSpeed, 250);

	int x, y;
	float angle;
	m_base->pGetBodyPosition(m_base, m_mBase->m_body, &x, &y, &angle);
	if (x!=pHo->hoX || y!=pHo->hoY)
	{
		pHo->hoX=x;
		pHo->hoY=y;
        m_started = YES;
		pHo->roc->rcChanged=YES;
	}
    
    [m_movement animations:anim];
    if (m_flags & EDFLAG_FINECOLLISIONS)
        [m_movement collisions];
    
    
	// The object has been moved
	return pHo->roc->rcChanged;
}

void CRunBox2D8Directions::SetCurrentAngle(LPHO pHo)
{
	if (m_mBase->m_currentAngle!=m_previousAngle)
	{
		m_previousAngle=m_mBase->m_currentAngle;
		pHo->roc->rcChanged=YES;
		if (m_flags&EDFLAG_ROTATE)
		{
            pHo->roc->rcAngle=m_mBase->m_currentAngle;
			pHo->roc->rcDir=0;
		}
		else
		{
			pHo->roc->rcDir=(int)(m_mBase->m_currentAngle/11.25f);
            while(pHo->roc->rcDir < 0)
                pHo->roc->rcDir += 32;
            while(pHo->roc->rcDir >= 32)
                pHo->roc->rcDir -= 32;
		}
	}
    
}
void CRunBox2D8Directions::SetFriction(int friction)
{
	m_friction=maxd((float)(((float)friction)/100.0), 0);
	m_fixture->SetFriction(m_friction);
}
void CRunBox2D8Directions::SetGravity(int gravity)
{
	m_gravity=maxd((float)(((float)gravity)/100.0), 0);
	m_base->pBodySetGravityScale(m_base, m_mBase->m_body, m_gravity);
}
void CRunBox2D8Directions::SetDensity(int density)
{
	m_density=maxd((float)(((float)density)/100.0), 0);
	m_fixture->SetDensity(m_density);
	m_base->pBodyResetMassData(m_base, m_mBase->m_body);
}
void CRunBox2D8Directions::SetRestitution(int restitution)
{
	m_restitution=maxd((float)(((float)restitution)/100.0), 0);
	m_base->pFixtureSetRestitution(m_base, m_fixture, m_restitution);
}
void CRunBox2D8Directions::SetAngle(float angle)
{
	m_mBase->m_currentAngle = angle;
	m_calculAngle = angle;
    if (!m_started)
        SetCurrentAngle(m_pHo);
    
	b2Vec2 vect = m_mBase->m_body->GetLinearVelocity();
	float length = sqrt(vect.x * vect.x + vect.y * vect.y);
	vect.x=(float)(length*cos(angle * b2_pi / 180.0f));
	vect.y=(float)(length*sin(angle * b2_pi / 180.0f));
	m_base->pBodySetLinearVelocityVector(m_base, m_mBase->m_body, vect);
}
float CRunBox2D8Directions::GetAngle()
{
	if (m_flags&EDFLAG_ROTATE)
	{
		return m_mBase->m_currentAngle;
	}
	return ANGLE_MAGIC;
}

DWORD CRunBox2D8Directions::GetFriction()
{
	return (DWORD)(m_friction * 100.0);
}
DWORD CRunBox2D8Directions::GetDensity()
{
	return (DWORD)(m_density*100.0);
}
DWORD CRunBox2D8Directions::GetRestitution()
{
	return (DWORD)(m_restitution * 100.0);
}

// Changes both X and Y position
// -----------------------------
void CRunBox2D8Directions::SetPosition(LPHO pHo, int x, int y)
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
void CRunBox2D8Directions::SetXPosition(LPHO pHo, int x)
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
void CRunBox2D8Directions::SetYPosition(LPHO pHo, int y)
{
	if (y!=pHo->hoY)
    {
        if (!m_started)
            pHo->hoY = y;
		m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, y);
    }
}

// Stops the object
// ----------------
void CRunBox2D8Directions::Stop(LPHO pHo, BOOL bCurrent)
{
	m_mBase->SetStopFlag(YES);
    
	if (m_mBase->m_eventCount!=pHo->hoAdRunHeader->rh4EventCount)
	{
		m_base->pBodySetLinearVelocityAdd(m_base, m_mBase->m_body, 0, 0, 0, 0);
	}
}

// Bounces the object
// ------------------
void CRunBox2D8Directions::Bounce(LPHO pHo, BOOL bCurrent)
{
}

// Go in reverse
// -------------
void CRunBox2D8Directions::Reverse(LPHO pHo)
{
}

// Restart the movement
// --------------------
void CRunBox2D8Directions::Start(LPHO pHo)
{
}

// Changes the speed
// -----------------
void CRunBox2D8Directions::SetSpeed(LPHO pHo, int speed)
{
	float speedf = speed / 100.0f * SETVELOCITY_MULT;
	float angle = (float)(m_base->pBodyGetAngle(m_base, m_mBase->m_body) * 180.0f / b2_pi);
	m_base->pBodySetLinearVelocity(m_base, m_mBase->m_body, speedf, angle);
}

// Changes the maximum speed
// -------------------------
void CRunBox2D8Directions::SetMaxSpeed(LPHO pHo, int speed)
{
}

// Changes the direction
// ---------------------
void CRunBox2D8Directions::SetDir(LPHO pHo, int dir)
{
	if (m_flags&EDFLAG_ROTATE)
		SetAngle(dir*11.25f);
	else
		pHo->roc->rcDir=dir;
}
int CRunBox2D8Directions::GetDir(LPHO pHo)
{
	if (m_flags&EDFLAG_ROTATE)
		return (int)(m_mBase->m_currentAngle/11.25f);
	else
		return pHo->roc->rcDir;
}

// Changes the acceleration
// ------------------------
void CRunBox2D8Directions::SetAcc(LPHO pHo, int acc)
{
	m_acceleration=(float)(((float)acc)/(100.0*EDACCMULT));
}

// Changes the deceleration
// ------------------------
void CRunBox2D8Directions::SetDec(LPHO pHo, int dec)
{
	m_deceleration=(float)(((float)dec)*EDDECMULT);
}

// Changes the rotation speed
// --------------------------
void CRunBox2D8Directions::SetRotSpeed(LPHO pHo, int speed)
{
}

// Changes the authorised directions out of 8
// ------------------------------------------
void CRunBox2D8Directions::Set8Dirs(LPHO pHo, int dirs)
{
}

// Changes the gravity
// -------------------
void CRunBox2D8Directions::SetGravity(LPHO pHo, int gravity)
{
	m_gravity=(float)(((float)gravity)/100.0);
	m_base->pBodySetGravityScale(m_base, m_mBase->m_body, m_gravity);
}

// Returns the speed
// -----------------
int CRunBox2D8Directions::GetSpeed(LPHO pHo)
{
	return pHo->roc->rcSpeed;
}

// Returns the acceleration
// ------------------------
int CRunBox2D8Directions::GetAcceleration(LPHO pHo)
{
	return (int)(m_acceleration*(100.0*EDACCMULT));
}

// Returns the deceleration
// ------------------------
int CRunBox2D8Directions::GetDeceleration(LPHO pHo)
{
	return (int)(m_deceleration/EDDECMULT);
}

// Returns the gravity
// -------------------
int CRunBox2D8Directions::GetGravity(LPHO pHo)
{
	return (int)(m_gravity*100.0);
}


// Extension Actions entry
// -----------------------
double CRunBox2D8Directions::ActionEntry(LPHO pHo, int action, double param1, double param2)
{
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

@implementation CRunMvtbox2d8directions

-(void)initialize:(CFile*)file
{
    m_object = new CRunBox2D8Directions();
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
