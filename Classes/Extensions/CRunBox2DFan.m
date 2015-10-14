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
//  CRunBox2dFan.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunBox2dFan.h"
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

#define b2fCND_ISACTIVE			0
#define	b2fCND_LAST_FAN			1
#define b2fACT_SETSTRENGTH		0
#define b2fACT_SETANGLE			1
#define b2fACT_SETWIDTH			2
#define b2fACT_SETHEIGHT		3
#define b2fACT_ONOFF			4
#define	b2fACT_LAST_FAN			5
#define b2fEXP_STRENGTH			0
#define b2fEXP_ANGLE			1
#define b2fEXP_WIDTH			2
#define b2fEXP_HEIGHT			3
#define	b2fEXP_LAST_FAN			4

void b2fAddObject(void* ptr, void* move);
void b2fRemoveObject(void* ptr, void* movement);
LPRDATABASE b2fGetBase(LPRDATAF rdPtr);
BOOL b2fStartObject(void* ptr);
short b2fCreateRunObject(LPRDATAF rdPtr, CFile* file);
short b2fDestroyRunObject(LPRDATAF rdPtr, int fast);
short b2fHandleRunObject(LPRDATAF rdPtr);
BOOL b2fRCND_ISACTIVE(LPRDATAF rdPtr, int param1, int param2);
void b2fRACT_SETSTRENGTH(LPRDATAF rdPtr, int param1, int param2);
void b2fRACT_SETANGLE(LPRDATAF rdPtr, int param1, int param2);
void b2fRACT_SETWIDTH(LPRDATAF rdPtr, int param1, int param2);
void b2fRACT_SETHEIGHT(LPRDATAF rdPtr, int param1, int param2);
void b2fRACT_ONOFF(LPRDATAF rdPtr, int param1, int param2);
int b2fREXP_STRENGTH(LPRDATAF rdPtr);
int b2fREXP_ANGLE(LPRDATAF rdPtr);
int b2fREXP_WIDTH(LPRDATAF rdPtr);
int b2fREXP_HEIGHT(LPRDATAF rdPtr);

void b2fAddObject(void* ptr, void* move)
{
	CRunMBase* movement = (CRunMBase*)move;
	LPRDATAF rdPtr=(LPRDATAF)ptr;
	if (movement->m_identifier==rdPtr->identifier)
	{
		rdPtr->objects->Add(movement);
	}
}
void b2fRemoveObject(void* ptr, void* movement)
{
	LPRDATAF rdPtr=(LPRDATAF)ptr;
	rdPtr->objects->RemoveObject(movement);
}
LPRDATABASE b2fGetBase(LPRDATAF rdPtr)
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

BOOL b2fStartObject(void* ptr)
{
	LPRDATAF rdPtr=(LPRDATAF)ptr;
	if (rdPtr->base==nil)
	{
		rdPtr->base=b2fGetBase(rdPtr);
		if (rdPtr->base==nil)
		{
			return NO;
		}
	}
	return rdPtr->base->started;
}

short b2fCreateRunObject(LPRDATAF rdPtr, CFile* file)
{
	rdPtr->flags=[file readAInt];
	rdPtr->angle=(float)((float)[file readAInt]*b2_pi/16.0f);
	rdPtr->strengthBase=[file readAInt];
	rdPtr->ho->hoImgWidth=[file readAInt];
	rdPtr->ho->hoImgHeight=[file readAInt];
	rdPtr->identifier=[file readAInt];

	rdPtr->strength=(float)(((float)rdPtr->strengthBase)/100.0/5.0f);
	rdPtr->base=nil;
	rdPtr->pAddObject=b2fAddObject;
	rdPtr->pRemoveObject=b2fRemoveObject;
	rdPtr->pStartObject=b2fStartObject;
	rdPtr->check=YES;
    rdPtr->objects = new CCArrayList();
    
	// No errors
	return 0;
}

short b2fDestroyRunObject(LPRDATAF rdPtr, int fast)
{
    delete rdPtr->objects;
	return 0;
}

short b2fHandleRunObject(LPRDATAF rdPtr)
{
	if (!b2fStartObject(rdPtr))
		return 0;
    
	if (rdPtr->flags&FANFLAG_ON)
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
					if (x>=rdPtr->ho->hoX && x<rdPtr->ho->hoX+rdPtr->ho->hoImgWidth && y>=rdPtr->ho->hoY && y<rdPtr->ho->hoY+rdPtr->ho->hoImgHeight)
					{
						pMovement->AddVelocity(rdPtr->strength*cos(rdPtr->angle), rdPtr->strength*sin(rdPtr->angle));
					}
                    break;
				}
                case MTYPE_ELEMENT:
				{
					CElement* element = (CElement*)pMovement->m_element;
					CRect rc = [element->sprite getSpriteRect];
					int x = (int)((rc.left + rc.right) / 2 + rdPtr->rh->rhWindowX);
					int y = (int)((rc.top + rc.bottom) / 2 + rdPtr->rh->rhWindowY);
					if (x>=rdPtr->ho->hoX && x<rdPtr->ho->hoX+rdPtr->ho->hoImgWidth && y>=rdPtr->ho->hoY && y<rdPtr->ho->hoY+rdPtr->ho->hoImgHeight)
					{
						pMovement->AddVelocity(rdPtr->strength*cos(rdPtr->angle), rdPtr->strength*sin(rdPtr->angle));
					}
                    break;
				}
                case MTYPE_OBJECT:
				{
					LPHO pHo=pMovement->m_pHo;
					if (pHo->hoX>=rdPtr->ho->hoX && pHo->hoX<rdPtr->ho->hoX+rdPtr->ho->hoImgWidth && pHo->hoY>=rdPtr->ho->hoY && pHo->hoY<rdPtr->ho->hoY+rdPtr->ho->hoImgHeight)
					{
						pMovement->AddVelocity(rdPtr->strength*cos(rdPtr->angle), rdPtr->strength*sin(rdPtr->angle));
					}
                    break;
				}
			}
		}
	}
	return 0;
}

BOOL b2fRCND_ISACTIVE(LPRDATAF rdPtr, int param1, int param2)
{
	return (rdPtr->flags&FANFLAG_ON)!=0;
}

void b2fRACT_SETSTRENGTH(LPRDATAF rdPtr, int param1, int param2)
{
	rdPtr->strength=(float)(((float)param1)/100.0*0.1f);
	rdPtr->strengthBase=param1;
}
void b2fRACT_SETANGLE(LPRDATAF rdPtr, int param1, int param2)
{
	rdPtr->angle=(float)((float)param1*b2_pi/180.0f);
}
void b2fRACT_SETWIDTH(LPRDATAF rdPtr, int param1, int param2)
{
	if (param1>0)
		rdPtr->ho->hoImgWidth=param1;
}
void b2fRACT_SETHEIGHT(LPRDATAF rdPtr, int param1, int param2)
{
	if (param1>0)
		rdPtr->ho->hoImgHeight=param1;
}
void b2fRACT_ONOFF(LPRDATAF rdPtr, int param1, int param2)
{
	if (param1)
		rdPtr->flags|=FANFLAG_ON;
	else
		rdPtr->flags&=~FANFLAG_ON;
}
int b2fREXP_STRENGTH(LPRDATAF rdPtr)
{
	return rdPtr->strengthBase;
}
int b2fREXP_ANGLE(LPRDATAF rdPtr)
{
	return (int)(rdPtr->angle*180.0f/b2_pi);
}
int b2fREXP_WIDTH(LPRDATAF rdPtr)
{
	return rdPtr->ho->hoImgWidth;
}
int b2fREXP_HEIGHT(LPRDATAF rdPtr)
{
	return rdPtr->ho->hoImgHeight;
}


/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DFan

-(int)getNumberOfConditions
{
	return b2fCND_LAST_FAN;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATAF));

    LPRDATAF rdPtr = (LPRDATAF)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    b2fCreateRunObject(rdPtr, file);
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    b2fDestroyRunObject((LPRDATAF)m_object, bFast);
    free(m_object);
}

-(int)handleRunObject
{
	return b2fHandleRunObject((LPRDATAF)m_object);
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    LPRDATAF rdPtr = (LPRDATAF)m_object;
    return b2fRCND_ISACTIVE(rdPtr, 0, 0);
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATAF rdPtr = (LPRDATAF)m_object;
    switch (num)
    {
        case b2fACT_SETSTRENGTH:
            b2fRACT_SETSTRENGTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2fACT_SETANGLE:
            b2fRACT_SETANGLE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2fACT_SETWIDTH:
            b2fRACT_SETWIDTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2fACT_SETHEIGHT:
            b2fRACT_SETHEIGHT(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2fACT_ONOFF:
            b2fRACT_ONOFF(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
    }
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
    LPRDATAF rdPtr = (LPRDATAF)m_object;

    int ret = 0;
    switch (num)
    {
        case b2fEXP_STRENGTH:
            ret = b2fREXP_STRENGTH(rdPtr);
            break;
        case b2fEXP_ANGLE:
            ret = b2fREXP_ANGLE(rdPtr);
            break;
        case b2fEXP_WIDTH:
            ret = b2fREXP_WIDTH(rdPtr);
            break;
        case b2fEXP_HEIGHT:
            ret = b2fREXP_HEIGHT(rdPtr);
            break;
            
    }
	return [rdPtr->rh getTempValue:ret];
}

@end
