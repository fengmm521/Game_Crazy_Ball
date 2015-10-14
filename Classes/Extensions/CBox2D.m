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
//  CBox2D.h
//  RuntimeIPhone
//
//  Created by Francois Lionet on 14/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//
#import "CBox2D.h"
#import "CFile.h"
#import "CCreateObjectInfo.h"
#import "CCndExtension.h"
#import "CActExtension.h"
#import "CObject.h"
#import "CRun.h"

// CRunMBase class
// ----------------------------------------------------------
CRunMBase::CRunMBase(LPRDATABASE base, CObject* pHo, WORD type)
{
    m_addVX=0;
    m_addVY=0;
    m_addVFlag=FALSE;
    m_setVX=0;
    m_setVY=0;
    m_setVFlag=FALSE;
    m_base = base;
    m_pHo=pHo;
    m_type=type;
    m_stopFlag=FALSE;
    m_currentAngle=0;
    m_platform = NO;
    m_background = NO;
    m_subType = MSUBTYPE_OBJECT;
}
void CRunMBase::PrepareCondition()
{
    m_stopFlag=NO;
    m_eventCount=m_pHo->hoAdRunHeader->rh4EventCount;
}
BOOL CRunMBase::IsStop()
{
    return m_stopFlag;
}
void CRunMBase::SetStopFlag(BOOL flag)
{
    m_stopFlag=flag;
}
void CRunMBase::AddVelocity(float vx, float vy)
{
    m_addVX=vx;
    m_addVY=vy;
    m_addVFlag=TRUE;
}
void CRunMBase::SetVelocity(float vx, float vy)
{
    if (!m_platform)
    {
        float angle=m_body->GetAngle();
        b2Vec2 position=m_body->GetPosition();
        position.x+=vx/2.56f;
        position.y+=vy/2.56f;
        m_base->pBodySetTransform(m_base, m_body, position, angle);
    }
    else
    {
        m_setVX+=vx*22.5f;
        m_setVY+=vy*22.5f;
        m_setVFlag=TRUE;
    }
}
void CRunMBase::ResetAddVelocity()
{
    if (m_addVFlag)
    {
        m_addVFlag=FALSE;
        m_addVX=0;
        m_addVY=0;
    }
    if (m_setVFlag)
    {
        m_setVFlag=FALSE;
        m_setVX=0;
        m_setVY=0;
    }
}

// CRunBox2DParent : parent class of all mixed Obective-C / C++ objects
//////////////////////////////////////////////////////////////////////////
@implementation CRunBox2DParent

-(int)getNumberOfConditions
{
	return 0;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    return NO;
}
-(void)destroyRunObject:(BOOL)bFast
{
}
-(int)handleRunObject
{
	return 0;
}
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	return NO;
}
-(void)action:(int)num withActExtension:(CActExtension*)act
{
}
-(CValue*)expression:(int)num
{
	return nil;
}

@end

// CRunMvtBox2D parent class of mixed objective-c / c++ movements
/////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunMvtBox2D

-(void)initialize:(CFile*)file
{
}
-(void)kill
{
}
-(BOOL)move
{
	return NO;
}
-(void)setPosition:(int)x withY:(int)y
{
}
-(void)setXPosition:(int)x
{
}
-(void)setYPosition:(int)y
{
}
-(void)stop:(BOOL)bCurrent
{
}
-(void)bounce:(BOOL)bCurrent
{
}
-(void)start
{
}
-(void)setSpeed:(int)speed
{
}
-(void)setMaxSpeed:(int)speed
{
}
-(void)setDir:(int)dir
{
}
-(void)setAcc:(int)acc
{
}
-(void)setDec:(int)dec
{
}
-(void)setRotSpeed:(int)speed
{
}
-(void)setGravity:(int)gravity
{
}
-(double)actionEntry:(int)action
{
	return 0;
}
-(int)getSpeed
{
	return 0;
}
-(int)getAcceleration
{
	return 0;
}
-(int)getDeceleration
{
	return 0;
}
-(int)getGravity
{
	return 0;
}
-(int)getDir
{
    return 0;
}
@end