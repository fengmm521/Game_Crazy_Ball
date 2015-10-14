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
// CCOLMASK : masque de collision
//
//----------------------------------------------------------------------------------
#import "CColMask.h"
#import "CMask.h"
#import "CServices.h"

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

@implementation CColMask

-(void)dealloc
{
	if (obstacle!=nil)
	{
		free(obstacle);
	}
	if (platform!=nil)
	{
		free(platform);
	}
	[super dealloc];
}

+(CColMask*)create:(int)xx1 withY1:(int)yy1 andX2:(int)xx2 andY2:(int)yy2 andFlags:(int)flags
{
	CColMask* m = [[CColMask alloc] init];
	
	m->mDxScroll = 0;
	m->mDyScroll = 0;
	m->mX1 = m->mX1Clip = xx1;
	m->mY1 = m->mY1Clip = yy1;
	m->mX2 = m->mX2Clip = xx2;
	m->mY2 = m->mY2Clip = yy2;
	m->width = xx2 - xx1;
	m->height = yy2 - yy1;
	m->lineWidth = ((m->width + 15) & ~15) / 16;
	if ((flags & CM_OBSTACLE) != 0)
	{
		m->obstacle = (short*)calloc(m->lineWidth*m->height, sizeof(short));
	}
	if ((flags & CM_PLATFORM) != 0)
	{
		m->platform = (short*)calloc(m->lineWidth*m->height, sizeof(short));
	}
	return m;
}

-(void)setOrigin:(int)dx withDY:(int)dy
{
	mDxScroll = dx;
	mDyScroll = dy;
}

-(void)fill:(short)value
{
	int l = lineWidth * height;
	int s;
	if (obstacle != nil)
	{
		for (s = 0; s < l; s++)
		{
			obstacle[s] = value;
		}
	}
	if (platform != nil)
	{
		for (s = 0; s < l; s++)
		{
			platform[s] = value;
		}
	}
}

-(void)fillRectangle:(int)x1 withY1:(int)y1 andX2:(int)x2 andY2:(int)y2 andValue:(int)val
{
	// Ajouter dx scrolling
	// --------------------
	x1 += mDxScroll;
	x2 += mDxScroll;
	y1 += mDyScroll;
	y2 += mDyScroll;
	
	// Verifier le clipping
	// --------------------
	if (x1 < mX1Clip)
	{
		x1 = mX1Clip;
	}
	if (x2 > mX2Clip)
	{
		x2 = mX2Clip;
	}
	if (x1 >= x2)
	{
		return;
	}
	
	if (y1 < mY1Clip)
	{
		y1 = mY1Clip;
	}
	if (y2 > mY2Clip)
	{
		y2 = mY2Clip;
	}
	if (y1 >= y2)
	{
		return;
	}
	
	x1 -= mX1;
	x2 -= mX1;
	y1 -= mY1;
	y2 -= mY1;
	
	if (obstacle != nil)
	{
		[self fillRect:obstacle withX1:x1 andY1:y1 andX2:x2 andY2:y2 andValue:(val & 1)];
	}
	if (platform != nil)
	{
		[self fillRect:platform withX1:x1 andY1:y1 andX2:x2 andY2:y2 andValue:(val>>1)&1];
	}
}

-(void)fillRect:(short*)mask withX1:(int)x1 andY1:(int)y1 andX2:(int)x2 andY2:(int)y2 andValue:(int)val
{
	int offset = y1 * lineWidth + (x1 & ~15) / 16;
	int h = y2 - y1;
	int w = (x2 / 16) - (x1 / 16) + 1;
	
	int x, y;
	short leftMask;
	short rightMask;
	int yOffset;
	if (w > 1)
	{
		if (val == 0)
		{
			leftMask = (short) ~lMask[x1 & 15];
			rightMask = (short) ~rMask[x2 & 15];
			for (y = 0; y < h; y++)
			{
				yOffset = offset + y * lineWidth;
				
				mask[yOffset] &= leftMask;
				for (x = 1; x < w - 1; x++)
				{
					mask[yOffset + x] = 0;
				}
				if (x == w - 1)
				{
					mask[yOffset + x] &= rightMask;
				}
			}
		}
		else
		{
			leftMask = lMask[x1 & 15];
			rightMask = rMask[x2 & 15];
			for (y = 0; y < h; y++)
			{
				yOffset = offset + y * lineWidth;
				
				mask[yOffset] |= leftMask;
				for (x = 1; x < w - 1; x++)
				{
					mask[yOffset + x] = (short) 0xFFFF;
				}
				if (x == w - 1)
				{
					mask[yOffset + x] |= rightMask;
				}
			}
		}
	}
	else
	{
		if (val == 0)
		{
			leftMask = (short) ~(lMask[x1 & 15] & rMask[x2 & 15]);
			for (y = 0; y < h; y++)
			{
				yOffset = offset + y * lineWidth;
				mask[yOffset] &= leftMask;
			}
		}
		else
		{
			leftMask = (short) (lMask[x1 & 15] & rMask[x2 & 15]);
			for (y = 0; y < h; y++)
			{
				yOffset = offset + y * lineWidth;
				mask[yOffset] |= leftMask;
			}
		}
	}
}

-(void)orMask:(CMask*)mask withX:(int)xx andY:(int)yy andPlane:(int)plans andValue:(int)val
{
	if ((plans & CM_OBSTACLE) != 0)
	{
		if (obstacle != nil)
		{
			[self orIt:obstacle withMask:mask andX:xx andY:yy andFlag:(val & 1)!=0];
		}
	}
	if ((plans & CM_PLATFORM) != 0)
	{
		if (platform != nil)
		{
			[self orIt:platform withMask:mask andX:xx andY:yy andFlag:((val>>1)&1)!=0];
		}
	}
}

-(void)orIt:(short*)dMask withMask:(CMask*)sMask andX:(int)xx andY:(int)yy andFlag:(BOOL)bOr
{
	int x1 = xx;
	int y1 = yy;
//	x1 += mDxScroll;
//	y1 += mDyScroll;
	int x2 = xx + sMask->width;
	int y2 = yy + sMask->height;
	int dx = 0;
	int dy = 0;
	int fx = sMask->width;
	int fy = sMask->height;
	
	// Verifier le clipping
	// --------------------
	if (x1 < mX1Clip)
	{
		dx = mX1Clip - x1;
		if (dx > sMask->width)
		{
			return;
		}
		x1 = mX1Clip;
	}
	if (x2 > mX2Clip)
	{
		fx = sMask->width - (x2 - mX2Clip);
		if (fx < 0)
		{
			return;
		}
		x2 = mX2Clip;
	}
	
	if (y1 < mY1Clip)
	{
		dy = mY1Clip - y1;
		if (dy > sMask->height)
		{
			return;
		}
		y1 = mY1Clip;
	}
	if (y2 > mY2Clip)
	{
		fy = sMask->height - (y2 - mY2Clip);
		if (fy < 0)
		{
			return;
		}
		y2 = mY2Clip;
	}
	
	x1 -= mX1;
	y1 -= mY1;
	x2 -= mX1;
	y2 -= mY1;
	
	int h = fy - dy;
	int w = (fx / 16) - (dx / 16) + 1;
	int x, y;
	short s;
	int offset, mOffset, shiftX, i;
	shiftX = x1 & 15;
	if (shiftX != 0)
	{
		switch (w)
		{
			case 1:
				if (bOr)
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						
						i = sMask->mask[(dy + y) * sMask->lineWidth + dx / 16] & lMask[dx & 15] & rMask[fx & 15] & 0xFFFF;
						dMask[offset] |= (short) (i >> shiftX);
						if (x1 / 16 + 1 < lineWidth)
						{
							dMask[++offset] |= (short) (i << (15 - shiftX));
						}
					}
				}
				else
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						i = sMask->mask[(dy + y) * sMask->lineWidth + dx / 16] & lMask[dx & 15] & rMask[fx & 15] & 0xFFFF;
						dMask[offset] &= ~(short) (i >> shiftX);
						offset++;
						if (x1 / 16 + 1 < lineWidth)
						{
							dMask[++offset] &= ~(short) (i << (15 - shiftX));
						}
					}
				}
				break;
			case 2:
				if (bOr)
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						i = sMask->mask[mOffset] & lMask[dx & 15] & 0xFFFF;
						dMask[offset] |= (short) (i >> shiftX);
						offset++;
						dMask[offset] |= (short) (i << (16 - shiftX));
						
						i = (short) (sMask->mask[mOffset + 1] & rMask[fx & 15]) & 0xFFFF;
						dMask[offset] |= (short) (i >> shiftX);
						if (x1 / 16 + 2 < lineWidth)
						{
							dMask[++offset] |= (short) (i << (16 - shiftX));
						}
					}
				}
				else
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						i = sMask->mask[mOffset] & lMask[dx & 15] & 0xFFFF;
						dMask[offset] &= ~(short) (i >> shiftX);
						offset++;
						dMask[offset] &= ~(short) (i << (16 - shiftX));
						
						i = sMask->mask[mOffset + 1] & rMask[fx & 15] & 0xFFFF;
						dMask[offset] &= ~(short) (i >> shiftX);
						if (x1 / 16 + 2 < lineWidth)
						{
							dMask[++offset] &= ~(short) (i << (16 - shiftX));
						}
					}
				}
				break;
			default:
				if (bOr)
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						// Gauche
						i = sMask->mask[mOffset] & lMask[dx & 15] & 0xFFFF;
						dMask[offset] |= (short) (i >> shiftX);
						offset++;
						dMask[offset] |= (short) (i << (16 - shiftX));
						
						// Milieu
						for (x = 1; x < w - 1; x++)
						{
							i = sMask->mask[mOffset + x] & 0xFFFF;
							dMask[offset] |= (short) (i >> shiftX);
							offset++;
							dMask[offset] |= (short) (i << (16 - shiftX));
						}
						
						// Droite
						i = sMask->mask[mOffset + x] & rMask[fx & 15] & 0xFFFF;
						dMask[offset] |= (short) (i >> shiftX);
						if (x1 / 16 + x < lineWidth)
						{
							dMask[++offset] |= (short) (i << (16 - shiftX));
						}
					}
				}
				else
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						// Gauche
						i = sMask->mask[mOffset] & lMask[dx & 15] & 0xFFFF;
						dMask[offset] &= ~(short) (i >> shiftX);
						offset++;
						dMask[offset] &= ~(short) (i << (16 - shiftX));
						
						// Milieu
						for (x = 1; x < w - 1; x++)
						{
							i = sMask->mask[mOffset + x] & 0xFFFF;
							dMask[offset] &= ~(short) (i >> shiftX);
							offset++;
							dMask[offset] &= ~(short) (i << (16 - shiftX));
						}
						
						// Droite
						i = sMask->mask[mOffset + x] & rMask[fx & 15] & 0xFFFF;
						dMask[offset] &= ~(short) (i >> shiftX);
						if (x1 / 16 + x < lineWidth)
						{
							dMask[++offset] &= ~(short) (i << (16 - shiftX));
						}
					}
				}
				break;
		}
	}
	else
	{
		switch (w)
		{
			case 1:
				if (bOr)
				{
					for (y = 0; y < h; y++)
					{
						s = (short) (sMask->mask[(dy + y) * sMask->lineWidth + dx / 16] & lMask[dx & 15] & rMask[fx & 15]);
						dMask[(y1 + y) * lineWidth + (x1 / 16)] |= s;
					}
				}
				else
				{
					for (y = 0; y < h; y++)
					{
						s = (short) (sMask->mask[(dy + y) * sMask->lineWidth + dx / 16] & lMask[dx & 15] & rMask[fx & 15]);
						dMask[(y1 + y) * lineWidth + (x1 / 16)] &= ~s;
					}
				}
				break;
			case 2:
				if (bOr)
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						s = (short) (sMask->mask[mOffset] & lMask[dx & 15]);
						dMask[offset] |= s;
						s = (short) (sMask->mask[mOffset + 1] & rMask[fx & 15]);
						dMask[offset + 1] |= s;
					}
				}
				else
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						s = (short) (sMask->mask[mOffset] & lMask[dx & 15]);
						dMask[offset] &= ~s;
						s = (short) (sMask->mask[mOffset + 1] & rMask[fx & 15]);
						dMask[offset + 1] &= ~s;
					}
				}
				break;
			default:
				if (bOr)
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						// Gauche
						s = (short) (sMask->mask[mOffset] & lMask[dx & 15]);
						dMask[offset] |= s;
						
						// Milieu
						for (x = 1; x < w - 1; x++)
						{
							s = sMask->mask[mOffset + x];
							dMask[offset + x] |= s;
						}
						if ((fx & 16) > 0)
						{
							// Droite
							s = (short) (sMask->mask[mOffset + x] & rMask[fx & 15]);
							dMask[offset + x] |= s;
						}
					}
				}
				else
				{
					for (y = 0; y < h; y++)
					{
						offset = (y1 + y) * lineWidth + (x1 / 16);
						mOffset = (dy + y) * sMask->lineWidth + dx / 16;
						
						// Gauche
						s = (short) (sMask->mask[mOffset] & lMask[dx & 15]);
						dMask[offset] &= ~s;
						
						// Milieu
						for (x = 1; x < w - 1; x++)
						{
							s = sMask->mask[mOffset + x];
							dMask[offset + x] &= ~s;
						}
						
						if ((fx & 16) > 0)
						{
							// Droite
							s = (short) (sMask->mask[mOffset + x] & rMask[fx & 15]);
							dMask[offset + x] &= ~s;
						}
					}
				}
				break;
		}
	}
}

-(void)orPlatformMask:(CMask*)sMask withX:(int)xx andY:(int)yy
{
	int x1 = xx;
	int y1 = yy;
	x1 += mDxScroll;
	y1 += mDyScroll;
	int x2 = xx + sMask->width;
	int y2 = yy + sMask->height;
	int dx = 0;
	int dy = 0;
	int fx = sMask->width;
	int fy = sMask->height;
	
	// Verifier le clipping
	// --------------------
	if (x1 < mX1Clip)
	{
		dx = mX1Clip - x1;
		if (dx > sMask->width)
		{
			return;
		}
		x1 = mX1Clip;
	}
	if (x2 > mX2Clip)
	{
		fx = sMask->width - (x2 - mX2Clip);
		if (fx < 0)
		{
			return;
		}
		x2 = mX2Clip;
	}
	
	if (y1 < mY1Clip)
	{
		dy = mY1Clip - y1;
		if (dy > sMask->height)
		{
			return;
		}
		y1 = mY1Clip;
	}
	if (y2 > mY2Clip)
	{
		fy = sMask->height - (y2 - mY2Clip);
		if (fy < 0)
		{
			return;
		}
		y2 = mY2Clip;
	}
	
	x1 -= mX1;
	y1 -= mY1;
	x2 -= mX1;
	y2 -= mY1;
	
	int h = fy - dy;
	int w = fx - dx;
	int x, y, yLimit;
	int xSOffset, xDOffset;
	short si, di;
	short* mask = sMask->mask;
	for (x = 0; x < w; x++)
	{
		xSOffset = (dx + x) / 16;
		si = (short) (((int)0x8000) >> ((dx + x) & 15));
		for (y = 0; y < h; y++)
		{
			if ((mask[(dy + y) * sMask->lineWidth + xSOffset] & si) != 0)
			{
				break;
			}
		}
		if (y < h)
		{
			yLimit = MIN(y + HEIGHT_PLATFORM, h);
			xDOffset = (x1 + x) / 16;
			di = (short) (((int)0x8000) >> ((x1 + x) & 15));
			for (; y < yLimit; y++)
			{
				if ((mask[(dy + y) * sMask->lineWidth + xSOffset] & si) != 0)
				{
					platform[(y1 + y) * lineWidth + xDOffset] |= di;
				}
			}
		}
	}
}

//Returns YES if the point is an obstacle, NO if no obstacle
-(BOOL)testPoint:(int)x withY:(int)y andPlane:(int)plans
{
	if (plans == CM_TEST_OBSTACLE)
	{
		if (obstacle != nil)
		{
			if ([self testPt:obstacle withX:x andY:y])
			{
				return YES;
			}
		}
	}
	if (plans == CM_TEST_PLATFORM)
	{
		if (platform != nil)
		{
			if ([self testPt:platform withX:x andY:y])
			{
				return YES;
			}
		}
		else if (obstacle != nil)
		{
			if ([self testPt:obstacle withX:x andY:y])
			{
				return YES;
			}
		}
	}
	return NO;
}

//Returns YES if the point is an obstacle, NO if no obstacle
-(BOOL)testPt:(short*)mask withX:(int)x andY:(int)y
{
	x += mDxScroll;
	y += mDyScroll;
	if (x < mX1Clip || x > mX2Clip)
	{
		return NO;
	}
	if (y < mY1Clip || y > mY2Clip)
	{
		return NO;
	}
	x -= mX1;
	y -= mY1;
	
	int offset = y * lineWidth + x / 16;
	short m = (short) (((int)0x8000) >> (x & 15));
	return (mask[offset] & m) != 0;
}

-(BOOL)testRect:(int)x withY:(int)y andWidth:(int)w andHeight:(int)h andPlane:(int)plans
{
	if (plans == CM_TEST_OBSTACLE)
	{
		if (obstacle != nil)
		{
			return [self testRc:obstacle withX:x andY:y andWidth:w andHeight:h];
		}
	}
	if (plans == CM_TEST_PLATFORM)
	{
		if (platform != nil)
		{
			return [self testRc:platform withX:x andY:y andWidth:w andHeight:h];
		}
		else if (obstacle != nil)
		{
			return [self testRc:obstacle withX:x andY:y andWidth:w andHeight:h];
		}
	}
	return false;
}

-(BOOL)testRc:(short*)mask withX:(int)xx andY:(int)yy andWidth:(int)sx andHeight:(int)sy
{
	int x1 = xx;
	int y1 = yy;
	x1 += mDxScroll;
	y1 += mDyScroll;
	int x2 = x1 + sx;
	int y2 = y1 + sy;
	
	// Verifier le clipping
	// --------------------
	if (x1 < mX1Clip)
	{
		x1 = mX1Clip;
	}
	if (x2 > mX2Clip)
	{
		x2 = mX2Clip;
	}
	
	if (y1 < mY1Clip)
	{
		y1 = mY1Clip;
	}
	if (y2 > mY2Clip)
	{
		y2 = mY2Clip;
	}
	
	if (x2 <= x1 || y2 <= y1)
	{
		return NO;
	}
	
	x1 -= mX1;
	x2 -= mX1;
	y1 -= mY1;
	y2 -= mY1;
	
	int h = y2 - y1;
	int w = ((x2 - 1) / 16) - (x1 / 16) + 1;
	int x, y;
	short s;
	int offset;
	
	switch (w)
	{
		case 1:
			s = (short) (lMask[x1 & 15] & rMask[((x2-1)&15)+1]);
			for (y = 0; y < h; y++)
			{
				offset = (y1 + y) * lineWidth + x1 / 16;
				if ((mask[offset] & s) != 0)
				{
					return YES;
				}
			}
			break;
		case 2:
			for (y = 0; y < h; y++)
			{
				offset = (y1 + y) * lineWidth + x1 / 16;
				if ((mask[offset] & lMask[x1 & 15]) != 0)
				{
					return YES;
				}
				if ((mask[offset + 1] & rMask[((x2-1)&15)+1]) != 0)
				{
					return YES;
				}
			}
			break;
		default:
			for (y = 0; y < h; y++)
			{
				offset = (y1 + y) * lineWidth + x1 / 16;
				if ((mask[offset] & lMask[x1 & 15]) != 0)
				{
					return YES;
				}
				for (x = 1; x < w - 1; x++)
				{
					if ((mask[offset + x] != 0))
					{
						return YES;
					}
				}
				if ((mask[offset + x] & rMask[((x2-1)&15)+1]) != 0)
				{
					return YES;
				}
			}
			break;
	}
	return NO;
}

-(BOOL)testMask:(CMask*)mask withYBase:(int)yBase andX:(int)xx andY:(int)yy andPlane:(int)plans
{
	if (plans == CM_TEST_OBSTACLE)
	{
		if (obstacle != nil)
		{
			return [self testIt:obstacle withMask:mask andYBase:yBase andX:xx andY:yy];
		}
	}
	if (plans == CM_TEST_PLATFORM)
	{
		if (platform != nil)
		{
			return [self testIt:platform withMask:mask andYBase:yBase andX:xx andY:yy];
		}
		else if (obstacle != nil)
		{
			return [self testIt:obstacle withMask:mask andYBase:yBase andX:xx andY:yy];
		}
	}
	return NO;
}

-(BOOL)testIt:(short*)dMask withMask:(CMask*)sMask andYBase:(int)yBase andX:(int)xx andY:(int)yy
{	
	int x1 = xx;
	int y1 = yy;
	x1 += mDxScroll;
	y1 += mDyScroll;
	int x2 = x1 + sMask->width;
	int y2 = y1 + sMask->height;
	int dx = 0;
	int dy = yBase;
	int fx = sMask->width;
	int fy = sMask->height;
	
	// Verifier le clipping
	// --------------------
	if (x1 < mX1Clip)
	{
		dx = mX1Clip - x1;
		if (dx > sMask->width)
		{
			return NO;
		}
		x1 = mX1Clip;
	}
	if (x2 > mX2Clip)
	{
		fx = sMask->width - (x2 - mX2Clip);
		if (fx < 0)
		{
			return NO;
		}
		x2 = mX2Clip;
	}
	
	if (y1 < mY1Clip)
	{
		dy = mY1Clip - y1;
		if (dy > sMask->height)
		{
			return NO;
		}
		y1 = mY1Clip;
	}
	if (y2 > mY2Clip)
	{
		fy = sMask->height - (y2 - mY2Clip);
		if (fy < 0)
		{
			return NO;
		}
		y2 = mY2Clip;
	}
	if (fx <= dx)
	{
		return NO;
	}
	
	x1 -= mX1;
	y1 -= mY1;
	x2 -= mX1;
	y2 -= mY1;

	int h = fy - dy;
	int w = (fx - dx + 15) / 16;
	int x, y;
	short s;
	int offset, mOffset, shiftX, i;
	shiftX = x1 & 15;
	if (shiftX != 0)
	{
		switch (w)
		{
			case 1:
				for (y = 0; y < h; y++)
				{
					offset = (y1 + y) * lineWidth + (x1 / 16);
					
					i = sMask->mask[(dy + y) * sMask->lineWidth + dx / 16] & lMask[dx & 15] & rMask[((fx-1)&15)+1] & 0xFFFF;
					if ((dMask[offset] & (short) (i >> shiftX)) != 0)
					{
						return YES;
					}
					if (x1 / 16 + 1 < lineWidth)
					{
						if ((dMask[++offset] & (short) (i << (15 - shiftX))) != 0)
						{
							return YES;
						}
					}
				}
				break;
			case 2:
				for (y = 0; y < h; y++)
				{
					offset = (y1 + y) * lineWidth + (x1 / 16);
					mOffset = (dy + y) * sMask->lineWidth + dx / 16;
					
					i = sMask->mask[mOffset] & lMask[dx & 15] & 0xFFFF;
					if ((dMask[offset] & (short) (i >> shiftX)) != 0)
					{
						return YES;
					}
					offset++;
					if ((dMask[offset] & (short) (i << (16 - shiftX))) != 0)
					{
						return YES;
					}
					
					i = (short) (sMask->mask[mOffset + 1] & rMask[((fx-1)&15)+1]) & 0xFFFF;
					if ((dMask[offset] & (short) (i >> shiftX)) != 0)
					{
						return YES;
					}
					if (x1 / 16 + 2 < lineWidth)
					{
						if ((dMask[++offset] & (short) (i << (16 - shiftX))) != 0)
						{
							return YES;
						}
					}
				}
				break;
			default:
				for (y = 0; y < h; y++)
				{
					offset = (y1 + y) * lineWidth + (x1 / 16);
					mOffset = (dy + y) * sMask->lineWidth + dx / 16;
					
					// Gauche
					i = sMask->mask[mOffset] & lMask[dx & 15] & 0xFFFF;
					if ((dMask[offset] & (short) (i >> shiftX)) != 0)
					{
						return YES;
					}
					offset++;
					if ((dMask[offset] & (short) (i << (16 - shiftX))) != 0)
					{
						return YES;
					}
					
					// Milieu
					for (x = 1; x < w - 1; x++)
					{
						i = sMask->mask[mOffset + x] & 0xFFFF;
						if ((dMask[offset] & (short) (i >> shiftX)) != 0)
						{
							return YES;
						}
						offset++;
						if ((dMask[offset] & (short) (i << (16 - shiftX))) != 0)
						{
							return YES;
						}
					}
					
					// Droite
					i = sMask->mask[mOffset + x] & rMask[((fx-1)&15)+1] & 0xFFFF;
					if ((dMask[offset] & (short) (i >> shiftX)) != 0)
					{
						return YES;
					}
					if (x1 / 16 + x < lineWidth)
					{
						if ((dMask[++offset] & (short) (i << (16 - shiftX))) != 0)
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
		switch (w)
		{
			case 1:
				for (y = 0; y < h; y++)
				{
					s = (short) (sMask->mask[(dy + y) * sMask->lineWidth + dx / 16] & lMask[dx & 15] & rMask[((fx-1)&15)+1]);
					if ((dMask[(y1 + y) * lineWidth + (x1 / 16)] & s) != 0)
					{
						return YES;
					}
				}
				break;
			case 2:
				for (y = 0; y < h; y++)
				{
					offset = (y1 + y) * lineWidth + (x1 / 16);
					mOffset = (dy + y) * sMask->lineWidth + dx / 16;
					
					s = (short) (sMask->mask[mOffset] & lMask[dx & 15]);
					if ((dMask[offset] & s) != 0)
					{
						return YES;
					}
					s = (short) (sMask->mask[mOffset + 1] & rMask[((fx-1)&15)+1]);
					if ((dMask[offset + 1] & s) != 0)
					{
						return YES;
					}
				}
				break;
			default:
				for (y = 0; y < h; y++)
				{
					offset = (y1 + y) * lineWidth + (x1 / 16);
					mOffset = (dy + y) * sMask->lineWidth + dx / 16;
					
					// Gauche
					s = (short) (sMask->mask[mOffset] & lMask[dx & 15]);
					if ((dMask[offset] & s) != 0)
					{
						return YES;
					}
					
					// Milieu
					for (x = 1; x < w - 1; x++)
					{
						s = sMask->mask[mOffset + x];
						if ((dMask[offset + x] & s) != 0)
						{
							return YES;
						}
					}
					
					// Droite
					s = (short) (sMask->mask[mOffset + x] & rMask[((fx-1)&15)+1]);
					if ((dMask[offset + x] & s) != 0)
					{
						return YES;
					}
				}
				break;
		}
	}
	return NO;
}


@end
