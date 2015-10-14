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
//----------------------------------------------------------------------------------
//
// CRUNMultipleTOuch
//
//----------------------------------------------------------------------------------
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CRunView.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CEventProgram.h"
#import "CEvents.h"
#import "CActExtension.h"
#import "CRCom.h"
#import "CRunMultipleTouch.h"

#define CND_NEWTOUCH 0
#define CND_ENDTOUCH 1
#define CND_NEWTOUCHANY 2
#define CND_ENDTOUCHANY 3
#define CND_TOUCHMOVED 4
#define CND_TOUCHACTIVE 5
#define	CND_NEWTOUCHOBJECT 6
#define	CND_TOUCHACTIVEOBJECT 7
#define CND_NEWPITCH 8
#define CND_PITCHACTIVE 9
#define CND_NEWGESTURE 10
#define CND_LAST 11

#define ACT_SETORIGINX 0
#define ACT_SETORIGINY 1
#define ACT_RECOGNIZE 2
#define	ACT_SETRECOGNITION 3
#define ACT_SETZONE	4
#define ACT_SETZONECOORD 5
#define ACT_LOADINI	6
#define ACT_RECOGNIZEG 7
#define ACT_CLEARGESTURES 8

#define EXP_GETNUMBER 0
#define EXP_GETLAST 1
#define EXP_MTGETX 2
#define EXP_MTGETY 3
#define EXP_GETLASTNEWTOUCH 4
#define EXP_GETLASTENDTOUCH 5
#define EXP_GETORIGINX 6
#define EXP_GETORIGINY 7
#define EXP_GETDELTAX 8
#define EXP_GETDELTAY 9
#define EXP_GETTOUCHANGLE 10
#define EXP_GETDISTANCE 11
#define EXP_PITCHDISTANCE 12
#define EXP_PITCHANGLE 13
#define EXP_PITCHPERCENTAGE 14
#define EXP_RECOGNIZEDNAME 15
#define EXP_RECOGNIZEDPERCENT 16

@implementation CRunMultipleTouch

-(int)getNumberOfConditions
{
	return CND_LAST;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
    ho->hoImgWidth=[file readAShort];
    ho->hoImgHeight=[file readAShort];
    flags=[file readAInt];
    depth=[file readAShort];
    
	newTouchCount=-1;
	endTouchCount=-1;
	movedTouchCount=-1;
    newGestureCount=-1;
	lastNewTouch=-1;
	lastEndTouch=-1;
    lastTouch=-1;
    touchArray=nil;
    pitch1=-1;
    pitch2=-1;
    touchCaptured=-1;
    
	NSString* text=[file readAString];
    if (flags&MTFLAG_RECOGNITION)
    {
        [self createRecognizer];
        CArrayList* strings=[[CArrayList alloc] init];
        [self getStrings:text withArrayList:strings];
        [self addGestures:strings];
        [strings clearRelease];
        [strings release];
        touchArray=[[CArrayList alloc] init];
    }
    
	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
        touches[n].touche=nil;
        touches[n].x=-1;
        touches[n].y=-1;
        touches[n].tNew=0;
        touches[n].tEnd=0;
        touches[n].startX=0;
        touches[n].startY=0;
        touches[n].dragX=0;
		touches[n].dragY=0;
	}
    gestureName=[[NSString alloc] initWithString:@""];
    gesturePercent=0;
    
	ho->hoAdRunHeader->rhApp->touches=self;
	return YES;
}
-(void)destroyRunObject:(BOOL)bFast
{
	ho->hoAdRunHeader->rhApp->touches=nil;
    [gestureName release];
    if (touchArray!=nil)
    {
        [touchArray clearRelease];
        [touchArray release];
    }
}
-(int)handleRunObject
{
	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
		if (touches[n].tNew>0)
		{
			touches[n].tNew--;
		}
		if (touches[n].tEnd>0)
		{
			touches[n].tEnd--;
		}
	}
	return 0;
}


-(void)resetTouches
{
	for (int n=0; n<MAX_TOUCHES; n++)
	{
		if(touches[n].touche != nil)
		{
			touches[n].touche=nil;
			touches[n].tEnd=2;
			lastTouch=n;
			lastEndTouch=n;
			endTouchCount=[ho getEventCount];
			[ho generateEvent:CND_ENDTOUCH withParam:0];
			[ho generateEvent:CND_ENDTOUCHANY withParam:0];
		}
	}
}


-(int)getDistance
{
	if (pitch1>=0 && pitch2>=0)
	{
	    int deltaX=touches[pitch2].x-touches[pitch1].x;
	    int deltaY=touches[pitch2].y-touches[pitch1].y;
        return (int)sqrt((double)(deltaX*deltaX+deltaY*deltaY));
	}
    return -1;
}

-(BOOL)touchBegan:(UITouch*)touch
{
	CRun* run = ho->hoAdRunHeader;
	CRunApp* rhApp = run->rhApp;

	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
		if (touches[n].touche==touch)
		{
			break;
		}
		if (touches[n].touche==nil)
		{
			break;
		}
	}
	if (n<MAX_TOUCHES && touches[n].touche==nil)
	{
		touches[n].touche=touch;
		CGPoint position = [touch locationInView:rhApp->runView];
        int x=position.x;
        int y=position.y;
		touches[n].x=x;
		touches[n].y=y;
		touches[n].dragX=x;
		touches[n].dragY=y;
		touches[n].startX=x;
		touches[n].startY=y;
		touches[n].tNew=2;
		lastTouch=n;
		lastNewTouch=n;
		newTouchCount=[ho getEventCount];

		int touchX = (x + run->rhWindowX) - rhApp->parentX;
		int touchY = (y + run->rhWindowY) - rhApp->parentY;
        [self callObjectConditions:touchX withY:touchY];
        
		if (pitch1<0)
		{
			pitch1=n;
		}
		else if (pitch2<0)
		{
			pitch2=n;
			[ho generateEvent:CND_NEWPITCH withParam:0];
			newPitchCount=[ho getEventCount];
			pitchDistance=[self getDistance];
		}
		else
		{
			pitch1=-1;
			pitch2=-1;
		}
        
		if ((flags&MTFLAG_RECOGNITION)!=0)
		{
            if ([touchArray size]>=depth)
            {
                [(CArrayList*)[touchArray get:0] release];
                [touchArray removeIndex:0];
            }
            CArrayList* touchs=[[CArrayList alloc] init];
            [touchArray add:touchs];
			if (x>=ho->hoX && x<ho->hoX+ho->hoImgWidth && y>=ho->hoY && y<ho->hoY+ho->hoImgHeight)
			{
				touches[n].xPrevious=x;
				touches[n].yPrevious=y;
				x-=ho->hoX;
				y-=ho->hoY;
				[touchs addInt:x];
				[touchs addInt:y];
				touchCaptured=n;
			}
		}        	

        [ho generateEvent:CND_NEWTOUCH withParam:0];
		[ho generateEvent:CND_NEWTOUCHANY withParam:0];

	}
	return YES;
}

-(void)touchMoved:(UITouch*)touch
{
	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
		if (touches[n].touche==touch)
		{
			CGPoint position = [touch locationInView:ho->hoAdRunHeader->rhApp->runView];
            int x=position.x;
            int y=position.y;
			touches[n].x=x;
			touches[n].y=y;
			touches[n].dragX=x;
			touches[n].dragY=y;
			lastTouch=n;
            
            if ((flags&MTFLAG_RECOGNITION)!=0 && n==touchCaptured)
		    {
		        if (x!=touches[n].xPrevious || y!=touches[n].yPrevious)
		        {
		        	touches[n].xPrevious=x;
		        	touches[n].yPrevious=y;
                    if (x>=ho->hoX && x<ho->hoX+ho->hoImgWidth && y>=ho->hoY && y<ho->hoY+ho->hoImgHeight)
                    {
                        x-=ho->hoX;
                        y-=ho->hoY;
                        [(CArrayList*)[touchArray get:[touchArray size]-1] addInt:x];
                        [(CArrayList*)[touchArray get:[touchArray size]-1] addInt:y];
                    }
		        }
		    }
			[ho generateEvent:CND_TOUCHMOVED withParam:0];
		}
	}
}
-(void)touchEnded:(UITouch*)touch
{
	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
		if (touches[n].touche==touch)
		{
			CGPoint position = [touch locationInView:ho->hoAdRunHeader->rhApp->runView];
            int x=position.x;
            int y=position.y;
			touches[n].x=x;
			touches[n].y=y;
			touches[n].dragX=x;
			touches[n].dragY=y;
			touches[n].touche=nil;
			touches[n].tEnd=2;
			lastTouch=n;
			lastEndTouch=n;
			endTouchCount=[ho getEventCount];
            
            if (n==pitch1)
		        pitch1=-1;
		    else if (n==pitch2)
		        pitch2=-1;
		    
		    if ((flags&MTFLAG_RECOGNITION)!=0 && n==touchCaptured)
		    {
				touchCaptured=-1;
		        if (x!=touches[n].xPrevious || y!=touches[n].yPrevious)
		        {
                    if (x>=ho->hoX && x<ho->hoX+ho->hoImgWidth && y>=ho->hoY && y<ho->hoY+ho->hoImgHeight)
                    {
                        x-=ho->hoX;
                        y-=ho->hoY;
                        [(CArrayList*)[touchArray get:[touchArray size]-1] addInt:x];
                        [(CArrayList*)[touchArray get:[touchArray size]-1] addInt:y];
                    }
			    }
		    }
			[ho generateEvent:CND_ENDTOUCH withParam:0];
			[ho generateEvent:CND_ENDTOUCHANY withParam:0];
		}
	}
}
-(void)touchCancelled:(UITouch*)touch
{
	[self touchEnded:touch];
}
                            

-(void)createRecognizer
{
    if ((flags&MTFLAG_RECOGNITION)!=0)
    {
        if (recognizer==NULL)
        {
            recognizer=[[PDollarRecognizer alloc] init];
        }
    }
}

-(void)getStrings:(NSString*)text withArrayList:(CArrayList*)pStrings
{
    int end = 0;
    NSRange range, pEnd1, pEnd2, r;
    range.location=0;
    while(range.location<[text length])
    {
        range.length=[text length]-range.location;
        pEnd1=[text rangeOfString:@"\n" options:NSLiteralSearch range:range];
        pEnd2=[text rangeOfString:@"\r" options:NSLiteralSearch range:range];
        if (pEnd1.location==NSNotFound)
            pEnd1.location=[text length];
        if (pEnd2.location==NSNotFound)
            pEnd2.location=[text length];
        end=(int)MIN(pEnd1.location, pEnd2.location);
        r.location=range.location;
        r.length=end-r.location;
        NSString* pString=[[NSString alloc] initWithString:[text substringWithRange:r]];
        [pStrings add:pString];
        range.location=MAX(pEnd1.location, pEnd2.location)+1;
    }	    	    	    
}
                            

-(void)addGestures:(CArrayList*)strings
{
    int number;
    int line=0;
    CArrayList* points=[[CArrayList alloc] init];
    NSString* name = nil;
    NSString* pString = nil;
    NSString* temp = nil;
    NSRange range, range2;
    while(TRUE)
    {
        for (; line<[strings size]; line++)
        {
            pString=(NSString*)[strings get:line];
            range=[pString rangeOfString:@"["];
            if (range.location!=NSNotFound)
            {
                range.location++;
                break;
            }
        }
        if (line>=[strings size])
            break;
        range2=[pString rangeOfString:@"]"];
        if (range2.location==NSNotFound)
            continue;
        range.length=range2.location-range.location;
        name=[NSString stringWithString:[pString substringWithRange:range]];
        
        [points clearRelease];
        for (line++, number=0; line<[strings size]; number++, line++)
        {
            pString=(NSString*)[strings get:line];
            
            range=[pString rangeOfString:@"="];
            if (range.location==NSNotFound)
                break;
            range.location++;
            
            NSRange pBracket, pComma;
            int x, y;
            while(TRUE)
            {
                range.length=[pString length]-range.location;
                pBracket=[pString rangeOfString:@"(" options:NSLiteralSearch range:range];
                if (pBracket.location==NSNotFound)
                    break;
                range.location=pBracket.location+1;
                range.length=[pString length]-range.location;
                pComma=[pString rangeOfString:@"," options:NSLiteralSearch range:range];
                if (pComma.location==NSNotFound)
                    break;
                range2.location=pBracket.location+1;
                range2.length=pComma.location-range.location;
                temp=[NSString stringWithString:[pString substringWithRange:range2]];
                x=[temp intValue];
                
                range.location=pComma.location+1;
                range.length=[pString length]-range.location;
                pBracket=[pString rangeOfString:@")" options:NSLiteralSearch range:range];
                if (pBracket.location==NSNotFound)
                    break;
                range2.location=pComma.location+1;
                range2.length=pBracket.location-range2.location;
                temp=[NSString stringWithString:[pString substringWithRange:range2]];
                y=[temp intValue];

                [points add: [[GPoint alloc] initWithX:x andY:y andID:number]];
                range.location=pBracket.location;
            }
        }
        [recognizer AddGesture:name withPoints:points];
    }
    [points clearRelease];
}
            
-(void)recognize:(int)d withName:(NSString*)name
{
	[self createRecognizer];
    
	int position;
	CArrayList* points=[[CArrayList alloc] init];
    
	for (position=0; position<d; position++)
	{
		if (position>=[touchArray size])
			break;
        
		CArrayList* t=(CArrayList*)[touchArray get:[touchArray size]-position-1];
		int n;
		int count=0;
		for (n=0; n<[t size]/2; n++)
		{
			[points add:[[GPoint alloc] initWithX:[t getInt:n*2] andY:[t getInt:n*2+1] andID:position]];
			count++;
		}
	}
    
	if ([points size]>1)
	{
		[recognizer Recognize:points withName:name];
		gestureNumber=recognizer->gestureNumber;
		gesturePercent=recognizer->gesturePercent;
		[gestureName release];
		gestureName=[[NSString alloc] initWithString:recognizer->gestureName];
		if (gestureNumber>=0)
		{
			newGestureCount = [ho getEventCount];
			[ho generateEvent:CND_NEWGESTURE withParam:0];
		}
	}
    else
    {
        gesturePercent=0;
        [gestureName release];
        gestureName=[[NSString alloc] initWithString:@""];
    }
    [points clearRelease];
    [points release];
}

-(void)callObjectConditions:(int)x withY:(int)y
{
	CArrayList* list=[[CArrayList alloc] init];
    CObject* pHox;
    int count=0;
    do
    {
        while(rh->rhObjectList[count]==nil)
			count++;
        pHox = rh->rhObjectList[count];
        count++;
        if ([self isObjectUnder:pHox withX:x andY:y])
        {
            [list add:pHox];
        }
    } while (count < rh->rhNObjects);
    
    for (count=0; count<[list size]; count++)
    {
        pHox=(CObject*)[list get:count];
        OiUnder=pHox->hoOi;
        hoUnder=(pHox->hoCreationId << 16) | (pHox->hoNumber & 0xFFFF);
        [ho generateEvent:CND_NEWTOUCHOBJECT withParam:0];
    }
    [list release];
}

-(BOOL)isActiveRoutine:(int)touch withOiList:(short)oiList
{
    BOOL result=NO;
    
    if (touch>=0 && touch<MAX_TOUCHES)
    {
	    if (touches[touch].touche!=nil)
	    {
            CEventProgram* evtProg=rh->rhEvtProg;
			CObject* rh2EventPrev=evtProg->rh2EventPrev;
			CObject* rh2EventPos = evtProg->rh2EventPos;
			int rh2EventPosOiList = evtProg->rh2EventPosOiList;
			CQualToOiList* rh2EventQualPos=evtProg->rh2EventQualPos;
            CObjInfo* rh2EventPrevOiList=evtProg->rh2EventPrevOiList;
            int evtNSelectedObjects=evtProg->evtNSelectedObjects;
            
            CObject* pHo=[evtProg evt_FirstObject:oiList];
            if (pHo!=NULL)
			{
				int x=touches[touch].x;
				int y=touches[touch].y;
                int count=evtProg->evtNSelectedObjects;
                
                do
                {
                    if (![self isObjectUnder:pHo withX:x andY:y])
                    {
                        count--;
                        [evtProg evt_DeleteCurrentObject];
                    }
                    pHo=[evtProg evt_NextObject];
                } while (pHo!=nil);
                result=(count!=0);
            }
            evtProg->evtNSelectedObjects=evtNSelectedObjects;
            evtProg->rh2EventPrev=rh2EventPrev;
            evtProg->rh2EventPosOiList=rh2EventPosOiList;
            evtProg->rh2EventPos=rh2EventPos;
            evtProg->rh2EventQualPos=rh2EventQualPos;
            evtProg->rh2EventPrevOiList=rh2EventPrevOiList;
        }
    }
    return result;
}
-(BOOL)selectObjectByFixedValue:(short)oiList withHoFV:(int)hoFV
{
    BOOL result=NO;
    
    CEventProgram* evtProg=rh->rhEvtProg;
	CObject* rh2EventPrev=evtProg->rh2EventPrev;
	CObject* rh2EventPos = evtProg->rh2EventPos;
	int rh2EventPosOiList = evtProg->rh2EventPosOiList;
	CQualToOiList* rh2EventQualPos=evtProg->rh2EventQualPos;
    CObjInfo* rh2EventPrevOiList=evtProg->rh2EventPrevOiList;
    int evtNSelectedObjects=evtProg->evtNSelectedObjects;
            
    CObject* pHo=[evtProg evt_FirstObject:oiList];
    if (pHo!=NULL)
	{
        int count=evtProg->evtNSelectedObjects;
                
        do
        {
		    int fv = (pHo->hoCreationId << 16) | (pHo->hoNumber & 0xFFFF);
		    if (fv != hoFV)
            {
                count--;
                [evtProg evt_DeleteCurrentObject];
            }
            pHo=[evtProg evt_NextObject];
        } while (pHo!=nil);
        result=(count!=0);
    }
    evtProg->evtNSelectedObjects=evtNSelectedObjects;
    evtProg->rh2EventPrev=rh2EventPrev;
    evtProg->rh2EventPosOiList=rh2EventPosOiList;
    evtProg->rh2EventPos=rh2EventPos;
    evtProg->rh2EventQualPos=rh2EventQualPos;
    evtProg->rh2EventPrevOiList=rh2EventPrevOiList;

    return result;
}
-(BOOL)isObjectUnder:(CObject*)pHox withX:(int)x andY:(int)y
{
	if ((pHox->hoFlags&HOF_DESTROYED)==0)
	{
		if (pHox->hoType==OBJ_SPR)
		{
			return [rh->spriteGen spriteCol_TestPointOne:pHox->roc->rcSprite withLayer:LAYER_ALL andX:x andY:y andFlags:SCF_EVENNOCOL];
		}
		else
		{
			return YES;
		}
	}
    return NO;
}


-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_NEWTOUCH:
			return [self cndNewTouch:cnd];
		case CND_ENDTOUCH:
			return [self cndEndTouch:cnd];
		case CND_NEWTOUCHANY:
			return [self cndNewTouchAny:cnd];
		case CND_ENDTOUCHANY:
			return [self cndEndTouchAny:cnd];
		case CND_TOUCHMOVED:
			return [self cndTouchMoved:cnd];
		case CND_TOUCHACTIVE:
			return [self cndTouchActive:cnd];
        case CND_NEWTOUCHOBJECT:
            return [self cndNewTouchObject:cnd];
        case CND_TOUCHACTIVEOBJECT:
        {
            LPEVP pParam=[cnd getParamObject:rh withNum:1];
            return [self isActiveRoutine:[cnd getParamExpression:rh withNum:0] withOiList:pParam->evp.evpW.evpW0];
        }
        case CND_NEWPITCH:
            return [self cndNewPitch:cnd];
        case CND_PITCHACTIVE:
            return [self cndPitchActive:cnd];
        case CND_NEWGESTURE:
            return [self cndNewGesture:cnd];
	}
	return NO;
}

-(BOOL)cndNewTouch:(CCndExtension*)cnd
{
	int touch=[cnd getParamExpression:rh withNum:0];
	BOOL bTest=NO;
	if (touch<0)
	{
		bTest=YES;
	}
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		if (touches[touch].tNew!=0)
		{
			bTest=YES;
		}
	}
	if (bTest)
	{
		if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
		{
			return YES;
		}
		if ([ho getEventCount] == newTouchCount)
		{
			return YES;
		}
	}
	return NO;
}
-(BOOL)cndNewTouchAny:(CCndExtension*)cnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == newTouchCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)cndEndTouchAny:(CCndExtension*)cnd
{
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if ([ho getEventCount] == newTouchCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)cndEndTouch:(CCndExtension*)cnd
{
	int touch=[cnd getParamExpression:rh withNum:0];
	BOOL bTest=NO;
	if (touch<0)
	{
		bTest=YES;
	}
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		if (touches[touch].tEnd!=0)
		{
			bTest=YES;
		}
	}
	if (bTest)
	{
		if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
		{
			return YES;
		}
		if ([ho getEventCount] == endTouchCount)
		{
			return YES; 
		}
	}
	return NO;
}
-(BOOL)cndTouchMoved:(CCndExtension*)cnd
{
	int touch=[cnd getParamExpression:rh withNum:0];
	BOOL bTest=NO;
	if (touch<0)
	{
		bTest=YES;
	}
	if (touch==lastTouch)
	{
		bTest=YES;
	}
	if (bTest)
	{
		if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
		{
			return YES;
		}
		if ([ho getEventCount] == movedTouchCount)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)cndTouchActive:(CCndExtension*)cnd
{
	int touch=[cnd getParamExpression:rh withNum:0];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		if (touches[touch].touche!=nil)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)cndNewPitch:(CCndExtension*)cnd
{
    if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
    {
        return true;
    }
    if ([ho getEventCount] == newPitchCount)
    {
        return true;
    }
    return false;
}

-(BOOL)cndNewGesture:(CCndExtension*)cnd
{
    if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
    {
        return true;
    }
    if ([ho getEventCount] == newGestureCount)
    {
        return true;
    }
    return false;
}

-(BOOL)cndPitchActive:(CCndExtension*)cnd
{
    return (pitch1>=0 && pitch2>=0);
}

-(BOOL)cndNewTouchObject:(CCndExtension*)cnd
{
    if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
    {
        LPEVP pParam = [cnd getParamObject:rh withNum:0];
        if ( OiUnder != pParam->evp.evpW.evpW1 )
			return false;
		return [self selectObjectByFixedValue:pParam->evp.evpW.evpW0 withHoFV:hoUnder];
    }
    if ([ho getEventCount] == newTouchCount)
    {
        return [self isActiveRoutine:lastNewTouch withOiList:[cnd getParamObject:rh withNum:0]->evp.evpW.evpW0];
    }
    return false;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_SETORIGINX:
			[self setOriginX:act];
			break;
		case ACT_SETORIGINY:
			[self setOriginY:act];
			break;
        case ACT_RECOGNIZE:
            [self actRecognize:act];
            break;
        case ACT_SETRECOGNITION:
            [self actSetRecognition:act];
            break;
        case ACT_SETZONE:
            [self actSetZone:act];
            break;
        case ACT_SETZONECOORD:
            [self actSetZoneCoords:act];
            break;
        case ACT_LOADINI:
            [self actLoadIni:act];
            break;
        case ACT_RECOGNIZEG:
            [self actRecognizeG:act];
            break;
        case ACT_CLEARGESTURES:
            [self actClearGestures];
            break;
	}
}
-(void)actSetZone:(CActExtension*)act
{
    short* zone=[act getParamZone:rh withNum:0];
    ho->hoX=*zone;
    ho->hoY=*(zone+1);
    ho->hoImgWidth=*(zone+2);
    ho->hoImgHeight=*(zone+3);
}
-(void)actSetZoneCoords:(CActExtension*)act
{
    ho->hoX=[act getParamExpression:rh withNum:0];
    ho->hoY=[act getParamExpression:rh withNum:1];
    ho->hoImgWidth=[act getParamExpression:rh withNum:2];
    ho->hoImgHeight=[act getParamExpression:rh withNum:3];
}
-(void)actLoadIni:(CActExtension*)act
{
    NSString* fileName=[act getParamFilename:rh withNum:0];
    NSData* myData = [rh->rhApp loadResourceData:fileName];
    if (myData != nil && [myData length]!=0)
    {
        [self createRecognizer];
        CArrayList* strings=[[CArrayList alloc] init];
        NSString* guess = [rh->rhApp stringGuessingEncoding:myData];
        if(guess != nil)
        {
            NSArray* lines = [guess componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
            for(NSString* s in lines)
            {
                [strings add:s];
            }
            [self addGestures:strings];
            [strings release];
        }
    }
}
    
-(void)actClearGestures
{
    if ((flags&MTFLAG_RECOGNITION)==0)
    {
        [self createRecognizer];
        [recognizer ClearGestures];
    }
}
-(void)actRecognize:(CActExtension*)act
{
    if ((flags&MTFLAG_RECOGNITION)!=0)
    {
        int d=[act getParamExpression:rh withNum:0];
        if (d<0)
            d=1;
        if (d>depth)
            d=depth;
        [self recognize:depth withName:nil];
    }
}
-(void)actRecognizeG:(CActExtension*)act
{
    if ((flags&MTFLAG_RECOGNITION)!=0)
    {
        NSString* name=[act getParamExpString:rh withNum:0];
        int d=[act getParamExpression:rh withNum:1];
        if (d<0)
            d=1;
        if (d>depth)
            d=depth;
        [self recognize:depth withName:name];
    }
}
-(void)actSetRecognition:(CActExtension*)act
{
    int onOff=[act getParamExpression:rh withNum:0];
    int d=[act getParamExpression:rh withNum:1];
    if (d<1)
        d=1;
    if (d>10)
        d=10;
    depth=d;

    if (onOff!=0)
    {
        flags=flags|MTFLAG_RECOGNITION;
        if (touchArray!=nil)
        {
            [touchArray clearRelease];
        }
        else
        {
            touchArray=[[CArrayList alloc] init];
        }
    }
    else
    {
        flags&=~MTFLAG_RECOGNITION;
        if (touchArray!=nil)
        {
            [touchArray clearRelease];
        }
    }
}

-(void)setOriginX:(CActExtension*)act
{
	int touch=[act getParamExpression:rh withNum:0];
	int coord=[act getParamExpression:rh withNum:1];
	
	if (touch>=0 && touch<MAX_TOUCHES)						   
	{
		touches[touch].startX=coord-rh->rhWindowX;
	}							   
}
-(void)setOriginY:(CActExtension*)act
{
	int touch=[act getParamExpression:rh withNum:0];
	int coord=[act getParamExpression:rh withNum:1];
	
	if (touch>=0 && touch<MAX_TOUCHES)						   
	{
		touches[touch].startY=coord-rh->rhWindowY;
	}							   
}

-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETNUMBER:
			return [self expGetNumber];
		case EXP_GETLAST:
			return [rh getTempValue:lastTouch];
		case EXP_MTGETX:
			return [self expGetX];
		case EXP_MTGETY:
			return [self expGetY];
		case EXP_GETLASTNEWTOUCH:
			return [rh getTempValue:lastNewTouch];
		case EXP_GETLASTENDTOUCH:
			return [rh getTempValue:lastEndTouch];
		case EXP_GETORIGINX:
			return [self expGetOriginX];
		case EXP_GETORIGINY:
			return [self expGetOriginY];
		case EXP_GETDELTAX:
			return [self expGetDeltaX];
		case EXP_GETDELTAY:
			return [self expGetDeltaY];
		case EXP_GETTOUCHANGLE:
			return [self expGetAngle];
		case EXP_GETDISTANCE:
			return [self expGetDistance];
        case EXP_PITCHDISTANCE:
            return [self expPitchDistance];
        case EXP_PITCHPERCENTAGE:
            return [self expPitchPercentage];
        case EXP_PITCHANGLE:
            return [self expPitchAngle];
        case EXP_RECOGNIZEDNAME:
        {
            CValue* ret=[rh getTempValue:0];
            [ret forceString:gestureName];
            return ret;
        }
        case EXP_RECOGNIZEDPERCENT:
            return [rh getTempValue:gesturePercent*100];

	}
	return nil;
}
-(CValue*)expPitchAngle
{
    CValue* ret=[rh getTempValue:-1];
    if (pitch1>=0 && pitch2>=0)
    {
        int deltaX=touches[pitch2].x-touches[pitch1].x;
        int deltaY=touches[pitch2].y-touches[pitch1].y;
        double angle=atan2(-deltaY,deltaX)*57.295779513082320876798154814105;
        if (angle<0)
        {
            angle=360.0+angle;
        }
        [ret forceInt:(int)angle];
    }
    return ret;
}
-(CValue*)expPitchDistance
{
    return [rh getTempValue:[self getDistance]];
}
-(CValue*)expPitchPercentage
{
    CValue* ret=[rh getTempValue:-1];
    int distance=[self getDistance];
    if (distance>=0 && pitchDistance>0)
    {
        double percent=((double)distance/(double)pitchDistance)*100;
        [ret forceInt:(int)percent];
    }
    return ret;
}


-(CValue*)expGetNumber
{
	int count=0;
	int n;
	for (n=0; n<MAX_TOUCHES; n++)
	{
		if (touches[n].touche!=nil)
		{
			count++;
		}
	}
	return [rh getTempValue:count];
}
-(CValue*)expGetX
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		return [rh getTempValue:touches[touch].x + rh->rhWindowX - rh->rhApp->parentX];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetY
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		return [rh getTempValue:touches[touch].y + rh->rhWindowY - rh->rhApp->parentY];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetOriginX
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		return [rh getTempValue:touches[touch].startX + rh->rhWindowX - rh->rhApp->parentX];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetOriginY
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		return [rh getTempValue:touches[touch].startY + rh->rhWindowY - rh->rhApp->parentY];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetDeltaX
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		return [rh getTempValue:touches[touch].dragX-touches[touch].startX];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetDeltaY
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		return [rh getTempValue:touches[touch].dragY-touches[touch].startY];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetAngle
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		int deltaX=touches[touch].dragX-touches[touch].startX;
		int deltaY=touches[touch].dragY-touches[touch].startY;
		double angle=atan2(-deltaY,deltaX)*57.295779513082320876798154814105;
		if (angle<0)
		{
			angle=360.0+angle;
		}
		return [rh getTempValue:(int)angle];
	}
	return [rh getTempValue:-1];
}
-(CValue*)expGetDistance
{
	int touch=[[ho getExpParam] getInt];
	if (touch>=0 && touch<MAX_TOUCHES)
	{
		int deltaX=touches[touch].dragX-touches[touch].startX;
		int deltaY=touches[touch].dragY-touches[touch].startY;
		double distance=sqrt(deltaX*deltaX+deltaY*deltaY);
		return [rh getTempValue:(int)distance];
	}
	return [rh getTempValue:-1];
}

@end

@implementation GPoint
-(id)initWithX:(double)xx andY:(double)yy andID:(double)id
{
	if(self = [super init])
	{
		X=xx;
		Y=yy;
		ID=id;
	}
    return self;
}
@end

@implementation PointCloud

-(id)initWithRecognizer:(PDollarRecognizer*)pRec andName:(NSString*)pName andPoints:(CArrayList*)points
{
	if(self = [super init])
	{
		Name=[[NSString alloc] initWithString:pName];

		Points=[[CArrayList alloc] init];
		int num;
		for (num=0; num<[points size]; num++)
		{
			GPoint* p=(GPoint*)[points get:num];
			[Points add:[[GPoint alloc] initWithX:p->X andY:p->Y andID:p->ID]];
		}
		Points = [pRec Resample:Points withNum:pRec->NumPoints];
		Points = [pRec Scale:Points];
		Points = [pRec TranslateTo:Points withPoint:pRec->Origin];
	}
    return self;
}
-(void)dealloc
{
    [Points clearRelease];
    [Points release];
    [Name release];
    [super dealloc];
}
@end
double dMax(double d1, double d2)
{
    if (d1>d2)
        return d1;
    return d2;
}
double dMin(double d1, double d2)
{
    if (d1<d2)
        return d1;
    return d2;
}

@implementation PDollarRecognizer

-(id)init
{
	if(self = [super init])
	{
		NumPoints = 32;
		Origin = [[GPoint alloc] initWithX:0 andY:0 andID:0];
		gesturePercent=0;
		gestureNumber=-1;
		gestureName=[[NSString alloc] initWithString:@""];
		PointClouds=[[CArrayList alloc] init];
	}
    return self;
}
-(void)dealloc
{
    [gestureName release];
    [PointClouds clearRelease];
    [PointClouds release];
    [Origin release];
    [super dealloc];
}
-(void)Recognize:(CArrayList*)points withName:(NSString*)name
{
	CArrayList* newPoints=[[CArrayList alloc] init];

	int n;
	for (n=0; n<[points size]; n++)
	{
		GPoint* p=(GPoint*)[points get:n];
		[newPoints add:[[GPoint alloc] initWithX:p->X andY:p->Y andID:p->ID]];
	}
/*
    [newPoints add:[[GPoint alloc] initWithX:100 andY:100 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:110 andY:110 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:112 andY:112 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:115 andY:115 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:117 andY:117 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:120 andY:120 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:122 andY:122 andID:0]];
    [newPoints add:[[GPoint alloc] initWithX:100 andY:100 andID:0]];
 */
	newPoints=[self Resample:newPoints withNum:NumPoints];
	newPoints=[self Scale:newPoints];
	newPoints=[self TranslateTo:newPoints withPoint:Origin];
    
	double b = 1000000;
	int u = -1;
	if (name==NULL)
	{
		for (int i = 0; i < [PointClouds size]; i++) // for each point-cloud template
		{
			double d = [self GreedyCloudMatch:newPoints withPointCloud:(PointCloud*)[PointClouds get:i]];
			if (d < b)
			{
				b = d; // best (least) distance
				u = i; // point-cloud
			}
		}
	}
	else
	{
		int num;
		for (num = 0; num < [PointClouds size]; num++)
		{
			if ([name compare:((PointCloud*)[PointClouds get:num])->Name]==0)
				break;
		}
		if (num<[PointClouds size])
		{
			b=[self GreedyCloudMatch:newPoints withPointCloud:(PointCloud*)[PointClouds get:num]];
			u=num;
		}
	}
	gesturePercent=dMax((double)(b - 2.0) / -2.0, 0.0);
	if (gesturePercent>0)
	{
		gestureNumber=u;
		NSString* ptr=(u == -1) ? @"" : ((PointCloud*)[PointClouds get:u])->Name;
        [gestureName release];
        gestureName=[[NSString alloc] initWithString:ptr];
	}
    else
    {
        gestureNumber = -1;
        [gestureName release];
        gestureName = [[NSString alloc] initWithString:@""];
    }
	[newPoints clearRelease];
	[newPoints release];
}
     
-(int)AddGesture:(NSString*)name withPoints:(CArrayList*)points
{
	int num;
	for (num = 0; num < [PointClouds size]; num++)
	{
		PointCloud* pCloud=(PointCloud*)[PointClouds get:num];
		if ([name compare:pCloud->Name]==0)
			break;
	}
    
	if (num<[PointClouds size])
	{
		[(PointCloud*)[PointClouds get:num] release];
        [PointClouds set:num object:[[PointCloud alloc] initWithRecognizer:self andName:name andPoints:points]];
	}
	else
	{
		[PointClouds add:[[PointCloud alloc] initWithRecognizer:self andName:name andPoints:points]];
	}
	return num;
}
-(void)ClearGestures
{
    [PointClouds clearRelease];
}

-(double)GreedyCloudMatch:(CArrayList*)points withPointCloud:(PointCloud*)P
{
	double e = 0.50;
	int step = (int)pow([points size], 1 - e);
	double min = 1000000000;
	for (int i = 0; i < [points size]; i += step)
    {
		double d1 = [self CloudDistance:points withPoints:P->Points andIndex:i];
		double d2 = [self CloudDistance:P->Points withPoints:points andIndex:i];
		min = dMin(min, dMin(d1, d2)); // min3
	}
	return min;
}
-(double)CloudDistance:(CArrayList*)pts1 withPoints:(CArrayList*)pts2 andIndex:(int)start
{
	int matchedSize=[pts1 size];
	BOOL* matched=(BOOL*)malloc(matchedSize*sizeof(BOOL));
	for (int k = 0; k < matchedSize; k++)
		matched[k] = NO;
	double sum = 0;
	int i = start;
	do
	{
		int index = -1;
		double min = 1000000000;
		for (int j = 0; j < matchedSize; j++)
		{
			if (!matched[j])
            {
				double d = [self Distance:(GPoint*)[pts1 get:i] withPoint:(GPoint*)[pts2 get:j]];
				if (d < min)
                {
					min = d;
					index = j;
				}
			}
		}
		matched[index] = TRUE;
		double weight = 1 -((double)((i - start + [pts1 size]) % [pts1 size]))/[pts1 size];
		sum += weight * min;
		i = (i + 1) % [pts1 size];
	} while (i != start);
	return sum;
}
-(CArrayList*)Resample:(CArrayList*)points withNum:(int)n
{
	double I = [self PathLength:points] / (n - 1); // interval length
	double D = 0.0;
    CArrayList* newpoints = [[CArrayList alloc] init];
	GPoint* p0=(GPoint*)[points get:0];
    [newpoints add:[[GPoint alloc] initWithX:p0->X andY:p0->Y andID:p0->ID]];
	for (int i = 1; i < [points size]; i++)
	{
		GPoint* point0=(GPoint*)[points get:i];
        GPoint* point1=(GPoint*)[points get:i-1];
		if (point0->ID == point1->ID)
		{
			double d = [self Distance:point1 withPoint:point0];
			if ((D + d) >= I)
			{
				double qx = point1->X + ((I - D) / d) * (point0->X - point1->X);
				double qy = point1->Y + ((I - D) / d) * (point0->Y - point1->Y);
                [newpoints add:[[GPoint alloc] initWithX:qx andY:qy andID:point0->ID]];
                [points addIndex:i object:[[GPoint alloc] initWithX:qx andY:qy andID:point0->ID]]; // insert 'q' at position i in points s.t. 'q' will be the next i
				D = 0.0;
			}
			else D += d;
		}
	}
	if ([newpoints size]==n - 1) // sometimes we fall a rounding-error short of adding the last point, so add it if so
	{
		p0=(GPoint*)[points get:[points size] - 1];
		[newpoints add:[[GPoint alloc] initWithX:p0->X andY:p0->Y andID:p0->ID]];
	}
	[points clearRelease];
	[points release];
	return newpoints;
}
-(CArrayList*)Scale:(CArrayList*)points
{
	double minX = 1000000000, maxX = -1000000000, minY = +1000000000, maxY = -1000000000;
	GPoint* p;
	int i;
	for (i = 0; i < [points size]; i++)
    {
		p=(GPoint*)[points get:i];
		minX = dMin(minX, p->X);
		minY = dMin(minY, p->Y);
		maxX = dMax(maxX, p->X);
		maxY = dMax(maxY, p->Y);
	}
	double size = dMax(maxX - minX, maxY - minY);
	CArrayList* newpoints = [[CArrayList alloc] init];
	for (i = 0; i < [points size]; i++)
    {
		p=(GPoint*)[points get:i];
		double qx = (p->X - minX) / size;
		double qy = (p->Y - minY) / size;
		[newpoints add:[[GPoint alloc] initWithX:qx andY:qy andID:p->ID]];
	}
	[points clearRelease];
	[points release];
	return newpoints;
}
-(CArrayList*)TranslateTo:(CArrayList*)points withPoint:(GPoint*) pt
{
	GPoint* c=[[GPoint alloc] initWithX:0 andY:0 andID:0];
	[self Centroid:c withPoints:points];
	CArrayList* newpoints =[[CArrayList alloc] init];
	for (int i = 0; i < [points size]; i++)
    {
		GPoint* p=(GPoint*)[points get:i];
		double qx = p->X + pt->X - c->X;
		double qy = p->Y + pt->Y - c->Y;
		[newpoints add:[[GPoint alloc] initWithX:qx andY:qy andID:p->ID]];
	}
	[points clearRelease];
	[points release];
	return newpoints;
}

-(void)Centroid:(GPoint*)point withPoints:(CArrayList*)points
{
	double x = 0.0, y = 0.0;
	for (int i = 0; i < [points size]; i++)
    {
		GPoint* p=(GPoint*)[points get:i];
		x += p->X;
		y += p->Y;
	}
	x /= [points size];
	y /= [points size];
	point->X=x;
	point->Y=y;
	point->ID=0;
}
-(double)PathDistance:(CArrayList*)pts1 withPoints:(CArrayList*)pts2 // average distance between corresponding points in two paths
{
	double d = 0.0;
	for (int i = 0; i < [pts1 size]; i++) // assumes pts1.length == pts2.length
		d += [self Distance:(GPoint*)[pts1 get:i] withPoint:(GPoint*)[pts2 get:i]];
	return d / [pts1 size];
}
-(double)PathLength:(CArrayList*)points // length traversed by a point path
{
	double d = 0.0;
	for (int i = 1; i < [points size]; i++)
	{
		GPoint* p0=(GPoint*)[points get:i];
        GPoint* p1=(GPoint*)[points get:i-1];
		if (p0->ID == p1->ID)
			d += [self Distance:p1 withPoint:p0];
	}
	return d;
}
-(double)Distance:(GPoint*)p1 withPoint:(GPoint*)p2 // Euclidean distance between two points
{
	double dx = p2->X - p1->X;
	double dy = p2->Y - p1->Y;
	return sqrt(dx * dx + dy * dy);
}
@end
