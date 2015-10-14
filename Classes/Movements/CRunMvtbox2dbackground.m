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
//  CRunMvtbox2dbackground.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 08/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtbox2dbackground.h"
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

void CRunBox2DBackground::Initialize(LPHO pHo, CFile* file)
{
	m_mBase = nil;
	m_pHo = pHo;
	m_base = nil;
	m_fixture = nil;
    
   [file skipBytes:1];
    m_friction=(float)([file readAInt]/100.0);
    m_restitution=(float)([file readAInt]/100.0);
    m_flags=[file readAInt];
	m_angle=(float)(((float)[m_movement dirAtStart:[file readAInt]]*180.0)/16.0);
    m_shape=[file readAShort];
    m_obstacle=[file readAShort];
    m_identifier=[file readAInt];
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
	m_previousAngle = -1;
    
	m_base=GetBase();
}

void CRunBox2DBackground::Delete()
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
LPRDATABASE CRunBox2DBackground::GetBase()
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
BOOL CRunBox2DBackground::CreateBody(LPHO pHo)
{
	if (m_mBase != nil && m_mBase->m_body!=nil)
		return YES;
    
	if (m_base==nil)
	{
		m_base=GetBase();
	}
    
	if (m_base==nil)
		return NO;
	
	switch (m_obstacle)
	{
        case 1:
            m_mBase = new CRunMBase(m_base, pHo, MTYPE_OBSTACLE);
            break;
        case 2:
            m_mBase = new CRunMBase(m_base, pHo, MTYPE_PLATFORM);
            break;
        default:
            m_mBase = new CRunMBase(m_base, pHo, MTYPE_OBJECT);
            break;
	}
    m_mBase->m_background = YES;
	m_mBase->m_movement = this;
	m_mBase->m_identifier = m_identifier;
	m_mBase->m_body = m_base->pCreateBody(m_base, b2_staticBody, pHo->hoX, pHo->hoY, m_angle, 0, m_mBase, 0, 0);
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
    m_moved = 2;
    
	return YES;
}
void CRunBox2DBackground::CreateFixture(LPHO pHo)
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
            m_fixture=m_base->pBodyCreateBoxFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, (int)(m_imgWidth * m_scaleX), (int)(m_imgHeight * m_scaleY), 0, m_friction, m_restitution);
            break;
        case 1:
            m_fixture=m_base->pBodyCreateCircleFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, (int)((m_imgWidth + m_imgHeight)/4 * (m_scaleX + m_scaleY) / 2), 0, m_friction, m_restitution);
            break;
        case 2:
            m_fixture=m_base->pBodyCreateShapeFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, m_mBase->m_image, 0, m_friction, m_restitution, m_scaleX, m_scaleY);
            break;
	}
}
void CRunBox2DBackground::CreateJoint(LPHO pHo)
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
BOOL CRunBox2DBackground::Move(LPHO pHo)
{
	if (!CreateBody(pHo))
		return NO;
    
	// Scale changed?
	if (pHo->roc->rcScaleX != m_scaleX || pHo->roc->rcScaleY != m_scaleY)
		CreateFixture(pHo);
    
	int x, y;
	m_base->pGetBodyPosition(m_base, m_mBase->m_body, &x, &y, &m_mBase->m_currentAngle);
    if (m_moved > 0)
    {
        if (x!=pHo->hoX || y!=pHo->hoY)
        {
            pHo->hoX=x;
            pHo->hoY=y;
            pHo->roc->rcChanged=1;
        }
        m_moved--;
    }
	if (m_mBase->m_currentAngle!=m_previousAngle)
	{
		m_previousAngle=m_mBase->m_currentAngle;
		pHo->roc->rcChanged=1;
		if (m_flags&BKFLAG_ROTATE)
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
    [m_movement animations:ANIMID_STOP];
    
	return pHo->roc->rcChanged;
}

// Changes both X and Y position
// -----------------------------
void CRunBox2DBackground::SetFriction(int friction)
{
	m_friction=maxd((float)(((float)friction)/100.0), 0);
	m_fixture->SetFriction(m_friction);
}
void CRunBox2DBackground::SetRestitution(int restitution)
{
	m_restitution=maxd((float)(((float)restitution)/100.0), 0);
	m_fixture->SetRestitution(m_restitution);
}
DWORD CRunBox2DBackground::GetFriction()
{
	return (DWORD)(m_friction * 100.0);
}
DWORD CRunBox2DBackground::GetRestitution()
{
	return (DWORD)(m_restitution * 100.0);
}

// Changes both X and Y position
// -----------------------------
void CRunBox2DBackground::SetPosition(LPHO pHo, int x, int y)
{
	if (x!=pHo->hoX || y!=pHo->hoY)
	{
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, POSDEFAULT);
		m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, y);
        m_moved = 10;
	}
}

// Changes X position
// ------------------
void CRunBox2DBackground::SetXPosition(LPHO pHo, int x)
{
	if (x!=pHo->hoX)
    {
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, POSDEFAULT);
        m_moved = 10;
    }
}

// Changes Y position
// ------------------
void CRunBox2DBackground::SetYPosition(LPHO pHo, int y)
{
	if (y!=pHo->hoY)
    {
		m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, y);
        m_moved = 10;
    }
}

// Stops the object
// ----------------
void CRunBox2DBackground::Stop(LPHO pHo, BOOL bCurrent)
{
}

// Bounces the object
// ------------------
void CRunBox2DBackground::Bounce(LPHO pHo, BOOL bCurrent)
{
}

// Go in reverse
// -------------
void CRunBox2DBackground::Reverse(LPHO pHo)
{
}

// Restart the movement
// --------------------
void CRunBox2DBackground::Start(LPHO pHo)
{
}

// Changes the speed
// -----------------
void CRunBox2DBackground::SetSpeed(LPHO pHo, int speed)
{
}

// Changes the maximum speed
// -------------------------
void CRunBox2DBackground::SetMaxSpeed(LPHO pHo, int speed)
{
}

// Changes the direction
// ---------------------
void CRunBox2DBackground::SetDir(LPHO pHo, int dir)
{
}

// Changes the acceleration
// ------------------------
void CRunBox2DBackground::SetAcc(LPHO pHo, int acc)
{
}

// Changes the deceleration
// ------------------------
void CRunBox2DBackground::SetDec(LPHO pHo, int dec)
{
}

void CRunBox2DBackground::SetAngle(float angle)
{
	m_base->pBodySetAngle(m_base, m_mBase->m_body, angle);
}
float CRunBox2DBackground::GetAngle()
{
	if (m_flags&BKFLAG_ROTATE)
	{
		return m_mBase->m_currentAngle;
	}
	return ANGLE_MAGIC;
}

// Changes the rotation speed
// --------------------------
void CRunBox2DBackground::SetRotSpeed(LPHO pHo, int speed)
{
}

// Changes the authorised directions out of 8
// ------------------------------------------
void CRunBox2DBackground::Set8Dirs(LPHO pHo, int dirs)
{
}

// Changes the gravity
// -------------------
void CRunBox2DBackground::SetGravity(LPHO pHo, int gravity)
{
}

// Returns the speed
// -----------------
int CRunBox2DBackground::GetSpeed(LPHO pHo)
{
	return pHo->roc->rcSpeed;
}

// Returns the acceleration
// ------------------------
int CRunBox2DBackground::GetAcceleration(LPHO pHo)
{
	return 0;
}

// Returns the deceleration
// ------------------------
int CRunBox2DBackground::GetDeceleration(LPHO pHo)
{
	return 0;
}

// Returns the gravity
// -------------------
int CRunBox2DBackground::GetGravity(LPHO pHo)
{
	return 0;
}


// Extension Actions entry
// -----------------------
double CRunBox2DBackground::ActionEntry(LPHO pHo, int action, double param1, double param2)
{
	switch (action)
	{
        case ACT_EXTSETFRICTION:
            SetFriction(param1);
            break;
        case ACT_EXTSETELASTICITY:
            SetRestitution(param1);
            break;
        case EXP_EXTGETFRICTION:
            return GetFriction();
        case EXP_EXTGETRESTITUTION:
            return GetRestitution();
        default:
            break;
	}
	return 0;
}


////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunMvtbox2dbackground

-(void)initialize:(CFile*)file
{
    m_object = new CRunBox2DBackground();
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
