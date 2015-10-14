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
// CIMAGE Une image
//
//----------------------------------------------------------------------------------
#import "CImage.h"
#import "CFile.h"
#import "CMask.h"
#import "CBitmap.h"
#import "CServices.h"
#import "CArrayList.h"
#import "CRunApp.h"
#import "NSExtensions.h"

@implementation CImage

-(void)dealloc
{
	if (data!=nil)
	{
		free(data);
	}
	if (mask!=nil)
	{
		[mask release];
	}
	if (maskPlatform!=nil)
	{
		[maskPlatform release];
	}
	if (maskRotation!=nil)
	{
		[maskRotation freeRelease];
		[maskRotation release];
	}
	if(replacedColors != nil)
	{
		[replacedColors freeRelease];
		[replacedColors release];
	}
	[self deleteTexture];
	[super dealloc];
}
-(id)init
{
	app=nil;
	data=nil;
	mask=nil;
	maskPlatform=nil;
	maskRotation=nil;
	handle = -1;
	textureId = -1;
	bytesPrPixel = 4;
	format = RGBA8888;
	flags = 0;
	bCanRelease=NO;
	coordsAreSwapped = NO;
	hasMipMaps = NO;
	replacedColors = nil;
	isUploading = NO;
	lineWidth = 0;
	bLineWidth = 0;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	return self;
}
-(id)initWithApp:(CRunApp*)a
{
	app=a;
	data=nil;
	mask=nil;
	maskPlatform=nil;
	maskRotation=nil;
	handle = -1;
	textureId = -1;
	bytesPrPixel = 4;
	format = RGBA8888;
	flags = 0;
	bCanRelease=NO;
	coordsAreSwapped = NO;
	hasMipMaps = NO;
	replacedColors = nil;
	isUploading = NO;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	return self;
}
-(id)initWithWidth:(int)sx andHeight:(int)sy
{
	width=sx;
	height=sy;
	originalWidth = width;
	originalHeight = height;
	mask=nil;
	maskPlatform=nil;
	maskRotation=nil;
	[self calculateTextureSize];
	data = (unsigned int*)calloc(height * width, sizeof(unsigned int));
	handle = -1;
	textureId = -1;
	bytesPrPixel = 4;
	format = RGBA8888;
	flags = 0;
	bCanRelease=NO;
	coordsAreSwapped = NO;
	hasMipMaps = NO;
	replacedColors = nil;
	isUploading = NO;
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	return self;
}
-(id)initWithBitmap:(CBitmap*)source
{
	width=source->width;
	height=source->height;
	originalWidth = width;
	originalHeight = height;
	data = (unsigned int*)malloc(height * width * sizeof(unsigned int));
	handle = -1;
	textureId = -1;
	bytesPrPixel = 4;
	format = RGBA8888;
	flags = 0;
	bCanRelease=NO;
	coordsAreSwapped = NO;
	mask=nil;
	maskPlatform=nil;
	maskRotation=nil;
	hasMipMaps = NO;
	resample = NO;
	replacedColors = nil;
	isUploading = NO;
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	memcpy(data, source->data, width*height*sizeof(unsigned int));
	return self;
}

-(void)calculateTextureSize
{
	textureWidth = 8;
	textureHeight = 8;
	while (textureWidth<width)
		textureWidth *= 2;
	while (textureHeight<height)
		textureHeight *= 2;
}

-(void)resizeWithWidth:(int)w andHeight:(int)h
{
	if (data!=nil)
	{
		free(data);
	}
	width=w;
	height=h;
	originalWidth = width;
	originalHeight = height;
	data = (unsigned int*)calloc(height * width, sizeof(unsigned int));
	hasMipMaps = NO;
	resample = NO;
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	[self updateTextureMatrix];
}
-(void)loadHandle:(CFile*)f
{
	file=f;
	handle = [file readAShort];
	[file skipBytes:16];
	chunkSize=[file readAInt];
	[file skipBytes:chunkSize];
	textureId = -1;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
}

-(void)load:(CFile*)f
{
	file=f;
	handle = [file readAShort];
	format = [file readAShort];
	flags = [file readAShort];
	width = [file readAShort];
	height = [file readAShort];
	xSpot = [file readAShort];
	ySpot = [file readAShort];
	xAP = [file readAShort];
	yAP = [file readAShort];
	chunkSize=[file readAInt];
	textureId = -1;
	bytesPrPixel = [CImage getFormatByteSize:format];
	offset=[file getFilePointer];
	replacedColors = [[CArrayList alloc] init];
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	originalWidth = width;
	originalHeight = height;
	
	NSAutoreleasePool* tempPool = [[NSAutoreleasePool alloc] init];
	
	NSData* compressedData = [file getSubData:chunkSize];
	NSData* imgData = [compressedData zlibInflate];
	
	//Copies the decompressed data to the data buffer
	dataLength = [imgData length];
	data = (unsigned int*)malloc(dataLength+1);
	[imgData getBytes:data length:dataLength];
	[imgData release];
	bCanRelease=YES;
	hasMipMaps = NO;
	resample = NO;
	
	[tempPool drain];
}

-(void)preload:(CFile*)f
{
	file=f;
	handle = [file readAShort];
	format = [file readAShort];
	flags = [file readAShort];
	width = [file readAShort];
	height = [file readAShort];
	xSpot = [file readAShort];
	ySpot = [file readAShort];
	xAP = [file readAShort];
	yAP = [file readAShort];
	chunkSize=[file readAInt];
	textureId = -1;
	bytesPrPixel = [CImage getFormatByteSize:format];
	offset=[file getFilePointer];
	replacedColors = [[CArrayList alloc] init];
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	originalWidth = width;
	originalHeight = height;
	dataLength = 0;
	data = nil;
	bCanRelease=YES;
	hasMipMaps = NO;
	resample = NO;
}

-(void)reload
{
	if (data!=nil)
		return;

	//Theese are autoreleased
	[file seek:offset];
	NSData* compressedData = [file getSubData:chunkSize];
	NSData* imgData = [compressedData zlibInflate];
	dataLength = [imgData length];
	
	//Copies the decompressed data to the data buffer
	data = (unsigned int*)malloc(dataLength+1);
	[imgData getBytes:data length:dataLength];
	[imgData release];
	bCanRelease=YES;
	hasMipMaps = NO;
	resample = NO;
	[self replaceColors];
}
+ (CImage*)loadUIImage:(UIImage*)image
{
    CGImageRef imageRef = [image CGImage];
    size_t width = CGImageGetWidth(imageRef);
    size_t height = CGImageGetHeight(imageRef);
	
    CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
    unsigned int *rawData = (unsigned int*)calloc(width*height, sizeof(unsigned int));
    NSUInteger bytesPerRow = width*sizeof(int);
    NSUInteger bitsPerComponent = 8;
    CGContextRef context = CGBitmapContextCreate(rawData, width, height,
												 bitsPerComponent, bytesPerRow, colorSpace,
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
    CGColorSpaceRelease(colorSpace);
    CGContextDrawImage(context, CGRectMake(0, 0, width, height), imageRef);
    CGContextRelease(context);
	
	CImage* newImage = [[CImage alloc] init];
	newImage->width = (int)width;
	newImage->height = (int)height;
	newImage->originalWidth = (int)width;
	newImage->originalHeight = (int)height;
	newImage->xSpot = newImage->ySpot = newImage->xAP = newImage->yAP = 0;
	newImage->maskPlatform = newImage->mask = nil;
	newImage->maskRotation = nil;
	newImage->file = nil;
	newImage->data = rawData;
	newImage->dataLength = width*height*sizeof(int);
	newImage->useCount = 1;
	newImage->handle = -1;
	newImage->textureId = -1;
	newImage->bytesPrPixel = 4;
	newImage->format = RGBA8888;
	newImage->flags = 0;
	newImage->hasMipMaps = NO;
	newImage->resample = YES;
	newImage->bCanRelease = NO;
	newImage->isUploading = NO;
	newImage->lineWidth = newImage->width*newImage->bytesPrPixel;
	newImage->bLineWidth = (newImage->lineWidth+3) & ~3;
	newImage->wrapS = newImage->wrapT = GL_CLAMP_TO_EDGE;

	//Un-premultiply the png data as cocoa simply doesn't want to return un-premultiplied image data no matter what.
	[newImage unpremultiply];

	[newImage updateTextureMatrix];
	return newImage;
}

+ (CImage*)loadBitmap:(CBitmap*)bitmap
{	
	int bufferSize = bitmap->width * bitmap->height * sizeof(int);
	
	CImage* newImage = [[CImage alloc] init];
	newImage->width = bitmap->width;
	newImage->height = bitmap->height;
	newImage->originalWidth = bitmap->width;
	newImage->originalHeight = bitmap->height;
	newImage->data = (unsigned int*)malloc(bufferSize+1);
	newImage->dataLength = bufferSize;
	memcpy(newImage->data, bitmap->data, bufferSize);
	newImage->handle = -1;
	newImage->textureId = -1;
	newImage->bytesPrPixel = 4;
	newImage->format = RGBA8888;
	newImage->flags = 0;
	newImage->hasMipMaps = NO;
	newImage->resample = NO;
	newImage->bCanRelease = NO;
	newImage->isUploading = NO;
	newImage->lineWidth = newImage->width*newImage->bytesPrPixel;
	newImage->bLineWidth = (newImage->lineWidth+3) & ~3;
	newImage->wrapS = newImage->wrapT = GL_CLAMP_TO_EDGE;
	[newImage updateTextureMatrix];
	return newImage;
}

-(CImage*)copy
{
	CImage* cp = [[CImage alloc] init];
	cp->width = width;
	cp->height = height;
	cp->originalWidth = originalWidth;
	cp->originalHeight = originalHeight;
	cp->textureWidth = textureWidth;
	cp->textureHeight = textureHeight;
	cp->data = (unsigned int*)malloc(dataLength+1);
	cp->dataLength = dataLength;
	memcpy(cp->data, data, dataLength);
	cp->handle = handle;
	cp->textureId = textureId;
	cp->bytesPrPixel = bytesPrPixel;
	cp->format = format;
	cp->flags = flags;
	cp->hasMipMaps = hasMipMaps;
	cp->resample = resample;
	cp->bCanRelease = bCanRelease;
	cp->isUploading = isUploading;
	cp->lineWidth = lineWidth;
	cp->bLineWidth = bLineWidth;
	cp->wrapS = wrapS;
	cp->wrapT = wrapT;
	[cp updateTextureMatrix];
	return cp;
}

- (void)loadBitmap:(CBitmap*)bitmap
{	
	int bufferSize = bitmap->width * bitmap->height * sizeof(int);
	
	if(data == nil || width != bitmap->width || height != bitmap->height || format != RGBA8888)
	{
		[self deleteTexture];
		if(data != nil)
			free(data);
		data = (unsigned int*)malloc(bufferSize);
		dataLength = bufferSize;
		width = bitmap->width;
		height = bitmap->height;
		[self calculateTextureSize];
		
		bytesPrPixel = 4;
		format = RGBA8888;
		flags = 0;
	}
	memcpy(data, bitmap->data, bufferSize);

	coordsAreSwapped = YES;
	hasMipMaps = NO;
	resample = NO;
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	wrapS = wrapT = GL_CLAMP_TO_EDGE;
	[self updateTextureMatrix];
	
	if(textureId == -1)
		[self uploadTexture];
	else
		[self reUploadTexture];
}

+ (CImage*)createFullColorImage:(CImage*)image
{
	CImage* newImage = [[CImage alloc] initWithApp:image->app];
	newImage->width = image->width;
	newImage->height = image->height;
	newImage->originalWidth = image->width;
	newImage->originalHeight = image->height;
	newImage->data = (unsigned int*)malloc(image->width*image->height*sizeof(unsigned int));
	newImage->dataLength = image->width*image->height*sizeof(int);
	newImage->handle = -1;
	newImage->textureId = -1;
	newImage->bytesPrPixel = 4;
	newImage->format = RGBA8888;
	newImage->flags = 0;
	newImage->hasMipMaps = NO;
	newImage->resample = NO;
	newImage->wrapS = newImage->wrapT = GL_CLAMP_TO_EDGE;
	
	for(int y=0; y<image->height; ++y)
		for(int x=0; x<image->width; ++x)
		{
			int pixel = [image getPixel:x withY:y];
			newImage->data[image->width*y+x] = pixel;
		}

	[newImage updateTextureMatrix];
	return newImage;
}

-(CGImageRef)getCGImage
{
	//Create duplicate but in full color
	CImage* newImage = [CImage createFullColorImage:self];
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef ctx = CGBitmapContextCreate(newImage->data, width, height, 8, 4*width, colorSpace, kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
		
	//Return the CGImage as normal
	CGImageRef cgImage = CGBitmapContextCreateImage(ctx);
	
	[newImage release];
	CGColorSpaceRelease(colorSpace);
	CGContextRelease(ctx);
	
	return cgImage;
}
-(void)freeCGImage:(CGImageRef)cgImage
{
	CGImageRelease(cgImage);
}
-(UIImage*)getUIImage
{
	CGImageRef cgi=[self getCGImage];
	return [UIImage imageWithCGImage:cgi];
}
-(CMask*)getMask:(int)nFlags withAngle:(float)angle andScaleX:(double)scaleX andScaleY:(double)scaleY
{
	if ((nFlags & GCMF_PLATFORM) == 0)
	{
		if (mask==nil)
		{
			if (data==nil)
			{
				[self reload];
			}			
			mask = [[CMask alloc] init];
			[mask createMask:self withFlags:nFlags];
			mask->xSpot = xSpot;
			mask->ySpot = ySpot;
		}
		if (angle==0 && scaleX==1.0 && scaleY==1.0)
		{
			if (app!=nil)
			{
				app->secondMask=app->firstMask;
				app->firstMask=mask;
			}
			return mask;
		}
		
		// Returns the rotated mask
		RotatedMask* rMask;
		if (maskRotation==nil)
		{
			maskRotation=[[CArrayList alloc] init];
		}
		int n;
		int tick=0x7FFFFFFF;
		int nOldest=-1;
		for (n=0; n<[maskRotation size]; n++)
		{
			rMask=(RotatedMask*)[maskRotation get:n];
			if (angle==rMask->angle && scaleX==rMask->scaleX && scaleY==rMask->scaleY)
			{
				if (app!=nil)
				{
					app->secondMask=app->firstMask;
					app->firstMask=rMask->mask;
				}
				return rMask->mask; 
			}
			if (rMask->tick<tick)
			{
				tick=rMask->tick;
				nOldest=n;
			}
		}
		if ([maskRotation size]<MAX_ROTATEDMASKS)
		{
			nOldest=-1;
		}
		rMask=(RotatedMask*)malloc(sizeof(RotatedMask));
		rMask->mask=[[CMask alloc] init];
		[rMask->mask createRotatedMask:mask withAngle:angle andScaleX:scaleX andScaleY:scaleY];
		rMask->angle=angle;
		rMask->scaleX=scaleX;
		rMask->scaleY=scaleY;
		rMask->tick=(int)CFAbsoluteTimeGetCurrent()*1000;
		if (nOldest<0)
		{
			[maskRotation add:rMask];
		}
		else
		{
			RotatedMask* pMaskOld = (RotatedMask*)[maskRotation get:nOldest];
			[pMaskOld->mask release];
			free(pMaskOld);
			[maskRotation set:nOldest object:rMask];
		}
		if (app!=nil)
		{
			app->secondMask=app->firstMask;
			app->firstMask=rMask->mask;
		}
		return rMask->mask;
	}
	else
	{
		if (maskPlatform == nil)
		{
			if (data==nil)
			{
				[self reload];
			}
			maskPlatform = [[CMask alloc] init];
			[maskPlatform createMask:self withFlags:nFlags];
			maskPlatform->xSpot = xSpot;
			maskPlatform->ySpot = ySpot;
		}
		if (app!=nil)
		{
			app->secondMask=app->firstMask;
			app->firstMask=maskPlatform;
		}
		return maskPlatform;
	}
}

-(CMask*)getMask:(int)nFlags
{
	if ((nFlags & GCMF_PLATFORM) == 0)
	{
		if (mask==nil)
		{
			if (data==nil)
			{
				[self reload];
			}			
			mask = [[CMask alloc] init];
			[mask createMask:self withFlags:nFlags];
			mask->xSpot = xSpot;
			mask->ySpot = ySpot;
		}
		if (app!=nil)
		{
			app->secondMask=app->firstMask;
			app->firstMask=mask;
		}
		return mask;
	}
	else
	{
		if (maskPlatform == nil)
		{
			if (data==nil)
			{
				[self reload];
			}
			maskPlatform = [[CMask alloc] init];
			[maskPlatform createMask:self withFlags:nFlags];
			maskPlatform->xSpot = xSpot;
			maskPlatform->ySpot = ySpot;
		}
		if (app!=nil)
		{
			app->secondMask=app->firstMask;
			app->firstMask=maskPlatform;
		}
		return maskPlatform;
	}
}

-(void)cleanMemory
{
	if (mask!=nil)
	{
		if (app!=nil && mask!=app->firstMask && mask!=app->secondMask)
		{
			[mask release];
			mask=nil;
		}
	}
	if (maskPlatform!=nil)
	{
		if (app!=nil && maskPlatform!=app->firstMask && maskPlatform!=app->secondMask)
		{
			[maskPlatform release];
			maskPlatform=nil;
		}
	}
	if (maskRotation!=nil)
	{
		int n;
		for (n=0; n<[maskRotation size]; n++)
		{
			RotatedMask* pRMask = (RotatedMask*)[maskRotation get:n];
			if (app!=nil && pRMask->mask!=app->firstMask && pRMask->mask!=app->secondMask)
			{
				[pRMask->mask release];
				free(pRMask);
				[maskRotation removeIndex:n];
				n--;
			}
		}
		if ([maskRotation size]==0)
		{
			[maskRotation release];
			maskRotation=nil;
		}
	}
	[self cleanPixelBuffer];
}

-(void)cleanPixelBuffer
{
	if (data!=nil && bCanRelease==YES)
	{
		free(data);
		data=nil;
		for(int i=0; i<[replacedColors size]; ++i)
		{
			ReplacedColor* info = (ReplacedColor*)[replacedColors get:i];
			info->replaced = NO;
		}
	}	
}
-(void)copyImage:(CImage*)image
{
	width=image->width;
	height=image->height;
	xSpot=image->xSpot;
	ySpot=image->ySpot;
	xAP=image->xAP;
	yAP=image->yAP;
	
	if (data!=nil)
	{
		free(data);
		[self deleteTexture];
	}
	data=(unsigned int*)malloc(image->width*image->height*4);

	int n;
	unsigned int* pSrce=image->data;
	unsigned int* pDest=data;
	for (n=width*height; n>0; n--)
	{
		*(pDest++)=*(pSrce++);
	}
}

-(ColorRGBA)getPixelF:(float)x withY:(float)y
{
	float offsetX = fmodf(x+1.0f, width);
	float offsetY = fmodf(y+1.0f, height);

	Vec2i a = Vec2i(x,			y);
	Vec2i b = Vec2i(offsetX,	y);
	Vec2i c = Vec2i(x,			offsetY);
	Vec2i d = Vec2i(offsetX,	offsetY);

	Vec2f fraction = Vec2f(fmodf(x, 1), fmodf(y, 1));

	ColorRGBA pA = [self getPixelRGBA:a.x withY:a.y];
	ColorRGBA pB = [self getPixelRGBA:b.x withY:b.y];
	ColorRGBA pC = [self getPixelRGBA:c.x withY:c.y];
	ColorRGBA pD = [self getPixelRGBA:d.x withY:d.y];

	GradientColor square = GradientColor(pA, pB, pC, pD);
	ColorRGBA resampled = square.getColorAtFraction(fraction.x, fraction.y);
	return resampled;
}


-(void)setPixelF:(ColorRGBA)pixel atX:(int)x andY:(int)y
{
	unsigned int newColor = pixel.getColorAsFormat(format);
	unsigned int pixel4;
	unsigned short pixel2;
	unsigned short* sData = (unsigned short*)data;
	int sWidth = width + (width % 2);
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;

	switch (format)
	{
		case RGBA8888:
		{
			int index = x+y*width;
			pixel4 = data[index];
			data[index] = (pixel4 & 0xFF000000) | newColor;
			break;
		}
		case RGBA4444:
		{
			int index = x+y*sWidth;
			pixel2 = sData[index];
			sData[index] = (pixel2 & 0x000F) | (short)newColor;
			break;
		}
		case RGBA5551:
		{
			int index = x+ y*sWidth;
			pixel2 = sData[index];
			sData[index] = (pixel2 & 0x0001) | (short)newColor;
			break;
		}
		case RGB888:
		{
			unsigned int* index = (unsigned int*)((unsigned char*)data + bLineWidth*y + x*bytesPrPixel);
			pixel4 = *index;
			*index = (pixel4 & 0xFF000000) | newColor;
			break;
		}
		case RGB565:
		{
			int index = x+y*sWidth;
			sData[index] = (short)newColor;
			break;
		}
	}
}



-(void)setPixel:(int)pixel atX:(int)x andY:(int)y
{
	unsigned int newColor = [CImage getReducedColorFromRed:getR(pixel) andGreen:getG(pixel) andBlue:getB(pixel) fromFormat:format];

	unsigned int pixel4;
	unsigned short pixel2;
	unsigned short* sData = (unsigned short*)data;
	int sWidth = width + (width % 2);
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;

	switch (format)
	{
		case RGBA8888:
		{
			int index = x+y*width;
			pixel4 = data[index];
			data[index] = (pixel4 & 0xFF000000) | newColor;
			break;
		}
		case RGBA4444:
		{
			int index = x+y*sWidth;
			pixel2 = sData[index];
			sData[index] = (pixel2 & 0x000F) | (short)newColor;
			break;
		}
		case RGBA5551:
		{
			int index = x+ y*sWidth;
			pixel2 = sData[index];
			sData[index] = (pixel2 & 0x0001) | (short)newColor;
			break;
		}
		case RGB888:
		{
			unsigned int* index = (unsigned int*)((unsigned char*)data + bLineWidth*y + x*bytesPrPixel);
			pixel4 = *index;
			*index = (pixel4 & 0xFF000000) | newColor;
			break;
		}
		case RGB565:
		{
			int index = x+y*sWidth;
			sData[index] = (short)newColor;
			break;
		}
	}
}


-(ColorRGBA)getPixelRGBA:(int)x withY:(int)y
{
	if (data==nil)
	{
		[self reload];
	}
	if (x<0 || x>=width || y<0 || y>=height)
		return 0;

	int pixel,a,r,g,b;
	short spixel;
	float inv;
	switch (format)
	{
		default:
		case RGBA8888:
			pixel = data[y*width+x];
			inv = 1.0f/255.0f;
			a = (pixel >> 24) & 0xFF;
			b = (pixel >> 16) & 0xFF;
			g = (pixel >> 8) & 0xFF;
			r = pixel & 0xFF;
			return ColorRGBA(r*inv, g*inv, b*inv, a*inv);

		case RGB888:
			pixel = *(int*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			inv = 1.0f/255.0f;
			b = (pixel >> 16) & 0xFF;
			g = (pixel >> 8) & 0xFF;
			r = pixel  & 0xFF;
			return ColorRGBA(r*inv, g*inv, b*inv, 1);

		case RGBA4444:
			spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			inv = 1.0f/15.0f;
			r = ((spixel >> 12) & 0xF)*inv;
			g = ((spixel >> 8) & 0xF)*inv;
			b = ((spixel >> 4) & 0xF)*inv;
			a = (spixel & 0xF)*inv;
			return ColorRGBA(r, g, b, a);

		case RGBA5551:
			spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			r = ((spixel >> 11) & 0x1F)*255/31;
			g = ((spixel >> 6) & 0x1F)*255/31;
			b = ((spixel >> 1) & 0x1F)*255/31;
			a = (spixel & 0x01)*255;
			return getABGRPremultiply(a,b,g,r);

		case RGB565:
			spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			r = ((spixel >> 11) & 0x1F)*255/31;
			g = ((spixel >> 5)  & 0x3F)*255/63;
			b = (spixel & 0x1F)*255/31;
			return getABGR(255,b,g,r);
	}
}

-(int)getPixel:(int)x withY:(int)y
{
	if (data==nil)
	{
		[self reload];
	}
	if (x<0 || x>=width || y<0 || y>=height)
		return 0;
		
	int pixel,a,r,g,b;
	short spixel;
	switch (format)
	{
		default:
		case RGBA8888:
			pixel = data[y*width+x];
			a = (pixel >> 24) & 0xFF;
			b = (pixel >> 16) & 0xFF;
			g = (pixel >> 8) & 0xFF;
			r = pixel & 0xFF;
			return getABGRPremultiply(a, b, g, r);
			
		case RGB888:
			pixel = *(int*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			r = (pixel >> 16) & 0xFF;
			g = (pixel >> 8) & 0xFF;
			b = pixel  & 0xFF;
			return getABGR(255,r,g,b);
			
		case RGBA4444:
			spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			r = ((spixel >> 12) & 0xF)*255/15;
			g = ((spixel >> 8) & 0xF)*255/15;
			b = ((spixel >> 4) & 0xF)*255/15;
			a = (spixel & 0xF)*255/15;
			return getABGRPremultiply(a,b,g,r);
			
		case RGBA5551:
			spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			r = ((spixel >> 11) & 0x1F)*255/31;
			g = ((spixel >> 6) & 0x1F)*255/31;
			b = ((spixel >> 1) & 0x1F)*255/31;
			a = (spixel & 0x01)*255;
			return getABGRPremultiply(a,b,g,r);
			
		case RGB565:
			spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
			r = ((spixel >> 11) & 0x1F)*255/31;
			g = ((spixel >> 5)  & 0x3F)*255/63;
			b = (spixel & 0x1F)*255/31;
			return getABGR(255,b,g,r);
	}
}
//Uploads the image to the graphics card as a texture only if it wasn't already uploaded.
-(NSUInteger)uploadTexture
{
	//If the texture is already uploaded, ignore the call
	if(textureId != -1 || isUploading)
		return 0;
	
	isUploading = YES;
	
	[self reload];
	size_t newSize = 0;
	openGLmode = GL_RGBA;
	openGLformat = GL_UNSIGNED_BYTE;
	unsigned int * texData = nil;
	
	[self calculateTextureSize];

	glGenTextures(1, &textureId);
	glBindTexture(GL_TEXTURE_2D, textureId);		//Start working with our new texture id
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapS);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapT);
	[self updateFilter];
	
	switch (format)
	{
		default:
		case RGBA8888:
			openGLmode = GL_RGBA;
			openGLformat = GL_UNSIGNED_BYTE;
			break;
		case RGB888:
			openGLmode = GL_RGB;
			openGLformat = GL_UNSIGNED_BYTE;
			break;
		case RGBA4444:
			openGLmode = GL_RGBA;
			openGLformat = GL_UNSIGNED_SHORT_4_4_4_4;
			break;
		case RGBA5551:
			openGLmode = GL_RGBA;
			openGLformat = GL_UNSIGNED_SHORT_5_5_5_1;
			break;
		case RGB565:
			openGLmode = GL_RGB;
			openGLformat = GL_UNSIGNED_SHORT_5_6_5;
			break;
	}
	
	int pixels = textureWidth*textureHeight;
	newSize = pixels*bytesPrPixel;
	
	if(textureWidth == width && textureHeight == height)
	{
		//Texture data can be directly transfered to the graphics card without copying
		glTexImage2D(GL_TEXTURE_2D, 0, openGLmode, textureWidth, textureHeight, 0, openGLmode, openGLformat, data);
	}
	else
	{
		//Copy to intermediate texture is required		
		texData = (unsigned int*)malloc(newSize);
		memset(texData, 0, newSize);
		
		lineWidth = width*bytesPrPixel;
		bLineWidth = (lineWidth+3) & ~3;
		
		for(int y=0; y<height; ++y)
			memcpy((char*)texData + textureWidth*y*bytesPrPixel, (char*)data + bLineWidth*y, lineWidth);
		
		glTexImage2D(GL_TEXTURE_2D, 0, openGLmode, textureWidth, textureHeight, 0, openGLmode, openGLformat, texData);
		free(texData);
	}

	//Release the temporary texture data
	[self cleanPixelBuffer];
	isUploading = NO;

	[self updateTextureMatrix];
	return newSize;
}


//Reupload the image data as a texture of the same size and format.
-(NSUInteger)reUploadTexture
{
	if(textureId == -1 || isUploading)
		return [self uploadTexture];
	
	isUploading = YES;
	
	//Reload if data source is missing
	[self reload];
	glActiveTexture(GL_TEXTURE0);
	glBindTexture(GL_TEXTURE_2D, textureId);
	[self updateFilter];
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapS);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapT);
	
	int pixels = textureWidth*textureHeight;
	size_t newSize = pixels*bytesPrPixel;
	unsigned int * texData = nil;

	if(textureWidth == width && textureHeight == height)
	{
		//Texture data can be directly transfered to the graphics card without copying
		glTexImage2D(GL_TEXTURE_2D, 0, openGLmode, textureWidth, textureHeight, 0, openGLmode, openGLformat, data);
	}
	else
	{
		//Copy to intermediate texture is required		
		texData = (unsigned int*)malloc(newSize);
		memset(texData, 0, newSize);
		
		lineWidth = width*bytesPrPixel;
		bLineWidth = (lineWidth+3) & ~3;
		
		for(int y=0; y<height; ++y)
			memcpy((char*)texData + textureWidth*y*bytesPrPixel, (char*)data + bLineWidth*y, lineWidth);
		
		glTexImage2D(GL_TEXTURE_2D, 0, openGLmode, textureWidth, textureHeight, 0, openGLmode, openGLformat, texData);
		free(texData);
	}
	isUploading = NO;
	return 0;
}

//Method for stretching an image to the full size of the texture to make it easily tileable with less slowdown during rendering
-(void)expectTilableImage
{
	if(textureId == -1)
		[self calculateTextureSize];

	if(wrapS != GL_REPEAT || wrapT != GL_REPEAT)
	{
		wrapS = GL_REPEAT;
		wrapT = GL_REPEAT;
		glBindTexture(GL_TEXTURE_2D, textureId);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, wrapS);
		glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, wrapT);
	}

	if(width != textureWidth || height != textureHeight)
	{
		[self reload];
		CImage* copy = [self copy];

		int oldWidth = width;
		int oldHeight = height;
		width = textureWidth;
		height = textureHeight;

		free(data);
		data = (unsigned int*)calloc(textureWidth*textureHeight*bytesPrPixel+4, sizeof(char));

		for(int y=0; y<textureHeight; ++y)
		{
			for(int x=0; x<textureWidth; ++x)
			{
				float fX = (x * oldWidth)/(float)textureWidth;
				float fY = (y * oldHeight)/(float)textureHeight;
				ColorRGBA pixel = [copy getPixelF:fX withY:fY];
				[self setPixelF:pixel atX:x andY:y];
			}
		}

		[self updateTextureMatrix];

		[copy release];
		[self reUploadTexture];
		//[self generateMipMaps];
	}
}

-(void)replaceColors
{
	[self reload];
	BOOL reupload = NO;
	for(int i=0; i<[replacedColors size]; ++i)
	{
		ReplacedColor* info = (ReplacedColor*)[replacedColors get:i];
		if(!info->replaced)
		{
			[self replaceColor:info];
			reupload = YES;
		}
	}
	if(reupload)
		[self reUploadTexture];
}

-(void)unpremultiply
{
	if (data==nil)
	{
		[self reload];
	}

	int pixel;
	short spixel;
	float inv;
	unsigned short pixel2;
	unsigned short* sData = (unsigned short*)data;
	int sWidth = width + (width % 2);

	switch (format)
	{
		//These formats doesn't have a practical alpha channel
		case RGBA5551:
		case RGB888:
		case RGB565:
			return;

		case RGBA8888:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					pixel = data[y*width+x];
					inv = 1.0f/255.0f;
					ColorRGBA color = ColorRGBA((pixel & 0xFF)*inv, ((pixel >> 8) & 0xFF)*inv, ((pixel >> 16) & 0xFF)*inv, ((pixel >> 24) & 0xFF)*inv);
					color.unpremultiply();
					unsigned int newColor = color.getRGBA8888();
					unsigned int pixel4;
					lineWidth = width*bytesPrPixel;
					bLineWidth = (lineWidth+3) & ~3;
					int index = x+y*width;
					pixel4 = data[index];
					data[index] = (pixel4 & 0xFF000000) | newColor;
				}
			}
			break;
		}
		case RGBA4444:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					spixel = *(short*)((char*)data + bLineWidth*y + x*bytesPrPixel);
					inv = 1.0f/15.0f;
					ColorRGBA color = ColorRGBA(((spixel >> 12) & 0xF)*inv, ((spixel >> 8) & 0xF)*inv, ((spixel >> 4) & 0xF)*inv, (spixel & 0xF)*inv);
					color.unpremultiply();
					unsigned int newColor = color.getRGBA4444();
					int index = x+y*sWidth;
					pixel2 = sData[index];
					sData[index] = (pixel2 & 0x000F) | (short)newColor;
				}
			}
			break;
		}
	}
}

-(void)replaceColor:(ReplacedColor*)info
{
	info->replaced = YES;
	unsigned int colorToReplace = [CImage getReducedColorFromRed:info->oR andGreen:info->oG andBlue:info->oB fromFormat:format];
	unsigned int newColor = [CImage getReducedColorFromRed:info->rR andGreen:info->rG andBlue:info->rB fromFormat:format];

	unsigned int pixel4;
	unsigned short pixel2;
	unsigned short* sData = (unsigned short*)data;
	int sWidth = width + (width % 2);
	lineWidth = width*bytesPrPixel;
	bLineWidth = (lineWidth+3) & ~3;
	
	switch (format)
	{
		case RGBA8888:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					int index = x+y*width;
					pixel4 = data[index];
					
					if ((pixel4 & 0x00FFFFFF) == colorToReplace)
					{
						data[index] = (pixel4 & 0xFF000000) | newColor;
					}
				}
			}
			break;
		}
		case RGBA4444:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					int index = x+y*sWidth;
					pixel2 = sData[index];
					
					if ((pixel2 & 0xFFF0) == colorToReplace)
					{
						sData[index] = (pixel2 & 0x000F) | (short)newColor;
					}
				}
			}
			break;
		}
		case RGBA5551:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					int index = x+ y*sWidth;
					pixel2 = sData[index];
					if ((pixel2 & 0xFFFE) == colorToReplace)
					{
						sData[index] = (pixel2 & 0x0001) | (short)newColor;
					}
				}
			}
			break;
		}
		case RGB888:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					unsigned int* index = (unsigned int*)((unsigned char*)data + bLineWidth*y + x*bytesPrPixel);
					pixel4 = *index;
					if ((pixel4 & 0x00FFFFFF) == colorToReplace)
					{
						*index = (pixel4 & 0xFF000000) | newColor;
					}
				}
			}
			break;
		}	
		case RGB565:
		{
			for(int y=0; y<height; ++y)
			{
				for(int x=0; x<width; ++x)
				{
					int index = x+y*sWidth;
					pixel2 = sData[index];
					if (pixel2 == colorToReplace)
					{
						sData[index] = (short)newColor;
					}
				}
			}
			break;
		}
	}
}

+(unsigned int)getReducedColorFromRed:(unsigned int)r andGreen:(unsigned int)g andBlue:(unsigned int)b fromFormat:(int)format
{
	//Returns the color in the given format (with the alpha-part always 0)
	switch (format)
	{
		case RGBA8888:
		case RGB888:
			return (b<<16|g<<8|r);
		case RGBA4444:
		{
			r = (unsigned int)((r*15)/255.0+0.49999);
			g = (unsigned int)((g*15)/255.0+0.49999);
			b = (unsigned int)((b*15)/255.0+0.49999);
			return (r<<12|g<<8|b<<4);
		}
		case RGBA5551:
		{
			r = (unsigned int)((r*31)/255.0+0.49999);
			g = (unsigned int)((g*31)/255.0+0.49999);
			b = (unsigned int)((b*31)/255.0+0.49999);
			return (r<<11|g<<6|b<<1);
		}
		case RGB565:
		{
			r = (unsigned int)((r*31)/255.0+0.49999);
			g = (unsigned int)((g*63)/255.0+0.49999);
			b = (unsigned int)((b*31)/255.0+0.49999);
			return (r<<11|g<<5|b);
		}
	}
	return 0;
}


-(int)deleteTexture
{	
	if(textureId != -1)
	{
		glDeleteTextures(1, &textureId);
		textureId = -1;
		return textureWidth*textureHeight*4;
	}
	coordsAreSwapped = NO;
	return 0;
}

+(int)getFormatByteSize:(int)format
{
	switch(format)
	{
		case RGBA8888:	return 4;
		case RGB888:	return 3;   
		case RGBA4444:
		case RGBA5551:
		case RGB565:	return 2;
		default: return 0;
	}
}

//If the texture doesn't have mip-maps they will be generated
//for much faster rendering and with fewer artifacts at the cost of memory.
-(void)generateMipMaps
{
	if(hasMipMaps)
		return;
	glBindTexture(GL_TEXTURE_2D, textureId);
	glHint(GL_GENERATE_MIPMAP_HINT, GL_NICEST);
	glGenerateMipmap(GL_TEXTURE_2D);
	hasMipMaps = YES;
	[self updateFilter];
}

-(NSString*)description
{
	return [NSString stringWithFormat:@"Tex[%i,%i] h:%i", width, height, handle];
}


@end
