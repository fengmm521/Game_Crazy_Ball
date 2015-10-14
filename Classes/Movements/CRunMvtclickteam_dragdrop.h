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
#import <Foundation/Foundation.h>
#import "CRunMvtExtension.h"

#define FLAG_LIMITAREA 1
#define FLAG_SNAPTO 2
#define FLAG_DROPWHENLEAVE 4
#define FLAG_FORCELIMITS 8
#define VK_LBUTTON 0
#define VK_RBUTTON 2

#define SET_DragDrop_Method 4145
#define SET_DragDrop_IsLimited 4146
#define SET_DragDrop_DropOutsideArea 4147
#define SET_DragDrop_ForceWithinLimits 4148
#define SET_DragDrop_AreaX 4149
#define SET_DragDrop_AreaY 4150
#define SET_DragDrop_AreaW 4151
#define SET_DragDrop_AreaH 4152
#define SET_DragDrop_SnapToGrid 4153
#define SET_DragDrop_GridX 4154
#define SET_DragDrop_GridY 4155
#define SET_DragDrop_GridW 4156
#define SET_DragDrop_GridH 4157
#define GET_DragDrop_AreaX 4158
#define GET_DragDrop_AreaY 4159
#define GET_DragDrop_AreaW 4160
#define GET_DragDrop_AreaH 4161
#define GET_DragDrop_GridX 4162
#define GET_DragDrop_GridY 4163
#define GET_DragDrop_GridW 4164
#define GET_DragDrop_GridH 4165

@interface CRunMvtclickteam_dragdrop : CRunMvtExtension
{
	// Données edittime
	int ed_dragWithSelected;
	int ed_limitX;
	int ed_limitY;
	int ed_limitWidth;
	int ed_limitHeight;
	int ed_gridOriginX;
	int ed_gridOriginY;
	int ed_gridDx;
	int ed_gridDy;
	int ed_flags;
	
    // Donnéez runtime
	int dragWith;
	
	int lastMouseX;
	int lastMouseY;
	BOOL keyDown;
	BOOL drag;
	
	// Variables for limited area dragging
	BOOL snapToGrid;
	BOOL limitedArea;
	BOOL dropWhenLeaveArea;
	BOOL forceWithinLimits;
	int minX;
	int minY;
	int maxX;
	int maxY;
	
	int gridOriginX;
	int gridOriginY;
	int gridSizeX;
	int gridSizeY;
	int x;
	int y;
	
	int lastX;
	int lastY;
	
    BOOL bLeftLast;
    BOOL bRightLast;
    int clickLoop;
    BOOL clickLeft;
    BOOL clickRight;	
}

-(void)initialize:(CFile*)file;
-(void)handleMouseKeys;
-(BOOL)isTopMostAOAtXY_Transparent:(int)xx withY:(int)yy;
-(BOOL)move;
-(void)handleDragAndDrop;
-(void)startDragging;
-(void)checkLimitedArea;
-(void)setPosition:(int)x with:(int)y;
-(void)setXPosition:(int)x;
-(void)setYPosition:(int)y;
-(void)stop:(BOOL)bCurrent;
-(void)start;
-(void)bounce:(BOOL)bCurrent;
-(double)actionEntry:(int)action;
-(int)getSpeed;

@end
