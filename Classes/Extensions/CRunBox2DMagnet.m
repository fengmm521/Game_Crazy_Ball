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
//  CRunBox2DMagnet.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunBox2DMagnet.h"
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
#import "CExtension.h"
#import "CSprite.h"

#define b2mCND_ISACTIVE			0
#define	b2mCND_LAST_MAGNET		1
#define b2mACT_SETSTRENGTH		0
#define b2mACT_SETANGLE			1
#define b2mACT_SETWIDTH			2
#define b2mACT_SETHEIGHT		3
#define b2mACT_ONOFF			4
#define b2mEXP_STRENGTH			0
#define b2mEXP_WIDTH			1
#define b2mEXP_HEIGHT			2

LPRDATABASE b2mGetBase(LPRDATAM rdPtr);
BOOL b2mrStartObject(void* ptr);
short b2mCreateRunObject(LPRDATAM rdPtr, CFile* file);
short b2mDestroyRunObject(LPRDATAM rdPtr, int fast);
short b2mHandleRunObject(LPRDATAM rdPtr);
BOOL b2mRCND_ISACTIVE(LPRDATAM rdPtr, int param1, int param2);
void b2mRACT_SETSTRENGTH(LPRDATAM rdPtr, int param1, int param2);
void b2mRACT_SETANGLE(LPRDATAM rdPtr, int param1, int param2);
void b2mRACT_SETWIDTH(LPRDATAM rdPtr, int param1, int param2);
void b2mRACT_SETHEIGHT(LPRDATAM rdPtr, int param1, int param2);
void b2mRACT_ONOFF(LPRDATAM rdPtr, int param1, int param2);
int b2mREXP_STRENGTH(LPRDATAM rdPtr,int param1);
int b2mREXP_WIDTH(LPRDATAM rdPtr,int param1);
int b2mREXP_HEIGHT(LPRDATAM rdPtr,int param1);
void b2mrAddObject(void* ptr, void* move);
void b2mrRemoveObject(void* ptr, void* movement);

void b2mrAddObject(void* ptr, void* move)
{
	CRunMBase* movement = (CRunMBase*)move;
	LPRDATAM rdPtr=(LPRDATAM)ptr;
	if (movement->m_identifier==rdPtr->identifier)
	{
		rdPtr->objects->Add(movement);
	}
}
void b2mrRemoveObject(void* ptr, void* movement)
{
	LPRDATAM rdPtr=(LPRDATAM)ptr;
	rdPtr->objects->RemoveObject(movement);
}
LPRDATABASE b2mGetBase(LPRDATAM rdPtr)
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
BOOL b2mrStartObject(void* ptr)
{
	LPRDATAM rdPtr=(LPRDATAM)ptr;
	if (rdPtr->base==nil)
	{
		rdPtr->base=b2mGetBase(rdPtr);
		if (rdPtr->base==nil)
		{
			return NO;
		}
	}
	return rdPtr->base->started;
}
#define MSTRENGTHMULT 0.001f
short b2mCreateRunObject(LPRDATAM rdPtr, CFile* file)
{
	rdPtr->flags=[file readAInt];
	rdPtr->angle=[file readAInt];
	rdPtr->strengthBase=[file readAInt];
	rdPtr->strength=(float)(((float)rdPtr->strengthBase)*MSTRENGTHMULT);
	rdPtr->ho->hoImgWidth=[file readAInt];
	rdPtr->ho->hoImgHeight=[file readAInt];
	rdPtr->identifier=[file readAInt];

	int sx=rdPtr->ho->hoImgWidth/2;
	int sy=rdPtr->ho->hoImgHeight/2;
	rdPtr->radius=(int)sqrt((double)(sx*sx+sy*sy));
	rdPtr->base=nil;
	rdPtr->pAddObject=b2mrAddObject;
	rdPtr->pRemoveObject=b2mrRemoveObject;
	rdPtr->pStartObject=b2mrStartObject;
    rdPtr->objects = new CCArrayList();
    
	// No errors
	return 0;
}

// ----------------
// DestroyRunObject
// ----------------
// Destroys the run-time object
//
short b2mDestroyRunObject(LPRDATAM rdPtr, int fast)
{
    delete rdPtr->objects;
	return 0;
}


// ----------------
// HandleRunObject
// ----------------
short b2mHandleRunObject(LPRDATAM rdPtr)
{
	if (!b2mrStartObject(rdPtr))
		return 0;
    
	if (rdPtr->flags&MAGNETFLAG_ON)
	{
		int n;
		for (n=0; n<rdPtr->objects->Size(); n++)
		{
			CRunMBase* pMovement=(CRunMBase*)rdPtr->objects->Get(n);
			switch (pMovement->m_type)
			{
                case MTYPE_PARTICULE:
				{
					CParticule* particule = (CParticule*)pMovement->m_particule;
					CRect rc = [particule->sprite getSpriteRect];
					int x = (int)((rc.left + rc.right) / 2 + rdPtr->rh->rhWindowX);
					int y = (int)((rc.top + rc.bottom) / 2 + rdPtr->rh->rhWindowY);
					int dx=x-(rdPtr->ho->hoX+rdPtr->ho->hoImgWidth/2);
					int dy=y-(rdPtr->ho->hoY+rdPtr->ho->hoImgHeight/2);
					int distance=(int)sqrt((double)(dx*dx+dy*dy));
					if (distance<rdPtr->radius)
					{
						float angle=(float)atan2((float)-dy, (float)dx)*180.0f/3.141592653589f;
						if (angle<0)
							angle=360.0f+angle;
						int a=(int)(angle/11.25f);
						DWORD mask=1<<a;
						if (rdPtr->angle&mask)
						{
							rdPtr->base->pBodyApplyImpulse(rdPtr->base, pMovement->m_body, rdPtr->strength, angle+180.0f);
						}
					}
                    break;
				}
                case MTYPE_ELEMENT:
				{
					CElement* element = (CElement*)pMovement->m_element;
					CRect rc = [element->sprite getSpriteRect];
					int x = (int)((rc.left + rc.right) / 2 + rdPtr->rh->rhWindowX);
					int y = (int)((rc.top + rc.bottom) / 2 + rdPtr->rh->rhWindowY);
					int dx=x-(rdPtr->ho->hoX+rdPtr->ho->hoImgWidth/2);
					int dy=y-(rdPtr->ho->hoY+rdPtr->ho->hoImgHeight/2);
					int distance=(int)sqrt((double)(dx*dx+dy*dy));
					if (distance<rdPtr->radius)
					{
						float angle=(float)atan2((float)-dy, (float)dx)*180.0f/3.141592653589f;
						if (angle<0)
							angle=360.0f+angle;
						int a=(int)(angle/11.25f);
						DWORD mask=1<<a;
						if (rdPtr->angle&mask)
						{
							rdPtr->base->pBodyApplyImpulse(rdPtr->base, pMovement->m_body, rdPtr->strength, angle+180.0f);
						}
					}
                    break;
				}
                case MTYPE_OBJECT:
				{
					LPHO pHo=pMovement->m_pHo;
					if (pHo->hoX>=rdPtr->ho->hoX && pHo->hoX<rdPtr->ho->hoX+rdPtr->ho->hoImgWidth && pHo->hoY>=rdPtr->ho->hoY && pHo->hoY<rdPtr->ho->hoY+rdPtr->ho->hoImgHeight)
					{
						int dx=pHo->hoX-(rdPtr->ho->hoX+rdPtr->ho->hoImgWidth/2);
						int dy=pHo->hoY-(rdPtr->ho->hoY+rdPtr->ho->hoImgHeight/2);
						float angle=(float)atan2((float)-dy, (float)dx)*180.0f/3.141592653589f;
						if (angle<0)
							angle=360.0f+angle;
						int a=(int)(angle/11.25f);
						DWORD mask=1<<a;
						if (rdPtr->angle&mask)
						{
							rdPtr->base->pBodyApplyImpulse(rdPtr->base, pMovement->m_body, rdPtr->strength, angle+180.0f);
						}
					}
				}
                    break;
			}
		}
	}
	return 0;
}

BOOL b2mRCND_ISACTIVE(LPRDATAM rdPtr, int param1, int param2)
{
	return (rdPtr->flags&MAGNETFLAG_ON)!=0;
}

void b2mRACT_SETSTRENGTH(LPRDATAM rdPtr, int param1, int param2)
{
	rdPtr->strengthBase=param1;
	rdPtr->strength=(float)(((float)param1)*MSTRENGTHMULT);
}
void b2mRACT_SETANGLE(LPRDATAM rdPtr, int param1, int param2)
{
	rdPtr->angle=param1;
}
void b2mRACT_SETWIDTH(LPRDATAM rdPtr, int param1, int param2)
{
	if (param1>0)
		rdPtr->ho->hoImgWidth=param1;
}
void b2mRACT_SETHEIGHT(LPRDATAM rdPtr, int param1, int param2)
{
	if (param1>0)
		rdPtr->ho->hoImgHeight=param1;
}
void b2mRACT_ONOFF(LPRDATAM rdPtr, int param1, int param2)
{
	if (param1)
		rdPtr->flags|=MAGNETFLAG_ON;
	else
		rdPtr->flags&=~MAGNETFLAG_ON;
}

int b2mREXP_STRENGTH(LPRDATAM rdPtr,int param1)
{
	return rdPtr->strengthBase;
}
int b2mREXP_WIDTH(LPRDATAM rdPtr,int param1)
{
	return rdPtr->ho->hoImgWidth;
}
int b2mREXP_HEIGHT(LPRDATAM rdPtr,int param1)
{
	return rdPtr->ho->hoImgHeight;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DMagnet

-(int)getNumberOfConditions
{
	return b2mCND_LAST_MAGNET;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATAM));
    
    LPRDATAM rdPtr = (LPRDATAM)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    b2mCreateRunObject(rdPtr, file);
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    b2mDestroyRunObject((LPRDATAM)m_object, bFast);
    free(m_object);
}

-(int)handleRunObject
{
	return b2mHandleRunObject((LPRDATAM)m_object);
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    LPRDATAM rdPtr = (LPRDATAM)m_object;
    return b2mRCND_ISACTIVE(rdPtr, 0, 0);
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATAM rdPtr = (LPRDATAM)m_object;
    switch (num)
    {
        case b2mACT_SETSTRENGTH:
            b2mRACT_SETSTRENGTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2mACT_SETANGLE:
            b2mRACT_SETSTRENGTH(rdPtr, act->pParams[0]->evp.evpL.evpL0, 0);
            break;
        case b2mACT_SETWIDTH:
            b2mRACT_SETWIDTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2mACT_SETHEIGHT:
            b2mRACT_SETHEIGHT(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2mACT_ONOFF:
            b2mRACT_SETSTRENGTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
    }
}

-(CValue*)expression:(int)num
{
    LPRDATAM rdPtr = (LPRDATAM)m_object;
    
    int ret = 0;
    switch (num)
    {
        case b2mEXP_STRENGTH:
            ret = b2mREXP_STRENGTH(rdPtr, 0);
            break;
        case b2mEXP_WIDTH:
            ret = b2mREXP_WIDTH(rdPtr, 0);
            break;
        case b2mEXP_HEIGHT:
            ret = b2mREXP_HEIGHT(rdPtr, 0);
            break;
            
    }
	return [rdPtr->rh getTempValue:ret];
}

@end
