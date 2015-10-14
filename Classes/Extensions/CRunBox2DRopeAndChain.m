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
//  CRunBox2DRopeAndChain.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunBox2DRopeAndChain.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CRMvt.h"
#import "CMove.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CRunApp.h"
#import "CServices.h"
#import "CRunFrame.h"
#import "CActExtension.h"
#import "CSpriteGen.h"
#import "CImageBank.h"
#import "CImage.h"
#import "CRSpr.h"
#import "CSprite.h"
#import "CEventProgram.h"
#import "CExtension.h"
#import "CQualToOiList.h"

enum
{
	CND_ONEACHRC,
	CND_ELEMENTCOLLISIONRC,
	CND_ELEMENTOUTLEFTRC,
	CND_ELEMENTOUTRIGHTRC,
	CND_ELEMENTOUTTOPRC,
	CND_ELEMENTOUTBOTTOMRC,
	CND_NONE,
	CND_ELEMENTCOLLISIONBACKDROPRC,
	CND_LAST_RC
};

// ---------------------------
// DEFINITION OF ACTIONS CODES
// ---------------------------
enum
{
	ACT_FOREACHRC,
	ACT_STOPRC,
	ACT_CLIMBUPRC,
	ACT_CLIMBDOWNRC,
	ACT_ATTACHRC,
	ACT_RELEASERC,
	ACT_STOPLOOPRC,
	ACT_CUTRC,
	ACT_ATTACHNUMBERRC,
	ACT_LAST_RC
};

// -------------------------------
// DEFINITION OF EXPRESSIONS CODES
// ------------------------------
enum
{
	EXP_LOOPINDEXRC,
	EXP_GETX1RC,
	EXP_GETY1RC,
	EXP_GETX2RC,
	EXP_GETY2RC,
	EXP_GETXMIDDLERC,
	EXP_GETYMIDDLERC,
	EXP_GETANGLERC,
	EXP_GETELEMENTRC,
	EXP_LAST_RC
};

int REXP_GETELEMENT(LPRDATARC rdPtr);
int REXP_GETANGLE(LPRDATARC rdPtr);
int REXP_GETYMIDDLE(LPRDATARC rdPtr);
int REXP_GETXMIDDLE(LPRDATARC rdPtr);
int REXP_GETY2(LPRDATARC rdPtr);
int REXP_GETX2(LPRDATARC rdPtr);
int getY2(LPRDATARC rdPtr, CElement* element);
int getX2(LPRDATARC rdPtr, CElement* element);
int REXP_GETY1(LPRDATARC rdPtr);
int REXP_GETX1(LPRDATARC rdPtr);
int REXP_LOOPINDEX(LPRDATARC rdPtr);
CElement* getElement(LPRDATARC rdPtr, int index);
void RACT_CUT(LPRDATARC rdPtr, int param1);
void RACT_STOPLOOP(LPRDATARC rdPtr);
void RACT_RELEASE(LPRDATARC rdPtr, LPHO pHo);
void RACT_ATTACHNUMBER(LPRDATARC rdPtr, LPHO pHo, int number);
void RACT_ATTACH(LPRDATARC rdPtr, LPHO pHo, int param2);
void RACT_CLIMBDOWN(LPRDATARC rdPtr, LPHO pHo);
void RACT_CLIMBUP(LPRDATARC rdPtr, LPHO pHo);
void RACT_STOP(LPRDATARC rdPtr);
void RACT_FOREACH(LPRDATARC rdPtr, NSString* pName);
BOOL RCND_ELEMENTCOLLISION(LPRDATARC rdPtr, CCndExtension* cnd);
BOOL RCND_ONEACH(LPRDATARC rdPtr, NSString* pName);
short rHandleRunObject(LPRDATARC rdPtr);
short rDestroyRunObject(LPRDATARC rdPtr, int fast);
short rCreateRunObject(LPRDATARC rdPtr, CFile* file);
BOOL rcrStartObject(void* ptr);
LPRDATABASE GetBase(LPRDATARC rdPtr);

LPRDATABASE GetBase(LPRDATARC rdPtr)
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
BOOL rcrStartObject(void* ptr)
{
	LPRDATARC rdPtr=(LPRDATARC)ptr;
	if (rdPtr->base==nil)
	{
		rdPtr->base=GetBase(rdPtr);
		if (rdPtr->base==nil)
		{
			return NO;
		}
	}
	return rdPtr->base->started;
}
short rCreateRunObject(LPRDATARC rdPtr, CFile* file)
{
    rdPtr->base = nil;
    rdPtr->ho->hoImgWidth = [file readAInt];
    rdPtr->ho->hoImgHeight = [file readAInt];
    rdPtr->flags = [file readAInt];
    rdPtr->angle = (float)([file readAInt] * 11.25);
    rdPtr->number = [file readAInt];
    rdPtr->friction = [file readAInt] / 100.0f;
    rdPtr->restitution = [file readAInt] / 100.0f;
    rdPtr->density = [file readAInt] / 100.0f;
    rdPtr->gravity = [file readAInt] / 100.0f;
    rdPtr->identifier = [file readAInt];
    rdPtr->nImages = [file readAShort];
    rdPtr->imageStart[0] = [file readAShort];
    [rdPtr->ho loadImageList:rdPtr->imageStart withLength:1];
    int n;
    for (n = 0; n < rdPtr->nImages; n++)
        rdPtr->images[n] = [file readAShort];
    [file skipBytes:(MAX_IMAGESRC - n) * 2];
    [rdPtr->ho loadImageList:rdPtr->images withLength:rdPtr->nImages];
    rdPtr->imageEnd[0] = [file readAShort];
    [rdPtr->ho loadImageList:rdPtr->imageEnd withLength:1];
    
	rdPtr->pStartObject = rcrStartObject;
    
    rdPtr->oldX = rdPtr->ho->hoX;
    rdPtr->oldY = rdPtr->ho->hoY;
	rdPtr->currentObject = nil;
	rdPtr->loopName = [[NSString alloc] initWithString:@""];
	rdPtr->effect = rdPtr->ho->ros->rsEffect;
	rdPtr->effectParam = rdPtr->ho->ros->rsEffectParam;
	rdPtr->visible = (rdPtr->ho->ros->rsFlags&RSFLAG_VISIBLE)!=0;
    rdPtr->elements = new CCArrayList();
    rdPtr->joints = new CCArrayList();
    rdPtr->ropeJoints = new CCArrayList();
    
	return 0;
}

// ----------------
// DestroyRunObject
// ----------------
// Destroys the run-time object
//
short rDestroyRunObject(LPRDATARC rdPtr, int fast)
{
	[rdPtr->loopName release];
	LPRDATABASE pBase = GetBase(rdPtr);
    int n;
    for (n = 0; n < rdPtr->elements->Size(); n++)
    {
        CElement* element = (CElement*)rdPtr->elements->Get(n);
        element->kill(pBase);
        delete element;
    }
	if (pBase != nil)
	{
		pBase->pDestroyBody(pBase, rdPtr->bodyStart);
		if (rdPtr->bodyEnd != nil)
			pBase->pDestroyBody(pBase, rdPtr->bodyEnd);
	}
    delete rdPtr->elements;
    delete rdPtr->joints;
    delete rdPtr->ropeJoints;
	return 0;
}


// ----------------
// HandleRunObject
// ----------------
short rHandleRunObject(LPRDATARC rdPtr)
{
	if (!rcrStartObject(rdPtr))
		return 0;
    
    CElement* element;
	b2Joint* joint;
    if (rdPtr->elements->Size() == 0)
    {
        int x = rdPtr->ho->hoX;
        int y = rdPtr->ho->hoY;
        
        rdPtr->bodyStart = rdPtr->base->pCreateBody(rdPtr->base, b2_staticBody, x, y, 0, 0, nil, 0, 0);
        rdPtr->base->pBodyCreateBoxFixture(rdPtr->base, rdPtr->bodyStart, nil, x, y, 16, 16, 0, 0, 0);
        b2Body* previousBody = rdPtr->bodyStart;
        
        float angle = - (float)(rdPtr->angle / 180.0f * b2_pi);
        
        element = new CElement(rdPtr, rdPtr->imageStart[0], 0, x, y, rdPtr->visible);
		CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:rdPtr->imageStart[0]];
        element->m_mBase->m_body = rdPtr->base->pCreateBody(rdPtr->base, b2_dynamicBody, x, y, rdPtr->angle, rdPtr->gravity, (void*)element->m_mBase, CBFLAG_DAMPING, rdPtr->damping);
        rdPtr->base->pBodyCreateBoxFixture(rdPtr->base, element->m_mBase->m_body, element->m_mBase, x, y, pImage->width, pImage->height, rdPtr->density, rdPtr->friction, rdPtr->restitution);
        
        b2RevoluteJointDef JointDef;
        JointDef.collideConnected = NO;
        JointDef.enableMotor = NO;
        
        joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, element->m_mBase->m_body, previousBody, element->m_mBase->m_body->GetPosition());
        rdPtr->ropeJoints->Add(joint);
		previousBody = element->m_mBase->m_body;
        
        int deltaX = pImage->xAP - pImage->xSpot;
        int deltaY = pImage->yAP - pImage->ySpot;
        int plusX = (int)(deltaX * cos(angle) - deltaY * sin(angle));
        int plusY = (int)(deltaX * sin(angle) + deltaY * cos(angle));
        x += plusX;
        y += plusY;
        
        rdPtr->elements->Add(element);
        
        int n;
        int nImage = 0;
        for (n=1; n<rdPtr->number - 1; n++)
        {
            element = new CElement(rdPtr, rdPtr->images[nImage], n, x, y, rdPtr->visible);
            pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:rdPtr->images[nImage]];
			element->m_mBase->m_body = rdPtr->base->pCreateBody(rdPtr->base, b2_dynamicBody, x, y, rdPtr->angle, rdPtr->gravity, (void*)element->m_mBase, CBFLAG_DAMPING, rdPtr->damping);
	        rdPtr->base->pBodyCreateBoxFixture(rdPtr->base, element->m_mBase->m_body, element->m_mBase, x, y, pImage->width, pImage->height, rdPtr->density, rdPtr->friction, rdPtr->restitution);
            
	        joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, element->m_mBase->m_body, previousBody, element->m_mBase->m_body->GetPosition());
	        rdPtr->ropeJoints->Add(joint);
			previousBody = element->m_mBase->m_body;
            
			deltaX = pImage->xAP - pImage->xSpot;
			deltaY = pImage->yAP - pImage->ySpot;
			plusX = (int)(deltaX * cos(angle) - deltaY * sin(angle));
			plusY = (int)(deltaX * sin(angle) + deltaY * cos(angle));
			x += plusX;
			y += plusY;
            
            nImage++;
            if (nImage >= rdPtr->nImages)
                nImage = 0;
            rdPtr->elements->Add(element);
        }
        element = new CElement(rdPtr, rdPtr->imageEnd[0], n, x, y, rdPtr->visible);
        pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:rdPtr->imageEnd[0]];
		element->m_mBase->m_body = rdPtr->base->pCreateBody(rdPtr->base, b2_dynamicBody, x, y, rdPtr->angle, rdPtr->gravity, (void*)element->m_mBase, CBFLAG_DAMPING, rdPtr->damping);
	    rdPtr->base->pBodyCreateBoxFixture(rdPtr->base, element->m_mBase->m_body, element->m_mBase, x, y, pImage->width, pImage->height, rdPtr->density, rdPtr->friction, rdPtr->restitution);
        
        joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, element->m_mBase->m_body, previousBody, element->m_mBase->m_body->GetPosition());
        rdPtr->ropeJoints->Add(joint);
		previousBody = element->m_mBase->m_body;
        rdPtr->elements->Add(element);
		
		rdPtr->bodyEnd = nil;
        if (rdPtr->flags & RCFLAG_ATTACHED)
        {
            deltaX = pImage->xAP - pImage->xSpot;
            deltaY = pImage->yAP - pImage->ySpot;
            plusX = (int)(deltaX * cos(angle) - deltaY * sin(angle));
            plusY = (int)(deltaX * sin(angle) + deltaY * cos(angle));
            x += plusX;
            y += plusY;
            
            rdPtr->bodyEnd = rdPtr->base->pCreateBody(rdPtr->base, b2_staticBody, x, y, 0, 0, nil, 0, 0);
            rdPtr->base->pBodyCreateBoxFixture(rdPtr->base, rdPtr->bodyEnd, nil, x, y, 16, 16, 0, 0, 0);
	        joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, rdPtr->bodyEnd, previousBody, rdPtr->bodyEnd->GetPosition());
	        rdPtr->ropeJoints->Add(joint);
        }
		rdPtr->lastElement = rdPtr->elements->Size() - 1;
    }
    
    if (rdPtr->ho->hoX != rdPtr->oldX || rdPtr->ho->hoY != rdPtr->oldY)
    {
        float deltaX = (float)(((float)rdPtr->ho->hoX - (float)rdPtr->oldX) / rdPtr->base->factor);
        float deltaY = -(float)(((float)rdPtr->ho->hoY - (float)rdPtr->oldY) / rdPtr->base->factor);
        rdPtr->oldX = rdPtr->ho->hoX;
        rdPtr->oldY = rdPtr->ho->hoY;
        
        b2Vec2 pos = rdPtr->bodyStart->GetPosition();
        float angle = rdPtr->bodyStart->GetAngle();
        pos.x += deltaX;
        pos.y += deltaY;
        rdPtr->base->pBodySetTransform(rdPtr->base, rdPtr->bodyStart, pos, angle);
        
        int n;
        for (n = 0; n < rdPtr->elements->Size() ; n++)
        {
            CElement* element = (CElement*)rdPtr->elements->Get(n);
            pos = element->m_mBase->m_body->GetPosition();
            float angle = element->m_mBase->m_body->GetAngle();
            pos.x += deltaX;
            pos.y += deltaY;
            rdPtr->base->pBodySetTransform(rdPtr->base, element->m_mBase->m_body, pos, angle);
        }
        
        if (rdPtr->bodyEnd)
        {
            pos = rdPtr->bodyEnd->GetPosition();
            angle = rdPtr->bodyEnd->GetAngle();
            pos.x += deltaX;
            pos.y += deltaY;
            rdPtr->base->pBodySetTransform(rdPtr->base, rdPtr->bodyEnd, pos, angle);
        }
    }
    
	if (rdPtr->lastElement > 0 && rdPtr->bodyEnd == nil)
	{
		CElement* element1 = (CElement*)rdPtr->elements->Get(rdPtr->lastElement);
		b2Vec2 position = rdPtr->base->pBodyGetPosition(rdPtr->base, element1->m_mBase->m_body);
		element = (CElement*)rdPtr->elements->Get(rdPtr->lastElement - 1);
		float angle = rdPtr->base->pBodyGetAngle(rdPtr->base, element->m_mBase->m_body);
		rdPtr->base->pBodySetTransform(rdPtr->base, element1->m_mBase->m_body, position, angle);
	}
    
	int n;
    for (n = 0; n < rdPtr->elements->Size() ; n++)
    {
        element = (CElement*)rdPtr->elements->Get(n);
        element->setPosition();
    }
    
    for (n = 0; n < rdPtr->joints->Size() ; n++)
    {
        CJointRC* cjoint = (CJointRC*)rdPtr->joints->Get(n);
        if (cjoint->counter > 0)
        {
            cjoint->counter--;
            if (cjoint->counter == 0)
            {
                rdPtr->joints->RemoveIndex(n);
                n--;
            }
        }
    }
    
	if (rdPtr->ho->ros->rsEffect != rdPtr->effect || rdPtr->ho->ros->rsEffectParam != rdPtr->effectParam)
	{
		rdPtr->effect = rdPtr->ho->ros->rsEffect;
		rdPtr->effectParam = rdPtr->ho->ros->rsEffectParam;
		for (n = 0; n < rdPtr->elements->Size() ; n++)
		{
			element = (CElement*)rdPtr->elements->Get(n);
			element->setEffect(rdPtr->effect, rdPtr->effectParam);
		}
	}
	BOOL visible = rdPtr->ho->ros->rsFlags&RSFLAG_VISIBLE;
	if (visible != rdPtr->visible)
	{
		rdPtr->visible = visible;
		for (n = 0; n < rdPtr->elements->Size() ; n++)
		{
			element = (CElement*)rdPtr->elements->Get(n);
			element->show(visible);
		}
	}
    
	return 0;
}



BOOL RCND_ONEACH(LPRDATARC rdPtr, NSString* pName)
{
	if ([pName caseInsensitiveCompare:rdPtr->loopName] == 0)
		return YES;
	return NO;
}
BOOL RCND_ELEMENTCOLLISION(LPRDATARC rdPtr, CCndExtension* cnd)
{
    LPEVP evpPtr = cnd->pParams[0];
	OINUM oi = evpPtr->evp.evpW.evpW1;
	if (oi == rdPtr->rh->rhEvtProg->rhCurParam[0])
	{
		[rdPtr->rh->rhEvtProg evt_AddCurrentObject:rdPtr->collidingHO];
		return YES;
	}
    else
    {
        short oil = evpPtr->evp.evpW.evpW0;
        if ((oil & 0x8000) != 0)
        {
            CQualToOiList* pq = (CQualToOiList*)((LPBYTE)rdPtr->rh->rhEvtProg->qualToOiList + (oil & 0x7FFF));
            int numOi = 0;
            while (numOi < pq->nQoi)
            {
                if (pq->qoiList[numOi] == rdPtr->rh->rhEvtProg->rhCurParam[0])
                {
                    [rdPtr->rh->rhEvtProg evt_AddCurrentObject:rdPtr->collidingHO];
                    return YES;
                }
                numOi += 2;
            };
        }
    }
	return NO;
}

void RACT_FOREACH(LPRDATARC rdPtr, NSString* pName)
{
    [rdPtr->loopName release];
    rdPtr->loopName = [[NSString alloc] initWithString:pName];
    
    int n;
    rdPtr->stopLoop = NO;
    for (n = 0; n < rdPtr->elements->Size() ; n++)
    {
        if (rdPtr->stopLoop)
            break;
        CElement* element = (CElement*)rdPtr->elements->Get(n);
        rdPtr->currentElement = element;
        rdPtr->loopIndex = n;
		[rdPtr->ho generateEvent:CND_ONEACHRC withParam:0];
    }
}
void RACT_STOP(LPRDATARC rdPtr)
{
	rdPtr->stopped = YES;
}
void RACT_CLIMBUP(LPRDATARC rdPtr, LPHO pHo)
{
    CRunMBase* object = (CRunMBase*)rdPtr->base->pGetMBase(rdPtr->base, pHo);
    if (object)
    {
        int n;
        for (n = 0; n < rdPtr->joints->Size() ; n++)
        {
            CJointRC* cjoint = (CJointRC*)rdPtr->joints->Get(n);
            if (cjoint->object == object && cjoint->joint != nil)
            {
                int n = cjoint->element->number;
                if (n > 0)
                {
                    rdPtr->base->pDestroyJoint(rdPtr->base, cjoint->joint);
                    
                    b2Vec2 pos1 = rdPtr->base->pBodyGetPosition(rdPtr->base, cjoint->element->m_mBase->m_body);
                    CElement* nextElement = (CElement*)rdPtr->elements->Get(n - 1);
                    b2Vec2 pos2 = rdPtr->base->pBodyGetPosition(rdPtr->base, nextElement->m_mBase->m_body);
                    float angle = rdPtr->base->pBodyGetAngle(rdPtr->base, cjoint->object->m_body);
                    b2Vec2 pos3 = rdPtr->base->pBodyGetPosition(rdPtr->base, cjoint->object->m_body);
                    pos3.x += pos2.x - pos1.x;
                    pos3.y += pos2.y - pos1.y;
                    rdPtr->base->pBodySetTransform(rdPtr->base, cjoint->object->m_body, pos3, angle);
                    
                    b2RevoluteJointDef JointDef;
                    JointDef.collideConnected = NO;
                    JointDef.enableMotor = YES;
                    JointDef.maxMotorTorque = 100000;
                    JointDef.motorSpeed = 0;
					b2Joint* joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, cjoint->object->m_body, nextElement->m_mBase->m_body, pos3);
                    cjoint->element = nextElement;
                    cjoint->joint = joint;
                }
                break;
            }
        }
    }
}
void RACT_CLIMBDOWN(LPRDATARC rdPtr, LPHO pHo)
{
    CRunMBase* object = (CRunMBase*)rdPtr->base->pGetMBase(rdPtr->base, pHo);
    if (object)
    {
        int n;
        for (n = 0; n < rdPtr->joints->Size() ; n++)
        {
            CJointRC* cjoint = (CJointRC*)rdPtr->joints->Get(n);
            if (cjoint->object == object && cjoint->joint != nil)
            {
                int n = cjoint->element->number;
                if (n < rdPtr->elements->Size() - 1)
                {
                    rdPtr->base->pDestroyJoint(rdPtr->base, cjoint->joint);
                    
                    b2Vec2 pos1 = rdPtr->base->pBodyGetPosition(rdPtr->base, cjoint->element->m_mBase->m_body);
                    CElement* nextElement = (CElement*)rdPtr->elements->Get(n + 1);
                    b2Vec2 pos2 = rdPtr->base->pBodyGetPosition(rdPtr->base, nextElement->m_mBase->m_body);
                    float angle = rdPtr->base->pBodyGetAngle(rdPtr->base, cjoint->object->m_body);
                    b2Vec2 pos3 = rdPtr->base->pBodyGetPosition(rdPtr->base, cjoint->object->m_body);
                    pos3.x += pos2.x - pos1.x;
                    pos3.y += pos2.y - pos1.y;
                    rdPtr->base->pBodySetTransform(rdPtr->base, cjoint->object->m_body, pos3, angle);
                    
                    b2RevoluteJointDef JointDef;
                    JointDef.collideConnected = NO;
                    JointDef.enableMotor = YES;
                    JointDef.maxMotorTorque = 100000;
                    JointDef.motorSpeed = 0;
					b2Joint* joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, cjoint->object->m_body, nextElement->m_mBase->m_body, pos3);
                    cjoint->element = nextElement;
                    cjoint->joint = joint;
                }
                break;
            }
        }
    }
}
void RACT_ATTACH(LPRDATARC rdPtr, LPHO pHo, int param2)
{
    if (rdPtr->currentElement == nil)
        return;
    CRunMBase* object = (CRunMBase*)rdPtr->base->pGetMBase(rdPtr->base, pHo);
    if (object)
    {
        int n;
        for (n = 0; n < rdPtr->joints->Size(); n++)
        {
            CJointRC* cjoint = (CJointRC*)rdPtr->joints->Get(n);
            if (cjoint->object == object)
                break;
        }
        if (n == rdPtr->joints->Size())
        {
			int distance = param2;
            b2RevoluteJointDef JointDef;
            JointDef.collideConnected = NO;
            JointDef.enableMotor = YES;
            JointDef.maxMotorTorque = 100000;
            JointDef.motorSpeed = 0;
			CElement* element = (CElement*)rdPtr->currentElement;
            b2Vec2 pos = rdPtr->base->pBodyGetPosition(rdPtr->base, element->m_mBase->m_body);
            b2Vec2 posObject = rdPtr->base->pBodyGetPosition(rdPtr->base, object->m_body);
            float angle = rdPtr->base->pBodyGetAngle(rdPtr->base, object->m_body);
			if (posObject.x > pos.x)
				posObject.x = pos.x + distance / rdPtr->base->factor;
			else
				posObject.x = pos.x - distance / rdPtr->base->factor;
            rdPtr->base->pBodySetTransform(rdPtr->base, object->m_body, posObject, angle);
			b2Joint* joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, object->m_body, element->m_mBase->m_body, pos);
            rdPtr->joints->Add(new CJointRC(object, element, joint));
        }
    }
}
void RACT_ATTACHNUMBER(LPRDATARC rdPtr, LPHO pHo, int number)
{
    CRunMBase* object = (CRunMBase*)rdPtr->base->pGetMBase(rdPtr->base, pHo);
    if (object)
    {
        int n;
        for (n = 0; n < rdPtr->joints->Size(); n++)
        {
            CJointRC* cjoint = (CJointRC*)rdPtr->joints->Get(n);
            if (cjoint->object == object)
                break;
        }
        if (n == rdPtr->joints->Size())
        {
            b2RevoluteJointDef JointDef;
            JointDef.collideConnected = NO;
            JointDef.enableMotor = YES;
            JointDef.maxMotorTorque = 100000;
            JointDef.motorSpeed = 0;
			if (number>=0 && number < rdPtr->elements->Size())
			{
				CElement* element = (CElement*)rdPtr->elements->Get(number);
                int xElement, yElement;
                float angle;
                rdPtr->base->pGetBodyPosition(rdPtr->base, element->m_mBase->m_body, &xElement, &yElement, &angle);
                CImage* image = [rdPtr->rh->rhApp->imageBank getImageFromHandle:pHo->roc->rcImage];
                xElement -= image->xAP - image->xSpot;
                yElement -= image->yAP - image->ySpot;
                rdPtr->base->pBodySetPosition(rdPtr->base, object->m_body, xElement, yElement);
				b2Vec2 pos = rdPtr->base->pBodyGetPosition(rdPtr->base, element->m_mBase->m_body);
				b2Joint* joint = rdPtr->base->pWorldCreateRevoluteJoint(rdPtr->base, &JointDef, object->m_body, element->m_mBase->m_body, pos);
				rdPtr->joints->Add(new CJointRC(object, element, joint));
			}
        }
    }
}
void RACT_RELEASE(LPRDATARC rdPtr, LPHO pHo)
{
    CRunMBase* object = (CRunMBase*)rdPtr->base->pGetMBase(rdPtr->base, pHo);
    if (object)
    {
        int n;
        for (n = 0; n < rdPtr->joints->Size() ; n++)
        {
            CJointRC* cjoint = (CJointRC*)rdPtr->joints->Get(n);
            if (cjoint->object == object && cjoint->joint != nil)
            {
                rdPtr->base->pDestroyJoint(rdPtr->base, cjoint->joint);
				cjoint->joint = nil;
                cjoint->counter = 200;
                break;
            }
        }
    }
}
void RACT_STOPLOOP(LPRDATARC rdPtr)
{
	rdPtr->stopLoop = YES;
}

void RACT_CUT(LPRDATARC rdPtr, int param1)
{
	if (param1 >= 0 && param1 < rdPtr->ropeJoints->Size())
	{
		b2Joint* joint = (b2Joint*)rdPtr->ropeJoints->Get(param1);
		rdPtr->base->pDestroyJoint(rdPtr->base, joint);
		rdPtr->ropeJoints->RemoveIndex(param1);
		rdPtr->lastElement = param1 -1;
	}
	rdPtr->stopLoop = YES;
}

CElement* getElement(LPRDATARC rdPtr, int index)
{
    if (index >= 0 && index < rdPtr->elements->Size())
        return (CElement*)rdPtr->elements->Get(index);
    return nil;
}

int REXP_LOOPINDEX(LPRDATARC rdPtr)
{
	return rdPtr->loopIndex;
}
int REXP_GETX1(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
        b2Vec2 o = rdPtr->base->pBodyGetPosition(rdPtr->base, element->m_mBase->m_body);
        return (int)o.x;
    }
	return 0;
}
int REXP_GETY1(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
        b2Vec2 o = rdPtr->base->pBodyGetPosition(rdPtr->base, element->m_mBase->m_body);
        return (int)o.y;
    }
	return 0;
}
int getX2(LPRDATARC rdPtr, CElement* element)
{
    b2Vec2 o = rdPtr->base->pBodyGetPosition(rdPtr->base, element->m_mBase->m_body);
	float angle = rdPtr->base->pBodyGetAngle(rdPtr->base, element->m_mBase->m_body);
    angle = -angle / 180 * b2_pi;
    CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:element->image];
	int deltaX = pImage->xAP - pImage->xSpot;
	int deltaY = pImage->yAP - pImage->ySpot;
	int plusX = (int)(deltaX * cos(angle) - deltaY * sin(angle));
	return (int)(o.x + plusX);
}
int getY2(LPRDATARC rdPtr, CElement* element)
{
    b2Vec2 o = rdPtr->base->pBodyGetPosition(rdPtr->base, element->m_mBase->m_body);
	float angle = rdPtr->base->pBodyGetAngle(rdPtr->base, element->m_mBase->m_body);
    angle = -angle / 180 * b2_pi;
    CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:element->image];
	int deltaX = pImage->xAP - pImage->xSpot;
	int deltaY = pImage->yAP - pImage->ySpot;
	int plusY = (int)(deltaX * sin(angle) + deltaY * cos(angle));
	return (int)(o.y + plusY);
}
int REXP_GETX2(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
		return getX2(rdPtr, element);
	}
	return 0;
}
int REXP_GETY2(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
		return getY2(rdPtr, element);
	}
	return 0;
}
int REXP_GETXMIDDLE(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
		int x1 = getX2(rdPtr, element);
		int x2, y2;
		float angle;
		rdPtr->base->pGetBodyPosition(rdPtr->base, element->m_mBase->m_body, &x2, &y2, &angle);
		return (int)((x1 + x2)/2);
	}
	return 0;
}
int REXP_GETYMIDDLE(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
		int y1 = getY2(rdPtr, element);
		int x2, y2;
		float angle;
		rdPtr->base->pGetBodyPosition(rdPtr->base, element->m_mBase->m_body, &x2, &y2, &angle);
		return (int)((y1 + y2)/2);
	}
	return 0;
}
int REXP_GETANGLE(LPRDATARC rdPtr)
{
 	int index = [[rdPtr->ho getExpParam] getInt];
	CElement* element = getElement(rdPtr, index);
    if (element)
    {
		int x2, y2;
		float angle;
		rdPtr->base->pGetBodyPosition(rdPtr->base, element->m_mBase->m_body, &x2, &y2, &angle);
		return (int)angle;
	}
	return 0;
}
int REXP_GETELEMENT(LPRDATARC rdPtr)
{
	if (rdPtr->currentElement != nil)
	{
		CElement* element = (CElement*)rdPtr->currentElement;
		return element->number;
	}
	return 0;
}



// JOINT OBJECT
////////////////////////////////////////////////////////////////////////
CJointRC::CJointRC(CRunMBase* o, CElement* e, b2Joint* j)
{
    element = e;
    joint = j;
    object = o;
    counter = 0;
}

// ELEMENT OBJECT
////////////////////////////////////////////////////////////////////////
CElement::CElement(LPRDATARC p, WORD i, int n, int xx, int yy, BOOL visible)
{ 
	parent = p;
	image = i;
	number = n;
	x = xx;
	y = yy;
	m_mBase = new CRunMBase(parent->base, parent->ho, MTYPE_ELEMENT);
	m_mBase->m_element = this;
	m_mBase->m_identifier = parent->identifier;
    
	CRSpr* rsPtr=parent->ho->ros;
	LPRH rhPtr = parent->ho->hoAdRunHeader;
	sprite = [rhPtr->spriteGen addSprite:x withY:y andImage:image andLayer:rsPtr->rsLayer andZOrder:rsPtr->rsZOrder andBackColor:rsPtr->rsBackColor andFlags:visible?0:SF_HIDDEN andObject:nil];
}
CElement::~CElement()
{
	delete m_mBase;
}
void CElement::kill(LPRDATABASE pBase)
{
	[parent->rh->spriteGen delSprite:sprite];
    if (pBase != nil)
        pBase->pDestroyBody(pBase, m_mBase->m_body);
}
void CElement::setPosition()
{
    parent->base->pBodyAddVelocity(parent->base, m_mBase->m_body, m_mBase->m_addVX, m_mBase->m_addVY);
	m_mBase->ResetAddVelocity();
    parent->base->pGetBodyPosition(parent->base, m_mBase->m_body, &x, &y, &angle);
    
    LPRH rhPtr = parent->rh;
	[rhPtr->spriteGen modifSpriteEx:sprite withX:x andY:y andImage:image andScaleX:1.0f andScaleY:1.0f andScaleFlag:YES andAngle:angle andRotateFlag:NO];
}
void CElement::setEffect(int effect, int effectParam)
{
	[parent->rh->spriteGen modifSpriteEffect:sprite withInkEffect:effect andInkEffectParam:effectParam];
}
void CElement::show(BOOL visible)
{
	[parent->rh->spriteGen showSprite:sprite withFlag:visible];
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DRopeAndChain

-(int)getNumberOfConditions
{
	return CND_LAST_RC;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATARC));
    
    LPRDATARC rdPtr = (LPRDATARC)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    rCreateRunObject(rdPtr, file);
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    rDestroyRunObject((LPRDATARC)m_object, bFast);
    free(m_object);
}

-(int)handleRunObject
{
	return rHandleRunObject((LPRDATARC)m_object);
}


-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    LPRDATARC rdPtr = (LPRDATARC)m_object;
    switch (num)
    {
        case CND_ONEACHRC:
            return RCND_ONEACH(rdPtr, [cnd getParamExpString:rdPtr->rh withNum:0]);
        case CND_ELEMENTCOLLISIONRC:
            return RCND_ELEMENTCOLLISION(rdPtr, cnd);
        case CND_ELEMENTOUTLEFTRC:
        case CND_ELEMENTOUTRIGHTRC:
        case CND_ELEMENTOUTTOPRC:
        case CND_ELEMENTOUTBOTTOMRC:
        case CND_ELEMENTCOLLISIONBACKDROPRC:
            return YES;
    }
    return NO;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATARC rdPtr = (LPRDATARC)m_object;
    switch (num)
    {
        case ACT_FOREACHRC:
            RACT_FOREACH(rdPtr, [act getParamExpString:rdPtr->rh withNum:0]);
            break;
        case ACT_STOPRC:
            RACT_STOP(rdPtr);
            break;
        case ACT_CLIMBUPRC:
            RACT_CLIMBUP(rdPtr, [act getParamObject:rdPtr->rh withNum:0]);
            break;
        case ACT_CLIMBDOWNRC:
            RACT_CLIMBDOWN(rdPtr, [act getParamObject:rdPtr->rh withNum:0]);
            break;
        case ACT_ATTACHRC:
            RACT_ATTACH(rdPtr, [act getParamObject:rdPtr->rh withNum:0], [act getParamExpression:rdPtr->rh withNum:1]);
            break;
        case ACT_RELEASERC:
            RACT_RELEASE(rdPtr, [act getParamObject:rdPtr->rh withNum:0]);
            break;
        case ACT_STOPLOOPRC:
            RACT_STOPLOOP(rdPtr);
            break;
        case ACT_CUTRC:
            RACT_CUT(rdPtr, [act getParamExpression:rdPtr->rh withNum:0]);
            break;
        case ACT_ATTACHNUMBERRC:
            RACT_ATTACHNUMBER(rdPtr, [act getParamObject:rdPtr->rh withNum:0], [act getParamExpression:rdPtr->rh withNum:1]);
            break;
    }
}

-(CValue*)expression:(int)num
{
    LPRDATARC rdPtr = (LPRDATARC)m_object;
    
    int ret = 0;
    switch (num)
    {
        case EXP_LOOPINDEXRC:
            ret = REXP_LOOPINDEX(rdPtr);
            break;
        case EXP_GETX1RC:
            ret = REXP_GETX1(rdPtr);
            break;
        case EXP_GETY1RC:
            ret = REXP_GETY1(rdPtr);
            break;
        case EXP_GETX2RC:
            ret = REXP_GETX2(rdPtr);
            break;
        case EXP_GETY2RC:
            ret = REXP_GETY2(rdPtr);
            break;
        case EXP_GETXMIDDLERC:
            ret = REXP_GETXMIDDLE(rdPtr);
            break;
        case EXP_GETYMIDDLERC:
            ret = REXP_GETYMIDDLE(rdPtr);
            break;
        case EXP_GETANGLERC:
            ret = REXP_GETANGLE(rdPtr);
            break;
        case EXP_GETELEMENTRC:
            ret = REXP_GETELEMENT(rdPtr);
            break;
    }
	return [rdPtr->rh getTempValue:ret];
}

@end
