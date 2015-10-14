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
// CRunAdvGameBoard : Advanced Game Board object
// fin: 4/10/09
//greyhill
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CArrayList;
@class CActExtension;
@class CCndExtension;
@class CCreateObjectInfo;
@class CObject;
@class CValue;

#define CID_conOnFoundConnected 0
#define CID_conOnFoundBrick 1
#define CID_conOnFoundLooped 2
#define CID_conOnNoFoundConnected 3
#define CID_conBrickCanFallUp 4
#define CID_conBrickCanFallDown 5
#define CID_conBrickCanFallLeft 6
#define CID_conBrickCanFallRight 7
#define CID_conOnBrickMoved 8
#define CID_conOnBrickDeleted 9
#define CID_conIsEmpty 10
#define AID_actSetBrick 0
#define AID_actClear 1
#define AID_actSetBoadSize 2
#define AID_actSetMinConnected 3
#define AID_actSearchHorizontal 4
#define AID_actSearchVertical 5
#define AID_actSearchDiagonalsLR 6
#define AID_actSearchConnected 7
#define AID_actDeleteHorizonal 8
#define AID_actDeleteVertical 9
#define AID_actSwap 10
#define AID_actDropX 11
#define AID_actDropOne 12
#define AID_actMarkUsed 13
#define AID_actDeleteMarked 14
#define AID_actUndoSwap 15
#define AID_actSearchDiagonalsRL 16
#define AID_actLoopFoundBricks 17
#define AID_actSetFixedOfBrick 18
#define AID_actImportActives 19
#define AID_actMarkCurrentSystem 20
#define AID_actMarkCurrentBrick 21
#define AID_actLoopEntireBoard 22
#define AID_actLoopBoardOfType 23
#define AID_actLoopSorrounding 24
#define AID_actLoopHozLine 25
#define AID_actLoopVerLine 26
#define AID_actClearWithType 27
#define AID_actInsertBrick 28
#define AID_actSetOrigin 29
#define AID_actSetCellDimensions 30
#define AID_actMoveFixedON 31
#define AID_actMoveFixedOFF 32
#define AID_actMoveBrick 33
#define AID_actDropOneUp 34
#define AID_actDropOneLeft 35
#define AID_actDropOneRight 36
#define AID_actDropXUp 37
#define AID_actDropXLeft 38
#define AID_actDropXRight 39
#define AID_actSetCellValue 40
#define AID_actDeleteBrick 41
#define AID_actShiftHosLine 42
#define AID_actShiftVerLine 43
#define AID_actPositionBricks 44
#define EID_expGetBrickAt 0
#define EID_expGetXSize 1
#define EID_expGetYSize 2
#define EID_expGetNumBricksInSystem 3
#define EID_expGetXofBrick 4
#define EID_expGetYofBrick 5
#define EID_expGetFoundBrickType 6
#define EID_expGetNumBricksInHozLine 7
#define EID_expGetNumBricksInVerLine 8
#define EID_expCountSorrounding 9
#define EID_expCountTotal 10
#define EID_expGetFoundBrickFixed 11
#define EID_expGetFoundXofBrick 12
#define EID_expGetFoundYofBrick 13
#define EID_expGetTypeofBrick 14
#define EID_expGetFixedOfBrick 15
#define EID_expGetFixedAt 16
#define EID_expLoopIndex 17
#define EID_expFindXfromFixed 18
#define EID_expFindYfromFixed 19
#define EID_expFindBrickfromFixed 20
#define EID_expGetLoopFoundXofBrick 21
#define EID_expGetLoopFoundYofBrick 22
#define EID_expGetLoopTypeofBrick 23
#define EID_expGetLoopFoundBrickFixed 24
#define EID_expLoopLoopIndex 25
#define EID_expGetXBrickFromX 26
#define EID_expGetYBrickFromY 27
#define EID_expSnapXtoGrid 28
#define EID_expSnapYtoGrid 29
#define EID_expGetOriginX 30
#define EID_expGetOriginY 31
#define EID_expGetCellWidth 32
#define EID_expGetCellHeight 33
#define EID_expGetCellValue 34
#define EID_expGetXofCell 35
#define EID_expGetYofCell 36
#define EID_expMovedFixed 37
#define EID_expMovedNewX 38
#define EID_expMovedNewY 39
#define EID_expMovedOldX 40
#define EID_expMovedOldY 41
#define EID_expDeletedFixed 42
#define EID_expDeletedX 43
#define EID_expDeletedY 44

@interface CRunAdvGameBoard : CRunExtension
{
    int BSizeX,  BSizeY,  MinConnected,  SwapBrick1,  SwapBrick2,  LoopIndex,  LoopedIndex,  OriginX,  OriginY,  CellWidth,  CellHeight;
    int* Board;
	int* StateBoard;
	int* FixedBoard;
	int* CellValues;
    BOOL MoveFixed,  TriggerMoved,  TriggerDeleted;
    int DeletedFixed,  DeletedX,  DeletedY,  MovedFixed,  MovedNewX,  MovedNewY,  MovedOldX,  MovedOldY;
    int AddIncrement,  SearchBrickType;
    CArrayList* Bricks; //<Integer>
    CArrayList* Looped; //<Integer>
}
-(int)getNumberOfConditions;
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version;
-(void)destroyRunObject:(BOOL)bFast;
-(int)getBrick:(int)x withY:(int)y;
-(int)getBrickAtPos:(int)pos;
-(BOOL)CHECKPOS:(int)nPos;
-(int)getPos:(int)x withY:(int)y;
-(int)getXbrick:(int)pos;
-(int)getYbrick:(int)pos;
-(void)setBrick:(int)x withY:(int)y andValue:(int)value;
-(int)getFixed:(int)x withY:(int)y;
-(void)setFixed:(int)x withY:(int)y andValue:(int)value;
-(int)wrapX:(int)shift;
-(int)wrapY:(int)shift;
-(void)MoveBrick:(int)sourceX withSrceY:(int)sourceY andDestX:(int)destX andDestY:(int)destY;
-(void)fall;
-(void)fallUP;
-(void)fallLEFT;
-(void)fallRIGHT;
-(int)handleRunObject;
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd;
-(BOOL)conBrickCanFallUp:(int)x withParam1:(int)y;
-(BOOL)conBrickCanFallDown:(int)x withParam1:(int)y;
-(BOOL)conBrickCanFallLeft:(int)x withParam1:(int)y;
-(BOOL)conBrickCanFallRight:(int)x withParam1:(int)y;
-(BOOL)conIsEmpty:(int)x withParam1:(int)y;
-(void)action:(int)num withActExtension:(CActExtension*)act;
-(void) actSetBrick:(int)x withParam1:(int)y andParam2:(int)brickType;
-(void) actClear;
-(void) actSetBoadSize:(int)x withParam1:(int)y;
-(void) actSearchHorizontal:(int)brickType;
-(void) actSearchVertical:(int)brickType;
-(void) actSearchDiagonalsLR:(int)brickType;
-(void) actSearchConnected:(int)startX withParam1:(int)startY;
-(void) actDeleteHorizonal:(int)y withParam1:(int)mode;
-(void) actDeleteVertical:(int)x withParam1:(int)mode;
-(void) actSwap:(int)x1 withParam1:(int)y1 andParam2:(int)x2 andParam3:(int)y2;
-(void) actDropX:(int)n;
-(void) actMarkUsed:(int)x withParam1:(int)y;
-(void) actDeleteMarked;
-(void) actUndoSwap;
-(void) actSearchDiagonalsRL:(int)brickType;
-(void) actLoopFoundBricks;
-(void) actSetFixedOfBrick:(int)x withParam1:(int)y andParam2:(int)fv;
-(void) actImportActives:(CObject*)selected;
-(void) actMarkCurrentSystem;
-(void) actMarkCurrentBrick;
-(void) actLoopEntireBoard;
-(void) actLoopBoardOfType:(int)brickType;
-(void) actLoopSorrounding:(int)x withParam1:(int)y;
-(void) actLoopHozLine:(int)y;
-(void) actLoopVerLine:(int)x;
-(void) actClearWithType:(int)brickType;
-(void) actInsertBrick:(int)x withParam1:(int)y andParam2:(int)brickType;
-(void) actSetCellDimensions:(int)x withParam1:(int)y;
-(void) actDropXUp:(int)n;
-(void) actDropXLeft:(int)n;
-(void) actDropXRight:(int)n;
-(void) actSetCellValue:(int)x withParam1:(int)y andParam2:(int)value;
-(void) actDeleteBrick:(int)x withParam1:(int)y;
-(void) actShiftHosLine:(int)yline withParam1:(int)shift;
-(void) actShiftVerLine:(int)xline withParam1:(int)shift;
-(CObject*)CObjectFromFixed:(int)fixed;
-(void) actPositionBricks;
-(CValue*)expression:(int)num;
-(CValue*) expGetXofBrick:(int)i;
-(CValue*) expGetYofBrick:(int)i;
-(CValue*) expGetNumBricksInHozLine:(int)y;
-(CValue*) expGetNumBricksInVerLine:(int)x;
-(CValue*) expCountSorrounding;
-(CValue*) expCountTotal;
-(CValue*) expGetFoundBrickFixed:(int)i;
-(CValue*) expGetFixedOfBrick;
-(CValue*) expGetFixedAt;
-(CValue*) expFindXfromFixed:(int)fixed;
-(CValue*) expFindYfromFixed:(int)fixed;
-(CValue*) expFindBrickfromFixed:(int)fixed;
-(CValue*) expGetLoopFoundBrickFixed;
-(CValue*) expGetXBrickFromX:(int)x;
-(CValue*) expGetYBrickFromY:(int)y;
-(CValue*) expSnapXtoGrid:(int)x;
-(CValue*) expSnapYtoGrid:(int)y;
-(CValue*) expGetCellValue;
-(int) expGetBrick;

@end
