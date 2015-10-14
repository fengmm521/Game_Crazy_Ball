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
// CMOVEEXTENSION : classe abstraite de mouvement extension
//
//----------------------------------------------------------------------------------
#import "CRunMvtExtension.h"
#import "CObject.h"
#import "CRun.h"
#import "CFile.h"
#import "CMoveExtension.h"
#import "CAnim.h"
#import "CRAni.h"
#import "CPoint.h"
#import "CRMvt.h"
#import "CRCom.h"
#import "CRunFrame.h"

@implementation CRunMvtExtension

-(void)setObject:(CObject*)hoPtr
{
	ho=hoPtr;
	rh=ho->hoAdRunHeader;
}	

// Fonctions virtuelles
// -----------------------------------------------------------------------------------
-(void)initialize:(CFile*)file
{
}
-(void)kill
{
}
-(BOOL)move
{
	return NO;
}
-(void)setPosition:(int)x withY:(int)y
{
}
-(void)setXPosition:(int)x
{
}
-(void)setYPosition:(int)y
{
}
-(void)stop:(BOOL)bCurrent
{
}
-(void)bounce:(BOOL)bCurrent
{
}
-(void)reverse
{
}
-(void)start
{
}
-(void)setSpeed:(int)speed
{
}
-(void)setMaxSpeed:(int)speed
{
}
-(void)setDir:(int)dir
{
}
-(void)setAcc:(int)acc
{
}
-(void)setDec:(int)dec
{
}
-(void)setRotSpeed:(int)speed
{
}
-(void)set8Dirs:(int)dirs
{
}
-(void)setGravity:(int)gravity
{
}
-(int)extension:(int)function param:(int)param
{
	return 0;
}
-(double)actionEntry:(int)action
{
	return 0;
}
-(int)getSpeed
{
	return 0;
}
-(int)getAcceleration
{
	return 0;
}
-(int)getDeceleration
{
	return 0;
}
-(int)getGravity
{
	return 0;
}
-(int)getDir
{
    return ho->roc->rcDir;
}

// Callback routines
// -------------------------------------------------------------------------
-(int)dirAtStart:(int)dir
{
	return [ho->rom dirAtStart:ho withDirAtStart:dir andDir:32];
}
-(void)animations:(int)anm
{
	ho->roc->rcAnim=anm;
	if (ho->roa!=nil)
	{
		[ho->roa animate];
	}
}
-(void)collisions
{
	ho->hoAdRunHeader->rh3CollisionCount++;	
	ho->rom->rmMovement->rmCollisionCount=ho->hoAdRunHeader->rh3CollisionCount;
	[ho->hoAdRunHeader newHandle_Collisions:ho];
}
-(CApproach)approachObject:(int)destX withDestY:(int)destY andOriginX:(int)originX andOriginY:(int)originY andFoot:(int)htFoot andPlane:(int)planCol
{
	destX-=ho->hoAdRunHeader->rhWindowX;
	destY-=ho->hoAdRunHeader->rhWindowY;
	originX-=ho->hoAdRunHeader->rhWindowX;
	originY-=ho->hoAdRunHeader->rhWindowY;
	CApproach bRet=[ho->rom->rmMovement mpApproachSprite:destX withDestY:destY andMaxX:originX andMaxY:originY andFoot:htFoot andPlane:planCol];
		
	bRet.point.x += ho->hoAdRunHeader->rhWindowX;
	bRet.point.y += ho->hoAdRunHeader->rhWindowY;
	return bRet;	    
}	    
-(BOOL)moveIt
{
	return [ho->rom->rmMovement newMake_Move:ho->roc->rcSpeed withDir:ho->roc->rcDir];
}
-(BOOL)testPosition:(int)x withY:(int)y andFoot:(int)htFoot andPlane:(int)planCol andFlag:(BOOL)flag
{
	return [ho->rom->rmMovement tst_SpritePosition:x withY:y andFoot:htFoot andPlane:planCol andFlag:flag];
}    
-(unsigned char)getJoystick
{
	return ho->hoAdRunHeader->rhPlayer;
}
-(BOOL)colMaskTestRect:(int)x withY:(int)y andWidth:(int)sx andHeight:(int)sy andLayer:(int)layer andPlane:(int)plan
{
	return ![ho->hoAdRunHeader->rhFrame bkdCol_TestRect:x withY:y andWidth:sx andHeight:sy andLayer:layer andPlane:plan];
}
-(BOOL)colMaskTestPoint:(int)x withY:(int)y andLayer:(int)layer andPlane:(int)plan
{
	return ![ho->hoAdRunHeader->rhFrame bkdCol_TestPoint:x withY:y andLayer:layer andPlane:plan];
}
-(double)getParamDouble
{
	CMoveExtension* mvt=(CMoveExtension*)ho->rom->rmMovement;
	return mvt->callParam1;
}
-(double)getParam1
{
	CMoveExtension* mvt=(CMoveExtension*)ho->rom->rmMovement;
	return mvt->callParam1;
}
-(double)getParam2
{
	CMoveExtension* mvt=(CMoveExtension*)ho->rom->rmMovement;
	return mvt->callParam2;
}
/*
public DataInputStream getInputStream()
{
	CMoveExtension mvt=(CMoveExtension)ho.rom.rmMovement;
	return mvt.inputStream;
}
public DataOutputStream getOutputStream()
{
	CMoveExtension mvt=(CMoveExtension)ho.rom.rmMovement;
	return mvt.outputStream;
}
*/

@end
