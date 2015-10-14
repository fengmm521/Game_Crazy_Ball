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
//  CRunMvtbox2dspring.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunMvtbox2dspring.h"
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
#import "CRAni.h"
#import "CObject.h"
#import "CExtension.h"

void CRunBox2DSpring::Initialize(LPHO pHo, CFile* file)
{
	m_mBase = nil;
	m_pHo = pHo;
	m_base=GetBase();
	m_fixture = nil;
    
    [file skipBytes:1];
    m_angle = (float)( [m_movement dirAtStart:[file readAInt]] * 180.0 / 16.0);
    m_strength=(float)([file readAInt]/100.0*10.0);
    m_flags=[file readAInt];
    m_shape=[file readAShort];
    m_identifier=[file readAInt];

	m_changed=NO;
	m_anim=ANIMID_STOP;
	m_actionCounter=0;
	m_actionObject=nil;
    m_started = NO;
    
	m_previousAngle=-1;
}

void CRunBox2DSpring::SetCollidingObject(CRunMBase* object)
{
	if ((m_flags&SPFLAG_ACTIVE)!=0 && object!=m_mBase)
	{
		if (m_actionObject != object)
		{
			m_actionObject = object;
			m_actionCounter=10;
			b2Vec2 velocity=m_base->pBodyGetLinearVelocity(m_base, object->m_body);
			float v=sqrt(velocity.x*velocity.x+velocity.y*velocity.y);
			m_base->pBodyAddLinearVelocity(m_base, object->m_body, m_strength+v, m_mBase->m_currentAngle);
			m_flags|=SPFLAG_WORKING;
			m_anim=ANIMID_WALK;
            m_pHo->roa->raAnimForced=m_anim+1;
            m_pHo->roa->raAnimRepeat=1;
            m_pHo->roc->rcSpeed=50;
            [m_movement animations:m_anim];
            m_pHo->roc->rcSpeed=0;
		}
	}
}

void CRunBox2DSpring::Delete()
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
LPRDATABASE CRunBox2DSpring::GetBase()
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
BOOL CRunBox2DSpring::CreateBody(LPHO pHo)
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
    
	float angle = m_angle;
	if ((m_flags &SPFLAG_ROTATE) == 0)
		angle = 0;
	m_mBase->m_body=m_base->pCreateBody(m_base, b2_staticBody, pHo->hoX, pHo->hoY, angle, 0, m_mBase, 0, 0);
	m_mBase->m_currentAngle = m_angle;
	if ((pHo->hoOEFlags & OEFLAG_ANIMATIONS) == 0)
	{
		m_shape = 0;
		m_mBase->m_image = -1;
		m_imgWidth = pHo->hoImgWidth;
		m_imgHeight = pHo->hoImgHeight;
	}
	else
	{
		if ((m_flags&SPFLAG_ROTATE)==0)
		{
			pHo->roc->rcDir = (int)(m_angle / 11.25);
            while(pHo->roc->rcDir < 0)
                pHo->roc->rcDir += 32;
            while(pHo->roc->rcDir >= 32)
                pHo->roc->rcDir -= 32;            
			[m_movement animations:ANIMID_STOP];
		}
		m_mBase->m_image = pHo->roc->rcImage;
        CImage* pImage;
        pImage = [m_pHo->hoAdRunHeader->rhApp->imageBank getImageFromHandle:m_mBase->m_image];
		m_imgWidth = pImage->width;
		m_imgHeight = pImage->height;
	}
	CreateFixture(pHo);
    
	return YES;
}
void CRunBox2DSpring::CreateFixture(LPHO pHo)
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
            m_fixture=m_base->pBodyCreateBoxFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, (int)(m_imgWidth * m_scaleX), (int)(m_imgHeight * m_scaleY), 30, 0, 0);
            break;
        case 1:
            m_fixture=m_base->pBodyCreateCircleFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, (int)((m_imgWidth + m_imgHeight)/4 * (m_scaleX + m_scaleY) / 2), 30, 0, 0);
            break;
        case 2:
            m_fixture=m_base->pBodyCreateShapeFixture(m_base, m_mBase->m_body, m_mBase, m_pHo->hoX, m_pHo->hoY, m_mBase->m_image, 30, 0, 0, m_scaleX, m_scaleY);
            break;
	}
}
BOOL CRunBox2DSpring::Move(LPHO pHo)
{
	if (!CreateBody(pHo))
		return NO;
    
    
	// Scale changed?
	if (pHo->roc->rcScaleX != m_scaleX || pHo->roc->rcScaleY != m_scaleY)
		CreateFixture(pHo);
    
	if (m_actionCounter > 0)
	{
		m_actionCounter--;
		if (m_actionCounter == 0)
			m_actionObject = nil;
	}
    
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
    SetCurrentAngle(angle);
    
	if ((m_flags&SPFLAG_WORKING)!=0 && pHo->roa != nil)
	{
        if (pHo->roa->raAnimOn!=ANIMID_WALK || pHo->roa->raAnimFrame>=pHo->roa->raAnimNumberOfFrame)
        {
            m_flags&=~SPFLAG_WORKING;
            m_anim=ANIMID_STOP;
            pHo->roa->raAnimForced=0;
            pHo->roa->raAnimFrame=0;
        }
 	}
	pHo->roc->rcSpeed=50;
	[m_movement animations:m_anim];
	pHo->roc->rcSpeed=0;
    
	pHo->roc->rcChanged|=m_changed;
	m_changed=NO;
    
	return pHo->roc->rcChanged;
}

void CRunBox2DSpring::SetCurrentAngle(float angle)
{
	if (m_flags&SPFLAG_ROTATE)
	{
		if (angle!=m_previousAngle)
		{
			m_mBase->m_currentAngle = angle;
			m_previousAngle=m_mBase->m_currentAngle;
			m_pHo->roc->rcChanged=YES;
			m_pHo->roc->rcAngle=m_mBase->m_currentAngle;
			m_pHo->roc->rcDir=0;
		}
	}
}
// Changes both X and Y position
// -----------------------------
void CRunBox2DSpring::SetPosition(LPHO pHo, int x, int y)
{
	if (x!=pHo->hoX || y!=pHo->hoY)
	{
        if (!m_started)
        {
            pHo->hoX = x;
            pHo->hoY = y;
        }
		m_base->pBodySetPosition(m_base, m_mBase->m_body, x, POSDEFAULT);
		m_base->pBodySetPosition(m_base, m_mBase->m_body, POSDEFAULT, y);
	}
}

// Changes X position
// ------------------
void CRunBox2DSpring::SetXPosition(LPHO pHo, int x)
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
void CRunBox2DSpring::SetYPosition(LPHO pHo, int y)
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
void CRunBox2DSpring::Stop(LPHO pHo, BOOL bCurrent)
{
	m_flags&=~SPFLAG_ACTIVE;
}

// Bounces the object
// ------------------
void CRunBox2DSpring::Bounce(LPHO pHo, BOOL bCurrent)
{
}

// Go in reverse
// -------------
void CRunBox2DSpring::Reverse(LPHO pHo)
{
}

// Restart the movement
// --------------------
void CRunBox2DSpring::Start(LPHO pHo)
{
	m_flags|=SPFLAG_ACTIVE;
}

// Changes the speed
// -----------------
void CRunBox2DSpring::SetSpeed(LPHO pHo, int speed)
{
	m_strength=(float)(((float)speed)/100.0*30.0f);
}

// Changes the maximum speed
// -------------------------
void CRunBox2DSpring::SetMaxSpeed(LPHO pHo, int speed)
{
}

// Changes the direction
// ---------------------
void CRunBox2DSpring::SetDir(LPHO pHo, int dir)
{
	m_mBase->m_currentAngle=(float)((float)dir)*11.25f;
	m_base->pBodySetAngle(m_base, m_mBase->m_body, m_mBase->m_currentAngle);
	if ((m_flags & SPFLAG_ROTATE) == 0)
		pHo->roc->rcDir = dir;
}
int CRunBox2DSpring::GetDir(LPHO pHo)
{
	if (m_flags&SPFLAG_ROTATE)
		return (int)(m_mBase->m_currentAngle/11.25f);
	else
		return pHo->roc->rcDir;
}
void CRunBox2DSpring::SetAngle(float angle)
{
	m_mBase->m_currentAngle = angle;
	m_base->pBodySetAngle(m_base, m_mBase->m_body, angle);
	if ((m_flags & SPFLAG_ROTATE) == 0)
		m_pHo->roc->rcDir = (int)(angle / 11.25);
}
float CRunBox2DSpring::GetAngle()
{
	if (m_flags&SPFLAG_ROTATE)
	{
		return m_mBase->m_currentAngle;
	}
	return ANGLE_MAGIC;
}


// Changes the acceleration
// ------------------------
void CRunBox2DSpring::SetAcc(LPHO pHo, int acc)
{
}

// Changes the deceleration
// ------------------------
void CRunBox2DSpring::SetDec(LPHO pHo, int dec)
{
}

// Changes the rotation speed
// --------------------------
void CRunBox2DSpring::SetRotSpeed(LPHO pHo, int speed)
{
}

// Changes the authorised directions out of 8
// ------------------------------------------
void CRunBox2DSpring::Set8Dirs(LPHO pHo, int dirs)
{
}

// Changes the gravity
// -------------------
void CRunBox2DSpring::SetGravity(LPHO pHo, int gravity)
{
}

// Returns the speed
// -----------------
int CRunBox2DSpring::GetSpeed(LPHO pHo)
{
	return (DWORD)(m_strength*100.0/30.0f);
}

// Returns the acceleration
// ------------------------
int CRunBox2DSpring::GetAcceleration(LPHO pHo)
{
	return 0;
}

// Returns the deceleration
// ------------------------
int CRunBox2DSpring::GetDeceleration(LPHO pHo)
{
	return 0;
}

// Returns the gravity
// -------------------
int CRunBox2DSpring::GetGravity(LPHO pHo)
{
	return 0;
}


// Extension Actions entry
// -----------------------
double CRunBox2DSpring::ActionEntry(LPHO pHo, int action, double param1, double param2)
{
	return 0;
}


/////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunMvtbox2dspring

-(void)initialize:(CFile*)file
{
    m_object = new CRunBox2DSpring();
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