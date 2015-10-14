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
// CMOVEEXTENSION : Mouvement extension
//
//----------------------------------------------------------------------------------
#import "CMoveExtension.h"
#import "CMoveDefExtension.h"
#import "CRunMvtExtension.h"
#import "CFile.h"
#import "CObject.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CRun.h"
#import "CRCom.h"

@implementation CMoveExtension

-(id)initWithObject:(CRunMvtExtension*)m
{
	movement = m;
	return self;
}

-(void)initMovement:(CObject*)ho withMoveDef:(CMoveDef*)mvPtr
{
	hoPtr = ho;
	
	CMoveDefExtension* mdExt = (CMoveDefExtension*) mvPtr;
	CFile* file = [[CFile alloc] initWithBytes:mdExt->data length:mdExt->length];
	[file setUnicode:ho->hoAdRunHeader->rhApp->bUnicode];	
	[movement initialize:file];
	[file release];
	
	hoPtr->roc->rcCheckCollides = YES;			//; Force la detection de collision
	hoPtr->roc->rcChanged = YES;
}

-(void)dealloc
{
	if(movement != nil)
		[movement release];
	[super dealloc];
}

-(void)kill
{
	[movement kill];
}

-(void)move
{
    if ([movement move])
    {
        hoPtr->roc->rcChanged = YES;
    }
}

-(void)stop
{
 	[movement stop:rmCollisionCount == hoPtr->hoAdRunHeader->rh3CollisionCount];	    // Sprite courant?
}

-(void)start
{
	[movement start];
}

-(void)bounce
{
	[movement bounce:rmCollisionCount == hoPtr->hoAdRunHeader->rh3CollisionCount];    // Sprite courant?
}

-(void)setSpeed:(int)speed
{
	[movement setSpeed:speed];
}

-(void)setMaxSpeed:(int)speed
{
	[movement setMaxSpeed:speed];
}

-(void)reverse
{
	[movement reverse];
}

-(void)setXPosition:(int)x
{
	[movement setXPosition:x];
	hoPtr->roc->rcChanged = YES;
	hoPtr->roc->rcCheckCollides = YES;
}

-(void)setYPosition:(int)y
{
	[movement setYPosition:y];
	hoPtr->roc->rcChanged = YES;
	hoPtr->roc->rcCheckCollides = YES;
}

-(void)setDir:(int)dir
{
	[movement setDir:dir];
	hoPtr->roc->rcChanged = YES;
	hoPtr->roc->rcCheckCollides = YES;
}

-(double)callMovement:(int)function param:(double)param
{
	callParam1 = param;
	return [movement actionEntry:function];
}
-(double)callMovement2:(int)function param:(double)param param2:(double)param2
{
	callParam1 = param;
	callParam2 = param2;
	return [movement actionEntry:function];
}

/*
public int callSavePosition(DataOutputStream stream)
{
	outputStream = stream;
	return (int) movement.actionEntry(0x1010);
}

public int callLoadPosition(DataInputStream stream)
{
	inputStream = stream;
	return (int) movement.actionEntry(0x1011);
}
*/
@end
