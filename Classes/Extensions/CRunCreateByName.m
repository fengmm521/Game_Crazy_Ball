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

#import "CRunCreateByName.h"
#import "CExtension.h"
#import "CActExtension.h"
#import "CRunApp.h"
#import "CRun.h"
#import "CValue.h"
#import "CArrayList.h"
#import "CServices.h"
#import "CObjInfo.h"
#import "CRunFrame.h"
#import "CLayer.h"
#import "CLO.h"
#import "CLOList.h"
#import "COIList.h"
#import "COI.h"
#import "COC.h"
#import "COCBackground.h"
#import "CBkd2.h"
#import "CSpriteGen.h"
#import "CObjectCommon.h"
#import "CSprite.h"

#define ACT_CREATEOBJ_AT_POS 0
#define ACT_CREATEOBJ_AT_XY 1
#define ACT_CREATEBKD_AT_POS 2
#define ACT_CREATEBKD_AT_XY 3
#define EXP_GETNAMEFROMFIXED 0

@implementation CRunCreateByName

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_CREATEOBJ_AT_POS:
		{
			NSString* name = [act getParamExpString:rh withNum:0];
			unsigned int position = [act getParamPosition:rh withNum:1];
			int layer = [act getParamExpression:rh withNum:2];
			[self createObject:name atX:POSX(position) andY:POSY(position) atLayer:layer];
			break;
		}
		case ACT_CREATEOBJ_AT_XY:
		{
			NSString* name = [act getParamExpString:rh withNum:0];
			int x = [act getParamExpression:rh withNum:1];
			int y = [act getParamExpression:rh withNum:2];
			int layer = [act getParamExpression:rh withNum:3];
			[self createObject:name atX:x andY:y atLayer:layer];
			break;
		}
		case ACT_CREATEBKD_AT_POS:
		{
			NSString* name = [act getParamExpString:rh withNum:0];
			unsigned int position = [act getParamPosition:rh withNum:1];
			int type = [act getParamExpression:rh withNum:2];
			int layer = [act getParamExpression:rh withNum:3];
			[self createBackdrop:name atX:POSX(position) andY:POSY(position) type:type atLayer:layer];
			break;
		}
		case ACT_CREATEBKD_AT_XY:
		{
			NSString* name = [act getParamExpString:rh withNum:0];
			int x = [act getParamExpression:rh withNum:1];
			int y = [act getParamExpression:rh withNum:2];
			int type = [act getParamExpression:rh withNum:3];
			int layer = [act getParamExpression:rh withNum:4];
			[self createBackdrop:name atX:x andY:y type:type atLayer:layer];
			break;
		}
	}
}

-(CValue*)expression:(int)num
{
	if(num == EXP_GETNAMEFROMFIXED)
	{
		int fixed = [[ho getExpParam] getInt];
		CObject* obj = [self->ho getObjectFromFixed:fixed];
		if(obj != nil)
			return [rh getTempString:obj->hoCommon->pCOI->oiName];
	}
	return [rh getTempString:@""];
}


-(void)createObject:(NSString*)objName atX:(int)x andY:(int)y atLayer:(int)layer
{
	CObjInfo** list = rh->rhOiList;
	int num = rh->rhMaxOI;
	short creationOi = -1;
	
	for(int i=0; i<num; ++i)
	{
		CObjInfo* info = list[i];
		if([info->oilName isEqualToString:objName])
		{
			creationOi = info->oilOi;
			break;
		}
	}
	if(creationOi == -1)
		return;

	//Create the event buffer (with plenty space):
	int bufferSize = sizeof(event)+sizeof(eventParam)+sizeof(CreateDuplicateParam);
	char* buffer = (char*)calloc(bufferSize, sizeof(char));
	
	if(layer >= rh->rhFrame->nLayers)
		layer = rh->rhFrame->nLayers-1;
	if(layer < -1)
		layer = -1;
	
	//The event that should be passed to the CreateObject routine
	event* evt = (event*)&buffer[0];
	
	//Resides at event+14
	eventParam* creationParams = (eventParam*)((char*)buffer+ACT_SIZE);
	
	//The object creation parameters
	CreateDuplicateParam* cdp = (CreateDuplicateParam*)&creationParams->evp.evpW.evpW0;
	
	cdp->cdpHFII = rh->rhMaxOI;
	cdp->cdpOi = creationOi;
	
	PositionParam pos = {0};
	pos.posX = x;
	pos.posY = y;
	pos.posLayer = layer;
	pos.posOINUMParent = -1;
	pos.posFlags |= CPF_DEFAULTDIR;
	cdp->cdpPos = pos;
	
	//Call the routine
	actCreateObject(evt,rh);
	
	free(buffer);
}

-(void)createBackdrop:(NSString*)objName atX:(int)x andY:(int)y type:(int)type atLayer:(int)layer
{
	CRunFrame* frame = rh->rhFrame;
	
	// Find backdrop
	for(int i=0; i<frame->nLayers; ++i)
	{
		CLayer* clayer = frame->layers[i];
		for(int j=0; j<clayer->nBkdLOs; ++j)
		{
			CLO* plo = [frame->LOList getLOFromIndex:clayer->nFirstLOIndex+j];
			COI* info = [rh->rhApp->OIList getOIFromHandle:plo->loOiHandle];
			
			if([info->oiName isEqualToString:objName])
			{
				COCBackground* backdrop = (COCBackground*)info->oiOC;
				short image = backdrop->ocImage;
				
				CBkd2* toadd = [[CBkd2 alloc] initWithCRun:rh];
				toadd->img = image;
				toadd->loHnd = 0;
				toadd->oiHnd = 0;
				toadd->x = x;
				toadd->y = y;
				toadd->nLayer = layer;
				toadd->obstacleType = (short)type;
				toadd->colMode = CM_BITMAP;
				toadd->pSpr[0] = toadd->pSpr[1] = toadd->pSpr[2] = toadd->pSpr[3] = nil;
				toadd->inkEffect = 0;
				toadd->inkEffectParam = 0;
				toadd->spriteFlag = SF_NOHOTSPOT;
				[rh addBackdrop2:toadd];
				break;
			}
		}
	}
}


@end
