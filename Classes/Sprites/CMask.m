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
// CMASK : un masque
//
//----------------------------------------------------------------------------------
#import "CMask.h"
#import "CServices.h"
#import "CColMask.h"
#import "CImage.h"

static short lMask[] =
{
(short) 0xFFFF, // 1111111111111111B
(short) 0x7FFF, // 0111111111111111B
(short) 0x3FFF, // 0011111111111111B
(short) 0x1FFF, // 0001111111111111B
(short) 0x0FFF, // 0000111111111111B
(short) 0x07FF, // 0000011111111111B
(short) 0x03FF, // 0000001111111111B
(short) 0x01FF, // 0000000111111111B
(short) 0x00FF, // 0000000011111111B
(short) 0x007F, // 0000000001111111B
(short) 0x003F, // 0000000000111111B
(short) 0x001F, // 0000000000011111B
(short) 0x000F, // 0000000000001111B
(short) 0x0007, // 0000000000000111B
(short) 0x0003, // 0000000000000011B
(short) 0x0001	// 0000000000000001B
};
static short rMask[] =
{
(short) 0x0000, // 1000000000000000B0
(short) 0x8000, // 1000000000000000B0
(short) 0xC000, // 1100000000000000B1
(short) 0xE000, // 1110000000000000B2
(short) 0xF000, // 1111000000000000B3
(short) 0xF800, // 1111100000000000B4
(short) 0xFC00, // 1111110000000000B5
(short) 0xFE00, // 1111111000000000B6
(short) 0xFF00, // 1111111100000000B7
(short) 0xFF80, // 1111111110000000B8
(short) 0xFFC0, // 1111111111000000B9
(short) 0xFFE0, // 1111111111100000B10
(short) 0xFFF0, // 1111111111110000B11
(short) 0xFFF8, // 1111111111111000B12
(short) 0xFFFC, // 1111111111111100B13
(short) 0xFFFE, // 1111111111111110B14
(short) 0xFFFF	// 1111111111111111B15
};

@implementation CMask

-(void)dealloc
{
	if (mask!=nil)
	{
		free(mask);
	}
	[super dealloc];
}
-(void)createMask:(CImage*)img withFlags:(int)nFlags
{
	width = img->width;
	height = img->height;

	int maskWidth = ((width + 15) & 0xFFFFFFF0) / 16;
	mask = (short*)calloc(maskWidth * height + 1, sizeof(short));
	lineWidth = maskWidth;
	int x, y;
	
	int s;
	short bm;
	//unsigned int* data=img->data;
	if ((nFlags & GCMF_PLATFORM) == 0)
	{
		for (y = 0; y < height; y++)
		{
			for (x = 0; x < width; x++)
			{
				s = (y * maskWidth) + (x & 0xFFFFFFF0) / 16;
				//if ((data[y * width + x] & 0xFF000000) != 0)
				if(pixelIsSolid(img, x, y))
				{
					bm = (short) (((int)0x8000) >> (x % 16));
					mask[s] |= bm;
				}
			}
		}
	}
	else
	{
		int endY;
		for (x = 0; x < width; x++)
		{
			for (y = 0; y < height; y++)
			{
				//if ((data[y * width + x] & 0xFF000000) != 0)
				if(pixelIsSolid(img, x, y))
				{
					break;
				}
			}
			if (y < height)
			{
				endY = MIN(height, y + HEIGHT_PLATFORM);
				bm = (short) (((int)0x8000) >> (x & 15));
				for (; y < endY; y++)
				{
					//if ((data[y * width + x] & 0xFF000000) != 0)
					if(pixelIsSolid(img, x, y))
					{
						s = (y * maskWidth) + x / 16;
						mask[s] |= bm;
					}
				}
			}
		}
	}
}
-(void)rotateRect:(int*)pWidth withPHeight:(int*)pHeight andPHX:(int*)pHX andPHY:(int*)pHY andAngle:(float)fAngle
{
	float x, y;	// , xo, yo;
	float cosa, sina;
	
	if ( fAngle == 90.0 )
	{
		cosa = 0.0;
		sina = 1.0;
	}
	else if ( fAngle == 180.0 )
	{
		cosa = -1.0;
		sina = 0.0;
	}
	else if ( fAngle == 270.0 )
	{
		cosa = 0.0;
		sina = -1.0;
	}
	else
	{
		float arad = fAngle * 0.017453292f;     // _PI / 180.0;
		cosa = cosf(arad);
		sina = sinf(arad);
	}
	
	// Rotate top-left point
	int topLeftX, topLeftY;
	
	// Ditto, optimized
	double nhxcos;
	double nhxsin;
	double nhycos;
	double nhysin;
	if ( pHX == nil )
	{
		nhxcos = nhxsin = nhycos = nhysin = 0.0;
		topLeftX = topLeftY = 0;
	}
	else
	{
		nhxcos = -*pHX * cosa;
		nhxsin = -*pHX * sina;
		nhycos = -*pHY * cosa;
		nhysin = -*pHY * sina;
		topLeftX = (int)(nhxcos + nhysin);
		topLeftY = (int)(nhycos - nhxsin);
	}
	
	// Rotate top-right point
	int topRightX, topRightY;
	
	// Ditto, optimized
	if ( pHX == nil )
		x = (float)*pWidth;
	else
		x = (float)(*pWidth - *pHX);
	nhxcos = x * cosa;
	nhxsin = x * sina;
	topRightX = (int)(nhxcos + nhysin);
	topRightY = (int)(nhycos - nhxsin);
	
	// Rotate bottom-right point
	int bottomRightX, bottomRightY;
	
	// Ditto, optimized
	if ( pHX == nil )
		y = (float)*pHeight;
	else
		y = (float)(*pHeight - *pHY);
	nhycos = y * cosa;
	nhysin = y * sina;
	bottomRightX = (int)(nhxcos + nhysin);
	bottomRightY = (int)(nhycos - nhxsin);
	
	// Bottom-left
	int bottomLeftX, bottomLeftY;
	bottomLeftX = topLeftX + bottomRightX - topRightX;
	bottomLeftY = topLeftY + bottomRightY - topRightY;
	
	// Get limits
	int xmin = MIN(topLeftX, MIN(topRightX, MIN(bottomRightX, bottomLeftX)));
	int ymin = MIN(topLeftY, MIN(topRightY, MIN(bottomRightY, bottomLeftY)));
	int xmax = MAX(topLeftX, MAX(topRightX, MAX(bottomRightX, bottomLeftX)));
	int ymax = MAX(topLeftY, MAX(topRightY, MAX(bottomRightY, bottomLeftY)));
	
	// Update hotspot position
	if ( pHX != nil)
	{
		*pHX = -xmin;
		*pHY = -ymin;
	}
	
	// Update rectangle
	*pWidth = xmax - xmin;
	*pHeight = ymax - ymin;
}

-(BOOL)createRotatedMask:(CMask*)pMask withAngle:(float)fAngle andScaleX:(float)fScaleX andScaleY:(float)fScaleY
{
	int x, y;
	
	// Calculate new mask bounding box
	int cx = pMask->width;
	int cy = pMask->height;
	
	int rcRight, rcBottom;
	rcRight = pMask->width * fScaleX;
	rcBottom = pMask->height * fScaleY;
	
	int hsX, hsY;
	hsX = pMask->xSpot * fScaleX;
	hsY = pMask->ySpot * fScaleY;
	[self rotateRect:&rcRight withPHeight:&rcBottom andPHX:&hsX andPHY:&hsY andAngle:fAngle];
	int newCx = rcRight;
	int newCy = rcBottom;
	if ( newCx <= 0 || newCy <= 0 )
		return NO;
	
	// Allocate memory for new mask
	int sMaskWidthWords=pMask->lineWidth;
	int dMaskWidthShorts = ((newCx + 15) & 0xFFFFFFF0) / 16;
	mask = (short*)calloc(dMaskWidthShorts * newCy + 1, sizeof(short));
	lineWidth = dMaskWidthShorts;
	width = newCx;
	height = newCy;
	xSpot = hsX;
	ySpot = hsY;
	
	float alpha = fAngle * 0.017453292f;
	float cosa = cosf(alpha);
	float sina = sinf(alpha);
	
	float fxs = (cx/2.0f) - ((newCx/2.0f) * cosa - (newCy/2.0f) * sina) / fScaleX;
	float fys = (cy/2.0f) - ((newCx/2.0f) * sina + (newCy/2.0f) * cosa) / fScaleY;
	
	short* pbs0 = pMask->mask;
	short* pbd0 = mask;		
	short* pbd1 = pbd0;
	
	int nxs = (int)(fxs * 65536);
	int nys = (int)(fys * 65536);
	int ncosa = (int)((cosa * 65536) / fScaleX);
	int nsina = (int)((sina * 65536) / fScaleY);
	
	int newCxMul16 = newCx/16;
	int newCxMod16 = newCx%16;
	
	int ncosa2=(int)((cosa*65536)/fScaleY);
	int nsina2=(int)((sina*65536)/fScaleX);
	
    int cxs=cx*65536;
    int cys=cy*65536;
    
	short bMask;
	short b;
	for (y=0; y<newCy; y++)
	{
		int txs = nxs;
		int tys = nys;
		short* pbd2 = pbd1;
		int xs, ys;
		
		for (x=0; x<newCxMul16; x++)
		{
			short bd = 0;
			
			// 1
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x8000;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 2
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x4000;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 3
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x2000;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 4
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x1000;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 5
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0800;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 6
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0400;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 7
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0200;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 8
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0100;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 9
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0080;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 10 
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0040;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 11
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0020;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 12
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0010;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 13
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0008;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 14
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0004;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 15
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0002;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			// 16
			if ( txs >= 0 && txs < cxs )
			{
				if ( tys >= 0 && tys < cys )
				{
                    xs = txs / 65536;
                    ys = tys / 65536;
					bMask = (short)(0x8000>>(xs%16));
					b = *(pbs0 + ys * sMaskWidthWords + xs/16);
					if ( b & bMask )
						bd |= 0x0001;
				}
			}
            txs += ncosa;
            tys += nsina;
			
			*(pbd2++) = bd;
		}
		
		if ( newCxMod16 )
		{
			short bdMask = 0x8000;
			short bdbd = 0;
			for (x=0; x<newCxMod16; x++, bdMask=(bdMask>>1)&0x7FFF)
			{				
				if ( txs >= 0 && txs < cxs && tys >= 0 && tys < cys )
				{
                    int bdxs = txs / 65536;
                    int bdys = tys / 65536;
					bMask = (short)(0x8000>>(bdxs%16));
					b = *(pbs0 + bdys * sMaskWidthWords + bdxs/16);
					if ( b & bMask )
						bdbd |= bdMask;
				}
				txs += ncosa;
				tys += nsina;
			}
			*pbd2 = bdbd;
		}
		
		pbd1 += dMaskWidthShorts;
		
		nxs -= nsina2;
		nys += ncosa2;		
	}
	return true;			
}



-(BOOL)testMask:(int)yBase1 withX1:(int)x1 andY1:(int)y1 andMask:(CMask*)pMask2 andYBase:(int)yBase2 andX2:(int)x2 andY2:(int)y2
{
	CMask* pLeft;
	CMask* pRight;
	int x1Left, y1Left, x1Right, y1Right;
	int syLeft, syRight;
	int yBaseLeft, yBaseRight;
	
	if (x1 <= x2)
	{
		pLeft = self;
		pRight = pMask2;
		yBaseLeft = yBase1;
		yBaseRight = yBase2;
		x1Left = x1;
		y1Left = y1;
		x1Right = x2;
		y1Right = y2;
	}
	else
	{
		pLeft = pMask2;
		pRight = self;
		yBaseLeft = yBase2;
		yBaseRight = yBase1;
		x1Left = x2;
		y1Left = y2;
		x1Right = x1;
		y1Right = y1;
	}
	syLeft = pLeft->height - yBaseLeft;
	syRight = pRight->height - yBaseRight;
	
	if (x1Left >= x1Right + pRight->width || x1Left + pLeft->width <= x1Right)
	{
		return NO;
	}
	if (y1Left >= y1Right + syRight || y1Left + syLeft < y1Right)
	{
		return NO;
	}
	
	int deltaX = x1Right - x1Left;
	int offsetX = deltaX / 16;
	int shiftX = deltaX % 16;
	int countX = MIN(x1Left + pLeft->width - x1Right, pRight->width);
	countX = (countX + 15) / 16;
	
	int deltaYLeft, deltaYRight, countY;
	if (y1Left <= y1Right)
	{
		deltaYLeft = y1Right - y1Left + yBaseLeft;
		deltaYRight = yBaseRight;
		countY = MIN(y1Left + syLeft, y1Right + syRight) - y1Right;
	}
	else
	{
		deltaYLeft = yBaseLeft;
		deltaYRight = y1Left - y1Right + yBaseRight;
		countY = MIN(y1Left + syLeft, y1Right + syRight) - y1Left;
	}
	int x, y;
	
	int offsetYLeft, offsetYRight;
	int leftX, middleX;
	short shortX;
	if (shiftX != 0)
	{
		switch (countX)
		{
			case 1:
				for (y = 0; y < countY; y++)
				{
					offsetYLeft = (deltaYLeft + y) * pLeft->lineWidth;
					offsetYRight = (deltaYRight + y) * pRight->lineWidth;
					
					// Premier mot
					leftX = ((int) pLeft->mask[offsetYLeft + offsetX]) << shiftX;
					shortX = (short) leftX;
					if ((shortX & pRight->mask[offsetYRight]) != 0)
					{
						return YES;
					}
					
					if (offsetX * 16 + 16 < pLeft->width)
					{
						middleX = (((int) pLeft->mask[offsetYLeft + offsetX + 1]) & 0x0000FFFF) << shiftX;
						shortX = (short) (middleX >> 16);
						if ((shortX & pRight->mask[offsetYRight]) != 0)
						{
							return YES;
						}
					}
				}
				break;
			case 2:
				for (y = 0; y < countY; y++)
				{
					offsetYLeft = (deltaYLeft + y) * pLeft->lineWidth;
					offsetYRight = (deltaYRight + y) * pRight->lineWidth;
					
					// Premier mot
					leftX = ((int) pLeft->mask[offsetYLeft + offsetX]) << shiftX;
					shortX = (short) leftX;
					if ((shortX & pRight->mask[offsetYRight]) != 0)
					{
						return YES;
					}
					middleX = (((int) pLeft->mask[offsetYLeft + offsetX + 1]) & 0x0000FFFF) << shiftX;
					shortX = (short) (middleX >> 16);
					if ((shortX & pRight->mask[offsetYRight]) != 0)
					{
						return YES;
					}
					
					// Milieu
					shortX = (short) middleX;
					if ((shortX & pRight->mask[offsetYRight + 1]) != 0)
					{
						return YES;
					}
                    if (offsetX+2<pLeft->lineWidth)
                    {
                        middleX = (((int) pLeft->mask[offsetYLeft + offsetX + 2]) & 0x0000FFFF) << shiftX;
                        shortX = (short) (middleX >> 16);
                        if ((shortX & pRight->mask[offsetYRight+1]) != 0)
                        {
                            return YES;
                        }                        
                    }
				}
				break;
			default:
				for (y = 0; y < countY; y++)
				{
					offsetYLeft = (deltaYLeft + y) * pLeft->lineWidth;
					offsetYRight = (deltaYRight + y) * pRight->lineWidth;
					
					// Premier mot
					leftX = ((int) pLeft->mask[offsetYLeft + offsetX]) << shiftX;
					shortX = (short) leftX;
					if ((shortX & pRight->mask[offsetYRight]) != 0)
					{
						return YES;
					}
					
					for (x = 0; x < countX - 1; x++)
					{
						middleX = (((int) pLeft->mask[offsetYLeft + offsetX + x+1]) & 0x0000FFFF) << shiftX;
						shortX = (short) (middleX >> 16);
						if ((shortX & pRight->mask[offsetYRight+x]) != 0)
						{
							return YES;
						}
						
						// Milieu
						shortX = (short) middleX;
						if ((shortX & pRight->mask[offsetYRight + x + 1]) != 0)
						{
							return YES;
						}
					}
                    if (offsetX+x+1<pLeft->lineWidth)
                    {
                        middleX = (((int) pLeft->mask[offsetYLeft + offsetX +x+1]) & 0x0000FFFF) << shiftX;
                        shortX = (short) (middleX >> 16);
                        if ((shortX & pRight->mask[offsetYRight+x]) != 0)
                        {
                            return YES;
                        }                        
                    }
				}
				break;
		}
	}
	else
	{
		for (y = 0; y < countY; y++)
		{
			offsetYLeft = (deltaYLeft + y) * pLeft->lineWidth;
			offsetYRight = (deltaYRight + y) * pRight->lineWidth;
			
			for (x = 0; x < countX; x++)
			{
				leftX = pLeft->mask[offsetYLeft + offsetX + x];
				if ((pRight->mask[offsetYRight + x] & leftX) != 0)
				{
					return YES;
				}
			}
		}
	}
	return NO;
}
-(BOOL)testRect:(int)yBase1 withX:(int)xx andY:(int)yy andWidth:(int)w andHeight:(int)h
{
	int x1 = xx;
	if (x1 < 0)
	{
		w += x1;
		x1 = 0;
	}
	int y1 = yy;
	if (yBase1 != 0 && y1 >= 0)
	{
		y1 = yBase1 + y1;
		h = height - y1;
	}
	if (y1 < 0)
	{
		h += y1;
		y1 = 0;
	}
	int x2 = x1 + w;
	if (x2 > width)
	{
		x2 = width;
	}
	int y2 = y1 + h;
	if (y2 > height)
	{
		y2 = height;
	}
	
	int offset = (y1) * lineWidth;
	int yCount = y2 - y1;
	int xCount = (x2 - x1) / 16 + 1;
	int xOffset = x1 / 16;
	int x, y;
	
	short m;
	int yOffset;
	for (y = 0; y < yCount; y++)
	{
		yOffset = y * lineWidth + offset;
		
		switch (xCount)
		{
			case 1:
				m = (short) (lMask[x1 & 15] & rMask[(x2 - 1) & 15]);
				if ((mask[yOffset + xOffset] & m) != 0)
				{
					return YES;
				}
				break;
			case 2:
				m = lMask[x1 & 15];
				if ((mask[yOffset + xOffset] & m) != 0)
				{
					return YES;
				}
				m = rMask[(x2 - 1) & 15];
				if ((mask[yOffset + xOffset + 1] & m) != 0)
				{
					return YES;
				}
				break;
			default:
				m = lMask[x1 & 15];
				if ((mask[yOffset + xOffset] & m) != 0)
				{
					return YES;
				}
				for (x = 1; x < xCount - 1; x++)
				{
					if (mask[yOffset + xOffset + 1] != 0)
					{
						return YES;
					}
				}
				m = rMask[(x2 - 1) & 15];
				if ((mask[yOffset + xOffset + x] & m) != 0)
				{
					return YES;
				}
				break;
		}
	}
	return NO;
}
-(BOOL)testPoint:(int)x1 withY:(int)y1
{
	if (x1 < 0 || x1 >= width || y1 < 0 || y1 >= height)
	{
		return NO;
	}
	
	int offset = (y1 * lineWidth) + x1 / 16;
	short m = (short) (((int)0x8000) >> (x1 & 15));
	if ((mask[offset] & m) != 0)
	{
		return YES;
	}
	return NO;
}
@end
