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
//  CRunBox2DParticules.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunBox2DParticules.h"
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
	CND_ONEACH,
	CND_PARTICULECOLLISION,
	CND_PARTICULEOUTLEFT,
	CND_PARTICULEOUTRIGHT,
	CND_PARTICULEOUTTOP,
	CND_PARTICULEOUTBOTTOM,
	CND_PARTICULESCOLLISION,
	CND_PARTICULECOLLISIONBACKDROP,
	CND_LAST_PARTICULES
};

// ---------------------------
// DEFINITION OF ACTIONS CODES
// ---------------------------
enum
{
	ACT_CREATEPARTICULESP,
	ACT_STOPPARTICULEP,
	ACT_FOREACHP,
	ACT_SETSPEEDP,
	ACT_SETROTATIONP,
	ACT_SETINTERVALP,
	ACT_SETANGLEP,
	ACT_DESTROYPARTICULEP,
	ACT_DESTROYPARTICULESP,
	ACT_SETSPEEDINTERVALP,
	ACT_SETCREATIONSPEEDP,
	ACT_SETCREATIONONP,
	ACT_STOPLOOPP,
	ACT_SETAPPLYFORCEP,
	ACT_SETAPPLYTORQUEP,
	ACT_SETASPEEDP,
	ACT_SETALOOPP,
	ACT_SETSCALEP,
	ACT_SETFRICTIONP,
	ACT_SETELASTICITYP,
	ACT_SETDENSITYP,
	ACT_SETGRAVITYP,
	ACT_SETDESTROYDISTANCEP,
	ACT_SETDESTROYANIMP,
	ACT_LAST_PARTICULES
};

// -------------------------------
// DEFINITION OF EXPRESSIONS CODES
// ------------------------------
enum
{
	EXP_PARTICULENUMBERP,
	EXP_GETPARTICULEXP,
	EXP_GETPARTICULEYP,
	EXP_GETPARTICULEANGLEP,
	EXP_GETSPEEDP,
	EXP_GETSPEEDINTERVALP,
	EXP_GETANGLEP,
	EXP_GETANGLEINTERVALP,
	EXP_GETROTATIONP,
	EXP_GETLOOPINDEXP,
	EXP_GETAPPLIEDFORCEP,
	EXP_GETAPPLIEDTORQUEP,
	EXP_LAST_PARTICULES
};

int REXP_GETAPPLIEDTORQUE(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETAPPLIEDFORCE(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETLOOPINDEX(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETROTATION(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETANGLEINTERVAL(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETANGLE(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETSPEEDINTERVAL(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETSPEED(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETPARTICULEANGLE(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETPARTICULEY(LPRDATAPARTICULES rdPtr,int param1);
int REXP_GETPARTICULEX(LPRDATAPARTICULES rdPtr,int param1);
int REXP_PARTICULENUMBER(LPRDATAPARTICULES rdPtr,int param1);
void RACT_SETDESTROYANIM(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETDESTROYDISTANCE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETGRAVITY(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETDENSITY(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETELASTICITY(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETFRICTION(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETSCALE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETALOOP(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETASPEED(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETAPPLYTORQUE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETAPPLYFORCE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_STOPLOOP(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETCREATIONON(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETCREATIONSPEED(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETSPEEDINTERVAL(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_DESTROYPARTICULES(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_DESTROYPARTICULE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETROTATION(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETINTERVAL(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETANGLE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_SETSPEED(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_FOREACH(LPRDATAPARTICULES rdPtr, NSString* pName, int param2);
void RACT_STOPPARTICULE(LPRDATAPARTICULES rdPtr, int param1, int param2);
void RACT_CREATEPARTICULES(LPRDATAPARTICULES rdPtr, int param1, int param2);
BOOL RCND_PARTICULECOLLISION(LPRDATAPARTICULES rdPtr, CCndExtension* cnd);
BOOL RCND_ONEACH(LPRDATAPARTICULES rdPtr, NSString* pName);
short pHandleRunObject(LPRDATAPARTICULES rdPtr);
void createParticules(LPRDATAPARTICULES rdPtr, int number);
int pDirAtStart(LPRDATAPARTICULES rdPtr, DWORD dirAtStart);
short pDestroyRunObject(LPRDATAPARTICULES rdPtr, int fast);
short pCreateRunObject(LPRDATAPARTICULES rdPtr, CFile* file);
BOOL prStartObject(void* ptr);
LPRDATABASE pGetBase(LPRDATAPARTICULES rdPtr);


LPRDATABASE pGetBase(LPRDATAPARTICULES rdPtr)
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
BOOL prStartObject(void* ptr)
{
	LPRDATAPARTICULES rdPtr=(LPRDATAPARTICULES)ptr;
	if (rdPtr->base==nil)
	{
		rdPtr->base=pGetBase(rdPtr);
		if (rdPtr->base==nil)
		{
			return NO;
		}
	}
	return rdPtr->base->started;
}
short pCreateRunObject(LPRDATAPARTICULES rdPtr, CFile* file)
{
    rdPtr->base = nil;
    rdPtr->ho->hoImgWidth = [file readAInt];
    rdPtr->ho->hoImgHeight = [file readAInt];
    rdPtr->type = [file readAShort];
    rdPtr->flags = [file readAInt];
    rdPtr->creationSpeed = [file readAInt];
    rdPtr->number = [file readAInt];
    rdPtr->animationSpeed = [file readAInt];
    rdPtr->angleDWORD = [file readAInt];
    rdPtr->speed = [file readAInt];
    rdPtr->speedInterval = [file readAInt];
    rdPtr->friction = (float)([file readAInt] / 100.0);
    rdPtr->restitution=(float)([file readAInt]/100.0);
    rdPtr->density=(float)([file readAInt]/100.0);
    rdPtr->angleInterval=[file readAInt];
    rdPtr->identifier=[file readAInt];
    rdPtr->gravity=(float)([file readAInt]/100.0);
    rdPtr->rotation = (float)([file readAInt] / 100.0 * ROTATIONPA_MULT);
    rdPtr->applyForce = (float)([file readAInt] / 100 * APPLYFORCEPA_MULT);
    rdPtr->applyTorque = (float)([file readAInt] / 100 * APPLYTORQUEPA_MULT);
    rdPtr->scaleSpeed = (float)([file readAInt] / 400);
    rdPtr->destroyDistance = [file readAInt];
    rdPtr->nImages = [file readAShort];
    int n;
    for (n=0; n<rdPtr->nImages; n++)
        rdPtr->images[n] = [file readAShort];
    [rdPtr->ho loadImageList:rdPtr->images withLength:rdPtr->nImages];
	rdPtr->angle = 0;
	rdPtr->pAddObject=nil;
	rdPtr->pRemoveObject=nil;
	rdPtr->pStartObject=prStartObject;
	rdPtr->loopName = [[NSString alloc] initWithString:@""];
	rdPtr->effect = rdPtr->ho->ros->rsEffect;
	rdPtr->effectParam = rdPtr->ho->ros->rsEffectParam;
	rdPtr->visible = (rdPtr->ho->ros->rsFlags&RSFLAG_VISIBLE)!=0;
    rdPtr->particules = new CCArrayList();
    rdPtr->toDestroy = new CCArrayList();
    
	return 0;
}

short pDestroyRunObject(LPRDATAPARTICULES rdPtr, int fast)
{
	LPRDATABASE pBase = pGetBase(rdPtr);
	if (pBase != nil)
	{
		int n;
		for (n = 0; n < rdPtr->particules->Size() ; n++)
		{
			CParticule* particule = (CParticule*)rdPtr->particules->Get(n);
			delete particule;
		}
	}
    delete rdPtr->particules;
    delete rdPtr->toDestroy;
    [rdPtr->loopName release];
	return 0;
}

int pDirAtStart(LPRDATAPARTICULES rdPtr, DWORD dirAtStart)
{
	int dir;
    
	// Compte le nombre de directions demandees
	int cpt=0;
	DWORD das=dirAtStart;
	DWORD das2;
	for (int n=0; n<32; n++)
	{
		das2=das;
		das>>=1;
		if (das2&1) cpt++;
	}
    
	// Une ou zero direction?
	if (cpt==0)
	{
        //			dir=random(DIRID_MAX-1);			// BUG dans la version 1 : ca met toujours a zero!
		dir=0;
	}
	else
	{
		// Appelle le hasard pour trouver le bit
		cpt=[rdPtr->rh random:cpt];
		das=dirAtStart;
		for (dir=0; ; dir++)
		{
			das2=das;
			das>>=1;
			if (das2&1)
			{
				cpt--;
				if (cpt<0) break;
			}
		}
	}
	return dir;
}

void createParticules(LPRDATAPARTICULES rdPtr, int number)
{
    int n;
    CParticule* particule;
    for (n = 0; n < number; n++)
    {
        int x, y;
        if (rdPtr->type == PATYPE_POINT)
        {
            x = [rdPtr->ho getX];
            y = [rdPtr->ho getY];
        }
        else
        {
			int rx = [rdPtr->rh random:rdPtr->ho->hoImgWidth];
			int ry = [rdPtr->rh random:rdPtr->ho->hoImgHeight];
            x = [rdPtr->ho getX] + rx;
            y = [rdPtr->ho getY] + ry;
        }
        
        float angle;
        if (rdPtr->angleDWORD != ANGLENONE)
            angle = (float)(pDirAtStart(rdPtr, rdPtr->angleDWORD) * 11.25);
        else
            angle = rdPtr->angle;
        if (rdPtr->angleInterval > 0)
        {
			int interval = [rdPtr->rh random:rdPtr->angleInterval * 2];
            angle += interval - rdPtr->angleInterval;
        }
        
        particule = new CParticule(rdPtr, x, y);
		particule->m_mBase->m_identifier = rdPtr->identifier;
        particule->setAnimation(rdPtr->images, rdPtr->nImages, rdPtr->animationSpeed, rdPtr->flags, rdPtr->visible);
        particule->setScale(rdPtr->scaleSpeed);
		particule->setForce(rdPtr->applyForce, rdPtr->applyTorque, angle);
		particule->setEffect(rdPtr->effect, rdPtr->effectParam);
        
        CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:rdPtr->images[0]];
        particule->m_mBase->m_body = rdPtr->base->pCreateBody(rdPtr->base, b2_dynamicBody, x, y, angle, rdPtr->gravity, particule->m_mBase, 0, 0);
        particule->fixture = rdPtr->base->pBodyCreateCircleFixture(rdPtr->base, particule->m_mBase->m_body, particule->m_mBase, x, y, (pImage->width + pImage->height) / 4, rdPtr->density, rdPtr->friction, rdPtr->restitution);
        
        float mass = particule->m_mBase->m_body->GetMass();
		int interval = [rdPtr->rh random:rdPtr->speedInterval * 2];
        int speed = rdPtr->speed + interval - rdPtr->speedInterval;
        speed = MAX(speed, 1);
        float speedFloat = (float)(speed / 100.0 * 20.0);
        rdPtr->base->pBodyApplyImpulse(rdPtr->base, particule->m_mBase->m_body, (float)(maxd(1.0, speedFloat * mass)), angle);
        rdPtr->base->pBodyApplyAngularImpulse(rdPtr->base, particule->m_mBase->m_body, rdPtr->rotation);
        
        rdPtr->particules->Add(particule);
    }
}


short pHandleRunObject(LPRDATAPARTICULES rdPtr)
{
	if (!prStartObject(rdPtr))
		return 0;
    
	int n;
    CParticule* particule;
    if (rdPtr->flags & PAFLAG_CREATEATSTART)
    {
        rdPtr->creationSpeedCounter += rdPtr->creationSpeed;
        if (rdPtr->creationSpeedCounter >= 100)
        {
            rdPtr->creationSpeedCounter -= 100;
            createParticules(rdPtr, rdPtr->number);
        }
    }
    
    for (n = 0; n < rdPtr->toDestroy->Size() ; n++)
    {
        particule = (CParticule*)rdPtr->toDestroy->Get(n);
		delete particule;
        rdPtr->toDestroy->RemoveIndex(n);
		rdPtr->particules->RemoveObject(particule);
        n--;
    }
    
	LPRH rhPtr = rdPtr->ho->hoAdRunHeader;
    for (n = 0; n < rdPtr->particules->Size() ; n++)
    {
        particule = (CParticule*)rdPtr->particules->Get(n);
        int x, y;
		float angle;
		rdPtr->base->pGetBodyPosition(rdPtr->base, particule->m_mBase->m_body, &x, &y, &angle);
		if (x < rhPtr->rh3XMinimumKill || x > rhPtr->rh3XMaximumKill
			|| y < rhPtr->rh3YMinimumKill || y > rhPtr->rh3YMaximumKill)
		{
			rdPtr->toDestroy->Add(particule);
            particule->destroyed = YES;
		}
		else
		{
			particule->animate();
		}
    }
    
	if (rdPtr->ho->ros->rsEffect != rdPtr->effect || rdPtr->ho->ros->rsEffectParam != rdPtr->effectParam)
	{
		rdPtr->effect = rdPtr->ho->ros->rsEffect;
		rdPtr->effectParam = rdPtr->ho->ros->rsEffectParam;
		for (n = 0; n < rdPtr->particules->Size() ; n++)
		{
			particule = (CParticule*)rdPtr->particules->Get(n);
            if (!particule->destroyed)
                particule->setEffect(rdPtr->effect, rdPtr->effectParam);
		}
	}
	BOOL visible = rdPtr->ho->ros->rsFlags&RSFLAG_VISIBLE;
	if (visible != rdPtr->visible)
	{
		rdPtr->visible = visible;
		for (n = 0; n < rdPtr->particules->Size() ; n++)
		{
			particule = (CParticule*)rdPtr->particules->Get(n);
			if (!particule->destroyed)
				particule->show(visible);
		}
	}   
	return 0;
}


BOOL RCND_ONEACH(LPRDATAPARTICULES rdPtr, NSString* pName)
{
	return [pName caseInsensitiveCompare:rdPtr->loopName] == 0;
}

BOOL RCND_PARTICULECOLLISION(LPRDATAPARTICULES rdPtr, CCndExtension* cnd)
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
            CQualToOiList* pq = rdPtr->rh->rhEvtProg->qualToOiList[oil & 0x7FFF];
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
void RACT_CREATEPARTICULES(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	createParticules(rdPtr, param1);
}
void RACT_STOPPARTICULE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	rdPtr->stopped = YES;
}
void RACT_FOREACH(LPRDATAPARTICULES rdPtr, NSString* pName, int param2)
{
    [rdPtr->loopName release];
    rdPtr->loopName = [[NSString alloc] initWithString:pName];
    
    int n;
    rdPtr->stopLoop = NO;
    for (n = 0; n < rdPtr->particules->Size() ; n++)
    {
        if (rdPtr->stopLoop)
            break;
        CParticule* particule = (CParticule*)rdPtr->particules->Get(n);
        rdPtr->currentParticule1 = particule;
        rdPtr->loopIndex = n;
        [rdPtr->ho generateEvent:CND_ONEACH withParam:0];
    }
}
void RACT_SETSPEED(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->speed = MIN(param1, 250);
    rdPtr->speed = MAX(rdPtr->speed, 0);
}
void RACT_SETANGLE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->angle = (float)param1;
	rdPtr->angleDWORD = ANGLENONE;
}
void RACT_SETINTERVAL(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	rdPtr->angleInterval = MIN(param1, 360);
	rdPtr->angleInterval = MAX(rdPtr->angleInterval, 0);
}
void RACT_SETROTATION(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->rotation = (float)MIN(param1, 250);
    rdPtr->rotation = MAX(rdPtr->rotation, -250);
}
void RACT_DESTROYPARTICULE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    if (rdPtr->currentParticule1 != nil)
	{
		if (rdPtr->toDestroy->IndexOf(rdPtr->currentParticule1) < 0
			&& rdPtr->particules->IndexOf(rdPtr->currentParticule1) >= 0)
		{
			rdPtr->toDestroy->Add(rdPtr->currentParticule1);
			rdPtr->currentParticule1->destroyed = YES;
		}
	}
}
void RACT_DESTROYPARTICULES(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    if (rdPtr->currentParticule1 != nil)
	{
		if (rdPtr->toDestroy->IndexOf(rdPtr->currentParticule1) < 0
			&& rdPtr->particules->IndexOf(rdPtr->currentParticule1) >= 0)
		{
			rdPtr->toDestroy->Add(rdPtr->currentParticule1);
			rdPtr->currentParticule1->destroyed = YES;
		}
	}
    if (rdPtr->currentParticule2 != nil)
	{
		if (rdPtr->toDestroy->IndexOf(rdPtr->currentParticule2) < 0
			&& rdPtr->particules->IndexOf(rdPtr->currentParticule2) >= 0)
		{
	        rdPtr->toDestroy->Add(rdPtr->currentParticule2);
			rdPtr->currentParticule2->destroyed = YES;
		}
	}
}
void RACT_SETSPEEDINTERVAL(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->speedInterval = MAX(param1, 0);
}
void RACT_SETCREATIONSPEED(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->creationSpeed = MIN(param1, 100);
    rdPtr->creationSpeed = MAX(rdPtr->creationSpeed, 0);
}
void RACT_SETCREATIONON(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	if (param1)
		rdPtr->flags |= PAFLAG_CREATEATSTART;
	else
		rdPtr->flags &= ~PAFLAG_CREATEATSTART;
}
void RACT_STOPLOOP(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->stopLoop = YES;
}
void RACT_SETAPPLYFORCE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->applyForce = (float)((float)param1 / 100 * APPLYFORCEPA_MULT);
}
void RACT_SETAPPLYTORQUE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->applyTorque = (float)((float)param1 / 100 * APPLYTORQUEPA_MULT);
}
void RACT_SETASPEED(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->animationSpeed = param1;
}
void RACT_SETALOOP(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->flags &= ~PAFLAG_LOOP;
    if (param1)
        rdPtr->flags |= PAFLAG_LOOP;
}
void RACT_SETSCALE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->scaleSpeed = (float)(param1 / 400.0f);
}
void RACT_SETFRICTION(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	rdPtr->friction = (float)(param1 / 100.0f);
}
void RACT_SETELASTICITY(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	rdPtr->restitution = (float)(param1 / 100.0f);
}
void RACT_SETDENSITY(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	rdPtr->density = (float)(param1 / 100.0f);
}
void RACT_SETGRAVITY(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	rdPtr->gravity = (float)(param1 / 100.0f);
}
void RACT_SETDESTROYDISTANCE(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
    rdPtr->destroyDistance = param1;
}
void RACT_SETDESTROYANIM(LPRDATAPARTICULES rdPtr, int param1, int param2)
{
	if (param1)
		rdPtr->flags |= PAFLAG_DESTROYANIM;
	else
		rdPtr->flags &= ~PAFLAG_DESTROYANIM;
}


int REXP_PARTICULENUMBER(LPRDATAPARTICULES rdPtr,int param1)
{
    return rdPtr->particules->Size();
}
int REXP_GETPARTICULEX(LPRDATAPARTICULES rdPtr,int param1)
{
    if (rdPtr->currentParticule1)
        return rdPtr->currentParticule1->x;
    return 0;
}
int REXP_GETPARTICULEY(LPRDATAPARTICULES rdPtr,int param1)
{
	if (rdPtr->currentParticule1)
		return rdPtr->currentParticule1->y;
	return 0;
}
int REXP_GETPARTICULEANGLE(LPRDATAPARTICULES rdPtr,int param1)
{
    if (rdPtr->currentParticule1)
        return (int)rdPtr->currentParticule1->angle;
	return 0;
}
int REXP_GETSPEED(LPRDATAPARTICULES rdPtr,int param1)
{
    return rdPtr->speed;
}
int REXP_GETSPEEDINTERVAL(LPRDATAPARTICULES rdPtr,int param1)
{
    return rdPtr->speedInterval;
}
int REXP_GETANGLE(LPRDATAPARTICULES rdPtr,int param1)
{
    return (int)rdPtr->angle;
}
int REXP_GETANGLEINTERVAL(LPRDATAPARTICULES rdPtr,int param1)
{
    return rdPtr->angleInterval;
}
int REXP_GETROTATION(LPRDATAPARTICULES rdPtr,int param1)
{
    return (int)rdPtr->rotation;
}
int REXP_GETLOOPINDEX(LPRDATAPARTICULES rdPtr,int param1)
{
    return rdPtr->loopIndex;
}
int REXP_GETAPPLIEDFORCE(LPRDATAPARTICULES rdPtr,int param1)
{
    return (int)(rdPtr->applyForce * 100 / APPLYFORCEPA_MULT);
}
int REXP_GETAPPLIEDTORQUE(LPRDATAPARTICULES rdPtr,int param1)
{
    return (int)(rdPtr->applyTorque * 100 / APPLYTORQUEPA_MULT);
}




// CPARTICULE
/////////////////////////////////////////////////////////////////////////
CParticule::CParticule(void* ptr, int xx, int yy)
{
	LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)ptr;
	
	m_mBase = new CRunMBase(rdPtr->base, rdPtr->ho, MTYPE_PARTICULE);
	m_mBase->m_particule = this;
    
	parent = rdPtr;
	initialX = xx;
	initialY= yy;
    x = xx;
    y = yy;
    angle = 0;
    nImages = 0;
    image = 0;
    animationSpeed = 0;
    animationSpeedCounter = 0;
    destroyed = NO;
    m_addVFlag = 0;
    m_addVX = 0;
    m_addVY = 0;
    oldWidth = 0;
    oldHeight = 0;
    fixture = nil;
    scaleSpeed = 0;
    scale = 0;
}
CParticule::~CParticule()
{
	LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)parent;
	LPRH rhPtr = rdPtr->ho->hoAdRunHeader;
	[rhPtr->spriteGen delSprite:sprite];
	rdPtr->base->pDestroyBody(rdPtr->base, m_mBase->m_body);
	delete m_mBase;
}
void CParticule::setForce(float force, float torque, float direction)
{
	m_force = force;
	m_torque = torque;
	m_direction = direction;
}
void CParticule::setAnimation(short* pImages, int nI, int aSpeed, DWORD f, BOOL visible)
{
	LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)parent;
    
	images = pImages;
    nImages = nI;
    animationSpeed = aSpeed;
    animationSpeedCounter = 0;
    flags = f;
    stopped = NO;
    
    CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:images[0]];
    oldWidth = pImage->width * scale;
    oldHeight = pImage->height * scale;
    
	CRSpr* rsPtr=rdPtr->ho->ros;
	LPRH rhPtr = rdPtr->ho->hoAdRunHeader;
	sprite = [rhPtr->spriteGen addSprite:x withY:y andImage:images[0] andLayer:rsPtr->rsLayer andZOrder:rsPtr->rsZOrder andBackColor:rsPtr->rsBackColor andFlags:visible?0:SF_HIDDEN andObject:nil];
}
void CParticule::setScale(float speed)
{
	scaleSpeed = speed;
    scale = 1;
}
void CParticule::setEffect(int effect, int effectParam)
{
	LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)parent;
	[rdPtr->rh->spriteGen modifSpriteEffect:sprite withInkEffect:effect andInkEffectParam:effectParam];
}
void CParticule::show(BOOL visible)
{
	LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)parent;
	[rdPtr->rh->spriteGen showSprite:sprite withFlag:visible];
}
void CParticule::animate()
{
	LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)parent;
    
	if (!stopped)
    {
        animationSpeedCounter += (int)(animationSpeed * rdPtr->ho->hoAdRunHeader->rh4MvtTimerCoef);
        while (animationSpeedCounter >= 100)
        {
            animationSpeedCounter -= 100;
            image++;
            if (image >= nImages)
            {
                if (flags & PAFLAG_LOOP)
                {
                    image = 0;
                }
                else
                {
                    image--;
                    stopped = YES;
                    if (!destroyed && flags & PAFLAG_DESTROYANIM)
                    {
                        rdPtr->toDestroy->Add(this);
                        destroyed = YES;
                    }
                }
            }
        }
    }
    float oldScale = scale;
    scale += scaleSpeed;
	
	short imageHandle = images[image];
    CImage* pImage = [rdPtr->rh->rhApp->imageBank getImageFromHandle:imageHandle];
	if(pImage == nil)
	{
		//rdPtr->toDestroy->Add(this);
		//destroyed = YES;
		return;
	}

    float width = (float)(pImage->width * scale);
    float height = (float)(pImage->height * scale);
    if (width < 1 || height < 1)
    {
        if (!destroyed)
        {
            rdPtr->toDestroy->Add(this);
            destroyed = YES;
        }
        scale = oldScale;
    }
    else
    {
        if (width != oldWidth || height != oldHeight)
        {
            oldWidth = width;
            oldHeight = height;
            rdPtr->base->pBodyDestroyFixture(rdPtr->base, m_mBase->m_body, fixture);
            fixture = rdPtr->base->pBodyCreateCircleFixture(rdPtr->base, m_mBase->m_body, m_mBase, x, y, (int)((width + height) / 4), rdPtr->density, rdPtr->friction, rdPtr->restitution);
        }
    }
    
    rdPtr->base->pBodyAddVelocity(rdPtr->base, m_mBase->m_body, m_mBase->m_addVX, m_mBase->m_addVY);
	m_mBase->ResetAddVelocity();
    
	rdPtr->base->pBodyApplyImpulse(rdPtr->base, m_mBase->m_body, m_force, m_direction);
	rdPtr->base->pBodyApplyAngularImpulse(rdPtr->base, m_mBase->m_body, m_torque);
    
	rdPtr->base->pGetBodyPosition(rdPtr->base, m_mBase->m_body, &x, &y, &angle);
    
    int dx = x - initialX;
    int dy = y - initialY;
    int distance = (int)(sqrt(dx * dx + dy * dy));
    if (distance > rdPtr->destroyDistance && !destroyed)
    {
        rdPtr->toDestroy->Add(this);
        destroyed = YES;
    }
	else
	{
		[rdPtr->rh->spriteGen modifSpriteEx:sprite withX:x andY:y andImage:images[image] andScaleX:scale andScaleY:scale andScaleFlag:YES andAngle:angle andRotateFlag:YES];
	}
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DParticules

-(int)getNumberOfConditions
{
	return CND_LAST_PARTICULES;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATAPARTICULES));
    
    LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    pCreateRunObject(rdPtr, file);
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    pDestroyRunObject((LPRDATAPARTICULES)m_object, bFast);
    free(m_object);
}

-(int)handleRunObject
{
	return pHandleRunObject((LPRDATAPARTICULES)m_object);
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)m_object;
    switch (num)
    {
        case CND_ONEACH:
            return RCND_ONEACH(rdPtr, [cnd getParamExpString:rh withNum:0]);
        case CND_PARTICULECOLLISION:
            return RCND_PARTICULECOLLISION(rdPtr, cnd);
        case CND_PARTICULEOUTLEFT:
        case CND_PARTICULEOUTRIGHT:
        case CND_PARTICULEOUTTOP:
        case CND_PARTICULEOUTBOTTOM:
        case CND_PARTICULESCOLLISION:
        case CND_PARTICULECOLLISIONBACKDROP:
            return YES;
    }
    return NO;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)m_object;
    switch (num)
    {
        case ACT_CREATEPARTICULESP:
            RACT_CREATEPARTICULES(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_STOPPARTICULEP:
            RACT_STOPPARTICULE(rdPtr, 0, 0);
            break;
        case ACT_FOREACHP:
            RACT_FOREACH(rdPtr, [act getParamExpString:rh withNum:0], 0);
            break;
        case ACT_SETSPEEDP:
            RACT_SETSPEED(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETROTATIONP:
            RACT_SETROTATION(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETINTERVALP:
            RACT_SETINTERVAL(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETANGLEP:
            RACT_SETANGLE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_DESTROYPARTICULEP:
            RACT_DESTROYPARTICULE(rdPtr, 0, 0);
            break;
        case ACT_DESTROYPARTICULESP:
            RACT_DESTROYPARTICULES(rdPtr, 0, 0);
            break;
        case ACT_SETSPEEDINTERVALP:
            RACT_SETSPEEDINTERVAL(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETCREATIONSPEEDP:
            RACT_SETCREATIONSPEED(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETCREATIONONP:
            RACT_SETCREATIONON(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_STOPLOOPP:
            RACT_STOPLOOP(rdPtr, 0, 0);
            break;
        case ACT_SETAPPLYFORCEP:
            RACT_SETAPPLYFORCE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETAPPLYTORQUEP:
            RACT_SETAPPLYTORQUE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETASPEEDP:
            RACT_SETASPEED(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETALOOPP:
            RACT_SETALOOP(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETSCALEP:
            RACT_SETSCALE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETFRICTIONP:
            RACT_SETFRICTION(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETELASTICITYP:
            RACT_SETELASTICITY(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETDENSITYP:
            RACT_SETDENSITY(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETGRAVITYP:
            RACT_SETGRAVITY(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETDESTROYDISTANCEP:
            RACT_SETDESTROYDISTANCE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case ACT_SETDESTROYANIMP:
            RACT_SETDESTROYANIM(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
    }
}

-(CValue*)expression:(int)num
{
    LPRDATAPARTICULES rdPtr = (LPRDATAPARTICULES)m_object;
    
    int ret = 0;
    switch (num)
    {
        case EXP_PARTICULENUMBERP:
            ret = REXP_PARTICULENUMBER(rdPtr, 0);
            break;
        case EXP_GETPARTICULEXP:
            ret = REXP_GETPARTICULEX(rdPtr, 0);
            break;
        case EXP_GETPARTICULEYP:
            ret = REXP_GETPARTICULEY(rdPtr, 0);
            break;
        case EXP_GETPARTICULEANGLEP:
            ret = REXP_GETPARTICULEANGLE(rdPtr, 0);
            break;
        case EXP_GETSPEEDP:
            ret = REXP_GETSPEED(rdPtr, 0);
            break;
        case EXP_GETSPEEDINTERVALP:
            ret = REXP_GETSPEEDINTERVAL(rdPtr, 0);
            break;
        case EXP_GETANGLEP:
            ret = REXP_GETANGLE(rdPtr, 0);
            break;
        case EXP_GETANGLEINTERVALP:
            ret = REXP_GETANGLEINTERVAL(rdPtr, 0);
            break;
        case EXP_GETROTATIONP:
            ret = REXP_GETROTATION(rdPtr, 0);
            break;
        case EXP_GETLOOPINDEXP:
            ret = REXP_GETLOOPINDEX(rdPtr, 0);
            break;
        case EXP_GETAPPLIEDFORCEP:
            ret = REXP_GETAPPLIEDFORCE(rdPtr, 0);
            break;
        case EXP_GETAPPLIEDTORQUEP:
            ret = REXP_GETAPPLIEDTORQUE(rdPtr, 0);
            break;
    }
	return [rdPtr->rh getTempValue:ret];
}

@end
