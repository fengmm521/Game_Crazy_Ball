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
// CRUNFRAME : contenu d'une frame
//
//----------------------------------------------------------------------------------
#import "CRunFrame.h"
#import "CRunApp.h"
#import "CRunView.h"
#import "CFile.h"
#import "CLOList.h"
#import "CImageBank.h"
#import "CFontBank.h"
#import "CSoundBank.h"
#import "CEventProgram.h"
#import "CRect.h"
#import "CChunk.h"
#import "CServices.h"
#import "CLayer.h"
#import "CLO.h"
#import "COIList.h"
#import "COI.h"
#import "CImage.h"
#import "CMask.h"
#import "CRect.h"
#import "CObjectCommon.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CObject.h"
#import "COC.h"
#import "CRun.h"
#import "CBkd2.h"
#import "CArrayList.h"
#import "CColMask.h"
#import "COCBackground.h"
#import "CTrans.h"
#import "CTransitionData.h"


@implementation CRunFrame

-(id)initWithApp:(CRunApp*)pApp
{
	app=pApp;
	frameName=nil;
	colMask=nil;
	fadeIn=nil;
	fadeOut=nil;
	m_wRandomSeed=-1;
	
	return self;
}
-(void)dealloc
{
	if (frameName!=nil)
	{ 
		[frameName release];
	}
	[LOList release];
	int n;
	for (n=0; n<nLayers; n++)
	{
		[layers[n] release];
	}
	free(layers);
	if (colMask!=nil)
	{
		[colMask release];
	}
	if (fadeIn!=nil)
	{
		[fadeIn release];
	}
	if (fadeOut!=nil)
	{
		[fadeOut release];
	}
	if (pTrans!=nil)
	{
		[pTrans release];
	}
	[super dealloc];
}

// Charge la frame
-(BOOL)loadFullFrame:(int)index
{
	// Positionne le fichier
	[app->file seek:app->frameOffsets[index]];
	
	// Charge la frame
	LOList = [[CLOList alloc] initWithApp:app];
	
	CChunk* chk = [[CChunk alloc] init];
	NSUInteger posEnd;
	int nOldFrameWidth = 0;
	int nOldFrameHeight = 0;
	m_wRandomSeed = -1;
	while (chk->chID != CHUNK_LAST)	
	{
		[chk readHeader:app->file];
		if (chk->chSize == 0)
		{
			continue;
		}
		posEnd = [app->file getFilePointer] + chk->chSize;
		switch (chk->chID)
		{
			case CHUNK_FRAMEHEADER:
				[self loadHeader];
				if ((leFlags & LEF_RESIZEATSTART) != 0)
				{
					nOldFrameWidth = leWidth;
					nOldFrameHeight = leHeight;
					
					leWidth = (int)app->runView.bounds.size.width;
					leHeight = (int)app->runView.bounds.size.height;
					
					// To keep compatibility with previous versions without virtual rectangle (nÈcessaire ?)
					leVirtualRect.left = leVirtualRect.top = 0;
					leVirtualRect.right = leWidth;
					leVirtualRect.bottom = leHeight;
				}
				
				// B243
				if ((leFlags & LEF_RESIZEATSTART) != 0)
				{
					leEditWinWidth = (int)app->runView.bounds.size.width;
					leEditWinHeight = (int)app->runView.bounds.size.height;
				}
				else
				{
					leEditWinWidth = MIN(app->gaCxWin, leWidth);
					leEditWinHeight = MIN(app->gaCyWin, leHeight);
				}
				originalWinWidth = leEditWinWidth;
				originalWinHeight = leEditWinHeight;
				break;
					
			case CHUNK_FRAMEVIRTUALRECT:
				leVirtualRect = CRectLoad(app->file);
				if ((leFlags & LEF_RESIZEATSTART) != 0)
				{
					if (leVirtualRect.width() == nOldFrameWidth || leVirtualRect.width() < leWidth)
					{
						leVirtualRect.right = leVirtualRect.left + leWidth;
					}
					if (leVirtualRect.height() == nOldFrameHeight || leVirtualRect.height() < leHeight)
					{
						leVirtualRect.bottom = leVirtualRect.top + leHeight;
					}
				}
				break;
			
			case CHUNK_RANDOMSEED:
				m_wRandomSeed = [app->file readAShort];
				break;
				
			case CHUNK_MVTTIMERBASE:
				m_dwMvtTimerBase = [app->file readAInt];
				break;
				
			case CHUNK_FRAMENAME:
				frameName = [app->file readAString];
				break;
				
			case CHUNK_FRAMELAYERS:
				[self loadLayers];
				break;
				
			case CHUNK_FRAMEITEMINSTANCES:
				[LOList load];
				break;
				
			case CHUNK_FRAME_IPHONE_OPTIONS:
				joystick=[app->file readAShort];
				iPhoneOptions=[app->file readAShort];
				break;
				
			case CHUNK_FRAMEFADEIN:
				fadeIn = [[CTransitionData alloc] init];
				[fadeIn load:app->file];
				break;
				
			case CHUNK_FRAMEFADEOUT:
				fadeOut = [[CTransitionData alloc] init];
				[fadeOut load:app->file];
				break;
				
			case CHUNK_FRAMEEVENTS:
				[app->events load];
				maxObjects = app->events->maxObjects;
//				[evtProg relocatePath:app];
				break;
		}
		// Positionne a la fin du chunk
		[app->file seek:posEnd];
	}
	
	[chk release];

	// Marque les OI a charger
	[app->OIList resetToLoad];
	int n;
	for (n = 0; n < LOList->nIndex; n++)
	{
		CLO* lo = [LOList getLOFromIndex:(short)n];
		[app->OIList setToLoad:lo->loOiHandle];
	}

	// Charge les OI et les elements des banques
	[app->imageBank resetToLoad];
	[app->fontBank resetToLoad];
	[app->OIList load:app->file];
	[app->OIList enumElements:app->imageBank withFont:app->fontBank];
	[app->imageBank load];
	[app->fontBank load];
	[app->events enumSounds:app->soundBank];
	[app->soundBank load];
	
	// Marque les OI de la frame
	[app->OIList resetOICurrent];
	for (n = 0; n < LOList->nIndex; n++)
	{
		CLO* lo = LOList->list[n];
		if (lo->loType >= OBJ_SPR)
		{
			[app->OIList setOICurrent:lo->loOiHandle];
		}
	}
	
	return YES;
}	

-(void)loadLayers
{
	nLayers = [app->file readAInt];
	layers = (CLayer**)malloc(nLayers*sizeof(CLayer*));
	
	int n;
	for (n = 0; n < nLayers; n++)
	{
		layers[n] = [[CLayer alloc] initWithFrame:self];
		[layers[n] load:app->file];
	}
}

-(void)loadHeader
{
	leWidth = [app->file readAInt];
	leHeight = [app->file readAInt];
	leBackground = [app->file readAColor];
	leFlags = [app->file readAInt];
}


// Get obstacle mask bits
-(int)getMaskBits
{
	int flgs = 0;
	
	int n;
	for (n = 0; n < LOList->nIndex; n++)
	{
		CLO* lo = [LOList getLOFromIndex:(short)n];
		if (lo->loLayer > 0)
		{
			break;
		}
		
		COI* poi = [app->OIList getOIFromHandle:lo->loOiHandle];
		if (poi->oiType < OBJ_SPR)
		{
			COC* poc = poi->oiOC;
			switch (poc->ocObstacleType)
			{
				case 1:	    // COC.OBSTACLE_SOLID:
					flgs |= CM_OBSTACLE;
					break;
				case 2:	    // COC.OBSTACLE_PLATFORM:
					flgs |= CM_PLATFORM;
					break;
			}
		}
		else
		{
			CObjectCommon* pCommon = (CObjectCommon*) poi->oiOC;
			if ((pCommon->ocOEFlags & OEFLAG_BACKGROUND) != 0)
			{
				switch ((pCommon->ocFlags2 & OCFLAGS2_OBSTACLEMASK) >> OCFLAGS2_OBSTACLESHIFT)
				{
					case 1:	    // OBSTACLE_SOLID:
						flgs |= CM_OBSTACLE;
						break;
					case 2:	    // OBSTACLE_PLATFORM:
						flgs |= CM_PLATFORM;
						break;
				}
			}
		}
	}
	return flgs;
}

//////////////////////////////////////////////////////////////////////////////
//
// Background collision routines
//
-(BOOL)bkdLevObjCol_TestPoint:(int)x withY:(int)y andLayer:(int)nTestLayer andPlane:(int)nPlane
{
	int nLayer;
	int nFirstLayer;
	int nLastLayer;
	int v;
	int cm_box;
	CRect rc;
	CImage* image;
	CMask* pMask;
	
	if (nTestLayer == LAYER_ALL)
	{
		nFirstLayer = 1;				// Layer 0 already tested by caller
		nLastLayer = nLayers - 1;
	}
	else
	{
		if (nTestLayer >= nLayers)
		{
			return false;
		}
		nFirstLayer = nLastLayer = nTestLayer;
	}
	
	int nPlayfieldWidth = leWidth;
	int nPlayfieldHeight = leHeight;
	
	for (nLayer = nFirstLayer; nLayer <= nLastLayer; nLayer++)
	{
		CLayer* pLayer = layers[nLayer];
		
		BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
		BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
		BOOL bWrap = (bWrapHorz | bWrapVert);
		int i;
		
		int dwWrapFlags = 0;
		int nSprite = 0;
		int nLOs = pLayer->nBkdLOs;

		// Optimization (only if no wrap)
		int nxz, nyz, nz;
		CArrayList* pZones = nil;
		CArrayList* pZone = nil;
		nxz = nyz = nz = 0;
		if ( !bWrap )
		{
			// Get (or calculate) LO lists per zone (zone width = 512 x 512)
			pZones = [app->run getLayerZones:nLayer];
			
			// Get number of zones
			nxz = ((app->frame->leWidth + OBJZONE_WIDTH - 1)/ OBJZONE_WIDTH) + 2;
			nyz = ((app->frame->leHeight + OBJZONE_HEIGHT - 1)/ OBJZONE_HEIGHT) + 2;
			nz = nxz * nyz;
		}
		
		if ( pZones != NULL )
		{
			int zy = 0;
			if ( y >= 0 )
				zy = MIN(y / OBJZONE_HEIGHT + 1, nyz-1);
			int zx = 0;
			if ( x >= 0 )
				zx = MIN(x / OBJZONE_WIDTH + 1, nxz-1);
			int z = zy * nxz + zx;
			//ASSERT(z < nz);
			pZone = (CArrayList*)[pZones get:z];
			if ( pZone != nil )
				nLOs = [pZone size];
			else
				nLOs = 0;
		}
		
		for (i = 0; i < nLOs; i++)
		{
			CLO* plo = [LOList getLOFromIndex:(short)(pLayer->nFirstLOIndex+i)];
			CObject* hoPtr = nil;
			
			if (pZone != nil)
				plo = [app->frame->LOList getLOFromIndex:[pZone getInt:i]];
			
			COI* poi = [app->OIList getOIFromHandle:plo->loOiHandle];
			if (poi == nil || poi->oiOC == nil)
			{
				continue;
			}
			
			COC* poc = poi->oiOC;
			int typeObj = poi->oiType;
			
			// Get object position
			rc.left = plo->loX;
			rc.top = plo->loY;
			
			// Get object rectangle
			if (typeObj < OBJ_SPR)
			{
				v = poc->ocObstacleType;
				// Ladder or no obstacle? continue
				if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
				{
					continue;
				}
				cm_box = poc->ocColMode;
				rc.right = rc.left + poc->ocCx;
				rc.bottom = rc.top + poc->ocCy;
			}
			else
			{
				CObjectCommon* pCommon = (CObjectCommon*) poc;
				// Dynamic item => must be a background object
				if ((pCommon->ocOEFlags & OEFLAG_BACKGROUND) == 0 || (hoPtr = [app->run find_HeaderObject:plo->loHandle]) == nil)
				{
					continue;
				}
				v = ((pCommon->ocFlags2 & OCFLAGS2_OBSTACLEMASK) >> OCFLAGS2_OBSTACLESHIFT);
				// Ladder or no obstacle? continue
				if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
				{
					continue;
				}
				cm_box = ((pCommon->ocFlags2 & OCFLAGS2_COLBOX) != 0) ? 1 : 0;
				rc.left = hoPtr->hoX - leX - hoPtr->hoImgXSpot;
				rc.top = hoPtr->hoY - leY - hoPtr->hoImgYSpot;
				rc.right = rc.left + hoPtr->hoImgWidth;
				rc.bottom = rc.top + hoPtr->hoImgHeight;
			}
			
			// Wrap
			if (bWrap)
			{
				switch (nSprite)
				{
                        // Normal sprite: test if other sprites should be displayed
					case 0:
						// Wrap horizontally?
						if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
						{
							// Wrap horizontally and vertically?
							if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 3;
								dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
							}
							
							// Wrap horizontally only
							else
							{
								nSprite = 1;
								dwWrapFlags |= (WRAP_X);
							}
						}
						// Wrap vertically?
						else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
						{
							nSprite = 2;
							dwWrapFlags |= (WRAP_Y);
						}
						break;
						
                        // Other sprite instance: wrap horizontally
					case 1:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_X;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_Y) != 0)
						{
							nSprite = 2;
						}
						break;
						
                        // Other sprite instance: wrap vertically
					case 2:
						// Wrap
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_Y;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_X) != 0)
						{
							nSprite = 1;
						}
						break;
						
                        // Other sprite instance: wrap horizontally and vertically
					case 3:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_XY;
						
						// Calculate next sprite to display
						nSprite = 2;
						break;
				}
			}
			
			do
			{
				if (x < rc.left || y < rc.top)
				{
					break;
				}
				
				// Point in rectangle?
				if (x >= rc.right || y >= rc.bottom)
				{
					break;
				}
				
				// Obstacle and ask for platform or reciprocally? continue
				if ( /* (v == OBSTACLE_SOLID && nPlane == CM_TEST_PLATFORM) || */ // Non car un obstacle solide est �crit dans les 2 masques...
					(v == OBSTACLE_PLATFORM && nPlane == CM_TEST_OBSTACLE))
				{
					break;
				}
				
				// Collision with box
				if (cm_box != 0)
				{
					return YES;		// collides
				}
				// Load image if not yet loaded
				//FRANCOIS:	    if ( (poi.oiLoadFlags & OILF_ELTLOADED) == 0 )
				//			    LoadOnCall(poi);
				
				int nGetColMaskFlag = GCMF_OBSTACLE;
				if (v == OBSTACLE_PLATFORM)
				{
					nGetColMaskFlag = GCMF_PLATFORM;
				}
				
				// Test if point into image mask
				pMask = nil;
				if (typeObj < OBJ_SPR)
				{
					image = [app->imageBank getImageFromHandle:((COCBackground*)poc)->ocImage];
					pMask = [image getMask:nGetColMaskFlag withAngle:0 andScaleX:1.0 andScaleY:1.0];
				}
				else
				{
					pMask = [hoPtr getCollisionMask:nGetColMaskFlag];
				}
				if (pMask == nil)		// No mask? collision
				{
					return YES;
				}
				
				if ([pMask testPoint:(int)(x - rc.left) withY:(int)(y - rc.top)])
				{
					return YES;
				}
			} while (NO);
			
			// Wrapped?
			if (dwWrapFlags != 0)
			{
				i--;
			}
		}
		
		// Scan Bkd2s
		if (pLayer->pBkd2 != nil)
		{
			CBkd2* pbkd;
			
			dwWrapFlags = 0;
			nSprite = 0;

			int size = [pLayer->pBkd2 size];
			for (i = 0; i < size; i++)
			{
				pbkd = (CBkd2*)[pLayer->pBkd2 get:i];
				
				// Get object position
				rc.left = pbkd->x;
				rc.top = pbkd->y;
				
				v = pbkd->obstacleType;
				if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
				{
					continue;
				}
				cm_box = (pbkd->colMode == CM_BOX) ? 1 : 0;
				
				// Get object rectangle
				image = [app->imageBank getImageFromHandle:pbkd->img];
				if (image != nil)
				{
					if((pbkd->spriteFlag & SF_NOHOTSPOT) == 0)
					{
						//Adjust bounding rectangle for hotspot
						rc.left -= image->xSpot;
						rc.top -= image->ySpot;
					}
					rc.right = rc.left + image->width;
					rc.bottom = rc.top + image->height;
				}
				else
				{
					rc.right = rc.left + 1;
					rc.bottom = rc.top + 1;
				}
				
				// Wrap
				if (bWrap)
				{
					switch (nSprite)
					{
                            // Normal sprite: test if other sprites should be displayed
						case 0:
							// Wrap horizontally?
							if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
							{
								// Wrap horizontally and vertically?
								if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
								{
									nSprite = 3;
									dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
								}
								
								// Wrap horizontally only
								else
								{
									nSprite = 1;
									dwWrapFlags |= (WRAP_X);
								}
							}
							// Wrap vertically?
							else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 2;
								dwWrapFlags |= (WRAP_Y);
							}
							break;
							
                            // Other sprite instance: wrap horizontally
						case 1:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_X;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_Y) != 0)
							{
								nSprite = 2;
							}
							break;
							
                            // Other sprite instance: wrap vertically
						case 2:
							// Wrap
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_Y;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_X) != 0)
							{
								nSprite = 1;
							}
							break;
							
                            // Other sprite instance: wrap horizontally and vertically
						case 3:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_XY;
							
							// Calculate next sprite to display
							nSprite = 2;
							break;
					}
				}
				
				do
				{
					// Point in rectangle?
					if (x < rc.left || y < rc.top)
					{
						break;
					}
					
					if (x >= rc.right || y >= rc.bottom)
					{
						break;
					}
					
					// Obstacle and ask for platform or reciprocally? continue
					if ( /* (v == OBSTACLE_SOLID && nPlane == CM_TEST_PLATFORM) || */ // Non car un obstacle solide est �crit dans les 2 masques...
						(v == OBSTACLE_PLATFORM && nPlane == CM_TEST_OBSTACLE))
					{
						break;
					}
					
					// Collision with box
					if (cm_box != 0)
					{
						return YES;		// collides
					}
					int nGetColMaskFlag = GCMF_OBSTACLE;
					if (v == OBSTACLE_PLATFORM)
					{
						nGetColMaskFlag = GCMF_PLATFORM;
					}
					
					// Test if point into image mask
					image = [app->imageBank getImageFromHandle:pbkd->img];
					pMask = [image getMask:nGetColMaskFlag withAngle:0 andScaleX:1.0 andScaleY:1.0];
					if (pMask != nil)
					{
						if ([pMask testPoint:(int)(x - rc.left) withY:(int)(y - rc.top)])
						{
							return YES;
						}
					}
				} while (NO);
				
				// Wrapped?
				if (dwWrapFlags != 0)
				{
					i--;
				}
			}
		}
	}
	return false;
}

-(BOOL)bkdLevObjCol_TestRect:(int)x withY:(int)y andWidth:(int)nWidth andHeight:(int)nHeight andLayer:(int)nTestLayer andPlane:(int)nPlane
{
	int nLayer;
	int nFirstLayer;
	int nLastLayer;
	int v;
	int cm_box;
	CRect rc;
	CImage* image;
	CMask* pMask = nil;
	
	if (nTestLayer == LAYER_ALL)
	{
		nFirstLayer = 1;				// Layer 0 already tested by caller
		nLastLayer = nLayers - 1;
	}
	else
	{
		if (nTestLayer >= nLayers)
		{
			return false;
		}
		nFirstLayer = nLastLayer = nTestLayer;
	}
	
	int nPlayfieldWidth = leWidth;
	int nPlayfieldHeight = leHeight;
	
	for (nLayer = nFirstLayer; nLayer <= nLastLayer; nLayer++)
	{
		CLayer* pLayer = layers[nLayer];
		
		BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
		BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
		BOOL bWrap = (bWrapHorz | bWrapVert);
		int i;

		int dwWrapFlags = 0;
		int nSprite = 0;
		int nLOs = pLayer->nBkdLOs;
		
		// Optimization (only if no wrap)
		int nxz, nyz, nz;
		CArrayList* pZones = nil;
		CArrayList* pZone = nil;
		nxz = nyz = nz = 0;
		if ( !bWrap )
		{
			// Get (or calculate) LO lists per zone (zone width = 512 x 512)
			pZones = [app->run getLayerZones:nLayer];
			
			// Get number of zones
			nxz = ((app->frame->leWidth + OBJZONE_WIDTH - 1)/ OBJZONE_WIDTH) + 2;
			nyz = ((app->frame->leHeight + OBJZONE_HEIGHT - 1)/ OBJZONE_HEIGHT) + 2;
			nz = nxz * nyz;
		}
		
		int minzy, maxzy;
		minzy = maxzy = 0;
		if ( pZones != nil )
		{
			if ( y >= 0 )
				minzy = MIN(y / OBJZONE_HEIGHT + 1, nyz-1);
			if ( (y+nHeight-1) >= 0 )
				maxzy = MIN((y+nHeight-1) / OBJZONE_HEIGHT + 1, nyz-1);
		}
		for (int zy=minzy; zy<=maxzy; zy++)
		{
			int minzx, maxzx;
			minzx = maxzx = 0;
			if ( pZones != NULL )
			{
				if ( x >= 0 )
					minzx = MIN(x / OBJZONE_WIDTH + 1, nxz-1);
				if ( (x+nWidth-1) >= 0 )
					maxzx = MIN((x+nWidth-1) / OBJZONE_WIDTH + 1, nxz-1);
			}
			for (int zx=minzx; zx<=maxzx; zx++)
			{
				if ( pZones != NULL )
				{
					int z = zy * nxz + zx;
					//ASSERT(z < nz);
					pZone = (CArrayList*)[pZones get:z];
					if ( pZone == nil )
						continue;
					nLOs = [pZone size];
				}
		
				for (i = 0; i < nLOs; i++)
				{
					CLO* plo = [LOList getLOFromIndex:(short) (pLayer->nFirstLOIndex + i)];
					CObject* hoPtr = nil;
					
					if (pZone != nil)
						plo = [app->frame->LOList getLOFromIndex:[pZone getInt:i]];
					
					COI* poi = [app->OIList getOIFromHandle:plo->loOiHandle];
					if (poi == nil || poi->oiOC == nil)
					{
						continue;
					}
					
					COC* poc = poi->oiOC;
					int typeObj = poi->oiType;
					
					// Get object position
					rc.left = plo->loX;
					rc.top = plo->loY;
					
					// Get object rectangle
					if (typeObj < OBJ_SPR)
					{
						v = poc->ocObstacleType;
						// Ladder or no obstacle? continue
						if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
						{
							continue;
						}
						cm_box = poc->ocColMode;
						rc.right = rc.left + poc->ocCx;
						rc.bottom = rc.top + poc->ocCy;
					}
					else
					{
						CObjectCommon* pCommon = (CObjectCommon*) poc;
						// Dynamic item => must be a background object
						if ((pCommon->ocOEFlags & OEFLAG_BACKGROUND) == 0 || (hoPtr = [app->run find_HeaderObject:plo->loHandle]) == nil)
						{
							continue;
						}
						v = ((pCommon->ocFlags2 & OCFLAGS2_OBSTACLEMASK) >> OCFLAGS2_OBSTACLESHIFT);
						// Ladder or no obstacle? continue
						if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
						{
							continue;
						}
						cm_box = ((pCommon->ocFlags2 & OCFLAGS2_COLBOX) != 0) ? 1 : 0;
						rc.left = hoPtr->hoX - leX - hoPtr->hoImgXSpot;
						rc.top = hoPtr->hoY - leY - hoPtr->hoImgYSpot;
						rc.right = rc.left + hoPtr->hoImgWidth;
						rc.bottom = rc.top + hoPtr->hoImgHeight;
					}
					
					// Wrap
					if (bWrap)
					{
						switch (nSprite)
						{
								// Normal sprite: test if other sprites should be displayed
							case 0:
								// Wrap horizontally?
								if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
								{
									// Wrap horizontally and vertically?
									if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
									{
										nSprite = 3;
										dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
									}
									
									// Wrap horizontally only
									else
									{
										nSprite = 1;
										dwWrapFlags |= (WRAP_X);
									}
								}
								// Wrap vertically?
								else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
								{
									nSprite = 2;
									dwWrapFlags |= (WRAP_Y);
								}
								break;
								
								// Other sprite instance: wrap horizontally
							case 1:
								// Wrap
								if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
								{
									int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
									rc.left += dx;
									rc.right += dx;
								}
								else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
								{
									int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
									rc.left -= dx;
									rc.right -= dx;
								}
								
								// Remove flag
								dwWrapFlags &= ~WRAP_X;
								
								// Calculate next sprite to display
								nSprite = 0;
								if ((dwWrapFlags & WRAP_Y) != 0)
								{
									nSprite = 2;
								}
								break;
								
								// Other sprite instance: wrap vertically
							case 2:
								// Wrap
								if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
								{
									int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
									rc.top += dy;
									rc.bottom += dy;
								}
								else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
								{
									int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
									rc.top -= dy;
									rc.bottom -= dy;
								}
								
								// Remove flag
								dwWrapFlags &= ~WRAP_Y;
								
								// Calculate next sprite to display
								nSprite = 0;
								if ((dwWrapFlags & WRAP_X) != 0)
								{
									nSprite = 1;
								}
								break;
								
								// Other sprite instance: wrap horizontally and vertically
							case 3:
								// Wrap
								if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
								{
									int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
									rc.left += dx;
									rc.right += dx;
								}
								else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
								{
									int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
									rc.left -= dx;
									rc.right -= dx;
								}
								if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
								{
									int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
									rc.top += dy;
									rc.bottom += dy;
								}
								else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
								{
									int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
									rc.top -= dy;
									rc.bottom -= dy;
								}
								
								// Remove flag
								dwWrapFlags &= ~WRAP_XY;
								
								// Calculate next sprite to display
								nSprite = 2;
								break;
						}
					}
					do
					{
						if (x + nWidth <= rc.left || y + nHeight <= rc.top)
						{
							break;
						}
						
						// Point in rectangle?
						if (x >= rc.right || y >= rc.bottom)
						{
							break;
						}
						
						// Obstacle and ask for platform or reciprocally? continue
						if ( /* (v == OBSTACLE_SOLID && nPlane == CM_TEST_PLATFORM) || */ // Non car un obstacle solide est �crit dans les 2 masques...
							(v == OBSTACLE_PLATFORM && nPlane == CM_TEST_OBSTACLE))
						{
							break;
						}
						
						// Collision with box
						if (cm_box != 0)
						{
							return YES;		// collides
						}
						// Load image if not yet loaded
						//FRANCOIS:	    if ( (poi->oiLoadFlags & OILF_ELTLOADED) == 0 )
						//			LoadOnCall(poi);
						
						// Get background mask
						int nGetColMaskFlag = GCMF_OBSTACLE;
						if (v == OBSTACLE_PLATFORM)
						{
							nGetColMaskFlag = GCMF_PLATFORM;
						}
						
						if (typeObj < OBJ_SPR)
						{
							image = [app->imageBank getImageFromHandle:((COCBackground*)poc)->ocImage];
							pMask = [image getMask:nGetColMaskFlag withAngle:0 andScaleX:1.0 andScaleY:1.0];
						}
						else
						{
							pMask = [hoPtr getCollisionMask:nGetColMaskFlag];
						}
						if (pMask == nil)		// No mask? collision
						{
							return YES;
						}
						
						// Test if rectangle intersects with background mask
						if ([pMask testRect:0 withX:(int)(x - rc.left) andY:(int)(y - rc.top) andWidth:nWidth andHeight:nHeight])
						{
							return YES;
						}
						
					} while (false);
					
					// Wrapped?
					if (dwWrapFlags != 0)
					{
						i--;
					}
				}
			}
		}
		
		// Scan Bkd2s
		if (pLayer->pBkd2 != nil)
		{
			CBkd2* pbkd;
			
			dwWrapFlags = 0;
			nSprite = 0;

			int size = [pLayer->pBkd2 size];
			for (i = 0; i < size; i++)
			{
				pbkd = (CBkd2*) [pLayer->pBkd2 get:i];
				
				rc.left = pbkd->x;
				rc.top = pbkd->y;
				
				v = pbkd->obstacleType;
				if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
				{
					continue;
				}
				cm_box = (pbkd->colMode == CM_BOX) ? 1 : 0;
				
				// Get object rectangle
				image = [app->imageBank getImageFromHandle:pbkd->img];
				if (image != nil)
				{
					if((pbkd->spriteFlag & SF_NOHOTSPOT) == 0)
					{
						//Adjust bounding rectangle for hotspot
						rc.left -= image->xSpot;
						rc.top -= image->ySpot;
					}
					rc.right = rc.left + image->width;
					rc.bottom = rc.top + image->height;
				}
				else
				{
					rc.right = rc.left + 1;
					rc.bottom = rc.top + 1;
				}
				
				// Wrap
				if (bWrap)
				{
					switch (nSprite)
					{
							// Normal sprite: test if other sprites should be displayed
						case 0:
							// Wrap horizontally?
							if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
							{
								// Wrap horizontally and vertically?
								if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
								{
									nSprite = 3;
									dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
								}
								
								// Wrap horizontally only
								else
								{
									nSprite = 1;
									dwWrapFlags |= (WRAP_X);
								}
							}
							
							// Wrap vertically?
							else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 2;
								dwWrapFlags |= (WRAP_Y);
							}
							break;
							
							// Other sprite instance: wrap horizontally
						case 1:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_X;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_Y) != 0)
							{
								nSprite = 2;
							}
							break;
							
							// Other sprite instance: wrap vertically
						case 2:
							// Wrap
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_Y;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_X) != 0)
							{
								nSprite = 1;
							}
							break;
							
							// Other sprite instance: wrap horizontally and vertically
						case 3:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_XY;
							
							// Calculate next sprite to display
							nSprite = 2;
							break;
					}
				}
				
				do
				{
					// Intersection?
					if (x + nWidth <= rc.left || y + nHeight <= rc.top)
					{
						break;
					}
					
					if (x >= rc.right || y >= rc.bottom)
					{
						break;
					}
					
					// Obstacle and ask for platform or reciprocally? continue
					if ( /* (v == OBSTACLE_SOLID && nPlane == CM_TEST_PLATFORM) || */ // Non car un obstacle solide est �crit dans les 2 masques...
						(v == OBSTACLE_PLATFORM && nPlane == CM_TEST_OBSTACLE))
					{
						break;
					}
					
					// Collision with box
					if (cm_box != 0)
					{
						return YES;		// collides
					}
					int nGetColMaskFlag = GCMF_OBSTACLE;
					if (v == OBSTACLE_PLATFORM)
					{
						nGetColMaskFlag = GCMF_PLATFORM;
					}
					
					// Test if point into image mask
					image = [app->imageBank getImageFromHandle:pbkd->img];
					pMask = [image getMask:nGetColMaskFlag withAngle:0 andScaleX:1.0 andScaleY:1.0];
					if (pMask != nil)
					{
						if ([pMask testRect:0 withX:(int)(x - rc.left) andY:(int)(y - rc.top) andWidth:nWidth andHeight:nHeight])
						{
							return YES;
						}
					}
				} while (NO);
				
				// Wrapped?
				if (dwWrapFlags != 0)
				{
					i--;
				}
			}
		}
	}
	return NO;
}

-(BOOL)bkdLevObjCol_TestSprite:(CSprite*)pSpr withImage:(short)newImg andX:(int)newX andY:(int)newY andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andFoot:(int)subHt andPlane:(int)nPlane
{
	CObject* hoPtr;
	int v;
	int cm_box;
	CRect rc;
	
	// Get sprite layer
	int nLayer = pSpr->sprLayer / 2;	    // GetSpriteLayer
	
	CLayer* pLayer = layers[nLayer];
	
	BOOL bWrapHorz = ((pLayer->dwOptions & FLOPT_WRAP_HORZ) != 0);
	BOOL bWrapVert = ((pLayer->dwOptions & FLOPT_WRAP_VERT) != 0);
	BOOL bWrap = (bWrapHorz | bWrapVert);
	int i;
	
	int nPlayfieldWidth = leWidth;
	int nPlayfieldHeight = leHeight;
	CImage* image;
	
	// Sprite collision mode
	int dwSprFlags = pSpr->sprFlags;
	BOOL bSprColBox = ((dwSprFlags & SF_COLBOX) != 0);
	
	// Sprite rectangle
	CRect sprRc;
	int nWidth, nHeight;
	int nImg = newImg;
	
	sprRc.left = newX;
	sprRc.top = newY;
	if (newImg == 0)
	{
		nImg = pSpr->sprImg;
	}
	
	CMask* pSprMask = nil;
	CMask* pBkdMask = nil;
//	int dwPSCFlags = 0;
	int yMaskBits = 0;
	
	// Bitmap collision?
	if (!bSprColBox)
	{
		// Image sprite not stretched and not rotated, or owner draw sprite?
		pSprMask = [app->run->spriteGen getSpriteMask:pSpr withImage:(short)nImg andFlags:GCMF_OBSTACLE andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
		if (pSprMask == nil)
		{
			sprRc.left = pSpr->sprX1new;		// GetSpriteRect
			sprRc.right = pSpr->sprX2new;
			sprRc.top = pSpr->sprY1new;
			sprRc.bottom = pSpr->sprY2new;
			nWidth = (int)sprRc.width();
			nHeight = (int)sprRc.height();
			bSprColBox = YES;			// no mask ? box collision
		}
		else
		{
			// Get sprite box
			if ((pSpr->sprFlags & SF_NOHOTSPOT) == 0)
			{
				sprRc.left -= pSprMask->xSpot;
				sprRc.top -= pSprMask->ySpot;
			}
			nWidth = pSprMask->width;
			nHeight = pSprMask->height;
			sprRc.right = sprRc.left + nWidth;
			sprRc.bottom = sprRc.top + nHeight;
		}
	}
	else
	{
		// Box collision: no need to calculate the mask
		if (nImg<0 || nImg == pSpr->sprImg || (dwSprFlags & SF_OWNERDRAW) != 0)
		{
			sprRc.left = pSpr->sprX1new;		// GetSpriteRect
			sprRc.right = pSpr->sprX2new;
			sprRc.top = pSpr->sprY1new;
			sprRc.bottom = pSpr->sprY2new;
			nWidth = (int)sprRc.width();
			nHeight = (int)sprRc.height();
		}
		else
		{
			image = [app->imageBank getImageFromHandle:(short)nImg];
			if (image != nil)
			{
				sprRc.left -= image->xSpot;
				sprRc.top -= image->ySpot;
				nWidth = image->width;
				nHeight = image->height;
				sprRc.right = sprRc.left + nWidth;
				sprRc.bottom = sprRc.top + nHeight;
			}
			else
			{
				sprRc.left = pSpr->sprX1new;		// GetSpriteRect
				sprRc.right = pSpr->sprX2new;
				sprRc.top = pSpr->sprY1new;
				sprRc.bottom = pSpr->sprY2new;
				nWidth = (int)sprRc.width();
				nHeight = (int)sprRc.height();
			}
		}
	}
	
	// Take subHt into account
	if (subHt != 0)
	{
		if (subHt > nHeight)
		{
			subHt = nHeight;
		}
		sprRc.top += nHeight - subHt;
		if (pSprMask != nil)
		{
			yMaskBits = nHeight - subHt;
		}
		nHeight = subHt;
	}
	
	// Scan LOs
	int dwWrapFlags = 0;
	int nSprite = 0;
	
	int nLOs = pLayer->nBkdLOs;
	
	
	// Optimization (only if no wrap)
	int nxz, nyz, nz;
	CArrayList* pZones = nil;
	CArrayList* pZone = nil;
	nxz = nyz = nz = 0;
	if ( !bWrap )
	{
		// Get (or calculate) LO lists per zone (zone width = 512 x 512)
		pZones = [app->run getLayerZones:nLayer];
		
		// Get number of zones
		nxz = ((app->frame->leWidth + OBJZONE_WIDTH - 1)/ OBJZONE_WIDTH) + 2;
		nyz = ((app->frame->leHeight + OBJZONE_HEIGHT - 1)/ OBJZONE_HEIGHT) + 2;
		nz = nxz * nyz;
	}
	
	int minzy, maxzy;
	minzy = maxzy = 0;
	if ( pZones != nil )
	{
		if (sprRc.top >= 0 )
			minzy = (int)MIN(sprRc.top / OBJZONE_HEIGHT + 1, nyz-1);
		if ( sprRc.bottom >= 0 )
			maxzy = (int)MIN( sprRc.bottom / OBJZONE_HEIGHT + 1, nyz-1);
	}
	for (int zy=minzy; zy<=maxzy; zy++)
	{
		int minzx, maxzx;
		minzx = maxzx = 0;
		if ( pZones != nil )
		{
			if ( sprRc.left >= 0 )
				minzx = (int)MIN(sprRc.left / OBJZONE_WIDTH + 1, nxz-1);
			if ( sprRc.right >= 0 )
				maxzx = (int)MIN(sprRc.right / OBJZONE_WIDTH + 1, nxz-1);
		}
		for (int zx=minzx; zx<=maxzx; zx++)
		{
			if ( pZones != nil )
			{
				int z = zy * nxz + zx;
				//ASSERT(z < nz);
				pZone = (CArrayList*)[pZones get:z];
				if ( pZone == nil )
				{
					//NSLog(@"No zone: %i", z);
					continue;
				}
				nLOs = [pZone size];
			}
	
			for (i = 0; i < nLOs; i++)
			{
				CLO* plo = [LOList getLOFromIndex:(short)(pLayer->nFirstLOIndex + i)];
				
				if (pZone != nil)
					plo = [app->frame->LOList getLOFromIndex:[pZone getInt:i]];
				
				COI* poi = [app->OIList getOIFromHandle:plo->loOiHandle];
				if (poi == nil || poi->oiOC == nil)
				{
					continue;
				}
				
				COC* poc = poi->oiOC;
				int typeObj = poi->oiType;
				
				// Get object position
				rc.left = plo->loX;
				rc.top = plo->loY;
				
				// Get object rectangle
				hoPtr = nil;
				if (typeObj < OBJ_SPR)
				{
					// Ladder or no obstacle? continue
					v = poc->ocObstacleType;
					if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
					{
						continue;
					}
					cm_box = poc->ocColMode;
					rc.right = rc.left + poc->ocCx;
					rc.bottom = rc.top + poc->ocCy;
				}
				else
				{
					// Dynamic item => must be a background object
					CObjectCommon* pCommon = (CObjectCommon*) poc;
					if ((pCommon->ocOEFlags & OEFLAG_BACKGROUND) == 0 || (hoPtr = [app->run find_HeaderObject:plo->loHandle]) == nil)
					{
						continue;
					}
					v = ((pCommon->ocFlags2 & OCFLAGS2_OBSTACLEMASK) >> OCFLAGS2_OBSTACLESHIFT);
					// Ladder or no obstacle? continue
					if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
					{
						continue;
					}
					cm_box = (pCommon->ocFlags2 & OCFLAGS2_COLBOX) != 0 ? 1 : 0;
					rc.left = hoPtr->hoX - leX - hoPtr->hoImgXSpot;
					rc.top = hoPtr->hoY - leY - hoPtr->hoImgYSpot;
					rc.right = rc.left + hoPtr->hoImgWidth;
					rc.bottom = rc.top + hoPtr->hoImgHeight;
				}
				
				// Wrap
				if (bWrap)
				{
					switch (nSprite)
					{
							// Normal sprite: test if other sprites should be displayed
						case 0:
							// Wrap horizontally?
							if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
							{
								// Wrap horizontally and vertically?
								if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
								{
									nSprite = 3;
									dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
								}
								
								// Wrap horizontally only
								else
								{
									nSprite = 1;
									dwWrapFlags |= (WRAP_X);
								}
							}
							// Wrap vertically?
							else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 2;
								dwWrapFlags |= (WRAP_Y);
							}
							break;
							
							// Other sprite instance: wrap horizontally
						case 1:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_X;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_Y) != 0)
							{
								nSprite = 2;
							}
							break;
							
							// Other sprite instance: wrap vertically
						case 2:
							// Wrap
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_Y;
							
							// Calculate next sprite to display
							nSprite = 0;
							if ((dwWrapFlags & WRAP_X) != 0)
							{
								nSprite = 1;
							}
							break;
							
							// Other sprite instance: wrap horizontally and vertically
						case 3:
							// Wrap
							if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left += dx;
								rc.right += dx;
							}
							else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
							{
								int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
								rc.left -= dx;
								rc.right -= dx;
							}
							if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top += dy;
								rc.bottom += dy;
							}
							else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
							{
								int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
								rc.top -= dy;
								rc.bottom -= dy;
							}
							
							// Remove flag
							dwWrapFlags &= ~WRAP_XY;
							
							// Calculate next sprite to display
							nSprite = 2;
							break;
					}
				}
				
				do
				{
					if (sprRc.right <= rc.left || sprRc.bottom <= rc.top)
					{
						break;
					}
					
					// No Intersection?
					if (sprRc.left >= rc.right || sprRc.top >= rc.bottom)
					{
						break;
					}
					
					// Obstacle and ask for platform or reciprocally? continue
					if ( /* (v == OBSTACLE_SOLID && nPlane == CM_TEST_PLATFORM) || */ // Non car un obstacle solide est �crit dans les 2 masques...
						(v == OBSTACLE_PLATFORM && nPlane == CM_TEST_OBSTACLE))
					{
						break;
					}
					
					// Background sprite = Box?
					if (cm_box != 0)
					{
						// Collision between 2 boxes? OK
						if (bSprColBox)
						{
							return YES;
						}
						
						// Active sprite = bitmap
						// => test collision between background rectangle and sprite's mask
						if (pSprMask == nil)
						{
							// FRA: pSprMask = [rhPtr->spriteGen completeSpriteColMask:pSpr withFlags:dwPSCFlags andWidth:nWidth andHeight:nHeight];
							if (pSprMask == nil)
							{
								return YES;		// Can't calculate mask => box collision
							}
							yMaskBits = 0;
							if (subHt != 0)
							{
								if (subHt > nHeight)
								{
									subHt = nHeight;
								}
								yMaskBits = nHeight - subHt;
							}
						}
						
						if ([pSprMask testRect:yMaskBits withX:(int)(rc.left - sprRc.left) andY:(int)(rc.top - sprRc.top) andWidth:(int)rc.width() andHeight:(int)rc.height()])
						{
							return YES;
						}
					}
					// Background sprite = bitmap
					else
					{
						// Load image if not yet loaded
						//FRANCOIS:	    if ( (poi->oiLoadFlags & OILF_ELTLOADED) == 0 )
						//			LoadOnCall(poi);
						
						int nGetColMaskFlag = GCMF_OBSTACLE;
						if (v == OBSTACLE_PLATFORM)
						{
							nGetColMaskFlag = GCMF_PLATFORM;
						}
						
						// Get background mask
						pBkdMask = nil;
						if (typeObj < OBJ_SPR)
						{
							image = [app->imageBank getImageFromHandle:((COCBackground*)poc)->ocImage];
							pBkdMask = [image getMask:nGetColMaskFlag withAngle:0 andScaleX:1.0 andScaleY:1.0];
						}
						else
						{
							pBkdMask = [hoPtr getCollisionMask:nGetColMaskFlag];
						}
						
						// Active sprite = box ?
						if (bSprColBox)
						{
							if (pBkdMask == nil)		// No background mask? collision
							{
								return YES;
							}
							
							// Test collision between background mask and sprite rectangle
							if ([pBkdMask testRect:0 withX:(int)(sprRc.left - rc.left) andY:(int)(sprRc.top - rc.top) andWidth:(int)nWidth andHeight:(int)nHeight])
							{
								return YES;
							}
						}
						// Active sprite = bitmap
						else
						{
							// Get sprite mask
							yMaskBits = 0;
							if (subHt != 0)
							{
								if (subHt > nHeight)
								{
									subHt = nHeight;
								}
								yMaskBits = nHeight - subHt;
							}
							// No background mask
							if (pBkdMask == nil)
							{
								// Test collision between sprite mask and background rectangle
								if ([pSprMask testRect:yMaskBits withX:(int)(rc.left - sprRc.left) andY:(int)(rc.top - sprRc.top) andWidth:(int)rc.width() andHeight:(int)rc.height()])
								{
									return YES;
								}
							}
							// Background mask
							else
							{
								if (pSprMask == nil)
								{
									// Test collision between background mask and sprite rectangle
									if ([pBkdMask testRect:0 withX:(int)(sprRc.left - rc.left) andY:(int)(sprRc.top - rc.top) andWidth:nWidth andHeight:nHeight])
									{
										return YES;
									}
								}
								else
								{
									// Test collision between background and sprite masks
									if ([pBkdMask testMask:0 withX1:(int)rc.left andY1:(int)rc.top andMask:pSprMask andYBase:yMaskBits andX2:(int)sprRc.left andY2:(int)sprRc.top])
									{
										return YES;
									}
								}
							}
						}
					}
				} while (NO);
				
				// Wrapped?
				if (dwWrapFlags != 0)
				{
					i--;
				}
			}
	
		}
	}

	// Scan Bkd2s
	if (pLayer->pBkd2 != nil)
	{
		CBkd2* pbkd;
		
		dwWrapFlags = 0;
		nSprite = 0;
		
		for (i = 0; i < [pLayer->pBkd2 size]; i++)
		{
			pbkd = (CBkd2*) [pLayer->pBkd2 get:i];
			
			// Get object position
			rc.left = pbkd->x;
			rc.top = pbkd->y;
			
			v = pbkd->obstacleType;
			if (v == 0 || v == OBSTACLE_LADDER || v == OBSTACLE_TRANSPARENT)
			{
				continue;
			}
			cm_box = (pbkd->colMode == CM_BOX) ? 1 : 0;
			
			// Get object rectangle
			image = [app->imageBank getImageFromHandle:pbkd->img];
			if (image != nil)
			{
				if((pbkd->spriteFlag & SF_NOHOTSPOT) == 0)
				{
					//Adjust bounding rectangle for hotspot
					rc.left -= image->xSpot;
					rc.top -= image->ySpot;
				}
				rc.right = rc.left + image->width;
				rc.bottom = rc.top + image->height;
			}
			else
			{
				rc.right = rc.left + 1;
				rc.bottom = rc.top + 1;
			}
			
			// Wrap
			if (bWrap)
			{
				switch (nSprite)
				{
                        // Normal sprite: test if other sprites should be displayed
					case 0:
						// Wrap horizontally?
						if (bWrapHorz && (rc.left < 0 || rc.right > nPlayfieldWidth))
						{
							// Wrap horizontally and vertically?
							if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
							{
								nSprite = 3;
								dwWrapFlags |= (WRAP_X | WRAP_Y | WRAP_XY);
							}
							
							// Wrap horizontally only
							else
							{
								nSprite = 1;
								dwWrapFlags |= (WRAP_X);
							}
						}
						
						// Wrap vertically?
						else if (bWrapVert && (rc.top < 0 || rc.bottom > nPlayfieldHeight))
						{
							nSprite = 2;
							dwWrapFlags |= (WRAP_Y);
						}
						break;
						
                        // Other sprite instance: wrap horizontally
					case 1:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_X;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_Y) != 0)
						{
							nSprite = 2;
						}
						break;
						
                        // Other sprite instance: wrap vertically
					case 2:
						// Wrap
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_Y;
						
						// Calculate next sprite to display
						nSprite = 0;
						if ((dwWrapFlags & WRAP_X) != 0)
						{
							nSprite = 1;
						}
						break;
						
                        // Other sprite instance: wrap horizontally and vertically
					case 3:
						// Wrap
						if (rc.left < 0)				// (rc.right + curFrame.m_leX) <= 0
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left += dx;
							rc.right += dx;
						}
						else if (rc.right > nPlayfieldWidth)	// (rc.left + curFrame.m_leX) >= nPlayfieldWidth
						{
							int dx = nPlayfieldWidth;	// + (rc.right - rc.left)
							rc.left -= dx;
							rc.right -= dx;
						}
						if (rc.top < 0)				// (rc.bottom + curFrame.m_leY) <= 0
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top += dy;
							rc.bottom += dy;
						}
						else if (rc.bottom > nPlayfieldHeight)		// (rc.top + curFrame.m_leY) >= nPlayfieldHeight
						{
							int dy = nPlayfieldHeight;	// + (rc.bottom - rc.top)
							rc.top -= dy;
							rc.bottom -= dy;
						}
						
						// Remove flag
						dwWrapFlags &= ~WRAP_XY;
						
						// Calculate next sprite to display
						nSprite = 2;
						break;
				}
			}
			
			do
			{
				// No Intersection?
				if (sprRc.right <= rc.left || sprRc.bottom <= rc.top)
				{
					break;
				}
				
				if (sprRc.left >= rc.right || sprRc.top >= rc.bottom)
				{
					break;
				}
				
				// Obstacle and ask for platform or reciprocally? continue
				if ( /* (v == OBSTACLE_SOLID && nPlane == CM_TEST_PLATFORM) || */ // Non car un obstacle solide est �crit dans les 2 masques...
					(v == OBSTACLE_PLATFORM && nPlane == CM_TEST_OBSTACLE))
				{
					break;
				}
				
				// Background sprite = Box?
				if (cm_box != 0)
				{
					// Collision between 2 boxes? OK
					if (bSprColBox)
					{
						return YES;
					}
					
					// Active sprite = bitmap
					// => test collision between background rectangle and sprite's mask
					if (pSprMask == nil)
					{
						return YES;		// Can't calculate mask => box collision
					}
					yMaskBits = 0;
					if (subHt != 0)
					{
						if (subHt > nHeight)
						{
							subHt = nHeight;
						}
						yMaskBits = nHeight - subHt;
					}
					
					if ([pSprMask testRect:yMaskBits withX:(int)(rc.left - sprRc.left) andY:(int)(rc.top - sprRc.top) andWidth:(int)rc.width() andHeight:(int)rc.height()])
					{
						return YES;
					}
				}
				// Background sprite = bitmap
				else
				{
					int nGetColMaskFlag = GCMF_OBSTACLE;
					if (v == OBSTACLE_PLATFORM)
					{
						nGetColMaskFlag = GCMF_PLATFORM;
					}
					
					// Get background mask
					image = [app->imageBank getImageFromHandle:pbkd->img];
					pBkdMask = [image getMask:nGetColMaskFlag withAngle:0 andScaleX:1.0 andScaleY:1.0];
					if (pBkdMask == nil)
					{
						continue;
					}
					
					// Active sprite = box ?
					if (bSprColBox)
					{
						// Test collision between background mask and sprite rectangle
						if ([pBkdMask testRect:0 withX:(int)(sprRc.left - rc.left) andY:(int)(sprRc.top - rc.top) andWidth:(int)nWidth andHeight:(int)nHeight])
						{
							return YES;
						}
					}
					// Active sprite = bitmap
					else
					{
						if (pSprMask == nil)
						{
// FRA:							pSprMask = [rhPtr->spriteGen completeSpriteColMask:pSpr withFlags:dwPSCFlags andWidth:nWidth andHeight:nHeight];
							if (pSprMask == nil)
							{
								return YES;		// Can't calculate mask => box collision
							}
							yMaskBits = 0;
							if (subHt != 0)
							{
								if (subHt > nHeight)
								{
									subHt = nHeight;
								}
								yMaskBits = nHeight - subHt;
							}
						}
						
						// Test collision between background mask and sprite's mask
						if ([pBkdMask testMask:0 withX1:(int)rc.left andY1:(int)rc.top andMask:pSprMask andYBase:yMaskBits andX2:(int)sprRc.left andY2:(int)sprRc.top])
						{
							return YES;
						}
					}
				}
			} while (NO);
			
			// Wrapped?
			if (dwWrapFlags != 0)
			{
				i--;
			}
		}
	}
	return NO;
}

////////////////////////////////////////////////
//
// Test collision with a specific point
// Returns YES if the point is an obstacle or platform, NO if no obstacle
-(BOOL)bkdCol_TestPoint:(int)x withY:(int)y andLayer:(int)nLayer andPlane:(int)nPlane
{
	CLayer* pLayer;
	int dwFlags;
	
	// All layers?
	if (nLayer == LAYER_ALL)
	{
		// Test with layer 0
		////////////////////
		
		// Wrap mode and full collision mask?
		pLayer = layers[0];
		if ((leFlags & LEF_TOTALCOLMASK) != 0 && (pLayer->dwOptions & (FLOPT_WRAP_HORZ | FLOPT_WRAP_VERT)) != 0)
		{
			// Handle collisions like with the other layers (detect collisions with the objects, not with the collision mask)
			if ([self bkdLevObjCol_TestPoint:x withY:y andLayer:0 andPlane:nPlane])
			{
				return YES;
			}
			else
			{
				return NO;
			}
		}
		// Normal mode (no wrap mode, or windowed collision mask)
		else
		{
			if ([colMask testPoint:x withY:y andPlane:nPlane])
			{
				return YES;
			}
		}
		
		// Other layers
		///////////////
		if (nLayers == 1)
		{
			return NO;
		}
		
		// Test with background objects
		if ((leFlags & LEF_TOTALCOLMASK) != 0)
		{
			// Total colmask => test with levObjs
			return [self bkdLevObjCol_TestPoint:x withY:y andLayer:nLayer andPlane:nPlane];
		}
		else
		{
			// Partial colmask => test with background sprites
			dwFlags = SCF_BACKGROUND;
			if (nPlane == CM_TEST_PLATFORM)
			{
				dwFlags |= SCF_PLATFORM;
			}
			else
			{
				dwFlags |= SCF_OBSTACLE;
			}
			
			return ([app->run->spriteGen spriteCol_TestPoint:nil withLayer:(short)nLayer andX:x andY:y andFlags:dwFlags] != nil);
		}
	}
	
	// Layer 0?
	if (nLayer == 0)
	{
		// Wrap mode and full collision mask?
		pLayer = layers[0];
		if ((leFlags & LEF_TOTALCOLMASK) != 0 && (pLayer->dwOptions & (FLOPT_WRAP_HORZ | FLOPT_WRAP_VERT)) != 0)
		{
			// Handle collisions like with the other layers (detect collisions with the objects, not with the collision mask)
			return [self bkdLevObjCol_TestPoint:x withY:y andLayer:0 andPlane:nPlane];
		}
		// Normal mode (no wrap mode, or windowed collision mask)
		else
		{
			return [colMask testPoint:x withY:y andPlane:nPlane];
		}
	}
	
	// Only one layer?
	if (nLayers == 1)
	{
		return NO;
	}
	
	// Layer > 0, total colmask?
	if ((leFlags & LEF_TOTALCOLMASK) != 0)
	{
		// Total colmask => test with levObjs
		return [self bkdLevObjCol_TestPoint:x withY:y andLayer:nLayer andPlane:nPlane];
	}
	
	// Partial colmask => test with background sprites
	dwFlags = SCF_BACKGROUND;
	if (nPlane == CM_TEST_PLATFORM)
	{
		dwFlags |= SCF_PLATFORM;
	}
	else
	{
		dwFlags |= SCF_OBSTACLE;
	}
	
	return [app->run->spriteGen spriteCol_TestPoint:nil withLayer:LAYER_ALL andX:x andY:y andFlags:dwFlags] != nil;
}

////////////////////////////////////////////////
//
// Test collision with a rectangle
//
-(BOOL)bkdCol_TestRect:(int) x withY:(int)y andWidth:(int)nWidth andHeight:(int)nHeight andLayer:(int)nLayer andPlane:(int)nPlane
{
	CLayer* pLayer;
	int dwFlags;
	
	// All layers?
	if (nLayer == LAYER_ALL)
	{
		// Test with layer 0
		////////////////////
		
		// Wrap mode and full collision mask?
		pLayer = layers[0];
		if ((leFlags & LEF_TOTALCOLMASK) != 0 && (pLayer->dwOptions & (-FLOPT_WRAP_HORZ | FLOPT_WRAP_VERT)) != 0)
		{
			// Handle collisions like with the other layers (detect collisions with the objects, not with the collision mask)
			return [self bkdLevObjCol_TestRect:x withY:y andWidth:nWidth andHeight:nHeight andLayer:0 andPlane:nPlane];
		}
		// Normal mode (no wrap mode, or windowed collision mask)
		else
		{
			if ([colMask testRect:x withY:y andWidth:nWidth andHeight:nHeight andPlane:nPlane])
			{
				return YES;
			}
		}
		
		// Other layers
		///////////////
		if (nLayers == 1)
		{
			return NO;
		}
		
		// Test with background objects
		if ((leFlags & LEF_TOTALCOLMASK) != 0)
		{
			// Total colmask => test with levObjs
			if ([self bkdLevObjCol_TestRect:x withY:y andWidth:nWidth andHeight:nHeight andLayer:nLayer andPlane:nPlane])
			{
				return YES;
			}
			else
			{
				return NO;
			}
		}
		else
		{
			// Partial colmask => test with background sprites
			dwFlags = SCF_BACKGROUND;
			if (nPlane == CM_TEST_PLATFORM)
			{
				dwFlags |= SCF_PLATFORM;
			}
			else
			{
				dwFlags |= SCF_OBSTACLE;
			}
			
			if ([app->run->spriteGen spriteCol_TestRect:nil withLayer:nLayer andX:x andY:y andWidth:nWidth andHeight:nHeight andFlags:dwFlags] != nil)
			{
				return YES;
			}
			else
			{
				return NO;
			}
		}
	}
	
	// Layer 0?
	if (nLayer == 0)
	{
		// Wrap mode and full collision mask?
		pLayer = layers[0];
		if ((leFlags & LEF_TOTALCOLMASK) != 0 && (pLayer->dwOptions & (FLOPT_WRAP_HORZ | FLOPT_WRAP_VERT)) != 0)
		{
			// Handle collisions like with the other layers (detect collisions with the objects, not with the collision mask)
			if ([self bkdLevObjCol_TestRect:x withY:y andWidth:nWidth andHeight:nHeight andLayer:0 andPlane:nPlane])
			{
				return YES;
			}
			else
			{
				return NO;
			}
		}
		// Normal mode (no wrap mode, or windowed collision mask)
		else
		{
			if ([colMask testRect:x withY:y andWidth:nWidth andHeight:nHeight andPlane:nPlane])
			{
				return YES;
			}
			else
			{
				return NO;
			}
		}
	}
	
	// Only one layer?
	if (nLayers == 1)
	{
		return NO;
	}
	
	// Layer > 0, total colmask?
	if ((leFlags & LEF_TOTALCOLMASK) != 0)
	{
		// Total colmask => test with levObjs
		return [self bkdLevObjCol_TestRect:x withY:y andWidth:nWidth andHeight:nHeight andLayer:nLayer andPlane:nPlane];
	}
	
	// Partial colmask => test with background sprites
	dwFlags = SCF_BACKGROUND;
	if (nPlane == CM_TEST_PLATFORM)
	{
		dwFlags |= SCF_PLATFORM;
	}
	else
	{
		dwFlags |= SCF_OBSTACLE;
	}
	
	return ([app->run->spriteGen spriteCol_TestRect:nil withLayer:LAYER_ALL andX:x andY:y andWidth:nWidth andHeight:nHeight andFlags:dwFlags] != nil);
}

/** Tests the collision of a sprite in the background.
 * Called from the game's main loop.
 */
-(BOOL)bkdCol_TestSprite:(CSprite*)pSpr withImage:(int)newImg andX:(int)newX andY:(int)newY andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andFoot:(int)subHt andPlane:(int)nPlane
{
	// Get sprite layer
	int dwLayer = pSpr->sprLayer / 2;	// GetSpriteLayer(idEditWin, pSpr);
	
	// Layer 0
	CLayer* pLayer;
	int dwFlags;
	if (dwLayer == 0)
	{
		// Wrap mode and full collision mask?
		pLayer = layers[0];
		if ((leFlags & LEF_TOTALCOLMASK) != 0 && (pLayer->dwOptions & (FLOPT_WRAP_HORZ | FLOPT_WRAP_VERT)) != 0)
		{
			// Handle collisions like with the other layers (detect collisions with the objects, not with the collision mask)
			return [self bkdLevObjCol_TestSprite:pSpr withImage:(short)newImg andX:newX andY:newY andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY andFoot:subHt andPlane:nPlane];
		}
		// Normal mode (no wrap mode, or windowed collision mask)
		else
		{
			return [self colMask_TestSprite:pSpr withImage:newImg andX:newX andY:newY andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY andFoot:subHt andPlane:nPlane];
		}
	}
	
	// Only one layer?
	if (nLayers == 1)
	{
		return NO;
	}
	
	// Layer > 0, total colmask?
	if ((leFlags & LEF_TOTALCOLMASK) != 0)
	{
		// Total colmask => test with levObjs
		return [self bkdLevObjCol_TestSprite:pSpr withImage:(short)newImg andX:newX andY:newY andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY andFoot:subHt andPlane:nPlane];
	}
	
	// Partial colmask => test with background sprites
	dwFlags = SCF_BACKGROUND;
	if (nPlane == CM_TEST_PLATFORM)
	{
		dwFlags |= SCF_PLATFORM;
	}
	else
	{
		dwFlags |= SCF_OBSTACLE;
	}
	
	return ([app->run->spriteGen spriteCol_TestSprite:pSpr withImage:(short)newImg andX:newX andY:newY andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY andFoot:subHt andFlags:dwFlags] != nil);
}


//-------------------------------------------------------------------------;
//	Tester la collision d'un sprite avec le masque du fond d'une fenetre	;
//-------------------------------------------------------------------------;
-(BOOL)colMask_TestSprite:(CSprite*)pSpr withImage:(int)newImg andX:(int)newX andY:(int)newY andAngle:(float)newAngle andScaleX:(float)newScaleX andScaleY:(float)newScaleY andFoot:(int)subHt andPlane:(int)nPlane
{
	if (pSpr == nil || colMask == nil)
	{
		return NO;
	}
	
	int nImg = newImg;
	int x1 = newX;
	int y1 = newY;
	int nColMode = (int) app->run->spriteGen->colMode;
	int nWidth, nHeight;

	CRect sprRc;
	sprRc.left = newX;
	sprRc.top = newY;
	CMask* pMask = nil;
	
	if (newImg == 0)
	{
		nImg = pSpr->sprImg;
	}
	
	// Bitmap collision?
	if (nColMode != CM_BOX && (pSpr->sprFlags & SF_COLBOX) == 0)
	{
		// Image sprite not stretched and not rotated, or owner draw sprite?
		pMask = [app->run->spriteGen getSpriteMask:pSpr withImage:(short)nImg andFlags:GCMF_OBSTACLE andAngle:newAngle andScaleX:newScaleX andScaleY:newScaleY];
		if (pMask == nil)
		{
			x1 -= (pSpr->sprX - pSpr->sprX1);
			y1 -= (pSpr->sprY - pSpr->sprY1);
			nWidth = pSpr->sprX2 - pSpr->sprX1;
			nHeight = pSpr->sprY2 - pSpr->sprY1;
		}
		else
		{
			// Get sprite box
			BOOL hasHotspot = (pSpr->sprFlags & SF_NOHOTSPOT) == 0;
			if (hasHotspot)
			{
				x1 -= pMask->xSpot;
				y1 -= pMask->ySpot;
			}
			nWidth = pMask->width;
			nHeight = pMask->height;
		}
		
		// Test mask collision
		if (pMask != nil)
		{
			int yMaskBits = 0;
			
			// Take subHt into account
			if (subHt != 0)
			{
				if (subHt > nHeight)
				{
					subHt = nHeight;
				}
				y1 += nHeight - subHt;
				yMaskBits = nHeight - subHt;
				nHeight = subHt;
			}
			return [colMask testMask:pMask withYBase:yMaskBits andX:x1 andY:y1 andPlane:nPlane];
		}
	}
	else
	{
		// Box collision: no need to calculate the mask
		if (nImg == 0 || nImg == pSpr->sprImg || (pSpr->sprFlags & SF_OWNERDRAW) != 0)
		{
			x1 -= (pSpr->sprX - pSpr->sprX1);
			y1 -= (pSpr->sprY - pSpr->sprY1);
			nWidth = pSpr->sprX2 - pSpr->sprX1;
			nHeight = pSpr->sprY2 - pSpr->sprY1;
		}
		else
		{
			CImage* pei = [app->imageBank getImageFromHandle:(short)nImg];
			if (pei != nil)
			{
				x1 -= pei->xSpot;
				y1 -= pei->ySpot;
				nWidth = pei->width;
				nHeight = pei->height;
			}
			else
			{
				x1 -= (pSpr->sprX - pSpr->sprX1);
				y1 -= (pSpr->sprY - pSpr->sprY1);
				nWidth = pSpr->sprX2 - pSpr->sprX1;
				nHeight = pSpr->sprY2 - pSpr->sprY1;
			}
		}
	}
	
	// Take subHt into account
	if (subHt != 0)
	{
		if (subHt > nHeight)
		{
			subHt = nHeight;
		}
		y1 += nHeight - subHt;
		nHeight = subHt;
	}
	
	return [colMask testRect:x1 withY:y1 andWidth:nWidth andHeight:nHeight andPlane:nPlane];
}

-(NSString*)description
{
	if(frameName != nil)
		return [NSString stringWithFormat:@"%@", frameName];
	return @"";
}
	
@end
