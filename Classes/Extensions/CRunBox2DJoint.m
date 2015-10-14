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
//  CRunBox2DJoint.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 26/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunBox2DJoint.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CServices.h"
#import "CRunFrame.h"
#import "CActExtension.h"
#import "CExtension.h"
#import "CSprite.h"
#import "CSpriteGen.h"

#define ACT_SETLIMITS			0
#define ACT_SETMOTOR			1
#define ACT_DESTROY				2
#define EXP_ANGLE1              0
#define EXP_ANGLE2              1
#define EXP_TORQUE              2
#define EXP_SPEED               3
#define PINFLAG_LINK 0x0001

void RACT_DESTROY(LPRDATA rdPtr);
void RACT_SETMOTOR(LPRDATA rdPtr, int param1, int param2);
void RACT_SETLIMITS(LPRDATA rdPtr, int param1, int param2);
void VerifyJoints(LPRDATA rdPtr);
CObject* GetHO(LPRDATA rdPtr, int fixedValue);
short jHandleRunObject(LPRDATA rdPtr);
void GetTopMostObjects(LPRDATA rdPtr, CCArrayList& list, int x, int y, int w, int h);
short jDestroyRunObject(LPRDATA rdPtr, int fast);
void jCreateRunObject(LPRDATA rdPtr, CFile* file, CCreateObjectInfo* cob);
BOOL rStartObject(void* ptr);
LPRDATABASE jGetBase(LPRDATA rdPtr);
int REXP_ANGLE1(LPRDATA rdPtr);
int REXP_ANGLE2(LPRDATA rdPtr);
int REXP_TORQUE(LPRDATA rdPtr);
int REXP_SPEED(LPRDATA rdPtr);


LPRDATABASE jGetBase(LPRDATA rdPtr)
{
    int pOL = 0;
    int nObjects;
	for (nObjects=0; nObjects<rdPtr->rh->rhNObjects; pOL++, nObjects++)
	{
		while(rdPtr->rh->rhObjectList[pOL]==nil) pOL++;
		CObject* pBase=rdPtr->rh->rhObjectList[pOL];
		if (pBase->hoType>=32)
		{
			if (pBase->hoCommon->ocIdentifier==BASEIDENTIFIER)
			{
                CExtension* pExtension = (CExtension*)pBase;
				LPRDATABASE pEngine=(LPRDATABASE)((CRunBox2DParent*)pExtension->ext)->m_object;
				if (pEngine->identifier==rdPtr->identifier)
				{
					return pEngine;
				}
			}
		}
	}
	return nil;
}

BOOL rStartObject(void* ptr)
{
	LPRDATA rdPtr=(LPRDATA)ptr;
	if (rdPtr->base==nil)
	{
		rdPtr->base=jGetBase(rdPtr);
		if (rdPtr->base==nil)
		{
			return NO;
		}
	}
	return rdPtr->base->started;
}

void jCreateRunObject(LPRDATA rdPtr, CFile* file, CCreateObjectInfo* cob)
{
    rdPtr->ho->hoX = cob->cobX;
    rdPtr->ho->hoY = cob->cobY;
    if (cob->cobFlags & COF_CREATEDATSTART)
    {
        rdPtr->ho->hoX += 16;
        rdPtr->ho->hoY += 16;
    }
    rdPtr->flags = [file readAInt];
    rdPtr->number = [file readAShort];
    rdPtr->angle1 = (int)[file readAInt];
    rdPtr->angle2 = (int)[file readAInt];
    rdPtr->torque = [file readAInt];
    rdPtr->speed = [file readAInt];
    rdPtr->identifier = [file readAInt];
    rdPtr->joints = new CCArrayList();
    rdPtr->base = nil;
}

short jDestroyRunObject(LPRDATA rdPtr, int fast)
{
	if (rdPtr->bodyStatic != nil)
	{
		LPRDATABASE pBase = jGetBase(rdPtr);
		if (pBase != NULL)
			rdPtr->base->pDestroyBody(rdPtr->base, rdPtr->bodyStatic);
	}
	int n;
	for (n = 0; n < rdPtr->joints->Size(); n++)
	{
		CJointO* pJointO = (CJointO*)rdPtr->joints->Get(n);
		delete pJointO;
	}
    delete rdPtr->joints;
	return 0;
}

void GetTopMostObjects(LPRDATA rdPtr, CCArrayList& list, int x, int y, int w, int h)
{
	CSprite* pSpr = nil;
	LPRH rhPtr = rdPtr->rh;
    
	// Checks for sprites
	do
	{
		// Get the next sprite at x,y
		pSpr = [rhPtr->spriteGen spriteCol_TestRect:pSpr withLayer:-1 andX:x-rhPtr->rhWindowX andY:y-rhPtr->rhWindowY andWidth:w andHeight:h andFlags:SCF_EVENNOCOL];
        
		if ( pSpr == nil )
			break;
        
		// Object not being destroyed?
		if ( (pSpr->sprFlags & SF_TOKILL) == 0 )
		{
			// Get object pointer
			LPHO pHo = (LPHO)pSpr->sprExtraInfo;
            
			// Active object ?
			if ( pHo != nil )
			{
				CRunMBase* pMBase = (CRunMBase*)rdPtr->base->pGetMBase(rdPtr->base, pHo);
				if (pMBase != nil && pMBase->m_identifier == rdPtr->identifier)
					list.Add(pMBase);
			}
		}
	} while (pSpr != nil);
}

short jHandleRunObject(LPRDATA rdPtr)
{
	if (!rStartObject(rdPtr))
		return 0;
    
	CCArrayList list;
	int x = rdPtr->ho->hoX;
	int y = rdPtr->ho->hoY;
	GetTopMostObjects(rdPtr, list, rdPtr->ho->hoX, rdPtr->ho->hoY, 32, 32);
	if (list.Size() > 0)
	{
		if ((rdPtr->flags & PINFLAG_LINK) != 0 || list.Size() == 1)
		{
			rdPtr->bodyStatic = rdPtr->base->pCreateBody(rdPtr->base, b2_staticBody, x, y, 0, 0, NULL, 0, 0);
			rdPtr->base->pBodyCreateBoxFixture(rdPtr->base, rdPtr->bodyStatic, NULL, x, y, 16, 16, 0, 0, 0);
		}
		b2RevoluteJointDef jointDef;
		jointDef.collideConnected=TRUE;
		b2Vec2 position((float)x, (float)y);
		rdPtr->base->pFrameToWorld(rdPtr->base, &position);
		b2RevoluteJoint* joint;
		if (list.Size() == 1)
		{
			CRunMBase* pMBase = (CRunMBase*)list.Get(0);
			joint = (b2RevoluteJoint*)rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &jointDef, rdPtr->bodyStatic, pMBase->m_body, position);
            rdPtr->base->pRJointSetLimits(rdPtr->base, joint, rdPtr->angle1, rdPtr->angle2);
            rdPtr->base->pRJointSetMotor(rdPtr->base, joint, rdPtr->torque, rdPtr->speed);
			rdPtr->joints->Add(new CJointO(NULL, pMBase, joint));
		}
		if (list.Size() >= 2)
		{
			int numbers = 1;
			if (rdPtr->number == 1)
				numbers = 10000;
			int n;
			CRunMBase* pMBase1;
			CRunMBase* pMBase2;
			for (n = 0; n < numbers; n++)
			{
				int index = list.Size() - 1 - n;
				pMBase1 = (CRunMBase*)list.Get(index);
				pMBase2 = (CRunMBase*)list.Get(index - 1);
				joint = (b2RevoluteJoint*)rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &jointDef, pMBase1->m_body, pMBase2->m_body, position);
                rdPtr->base->pRJointSetLimits(rdPtr->base, joint, rdPtr->angle1, rdPtr->angle2);
                rdPtr->base->pRJointSetMotor(rdPtr->base, joint, rdPtr->torque, rdPtr->speed);
				rdPtr->joints->Add(new CJointO(pMBase1, pMBase2, joint));
				if (index == 1)
					break;
			}
			if ((rdPtr->flags & PINFLAG_LINK) != 0)
			{
				joint = (b2RevoluteJoint*)rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &jointDef, rdPtr->bodyStatic, pMBase2->m_body, position);
				rdPtr->joints->Add(new CJointO(NULL, pMBase2, joint));
			}
		}
	}
	return REFLAG_ONESHOT;
}

CObject* GetHO(LPRDATA rdPtr, int fixedValue)
{
	CObject* hoPtr=rdPtr->rh->rhObjectList[fixedValue&0xFFFF];
	if (hoPtr!=nil && hoPtr->hoCreationId==fixedValue>>16)
	{
		return hoPtr;
	}
	return nil;
}

void VerifyJoints(LPRDATA rdPtr)
{
	int n;
	for (n = 0; n < rdPtr->joints->Size(); n++)
	{
		CJointO* pJointO = (CJointO*)rdPtr->joints->Get(n);
		LPHO pHo;
		BOOL bFlag = YES;
		if (pJointO->m_fv1 != -1)
		{
			pHo = GetHO(rdPtr, pJointO->m_fv1);
			if (pHo == nil)
				bFlag = NO;
		}
		if (pJointO->m_fv2 != -1)
		{
			pHo = GetHO(rdPtr, pJointO->m_fv2);
			if (pHo == nil)
				bFlag = NO;
		}
		if (!bFlag)
		{
			rdPtr->joints->RemoveIndex(n);
			n--;
		}
	}
}

void RACT_SETLIMITS(LPRDATA rdPtr, int param1, int param2)
{
	VerifyJoints(rdPtr);

    rdPtr->angle1 = param1;
    rdPtr->angle2 = param2;
	int n;
	for (n = 0; n < rdPtr->joints->Size(); n++)
	{
		CJointO* pJointO = (CJointO*)rdPtr->joints->Get(n);
		rdPtr->base->pRJointSetLimits(rdPtr->base, pJointO->m_joint, param1, param2);
	}
}

void RACT_SETMOTOR(LPRDATA rdPtr, int param1, int param2)
{
	VerifyJoints(rdPtr);
    
    rdPtr->torque = param1;
    rdPtr->speed = param2;
	int n;
	for (n = 0; n < rdPtr->joints->Size(); n++)
	{
		CJointO* pJointO = (CJointO*)rdPtr->joints->Get(n);
		rdPtr->base->pRJointSetMotor(rdPtr->base, pJointO->m_joint, param1, param2);
	}
}

void RACT_DESTROY(LPRDATA rdPtr)
{
	VerifyJoints(rdPtr);
    
	int n;
	for (n = 0; n < rdPtr->joints->Size(); n++)
	{
		CJointO* pJointO = (CJointO*)rdPtr->joints->Get(n);
		rdPtr->base->pDestroyJoint(rdPtr->base, pJointO->m_joint);
		rdPtr->joints->RemoveIndex(n);
		n--;
	}
}

int REXP_ANGLE1(LPRDATA rdPtr)
{
    return rdPtr->angle1;
}
int REXP_ANGLE2(LPRDATA rdPtr)
{
    return rdPtr->angle2;
}
int REXP_TORQUE(LPRDATA rdPtr)
{
    return rdPtr->torque;
}
int REXP_SPEED(LPRDATA rdPtr)
{
    return rdPtr->speed;
}
CJointO::CJointO(CRunMBase* pBase1, CRunMBase* pBase2, b2RevoluteJoint* joint)
{
	LPHO pHo;
	m_fv1 = -1;
	if (pBase1 != NULL)
	{
		pHo = pBase1->m_pHo;
		m_fv1 = (pHo->hoCreationId<<16)|(pHo->hoNumber&0xFFFF);
	}
	m_fv2 = -1;
	if (pBase2 != NULL)
	{
		pHo = pBase2->m_pHo;
		m_fv2 = (pHo->hoCreationId<<16)|(pHo->hoNumber&0xFFFF);
	}
	m_joint = joint;    
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DJoint

-(int)getNumberOfConditions
{
	return 0;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATA));
    
    LPRDATA rdPtr = (LPRDATA)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    jCreateRunObject(rdPtr, file, cob);
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    jDestroyRunObject((LPRDATA)m_object, bFast);
    free(m_object);
}

-(int)handleRunObject
{
	return jHandleRunObject((LPRDATA)m_object);
}


// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATA rdPtr = (LPRDATA)m_object;
    switch (num)
    {
        case ACT_SETLIMITS:
            RACT_SETLIMITS(rdPtr, [act getParamExpression:rh withNum:0], [act getParamExpression:rh withNum:1]);
            break;
        case ACT_SETMOTOR:
            RACT_SETMOTOR(rdPtr, [act getParamExpression:rh withNum:0], [act getParamExpression:rh withNum:1]);
            break;
        case ACT_DESTROY:
            RACT_DESTROY(rdPtr);
            break;
    }
}
-(CValue*)expression:(int)num;
{
    LPRDATA rdPtr = (LPRDATA)m_object;
    int ret = 0;
    switch(num)
    {
        case EXP_ANGLE1:
            ret = REXP_ANGLE1(rdPtr);
            break;
        case EXP_ANGLE2:
            ret = REXP_ANGLE2(rdPtr);
            break;
        case EXP_TORQUE:
            ret = REXP_TORQUE(rdPtr);
            break;
        case EXP_SPEED:
            ret = REXP_SPEED(rdPtr);
            break;
    }
	return [rdPtr->rh getTempValue:ret];
}


@end