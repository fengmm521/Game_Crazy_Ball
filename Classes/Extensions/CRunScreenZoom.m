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
//  CRunScreenZoom.m
//  RuntimeIPhone
//
//  Created by Francois Lionet on 07/10/13.
//  Copyright (c) 2013 Clickteam. All rights reserved.
//

#import "CRunScreenZoom.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CArrayList.h"
#import "CRunFrame.h"
#import "CServices.h"
#import "CActExtension.h"

@implementation CRunScreenZoom

-(int)getNumberOfConditions
{
	return CND_LAST;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    scAngleAnim=nil;
    scScaleAnim=nil;
    scScaleXAnim=nil;
    scScaleYAnim=nil;
    scShakeXAnim=nil;
    scShakeYAnim=nil;
    laAngleAnim=[[CArrayList alloc] init];
    laScaleAnim=[[CArrayList alloc] init];
    laScaleXAnim=[[CArrayList alloc] init];
    laScaleYAnim=[[CArrayList alloc] init];
    laShakeXAnim=[[CArrayList alloc] init];
    laShakeYAnim=[[CArrayList alloc] init];
    currentLayer=nil;

    [file skipBytes:8*2];
    
    rh->rhApp->scScaleX=[file readAFloat];
    rh->rhApp->scScaleY=[file readAFloat];
    rh->rhApp->scScale=(rh->rhApp->scScaleX+rh->rhApp->scScaleY)/2;
    [file skipBytes:8];
    rh->rhApp->scAngle=[file readAFloat];
    
    int temp;
    temp=[file readAInt];
    if (temp==0x07654321)
        temp=rh->rhApp->gaCxWin/2;
    rh->rhApp->scXSpot=temp;
    
    temp=[file readAInt];
    if (temp==0x07654321)
        temp=rh->rhApp->gaCyWin/2;
    rh->rhApp->scYSpot=temp;
    
    temp=[file readAInt];
    if (temp==0x07654321)
        temp=rh->rhApp->gaCxWin/2;
    rh->rhApp->scXDest=temp;
    
    temp=[file readAInt];
    if (temp==0x07654321)
        temp=rh->rhApp->gaCyWin/2;
    rh->rhApp->scYDest=temp;
    
	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
    [laAngleAnim clearRelease];
    [laAngleAnim release];
    [laScaleAnim clearRelease];
    [laScaleAnim release];
    [laScaleXAnim clearRelease];
    [laScaleXAnim release];
    [laScaleYAnim clearRelease];
    [laScaleYAnim release];
    [laShakeXAnim clearRelease];
    [laShakeXAnim release];
    [laShakeYAnim clearRelease];
    [laShakeYAnim release];
}

-(int)handleRunObject
{
    if (scAngleAnim != nil)
    {
        rh->rhApp->scAngle=[scAngleAnim animate];
        if (scAngleAnim->completed)
        {
            [scAngleAnim release];
            scAngleAnim=nil;
            [ho generateEvent:CND_SCANGLEOVER withParam:0];
        }
    }
    if (scScaleAnim != nil)
    {
        rh->rhApp->scScale=[scScaleAnim animate];
        rh->rhApp->scScaleX=rh->rhApp->scScale;
        rh->rhApp->scScaleY=rh->rhApp->scScale;
        if (scScaleAnim->completed)
        {
            [scScaleAnim release];
            scScaleAnim=nil;
            [ho generateEvent:CND_SCSCALEOVER withParam:0];
        }
    }
    if (scScaleXAnim != nil)
    {
        rh->rhApp->scScaleX=[scScaleXAnim animate];
        if (scScaleXAnim->completed)
        {
            [scScaleXAnim release];
            scScaleXAnim=nil;
            [ho generateEvent:CND_SCSCALEOVER withParam:0];
        }
    }
    if (scScaleYAnim != nil)
    {
        rh->rhApp->scScaleY=[scScaleYAnim animate];
        if (scScaleYAnim->completed)
        {
            [scScaleYAnim release];
            scScaleYAnim=nil;
            [ho generateEvent:CND_SCSCALEOVER withParam:0];
        }
    }
    if (scShakeXAnim != nil)
    {
        rh->rhApp->scXDest=(int)[scShakeXAnim animate];
        if (scShakeXAnim->completed)
        {
            [scShakeXAnim release];
            scShakeXAnim=nil;
            [ho generateEvent:CND_SCSHAKEOVER withParam:0];
        }
    }
    if (scShakeYAnim != nil)
    {
        rh->rhApp->scYDest=(int)[scShakeYAnim animate];
        if (scShakeYAnim->completed)
        {
            [scShakeYAnim release];
            scShakeYAnim=nil;
            [ho generateEvent:CND_SCSHAKEOVER withParam:0];
        }
    }
    
    int n;
    CRunScreenZoomAnim* anim;
    for (n=0; n<[laAngleAnim size]; n++)
    {
        anim=(CRunScreenZoomAnim*)[laAngleAnim get:n];
        anim->layer->angle=[anim animate];
        if (anim->completed)
        {
            [laAngleAnim removeIndexRelease:n];
            currentLayer=anim->layer;
            [ho generateEvent:CND_LAANGLEOVER withParam:0];
            n--;
        }
    }
    for (n=0; n<[laScaleAnim size]; n++)
    {
        anim=(CRunScreenZoomAnim*)[laScaleAnim get:n];
        anim->layer->scale=[anim animate];
        anim->layer->scaleX = anim->layer->scale;
        anim->layer->scaleY = anim->layer->scale;
        if (anim->completed)
        {
            [laScaleAnim removeIndexRelease:n];
            currentLayer=anim->layer;
            [ho generateEvent:CND_LASCALEOVER withParam:0];
            n--;
        }
    }
    for (n=0; n<[laScaleXAnim size]; n++)
    {
        anim=(CRunScreenZoomAnim*)[laScaleXAnim get:n];
        anim->layer->scaleX = [anim animate];
        if (anim->completed)
        {
            [laScaleXAnim removeIndexRelease:n];
            currentLayer=anim->layer;
            [ho generateEvent:CND_LASCALEOVER withParam:0];
            n--;
        }
    }
    for (n=0; n<[laScaleYAnim size]; n++)
    {
        anim=(CRunScreenZoomAnim*)[laScaleYAnim get:n];
        anim->layer->scaleY = [anim animate];
        if (anim->completed)
        {
            [laScaleYAnim removeIndexRelease:n];
            currentLayer=anim->layer;
            [ho generateEvent:CND_LASCALEOVER withParam:0];
            n--;
        }
    }
    for (n=0; n<[laShakeXAnim size]; n++)
    {
        anim=(CRunScreenZoomAnim*)[laShakeXAnim get:n];
        anim->layer->xDest = [anim animate];
        if (anim->completed)
        {
            [laShakeXAnim removeIndexRelease:n];
            currentLayer=anim->layer;
            [ho generateEvent:CND_LASHAKEOVER withParam:0];
            n--;
        }
    }
    for (n=0; n<[laShakeYAnim size]; n++)
    {
        anim=(CRunScreenZoomAnim*)[laShakeYAnim get:n];
        anim->layer->yDest = [anim animate];
        if (anim->completed)
        {
            [laShakeYAnim removeIndexRelease:n];
            currentLayer=anim->layer;
            [ho generateEvent:CND_LASHAKEOVER withParam:0];
            n--;
        }
    }
    return 0;    
}


// Conditions
// --------------------------------------------------

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
    switch (num)
    {
        case CND_SCANGLEOVER:
        case CND_SCSCALEOVER:
        case CND_SCSHAKEOVER:
            return YES;
        case CND_LAANGLEOVER:
        case CND_LASCALEOVER:
        case CND_LASHAKEOVER:
        {
            NSString* name=[cnd getParamExpString:rh withNum:0];
            return [name caseInsensitiveCompare:currentLayer->pName]==0;
        }
    }
	return NO;
}

// Actions
// -------------------------------------------------

-(CLayer*)getLayer:(NSString*)pName
{
    int nLayer;
    for (nLayer = 0; nLayer < rh->rhFrame->nLayers; nLayer++)
    {
        CLayer* pLayer = rh->rhFrame->layers[nLayer];
        if ([pName caseInsensitiveCompare:pLayer->pName]==0)
        {
            return pLayer;
        }
    }
    return nil;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
    CLayer* layer;
    CRunScreenZoomAnim* anim;
    switch (num)
    {
        case ACT_SCANGLE:
            rh->rhApp->scAngle=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCSCALE:
            rh->rhApp->scScale=[act getParamExpDouble:rh withNum:0];
            rh->rhApp->scScaleX=rh->rhApp->scScale;
            rh->rhApp->scScaleY=rh->rhApp->scScale;
            break;
        case ACT_SCXSCALE:
            rh->rhApp->scScaleX=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCYSCALE:
            rh->rhApp->scScaleY=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCPIVOT:
        {
			unsigned int position = [act getParamPosition:rh withNum:0];
            rh->rhApp->scXSpot=POSX(position);
            rh->rhApp->scYSpot=POSY(position);
            break;
        }
        case ACT_SCXPIVOT:
            rh->rhApp->scXSpot=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCYPIVOT:
            rh->rhApp->scYSpot=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCDEST:
        {
            unsigned int position = [act getParamPosition:rh withNum:0];
            rh->rhApp->scXDest=POSX(position);
            rh->rhApp->scYDest=POSY(position);
            break;
            
        }
        case ACT_SCXDEST:
            rh->rhApp->scYDest=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCYDEST:
            rh->rhApp->scYDest=[act getParamExpDouble:rh withNum:0];
            break;
        case ACT_SCLIANGLE:
            if (scAngleAnim)
                [scAngleAnim release];
            scAngleAnim=[[CRunScreenZoomAnimLinear alloc] initAnim:rh->rhApp->scAngle withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCLISCALE:
            if (scScaleAnim)
                [scScaleAnim release];
            scScaleAnim=[[CRunScreenZoomAnimLinear alloc] initAnim:rh->rhApp->scScale withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCLIXSCALE:
            if (scScaleXAnim)
                [scScaleXAnim release];
            scScaleXAnim=[[CRunScreenZoomAnimLinear alloc] initAnim:rh->rhApp->scScaleX withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCLIYSCALE:
            if (scScaleYAnim)
                [scScaleYAnim release];
            scScaleYAnim=[[CRunScreenZoomAnimLinear alloc] initAnim:rh->rhApp->scScaleY withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCSMANGLE:
            if (scAngleAnim)
                [scAngleAnim release];
            scAngleAnim=[[CRunScreenZoomAnimSmooth alloc] initAnim:rh->rhApp->scAngle withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCSMSCALE:
            if (scScaleAnim)
                [scScaleAnim release];
            scScaleAnim=[[CRunScreenZoomAnimSmooth alloc] initAnim:rh->rhApp->scScale withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCSMXSCALE:
            if (scScaleXAnim)
                [scScaleXAnim release];
            scScaleXAnim=[[CRunScreenZoomAnimSmooth alloc] initAnim:rh->rhApp->scScaleX withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCSMYSCALE:
            if (scScaleYAnim)
                [scScaleYAnim release];
            scScaleYAnim=[[CRunScreenZoomAnimSmooth alloc] initAnim:rh->rhApp->scScaleY withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1]];
            break;
        case ACT_SCELANGLE:
            if (scAngleAnim)
                [scAngleAnim release];
            scAngleAnim=[[CRunScreenZoomAnimElastic alloc] initAnim:rh->rhApp->scAngle withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1] andFactor:[act getParamExpDouble:rh withNum:2]];
            break;
        case ACT_SCELSCALE:
            if (scScaleAnim)
                [scScaleAnim release];
            scScaleAnim=[[CRunScreenZoomAnimElastic alloc] initAnim:rh->rhApp->scScale withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1] andFactor:[act getParamExpDouble:rh withNum:2]];
            break;
        case ACT_SCELXSCALE:
            if (scScaleXAnim)
                [scScaleXAnim release];
            scScaleXAnim=[[CRunScreenZoomAnimElastic alloc] initAnim:rh->rhApp->scScaleX withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1] andFactor:[act getParamExpDouble:rh withNum:2]];
            break;
        case ACT_SCELYSCALE:
            if (scScaleYAnim)
                [scScaleYAnim release];
            scScaleXAnim=[[CRunScreenZoomAnimElastic alloc] initAnim:rh->rhApp->scScaleY withEnd:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1] andFactor:[act getParamExpDouble:rh withNum:2]];
            break;
        case ACT_SCSHAKEX:
            if (scShakeXAnim)
                [scShakeXAnim release];
            scShakeXAnim=[[CRunScreenZoomAnimShake alloc] initAnim:rh->rhApp->scXDest withLength:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1] andTotal:[act getParamExpDouble:rh withNum:2]];
            break;
        case ACT_SCSHAKEY:
            if (scShakeYAnim)
                [scShakeYAnim release];
            scShakeYAnim=[[CRunScreenZoomAnimShake alloc] initAnim:rh->rhApp->scYDest withLength:[act getParamExpDouble:rh withNum:0] andDuration:[act getParamExpDouble:rh withNum:1] andTotal:[act getParamExpDouble:rh withNum:2]];
            break;
            
            
        case ACT_LAANGLE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->angle = [act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LASCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->scale=[act getParamExpDouble:rh withNum:1];
                layer->scaleX = layer->scale;
                layer->scaleY = layer->scale;
            }
            break;
        case ACT_LAXSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->scaleX =[act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LAYSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->scaleY = [act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LAPIVOT:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                unsigned int position=[act getParamPosition:rh withNum:1];
                layer->xSpot = POSX(position);
                layer->ySpot = POSY(position);
            }
            break;
        case ACT_LAXPIVOT:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->xSpot = [act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LAYPIVOT:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->ySpot = [act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LADEST:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                unsigned int position=[act getParamPosition:rh withNum:1];
                layer->xDest = POSX(position);
                layer->yDest = POSY(position);
            }
            break;
        case ACT_LAXDEST:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->xDest = [act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LAYDEST:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                layer->yDest = [act getParamExpDouble:rh withNum:1];
            }
            break;
        case ACT_LALIANGLE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimLinear alloc] initAnim:layer->angle withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laAngleAnim add:anim];
            }
            break;
        case ACT_LALISCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimLinear alloc] initAnim:layer->scale withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laScaleAnim add:anim];
            }
            break;
        case ACT_LALIXSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimLinear alloc] initAnim:layer->scaleX withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laScaleXAnim add:anim];
            }
            break;
        case ACT_LALIYSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimLinear alloc] initAnim:layer->scaleY withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laScaleYAnim add:anim];
            }
            break;
        case ACT_LASMANGLE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimSmooth alloc] initAnim:layer->angle withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laAngleAnim add:anim];
            }
            break;
        case ACT_LASMSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimSmooth alloc] initAnim:layer->scale withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laScaleAnim add:anim];
            }
            break;
        case ACT_LASMXSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimSmooth alloc] initAnim:layer->scaleX withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laScaleXAnim add:anim];
            }
            break;
        case ACT_LASMYSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimSmooth alloc] initAnim:layer->scaleY withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2]];
                anim->layer=layer;
                [laScaleYAnim add:anim];
            }
            break;
        case ACT_LAELANGLE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimElastic alloc] initAnim:layer->angle withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2] andFactor:[act getParamExpDouble:rh withNum:3]];
                anim->layer=layer;
                [laAngleAnim add:anim];
            }
            break;
        case ACT_LAELSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimElastic alloc] initAnim:layer->scale withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2] andFactor:[act getParamExpDouble:rh withNum:3]];
                anim->layer=layer;
                [laScaleAnim add:anim];
            }
            break;
        case ACT_LAELXSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimElastic alloc] initAnim:layer->scaleX withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2] andFactor:[act getParamExpDouble:rh withNum:3]];
                anim->layer=layer;
                [laScaleXAnim add:anim];
            }
            break;
        case ACT_LAELYSCALE:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimElastic alloc] initAnim:layer->scaleY withEnd:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2] andFactor:[act getParamExpDouble:rh withNum:3]];
                anim->layer=layer;
                [laScaleYAnim add:anim];
            }
            break;
        case ACT_LASHAKEX:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimShake alloc] initAnim:layer->xDest withLength:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2] andTotal:[act getParamExpDouble:rh withNum:3]];
                anim->layer=layer;
                [laShakeXAnim add:anim];
            }
            break;
        case ACT_LASHAKEY:
            layer=[self getLayer:[act getParamExpString:rh withNum:0]];
            if (layer != nil)
            {
                anim=[[CRunScreenZoomAnimShake alloc] initAnim:layer->yDest withLength:[act getParamExpDouble:rh withNum:1] andDuration:[act getParamExpDouble:rh withNum:2] andTotal:[act getParamExpDouble:rh withNum:3]];
                anim->layer=layer;
                [laShakeYAnim add:anim];
            }
            break;
    }
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	CValue* ret=[rh getTempValue:0];
    CLayer* layer;
    switch (num)
    {
        case EXP_SCANGLE:
            [ret forceDouble:rh->rhApp->scAngle];
            break;
        case EXP_SCXSCALE:
            [ret forceDouble:rh->rhApp->scScaleX];
            break;
        case EXP_SCYSCALE:
            [ret forceDouble:rh->rhApp->scScaleY];
            break;
        case EXP_SCXPIVOT:
            [ret forceInt:rh->rhApp->scXSpot];
            break;
        case EXP_SCYPIVOT:
            [ret forceInt:rh->rhApp->scYSpot];
            break;
        case EXP_SCSCALE:
            [ret forceDouble:rh->rhApp->scScale];
            break;
        case EXP_SCXDEST:
            [ret forceInt:rh->rhApp->scYDest];
            break;
        case EXP_SCYDEST:
            [ret forceInt:rh->rhApp->scYDest];
            break;
            
        case EXP_LAANGLE:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceDouble:layer->angle];
            break;
        case EXP_LAXSCALE:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceDouble:layer->scaleX];
            break;
        case EXP_LAYSCALE:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceDouble:layer->scaleY];
            break;
        case EXP_LAXPIVOT:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceInt:layer->xSpot];
            break;
        case EXP_LAYPIVOT:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceInt:layer->ySpot];
            break;
        case EXP_LASCALE:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceDouble:layer->scale];
            break;
        case EXP_LAXDEST:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceInt:layer->xDest];
            break;
        case EXP_LAYDEST:
            layer=[self getLayer:[[ho getExpParam] getString]];
            if (layer != nil)
                [ret forceInt:layer->yDest];
            break;
    }
    return ret;

	return nil;
}

@end


// ANIMATION CLASSES
//////////////////////////////////////////////////////////////////////////////////

@implementation CRunScreenZoomAnim

-(float)animate
{
    return 0;
}

@end

@implementation CRunScreenZoomAnimLinear

-(id)initAnim:(float)i withEnd:(float)e andDuration:(double)d
{
    if (self=[super init])
	{
        initial = i;
        end = e;
        current = initial;
        duration = d;
        initialTime = CFAbsoluteTimeGetCurrent()*1000;
        completed = NO;
        
	}
	return self;
}
-(float)animate
{
    double delta=CFAbsoluteTimeGetCurrent()*1000-initialTime;
    if (delta>=duration)
    {
        completed=YES;
        current=end;
    }
    else
    {
        current=initial+((end-initial)*delta)/duration;
    }
    return current;
}

@end

@implementation CRunScreenZoomAnimSmooth

-(id)initAnim:(float)i withEnd:(float)e andDuration:(double)d
{
    if (self=[super init])
	{
        middle=(e+i)/2;
        length=(e-i)/2;
        end=e;
        duration=d;
        current=i;
        initialTime=CFAbsoluteTimeGetCurrent()*1000;
        completed=NO;
	}
	return self;
}
-(float)animate
{
    double delta=CFAbsoluteTimeGetCurrent()*1000-initialTime;
    if (delta>=duration)
    {
        completed=YES;
        current=end;
    }
    else
    {
        double angle=(delta/duration)*_PI;
        current=(float)(middle+length*(-cos(angle)));
    }
    return current;
}

@end

@implementation CRunScreenZoomAnimElastic

-(id)initAnim:(float)i withEnd:(float)e andDuration:(double)d andFactor:(double)f
{
    if (self=[super init])
	{
        middle=(i+e)/2;
        end=e;
        duration=d;
        length=e-i;
        factor=(float)(1/MAX(f, 1.0));
        current=i;
        initialTime=CFAbsoluteTimeGetCurrent()*1000;
        completed=NO;
        position = 0;
	}
	return self;
}
-(float)animate
{
    double delta=CFAbsoluteTimeGetCurrent()*1000-initialTime;
    double angle=(delta/duration)*_PI/2;
    
    if (angle>=_PI/2)
    {
        if (position==0 || position==2)
        {
            length*=factor;
            duration*=factor;
            if (duration<10)
            {
                completed=YES;
                current=end;
                return current;
            }
        }
        position=(position+1)%4;
        initialTime=CFAbsoluteTimeGetCurrent()*1000;
        angle=0;
    }
    current=(float)(end-length*cos(angle+position*_PI/2));
    return current;
}

@end

@implementation CRunScreenZoomAnimShake

-(id)initAnim:(float)m withLength:(float)l andDuration:(double)d andTotal:(double)t
{
    if (self=[super init])
	{
        middle=m;
        length=l;
        total = t;
        duration=d;
        initialTime=CFAbsoluteTimeGetCurrent()*1000;
        completed=NO;
	}
	return self;
}
-(float)animate
{
    double delta=CFAbsoluteTimeGetCurrent()*1000-initialTime;
    double angle=(delta/duration)*_PI*2;
    
    if (CFAbsoluteTimeGetCurrent()*1000>initialTime+total)
    {
        completed=YES;
        current=middle;
        return current;
    }
    current=(float)(middle+length*sin(angle));
    return current;
}

@end

