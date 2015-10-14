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
// CRUNKCBOXA Active system box
//
//----------------------------------------------------------------------------------
#import "CBitmap.h"
#import "CRunKcBoxA.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CRun.h"
#import "CCreateObjectInfo.h"
#import "CExtension.h"
#import "CValue.h"
#import "CObjectCommon.h"
#import "CMoveDef.h"
#import "CMoveDefExtension.h"
#import "CRCom.h"
#import "CObjectCommon.h"
#import "CMoveDefList.h"
#import "CRMvt.h"
#import "CServices.h"
#import "CSpriteGen.h"
#import "CSprite.h"
#import "CObject.h"
#import "CExtension.h"
#import "CLayer.h"
#import "CRunApp.h"
#import "CRunFrame.h"
#import "CArrayList.h"
#import "CObjInfo.h"
#import "CRVal.h"
#import "CEventProgram.h"
#import "CFile.h"
#import "CArrayList.h"
#import "CFontInfo.h"
#import "CRect.h"
#import "CImage.h"
#import "CFont.h"
#import "CTextSurface.h"
#import "CRenderer.h"

@implementation CRunKcBoxA

-(int)getNumberOfConditions
{
	return 8;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	CRun* fprh = ho->hoAdRunHeader;
	
	// Get FrameData        
	KcBoxACFrameData* pData = nil;
	CExtStorage* pExtData = [fprh getStorage:ho->hoIdentifier];
	if (pExtData == nil)
	{
		pData = [[KcBoxACFrameData alloc] init];
		[fprh addStorage:pData  withID:ho->hoIdentifier];
	}
	else
	{
		pData = (KcBoxACFrameData*) pExtData;
	}
	
	// Set up parameters
	[ho setX:cob->cobX];
	[ho setY:cob->cobY];
	[ho setWidth:[file readAShort]];
	[ho setHeight:[file readAShort]];
	textSurface = [[CTextSurface alloc] initWidthWidth:ho->hoImgWidth andHeight:ho->hoImgHeight];
	
	// Copy CDATA (memcpy(&rdPtr->rData, &edPtr->eData, sizeof(CDATA));)
	rData = [[KcBoxACData alloc] init];
	rData->dwFlags = [file readAInt];
	rData->fillColor = [file readAInt];
	rData->borderColor1 = [file readAInt];
	rData->borderColor2 = [file readAInt];
	
	//file.skipBytes(2);
	short* imageList = (short*)malloc(1*sizeof(short));
	imageList[0] = [file readAShort];
	if (imageList[0] != -1)
	{
		[ho loadImageList:imageList withLength:1];
		rData->wImage = [ho getImage:imageList[0]];
	}
	
	rData->wFree = [file readAShort];
	rData->textColor = [file readAInt];
	rData->textMarginLeft = [file readAShort];
	rData->textMarginTop = [file readAShort];
	rData->textMarginRight = [file readAShort];
	rData->textMarginBottom = [file readAShort];
	
	// Init font
	wFont = [[CFontInfo alloc] init];
	wUnderlinedFont = [[CFontInfo alloc] init];	
	CFontInfo* textLf;
	if (ho->hoAdRunHeader->rhApp->bUnicode==NO)
	{
		textLf = [file readLogFont16];
	}
	else
	{
		textLf = [file readLogFont];
	}
	if (textLf->lfFaceName != nil)
	{
		[wFont release];
		wFont = textLf;//this.wFont.font = textLf.createFont();
		if ((rData->dwFlags & FLAG_HYPERLINK) != 0)
		{
			textLf->lfUnderline = 1;
			[wUnderlinedFont release];
			wUnderlinedFont = [CFontInfo fontInfoFromFontInfo:textLf];//this.wUnderlinedFont.font = textLf.createFont();
		}
	}
	else
	{
		[textLf release];
	}
	
	// Copy text
	dwRtFlags = 0;
	pText = nil;
	[file skipStringOfLength:40];
	[file adjustTo8];
	
	int textSize = [file readAInt];
	if (ho->hoAdRunHeader->rhApp->bUnicode)
	{
		textSize=textSize/2;
	}
	//        file.skipBytes(2); //necessary for some reason
	if (textSize != 0)
	{
		// Extract tool tip
		NSString* lText = [file readAStringWithSize:textSize];//file.readString();
		textSize=(int)[lText length];
		for (int i = textSize-1; i >= 1; i--)
		{
			if ( ([lText characterAtIndex:i]=='n') && ([lText characterAtIndex:i-1]=='\\') )
			{
				textSize=i-1;
				lText = [[NSString alloc] initWithString:[lText substringToIndex:textSize]];
				break;
			}
		}
		if (textSize != 0)
		{
			pText = [[NSString alloc] initWithString:lText];
		}
		[lText release];
	}
	else
		pText = [[NSString alloc] initWithString:@""];
	
	// Add to global list of objects
	rNumInObjList = [pData AddObject:self]; //up to here
	
	// Container?
	rNumInContList = -1;
	if ((rData->dwFlags & FLAG_CONTAINER) != 0)
	{
		rNumInContList = [pData AddContainer:self];
	}
	
	// Contained?
	rContNum = -1;
	if ((rData->dwFlags & FLAG_CONTAINED) != 0)
	{
		rContNum = [pData GetContainer:self];
		if (rContNum != -1)
		{
			CRunKcBoxA* rdPtrCont = (CRunKcBoxA*)[pData->pContainers get:rContNum];
			rContDx = (short) [ho getX] - [rdPtrCont->ho getX];
			rContDy = (short) [ho getY] - [rdPtrCont->ho getY];
		}
	}
	rData1 = [[KcBoxACData1 alloc] init];
	rData1->dwVersion = [file readAInt];
	rData1->dwUnderlinedColor = [file readAInt];
	
	// Button?
	rNumInBtnList = -1;
	rClickCount = -1;
	rLeftClickCount = -1;
	if ((rData->dwFlags & (FLAG_BUTTON | FLAG_HYPERLINK)) != 0)
	{
		rNumInBtnList = [pData AddButton:self];
	}
	
	updated = YES;
	oldKMouse = rh->rhApp->bMouseDown;

	return NO;
}

-(void)destroyRunObject:(BOOL)bFast
{
	CRun* rhPtr = ho->hoAdRunHeader;
	
	// Get FrameData
	KcBoxACFrameData* pData = (KcBoxACFrameData*)[rhPtr getStorage:ho->hoIdentifier];
	
	// Container?
	if ((rNumInContList != -1) && (pData != nil))
	{
		[pData RemoveContainer:self];
	}
	
	// Remove from global list of objects
	if ((rNumInObjList != -1) && (pData != nil))
	{
		[pData RemoveObjectFromList:self];
	}
	
	if ([pData IsEmpty])
	{
		[rhPtr delStorage:ho->hoIdentifier];
		[pData release];
	}
	if (pText!=nil)
	{
		[pText release];
	}
	[rData release];
	[rData1 release];
	[textSurface release];
}

-(void)mouseClicked
{
	CRun* rhPtr = ho->hoAdRunHeader;
	KcBoxACFrameData* pData = (KcBoxACFrameData*)[rhPtr getStorage:ho->hoIdentifier];
	if (pData != nil)
	{
		if ((rData->dwFlags & FLAG_DISABLED) == 0)
		{
			if (rNumInObjList == [pData GetObjectFromList:rh->rh2MouseX  withParam1:rh->rh2MouseY])
			{
				rClickCount = [ho getEventCount];
				[ho pushEvent:CND_CLICKED  withParam:[ho getEventParam]];
			}
		}
	}
}

-(void)mousePressed
{
	CRun* rhPtr = ho->hoAdRunHeader;
	KcBoxACFrameData* pData = (KcBoxACFrameData*)[rhPtr getStorage:ho->hoIdentifier];
	if (pData != nil)
	{
		if ((rData->dwFlags & FLAG_DISABLED) == 0)
		{
			if (rNumInObjList == [pData GetObjectFromList:rh->rh2MouseX  withParam1:rh->rh2MouseY])
			{
				if ((rData->dwFlags & FLAG_BUTTON) != 0)//is a button
				{
					rData->dwFlags |= FLAG_BUTTON_PRESSED;
					if ((rData->dwFlags & FLAG_CHECKBOX) != 0)//is a checkbox
					{
						if ((rData->dwFlags & FLAG_CHECKED) != 0) //is checked
						{
							rData->dwFlags &= ~FLAG_CHECKED;
						}
						else
						{
							rData->dwFlags |= FLAG_CHECKED;
						}
					}
				}
				if ((rData->dwFlags & FLAG_HYPERLINK) != 0) //if hyperlink
				{
					if ((rData->dwFlags & FLAG_BUTTON_HIGHLIGHTED) == 0)
					{
						rData->dwFlags |= FLAG_BUTTON_HIGHLIGHTED;
					}
				}
				rLeftClickCount = [ho getEventCount];
				[ho pushEvent:CND_LEFTCLICK  withParam:[ho getEventParam]];
				[ho redraw];
			}
		}
	}
}

-(void)mouseReleased
{
	BOOL redraw = NO;
	if ((rData->dwFlags & FLAG_BUTTON_PRESSED) != 0)
	{
		rData->dwFlags &= ~FLAG_BUTTON_PRESSED;
		redraw = YES;
	}
	if ((rData->dwFlags & FLAG_BUTTON_HIGHLIGHTED) != 0)
	{
		rData->dwFlags &= ~FLAG_BUTTON_HIGHLIGHTED;
		redraw = YES;
	}
	if (redraw == YES)
	{
		[ho redraw];
	}
}

-(int)handleRunObject
{
	CRun* rhPtr = ho->hoAdRunHeader;
	
	BOOL kMouse=rhPtr->rhApp->bMouseDown;
	if (kMouse!=oldKMouse)
	{
		oldKMouse=kMouse;
		if (kMouse)
		{
			[self mousePressed];
		}
		else
		{
			[self mouseClicked];
			[self mouseReleased];
		}
	}
	
	int oldX = [ho getX];
	int oldY = [ho getY];
	int newX = oldX;
	int newY = oldY;
	int reCode = 0;
	
	KcBoxACFrameData* pData = (KcBoxACFrameData*)[rhPtr getStorage:ho->hoIdentifier];
	if (pData != nil)
	{
		BOOL bActive = YES;
		if (bActive == YES)
		{
			if (((rData->dwFlags & FLAG_BUTTON) != 0) || ((rData->dwFlags & FLAG_HYPERLINK) != 0)) //15th april 09 change
			{
				if ((rData->dwFlags & FLAG_DISABLED) == 0)
				{
					if (rNumInObjList == [pData GetObjectFromList:rh->rh2MouseX  withParam1:rh->rh2MouseY])
					{
						if ((rData->dwFlags & FLAG_BUTTON_HIGHLIGHTED) == 0)
						{
							rData->dwFlags |= FLAG_BUTTON_HIGHLIGHTED;
						}
					}
					else
					{
						if ((rData->dwFlags & FLAG_BUTTON_HIGHLIGHTED) != 0)
						{
							rData->dwFlags &= ~FLAG_BUTTON_HIGHLIGHTED;
						}
					}
					reCode = REFLAG_DISPLAY;
				}
			}
		}
	}
	
	// Docking
	if ((dwRtFlags & DOCK_FLAGS) != 0 && (rData->dwFlags & FLAG_CONTAINED) == 0)
	{
		int windowWidth = rhPtr->rhApp->gaCxWin;
		int windowHeight = rhPtr->rhApp->gaCyWin;
		int x = 0;
		int y = 0;
		int w = rhPtr->rhApp->gaCxWin;
		int h = rhPtr->rhApp->gaCyWin;
		// Dock
		if ((dwRtFlags & DOCK_LEFT) != 0)
		{
			if (windowWidth > w)
			{
				newX = (int)(rh->rhFrame->leX + abs(x) - (windowWidth - w) / 2);
			}
			else
			{
				newX = (int)(rh->rhFrame->leX + abs(x));
			}
		}
		if ((dwRtFlags & DOCK_RIGHT) != 0)
		{
			if (windowWidth > w)
			{
				newX = (int)(rh->rhFrame->leX + abs(x) + w - [ho getWidth] - (windowWidth - w) / 2);
			}
			else
			{
				newX = (int)(rh->rhFrame->leX + abs(x) + w - [ho getWidth]);
			}
		}
		if ((dwRtFlags & DOCK_TOP) != 0)
		{
			if (windowHeight > h)
			{
				newY = (int)(rh->rhFrame->leY + abs(y) - (windowHeight - h) / 2);
			}
			else
			{
				newY = (int)(rh->rhFrame->leY + abs(y));
			}
		}
		if ((dwRtFlags & DOCK_BOTTOM) != 0)
		{
			if (windowHeight > h)
			{
				newY = (int)(rh->rhFrame->leY + abs(y) + h - [ho getHeight] - (windowHeight - h) / 2);
			}
			else
			{
				newY = (int)(rh->rhFrame->leY - abs(y) + h - [ho getHeight]); //requires - here for some reason.
			}
		}
	}
	
	// Contained ? must update coordinates
	if ((rData->dwFlags & FLAG_CONTAINED) != 0)
	{
		// Not yet a container? search Medor, search!
		if (rContNum == -1)
		{
			if (pData != nil)
			{
				rContNum = [pData GetContainer:self];
				if (rContNum != -1)
				{
					CRunKcBoxA* rdPtrCont = (CRunKcBoxA*)[pData->pContainers get:rContNum];
					rContDx = (short) ([ho getX] - [rdPtrCont->ho getX]);
					rContDy = (short) ([ho getY] - [rdPtrCont->ho getY]);
				}
			}
		}
		
		if ((rContNum != -1) && (pData != nil) && (rContNum < [pData->pContainers size]))
		{
			CRunKcBoxA* rdPtrCont = (CRunKcBoxA*)[pData->pContainers get:rContNum];
			if (rdPtrCont != nil)
			{
				newX = [rdPtrCont->ho getX] + rContDx;
				newY = [rdPtrCont->ho getY] + rContDy;
			}
		}
	}
	
	if ((newX != oldX) || (newY != oldY))
	{
		[ho setX:newX];
		[ho setY:newY];
		
		// Update tooltip position
		//UpdateToolTipRect(rdPtr);
		
		reCode = REFLAG_DISPLAY;
	}
	return reCode;	// REFLAG_ONESHOT+REFLAG_DISPLAY;
	
}

-(void)displayRunObject:(CRenderer*)renderer
{
	CRect rc = ho->hoRect;
	CFontInfo* hFn=wFont;
	if ((wFont != nil) && ([pText length] != 0) && (rData->textColor != COLOR_NONE))
	{
		if (((rData->dwFlags & FLAG_HYPERLINK) != 0) && (wUnderlinedFont != nil))
		{
			if ((rData->dwFlags & (FLAG_BUTTON_HIGHLIGHTED | FLAG_BUTTON_PRESSED)) != 0)
			{
				hFn = wUnderlinedFont;
			}
		}
	}
	[self DisplayObject:renderer withParam1:ho->hoAdRunHeader->rhApp andParam2:rc andParam3:rData andParam4:pText andParam5:hFn andParam6:rData1];
}

-(void)BuildSysColorTable
{
	sysColorTab[0] = 0xc8c8c8;
	sysColorTab[1] = 0x000000;
	sysColorTab[2] = 0x99b4d1;
	sysColorTab[3] = 0xbfcddb;//SystemColor.activeCaptionBorder;
	sysColorTab[4] = 0xf0f0f0;
	sysColorTab[5] = 0xffffff;
	sysColorTab[6] = 0x646464;//SystemColor.inactiveCaptionBorder;
	sysColorTab[7] = 0x000000;
	sysColorTab[8] = 0x000000;
	sysColorTab[9] = 0x000000;
	sysColorTab[10] = 0xb4b4b4;//new
	sysColorTab[11] = 0xf4f7fc;//new
	sysColorTab[12] = 0xababab;//mdi one, doesn't quite match. There is no java mdi background colour./ AppWorksapce
	sysColorTab[13] = 0x3399ff;//SystemColor.textText;
	sysColorTab[14] = 0xffffff; //new //SystemColor.textHighlight;
	sysColorTab[15] = 0xf0f0f0;//SystemColor.textHighlightText;
	sysColorTab[16] = 0xa0a0a0;//SystemColor.textInactiveText;
	sysColorTab[17] = 0x808080;
	sysColorTab[18] = 0x000000;
	sysColorTab[19] = 0x434e54;
	sysColorTab[20] = 0xffffff;
	sysColorTab[21] = 0x696969;
	sysColorTab[22] = 0xe3e3e3;
	sysColorTab[23] = 0x000000;
	sysColorTab[24] = 0xffffe1;
}

-(int)myGetSysColor:(int)colorIndex
{
	// Build table
	if (!bSysColorTab)
	{
		[self BuildSysColorTable];
		bSysColorTab = YES;
	}
	
	// Get color
	if (colorIndex < COLOR_GRADIENTINACTIVECAPTION)
	{
		return sysColorTab[colorIndex];
	}
	
	// Unknown color
	//return GetSysColor(colorIndex);
	return 0;
}

-(void)DisplayObject:(CRenderer*)renderer withParam1:(CRunApp*)idApp andParam2:(CRect)rc andParam3:(KcBoxACData*)pc andParam4:(NSString*)text andParam5:(CFontInfo*)hFnt andParam6:(KcBoxACData1*)pdata1
{
	int x = (int)rc.left;
	int y = (int)rc.top;
	int w = (int)rc.width();
	int h = (int)rc.height();

	CRect oldrc = rc;
	rc.left = rc.top = 0;
	rc.bottom = h;
	rc.right = w;
	
	// Background
	if (pc->fillColor != COLOR_NONE)
	{
		int color;
		int clr = pc->fillColor;
		if ((clr & COLORFLAG_RGB) != 0)
		{
			color = (clr & ~COLOR_FLAGS);
        }
        else
		{
			if (((pc->dwFlags & FLAG_CHECKED) != 0) && (clr == COLOR_BTNFACE))
            {
                clr = COLOR_3DLIGHT;
            }
            color = [self myGetSysColor:clr];
		}
		renderer->renderSolidColor(color, x, y, w, h, 0, 0);
	}
			
	// Image
	if ((pc->wImage != nil) && ((pc->dwFlags & FLAG_HIDEIMAGE) == 0))
	{
		BOOL bDisplayImage = YES;
		if ((pc->dwFlags & (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX)) == (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX))
		{
			if ((pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) == 0)
			{
				bDisplayImage = NO;
			}
		}
		if (bDisplayImage == YES)
		{
			int xc, yc, wc, hc;
			if ((pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0 && (pc->dwFlags & (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX)) != (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX))
			{
				x += 2;
				y += 2;
			}
			
			xc = x;
			wc = w;
			yc = y;
			hc = h;
			
			if ((pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0 && (pc->dwFlags & (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX)) != (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX))
			{
				wc -= 2;
				hc -= 2;
			}
		
			if (wc > 0 && hc > 0)
			{
				renderer->setClip(xc, yc, wc, hc);
				if ((pc->dwFlags & ALIGN_IMAGE_TOPLEFT) != 0)
				{
					renderer->renderImage(rData->wImage, x, y, rData->wImage->width, rData->wImage->height, 0, 0);
				}
				else if ((pc->dwFlags & ALIGN_IMAGE_CENTER) != 0)
				{
					renderer->renderImage(rData->wImage, x+(w-rData->wImage->width)/2, y+(h-rData->wImage->height)/2, rData->wImage->width, rData->wImage->height, 0, 0);
                }	
                else if ((pc->dwFlags & ALIGN_IMAGE_PATTERN) != 0)
                {	
					int wi = rData->wImage->width;
					int hi = rData->wImage->height;
					for (int yi = 0; yi < h; yi += hi)
					{
						for (int xi = 0; xi < w; xi += wi)
						{
							renderer->renderImage(rData->wImage, x+xi, y+yi, rData->wImage->width, rData->wImage->height, 0, 0);
						}
					}
				}
				renderer->resetClip();
			}
			pc->dwFlags &= ~FLAG_FORCECLIPPING;
			
			if ((pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0 && (pc->dwFlags & (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX)) != (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX))
			{
				x -= 2;
				y -= 2;
			}
		}
	}
	
	// Text
	if (([text length] != 0) && (pc->textColor != COLOR_NONE))
	{
		updated |= [textSurface setSizeWithWidth:w andHeight:h];
		
		if(updated)
		{
			[textSurface manualClear:ABGRtoRGB(pc->textColor)];
			
			unsigned int dtFlags = 0;
			
			if ( (pc->dwFlags & ALIGN_MULTILINE) == 0 )
				dtFlags |= DT_SINGLELINE;
			
			if ( pc->dwFlags & ALIGN_LEFT )
				dtFlags |= DT_LEFT;
			if ( pc->dwFlags & ALIGN_HCENTER )
				dtFlags |= DT_CENTER;
			if ( pc->dwFlags & ALIGN_RIGHT )
				dtFlags |= DT_RIGHT;
			
			//Turns out they DO work in multiline mode!
			if ( pc->dwFlags & ALIGN_TOP )
				dtFlags |= DT_TOP;
			if ( pc->dwFlags & ALIGN_VCENTER )
				dtFlags |= DT_VCENTER;
			if ( pc->dwFlags & ALIGN_BOTTOM )
				dtFlags |= DT_BOTTOM;
			
			// Add margin
			rc.left += pc->textMarginLeft;
			rc.top += pc->textMarginTop;
			rc.right -= (pc->textMarginRight+1);
			rc.bottom -= (pc->textMarginBottom+1);
			
			if ( (pc->dwFlags & FLAG_BUTTON) != 0 && (pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0 && (pc->dwFlags & (FLAG_BUTTON|FLAG_CHECKBOX|FLAG_IMAGECHECKBOX)) != (FLAG_BUTTON|FLAG_CHECKBOX|FLAG_IMAGECHECKBOX) )
			{
				rc.left += 2;
				rc.top += 2;
			}
			
			// Vertical alignement in multi-line mode
			CFont* font=[CFont createFromFontInfo:hFnt];
			if ( (pc->dwFlags & ALIGN_MULTILINE) != 0 && (pc->dwFlags & (ALIGN_VCENTER | ALIGN_BOTTOM)) != 0 )
			{
				CRect rcSave = rc;
				CRect rc1 = rc;
				
				[textSurface manualDrawText:text withFlags:dtFlags|DT_CALCRECT andRect:rc1 andColor:ABGRtoRGB(pc->textColor) andFont:font];
				
				int hr = (int)rc.height();
				int ht = (int)rc1.height();
				if ( (pc->dwFlags & ALIGN_BOTTOM) != 0 )
					rc.top = rc.bottom - ht;
				else
				{
					rc.top += (hr-ht)/2;
				}
				
				// Limit
				if ( rc.left < rcSave.left )
					rc.left = rcSave.left;
				if ( rc.top < rcSave.top )
					rc.top = rcSave.top;
				if ( rc.right > rcSave.right )
					rc.right = rcSave.right;
				if ( rc.bottom > rcSave.bottom )
					rc.bottom = rcSave.bottom;
			}
			
			// Text color...
			if ( pc->dwFlags & FLAG_DISABLED )
			{
				int clr = [self myGetSysColor:20];
				rc.left++;
				rc.top++;
				rc.right++;
				rc.bottom++;
				[textSurface manualDrawText:text withFlags:dtFlags andRect:rc andColor:ABGRtoRGB(clr) andFont:font];
				clr = [self myGetSysColor:16];
				rc.left--;
				rc.top--;
				rc.right--;
				rc.bottom--;
				[textSurface manualDrawText:text withFlags:dtFlags andRect:rc andColor:ABGRtoRGB(clr) andFont:font];
			}
			else
			{
				int clr = pc->textColor;
				
				if ( (pc->dwFlags & FLAG_HYPERLINK) != 0 )
				{
					if ( (pc->dwFlags & (FLAG_BUTTON_HIGHLIGHTED | FLAG_BUTTON_PRESSED)) != 0 )
					{
						clr = pdata1->dwUnderlinedColor;		// COLORFLAG_RGB | 0x0000FF;
					}
				}
				
				if ( clr & COLORFLAG_RGB )
					clr &= ~COLOR_FLAGS;
				else
					clr = [self myGetSysColor:clr];
				[textSurface manualDrawText:text withFlags:dtFlags andRect:rc andColor:ABGRtoRGB(clr) andFont:font];
			}
			
			if ( (pc->dwFlags & FLAG_BUTTON) != 0 && (pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0 && (pc->dwFlags & (FLAG_BUTTON|FLAG_CHECKBOX|FLAG_IMAGECHECKBOX)) != (FLAG_BUTTON|FLAG_CHECKBOX|FLAG_IMAGECHECKBOX) )
			{
				rc.left -= 2;
				rc.top  -= 2;
			}
			
			// Remove margin
			rc.left -= pc->textMarginLeft;
			rc.top -= pc->textMarginTop;
			rc.right += pc->textMarginRight;
			rc.bottom += pc->textMarginBottom;
			
			[textSurface manualUploadTexture];
			
			[font release];
		}
		
		[textSurface draw:renderer withX:oldrc.left andY:oldrc.top andEffect:0 andEffectParam:0];
		updated = NO;
	}

	// Border
	int color1 = (int) pc->borderColor1;
	int color2 = (int) pc->borderColor2;
	BOOL bDisplayBorder = YES;
	if ((pc->dwFlags & FLAG_BUTTON) != 0)
	{
		if ((pc->dwFlags & FLAG_SHOWBUTTONBORDER) == 0)
		{
			// App active?
			bDisplayBorder = ((pc->dwFlags & (FLAG_BUTTON_HIGHLIGHTED | FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0);
		}
		if ((pc->dwFlags & (FLAG_BUTTON_PRESSED | FLAG_CHECKED)) != 0 && (pc->dwFlags & (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX)) != (FLAG_BUTTON | FLAG_CHECKBOX | FLAG_IMAGECHECKBOX))
		{
			color1 = (int) pc->borderColor2;
			color2 = (int) pc->borderColor1;
		}
	}
	if (bDisplayBorder == YES)
	{
		if (color1 != (int) COLOR_NONE)
		{
			if ((color1 & COLORFLAG_RGB) != 0)
			{
				color1 &= ~COLOR_FLAGS;
			}
			else
			{
				color1 = [self myGetSysColor:color1];
			}
			renderer->renderSolidColor(color1, x, y, w-1, 1, 0, 0);
			renderer->renderSolidColor(color1, x, y, 1, h-1, 0, 0);
		}
		if (color2 != COLOR_NONE)
		{
			if ((color2 & COLORFLAG_RGB) != 0)
			{
				color2 &= ~COLOR_FLAGS;
			}
			else
			{
				color2 = [self myGetSysColor:color2];
			}
			renderer->renderSolidColor(color2, x,		y+h-1,	w,	1, 0, 0);
			renderer->renderSolidColor(color2, x+w-1,	y,		1,	h-1, 0, 0);
		}
	}

}

-(CFontInfo*)getRunObjectFont
{
	return wFont;
}

-(void)setRunObjectFont:(CFontInfo*)fi withRect:(CRect)rc
{
	[wFont release];
	wFont = [CFontInfo fontInfoFromFontInfo:fi];
	if ((rData->dwFlags & FLAG_HYPERLINK) != 0)
	{
		wFont->lfUnderline = 1;
		wUnderlinedFont = fi;
	}
	
	if (!rc.isNil())
	{
		[ho setWidth:(int)rc.right];
		[ho setHeight:(int)rc.bottom];
		ho->hoRect.right = ho->hoRect.left + rc.right;
		ho->hoRect.bottom = ho->hoRect.top + rc.bottom;
	}
	[ho redraw];
	
}

-(int)getRunObjectTextColor
{
	int clr = (int) rData->textColor;
	if ((clr & COLORFLAG_RGB) != 0)
	{
		return clr & ~(int) COLORFLAG_RGB;
	}
	return [self myGetSysColor:clr];
}

-(void)setRunObjectTextColor:(int)rgb
{
	rData->textColor = (rgb | COLORFLAG_RGB);
	[ho redraw];
}



// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_CLICKED:
			return [self IsClicked];
		case CND_ENABLED:
			return [self IsEnabled];
		case CND_CHECKED:
			return [self IsChecked];
		case CND_LEFTCLICK:
			return [self LeftClick];
		case CND_RIGHTCLICK:
			return [self RightClick];
		case CND_MOUSEOVER:
			return [self MouseOver];
		case CND_IMAGESHOWN:
			return [self IsImageShown];
		case CND_DOCKED:
			return [self IsDocked];
	}
	return NO;
}

-(BOOL)IsClicked
{
	CRun* rhPtr = ho->hoAdRunHeader;
	if (rClickCount == -1)
	{
		return NO;
	}
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if (rhPtr->rh4EventCount == rClickCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)IsEnabled
{
	return ((rData->dwFlags & FLAG_DISABLED) == 0);
}
-(BOOL)IsChecked
{
	return ((rData->dwFlags & FLAG_CHECKED) != 0);
}
-(BOOL)LeftClick
{
	CRun* rhPtr = ho->hoAdRunHeader;
	if ((ho->hoFlags & HOF_TRUEEVENT) != 0)
	{
		return YES;
	}
	if (rhPtr->rh4EventCount == rLeftClickCount)
	{
		return YES;
	}
	return NO;
}
-(BOOL)RightClick
{
	return NO;
}

-(BOOL)MouseOver
{
	CRun* rhPtr = ho->hoAdRunHeader;
	KcBoxACFrameData* pData = (KcBoxACFrameData*)[rhPtr getStorage:ho->hoIdentifier];
	if (pData != nil)
	{
		return (rNumInObjList == [pData GetObjectFromList:rh->rh2MouseX  withParam1:rh->rh2MouseY]);
	}
	return NO;
}

-(BOOL)IsImageShown
{
	return ((rData->dwFlags & FLAG_HIDEIMAGE) == 0);
}
-(BOOL)IsDocked
{
	return ((dwRtFlags & DOCK_FLAGS) != 0);
}

// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num){
		case ACT_ACTION_SETDIM:
			[self SetDimensions:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case ACT_ACTION_SETPOS:
			[self SetPosition:[act getParamExpression:rh withNum:0] withParam1:[act getParamExpression:rh withNum:1]];
			break;
		case ACT_ACTION_ENABLE:
			[self Enable];
			break;
		case ACT_ACTION_DISABLE:
			[self Disable];
			break;
		case ACT_ACTION_CHECK:
			[self Check];
			break;
		case ACT_ACTION_UNCHECK:
			[self Uncheck];
			break;
		case ACT_ACTION_SETCOLOR_NONE:
			[self SetFillColor_None];
			break;
		case ACT_ACTION_SETCOLOR_3DDKSHADOW:
			[self SetFillColor_3DDKSHADOW];
			break;
		case ACT_ACTION_SETCOLOR_3DFACE:
			[self SetFillColor_3DFACE];
			break;
		case ACT_ACTION_SETCOLOR_3DHILIGHT:
			[self SetFillColor_3DHIGHLIGHT];
			break;
		case ACT_ACTION_SETCOLOR_3DLIGHT:
			[self SetFillColor_3DLIGHT];
			break;
		case ACT_ACTION_SETCOLOR_3DSHADOW:
			[self SetFillColor_3DSHADOW];
			break;
		case ACT_ACTION_SETCOLOR_ACTIVECAPTION:
			[self SetFillColor_ACTIVECAPTION];
			break;
		case ACT_ACTION_SETCOLOR_APPWORKSPACE:
			[self SetFillColor_APPWORKSPACE];
			break;
		case ACT_ACTION_SETCOLOR_DESKTOP:
			[self SetFillColor_DESKTOP];
			break;
		case ACT_ACTION_SETCOLOR_HIGHLIGHT:
			[self SetFillColor_HIGHLIGHT];
			break;
		case ACT_ACTION_SETCOLOR_INACTIVECAPTION:
			[self SetFillColor_INACTIVECAPTION];
			break;
		case ACT_ACTION_SETCOLOR_INFOBK:
			[self SetFillColor_INFOBK];
			break;
		case ACT_ACTION_SETCOLOR_MENU:
			[self SetFillColor_MENU];
			break;
		case ACT_ACTION_SETCOLOR_SCROLLBAR:
			[self SetFillColor_SCROLLBAR];
			break;
		case ACT_ACTION_SETCOLOR_WINDOW:
			[self SetFillColor_WINDOW];
			break;
		case ACT_ACTION_SETCOLOR_WINDOWFRAME:
			[self SetFillColor_WINDOWFRAME];
			break;
		case ACT_ACTION_SETCOLOR_OTHER:
			[self SetFillColor_Other:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_ACTION_SETB1COLOR_NONE:
			[self SetB1Color_None];
			break;
		case ACT_ACTION_SETB1COLOR_3DDKSHADOW:
			[self SetB1Color_3DDKSHADOW];
			break;
		case ACT_ACTION_SETB1COLOR_3DFACE:
			[self SetB1Color_3DFACE];
			break;
		case ACT_ACTION_SETB1COLOR_3DHILIGHT:
			[self SetB1Color_3DHIGHLIGHT];
			break;
		case ACT_ACTION_SETB1COLOR_3DSHADOW:
			[self SetB1Color_3DSHADOW];
			break;
		case ACT_ACTION_SETB1COLOR_ACTIVEBORDER:
			[self SetB1Color_ACTIVEBORDER];
			break;
		case ACT_ACTION_SETB1COLOR_INACTIVEBORDER:
			[self SetB1Color_INACTIVEBORDER];
			break;
		case ACT_ACTION_SETB1COLOR_WINDOWFRAME:
			[self SetB1Color_WINDOWFRAME];
			break;
		case ACT_ACTION_SETB1COLOR_OTHER:
			[self SetB1Color_Other:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_ACTION_SETB2COLOR_NONE:
			[self SetB2Color_None];
			break;
		case ACT_ACTION_SETB2COLOR_3DDKSHADOW:
			[self SetB2Color_3DDKSHADOW];
			break;
		case ACT_ACTION_SETB2COLOR_3DFACE:
			[self SetB2Color_3DFACE];
			break;
		case ACT_ACTION_SETB2COLOR_3DHILIGHT:
			[self SetB2Color_3DHIGHLIGHT];
			break;
		case ACT_ACTION_SETB2COLOR_3DLIGHT:
			[self SetB2Color_3DLIGHT];
			break;
		case ACT_ACTION_SETB2COLOR_3DSHADOW:
			[self SetB2Color_3DSHADOW];
			break;
		case ACT_ACTION_SETB2COLOR_ACTIVEBORDER:
			[self SetB2Color_ACTIVEBORDER];
			break;
		case ACT_ACTION_SETB2COLOR_INACTIVEBORDER:
			[self SetB2Color_INACTIVEBORDER];
			break;
		case ACT_ACTION_SETB2COLOR_WINDOWFRAME:
			[self SetB2Color_WINDOWFRAME];
			break;
		case ACT_ACTION_SETB2COLOR_OTHER:
			[self SetB2Color_Other :[act getParamExpression:rh withNum:0]];
			break;
		case ACT_ACTION_TEXTCOLOR_NONE:
			[self SetTxtColor_None];
			break;
		case ACT_ACTION_TEXTCOLOR_3DHILIGHT:
			[self SetTxtColor_3DHIGHLIGHT];
			break;
		case ACT_ACTION_TEXTCOLOR_3DSHADOW:
			[self SetTxtColor_3DSHADOW];
			break;
		case ACT_ACTION_TEXTCOLOR_BTNTEXT:
			[self SetTxtColor_BTNTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_CAPTIONTEXT:
			[self SetTxtColor_CAPTIONTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_GRAYTEXT:
			[self SetTxtColor_GRAYTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_HIGHLIGHTTEXT:
			[self SetTxtColor_HIGHLIGHTTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_INACTIVECAPTIONTEXT:
			[self SetTxtColor_INACTIVECAPTIONTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_INFOTEXT:
			[self SetTxtColor_INFOTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_MENUTEXT:
			[self SetTxtColor_MENUTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_WINDOWTEXT:
			[self SetTxtColor_WINDOWTEXT];
			break;
		case ACT_ACTION_TEXTCOLOR_OTHER:
			[self SetTxtColor_Other :[act getParamExpression:rh withNum:0]];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_NONE:
			[self SetHyperlinkColor_None];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_3DHILIGHT:
			[self SetHyperlinkColor_3DHIGHLIGHT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_3DSHADOW:
			[self SetHyperlinkColor_3DSHADOW];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_BTNTEXT:
			[self SetHyperlinkColor_BTNTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_CAPTIONTEXT:
			[self SetHyperlinkColor_CAPTIONTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_GRAYTEXT:
			[self SetHyperlinkColor_GRAYTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_HIGHLIGHTTEXT:
			[self SetHyperlinkColor_HIGHLIGHTTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_INACTIVECAPTIONTEXT:
			[self SetHyperlinkColor_INACTIVECAPTIONTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_INFOTEXT:
			[self SetHyperlinkColor_INFOTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_MENUTEXT:
			[self SetHyperlinkColor_MENUTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_WINDOWTEXT:
			[self SetHyperlinkColor_WINDOWTEXT];
			break;
		case ACT_ACTION_HYPERLINKCOLOR_OTHER:
			[self SetHyperlinkColor_Other:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_ACTION_SETTEXT:
			[self SetText:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_ACTION_SETTOOLTIPTEXT:
			[self SetToolTipText:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_ACTION_UNDOCK:
			[self Undock];
			break;
		case ACT_ACTION_DOCK_LEFT:
			[self DockLeft];
			break;
		case ACT_ACTION_DOCK_RIGHT:
			[self DockRight];
			break;
		case ACT_ACTION_DOCK_TOP:
			[self DockTop];
			break;
		case ACT_ACTION_DOCK_BOTTOM:
			[self DockBottom];
			break;
		case ACT_ACTION_SHOWIMAGE:
			[self ShowImage];
			break;
		case ACT_ACTION_HIDEIMAGE:
			[self HideImage];
			break;
		case ACT_ACTION_RESETCLICKSTATE:
			[self ResetClickState];
			break;
		case ACT_ACTION_SETCMDID: //non operational
			[self AttachMenuCmd];
			break;
		}	
	}

	-(void)SetDimensions :(int)w withParam1:(int)h
	{
		// Set dimensions
		if (([ho getWidth] != w) ||  ([ho getHeight] != h))
		{
			[ho setWidth:w];//rdPtr->rHo.hoImgWidth = (short)p1;
			[ho setHeight:h];//rdPtr->rHo.hoImgHeight = (short)p2;
			
			// Update tooltip rectangle
			//UpdateToolTipRect(rdPtr);
			[ho redraw];
	}
}

-(void)SetPosition :(int)x withParam1:(int)y
{
	if (([ho getX] != x) ||  ([ho getY] != y))
	{
		[ho setX:x];//rdPtr->rHo.hoX = (short)p1;
		[ho setY:y];//rdPtr->rHo.hoY = (short)p2;
		
		// Update tooltip position
		//UpdateToolTipRect(rdPtr);
		
		// Container ? must update coordinates of contained objects
		if ((rData->dwFlags & FLAG_CONTAINER) != 0 )
		{
			CRun* rhPtr = ho->hoAdRunHeader;
			// Get FrameData
			KcBoxACFrameData* pData = (KcBoxACFrameData*)[rhPtr getStorage:ho->hoIdentifier];
			if (pData != nil)
			{
				[pData UpdateContainedPos];// = new CFrameData();
			}
		}
		[ho redraw];
	}
}

-(void)Enable
{
	if ((rData->dwFlags & FLAG_DISABLED ) != 0)
	{
		rData->dwFlags &= ~FLAG_DISABLED;
		[ho redraw];
	}
}
-(void)Disable
{
	if ((rData->dwFlags & FLAG_DISABLED ) == 0)
	{
		rData->dwFlags |= FLAG_DISABLED;
		[ho redraw];
	}	
}

-(void)Check
{
	if ((rData->dwFlags & FLAG_CHECKED ) == 0)
	{
		rData->dwFlags |= FLAG_CHECKED;
		[ho redraw];
	}
}

-(void)Uncheck
{
	if ((rData->dwFlags & FLAG_CHECKED ) != 0)
	{
		rData->dwFlags &= ~FLAG_CHECKED;
		[ho redraw];
	}
}
-(void)SetFillColor_None
{
	if (rData->fillColor != COLOR_NONE )
	{
		rData->fillColor = COLOR_NONE;
		[ho redraw];
	}
}
-(void)SetFillColor_3DDKSHADOW
{
	if (rData->fillColor != 21)
	{
		rData->fillColor = 21;
		[ho redraw];
	}
}
-(void)SetFillColor_3DFACE
{
	if (rData->fillColor != 15)
	{
		rData->fillColor = 15;
		[ho redraw];
	}
}
-(void)SetFillColor_3DHIGHLIGHT
{
	if (rData->fillColor != 20)
	{
		rData->fillColor = 20;
		[ho redraw];
	}
}
-(void)SetFillColor_3DLIGHT
{
	if (rData->fillColor != 22)
	{
		rData->fillColor = 22;
		[ho redraw];
	}
}
-(void)SetFillColor_3DSHADOW
{
	if (rData->fillColor != 16)
	{
		rData->fillColor = 16;
		[ho redraw];
	}
}
-(void)SetFillColor_ACTIVECAPTION
{
	if (rData->fillColor != 2)
	{
		rData->fillColor = 2;
		[ho redraw];
	}
}
-(void)SetFillColor_APPWORKSPACE
{
	if (rData->fillColor != 12)
	{
		rData->fillColor = 12;
		[ho redraw];
	}
}
-(void)SetFillColor_DESKTOP
{
	if (rData->fillColor != 1)
	{
		rData->fillColor = 1;
		[ho redraw];
	}
}
-(void)SetFillColor_HIGHLIGHT
{
	if (rData->fillColor != 13)
	{
		rData->fillColor = 13;
		[ho redraw];
	}
}
-(void)SetFillColor_INACTIVECAPTION
{
	if (rData->fillColor != 3)
	{
		rData->fillColor = 3;
		[ho redraw];
	}
}
-(void)SetFillColor_INFOBK
{
	if (rData->fillColor != 24)
	{
		rData->fillColor = 24;
		[ho redraw];
	}
}
-(void)SetFillColor_MENU
{
	if (rData->fillColor != 4)
	{
		rData->fillColor = 4;
		[ho redraw];
	}
}
-(void)SetFillColor_SCROLLBAR
{
	if (rData->fillColor != 0)
	{
		rData->fillColor = 0;
		[ho redraw];
	}
}
-(void)SetFillColor_WINDOW
{
	if (rData->fillColor != 5)
	{
		rData->fillColor = 5;
		[ho redraw];
	}
}
-(void)SetFillColor_WINDOWFRAME
{
	if (rData->fillColor != 6)
	{
		rData->fillColor = 6;
		[ho redraw];
	}
}
-(void)SetFillColor_Other :(int)c
{
	if (( c & PARAMFLAG_SYSTEMCOLOR ) != 0)
	{
		c &= 0xFFFF;
	}
	else
	{
		c |= COLORFLAG_RGB;
	}
	if (rData->fillColor != c)
	{
		rData->fillColor = c;
		[ho redraw];
	}
}

-(void)SetB1Color_None
{
	if (rData->borderColor1 != COLOR_NONE )
	{
		rData->borderColor1 = COLOR_NONE;
		[ho redraw];
	}
}
-(void)SetB1Color_3DDKSHADOW
{
	if (rData->borderColor1 != 21)
	{
		rData->borderColor1 = 21;
		[ho redraw];
	}
}
-(void)SetB1Color_3DFACE
{
	if (rData->borderColor1 != 15)
	{
		rData->borderColor1 = 15;
		[ho redraw];
	}
}
-(void)SetB1Color_3DHIGHLIGHT
{
	if (rData->borderColor1 != 20)
	{
		rData->borderColor1 = 20;
		[ho redraw];
	}
}
-(void)SetB1Color_3DLIGHT
{
	if (rData->borderColor1 != 22)
	{
		rData->borderColor1 = 22;
		[ho redraw];
	}
}
-(void)SetB1Color_3DSHADOW
{
	if (rData->borderColor1 != 16)
	{
		rData->borderColor1 = 16;
		[ho redraw];
	}
}
-(void)SetB1Color_ACTIVEBORDER
{
	if (rData->borderColor1 != 10)
	{
		rData->borderColor1 = 10;
		[ho redraw];
	}
}
-(void)SetB1Color_INACTIVEBORDER
{
	if (rData->borderColor1 != 11)
	{
		rData->borderColor1 = 11;
		[ho redraw];
	}
}
-(void)SetB1Color_WINDOWFRAME
{
	if (rData->borderColor1 != 6)
	{
		rData->borderColor1 = 6;
		[ho redraw];
	}
}
-(void)SetB1Color_Other :(int)c
{
	if (( c & PARAMFLAG_SYSTEMCOLOR ) != 0)
	{
		c &= 0xFFFF;
	}
	else
	{
		c |= COLORFLAG_RGB;
	}
	if (rData->borderColor1 != c)
	{
		rData->borderColor1 = c;
		[ho redraw];
	}
}

-(void)SetB2Color_None
{
	if (rData->borderColor2 != COLOR_NONE )
	{
		rData->borderColor2 = COLOR_NONE;
		[ho redraw];
	}
}
-(void)SetB2Color_3DDKSHADOW
{
	if (rData->borderColor2 != 21)
	{
		rData->borderColor2 = 21;
		[ho redraw];
	}
}
-(void)SetB2Color_3DFACE
{
	if (rData->borderColor2 != 15)
	{
		rData->borderColor2 = 15;
		[ho redraw];
	}
}
-(void)SetB2Color_3DHIGHLIGHT
{
	if (rData->borderColor2 != 20)
	{
		rData->borderColor2 = 20;
		[ho redraw];
	}
}
-(void)SetB2Color_3DLIGHT
{
	if (rData->borderColor2 != 22)
	{
		rData->borderColor2 = 22;
		[ho redraw];
	}
}
-(void)SetB2Color_3DSHADOW
{
	if (rData->borderColor2 != 16)
	{
		rData->borderColor2 = 16;
		[ho redraw];
	}
}
-(void)SetB2Color_ACTIVEBORDER
{
	if (rData->borderColor2 != 10)
	{
		rData->borderColor2 = 10;
		[ho redraw];
	}
}
-(void)SetB2Color_INACTIVEBORDER
{
	if (rData->borderColor2 != 11)
	{
		rData->borderColor2 = 11;
		[ho redraw];
	}
}
-(void)SetB2Color_WINDOWFRAME
{
	if (rData->borderColor2 != 6)
	{
		rData->borderColor2 = 6;
		[ho redraw];
	}
}
-(void)SetB2Color_Other :(int)c
{
	if (( c & PARAMFLAG_SYSTEMCOLOR ) != 0)
	{
		c &= 0xFFFF;
	}
	else
	{
		c |= COLORFLAG_RGB;
	}
	if (rData->borderColor2 != c)
	{
		rData->borderColor2 = c;
		[ho redraw];
	}
}

-(void)SetTxtColor_None
{
	if (rData->textColor != COLOR_NONE )
	{
		rData->textColor = COLOR_NONE;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_3DHIGHLIGHT
{
	if (rData->textColor != 20 )
	{
		rData->textColor = 20;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_3DSHADOW
{
	if (rData->textColor != 16)
	{
		rData->textColor = 16;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_BTNTEXT
{
	if (rData->textColor != 18)
	{
		rData->textColor = 18;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_CAPTIONTEXT
{
	if (rData->textColor != 9)
	{
		rData->textColor = 9;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_GRAYTEXT
{
	if (rData->textColor != 17)
	{
		rData->textColor = 17;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_HIGHLIGHTTEXT
{
	if (rData->textColor != 14)
	{
		rData->textColor = 14;
		[ho redraw];
	}
}
-(void)SetTxtColor_INACTIVECAPTIONTEXT
{
	if (rData->textColor != 19)
	{
		rData->textColor = 19;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_INFOTEXT
{
	if (rData->textColor != 23)
	{
		rData->textColor = 23;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_MENUTEXT
{
	if (rData->textColor != 7)
	{
		rData->textColor = 7;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_WINDOWTEXT
{
	if (rData->textColor != 8)
	{
		rData->textColor = 8;
		[ho redraw];
	}
	updated = YES;
}
-(void)SetTxtColor_Other :(int)c
{
	if (( c & PARAMFLAG_SYSTEMCOLOR ) != 0)
	{
		c &= 0xFFFF;
	}
	else
	{
		c |= COLORFLAG_RGB;
	}
	if (rData->textColor != c)
	{
		rData->textColor = c;
		[ho redraw];
	}
	updated = YES;
}

-(void)SetHyperlinkColor_None
{
	if (rData1->dwUnderlinedColor != COLOR_NONE )
	{
		rData1->dwUnderlinedColor = COLOR_NONE;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_3DHIGHLIGHT
{
	if (rData1->dwUnderlinedColor != 20 )
	{
		rData1->dwUnderlinedColor = 20;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_3DSHADOW
{
	if (rData1->dwUnderlinedColor != 16)
	{
		rData1->dwUnderlinedColor = 16;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_BTNTEXT
{
	if (rData1->dwUnderlinedColor != 18)
	{
		rData1->dwUnderlinedColor = 18;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_CAPTIONTEXT
{
	if (rData1->dwUnderlinedColor != 9)
	{
		rData1->dwUnderlinedColor = 9;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_GRAYTEXT
{
	if (rData1->dwUnderlinedColor != 17)
	{
		rData1->dwUnderlinedColor = 17;
		[ho redraw];
	}
}

-(void)SetHyperlinkColor_HIGHLIGHTTEXT
{
	if (rData1->dwUnderlinedColor != 14)
	{
		rData1->dwUnderlinedColor = 14;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_INACTIVECAPTIONTEXT
{
	if (rData1->dwUnderlinedColor != 19)
	{
		rData1->dwUnderlinedColor = 19;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_INFOTEXT
{
	if (rData1->dwUnderlinedColor != 23)
	{
		rData1->dwUnderlinedColor = 23;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_MENUTEXT
{
	if (rData1->dwUnderlinedColor != 7)
	{
		rData1->dwUnderlinedColor = 7;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_WINDOWTEXT
{
	if (rData1->dwUnderlinedColor != 8)
	{
		rData1->dwUnderlinedColor = 8;
		[ho redraw];
	}
}
-(void)SetHyperlinkColor_Other :(int)c
{
	if (( c & PARAMFLAG_SYSTEMCOLOR ) != 0)
	{
		c &= 0xFFFF;
	}
	else
	{
		c |= COLORFLAG_RGB;
	}
	if (rData1->dwUnderlinedColor != c)
	{
		rData1->dwUnderlinedColor = c;
		[ho redraw];
	}
}

-(void)SetText:(NSString*)s
{
	[pText release];
	pText=[[NSString alloc] initWithString:s];
	updated = YES;
	[ho redraw];
}
-(void)SetToolTipText:(NSString*)s
{
}

-(void)Undock
{
	if ((dwRtFlags & DOCK_FLAGS )!= 0)
	{
		dwRtFlags &= ~DOCK_FLAGS;
	}
}
-(void)DockLeft
{
	if ((dwRtFlags & DOCK_LEFT )== 0)
	{
		dwRtFlags |= DOCK_LEFT;
		[ho reHandle];
	}
}
-(void)DockRight
{
	if ((dwRtFlags & DOCK_RIGHT )== 0)
	{
		dwRtFlags |= DOCK_RIGHT;
		[ho reHandle];
	}
}
-(void)DockTop
{
	if ((dwRtFlags & DOCK_TOP)== 0)
	{
		dwRtFlags |= DOCK_TOP;
		[ho reHandle];
	}
}
-(void)DockBottom
{
	if ((dwRtFlags & DOCK_BOTTOM)== 0)
	{
		dwRtFlags |= DOCK_BOTTOM;
		[ho reHandle];
	}
}
-(void)ShowImage
{
	if ((rData->dwFlags & FLAG_HIDEIMAGE ) != 0)
	{
		rData->dwFlags &= ~FLAG_HIDEIMAGE;
		[ho redraw];
	}
}
-(void)HideImage
{
	if ((rData->dwFlags & FLAG_HIDEIMAGE ) == 0)
	{
		rData->dwFlags |= FLAG_HIDEIMAGE;
		[ho redraw];
	}
}
-(void)ResetClickState
{
	rClickCount = -1;
}
-(void)AttachMenuCmd
{
}




// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_COLOR_BACKGROUND:
			return [self ExpColorBackground];
		case EXP_COLOR_BORDER1:
			return [self ExpColorBorder1];
		case EXP_COLOR_BORDER2:
			return [self ExpColorBorder2];
		case EXP_COLOR_TEXT:
			return [self ExpColorText];
		case EXP_COLOR_HYPERLINK:
			return [self ExpColorHyperlink];
		case EXP_COLOR_3DDKSHADOW:
			return [self ExpColor_3DDKSHADOW];
		case EXP_COLOR_3DFACE:
			return [self ExpColor_3DFACE];
		case EXP_COLOR_3DHILIGHT:
			return [self ExpColor_3DHILIGHT];
		case EXP_COLOR_3DLIGHT:
			return [self ExpColor_3DLIGHT];
		case EXP_COLOR_3DSHADOW:
			return [self ExpColor_3DSHADOW];
		case EXP_COLOR_ACTIVEBORDER:
			return [self ExpColor_ACTIVEBORDER];
		case EXP_COLOR_ACTIVECAPTION:
			return [self ExpColor_ACTIVECAPTION];
		case EXP_COLOR_APPWORKSPACE:
			return [self ExpColor_APPWORKSPACE];
		case EXP_COLOR_DESKTOP:
			return [self ExpColor_DESKTOP];
		case EXP_COLOR_BTNTEXT:
			return [self ExpColor_BTNTEXT];
		case EXP_COLOR_CAPTIONTEXT:
			return [self ExpColor_CAPTIONTEXT];
		case EXP_COLOR_GRAYTEXT:
			return [self ExpColor_GRAYTEXT];
		case EXP_COLOR_HIGHLIGHT:
			return [self ExpColor_HIGHLIGHT];
		case EXP_COLOR_HIGHLIGHTTEXT:
			return [self ExpColor_HIGHLIGHTTEXT];
		case EXP_COLOR_INACTIVEBORDER:
			return [self ExpColor_INACTIVEBORDER];
		case EXP_COLOR_INACTIVECAPTION:
			return [self ExpColor_INACTIVECAPTION];
		case EXP_COLOR_INACTIVECAPTIONTEXT:
			return [self ExpColor_INACTIVECAPTIONTEXT];
		case EXP_COLOR_INFOBK:
			return [self ExpColor_INFOBK];
		case EXP_COLOR_INFOTEXT:
			return [self ExpColor_INFOTEXT];
		case EXP_COLOR_MENU:
			return [self ExpColor_MENU];
		case EXP_COLOR_MENUTEXT:
			return [self ExpColor_MENUTEXT];
		case EXP_COLOR_SCROLLBAR:
			return [self ExpColor_SCROLLBAR];
		case EXP_COLOR_WINDOW:
			return [self ExpColor_WINDOW];
		case EXP_COLOR_WINDOWFRAME:
			return [self ExpColor_WINDOWFRAME];
		case EXP_COLOR_WINDOWTEXT:
			return [self ExpColor_WINDOWTEXT];
		case EXP_GETTEXT:
			return [self ExpGetText];
		case EXP_GETTOOLTIPTEXT:
			return [self ExpGetToolTipText];
		case EXP_GETWIDTH:
			return [self ExpGetWidth];
		case EXP_GETHEIGHT:
			return [self ExpGetHeight];
		case EXP_GETX:
			return [self ExpGetX];
		case EXP_GETY:
			return [self ExpGetY];
		case EXP_SYSTORGB:
			return [self ExpSysToRGB];
	}
	return [rh getTempValue:0];
}

-(CValue*)ExpColorBackground
{
	int clr = rData->fillColor;
	if ((clr &  COLORFLAG_RGB )!= 0)
	{
		clr &= 0xFFFFFF;
	}
	else
	{
		clr |= PARAMFLAG_SYSTEMCOLOR;
	}
	return [rh getTempValue:(int)clr];
}

-(CValue*)ExpColorBorder1
{
	int clr = rData->borderColor1;
	if ((clr &  COLORFLAG_RGB )!= 0)
	{
		clr &= 0xFFFFFF;
	}
	else
	{
		clr |= PARAMFLAG_SYSTEMCOLOR;
	}
	return [rh getTempValue:(int)clr];
}

-(CValue*)ExpColorBorder2
{
	int clr = rData->borderColor2;
	if ((clr &  COLORFLAG_RGB )!= 0)
	{
		clr &= 0xFFFFFF;
	}
	else
	{
		clr |= PARAMFLAG_SYSTEMCOLOR;
	}
	return [rh getTempValue:(int)clr];
}

-(CValue*)ExpColorText
{
	int clr = rData->textColor;
	if ((clr &  COLORFLAG_RGB )!= 0)
	{
		clr &= 0xFFFFFF;
	}
	else
	{
		clr |= PARAMFLAG_SYSTEMCOLOR;
	}
	return [rh getTempValue:(int)clr];
}

-(CValue*)ExpColorHyperlink
{
	int clr = rData1->dwUnderlinedColor;
	if ((clr &  COLORFLAG_RGB )!= 0)
	{
		clr &= 0xFFFFFF;
	}
	else
	{
		clr |= PARAMFLAG_SYSTEMCOLOR;
	}
	return [rh getTempValue:(int)clr];
}

-(CValue*)ExpColor_3DDKSHADOW
{
	return [rh getTempValue:21 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_3DFACE
{
	return [rh getTempValue:15 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_3DHILIGHT
{
	return [rh getTempValue:20 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_3DLIGHT
{
	return [rh getTempValue:22 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_3DSHADOW
{
	return [rh getTempValue:16 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_ACTIVEBORDER
{
	return [rh getTempValue:10 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_ACTIVECAPTION
{
	return [rh getTempValue:2 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_APPWORKSPACE
{
	return [rh getTempValue:12 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_DESKTOP
{
	return [rh getTempValue:1 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_BTNTEXT
{
	return [rh getTempValue:18 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_CAPTIONTEXT
{
	return [rh getTempValue:9 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_GRAYTEXT
{
	return [rh getTempValue:17 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_HIGHLIGHT
{
	return [rh getTempValue:13 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_HIGHLIGHTTEXT
{
	return [rh getTempValue:14 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_INACTIVEBORDER
{
	return [rh getTempValue:11 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_INACTIVECAPTION
{
	return [rh getTempValue:3 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_INACTIVECAPTIONTEXT
{
	return [rh getTempValue:19 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_INFOBK
{
	return [rh getTempValue:24 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_INFOTEXT
{
	return [rh getTempValue:23 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_MENU
{
	return [rh getTempValue:4 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_MENUTEXT
{
	return [rh getTempValue:7 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_SCROLLBAR
{
	return [rh getTempValue:0 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_WINDOW
{
	return [rh getTempValue:5 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_WINDOWFRAME
{
	return [rh getTempValue:6 | PARAMFLAG_SYSTEMCOLOR];
}
-(CValue*)ExpColor_WINDOWTEXT
{
	return [rh getTempValue:8 | PARAMFLAG_SYSTEMCOLOR];
}

-(CValue*)ExpGetText
{
	return [rh getTempString:pText];
}
-(CValue*)ExpGetToolTipText
{
	return [rh getTempString:@""];
}
-(CValue*)ExpGetWidth
{
	return [rh getTempValue:[ho getWidth]];
}
-(CValue*)ExpGetHeight
{
	return [rh getTempValue:[ho getHeight]];
}
-(CValue*)ExpGetX
{
	return [rh getTempValue:[ho getX]];
}
-(CValue*)ExpGetY
{
	return [rh getTempValue:[ho getY]];
}

-(CValue*)ExpSysToRGB
{
	int rgb;
	int paramColor = [[ho getExpParam] getInt];//DWORD)CNC_GetFirstExpressionParameter(rdPtr, param1, TYPE_INT);
	
	if ((paramColor & PARAMFLAG_SYSTEMCOLOR )!=0)
	{
		int sc = paramColor & 0xFFFF;
		rgb = [self myGetSysColor:sc];
	}
	else
	{
		rgb = paramColor & 0xFFFFFF;
	}
	int r = getR(rgb);
	int g = getG(rgb);
	int b = getB(rgb);
	return [rh getTempValue:b*65536 + g*256 + r];
}

@end


// CLASSES ANNEXES ////////////////////////////////////////////////////////////////////////////
@implementation KcBoxACData
@end

@implementation KcBoxACData1
@end

@implementation KcBoxACFrameData

-(void)dealloc
{
	if (pObjects!=nil)
	{
		[pObjects release];
	}
	if (pContainers!=nil)
	{
		[pContainers release];
	}
	if (pButtons!=nil)
	{
		[pButtons release];
	}
	[super dealloc];
}
-(BOOL)IsEmpty
{
	if (pObjects != nil)
	{
		for (int i = 0; i < [pObjects size]; i++)
		{
			if ([pObjects get:i] != nil)
			{
				return NO;
			}
		}
	}
	if (pContainers != nil)
	{
		for (int i = 0; i < [pContainers size]; i++)
		{
			if ([pContainers get:i] != nil)
			{
				return NO;
			}
		}
	}
	return YES;
}

-(int)AddObjAddr:(int)t withParam1:(CRunKcBoxA*)reObject
{
	if (t == TYPE_OBJECT)
	{
		// 1st allocation
		if (pObjects == nil)
		{
			pObjects = [[CArrayList alloc] init];
			[pObjects add:reObject];
			//pObjects.set(0, reObject);
			return 0;
		}
		// Search for free place
		for (int i=0; i < [pObjects size]; i++)
		{
			if ([pObjects get:i] == nil )
			{
				[pObjects set:i object:reObject];
				return i;
			}
		}
		// Reallocation
		[pObjects add:reObject];
		return [pObjects size] - 1;
	}
	if (t ==TYPE_CONTAINER)
	{
		if (pContainers == nil)
		{
			pContainers = [[CArrayList alloc] init];
			[pContainers add:reObject];
			return 0;
		}
		// Search for free place
		for (int i=0; i < [pContainers size]; i++)
		{
			if ([pContainers get:i] == nil )
			{
				[pContainers set:i object:reObject];
				return i;
			}
		}
		// Reallocation
		[pContainers add:reObject];
		return [pContainers size] - 1;
	}
	if (t == TYPE_BUTTON)
	{
		if (pButtons == nil)
		{
			pButtons = [[CArrayList alloc] init];
			[pButtons add:reObject];
			return 0;
		}
		// Search for free place
		for (int i=0; i < [pButtons size]; i++)
		{
			if ([pButtons get:i] == nil )
			{
				[pButtons set:i object:reObject];
				return i;
			}
		}
		// Reallocation
		[pButtons add:reObject];
		return [pButtons size] - 1;
	}
	return 0; //won't happen
}

// Remove object from list
-(void)RemoveObjAddr:(int)t withParam1:(CRunKcBoxA*)reObject
{
	if (t == TYPE_OBJECT)
	{
		if (pObjects != nil)
		{
			NSInteger i = [pObjects indexOf:reObject];
			if (i != -1)
			{
				[pObjects set:i object:nil];
			}                
		}
	}
	if (t == TYPE_CONTAINER)
	{
		if (pContainers != nil)
		{
			NSInteger i = [pContainers indexOf:reObject];
			if (i != -1)
			{
				[pContainers set:i object:nil];
			} 
		}
	}
	if (t == TYPE_BUTTON)
	{
		if (pButtons != nil)
		{
			NSInteger i = [pButtons indexOf:reObject];
			if (i != -1)
			{
				[pButtons set:i object:nil];
			} 
		}
	}	
}

// Add objects
-(int)AddContainer:(CRunKcBoxA*)re
{
	return [self AddObjAddr:TYPE_CONTAINER  withParam1:re];
}
-(int)AddObject:(CRunKcBoxA*)re
{
	return [self AddObjAddr:TYPE_OBJECT  withParam1:re];
}
-(int)AddButton:(CRunKcBoxA*)re
{
	return [self AddObjAddr:TYPE_BUTTON  withParam1:re];
}
-(void)RemoveContainer:(CRunKcBoxA*)re
{
	[self RemoveObjAddr:TYPE_CONTAINER  withParam1:re];
}
-(void)RemoveObjectFromList:(CRunKcBoxA*)re
{
	[self RemoveObjAddr:TYPE_OBJECT  withParam1:re];
}
-(void)RemoveButton:(CRunKcBoxA*)re
{
	[self RemoveObjAddr:TYPE_BUTTON  withParam1:re];
}

// Get objects
-(int)GetContainer:(CRunKcBoxA*)re
{
	int left = [re->ho getX];
	int top = [re->ho getY];
	int right = [re->ho getX] + [re->ho getWidth];
	int bottom = [re->ho getY] + [re->ho getHeight];
	
	if (pContainers != nil)
	{
		for (int i=0; i < [pContainers size]; i++)
		{
			if (([pContainers get:i] != nil) && ([pContainers get:i] != re))
			{
				CRunKcBoxA* reThisOne = (CRunKcBoxA*)[pContainers get:i];
				if ((left >= [reThisOne->ho getX]) && (right <= [reThisOne->ho getX] + [reThisOne->ho getWidth]) && (top >= [reThisOne->ho getY]) && (bottom <= [reThisOne->ho getY] + [reThisOne->ho getHeight]) )
				{
					return i;
				}
			}
		} 
	}
	return -1;
}
-(int)GetObjectFromList:(int)x withParam1:(int)y
{
	int r = -1;
	if (pObjects != nil)
	{
		for (int i = [pObjects size] - 1; i >= 0; i--)
		{
			if ([pObjects get:i] != nil)
			{
				CRunKcBoxA* reThisOne = (CRunKcBoxA*)[pObjects get:i];
				if ((x >= [reThisOne->ho getX]) && (x <= ([reThisOne->ho getX] + [reThisOne->ho getWidth])) && (y >= ([reThisOne->ho getY])) && (y <= ([reThisOne->ho getY] + [reThisOne->ho getHeight])))
				{
					r = i;
					break;
				}
			}
		}
	}
	return r;
}

-(void)UpdateContainedPos
{
	if (pObjects != nil)
	{
		for (int i=0; i < [pObjects size]; i++)
		{
			if ([pObjects get:i] != nil)
			{
				CRunKcBoxA* reThisOne = (CRunKcBoxA*)[pObjects get:i];
				// Contained ? must update coordinates
				if ((reThisOne->rData->dwFlags & FLAG_CONTAINED) != 0)
				{
					// Not yet a container? search Medor, search!
					if (reThisOne->rContNum == -1 )
					{
						reThisOne->rContNum = [self GetContainer:reThisOne];
						if (reThisOne->rContNum != -1 )
						{
							CRunKcBoxA* rdPtrCont = (CRunKcBoxA*)[pContainers get:reThisOne->rContNum];
							reThisOne->rContDx = (short)([reThisOne->ho getX] - [rdPtrCont->ho getX]);
							reThisOne->rContDy = (short)([reThisOne->ho getY] - [rdPtrCont->ho getY]);
						}
					}
					
					if ((reThisOne->rContNum != -1) && (reThisOne->rContNum < [pContainers size] ))
					{
						CRunKcBoxA* rdPtrCont = (CRunKcBoxA*)[pContainers get:reThisOne->rContNum];
						if (rdPtrCont != nil )
						{
							int newX = [rdPtrCont->ho getX] + reThisOne->rContDx;
							int newY = [rdPtrCont->ho getY] + reThisOne->rContDy;
							if ((newX != [reThisOne->ho getX]) || (newY != [reThisOne->ho getY]))
							{
								[reThisOne->ho setX:newX];
								[reThisOne->ho setY:newY];
								// Update tooltip position
								//UpdateToolTipRect(reThisOne);
								[reThisOne->ho redraw];
							}
						}
					}
				}
			}
		}
	}
}


@end

