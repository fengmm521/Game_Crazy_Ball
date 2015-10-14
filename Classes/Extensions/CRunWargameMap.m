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
// CRunWargameMap: Wargame Map object
// fin 29/01/09
//
//----------------------------------------------------------------------------------
#import "CRunWargameMap.h"
#import "CFile.h"
#import "CRunApp.h"
#import "CBitmap.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CArrayList.h"

@implementation CRunWargameMap

-(int)getNumberOfConditions
{
	return 10;
}

-(void)fillMap:(unsigned char)v
{
	for (int i = 0; i < mapWidth*mapHeight; i++)
	{
		map[i] = v;
	}
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoX = cob->cobX;
	ho->hoY = cob->cobY;
	ho->hoImgWidth = 32;
	ho->hoImgHeight = 32;
	mapWidth = [file readAInt];
	mapHeight = [file readAInt];
	oddColumnsHigh = ([file readAChar] == 0) ? NO : YES;
	map = (unsigned char*)malloc(mapWidth * mapHeight);
	[self fillMap:1];
	return YES;	 
}

-(void)destroyRunObject:(BOOL)bFast
{
	free(map);
	if (path!=nil)
	{
		[path clearRelease];
		[path release];
	}	
}

-(int)heuristic:(int)x1 withParam1:(int)y1 andParam2:(int)x2 andParam3:(int)y2 andParam4:(int)oddColumnConstant
{
	int xdist = abs(x1 - x2);
	int ydist = abs(y1 - y2);
	int additional;	// This is the number of steps we must move vertically.
	// The principle of the heuristic is that for every two columns we move across,
	// we can move one row down simultaneously. This means we can remove the number of rows
	// calculated from the absolute difference between rows.
	// The result is that we have an efficient and correct heuristic for the quickest path.
	
	// If we're in a low column, we move down a row on every odd column rather than even columns.
	if (((x1 % 2) ^ oddColumnConstant) == 1)
	{
		additional = ydist - ((xdist + 1) / 2);
	}
	else
	{
		additional = ydist - (xdist / 2);
	}
	if (additional > 0)
	{
		return xdist + additional;
	}
	return xdist;
}

-(CArrayList*)resort:(CArrayList*)openHeap withParam1:(int*)fCost
{
	CArrayList* r = [[CArrayList alloc] init];
	for (int i = 0; i < [openHeap size]; i++)
	{
		if ([r size] == 0)
		{
			[r addInt:[openHeap getInt:i]];
		}
		else
		{
			int insertAt = [r size];
			for (int j = [r size] - 1; j >= 0; j--)
			{
				if (fCost[[openHeap getInt:i]] < fCost[[r getInt:j]])
				{
					insertAt = j;
				}
			}
			[r addIndex:insertAt integer:[openHeap getInt:i]];
		}
	}
	[openHeap release];
	return r;
}

-(CArrayList*)ConstructPath:(int*)gCost withParam1:(int*)parent andParam2:(int)x1 andParam3:(int)y1 andParam4:(int)x2 andParam5:(int)y2
{
	CArrayList* rPath = [[CArrayList alloc] init];
	int pos = x2 + y2 * mapWidth;
	int finishPos = x1 + y1 * mapWidth;
	// Add the current (destination) point
	WargameMapPathPoint* point = [[WargameMapPathPoint alloc] initParams:x2 withParam1:y2 andParam2:gCost[pos]];
	[rPath add:point];
	// Go backwards through the path
	while (pos != finishPos)
	{
		pos = parent[pos];
		point = [[WargameMapPathPoint alloc] initParams:pos % mapWidth withParam1:pos / mapWidth andParam2:gCost[pos]];
		[rPath addIndex:0 object:point];
	}
	return rPath;
}

struct pair
{
	int first;
	int second;
};

-(CArrayList*)Pathfinder:(int)x1 withParam1:(int)y1 andParam2:(int)x2 andParam3:(int)y2
{
	int oddColumnConstant = oddColumnsHigh ? 1 : 0;
	unsigned char* sets = (unsigned char*)calloc(mapWidth * mapHeight, 1);
	int* fCost = (int*)calloc(mapWidth * mapHeight, sizeof(int));
	int* gCost = (int*)calloc(mapWidth * mapHeight, sizeof(int));
	int* hCost = (int*)calloc(mapWidth * mapHeight, sizeof(int));
	int* parent = (int*)calloc(mapWidth * mapHeight, sizeof(int));
	CArrayList* openHeap = [[CArrayList alloc] init]; //Integer
	sets[x1 + y1 * mapWidth] = SETS_OPEN_SET;
	[openHeap addInt:(x1 + y1 * mapWidth)];
	while ([openHeap size]!=0)
	{
		// Grab the cheapest 
		int current = [openHeap getInt:0]; //0 is the top
		int currentX = current % mapWidth;
		int currentY = (int) floor(current / mapWidth);
		if ((currentX == x2) && (currentY == y2))
		{
			// We're done!
			CArrayList* ret=[self ConstructPath:gCost  withParam1:parent  andParam2:x1  andParam3:y1  andParam4:x2  andParam5:y2];
			free(sets);
			free(fCost);
			free(gCost);
			free(hCost);
			free(parent);
			[openHeap release];
			return ret;
		}
		// Remove from open set and add to closed set
		[openHeap removeIndex:0];
		sets[current] = SETS_CLOSED_SET;
		// Is this column high? 1 if high, -1 if not.
		int sideColumnConstant = ((currentX % 2) ^ oddColumnConstant) * 2 - 1;
		// Get the neighbouring coordinates
		int neighboursX[] =
		{
			currentX - 1, currentX - 1,
			currentX, currentX,
			currentX + 1, currentX + 1
		};
		int neighboursY[] =
		{
			currentY, currentY + sideColumnConstant,
			currentY - 1, currentY + 1,
			currentY, currentY + sideColumnConstant
		};
		// and walk through them
		for (int i = 0; i < 6; i++)
		{
			// Out of bounds?
			if ((neighboursX[i] >= mapWidth) || (neighboursX[i] < 0) ||
				(neighboursY[i] >= mapHeight) || (neighboursY[i] < 0))
			{
				continue;
			}
			int next = neighboursX[i] + neighboursY[i] * mapWidth;
			// In closed set?
			if (sets[next] == SETS_CLOSED_SET)
			{
				continue;
			}
			// Impassable?
			if (map[next] >= INF_TILE_COST)
			{
				continue;
			}
			// Calculate the cost to travel to this tile
			int g = gCost[current] + map[next];
			// Is this not in the open set?
			if (sets[next] != SETS_OPEN_SET)
			{
				// Add to open set
				sets[next] = SETS_OPEN_SET;
				hCost[next] = [self heuristic:neighboursX[i] withParam1:neighboursY[i] andParam2:x2  andParam3:y2  andParam4:oddColumnConstant];
				parent[next] = current;
				gCost[next] = g;
				fCost[next] = g + hCost[next];
				// Add to heap
				[openHeap addIndex:0 integer:next];
				openHeap = [self resort:openHeap  withParam1:fCost];
			}
			// Did we find a quicker path to this tile?
			else if (g < gCost[current])
			{
				parent[next] = current;
				gCost[next] = g;
				fCost[next] = g + hCost[next];
				// We need to resort the queue now it's been updated
				openHeap = [self resort:openHeap  withParam1:fCost];
			}
		}
	}
	return nil;
}

-(int)my_max:(int)x withParam1:(int)y
{
	return (x < y) ? y : x;
}

-(BOOL)WithinBounds:(int)x withParam1:(int)y
{ //1-based
	if ((x > 0) && (x <= mapWidth) && (y > 0) && (y <= mapHeight))
	{
		return YES;
	}
	return NO;
}

-(BOOL)PointWithinBounds:(int)x
{ //1-based
	if (path == nil)
	{
		return NO;
	}
	return (x <= [path size] - 1);
}

-(unsigned char)GetTileFromArray:(int)x withParam1:(int)y
{
	return map[x + (y * mapWidth)];
}

-(void)SetTileInArray:(int)x withParam1:(int)y andParam2:(unsigned char)value
{
	map[x + (y * mapWidth)] = value;
}

-(CArrayList*)GetStraightLinePath:(int)x1 withParam1:(int)y1 andParam2:(int)x2 andParam3:(int)y2
{
	int cost = 0, cumulativeCost = 0;
	int xstep = (x1 < x2) ? 1 : -1;
	int ystep = (y1 < y2) ? 1 : -1;
	CArrayList* rPath = [[CArrayList alloc] init];
	// If the X coordinates are the same, our path is simple.
	WargameMapPathPoint* point;
	if (x1 == x2)
	{
		while (YES)
		{
			cost = [self GetTileFromArray:x1  withParam1:y1];
			if (cost >= INF_TILE_COST)
			{
				// Fail...
				[rPath release];
				return nil;
			}
			cumulativeCost += cost;
			point = [[WargameMapPathPoint alloc] initParams:x1  withParam1:y1  andParam2:cumulativeCost];
			[rPath add:point];
			if (y1 == y2)
			{
				// Finished!
				
				return rPath;
			}
			y1 += ystep;
		}
	}
	int verticalMovement = 0, adjustedWidth = 0;
	int incrementColumn = oddColumnsHigh ? 1 : 0;
	
	// Calculate the vertical distance we should be travelling.
	// Are we going in the / direction?
	if (((x1 < x2) && (y1 > y2)) || ((x1 > x2) && (y1 < y2)))
	{
		// Reverse the columns that we increment on.
		incrementColumn = 1 - incrementColumn;
	}
	// When the Y position is equal, the rightmost column must be high.
	else if ((y1 == y2) && (([self my_max:x1 withParam1:x2] & 1) == incrementColumn))
	{
		incrementColumn = 1 - incrementColumn;
	}
	
	// Move the X coordinates left so that they lie on low columns.
	adjustedWidth = x2 - (((x2 & 1) != incrementColumn) ? 1 : 0);
	adjustedWidth -= x1 - (((x1 & 1) != incrementColumn) ? 1 : 0);
	verticalMovement = abs(adjustedWidth) / 2;
	if (abs(y2 - y1) != verticalMovement)
	{
		// Not a straight line. For shame.
		return nil;
	}
	// If we're going backwards, reverse the columns we increment on. (Maybe for the second time!)
	if (x1 > x2)
	{
		incrementColumn = 1 - incrementColumn;
	}
	// Move in the X dimension.
	while (YES)
	{
		cost = [self GetTileFromArray:x1  withParam1:y1];
		if (cost >= INF_TILE_COST)
		{
			// Fail...
			[rPath clearRelease];
			[rPath release];
			return nil;
		}
		cumulativeCost += cost;
		point = [[WargameMapPathPoint alloc] initParams:x1  withParam1:y1  andParam2:cumulativeCost];
		[rPath add:point];
		if (x1 == x2)
		{
			// Finished!
			return rPath;
		}
		x1 += xstep;
		// Do we need to change the Y position?
		if ((x1 & 1) == incrementColumn)
		{
			y1 += ystep;
		}
	}
}

-(BOOL)IsHighColumn:(int)column withParam1:(BOOL)oddColumnsHigh2
{
	return ((oddColumnsHigh2 && ((column % 2) == 1)) || (!oddColumnsHigh2 && ((column % 2) == 0)));
}

-(int)GetKeypadStyleDirection:(int)pointIndex
{
	if (pointIndex == 0)
	{
		return 0;
	}
	WargameMapPathPoint* current = (WargameMapPathPoint*)[path get:pointIndex];
	WargameMapPathPoint* last = (WargameMapPathPoint*)[path get:pointIndex - 1];
	
	switch (current->x - last->x)
	{
		case 0:
			// Same column. This means either north or south - simple.
			return (current->y < last->y) ? 8 : 2;
			
		case -1:
			// We've moved a column west.
			// In high columns, at the south-east Y positions are not equal.
			// but in low columns, at the south-east Y positions are equal.
			// Use XOR to negate the equality for high columns.
			return ((current->y == last->y) ^ ([self IsHighColumn:current->x withParam1:oddColumnsHigh] ? 1 : 7));
			
		case 1:
			// We've moved a column east.
			return ((current->y == last->y) ^ ([self IsHighColumn:current->x withParam1:oddColumnsHigh] ? 3 : 9));
	}
	// If we reached here something went wrong somewhere (how helpful)
	return 0;
}


// Conditions
// --------------------------------------------------
-(BOOL)cCompareTileCost:(int)x withParam1:(int)y andParam2:(CCndExtension*)cnd
{
	if ([self WithinBounds:x  withParam1:y])
	{
		return [cnd compareValues:rh  withNum:2  andValue:[rh getTempValue:[self GetTileFromArray:x - 1  withParam1:y - 1]]];
	}
	return [cnd compareValues:rh  withNum:2  andValue:[rh getTempValue:INF_TILE_COST]];
}

-(BOOL)cTileImpassable:(int)x withParam1:(int)y
{
	if ([self WithinBounds:x  withParam1:y])
	{
		return ([self GetTileFromArray:x - 1  withParam1:y - 1] >= INF_TILE_COST) ? YES : NO;
	}
	return YES;
}

-(BOOL)cPathExists
{
	if (path != nil)
	{
		return YES;
	}
	return NO;
}

-(BOOL)cComparePathCost:(CCndExtension*)cnd
{
	if (path == nil)
	{
		return [cnd compareValues:rh  withNum:0  andValue:[rh getTempValue:0]];
	}
	return [cnd compareValues:rh withNum:0 andValue:[rh getTempValue:((WargameMapPathPoint*)[path get:[path size]-1])->cumulativeCost]];
}
			 	
-(BOOL)cComparePathLength:(CCndExtension*)cnd
{
	if (path == nil)
	{
		return [cnd compareValues:rh  withNum:0  andValue:[rh getTempValue:0]];
	}
	return [cnd compareValues:rh withNum:0 andValue:[rh getTempValue:[path size]-1]];
}
			
-(BOOL)cCompareCostToPoint:(int)pointIndex withParam1:(CCndExtension*)cnd
{
	if (path == nil)
	{
		return [cnd compareValues:rh  withNum:1  andValue:[rh getTempValue:0]];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [cnd compareValues:rh  withNum:1  andValue:[rh getTempValue:0]];
	}
	return [cnd compareValues:rh  withNum:1 andValue:[rh getTempValue:((WargameMapPathPoint*)[path get:pointIndex])->cumulativeCost]];
}
			 
-(BOOL)cComparePointDirection:(int)pointIndex withParam1:(CCndExtension*)cnd
{
	if (path == nil)
	{
		return [cnd compareValues:rh  withNum:1  andValue:[rh getTempValue:0]];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [cnd compareValues:rh  withNum:1  andValue:[rh getTempValue:0]];
	}
	return [cnd compareValues:rh  withNum:1  andValue:[rh getTempValue:[self GetKeypadStyleDirection:pointIndex]]];
}

-(BOOL)cCompareCostToCurrent:(CCndExtension*)cnd
{
	if (path == nil)
	{
		return [cnd compareValues:rh  withNum:0  andValue:[rh getTempValue:0]];
	}
	return [cnd compareValues:rh  withNum:0 andValue:[rh getTempValue:((WargameMapPathPoint*)[path get:iterator])->cumulativeCost]];
}
			 
-(BOOL)cCompareCurrentDirection:(CCndExtension*)cnd
{
	if (path == nil)
	{
		return [cnd compareValues:rh  withNum:0  andValue:[rh getTempValue:0]];
	}
	if (![self PointWithinBounds:iterator])
	{
		return [cnd compareValues:rh  withNum:0  andValue:[rh getTempValue:0]];
	}
	return [cnd compareValues:rh  withNum:0  andValue:[rh getTempValue:[self GetKeypadStyleDirection:iterator]]];
}

-(BOOL)cEndOfPath
{
	if (path == nil)
	{
		return YES;
	}
	if (iterator >= [path size] - 1)
	{
		return YES;
	}
	return NO;
}



-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_COMPARETILECOST:
			return [self cCompareTileCost:[cnd getParamExpression:rh withNum:0]  withParam1:[cnd getParamExpression:rh withNum:1]  andParam2:cnd];
		case CND_TILEIMPASSABLE:
			return [self cTileImpassable:[cnd getParamExpression:rh withNum:0]  withParam1:[cnd getParamExpression:rh withNum:1]];
		case CND_PATHEXISTS:
			return [self cPathExists];
		case CND_COMPAREPATHCOST:
			return [self cComparePathCost:cnd];
		case CND_COMPAREPATHLENGTH:
			return [self cComparePathLength:cnd];
		case CND_COMPARECOSTTOPOINT:
			return [self cCompareCostToPoint:[cnd getParamExpression:rh withNum:0]  withParam1:cnd];
		case CND_COMPAREPOINTDIRECTION:
			return [self cComparePointDirection:[cnd getParamExpression:rh withNum:0]  withParam1:cnd];
		case CND_COMPARECOSTTOCURRENT:
			return [self cCompareCostToCurrent:cnd];
		case CND_COMPARECURRENTDIRECTION:
			return [self cCompareCurrentDirection:cnd];
		case CND_EXTENDOFPATH:
			return [self cEndOfPath];
	}
	return NO;
}
	
	
// Actions
// -------------------------------------------------
-(void)aSetWidth:(int)w
{
	mapWidth = w;
	free(map);
	map = (unsigned char*)malloc(w * mapHeight);
	[self fillMap:0];
}

-(void)aSetHeight:(int)h
{
	mapHeight = h;
	free(map);
	map = (unsigned char*)malloc(h * mapWidth);
	[self fillMap:0];
}

-(void)aSetCost:(int)x withParam1:(int)y andParam2:(int)cost
{
	if ([self WithinBounds:x  withParam1:y])
	{
		if (cost > 255)
		{
			cost = 255;
		}
		[self SetTileInArray:x - 1  withParam1:y - 1  andParam2:(unsigned char)cost];
	}
}

-(void)aCalculatePath:(int)startX2 withParam1:(int)startY2 andParam2:(int)destX2 andParam3:(int)destY2
{
	startX = startX2;
	startY = startY2;
	destX = destX2;
	destY = destY2;
	if (path!=nil)
	{
		[path clearRelease];
		[path release];
	}
	path = [self Pathfinder:startX - 1  withParam1:startY - 1  andParam2:destX - 1  andParam3:destY - 1];
	iterator = 0;
}

-(void)aNextPoint
{
	if ((path != nil) && (iterator < [path size]  - 1))
	{
		iterator++;
	}
}

-(void)aPrevPoint
{
	if (iterator > 0)
	{
		iterator--;
	}
}

-(void)aResetPoint
{
	iterator = 0;
}

-(void)aCalculateLOS:(int)startX2 withParam1:(int)startY2 andParam2:(int)destX2 andParam3:(int)destY2
{
	startX = startX2;
	startY = startY2;
	destX = destX2;
	destY = destY2;
	if (path!=nil)
	{
		[path clearRelease];
		[path release];
	}
	path = [self GetStraightLinePath:startX - 1  withParam1:startY - 1  andParam2:destX - 1  andParam3:destY - 1];
	iterator = 0;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{
		case ACT_EXTSETWIDTH:
			[self aSetWidth:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_EXTSETHEIGHT:
			[self aSetHeight:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETCOST:
			[self aSetCost:[act getParamExpression:rh withNum:0]  withParam1:[act getParamExpression:rh withNum:1]  andParam2:[act getParamExpression:rh withNum:2]];
			break;
		case ACT_CALCULATEPATH:
			[self aCalculatePath:[act getParamExpression:rh withNum:0]  withParam1:[act getParamExpression:rh withNum:1]  andParam2:[act getParamExpression:rh withNum:2]  andParam3:[act getParamExpression:rh withNum:3]];
			break;
		case ACT_NEXTPOINT:
			[self aNextPoint];
			break;
		case ACT_PREVPOINT:
			[self aPrevPoint];
			break;
		case ACT_RESETPOINT:
			[self aResetPoint];
			break;
		case ACT_CALCULATELOS:
			[self aCalculateLOS:[act getParamExpression:rh withNum:0]  withParam1:[act getParamExpression:rh withNum:1]  andParam2:[act getParamExpression:rh withNum:2]  andParam3:[act getParamExpression:rh withNum:3]];
			break;
	}
}

// Expressions
// --------------------------------------------

-(CValue*)eGetTileCost
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	if (map == nil)
	{
		return [rh getTempValue:0];
	}
	if (![self WithinBounds:x  withParam1:y])
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:[self GetTileFromArray:x - 1  withParam1:y - 1]];
}

-(CValue*)eGetPathCost
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*)[path get:[path size]-1])->cumulativeCost];
}
			
-(CValue*)eGetPathLength
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:[path size]-1];
}

-(CValue*)eGetCostToPoint:(int)pointIndex
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*)[path get:pointIndex])->cumulativeCost];
}
			
-(CValue*)eGetPointDirection:(int)pointIndex
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:[self GetKeypadStyleDirection:pointIndex]];
}

-(CValue*)eGetPointX:(int)pointIndex
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*)[path get:pointIndex])->x + 1];
}
			
-(CValue*)eGetPointY:(int)pointIndex
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*)[path get:pointIndex])->y + 1];
}
			
-(CValue*)eGetCostToCurrent
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*)[path get:iterator])->cumulativeCost];
}
			
-(CValue*)eGetCurrentDirection
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	if (iterator == 0)
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:[self GetKeypadStyleDirection:iterator]];
}

-(CValue*)eGetCurrentX
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*) [path get:iterator])->x + 1];
}

-(CValue*)eGetCurrentY
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	return [rh getTempValue:((WargameMapPathPoint*)[path get:iterator])->y + 1];
}

-(CValue*)eGetCostAtPoint:(int)pointIndex
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	if (![self PointWithinBounds:pointIndex])
	{
		return [rh getTempValue:0];
	}
	WargameMapPathPoint* p = (WargameMapPathPoint*)[path get:pointIndex];
	return [rh getTempValue:[self GetTileFromArray:p->x  withParam1:p->y]];
}

-(CValue*)eGetCostAtCurrent
{
	if (path == nil)
	{
		return [rh getTempValue:0];
	}
	WargameMapPathPoint* p = (WargameMapPathPoint*)[path get:iterator];
	return [rh getTempValue:[self GetTileFromArray:p->x  withParam1:p->y]];
}

-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_EXTGETWIDTH:
			return [rh getTempValue:mapWidth];
		case EXP_EXTGETHEIGHT:
			return [rh getTempValue:mapHeight];
		case EXP_GETTILECOST:
			return [self eGetTileCost];
		case EXP_GETPATHCOST:
			return [self eGetPathCost];
		case EXP_GETPATHLENGTH:
			return [self eGetPathLength];
		case EXP_GETCOSTTOPOINT:
			return [self eGetCostToPoint:[[ho getExpParam] getInt]];
		case EXP_GETPOINTDIRECTION:
			return [self eGetPointDirection:[[ho getExpParam] getInt]];
		case EXP_GETPOINTX:
			return [self eGetPointX:[[ho getExpParam] getInt]];
		case EXP_GETPOINTY:
			return [self eGetPointY:[[ho getExpParam] getInt]];
		case EXP_GETSTARTX:
			return [rh getTempValue:startX];
		case EXP_GETSTARTY:
			return [rh getTempValue:startY];
		case EXP_GETDESTX:
			return [rh getTempValue:destX];
		case EXP_GETDESTY:
			return [rh getTempValue:destY];
		case EXP_GETCURRENTINDEX:
			return [rh getTempValue:iterator];
		case EXP_GETCOSTTOCURRENT:
			return [self eGetCostToCurrent];
		case EXP_GETCURRENTDIRECTION:
			return [self eGetCurrentDirection];
		case EXP_GETCURRENTX:
			return [self eGetCurrentX];
		case EXP_GETCURRENTY:
			return [self eGetCurrentY];
		case EXP_GETCOSTATPOINT:
			return [self eGetCostAtPoint:[[ho getExpParam] getInt]];
		case EXP_GETCOSTATCURRENT:
			return [self eGetCostAtCurrent];
	}
	return [rh getTempValue:0];//won't be used
}

@end
			
@implementation WargameMapPathPoint

-(id)initParams:(int)xx withParam1:(int)yy andParam2:(int)cc
{
	x=xx;
	y=yy;
	cumulativeCost=cc;
	return self;
}

@end