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
//  CRunBox2DTreadmill.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 13/11/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunBox2DTreadmill.h"
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

#define b2tCND_ISACTIVE			0
#define	b2tCND_LAST_TM			1
#define b2tACT_SETSTRENGTH		0
#define b2tACT_SETANGLE			1
#define b2tACT_SETWIDTH			2
#define b2tACT_SETHEIGHT		3
#define b2tACT_ONOFF			4
#define b2tEXP_STRENGTH			0
#define b2tEXP_ANGLE			1
#define b2tEXP_WIDTH			2
#define b2tEXP_HEIGHT			3

int b2tREXP_HEIGHT(LPRDATAT rdPtr,int param1);
int b2tREXP_WIDTH(LPRDATAT rdPtr,int param1);
int b2tREXP_ANGLE(LPRDATAT rdPtr,int param1);
int b2tREXP_STRENGTH(LPRDATAT rdPtr,int param1);
void b2tRACT_ONOFF(LPRDATAT rdPtr, int param1, int param2);
void b2tRACT_SETHEIGHT(LPRDATAT rdPtr, int param1, int param2);
void b2tRACT_SETWIDTH(LPRDATAT rdPtr, int param1, int param2);
void b2tRACT_SETANGLE(LPRDATAT rdPtr, int param1, int param2);
void b2tRACT_SETSTRENGTH(LPRDATAT rdPtr, int param1, int param2);
BOOL b2tRCND_ISACTIVE(LPRDATAT rdPtr, int param1, int param2);
short b2tHandleRunObject(LPRDATAT rdPtr);
short b2tDestroyRunObject(LPRDATAT rdPtr, int fast);
short b2tCreateRunObject(LPRDATAT rdPtr, CFile* file);
BOOL b2trStartObject(void* ptr);
LPRDATABASE b2tGetBase(LPRDATAT rdPtr);
void b2trRemoveObject(void* ptr, void* movement);
void b2trAddObject(void* ptr, void* move);

void b2trAddObject(void* ptr, void* move)
{
	CRunMBase* movement = (CRunMBase*)move;
	LPRDATAT rdPtr=(LPRDATAT)ptr;
	if (movement->m_identifier==rdPtr->identifier)
	{
		rdPtr->objects->Add(movement);
	}
}
void b2trRemoveObject(void* ptr, void* movement)
{
	LPRDATAT rdPtr=(LPRDATAT)ptr;
	rdPtr->objects->RemoveObject(movement);
}
LPRDATABASE b2tGetBase(LPRDATAT rdPtr)
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
BOOL b2trStartObject(void* ptr)
{
	LPRDATAT rdPtr=(LPRDATAT)ptr;
	if (rdPtr->base==nil)
	{
		rdPtr->base=b2tGetBase(rdPtr);
		if (rdPtr->base==nil)
		{
			return NO;
		}
	}
	return rdPtr->base->started;
}
short b2tCreateRunObject(LPRDATAT rdPtr, CFile* file)
{
	rdPtr->flags=[file readAInt];
	rdPtr->angle=(float)((float)[file readAInt]*b2_pi/16.0f);
	rdPtr->strengthBase=[file readAInt];
	rdPtr->strength=(float)(((float)rdPtr->strengthBase)/100.0);
	rdPtr->ho->hoImgWidth=[file readAInt];
	rdPtr->ho->hoImgHeight=[file readAInt];
	rdPtr->identifier=[file readAInt];

	rdPtr->base=nil;
	rdPtr->pAddObject=b2trAddObject;
	rdPtr->pRemoveObject=b2trRemoveObject;
	rdPtr->pStartObject=b2trStartObject;
	rdPtr->check=YES;
    rdPtr->objects = new CCArrayList();
    
	// No errors
	return 0;
}

// ----------------
// DestroyRunObject
// ----------------
// Destroys the run-time object
//
short b2tDestroyRunObject(LPRDATAT rdPtr, int fast)
{
    delete rdPtr->objects;
	return 0;
}


// ----------------
// HandleRunObject
// ----------------
short b2tHandleRunObject(LPRDATAT rdPtr)
{
	if (!b2trStartObject(rdPtr))
		return 0;
    
	if (rdPtr->flags&TMFLAG_ON)
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
						pMovement->SetVelocity(rdPtr->strength*cos(rdPtr->angle), rdPtr->strength*sin(rdPtr->angle));
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
						pMovement->SetVelocity(rdPtr->strength*cos(rdPtr->angle), rdPtr->strength*sin(rdPtr->angle));
					}
                    break;
				}
                case MTYPE_OBJECT:
				{
					LPHO pHo=pMovement->m_pHo;
					if (pHo->hoX>=rdPtr->ho->hoX && pHo->hoX<rdPtr->ho->hoX+rdPtr->ho->hoImgWidth && pHo->hoY>=rdPtr->ho->hoY && pHo->hoY<rdPtr->ho->hoY+rdPtr->ho->hoImgHeight)
					{
						pMovement->SetVelocity(rdPtr->strength*cos(rdPtr->angle), rdPtr->strength*sin(rdPtr->angle));
					}
                    break;
				}
			}
		}
	}
	return 0;
}

BOOL b2tRCND_ISACTIVE(LPRDATAT rdPtr, int param1, int param2)
{
	return (rdPtr->flags&TMFLAG_ON)!=0;
}

void b2tRACT_SETSTRENGTH(LPRDATAT rdPtr, int param1, int param2)
{
	rdPtr->strength=(float)(((float)param1)/100.0*0.1f);
	rdPtr->strengthBase=param1;
}
void b2tRACT_SETANGLE(LPRDATAT rdPtr, int param1, int param2)
{
	rdPtr->angle=(float)((float)param1*b2_pi/180.0f);
}
void b2tRACT_SETWIDTH(LPRDATAT rdPtr, int param1, int param2)
{
	if (param1>0)
		rdPtr->ho->hoImgWidth=(int)param1;
}
void b2tRACT_SETHEIGHT(LPRDATAT rdPtr, int param1, int param2)
{
	if (param1>0)
		rdPtr->ho->hoImgHeight=(int)param1;
}
void b2tRACT_ONOFF(LPRDATAT rdPtr, int param1, int param2)
{
	if (param1)
		rdPtr->flags|=TMFLAG_ON;
	else
		rdPtr->flags&=~TMFLAG_ON;
}

int b2tREXP_STRENGTH(LPRDATAT rdPtr,int param1)
{
	return rdPtr->strengthBase;
}
int b2tREXP_ANGLE(LPRDATAT rdPtr,int param1)
{
	return (int)(rdPtr->angle/b2_pi*180.0f);
}
int b2tREXP_WIDTH(LPRDATAT rdPtr,int param1)
{
	return rdPtr->ho->hoImgWidth;
}
int b2tREXP_HEIGHT(LPRDATAT rdPtr,int param1)
{
	return rdPtr->ho->hoImgHeight;
}

/////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation CRunBox2DTreadmill

-(int)getNumberOfConditions
{
	return b2tCND_LAST_TM;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    m_object = malloc(sizeof(RUNDATAT));
    
    LPRDATAT rdPtr = (LPRDATAT)m_object;
    rdPtr->rh = ho->hoAdRunHeader;
    rdPtr->ho = ho;
    b2tCreateRunObject(rdPtr, file);
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    b2tDestroyRunObject((LPRDATAT)m_object, bFast);
    free(m_object);
}

-(int)handleRunObject
{
	return b2tHandleRunObject((LPRDATAT)m_object);
}

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    LPRDATAT rdPtr = (LPRDATAT)m_object;
    return b2tRCND_ISACTIVE(rdPtr, 0, 0);
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
    LPRDATAT rdPtr = (LPRDATAT)m_object;
    switch (num)
    {
        case b2tACT_SETSTRENGTH:
            b2tRACT_SETSTRENGTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2tACT_SETANGLE:
            b2tRACT_SETANGLE(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2tACT_SETWIDTH:
            b2tRACT_SETWIDTH(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2tACT_SETHEIGHT:
            b2tRACT_SETHEIGHT(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
        case b2tACT_ONOFF:
            b2tRACT_ONOFF(rdPtr, [act getParamExpression:rh withNum:0], 0);
            break;
    }
}

-(CValue*)expression:(int)num
{
    LPRDATAT rdPtr = (LPRDATAT)m_object;
    
    int ret = 0;
    switch (num)
    {
        case b2tEXP_STRENGTH:
            ret = b2tREXP_STRENGTH(rdPtr, 0);
            break;
        case b2tEXP_ANGLE:
            ret = b2tREXP_ANGLE(rdPtr, 0);
            break;
        case b2tEXP_WIDTH:
            ret = b2tREXP_WIDTH(rdPtr, 0);
            break;
        case b2tEXP_HEIGHT:
            ret = b2tREXP_HEIGHT(rdPtr, 0);
            break;
    }
	return [rdPtr->rh getTempValue:ret];
}

@end
