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
// CRUNMVTCLICKTEAM-DRAGDROP
//
//----------------------------------------------------------------------------------
#import "CRunMvtclickteam_dragdrop.h"
#import "CObject.h"
#import "CRCom.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CRAni.h"
#import "CAnim.h"
#import "CRun.h"
#import "CFile.h"
#import "CServices.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "COI.h"

@implementation CRunMvtclickteam_dragdrop

-(void)initialize:(CFile*)file
{
	[file skipBytes:1];
	
	//Flags
	ed_flags = [file readAInt];
	ed_dragWithSelected = [file readAInt];
	ed_limitX = [file readAInt];
	ed_limitY = [file readAInt];
	ed_limitWidth = [file readAInt];
	ed_limitHeight = [file readAInt];
	ed_gridOriginX = [file readAInt];
	ed_gridOriginY = [file readAInt];
	ed_gridDx = [file readAInt];
	ed_gridDy = [file readAInt];
	
	//*** General variables
	dragWith = ed_dragWithSelected;
	drag = NO;
	keyDown = NO;
	snapToGrid = ((ed_flags & FLAG_SNAPTO) != 0);
	limitedArea = ((ed_flags & FLAG_LIMITAREA) != 0);
	dropWhenLeaveArea = ((ed_flags & FLAG_DROPWHENLEAVE) != 0);
	forceWithinLimits = ((ed_flags & FLAG_FORCELIMITS) != 0);
	
	// Limit area settings
	minX = ed_limitX;
	minY = ed_limitY;
	maxX = minX + ed_limitWidth;
	maxY = minY + ed_limitHeight;
	
	// Grid settings
	gridOriginX = ed_gridOriginX;
	gridOriginY = ed_gridOriginY;
	gridSizeX = ed_gridDx;
	gridSizeY = ed_gridDy;
	
	lastX = ho->hoX;
	lastY = ho->hoY;
}

-(void)handleMouseKeys
{
	BOOL bLeft=ho->hoAdRunHeader->rhApp->bMouseDown;
	if (bLeft!=bLeftLast)
	{
		bLeftLast=bLeft;
		if (bLeft)
		{
			if (clickLoop != ho->hoAdRunHeader->rhLoopCount + 1)
				clickRight = NO;
			clickLoop = ho->hoAdRunHeader->rhLoopCount + 1;
			clickLeft = YES;
			x = rh->rh2MouseX;
			y = rh->rh2MouseY;
		}
	}
}

-(BOOL)isTopMostAOAtXY_Transparent:(int)xx withY:(int)yy
{
	CObject* pRo = nil;
	CSprite* pSpr = nil;
    
	do
	{
		// Get the next sprite at x,y
		pSpr = [ho->hoAdRunHeader->spriteGen spriteCol_TestPoint:pSpr withLayer:-1 andX:xx andY:yy andFlags:SCF_EVENNOCOL];
		
		if ( pSpr == nil )
			break;
		
		// Object not being destroyed?
		if ( (pSpr->sprFlags & SF_TOKILL) == 0 )
		{
			// Get object pointer
			CObject* pHo = pSpr->sprExtraInfo;
			
			// Active object ?
			if ( pHo != nil && pHo->hoType == OBJ_SPR )
				pRo = pHo;
			
		}
	} while (pSpr != nil);
    if (pRo==ho)
    {
        return YES;
    }
    
	// Explore other objects
	// ~~~~~~~~~~~~~~~~~~~~~~~~~
    int count=0;
	int i;
	CObject* pHox;
	int left, top, right, bottom;
	
	for (i=0; i<ho->hoAdRunHeader->rhNObjects; i++)
	{
		while(ho->hoAdRunHeader->rhObjectList[count]==nil)
			count++;
		pHox=ho->hoAdRunHeader->rhObjectList[count];
		count++;
		
		left=pHox->hoX - pHox->hoImgXSpot;
		top=pHox->hoY - pHox->hoImgYSpot;
		right=left + pHox->hoImgWidth;
		bottom=top + pHox->hoImgHeight;
		if (x>=left && x<right && y>=top && y<bottom)
		{
			if ((pHox->hoFlags & HOF_DESTROYED) == 0)
			{
				if (pHox->hoType!=OBJ_SPR)
				{
					pRo=pHox;
				}
			}
		}
	}
	
	if( pRo != nil )
	{
		if( pRo == ho )
		{
			return YES;
		}
	}
	return NO;
}

-(BOOL)move
{
	[self handleMouseKeys];
	[self handleDragAndDrop];
	
	// Handle the objects movement, if it needs to be moved.
	if( drag )
	{
		int dX = ho->hoAdRunHeader->rhApp->mouseX - lastMouseX;
		int dY = ho->hoAdRunHeader->rhApp->mouseY - lastMouseY;
		
		lastMouseX = ho->hoAdRunHeader->rhApp->mouseX;
		lastMouseY = ho->hoAdRunHeader->rhApp->mouseY;
		
		[self animations:ANIMID_WALK];
		x += dX;
		y += dY;
		
		ho->hoX = x;
		ho->hoY = y;
		
		if(snapToGrid)
		{
			int topX = ((ho->hoX - ho->hoImgXSpot) - gridOriginX) % gridSizeX;
			int topY = ((ho->hoY - ho->hoImgYSpot) - gridOriginY) % gridSizeY;
			
			ho->hoX -= topX;
			ho->hoY -= topY;
		}
		
		[self checkLimitedArea];
		[self collisions];
		
		return YES;
	}
	else
	{
		BOOL hasChanged = NO;
		if (forceWithinLimits)
		{
			int oldX = ho->hoX;
			int oldY = ho->hoY;
			[self checkLimitedArea];
			if ((oldX != ho->hoX) || (oldY != ho->hoY))
				hasChanged = YES;
		}
		[self animations:ANIMID_STOP];
		[self collisions];
		return hasChanged;
	}
}

-(void)handleDragAndDrop
{
	if( !drag )
	{
		// Check if dragging of object has started
		if( dragWith == 0)
		{
			// Left mouse button is down
			if( ho->hoAdRunHeader->rhApp->bMouseDown)
			{
				if( keyDown == NO )
				{
					keyDown = YES;
					
					if( [self isTopMostAOAtXY_Transparent:ho->hoAdRunHeader->rhApp->mouseX withY:ho->hoAdRunHeader->rhApp->mouseY] )
					{
						[self startDragging];
					}
				}
			}
			else
			{
				keyDown = NO;
			}
		}
/*		else if( dragWith == 1)
		{
			// Right mouse button is down
			if( ho->hoAdRunHeader->rhApp.getKeyState(VK_RBUTTON))
			{
				if( keyDown == false )
				{
					keyDown = true;
					
					if( isTopMostAOAtXY_Transparent(ho.hoAdRunHeader.rhApp.mouseX, ho.hoAdRunHeader.rhApp.mouseY) )
					{
						startDragging();
					}
				}
			}
			else
			{
				keyDown = false;
			}
		}
*/		else if( dragWith == 2)
		{
			// Left mouse button clicked or currently down
			if (ho->hoAdRunHeader->rhApp->bMouseDown)
			{
				if( keyDown == NO )
				{
					keyDown = YES;
				}
			}
			else
			{
				if(keyDown == YES)
				{
					if( [self isTopMostAOAtXY_Transparent:ho->hoAdRunHeader->rhApp->mouseX withY:ho->hoAdRunHeader->rhApp->mouseY] )
					{
						[self startDragging];
					}
				}
				
				keyDown = NO;
			}
		}
/*		else if( dragWith == 3)
		{
			// Right mouse button clicked or currently down
			if (((clickLoop == ho->hoAdRunHeader->rhLoopCount) && clickRight) || (ho.hoAdRunHeader.rhApp.getKeyState(VK_RBUTTON) )
			{
				if( keyDown == NO )
				{
					keyDown = YES;
				}
			}
			else
			{
				if(keyDown == YES)
				{
					if( [self isTopMostAOAtXY_Transparent:ho->hoAdRunHeader->rhApp->mouseX withY:ho->hoAdRunHeader->rhApp->mouseY] )
					{
						[self startDragging];
					}
				}
				
				keyDown = NO;
			}
		}
*/	
	}
	else
	{
		// Check if dragging of object has ended.
		if( dragWith == 0)
		{
			// Left mouse button released
			if( ho->hoAdRunHeader->rhApp->bMouseDown==false)
			{
				[self stop:YES];
			}
		}
/*		else if( dragWith == 1)
		{
			// Right mouse button released
			if(ho.hoAdRunHeader.rhApp.getKeyState(VK_RBUTTON)==false)
			{
				stop(true);
			}
		}
*/		else if( dragWith == 2)
		{
			// Left mouse button clicked or currently down
			if (((clickLoop == ho->hoAdRunHeader->rhLoopCount) && clickLeft) || (ho->hoAdRunHeader->rhApp->bMouseDown))
			{
				keyDown = YES;
			}
			else
			{
				if(keyDown)
				{
					[self stop:YES];
				}
			}
		}
/*		else if( dragWith == 3)
		{
			// Right mouse button clicked or currently down
			if (((clickLoop == ho.hoAdRunHeader.rhLoopCount) && clickRight) || (ho.hoAdRunHeader.rhApp.getKeyState(VK_RBUTTON)))
			{
				keyDown = true;
			}
			else
			{
				if(keyDown)
				{
					stop(true);
				}
			}
		}
 */
	}
}

-(void)startDragging
{
	lastMouseX = ho->hoAdRunHeader->rhApp->mouseX;
	lastMouseY = ho->hoAdRunHeader->rhApp->mouseY;
	
	lastX = ho->hoX;
	lastY = ho->hoY;
	
	x = ho->hoX;
	y = ho->hoY;
	
	drag = YES;
	
	ho->roc->rcSpeed = 50;
}

-(void)checkLimitedArea
{
	if( limitedArea )
	{
		// Check x-coordinates
		if( ho->hoX < minX)
		{
			ho->hoX = minX;
			if(dropWhenLeaveArea) drag = NO;
		}
		else if( ho->hoX > maxX)
		{
			ho->hoX = maxX;
			if(dropWhenLeaveArea) drag = NO;
		}
		
		// Check y-coordinates
		if( ho->hoY < minY)
		{
			ho->hoY = minY;
			if(dropWhenLeaveArea) drag = NO;
		}
		else if( ho->hoY > maxY)
		{
			ho->hoY = maxY;
			if(dropWhenLeaveArea) drag = NO;
		}
	}
}

-(void)setPosition:(int)xx with:(int)yy
{
	ho->hoX=x;
	ho->hoY=y;
}

-(void)setXPosition:(int)xx
{
	ho->hoX=xx;
}

-(void)setYPosition:(int)yy
{
	ho->hoY=yy;
}

-(void)stop:(BOOL)bCurrent
{
	drag = NO;
	keyDown = NO;
	
	ho->roc->rcSpeed = 0;
}

-(void)start
{
	[self startDragging];
}

-(void)bounce:(BOOL)bCurrent
{
	if( drag )
	{
		[self setPosition:lastX withY:lastY];
		[self stop:YES];
	}
}

//****************************************
//*** Extension Actions entry ************
//****************************************
-(double)actionEntry:(int)action
{
	int param;
	switch (action)
	{
		case SET_DragDrop_Method:
		{
			param=(int)[self getParamDouble];
			// Methods 0-4 supported
			if ((param >= 0) && (param < 5))
			{
				dragWith = param;
			}
		}
			break; 
			
		case SET_DragDrop_IsLimited:
		{
			param=(int)[self getParamDouble];
			limitedArea = param != 0;
		}
			break;
			
		case SET_DragDrop_DropOutsideArea:
		{
			param=(int)[self getParamDouble];
			dropWhenLeaveArea = param != 0;
		}
			break;
			
		case SET_DragDrop_ForceWithinLimits:
		{
			param=(int)[self getParamDouble];
			forceWithinLimits = param != 0;
		}
			break;
			
		case SET_DragDrop_AreaX:
		{
			param=(int)[self getParamDouble];
			minX = param;
		}
			break;
			
		case SET_DragDrop_AreaY:
		{
			param=(int)[self getParamDouble];
			minY = param;
		}
			break;
			
		case SET_DragDrop_AreaW:
		{
			param=(int)[self getParamDouble];
			maxX = minX + param;
		}
			break;
			
		case SET_DragDrop_AreaH:
		{
			param=(int)[self getParamDouble];
			maxY = minY + param;
		}
			break;
			
		case SET_DragDrop_SnapToGrid:
		{
			param=(int)[self getParamDouble];
			snapToGrid = param != 0;
		}
			break;
			
		case SET_DragDrop_GridX:
		{
			param=(int)[self getParamDouble];
			gridOriginX = param;
		}
			break;
			
		case SET_DragDrop_GridY:
		{
			param=(int)[self getParamDouble];
			gridOriginY = param;
		}
			break;
			
		case SET_DragDrop_GridW:
		{
			param=(int)[self getParamDouble];
			gridSizeX = param;
		}
			break;
			
		case SET_DragDrop_GridH:
		{
			param=(int)[self getParamDouble];
			gridSizeY = param;
		}
			break;
			
		case GET_DragDrop_AreaX:
		{
			return minX;
		}
			
		case GET_DragDrop_AreaY:
		{
			return minY;
		}
			
		case GET_DragDrop_AreaW:
		{
			return maxX - minX;
		}
			
		case GET_DragDrop_AreaH:
		{
			return maxY - minY;
		}
			
		case GET_DragDrop_GridX:
		{
			return gridOriginX;
		}
			
		case GET_DragDrop_GridY:
		{
			return gridOriginY;
		}
			
		case GET_DragDrop_GridW:
		{
			return gridSizeX;
		}
			
		case GET_DragDrop_GridH:
		{
			return gridSizeY;
		}
	}
	return 0;
}

-(int)getSpeed
{
	return ho->roc->rcSpeed;
}

-(int)getAcceleration
{
	return 100;
}

-(int)getDeceleration
{
	return 100;
}


@end
