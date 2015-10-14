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
// CBITMAP : ecran bitmap
//
//----------------------------------------------------------------------------------
#import "CBitmap.h"
#import "CImage.h"
#import "CServices.h"
#import "CRenderer.h"

@implementation CBitmap

-(id)initWithWidth:(int)sx andHeight:(int)sy
{
	int maxTextureSize = CRenderer::getRenderer()->maxTextureSize;
	width= clamp(sx, 1, maxTextureSize);
	height=clamp(sy, 1, maxTextureSize);
	clipX1=0;
	clipY1=0;
	clipX2=width;
	clipY2=height;
	
	CGColorSpaceRef colorSpace;
	colorSpace = CGColorSpaceCreateDeviceRGB();
	data = (unsigned int*)malloc(height * width * 4);
	context = CGBitmapContextCreate(data, width, height, 8, 4 * width, colorSpace, kCGImageAlphaNoneSkipLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);	
	[self fillRect:0 withY:0 andWidth:width andHeight:height andColor:0];
	return self;
}
-(id)initWithoutContext:(int)w withHeight:(int)h
{
	width=w;
	height=h;
	clipX1=0;
	clipY1=0;
	clipX2=width;
	clipY2=height;
	context=nil;
	data = (unsigned int*)calloc(height * width, sizeof(unsigned int));
	return self;
}
-(id)initWithBitmap:(CBitmap*)source
{
	width=source->width;
	height=source->height;
	clipX1=0;
	clipY1=0;
	clipX2=width;
	clipY2=height;
	context=nil;
	data = (unsigned int*)malloc(height * width * sizeof(unsigned int));
	memcpy(data, source->data, width*height*sizeof(unsigned int));
	return self;
}
-(id)initWithImage:(CBitmap*)source
{
	width=source->width;
	height=source->height;
	clipX1=0;
	clipY1=0;
	clipX2=width;
	clipY2=height;
	context=nil;
	data = (unsigned int*)malloc(height * width * sizeof(unsigned int));
	
	int y;
	unsigned int* pDest;
	unsigned int* pSrce=source->data;
	for (y=0; y<height; y++)
	{
		pDest=data+(height-y)*width;
		memcpy(pDest, pSrce, width*(sizeof(unsigned int)));
		pSrce+=width;
	}
	return self;
}

-(void)dealloc
{
	if (context!=nil)
	{
		CGContextRelease(context);	
	}
	free(data);
	[super dealloc];
}
-(void)resizeWithWidth:(int)w andHeight:(int)h
{
	if (data!=nil)
	{
		free(data);
	}
	width=w;
	height=h;
	data = (unsigned int*)calloc(height * width, sizeof(unsigned int));

	if (context!=nil)
	{
		CGContextRelease(context);	
		context=nil;
	}
}
-(void)fillWithColor:(int)c
{
	int x1=clipX1;
	int y1=clipY1;
	int x2=clipX2;
	int y2=clipY2;

	int sx=x2-x1;
	if (sx<=0)
		return;
	int sy=y2-y1;
	if (sy<=0)
		return;

	c=swapRGB(c);
	unsigned int* pDest;
	unsigned int* pData=data+width*(height-1);
	int xx, yy;
	for (yy=0; yy<sy; yy++)
	{
		pDest=pData-(y1+yy)*width+x1;
		for (xx=sx; xx>0; xx--)
		{
			*(pDest++)=c;
		}
	}
}

-(void)fillRect:(int)x withY:(int)y andWidth:(int)w andHeight:(int)h andColor:(int)c
{
 	int x1=x;
	int y1=y;
	int x2=x+w;
	int y2=y+h;
	
	if (x1<clipX1)
	{
		x1=clipX1;
	}
	if (y1<clipY1)
	{
		y1=clipY1;
	}
	if (x2>clipX2)
	{
		x2=clipX2;
	}
	if (y2>clipY2)
	{
		y2=clipY2;
	}
	int sx=x2-x1;
	if (sx<=0)
	{
		return;
	}
	int sy=y2-y1;
	if (sy<=0)
	{
		return;
	}
	
	c=swapRGB(c);
	unsigned int* pDest;
	unsigned int* pData=data+width*(height-1);
	int xx, yy;
	for (yy=0; yy<sy; yy++)
	{
		pDest=pData-(y1+yy)*width+x1;
		for (xx=sx; xx>0; xx--)
		{
			*(pDest++)=c;
		}
	}	
}
-(void)drawImage:(int)x withY:(int)y andImage:(CImage*)image andInkEffect:(int)inkEffect andInkEffectParam:(int)inkEffectParam
{
	int x1=x;
	int y1=y;
	int x2=x+image->width;
	int y2=y+image->height;
	int dx=0;
	int dy=0;
	if (x1<clipX1)
	{
		dx+=clipX1-x1;
		x1=clipX1;
	}
	if (y1<clipY1)
	{
		dy+=clipY1-y1;
		y1=clipY1;
	}
	if (x2>clipX2)
	{
		x2=clipX2;
	}
	if (y2>clipY2)
	{
		y2=clipY2;
	}
	int sx=x2-x1;
	if (sx<=0)
	{
		return;
	}
	int sy=y2-y1;
	if (sy<=0)
	{
		return;
	}
	
	unsigned int* pData=data+width*(height-1);
	unsigned int* pDest;
	unsigned int* pSrce;
	unsigned int alpha;

	int xx, yy;
	unsigned int dw1, dw2, dw3, dw4;
	
	if ((inkEffect&EFFECTFLAG_TRANSPARENT)!=0 && (inkEffect&EFFECT_MASK)==0)
	{
		for (yy=0; yy<sy; yy++)
		{
			pDest=pData-(y1+yy)*width+x1;
			pSrce=image->data+(dy+yy)*image->width+dx;
			for (xx=sx; xx>0; xx--)
			{
				alpha=((*pSrce)>>24)&0xFF;
				if (alpha!=0)
				{
					if (alpha==255)
					{
						*(pDest++)=*(pSrce++);
					}
					else
					{
						dw1=((*pSrce)&0x00FF00FF)*alpha;
						dw2=((*pDest)&0x00FF00FF)*(256-alpha);
						dw3=((dw1+dw2)>>8)&0x00FF00FF;
						
						dw1=((*(pSrce++))&0x0000FF00)*alpha;
						dw2=((*pDest)&0x0000FF00)*(256-alpha);
						dw4=((dw1+dw2)>>8)&0x0000FF00;
						
						*(pDest++)=(dw3|dw4);
					}					
				}	
				else
				{
					pSrce++;
					pDest++;
				}
			}
		}
	}
	else if ((inkEffect&EFFECTFLAG_TRANSPARENT)==0 && (inkEffect&EFFECT_MASK)==0)
	{
		for (yy=0; yy<sy; yy++)
		{
			pDest=pData-(y1+yy)*width+x1;
			pSrce=image->data+(dy+yy)*image->width+dx;
			for (xx=sx; xx>0; xx--)
			{
				*(pDest++)=*(pSrce++);
			}
		}
	}
	else
	{
		int srce = 0;
		int effect=inkEffect&EFFECT_MASK;
		for (yy=0; yy<sy; yy++)
		{
			pDest=pData-(y1+yy)*width+x1;
			pSrce=image->data+(dy+yy)*image->width+dx;
			for (xx=sx; xx>0; xx--)
			{
				alpha=((*pSrce)>>24)&0xFF;
				switch(effect)
				{
					case BOP_BLEND:
						dw1=( ((*pDest&0x00FF00FF)*inkEffectParam)+((*pSrce&0x00FF00FF)*(128-inkEffectParam)) )/128;
						dw2=( ((*pDest&0x0000FF00)*inkEffectParam)+((*(pSrce++)&0x0000FF00)*(128-inkEffectParam)) )/128;
						srce=(dw1|dw2)&0x00FFFFFF;
						break;
					case BOP_INVERT:
						srce=*(pSrce++)^0x00FFFFFF;
						break;
					case BOP_XOR:
						srce=*(pSrce++)^*pDest;
						break;
					case BOP_AND:
						srce=*(pSrce++)&*pDest;
						break;
					case BOP_OR:
						srce=*(pSrce++)|*pDest;
						break;
					case BOP_ADD:
						srce=*(pSrce++)+*pDest;
						if (srce>255)
						{
							srce=255;
						}
						break;
					case BOP_SUB:
						srce=*pDest-*(pSrce++);
						if (srce>255)
						{
							srce=0;
						}
						break;
					case BOP_MONO:
					{
						srce=*(pSrce++);
						int r=(srce>>24)&0xFF;
						int g=(srce>>16)&0xFF;
						int b=srce&0xFF;
						int s=(r*5+b*2+g*9)/16;
						srce=(s<<16)|(s<<8)|s;						
						break;
					}
				}
				if (inkEffect&EFFECTFLAG_TRANSPARENT)
				{
					if (alpha!=0)
					{
						if (alpha==255)
						{
							*(pDest++)=srce;
						}
						else
						{
							dw1=(srce&0x00FF00FF)*alpha;
							dw2=((*pDest)&0x00FF00FF)*(256-alpha);
							dw3=((dw1+dw2)>>8)&0x00FF00FF;
							
							dw1=(srce&0x0000FF00)*alpha;
							dw2=((*pDest)&0x0000FF00)*(256-alpha);
							dw4=((dw1+dw2)>>8)&0x0000FF00;
							
							*(pDest++)=(dw3|dw4);
						}					
					}	
					else
					{
						pDest++;
					}
				}
				else
				{
					*(pDest++)=srce;
				}
			}
		}
	}
}
-(void)copyColorMask:(CImage*)img withColor:(int)couleur
{
	[self drawImage:0 withY:0 andImage:img andInkEffect:0 andInkEffectParam:0];

	int x, y, alpha;
	int color=swapRGB(couleur)&0x00FFFFFF;
	for (y=0; y<height; y++)
	{
		for (x=0; x<width; x++)
		{
			alpha=data[y*width+x]&0xFF000000;
			if (alpha!=0)
			{
				data[y*width+x]=alpha|color;
			}
		}
	}
}
-(void)copyImage:(CImage*)source
{
	if (width==source->width && height==source->height)
	{
		memcpy(data, source->data, width*height*sizeof(unsigned int));
	}
}
-(void)fade:(CBitmap*)source withCoef:(int)alpha
{
	if (width==source->width && height==source->height)
	{
		unsigned int* pSrce=source->data;
		unsigned int* pDest=data;
		int n;
		unsigned int srce, dw1, dw2, dw3, dw4, a;
		for (n=width*height; n>0; n--)
		{
			srce=*(pSrce++);
			if (alpha!=0)
			{
				if (alpha==255)
				{
					*(pDest++)=srce;
				}
				else
				{
					dw1=(srce&0x00FF00FF)*alpha;
					dw2=((*pDest)&0x00FF00FF)*(256-alpha);
					dw3=((dw1+dw2)>>8)&0x00FF00FF;
					
					dw1=(srce&0x0000FF00)*alpha;
					dw2=((*pDest)&0x0000FF00)*(256-alpha);
					dw4=((dw1+dw2)>>8)&0x0000FF00;
				
					a=(((srce>>24)&0xFF)*alpha)/256;
					*(pDest++)=(a<<24)|(dw3|dw4);
				}					
			}	
			else
			{
				pDest++;
			}
		}
	}
}

-(void)screenCopy:(CBitmap*)source
{
	if (width==source->width && height==source->height)
	{
		memcpy(data, source->data, width*height*sizeof(unsigned int));
	}
}
-(void)screenCopy:(CBitmap*)source withX:(int)xSource andY:(int)ySource andWidth:(int)wSource andHeight:(int)hSource
{
	int x1=xSource;
	int y1=ySource;
	int x2=xSource+wSource;
	int y2=ySource+hSource;
	
	if (x1<0)
	{
		x1=0;
	}
	if (y1<0)
	{
		y1=0;
	}
	if (x2>width)
	{
		x2=width;
	}
	if (y2>height)
	{
		y2=height;
	}
	int w=x2-x1;
	int h=y2-y1;
	if (w<=0 || h<=0)
	{
		return;
	}
	
	unsigned int* pSrceData=source->data+source->width*(source->height-1);
	unsigned int* pDestData=data+width*(height-1);
	unsigned int* pSrce;
	unsigned int* pDest;
	int x, y;
	for (y=0; y<h; y++)
	{
		pSrce=pSrceData-(y1+y)*source->width+x1;
		pDest=pDestData-(y1+y)*width+x1;
		for (x=w; x>0; x--)
		{
			*(pDest++)=*(pSrce++);
		}
	}		
}
-(void)screenCopy:(CBitmap*)source withDestX:(int)xDest andDestY:(int)yDest andSourceX:(int)xSource andSourceY:(int)ySource andWidth:(int)wSource andHeight:(int)hSource
{
	int xs1=xSource;
	int ys1=ySource;
	int xs2=xSource+wSource;
	int ys2=ySource+hSource;	
	if (xs1<0)
	{
		xs1=0;
	}
	if (ys1<0)
	{
		ys1=0;
	}
	if (xs2>source->width)
	{
		xs2=source->width;
	}
	if (ys2>source->height)
	{
		ys2=source->height;
	}

	int xd1=xDest;
	int yd1=yDest;
	int xd2=xDest+wSource;
	int yd2=yDest+hSource;	
	if (xd1<0)
	{
		xs1-=xd1;
		xd1=0;
	}
	if (yd1<0)
	{
		ys1-=yd1;
		yd1=0;
	}
	if (xd2>width)
	{
		xd2=width;
	}
	if (yd2>height)
	{
		yd2=height;
	}
	int w=xs2-xs1;
	int h=ys2-ys1;
	int wd=xd2-xd1;
	int hd=yd2-yd1;
	w=MIN(w, wd);
	h=MIN(h, hd);
	if (w<=0 || h<=0)
	{
		return;
	}
	
	unsigned int* pSrceData=source->data+source->width*(source->height-1);
	unsigned int* pDestData=data+width*(height-1);
	unsigned int* pSrce;
	unsigned int* pDest;
	int x, y;
	for (y=0; y<h; y++)
	{
		pSrce=pSrceData-(ys1+y)*source->width+xs1;
		pDest=pDestData-(yd1+y)*width+xd1;
		for (x=w; x>0; x--)
		{
			*(pDest++)=*(pSrce++);
		}
	}		
}
-(void)drawPatternRect:(CImage*)image withX:(int)x andY:(int)y andWidth:(int)w andHeight:(int)h andInkEffect:(int)inkEffect andInkEffectParam:(int)inkEffectParam
{
	int x1=x;
	int y1=y;
	int x2=x+w;
	int y2=y+h;
	if (x1<clipX1)
	{
		x1=clipX1;
	}
	if (y1<clipY1)
	{
		y1=clipY1;
	}
	if (x2>clipX2)
	{
		x2=clipX2;
	}
	if (y2>clipY2)
	{
		y2=clipY2;
	}
	int sx=x2-x1;
	if (sx<=0)
	{
		return;
	}
	int sy=y2-y1;
	if (sy<=0)
	{
		return; 		
	}

	unsigned int* pDest;
	unsigned int* pSrce;
	unsigned int* pData=data+width*(height-1);
	int xx, yy;
	unsigned int dw1, dw2, dw3, dw4;
	unsigned int* pSrce2;
	unsigned int alpha;
	if ((inkEffect&EFFECTFLAG_TRANSPARENT)!=0 && (inkEffect&EFFECT_MASK)==0)
	{
		for (yy=0; yy<sy; yy++)
		{
			pDest=pData-(y1+yy)*width+x1;
			pSrce=image->data+((yy+y1-y)%image->height)*image->width;
			for (xx=0; xx<sx; xx++)
			{
				pSrce2=pSrce+((xx+x1-x)%image->width);
				alpha=((*pSrce2)>>24)&0xFF;
				if (alpha!=0)
				{
					if (alpha==255)
					{
						*(pDest++)=*(pSrce2);
					}
					else
					{
						dw1=((*pSrce2)&0x00FF00FF)*alpha;
						dw2=((*pDest)&0x00FF00FF)*(256-alpha);
						dw3=((dw1+dw2)>>8)&0x00FF00FF;
						
						dw1=((*(pSrce2))&0x0000FF00)*alpha;
						dw2=((*pDest)&0x0000FF00)*(256-alpha);
						dw4=((dw1+dw2)>>8)&0x0000FF00;
						
						*(pDest++)=(dw3|dw4);
					}					
				}	
				else
				{
					pDest++;
				}
			}
		}
	}
	else if ((inkEffect&EFFECTFLAG_TRANSPARENT)==0 && (inkEffect&EFFECT_MASK)==0)
	{
		for (yy=0; yy<sy; yy++)
		{
			pDest=pData-(y1+yy)*width+x1;
			pSrce=image->data+((yy+y1-y)%image->height)*image->width;
			for (xx=0; xx<sx; xx++)
			{
				pSrce2=pSrce+((xx+x1-x)%image->width);
				*(pDest++)=*(pSrce2);
			}
		}
	}
	else
	{
		int srce = 0;
		int effect=inkEffect&EFFECT_MASK;
		for (yy=0; yy<sy; yy++)
		{
			pDest=pData-(y1+yy)*width+x1;
			pSrce=image->data+((yy+y1-y)%image->height)*image->width;
			for (xx=0; xx<sx; xx++)
			{
				pSrce2=pSrce+((xx+x1-x)%image->width);
				alpha=((*pSrce2)>>24)&0xFF;
				switch(effect)
				{
					case BOP_BLEND:
						dw1=( ((*pDest&0x00FF00FF)*inkEffectParam)+((*pSrce2&0x00FF00FF)*(128-inkEffectParam)) )/128;
						dw2=( ((*pDest&0x0000FF00)*inkEffectParam)+((*(pSrce2)&0x0000FF00)*(128-inkEffectParam)) )/128;
						srce=(dw1|dw2)&0x00FFFFFF;
						break;
					case BOP_INVERT:
						srce=*(pSrce2)^0x00FFFFFF;
						break;
					case BOP_XOR:
						srce=*(pSrce2)^*pDest;
						break;
					case BOP_AND:
						srce=*(pSrce2)&*pDest;
						break;
					case BOP_OR:
						srce=*(pSrce2)|*pDest;
						break;
					case BOP_ADD:
						srce=*(pSrce2)+*pDest;
						if (srce>255)
						{
							srce=255;
						}
						break;
					case BOP_SUB:
						srce=*pDest-*(pSrce2);
						if (srce>255)
						{
							srce=0;
						}
						break;
					case BOP_MONO:
					{
						srce=*(pSrce2);
						int r=(srce>>24)&0xFF;
						int g=(srce>>16)&0xFF;
						int b=srce&0xFF;
						int s=(r*5+b*2+g*9)/16;
						srce=(s<<16)|(s<<8)|s;						
						break;
					}
				}
				if (inkEffect&EFFECTFLAG_TRANSPARENT)
				{
					if (alpha!=0)
					{
						if (alpha==255)
						{
							*(pDest++)=srce;
						}
						else
						{
							dw1=(srce&0x00FF00FF)*alpha;
							dw2=((*pDest)&0x00FF00FF)*(256-alpha);
							dw3=((dw1+dw2)>>8)&0x00FF00FF;
							
							dw1=(srce&0x0000FF00)*alpha;
							dw2=((*pDest)&0x0000FF00)*(256-alpha);
							dw4=((dw1+dw2)>>8)&0x0000FF00;
							
							*(pDest++)=(dw3|dw4);
						}					
					}	
					else
					{
						pDest++;
					}
				}
				else
				{
					*(pDest++)=srce;
				}
			}
		}
	}
}
-(void)drawPatternEllipse:(CImage*)image withX1:(int)x1 andY1:(int)y1 andX2:(int)x2 andY2:(int)y2 andInkEffect:(int)inkEffect andInkEffectParam:(int)inkEffectParam
{
	unsigned int* pData=data+width*(height-1);
	double xx, yy;
	double sy=y2-y1;
	double sx=x2-x1;
	double xCenter=(x1+x2)/2;
	double yCenter=(y1+y2)/2;
	double a=sx/2;
	double b=sy/2;
	unsigned int dw1, dw2, dw3, dw4;
	unsigned int* pSrce2;
	unsigned int* pDest;
	unsigned int* pDest2;
	unsigned int* pSrce;
	unsigned int alpha;
	for (yy=y1; yy<y2; yy++)
	{
		if (yy>=clipY1 && yy<clipY2)
		{
			pDest=pData-((int)yy)*width;
			pSrce=image->data+(((int)yy-y1)%image->height)*image->width;
			for (xx=x1; xx<x2; xx++)
			{
				if (xx>=clipX1 && xx<clipX2)
				{
					if ( ((xx-xCenter)/a)*((xx-xCenter)/a) + ((yy-yCenter)/b)*((yy-yCenter)/b) <1.0)
					{
						pDest2=pDest+(int)xx;
						pSrce2=pSrce+(((int)xx-x1)%image->width);
						if ((inkEffect&EFFECTFLAG_TRANSPARENT)!=0 && (inkEffect&EFFECT_MASK)==0)
						{
							alpha=((*pSrce2)>>24)&0xFF;
							if (alpha!=0)
							{
								if (alpha==255)
								{
									*pDest2=*pSrce2;
								}
								else
								{
									dw1=((*pSrce2)&0x00FF00FF)*alpha;
									dw2=((*pDest2)&0x00FF00FF)*(256-alpha);
									dw3=((dw1+dw2)>>8)&0x00FF00FF;
									
									dw1=((*(pSrce2))&0x0000FF00)*alpha;
									dw2=((*pDest2)&0x0000FF00)*(256-alpha);
									dw4=((dw1+dw2)>>8)&0x0000FF00;
									
									*pDest2=(dw3|dw4);
								}					
							}		
						}
						else if ((inkEffect&EFFECTFLAG_TRANSPARENT)==0 && (inkEffect&EFFECT_MASK)==0)
						{
							*pDest2=*(pSrce2);
						}
						else
						{
							int srce = 0;
							int effect=inkEffect&EFFECT_MASK;
							alpha=((*pSrce2)>>24)&0xFF;
							switch(effect)
							{
								case BOP_BLEND:
									dw1=( ((*pDest2&0x00FF00FF)*inkEffectParam)+((*pSrce2&0x00FF00FF)*(128-inkEffectParam)) )/128;
									dw2=( ((*pDest2&0x0000FF00)*inkEffectParam)+((*pSrce2&0x0000FF00)*(128-inkEffectParam)) )/128;
									srce=(dw1|dw2)&0x00FFFFFF;
									break;
								case BOP_INVERT:
									srce=*pSrce2^0x00FFFFFF;
									break;
								case BOP_XOR:
									srce=*pSrce2^*pDest2;
									break;
								case BOP_AND:
									srce=*pSrce2&*pDest2;
									break;
								case BOP_OR:
									srce=*pSrce2|*pDest2;
									break;
								case BOP_ADD:
									srce=*pSrce2+*pDest2;
									if (srce>255)
									{
										srce=255;
									}
									break;
								case BOP_SUB:
									srce=*pDest2-*pSrce2;
									if (srce>255)
									{
										srce=0;
									}
									break;
								case BOP_MONO:
								{
									srce=*pSrce2;
									int r=(srce>>24)&0xFF;
									int g=(srce>>16)&0xFF;
									int b=srce&0xFF;
									int s=(r*5+b*2+g*9)/16;
									srce=(s<<16)|(s<<8)|s;						
									break;
								}
							}
							if (inkEffect&EFFECTFLAG_TRANSPARENT)
							{
								if (alpha!=0)
								{
									if (alpha==255)
									{
										*pDest2=srce;
									}
									else
									{
										dw1=(srce&0x00FF00FF)*alpha;
										dw2=((*pDest2)&0x00FF00FF)*(256-alpha);
										dw3=((dw1+dw2)>>8)&0x00FF00FF;
										
										dw1=(srce&0x0000FF00)*alpha;
										dw2=((*pDest2)&0x0000FF00)*(256-alpha);
										dw4=((dw1+dw2)>>8)&0x0000FF00;
										
										*pDest2=(dw3|dw4);
									}					
								}	
							}
							else
							{
								*pDest2=srce;
							}
						}
					}
				}
			}	
		}
	}
}
-(void)setClipWithX1:(int)x1 andY1:(int)y1 andX2:(int)x2 andY2:(int)y2
{
	clipX1=x1;	
	clipY1=y1;
	clipX2=x2;
	clipY2=y2;
	if (clipX1<0)
	{
		clipX1=0;
	}
	if (clipY1<0)
	{
		clipY1=0;
	}
	if (clipX2>width)
	{
		clipX2=width;
	}
	if (clipY2>height)
	{
		clipY2=height;
	}
}
-(void)resetClip
{
	clipX1=0;
	clipY1=0;
	clipX2=width;
	clipY2=height;
}
-(void)stretchWithSource:(CBitmap*)pSource andDestX:(int)tX andDestY:(int)tY andSourceX:(int)sX andSourceY:(int)sY andNewWidth:(int)newWidth andNewHeight:(int)newHeight andSrcWidth:(int)srcWidth andSrcHeight:(int)srcHeight
{	
	if (newWidth==0 || newHeight==0 || srcWidth==0 || srcHeight==0)
		return;

	int newHtTmp=newHeight;
	int htTmp=srcHeight;

	int srcWidthBytes=pSource->width;
	int destWidthBytes=width;
	int newWidthInBytes=newWidth*sizeof(int);
	
	unsigned int* psb=pSource->data+sX+sY*pSource->width;
	unsigned int* pdb=data+tX+tY*width;
	unsigned int* pdb0=pdb;
	
	unsigned int CoefX=(newWidth<<16)/srcWidth;
	unsigned int CoefY=(newHeight<<16)/srcHeight;
	unsigned int CptY=CoefY;
	
	do
	{
		if (CptY>=0x10000)
		{
			[CBitmap stretchLineWithDest:pdb andSource:psb andNewWidth:newWidth andSrcWidth:srcWidth andCoefX:CoefX];
			psb+=srcWidthBytes;
			pdb+=destWidthBytes;
			
			while(--newHtTmp>0)
			{
				CptY-=0x10000;
				if (CptY<0x10000)
				{
					break;
				}
				memcpy(pdb, pdb-destWidthBytes, newWidthInBytes);
				pdb+=destWidthBytes;
			}
		}
		else
		{
			psb+=srcWidthBytes;
		}		
		CptY+=CoefY;		
	}while(--htTmp>0);
	
	if (newHtTmp>0)
	{
		if (pdb!=pdb0)
		{
			memcpy(pdb, pdb-destWidthBytes, newWidthInBytes);
//			pdb+=destWidthBytes;
		}
		else
		{
			psb-=srcWidthBytes;
			[CBitmap stretchLineWithDest:pdb andSource:psb andNewWidth:newWidth andSrcWidth:srcWidth andCoefX:CoefX];
//			psb+=srcWidthBytes;
//			pdb+=destWidthBytes;
		}
	}
}
+(void)stretchLineWithDest:(unsigned int*)dest andSource:(unsigned int*)src andNewWidth:(int)newWidth andSrcWidth:(int)srcWidth andCoefX:(int)CoefX
{
	unsigned dw=0;
	unsigned int coef=CoefX;
	unsigned int count;
	
	if (CoefX>=0x10000)
	{
		do
		{
			dw=*src++;
			count=(coef>>16);
			coef&=0xFFFF;
			coef+=CoefX;
			newWidth-=count;
			
			do
			{
				*dest++=dw;
			}while(--count>0);
			
		}while(--srcWidth>0);
		
		if (newWidth>0)
		{
			*dest++=dw;
		}
	}
	else
	{
		count=0;
		do
		{
			count++;
			
			if ((coef&0xFFFF0000)==0)
			{
				coef+=CoefX;
			}
			else
			{
				dw=*src;
				*dest++=dw;
				src+=count;
				coef&=0xFFFF;
				coef+=CoefX;
				count=0;
				newWidth--;
			}
		}while(--srcWidth>0);
		
		if (newWidth>0 && count!=0)
		{
			*dest++=dw;
		}
	}
}
-(void)rotateWithSource:(CBitmap*)source andAngle:(float)angle andAA:(BOOL)bAA andClrFill:(int)clrFill
{
	if (angle==0 || angle==180)
	{
		[self screenCopy:source withDestX:0 andDestY:0 andSourceX:0 andSourceY:0 andWidth:source->width andHeight:source->height];
		if (angle==180)
		{
			[self reverseXWithX:0 andY:0 andWidth:width andHeight:height];
			[self reverseYWithX:0 andY:0 andWidth:width andHeight:height];
		}
		return;
	}
	
	float cosa;
	float sina;
	if (angle==90)
	{
		cosa=0.0f;
		sina=1.0f;
	}
	else if (angle==270)
	{
		cosa=0.0f;
		sina=-1.0f;
	}
	else
	{
		cosa=cosf(((angle*M_PI)/180.0f));
		sina=sinf(((angle*M_PI)/180.0f));
	}
	float fxs=(float)source->width/2-(float)width/2*cosa+(float)height/2*sina;
	float fys=(float)source->height/2-(float)width/2*sina-(float)height/2*cosa;
	
	int x, y;
	unsigned int* pDestBits=data;
	unsigned int* pDest=pDestBits;
	int nDestPitch=width;
	unsigned int* pSrcBits=source->data;
	int nSrcPitch=source->width;
	unsigned int dw;
	int xs;
	int ys;
	int nDestWidth=width;
	int nDestHeight=height;
	int nSrcWidth=source->width;
	int nSrcHeight=source->height;
	// if (bAA)
	{
		for (y=0; y<nDestHeight; y++)
		{
			unsigned int* pd=pDest;
			float txs=fxs;
			float tys=fys;
			
			for (x=0; x<nDestWidth; x++)
			{
				xs=(int)txs;
				ys=(int)tys;
				txs+=cosa;
				tys+=sina;
				
				dw=0;
				if (xs>=0 && xs<nSrcWidth && ys>=0 && ys<nSrcHeight)
				{
					dw=*(pSrcBits+ys*nSrcPitch+xs);
				}
				*pd++=dw;
			}
			pDest+=nDestPitch;
			fxs-=sina;
			fys+=cosa;
		}	 
	}
}
-(void)reverseXWithX:(int)xx andY:(int)yy andWidth:(int)ww andHeight:(int)hh
{
	int x1=xx;
	int y1=yy;
	int x2=xx+ww;
	int y2=yy+hh;
	if (x1<0)
	{
		x1=0;
	}
	if (y1<0)
	{
		y1=0;
	}
	if (x2>width)
	{
		x2=width;
	}
	if (y2>height)
	{
		y2=height;
	}
	int w=x2-x1;
	int h=y2-y1;
	if (w==0 || h==0)
	{
		return;
	}
	
	int x, y;
	unsigned int temp;
	for (y=0; y<h; y++)
	{
		unsigned int* pDest=data+(y1+y)*width+x1;
		for (x=0; x<w/2; x++)
		{
			temp=*(pDest+x);
			*(pDest+x)=*(pDest+w-x-1);
			*(pDest+w-x-1)=temp;
		}
	}		
}
-(void)reverseYWithX:(int)xx andY:(int)yy andWidth:(int)ww andHeight:(int)hh
{
	int x1=xx;
	int y1=yy;
	int x2=xx+ww;
	int y2=yy+hh;
	if (x1<0)
	{
		x1=0;
	}
	if (y1<0)
	{
		y1=0;
	}
	if (x2>width)
	{
		x2=width;
	}
	if (y2>height)
	{
		y2=height;
	}
	int w=x2-x1;
	int h=y2-y1;
	if (w==0 || h==0)
	{
		return;
	}
	
	int y;
	unsigned int* temp=(unsigned int*)malloc(w*sizeof(unsigned int)); 
	for (y=0; y<h/2; y++)
	{
		unsigned int* pDest1=data+(y1+y)*width+x1;
		unsigned int* pDest2=data+(y1+w-y-1)*width+x1;
		memcpy(temp, pDest1, w*sizeof(unsigned int));
		memcpy(pDest1, pDest2, w*sizeof(unsigned int));
		memcpy(pDest2, temp, w*sizeof(unsigned int));
	}
	free(temp);
}

@end
