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
#import "CRunAdvGameBoard.h"
#import "CRun.h"
#import "CFile.h"
#import "CObject.h"
#import "CBitmap.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CArrayList.h"
#import "CExtension.h"
#import "CRCom.h"

@implementation CRunAdvGameBoard

-(int)getNumberOfConditions
{
	return 11;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	[file skipBytes:8];
	BSizeX = [file readAInt];
	BSizeY = [file readAInt];
	MinConnected = [file readAInt];
	SwapBrick1 = 0;
	SwapBrick2 = 0;
	LoopIndex = 0;
	LoopedIndex = 0;
	
	int size = BSizeX * BSizeY;
	Board = (int*)calloc(size, sizeof(int));
	StateBoard = (int*)calloc(size, sizeof(int));
	FixedBoard = (int*)calloc(size, sizeof(int));
	CellValues = (int*)calloc(size, sizeof(int));
	
	OriginX = [file readAInt];
	OriginY = [file readAInt];
	CellWidth = [file readAInt];
	CellHeight = [file readAInt];
	MoveFixed = ([file readAByte] != 0) ? true : false;
	TriggerMoved = ([file readAByte] != 0) ? true : false;
	TriggerDeleted = ([file readAByte] != 0) ? true : false;
	
	DeletedFixed = -1;
	DeletedX = -1;
	DeletedY = -1;
	
	MovedFixed = -1;
	MovedNewX = -1;
	MovedNewY = -1;
	
	MovedOldX = -1;
	MovedOldY = -1;

	Bricks=[[CArrayList alloc] init];
	Looped=[[CArrayList alloc] init];
	return YES;
}
-(void)destroyRunObject:(BOOL)bFast
{
	free(Board);
	free(StateBoard);
	free(FixedBoard);
	free(CellValues);
	[Bricks release];
	[Looped release];
}

-(int)getBrick:(int)x withY:(int)y
{
	if ((x < BSizeX) && (x >= 0) && (y < BSizeY) && (y >= 0))
	{
		return Board[BSizeX * y + x];
	}
	else
	{
		return -1;
	}
}

-(int)getBrickAtPos:(int)pos
{
	if ([self CHECKPOS:pos])
	{
		return Board[pos];
	}
	return 0;
}

-(BOOL)CHECKPOS:(int)nPos
{
	if (nPos >= 0 && nPos < BSizeX * BSizeY)
	{
		return YES;
	}
	return NO;
}

-(int)getPos:(int)x withY:(int)y
{
	if ((x < BSizeX) && (x >= 0) && (y < BSizeY) && (y >= 0))
	{
		return BSizeX * y + x;
	}
	else
	{
		return -1;
	}
}

-(int)getXbrick:(int)pos
{
	return pos % BSizeX;
}

-(int)getYbrick:(int)pos
{
	return pos / BSizeX;
}

-(void)setBrick:(int)x withY:(int)y andValue:(int)value
{
	if ([self CHECKPOS:[self getPos:x withY:y]])
	{
		Board[[self getPos:x withY:y]] = value;
	}
}

-(int)getFixed:(int)x withY:(int)y
{
	if ((x < BSizeX) && (x >= 0) && (y < BSizeY) && (y >= 0))
	{
		return FixedBoard[BSizeX * y + x];
	}
	else
	{
		return -1;
	}
}

-(void)setFixed:(int)x withY:(int)y andValue:(int)value
{
	if ([self CHECKPOS:[self getPos:x withY:y]])
	{
		FixedBoard[[self getPos:x withY:y]] = value;
	}
}

-(int)wrapX:(int)shift
{
	return (shift >= 0) ? (shift % BSizeX) : BSizeX + (shift % BSizeX);
}

-(int)wrapY:(int)shift
{
	return (shift >= 0) ? (shift % BSizeY) : BSizeY + (shift % BSizeY);
}

-(void)MoveBrick:(int)sourceX withSrceY:(int)sourceY andDestX:(int)destX andDestY:(int)destY
{
	
	if (([self getPos:destX withY:destY] != -1) && ([self getPos:sourceX withY:sourceY] != -1))
	{
		BOOL triggerdeletedflag = NO;
		BOOL triggermovedflag = NO;
		
		if (TriggerMoved)
		{
			MovedFixed = [self getFixed:sourceX withY:sourceY];
			MovedNewX = destX;
			MovedNewY = destY;
			MovedOldX = sourceX;
			MovedOldY = sourceY;
			triggermovedflag = YES;
		}
		
		if (TriggerDeleted && [self getBrick:destX withY:destY] != 0)
		{
			DeletedFixed = [self getFixed:destX withY:destY];
			DeletedX = destX;
			DeletedY = destY;
			triggerdeletedflag = YES;
		}
		
		// Move the brick
		if ([self CHECKPOS:[self getPos:destX withY:destY]] && [self CHECKPOS:[self getPos:sourceX withY:sourceY]])
		{
			Board[[self getPos:destX withY:destY]] = Board[[self getPos:sourceX withY:sourceY]];
			Board[[self getPos:sourceX withY:sourceY]] = 0;
			
			if (MoveFixed)
			{
				FixedBoard[[self getPos:destX withY:destY]] = FixedBoard[[self getPos:sourceX withY:sourceY]];
				FixedBoard[[self getPos:sourceX withY:sourceY]] = 0;
			}
		}
		if (triggermovedflag)
		{
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
		}
		if (triggerdeletedflag)
		{
			[ho generateEvent:CID_conOnBrickDeleted withParam:[ho getEventParam]];
		}
	}
}

-(void)fall
{
	for (int x = 0; x < BSizeX; x++)
	{
		for (int y = BSizeY - 2; y >= 0; y--)
		{
			if ([self getBrick:x withY:y + 1] == 0)
			{
				[self MoveBrick:x withSrceY:y andDestX:x andDestY:y + 1];
			}
		}
	}
}

-(void)fallUP
{
	for (int x = 0; x < BSizeX; x++)
	{
		for (int y = 1; y <= BSizeY - 1; y++)
		{
			if ([self getBrick:x withY:y - 1] == 0)
			{
				[self MoveBrick:x withSrceY:y andDestX:x andDestY:y - 1];
			}
		}
	}
}

-(void)fallLEFT
{
	for (int y = 0; y <= BSizeY; y++)
	{
		for (int x = 1; x < BSizeX; x++)
		{
			if ([self getBrick:x - 1 withY:y] == 0)
			{
				[self MoveBrick:x withSrceY:y andDestX:x - 1 andDestY:y];
			}
		}
	}
}

-(void)fallRIGHT
{
	for (int y = 0; y <= BSizeY; y++)
	{
		for (int x = BSizeX - 2; x >= 0; x--)
		{
			if ([self getBrick:x + 1 withY:y] == 0)
			{
				[self MoveBrick:x withSrceY:y andDestX:x + 1 andDestY:y];
			}
		}
	}
}

-(int)handleRunObject
{
	AddIncrement = 0;
	return 0;
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CID_conOnFoundConnected:
			return YES;
		case CID_conOnFoundBrick:
			return YES;
		case CID_conOnFoundLooped:
			return YES;
		case CID_conOnNoFoundConnected:
			return YES;
		case CID_conBrickCanFallUp:
			return [self conBrickCanFallUp:[cnd getParamExpression:rh withNum:0] withParam1:[cnd getParamExpression:rh withNum:1]];
		case CID_conBrickCanFallDown:
			return [self conBrickCanFallDown:[cnd getParamExpression:rh withNum:0] withParam1:[cnd getParamExpression:rh withNum:1]];
		case CID_conBrickCanFallLeft:
			return [self conBrickCanFallLeft:[cnd getParamExpression:rh withNum:0] withParam1:[cnd getParamExpression:rh withNum:1]];
		case CID_conBrickCanFallRight:
			return [self conBrickCanFallRight:[cnd getParamExpression:rh withNum:0] withParam1:[cnd getParamExpression:rh withNum:1]];
		case CID_conOnBrickMoved:
			return YES;
		case CID_conOnBrickDeleted:
			return YES;
		case CID_conIsEmpty:
			return [self conIsEmpty:[cnd getParamExpression:rh withNum:0] withParam1:[cnd getParamExpression:rh withNum:1]];
	}
	return NO;
}

-(BOOL)conBrickCanFallUp:(int)x withParam1:(int)y
{
	int tempbrick = 0;
	int currentbrick = [self getBrick:x withY:y];
	int belowbrick = [self getBrick:x withY:y + 1];
	
	if (belowbrick == -1 || currentbrick == 0 || currentbrick == -1)
	{
		return NO;
	}
	
	for (int i = y; i >= 0; i--)
	{
		tempbrick = [self getBrick:x withY:i];
		
		if (tempbrick == 0)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)conBrickCanFallDown:(int)x withParam1:(int)y
{
	int tempbrick = 0;
	int currentbrick = [self getBrick:x withY:y];
	int belowbrick = [self getBrick:x withY:y + 1];
	
	if (belowbrick == -1 || currentbrick == 0 || currentbrick == -1)
	{
		return NO;
	}
	
	for (int i = y; i <= BSizeY - 1; i++)
	{
		tempbrick = [self getBrick:x withY:i];
		
		if (tempbrick == 0)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)conBrickCanFallLeft:(int)x withParam1:(int)y
{
	int tempbrick = 0;
	int currentbrick = [self getBrick:x withY:y];
	int belowbrick = [self getBrick:x - 1 withY:y];
	
	if (belowbrick == -1 || currentbrick == 0 || currentbrick == -1)
	{
		return NO;
	}
	
	for (int i = x; i >= 0; i--)
	{
		tempbrick = [self getBrick:i withY:y];
		
		if (tempbrick == 0)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)conBrickCanFallRight:(int)x withParam1:(int)y
{
	int tempbrick = 0;
	int currentbrick = [self getBrick:x withY:y];
	int belowbrick = [self getBrick:x + 1 withY:y];
	
	if (belowbrick == -1 || currentbrick == 0 || currentbrick == -1)
	{
		return NO;
	}
	
	for (int i = x; i <= BSizeX - 1; i++)
	{
		tempbrick = [self getBrick:i withY:y];
		
		if (tempbrick == 0)
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)conIsEmpty:(int)x withParam1:(int)y
{
	if ([self getBrick:x withY:y] == 0)
	{
		return YES;
	}
	else
	{
		return NO;
	}
}





// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case AID_actSetBrick:
			[self actSetBrick:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpression:rh withNum:2]];
			break;
		case AID_actClear:
			[self actClear];
			break;
		case AID_actSetBoadSize:
			 [self actSetBoadSize:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actSetMinConnected:
			MinConnected = [act getParamExpression:rh withNum:0];
			break;
		case AID_actSearchHorizontal:
			[self actSearchHorizontal:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actSearchVertical:
			[self actSearchVertical:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actSearchDiagonalsLR:
			[self actSearchDiagonalsLR:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actSearchConnected:
			[self actSearchConnected:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actDeleteHorizonal:
			[self actDeleteHorizonal:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actDeleteVertical:
			[self actDeleteVertical:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actSwap:
			[self actSwap:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpression:rh withNum:2] andParam3:[act getParamExpression:rh withNum:3]];
			break;
		case AID_actDropX:
			[self actDropX:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actDropOne:
			[self fall];
			break;
		case AID_actMarkUsed:
			[self actMarkUsed:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actDeleteMarked:
			[self actDeleteMarked];
			break;
		case AID_actUndoSwap:
			[self actUndoSwap];
			break;
		case AID_actSearchDiagonalsRL:
			[self actSearchDiagonalsRL:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actLoopFoundBricks:
			[self actLoopFoundBricks];
			break;
		case AID_actSetFixedOfBrick:
			[self actSetFixedOfBrick:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpression:rh withNum:2]];
			break;
		case AID_actImportActives:
			[self actImportActives:[act getParamObject:rh withNum:0]];
			break;
		case AID_actMarkCurrentSystem:
			[self actMarkCurrentSystem];
			break;
		case AID_actMarkCurrentBrick:
			[self actMarkCurrentBrick];
			break;
		case AID_actLoopEntireBoard:
			[self actLoopEntireBoard];
			break;
		case AID_actLoopBoardOfType:
			[self actLoopBoardOfType:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actLoopSorrounding:
			[self actLoopSorrounding:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actLoopHozLine:
			[self actLoopHozLine:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actLoopVerLine:
			[self actLoopVerLine:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actClearWithType:
			[self actClearWithType:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actInsertBrick:
			[self actInsertBrick:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpression:rh withNum:2]];
			break;
		case AID_actSetOrigin:
			OriginX = [act getParamExpression:rh withNum:0];
			OriginY = [act getParamExpression:rh withNum:1];
			break;
		case AID_actSetCellDimensions:
			[self actSetCellDimensions:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actMoveFixedON:
			MoveFixed = YES;
			break;
		case AID_actMoveFixedOFF:
			MoveFixed = NO;
			break;
		case AID_actMoveBrick:
			[self MoveBrick:[act getParamExpression:rh withNum:0] withSrceY:[act getParamExpression:rh withNum:1] andDestX:[act getParamExpression:rh withNum:2] andDestY:[act getParamExpression:rh withNum:3]];
			break;
		case AID_actDropOneUp:
			[self fallUP];
			break;
		case AID_actDropOneLeft:
			[self fallLEFT];
			break;
		case AID_actDropOneRight:
			[self fallRIGHT];
			break;
		case AID_actDropXUp:
			[self actDropXUp:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actDropXLeft:
			[self actDropXLeft:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actDropXRight:
			[self actDropXRight:[act getParamExpression:rh withNum:0]];
			break;
		case AID_actSetCellValue:
			[self actSetCellValue:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1] andParam2:[act getParamExpression:rh withNum:2]];
			break;
		case AID_actDeleteBrick:
			[self actDeleteBrick:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actShiftHosLine:
			[self actShiftHosLine:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actShiftVerLine:
			[self actShiftVerLine:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case AID_actPositionBricks:
			[self actPositionBricks];
			break;
	}
}

-(void) actSetBrick:(int)x withParam1:(int)y andParam2:(int)brickType
{
	[self setBrick:x withY:y andValue:brickType];
}

-(void) actClear
{
	int size = BSizeX * BSizeY;
	for (int i = 0; i < size; i++)
	{
		Board[i] = 0;
	}
}

-(void) actSetBoadSize:(int)x withParam1:(int)y
{
	BSizeX = x; //Update size
	BSizeY = y;
	int size = BSizeX * BSizeY;
	free(Board);
	free(StateBoard);
	free(FixedBoard);
	free(CellValues);
	Board = (int*)calloc(size, sizeof(int)); //Create new array
	StateBoard = (int*)calloc(size, sizeof(int));
	FixedBoard = (int*)calloc(size, sizeof(int));
	CellValues = (int*)calloc(size, sizeof(int));
}

-(void) actSearchHorizontal:(int)brickType
{
//	int MinConnected = MinConnected;
	SearchBrickType = brickType;
	int SizeX = BSizeX;
	int SizeY = BSizeY;
	int Found = 0;
	[Bricks clear];
	int FoundTotal = 0;
	
	for (int y = 0; y < SizeY; y++)
	{
		Found = 0;
		[Bricks clear];
		
		for (int x = 0; x < SizeX; x++)
		{
			if ([self getBrick:x withY:y] == brickType)
			{
				Found++;
				if ([self CHECKPOS:[self getPos:x withY:y]])
				{
					if (StateBoard[[self getPos:x withY:y]] == 0)
					{
						[Bricks addInt:[self getPos:x withY:y]];
					}
				}
			}
			else
			{
				if (Found >= MinConnected)
				{
					[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
					FoundTotal++;
				}
				Found = 0;
				[Bricks clear];
			}
			
		}
		if (Found >= MinConnected)
		{
			[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
			FoundTotal++;
		}
//		Found = 0;
		[Bricks clear];
	}
	
	if (FoundTotal == 0)
	{
		[ho generateEvent:CID_conOnNoFoundConnected withParam:[ho getEventParam]];
	}
}

-(void) actSearchVertical:(int)brickType
{
//	int MinConnected = MinConnected;
	SearchBrickType = brickType;
	int SizeX = BSizeX;
	int SizeY = BSizeY;
	int Found = 0;
	[Bricks clear];
	int FoundTotal = 0;
	
	for (int x = 0; x < SizeX; x++)
	{
		Found = 0;
		[Bricks clear];
		
		for (int y = 0; y < SizeY; y++)
		{
			if ([self getBrick:x withY:y] == brickType)
			{
				Found++;
				if ([self CHECKPOS:[self getPos:x withY:y]])
				{
					if (StateBoard[[self getPos:x withY:y]] == 0)
					{
						[Bricks addInt:[self getPos:x withY:y]];
					}
				}
			}
			else
			{	//Trigger condition
				if (Found >= MinConnected)
				{
					[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
					FoundTotal++;
				}
				Found = 0;
				[Bricks clear];
			}
			
		} // Trigger condition
		if (Found >= MinConnected)
		{
			[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
			FoundTotal++;
		}
//		Found = 0;
		[Bricks clear];
	}
	if (FoundTotal == 0)
	{
		[ho generateEvent:CID_conOnNoFoundConnected withParam:[ho getEventParam]];
	}
}

-(void) actSearchDiagonalsLR:(int)brickType
{
	int around = BSizeY + BSizeX + 2;
	int startoffX = 0;
	int startoffY = BSizeY;
	int loopindex = 0;
	int foundtotal = 0;
	int foundbricks = 0;
	
	for (int i = 0; i < around; i++)
	{
		if (startoffY == 0)
		{
			startoffX++;
		}
		
		if (startoffY > 0)
		{
			startoffY--;
		}
		
		loopindex = 0;
		[Bricks clear];
		foundbricks = 0;
		
		while ([self getPos:startoffX + loopindex withY:startoffY + loopindex] != -1)
		{
			if ([self getBrick:startoffX + loopindex withY:startoffY + loopindex] == brickType)
			{
				foundbricks++;
				
				if ([self CHECKPOS:[self getPos:startoffX + loopindex withY:startoffY + loopindex]])
				{
					if (StateBoard[[self getPos:startoffX + loopindex withY:startoffY + loopindex]] == 0)
					{
						[Bricks addInt:[self getPos:startoffX + loopindex withY:startoffY + loopindex]];
					}
				}
			}
			else
			{
				
				if (foundbricks >= MinConnected)
				{
					[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
					foundtotal++;
				}
				
				[Bricks clear];
				foundbricks = 0;
			}
			loopindex++;
		}
		
		if (foundbricks >= MinConnected)
		{
			[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
			foundtotal++;
		}
	}
	if (foundtotal == 0)
	{
		[ho generateEvent:CID_conOnNoFoundConnected withParam:[ho getEventParam]];
	}
}

-(void) actSearchConnected:(int)startX withParam1:(int)startY
{
	int FindBrick = [self getBrick:startX withY:startY];
	int size = BSizeX * BSizeY;
	int FoundTotal = 0;
	
	int* Used = (int*)calloc(size, sizeof(int));
	
	CArrayList* BrickList = [[CArrayList alloc] init]; //<Integer>
	[BrickList addInt:[self getPos:startX withY:startY]];
	
	if ([self CHECKPOS:[self getPos:startX withY:startY]])
	{
		Used[[self getPos:startX withY:startY]] = 1;
	}
	
	[Bricks clear];
	[Bricks addInt:[self getPos:startX withY:startY]];
	
	int currentbrick = 0;
	int currentX = 0;
	int currentY = 0;
	
	int offsetX[] =
	{
		0, -1, 1, 0
	};
	int offsetY[] =
	{
		-1, 0, 0, 1
	};
	
	//char * temp ="";
	
	while ([BrickList size] > 0)
	{
		currentX = [self getXbrick:[BrickList getInt:0]];
		currentY = [self getYbrick:[BrickList getInt:0]];
		for (int dir = 0; dir < 4; dir++) //Loop around brick
		{
			currentbrick = [self getPos:currentX + offsetX[dir] withY:currentY + offsetY[dir]];
			if ([self CHECKPOS:currentbrick])
			{
				if ((Board[currentbrick] == FindBrick) && (Used[currentbrick] == 0) && (currentbrick != -1))
				{
					[BrickList addInt:currentbrick];
					[Bricks addInt:currentbrick];
					Used[currentbrick] = 1;
				}
			}
		}
		[BrickList removeIndex:0];
	}
	if ([Bricks size]>= MinConnected)
	{
		[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
		FoundTotal++;
	}
	
	[BrickList clear];
	
	if (FoundTotal == 0)
	{
		[ho generateEvent:CID_conOnNoFoundConnected withParam:[ho getEventParam]];
	}
	[BrickList release];
	free(Used);
}

-(void) actDeleteHorizonal:(int)y withParam1:(int)mode
{
	for (int del = 0; del < BSizeX; del++)
	{
		if ([self CHECKPOS:[self getPos:del withY:y]])
		{
			BOOL triggerdeletedflag = NO;
			if (TriggerDeleted)
			{
				DeletedFixed = FixedBoard[[self getPos:del withY:y]];
				DeletedX = del;
				DeletedY = y;
				triggerdeletedflag = YES;
			}
			
			Board[[self getPos:del withY:y]] = 0;
			if (MoveFixed)
			{
				FixedBoard[[self getPos:del withY:y]] = 0;
			}
			
			if (triggerdeletedflag)
			{
				[ho generateEvent:CID_conOnBrickDeleted withParam:[ho getEventParam]];
			}
		}
	}
	
	if (mode == 1) //MOVE ABOVE DOWNWARDS
	{
		for (int udX = 0; udX < BSizeX; udX++)
		{
			for (int udY = y - 1; udY >= 0; udY--)
			{
				[self MoveBrick:udX withSrceY:udY andDestX:udX andDestY:udY + 1];
			}
		}
	}
	
	if (mode == 2) //MOVE BELOW UPWARDS
	{
		for (int udX = 0; udX < BSizeX; udX++)
		{
			for (int udY = y + 1; udY < BSizeY; udY++)
			{
				[self MoveBrick:udX withSrceY:udY andDestX:udX andDestY:udY - 1];
			}
		}
	}
}

-(void) actDeleteVertical:(int)x withParam1:(int)mode
{
	for (int del = 0; del < BSizeY; del++)
	{
		if ([self CHECKPOS:[self getPos:x withY:del]])
		{
			BOOL triggerdeletedflag = NO;
			if (TriggerDeleted)
			{
				DeletedFixed = FixedBoard[[self getPos:x withY:del]];
				DeletedX = x;
				DeletedY = del;
				triggerdeletedflag = YES;
			}
			
			Board[[self getPos:x withY:del]] = 0;
			if (MoveFixed)
			{
				FixedBoard[[self getPos:x withY:del]] = 0;
			}
			
			if (triggerdeletedflag)
			{
				[ho generateEvent:CID_conOnBrickDeleted withParam:[ho getEventParam]];
			}
		}
	}
	
	if (mode == 1) //MOVE LEFT TO RIGHT ->-> ||
	{
		for (int lrY = 0; lrY < BSizeY; lrY++)
		{
			for (int lrX = x - 1; lrX >= 0; lrX--)
			{
				[self MoveBrick:lrX withSrceY:lrY andDestX:lrX + 1 andDestY:lrY];
			}
		}
	}
	if (mode == 2) //MOVE RIGHT TO LEFT   || <-<-
	{
		for (int lrY = 0; lrY < BSizeY; lrY++)
		{
			for (int lrX = x + 1; lrX < BSizeX; lrX++)
			{
				[self MoveBrick:lrX withSrceY:lrY andDestX:lrX - 1 andDestY:lrY];
			}
		}
	}
}

-(void) actSwap:(int)x1 withParam1:(int)y1 andParam2:(int)x2 andParam3:(int)y2
{
	SwapBrick1 = [self getPos:x1 withY:y1];  //Brick 1
	SwapBrick2 = [self getPos:x2 withY:y2];  //Brick 2
	
	if ([self CHECKPOS:SwapBrick1] && [self CHECKPOS:SwapBrick2])
	{
		int temp = Board[SwapBrick1];
		int tempfixed = FixedBoard[SwapBrick1];
		
		Board[SwapBrick1] = Board[SwapBrick2];
		Board[SwapBrick2] = temp;
		
		if (MoveFixed)
		{
			FixedBoard[SwapBrick1] = FixedBoard[SwapBrick2];
			FixedBoard[SwapBrick2] = tempfixed;
		}
		
		if (TriggerMoved)
		{
			MovedFixed = FixedBoard[SwapBrick1];
			MovedNewX = x1;
			MovedNewY = y1;
			MovedOldX = x2;
			MovedOldY = y2;
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
			
			MovedFixed = FixedBoard[SwapBrick2];
			MovedNewX = x2;
			MovedNewY = y2;
			MovedOldX = x1;
			MovedOldY = y1;
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
		}
	}
}

-(void) actDropX:(int)n
{
	for (int i = 0; i < n; i++)
	{
		[self fall];
	}
}

-(void) actMarkUsed:(int)x withParam1:(int)y
{
	if ([self CHECKPOS:[self getPos:x withY:y]])
	{
		StateBoard[[self getPos:x withY:y]] = 1;
	}
}

-(void) actDeleteMarked
{
	int size = BSizeX * BSizeY;
	BOOL triggerdeleteflag = NO;
	
	for (int i = 0; i < size; i++)
	{
		triggerdeleteflag = NO;
		if (StateBoard[i] == 1)
		{
			if (TriggerDeleted)
			{
				DeletedFixed = FixedBoard[i];
				DeletedX = [self getXbrick:i];
				DeletedY = [self getYbrick:i];
				triggerdeleteflag = YES;
			}
			
			Board[i] = 0;
			StateBoard[i] = 0;
			
			if (MoveFixed)
			{
				FixedBoard[i] = 0;
			}
			
			if (triggerdeleteflag)
			{
				[ho generateEvent:CID_conOnBrickDeleted withParam:[ho getEventParam]];
			}
		}
	}
}

-(void) actUndoSwap
{
	if ([self CHECKPOS:SwapBrick1] && [self CHECKPOS:SwapBrick2])
	{
		int temp = Board[SwapBrick1];
		int tempfixed = FixedBoard[SwapBrick1];
		
		Board[SwapBrick1] = Board[SwapBrick2];
		Board[SwapBrick2] = temp;
		
		if (MoveFixed)
		{
			FixedBoard[SwapBrick1] = FixedBoard[SwapBrick2];
			FixedBoard[SwapBrick2] = tempfixed;
		}
		
		if (TriggerMoved)
		{
			MovedFixed = FixedBoard[SwapBrick1];
			MovedNewX = [self getXbrick:SwapBrick1];
			MovedNewY = [self getYbrick:SwapBrick1];
			MovedOldX = [self getXbrick:SwapBrick2];
			MovedOldY = [self getYbrick:SwapBrick2];
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
			
			MovedFixed = FixedBoard[SwapBrick2];
			MovedNewX = [self getXbrick:SwapBrick2];
			MovedNewY = [self getYbrick:SwapBrick2];
			MovedOldX = [self getXbrick:SwapBrick1];
			MovedOldY = [self getYbrick:SwapBrick1];
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
		}
	}
}

-(void) actSearchDiagonalsRL:(int)brickType
{
	
	int around = BSizeY + BSizeX + 2;
	int startoffX = BSizeX - 1;
	int startoffY = BSizeY;
	int loopindex = 0;
	int foundtotal = 0;
	int foundbricks = 0;
	
	for (int i = 0; i < around; i++)
	{
		if (startoffY == 0)
		{
			startoffX--;
		}
		
		if (startoffY > 0)
		{
			startoffY--;
		}
		
		loopindex = 0;
		foundbricks = 0;
		[Bricks clear];
		
		while ([self getPos:startoffX - loopindex withY:startoffY + loopindex] != -1)
		{
			if ([self getBrick:startoffX - loopindex withY:startoffY + loopindex] == brickType)
			{
				foundbricks++;
				
				if ([self CHECKPOS:[self getPos:startoffX - loopindex withY:startoffY + loopindex]])
				{
					if (StateBoard[[self getPos:startoffX - loopindex withY:startoffY + loopindex]] == 0)
					{
						[Bricks addInt:[self getPos:startoffX - loopindex withY:startoffY + loopindex]];
					}
				}
			}
			else
			{
				
				if (foundbricks >= MinConnected)
				{
					[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
					foundtotal++;
				}
				
				[Bricks clear];
				foundbricks = 0;
			}
			
			loopindex++;
		}
		
		if (foundbricks >= MinConnected)
		{
			[ho generateEvent:CID_conOnFoundConnected withParam:[ho getEventParam]];
			foundtotal++;
		}
		
	}
	if (foundtotal == 0)
	{
		[ho generateEvent:CID_conOnNoFoundConnected withParam:[ho getEventParam]];
	}
}

-(void) actLoopFoundBricks
{
	for (int loop = 0; loop < [Bricks size]; loop++)
	{
		LoopIndex = loop;
		[ho generateEvent:CID_conOnFoundBrick withParam:[ho getEventParam]];
	}
}

-(void) actSetFixedOfBrick:(int)x withParam1:(int)y andParam2:(int)fv
{
	if ([self CHECKPOS:[self getPos:x withY:y]])
	{
		FixedBoard[[self getPos:x withY:y]] = fv;
	}
}

-(void) actImportActives:(CObject*)selected
{
	int size = BSizeX * BSizeY;
	if ([self CHECKPOS:size - AddIncrement - 1])
	{
		FixedBoard[size - AddIncrement - 1] = (selected->hoCreationId << 16) + selected->hoNumber;
	}
	AddIncrement++;
}

-(void) actMarkCurrentSystem
{
	for (int i = 0; i < [Bricks size]; i++)
	{
		if ([self CHECKPOS:[Bricks getInt:i]])
		{
			StateBoard[[Bricks getInt:i]] = 1;
		}
        //MessageBox(NULL, "Brick marked in system" , "Brick marked", MB_ICONEXCLAMATION);
	}
}

-(void) actMarkCurrentBrick
{
	if ([self CHECKPOS:[Bricks getInt:LoopIndex]])
	{
		StateBoard[[Bricks getInt:LoopIndex]] = 1;
	}
    //MessageBox(NULL, "Brick marked" , "Brick marked", MB_ICONEXCLAMATION);
}

-(void) actLoopEntireBoard
{
	int size = BSizeX * BSizeY;
	[Looped clear];
	
	for (int i = 0; i < size; i++)
	{
		[Looped addInt:i];
	}
	
	for (int u = 0; u < [Looped size]; u++)
	{
		LoopedIndex = u;
		[ho generateEvent:CID_conOnFoundLooped withParam:[ho getEventParam]];
	}
}

-(void) actLoopBoardOfType:(int)brickType
{
	int size = BSizeX * BSizeY;
	[Looped clear];
	
	for (int i = 0; i < size; i++)
	{
		if (Board[i] == brickType)
		{
			[Looped addInt:i];
		}
	}
	for (int u = 0; u < [Looped size]; u++)
	{
		LoopedIndex = u;
		[ho generateEvent:CID_conOnFoundLooped withParam:[ho getEventParam]];
	}
}

-(void) actLoopSorrounding:(int)x withParam1:(int)y
{
	[Looped clear];
	
	int offsetX[] =
	{
		-1, 0, 1, -1, 1, -1, 0, 1
	};
	int offsetY[] =
	{
		-1, -1, -1, 0, 0, 1, 1, 1
	};
	
	for (int i = 0; i < 8; i++)
	{
		if ([self getBrick:x + offsetX[i] withY:y + offsetY[i]] != -1)
		{
			[Looped addInt:[self getPos:x + offsetX[i] withY:y + offsetY[i]]];
		}
	}
	
	for (int u = 0; u < [Looped size]; u++)
	{
		LoopedIndex = u;
		[ho generateEvent:CID_conOnFoundLooped withParam:[ho getEventParam]];
	}
}

-(void) actLoopHozLine:(int)y
{
	[Looped clear];
	for (int i = 0; i < BSizeX; i++)
	{
		[Looped addInt:[self getPos:i withY:y]];
	}
	
	for (int u = 0; u < [Looped size]; u++)
	{
		LoopedIndex = u;
		[ho generateEvent:CID_conOnFoundLooped withParam:[ho getEventParam]];
	}
}

-(void) actLoopVerLine:(int)x
{
	[Looped clear];
	for (int i = 0; i < BSizeY; i++)
	{
		[Looped addInt:[self getPos:x withY:i]];
	}
	
	for (int u = 0; u < [Looped size]; u++)
	{
		LoopedIndex = u;
		[ho generateEvent:CID_conOnFoundLooped withParam:[ho getEventParam]];
	}
}

-(void) actClearWithType:(int)brickType
{
	int size = BSizeX * BSizeY;
	for (int i = 0; i < size; i++)
	{
		Board[i] = brickType;
	}
}

-(void) actInsertBrick:(int)x withParam1:(int)y andParam2:(int)brickType
{
	int size = BSizeX * BSizeY;
	BOOL triggerdeletedflag = NO;
	
	if (TriggerDeleted && Board[size - 1] != 0)
	{
		DeletedFixed = FixedBoard[size - 1];
		DeletedX = [self getXbrick:size - 1];
		DeletedY = [self getYbrick:size - 1];
		triggerdeletedflag = YES;
	}
	
	for (int i = size - 2; i > [self getPos:x withY:y]; i--)
	{
		[self MoveBrick:[self getXbrick:i] withSrceY:[self getYbrick:i] andDestX:[self getXbrick:i + 1] andDestY:[self getYbrick:i]];
	}
	
	if ([self CHECKPOS:[self getPos:x withY:y]])
	{
		Board[[self getPos:x withY:y]] = brickType;
		
		if (MoveFixed)
		{
			FixedBoard[[self getPos:x withY:y]] = 0;
		}
	}
	
	if (triggerdeletedflag && TriggerDeleted)
	{
		[ho generateEvent:CID_conOnBrickDeleted withParam:[ho getEventParam]];
	}
}

-(void) actSetCellDimensions:(int)x withParam1:(int)y
{
	CellWidth = x;
	CellHeight = y;
	if (CellWidth == 0)
	{
		CellWidth = 1;
	}
	if (CellHeight == 0)
	{
		CellHeight = 1;
	}
}

-(void) actDropXUp:(int)n
{
	for (int i = 0; i < n; i++)
	{
		[self fallUP];
	}
}

-(void) actDropXLeft:(int)n
{
	for (int i = 0; i < n; i++)
	{
		[self fallLEFT];
	}
}

-(void) actDropXRight:(int)n
{
	for (int i = 0; i < n; i++)
	{
		[self fallRIGHT];
	}
}

-(void) actSetCellValue:(int)x withParam1:(int)y andParam2:(int)value
{
	if ([self getPos:x withY:y] != -1)
	{
		CellValues[[self getPos:x withY:y]] = value;
	}
}

-(void) actDeleteBrick:(int)x withParam1:(int)y
{
	if (TriggerDeleted)
	{
		DeletedFixed = [self getFixed:x withY:y];
		DeletedX = x;
		DeletedY = y;
	}
	
	[self setBrick:x withY:y andValue:0];
	
	if (TriggerDeleted)
	{
		[ho generateEvent:CID_conOnBrickDeleted withParam:[ho getEventParam]];
	}
}

-(void) actShiftHosLine:(int)yline withParam1:(int)shift
{
	int* templine = (int*)calloc(BSizeX, sizeof(int));
	int* tempfixed = (int*)calloc(BSizeX, sizeof(int));
	
	//write to templine
	for (int i = 0; i < BSizeX; i++)
	{
		templine[i] = [self getBrick:[self wrapX:i - shift] withY:yline];
		tempfixed[i] = [self getFixed:[self wrapX:i - shift] withY:yline];
	}
	
	for (int j = 0; j < BSizeX; j++)
	{
		if (TriggerMoved)
		{
			MovedOldX = j;
			MovedOldY = yline;
			MovedNewX = [self wrapX:j + shift];
			MovedNewY = yline;
			MovedFixed = [self getFixed:j withY:yline];
		}
		
		[self setBrick:j withY:yline andValue:templine[j]];
		
		if (MoveFixed)
		{
			[self setFixed:j withY:yline andValue:tempfixed[j]];
		}
		
		if (TriggerMoved)
		{
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
		}
	}
	free(templine);
	free(tempfixed);
}

-(void) actShiftVerLine:(int)xline withParam1:(int)shift
{
	int* templine = (int*)calloc(BSizeY, sizeof(int));
	int* tempfixed = (int*)calloc(BSizeY, sizeof(int));
	
	//write to templine
	for (int i = 0; i < BSizeY; i++)
	{
		templine[i] = [self getBrick:xline withY:[self wrapY:i - shift]];
		tempfixed[i] = [self getFixed:xline withY:[self wrapY:i - shift]];
	}
	
	for (int j = 0; j < BSizeY; j++)
	{
		if (TriggerMoved)
		{
			MovedOldX = xline;
			MovedOldY = j;
			MovedNewX = xline;
			MovedNewY = [self wrapY:j + shift];
			MovedFixed = [self getFixed:xline withY:j];
		}
		
		[self setBrick:xline withY:j andValue:templine[j]];
		
		if (MoveFixed)
		{
			[self setFixed:xline withY:j andValue:tempfixed[j]];
		}
		
		if (TriggerMoved)
		{
			[ho generateEvent:CID_conOnBrickMoved withParam:[ho getEventParam]];
		}
	}
	free(templine);
	free(tempfixed);
}

-(CObject*)CObjectFromFixed:(int)fixed
{
	CObject* pObject;
	for (pObject=[ho getFirstObject]; pObject!=nil; pObject=[ho getNextObject])
	{
		if (((pObject->hoCreationId << 16) + pObject->hoNumber) == fixed)
		{
			return pObject;
		}
	}
	return nil;
}

-(void) actPositionBricks
{
	int size = BSizeX * BSizeY;
	int fixed = 0;
	CObject* active;
	int posX = 0;
	int posY = 0;
	
	for (int i = 0; i < size; i++)
	{
		fixed = FixedBoard[i];
		active = [self CObjectFromFixed:fixed];
		posX = [self getXbrick:i];
		posY = [self getYbrick:i];
		
		if (active != nil && fixed > 0)
		{
			active->hoX = CellWidth * posX + OriginX;
			active->hoY = CellHeight * posY + OriginY;
			active->roc->rcChanged = YES;
		}
		
	}
}







// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EID_expGetBrickAt:
			return [rh getTempValue:[self expGetBrick]];
		case EID_expGetXSize:
			return [rh getTempValue:BSizeX];
		case EID_expGetYSize:
			return [rh getTempValue:BSizeY];
		case EID_expGetNumBricksInSystem:
			return [rh getTempValue:[Bricks size]];
		case EID_expGetXofBrick:
			return [self expGetXofBrick:[[ho getExpParam] getInt]];
		case EID_expGetYofBrick:
			return [self expGetYofBrick:[[ho getExpParam] getInt]];
		case EID_expGetFoundBrickType:
			return [rh getTempValue:SearchBrickType];
		case EID_expGetNumBricksInHozLine:
			return [self expGetNumBricksInHozLine:[[ho getExpParam] getInt]];
		case EID_expGetNumBricksInVerLine:
			return [self expGetNumBricksInVerLine:[[ho getExpParam] getInt]];
		case EID_expCountSorrounding:
			return [self expCountSorrounding];
		case EID_expCountTotal:
			return [self expCountTotal];
		case EID_expGetFoundBrickFixed:
			return [self expGetFoundBrickFixed:[[ho getExpParam] getInt]];
		case EID_expGetFoundXofBrick:
			return [rh getTempValue:[self getXbrick:[Bricks getInt:LoopIndex]]];
		case EID_expGetFoundYofBrick:
			return [rh getTempValue:[self getYbrick:[Bricks getInt:LoopIndex]]];
		case EID_expGetTypeofBrick:
			return [rh getTempValue:SearchBrickType];
		case EID_expGetFixedOfBrick:
			return [self expGetFixedOfBrick];
		case EID_expGetFixedAt:
			return [self expGetFixedAt];
		case EID_expLoopIndex:
			return [rh getTempValue:LoopIndex];
		case EID_expFindXfromFixed:
			return [self expFindXfromFixed:[[ho getExpParam] getInt]];
		case EID_expFindYfromFixed:
			return [self expFindYfromFixed:[[ho getExpParam] getInt]];
		case EID_expFindBrickfromFixed:
			return [self expFindBrickfromFixed:[[ho getExpParam] getInt]];
		case EID_expGetLoopFoundXofBrick:
			return [rh getTempValue:[self getXbrick:[Looped getInt:LoopedIndex]]];
		case EID_expGetLoopFoundYofBrick:
			return [rh getTempValue:[self getYbrick:[Looped getInt:LoopedIndex]]];
		case EID_expGetLoopTypeofBrick:
			return [rh getTempValue:[self getBrickAtPos:[Looped getInt:LoopedIndex]]];
		case EID_expGetLoopFoundBrickFixed:
			return [self expGetLoopFoundBrickFixed];
		case EID_expLoopLoopIndex:
			return [rh getTempValue:LoopIndex];
		case EID_expGetXBrickFromX:
			return [self expGetXBrickFromX:[[ho getExpParam] getInt]];
		case EID_expGetYBrickFromY:
			return [self expGetYBrickFromY:[[ho getExpParam] getInt]];
		case EID_expSnapXtoGrid:
			return [self expSnapXtoGrid:[[ho getExpParam] getInt]];
		case EID_expSnapYtoGrid:
			return [self expSnapYtoGrid:[[ho getExpParam] getInt]];
		case EID_expGetOriginX:
			return [rh getTempValue:OriginX];
		case EID_expGetOriginY:
			return [rh getTempValue:OriginY];
		case EID_expGetCellWidth:
			return [rh getTempValue:CellWidth];
		case EID_expGetCellHeight:
			return [rh getTempValue:CellHeight];
		case EID_expGetCellValue:
			return [self expGetCellValue];
		case EID_expGetXofCell:
			return [rh getTempValue:CellWidth * [[ho getExpParam] getInt] + OriginX];
		case EID_expGetYofCell:
			return [rh getTempValue:CellHeight * [[ho getExpParam] getInt] + OriginY];
		case EID_expMovedFixed:
			return [rh getTempValue:MovedFixed];
		case EID_expMovedNewX:
			return [rh getTempValue:MovedNewX];
		case EID_expMovedNewY:
			return [rh getTempValue:MovedNewY];
		case EID_expMovedOldX:
			return [rh getTempValue:MovedOldX];
		case EID_expMovedOldY:
			return [rh getTempValue:MovedOldY];
		case EID_expDeletedFixed:
			return [rh getTempValue:DeletedFixed];
		case EID_expDeletedX:
			return [rh getTempValue:DeletedX];
		case EID_expDeletedY:
			return [rh getTempValue:DeletedY];
	}
	return [rh getTempValue:0];
}

-(CValue*) expGetXofBrick:(int)i
{
	if (i < [Bricks size])
	{
		return [rh getTempValue:[self getXbrick:[Bricks getInt:i]]];
	}
	else
	{
		return [rh getTempValue:-1];
	}
}

-(CValue*) expGetYofBrick:(int)i
{
	if (i < [Bricks size])
	{
		return [rh getTempValue:[self getYbrick:[Bricks getInt:i]]];
	}
	else
	{
		return [rh getTempValue:-1];
	}
}

-(CValue*) expGetNumBricksInHozLine:(int)y
{
	int count = 0;
	
	for (int i = 0; i < BSizeX; i++)
	{
		if ([self getBrick:i withY:y] != 0)
		{
			count++;
		}
	}
	return [rh getTempValue:count];
}

-(CValue*) expGetNumBricksInVerLine:(int)x
{
	int count = 0;
	
	for (int i = 0; i < BSizeY; i++)
	{
		if ([self getBrick:x withY:i] != 0)
		{
			count++;
		}
	}
	return [rh getTempValue:count];
}
-(int) expGetBrick
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	return [self getBrick:x withY:y];
}
	
-(CValue*) expCountSorrounding
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	int value=[[ho getExpParam] getInt];
	int offsetX[] =
	{
		-1, 0, 1, -1, 1, -1, 0, 1
	};
	int offsetY[] =
	{
		-1, -1, -1, 0, 0, 1, 1, 1
	};
	
	int count = 0;
	
	for (int i = 0; i < 8; i++)
	{
		if ([self getBrick:x + offsetX[i] withY:y + offsetY[i]] == value)
		{
			count++;
		}
	}
	
	return [rh getTempValue:count];
}

-(CValue*) expCountTotal
{
	int count = 0;
	for (int i = 0; i < BSizeX * BSizeY; i++)
	{
		if (Board[i] != 0)
		{
			count++;
		}
	}
	return [rh getTempValue:count];
}

-(CValue*) expGetFoundBrickFixed:(int)i
{
	if (i < [Looped size])
	{
		if ([self CHECKPOS:LoopIndex])
		{
			return [rh getTempValue:FixedBoard[LoopIndex]];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*) expGetFixedOfBrick
{
	if (LoopIndex < [Bricks size])
	{
		if ([self CHECKPOS:[Bricks getInt:LoopIndex]])
		{
			return [rh getTempValue:FixedBoard[[Bricks getInt:LoopIndex]]];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*) expGetFixedAt
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	if ([self getPos:x withY:y] != -1)
	{
		return [rh getTempValue:FixedBoard[[self getPos:x withY:y]]];
	}
	return [rh getTempValue:-1];
}

-(CValue*) expFindXfromFixed:(int)fixed
{
	int size = BSizeX * BSizeY;
	
	for (int i = 0; i < size; i++)
	{
		if (FixedBoard[i] == fixed)
		{
			return [rh getTempValue:[self getXbrick:i]];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*) expFindYfromFixed:(int)fixed
{
	int size = BSizeX * BSizeY;
	
	for (int i = 0; i < size; i++)
	{
		if (FixedBoard[i] == fixed)
		{
			return [rh getTempValue:[self getYbrick:i]];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*) expFindBrickfromFixed:(int)fixed
{
	int size = BSizeX * BSizeY;
	
	for (int i = 0; i < size; i++)
	{
		if (FixedBoard[i] == fixed)
		{
			return [rh getTempValue:Board[i]];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*) expGetLoopFoundBrickFixed
{
	if (LoopedIndex < [Looped size])
	{
		if ([self CHECKPOS:[Looped getInt:LoopedIndex]])
		{
			return [rh getTempValue:FixedBoard[[Looped getInt:LoopedIndex]]];
		}
	}
	return [rh getTempValue:-1];
}

-(CValue*) expGetXBrickFromX:(int)x
{
	return [rh getTempValue:(int) ((x - OriginX) / CellWidth)];
}

-(CValue*) expGetYBrickFromY:(int)y
{
	return [rh getTempValue:(int) ((y - OriginY) / CellHeight)];
}

-(CValue*) expSnapXtoGrid:(int)x
{
	return [rh getTempValue:((int) ((x - OriginX) / CellWidth)) * CellWidth + OriginX];
}

-(CValue*) expSnapYtoGrid:(int)y
{
	return [rh getTempValue:((int) ((y - OriginY) / CellHeight)) * CellHeight + OriginY];
}

-(CValue*) expGetCellValue
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	if ([self CHECKPOS:[self getPos:x withY:y]])
	{
		return [rh getTempValue:CellValues[[self getPos:x withY:y]]];
	}
	return [rh getTempValue:-1];
}

@end
