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
// CRUNLAYER : Objet layer
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"
#import "CEvents.h"

#define X_UP  0
#define X_DOWN  1
#define Y_UP  2
#define Y_DOWN  3
#define ALT_UP  4
#define ALT_DOWN  5

@class CObject;
@class CRun;
@class CActExtension;
@class CCndExtension;
@class CBitmap;
@class CCreateObjectInfo;
@class CSprite;
@class CSortData;
@class CObjInfo;
@class CValue;

@interface CRunLayer : CRunExtension
{
    int holdFValue;
    int wCurrentLayer;
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)cndAtBack:(CCndExtension*)cnd;
-(BOOL)cndAtBackRout:(int)param1;
-(BOOL)cndAtFront:(CCndExtension*)cnd;
-(BOOL)cndAtFrontRout:(int)param1;
-(BOOL)cndAbove:(CCndExtension*)cnd;
-(BOOL)cndAboveRout:(int)param1 withParam1:(int)param2;
-(BOOL)cndBelow:(CCndExtension*)cnd;
-(BOOL)cndBelowRout:(int)param1 withParam1:(int)param2;
-(BOOL)cndBetween:(CCndExtension*)cnd;
-(BOOL)cndAtBackObj:(CCndExtension*)cnd;
-(BOOL)cndAtFrontObj:(CCndExtension*)cnd;
-(BOOL)cndAboveObj:(CCndExtension*)cnd;
-(BOOL)cndBelowObj:(CCndExtension*)cnd;
-(BOOL)cndBetweenObj:(CCndExtension*)cnd;
-(BOOL)cndIsLayerVisible:(CCndExtension*)cnd;
-(int)FindLayerByName:(NSString*)pName;
-(BOOL)cndIsLayerVisibleByName:(CCndExtension*)cnd;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void)actBackOne:(CActExtension*)act;
-(void)actBackOneRout:(int)param1;
-(void)actForwardOne:(CActExtension*)act;
-(void)actForwardOneRout:(int)param1;
-(void)actSwap:(CActExtension*)act;
-(void)actSwapRout:(int)param1 withParam1:(int)param2;
-(void)actSetObj:(CActExtension*)act;
-(void)actBringFront:(CActExtension*)act;
-(void)actBringFrontRout:(int)param1;
-(void)actSendBack:(CActExtension*)act;
-(void)actSendBackRout:(int)param1;
-(void)actBackN:(CActExtension*)act;
-(void)actBackNRout:(int)param1 withParam1:(int)param2;
-(void)actForwardN:(CActExtension*)act;
-(void)actForwardNRout:(int)param1 withParam1:(int)param2;
-(void)actReverse:(CActExtension*)act;
-(void)actMoveAbove:(CActExtension*)act;
-(void)actMoveAboveRout:(int)param1 withParam1:(int)param2;
-(void)actMoveBelow:(CActExtension*)act;
-(void)actMoveBelowRout:(int)param1 withParam1:(int)param2;
-(void)actMoveToN:(CActExtension*)act;
-(void)actMoveToNRout:(int)param1 withParam1:(int)param2;
-(void)actSortByXUP:(CActExtension*)act;
-(void)actSortByYUP:(CActExtension*)act;
-(void)actSortByXDOWN:(CActExtension*)act;
-(void)actSortByYDOWN:(CActExtension*)act;
-(void)actBackOneObj:(CActExtension*)act;
-(void)actForwardOneObj:(CActExtension*)act;
-(void)actSwapObj:(CActExtension*)act;
-(void)actBringFrontObj:(CActExtension*)act;
-(void)actSendBackObj:(CActExtension*)act;
-(void)actBackNObj:(CActExtension*)act;
-(void)actForwardNObj:(CActExtension*)act;
-(void)actMoveAboveObj:(CActExtension*)act;
-(void)actMoveBelowObj:(CActExtension*)act;
-(void)actMoveToNObj:(CActExtension*)act;
-(void)actSortByALTUP:(CActExtension*)act;
-(void)actSortByALTDOWN:(CActExtension*)act;
-(void)actSetLayerX:(CActExtension*)act;
-(void)actSetLayerY:(CActExtension*)act;
-(void)actSetLayerXY:(CActExtension*)act;
-(void)actShowLayer:(CActExtension*)act;
-(void)actHideLayer:(CActExtension*)act;
-(void)actSetLayerXByName:(CActExtension*)act;
-(void)actSetLayerYByName:(CActExtension*)act;
-(void)actSetLayerXYByName:(CActExtension*)act;
-(void)actShowLayerByName:(CActExtension*)act;
-(void)actHideLayerByName:(CActExtension*)act;
-(void)actSetCurrentLayer:(CActExtension*)act;
-(void)actSetCurrentLayerByName:(CActExtension*)act;
-(void)actSetLayerCoefX:(CActExtension*)act;
-(void)actSetLayerCoefY:(CActExtension*)act;
-(void)actSetLayerCoefXByName:(CActExtension*)act;
-(void)actSetLayerCoefYByName:(CActExtension*)act;
-(CValue*)expression:(int)num;
-(CValue*)expGetFV;
-(CValue*)expGetTopFV;
-(CValue*)expGetBottomFV;
-(CValue*)expGetDesc;
-(CValue*)expGetDesc10;
-(CValue*)expGetNumLevels;
-(CValue*)expGetLevel;
-(CValue*)expGetLevelFV;
-(CValue*)expGetLayerX;
-(CValue*)expGetLayerY;
-(CValue*)expGetLayerXByName;
-(CValue*)expGetLayerYByName;
-(CValue*)expGetLayerCount;
-(CValue*)expGetLayerName;
-(CValue*)expGetLayerIndex;
-(CValue*)expGetCurrentLayer;
-(CValue*)expGetLayerCoefX;
-(CValue*)expGetLayerCoefY;
-(CValue*)expGetLayerCoefXByName;
-(CValue*)expGetLayerCoefYByName;
-(CValue*)expGetZeroOneParam;
-(void)lyrSwapSpr:(CSprite*)sp1 withParam1:(CSprite*)sp2;
-(BOOL)lyrSwapThem:(CSprite*)sprPtr1 withParam1:(CSprite*)sprPtr2 andParam2:(BOOL)bRedraw;
-(CSprite*)lyrGetSprite:(int)fixedValue;
-(CObject*)lyrGetROfromFV:(int)fixedValue;
-(BOOL)lyrSortBy:(int)flag withParam1:(int)altDefaultVal andParam2:(int)altValue;
-(BOOL)isGreater:(CSortData*)item1 withParam1:(CSortData*)item2;
-(NSString*)lyrGetList:(int)lvlStart withParam1:(int)iteration;
-(int)lyrGetFVfromEVP:(LPEVP)evp;
-(CObject*)lyrGetROfromEVP:(LPEVP)evp;
-(CObjInfo*)lyrGetOILfromEVP:(LPEVP)evp;
-(int)lyrGetFVfromOIL:(CObjInfo*)oilPtr;
-(void)lyrResetEventList:(CObjInfo*)oilPtr;
-(BOOL)lyrProcessCondition:(LPEVP)param1 withParam1:(LPEVP)param2 andParam2:(int)cond;
-(BOOL)doCondition:(int)cond withParam1:(int)param1 andParam2:(int)param2;
-(CValue*)expGetZeroOneParam;

@end


@interface CSortData : NSObject
{
@public
    CSprite* indexSprite;
    int sprX;
    int sprY;
    int sprAlt;
    int cmpFlag;	
}

@end
