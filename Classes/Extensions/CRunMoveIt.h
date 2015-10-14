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
//  CRunMoveIt.h
//  RuntimeIPhone
//
//  Created by Anders Riggelsen on 3/10/11.
//  Copyright 2011 Clickteam. All rights reserved.
//

#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;
@class CArrayList;
@class CObject;
@class MoveItItem;

@interface CRunMoveIt : CRunExtension
{
	CArrayList* movingObjects;
	CArrayList* queue;
	CObject* triggeredObject;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(int)handleRunObject;
-(void)destroyRunObject:(BOOL)bFast;

-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(CValue*)expression:(int)num;

-(MoveItItem*)getItemFromFixed:(int)fixed;
-(MoveItItem*)getItemFromIndex:(int)index;

-(void)moveObject:(CObject*)object andX:(int)x andY:(int)y andCycles:(int)cycles;
-(void)act_moveObjectsWithSpeed:(int)x andY:(int)y andSpeed:(double)speed;
-(void)act_moveObjectsWithTime:(int)x andY:(int)y andTime:(int)time;
-(void)act_stopByFixedValue:(int)fixed;
-(void)act_stopByIndex:(int)index;
-(void)act_stopByObjectSelector:(CObject*)object;
-(void)act_addObjectToQueue:(CObject*)object;
-(void)act_clearQueue;
-(void)act_stopAll;
-(void)act_doMoveStep;

-(CValue*)exp_getNumberOfObjectsMoving;
-(CValue*)exp_fromFixedGetIndex;
-(CValue*)exp_fromFixedGetTotalDistance;
-(CValue*)exp_fromFixedGetRemainingDistance;
-(CValue*)exp_fromFixedGetAngle;
-(CValue*)exp_fromFixedGetDirection;
-(CValue*)exp_fromIndexGetFixed;
-(CValue*)exp_fromIndexGetTotalDistance;
-(CValue*)exp_fromIndexGetRemainingDistance;
-(CValue*)exp_fromIndexGetAngle;
-(CValue*)exp_fromIndexGetDirection;
-(CValue*)exp_onObjectFinnishedGetFixed;

@end



@interface MoveItItem : CRunExtension
{
@public
	CObject* mobject;
	int sourceX;
	int sourceY;
	int destX;
	int destY;
	int cycles;
	int step;
}
-(id)initWithObject:(CObject*)obj andDstX:(int)dstX andDstY:(int)dstY andCycles:(int)numCycles;
-(void)moveToDstX:(int)dstX andDstY:(int)dstY andCycles:(int)numCycles;

@end