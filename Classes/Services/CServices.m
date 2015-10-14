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
// CSERVICES : Routines utiles diverses
//
//----------------------------------------------------------------------------------
#import "CServices.h"
#import "CRect.h"
#import "CFont.h"
#import "CBitmap.h"
#import "CRenderToTexture.h"
#import "CSprite.h"

int* xPos=nil;
int* yPos=nil;
int* length=nil;
int* pChar=nil;

// Fonctions C
double maxd(double a, double b)
{
	return ((a>b) ? a : b);
}
double mind(double a, double b)
{
	return ((a<b) ? a : b);
}

double absDouble(double v)
{
	if (v>=0.0)
	{
		return v;
	}
	return -v;
}
int getR(int rgb)
{
	return (rgb>>16)&0xFF;
}
int getG(int rgb)
{
	return (rgb>>8)&0xFF;
}
int getB(int rgb)
{
	return (rgb&0xFF);
}

int getRGB(int r, int g, int b)
{
	return (r&0xFF)<<16 | (g&0xFF)<<8 | (b&0xFF);
}

int getRGBA(int r, int g, int b, int a)
{
	return (r&0xFF)<<24 | (g&0xFF)<<16 | (b&0xFF)<<8 | (a&0xFF);
}

int getABGR(int a, int b, int g, int r)
{
	return (a&0xFF)<<24 | (b&0xFF)<<16 | (g&0xFF)<<8 | (r&0xFF);
}

int getABGR(ColorRGBA color)
{
	int r = (int)(color.r*255);
	int g = (int)(color.g*255);
	int b = (int)(color.b*255);
	int a = (int)(color.a*255);
	return (a&0xFF)<<24 | (b&0xFF)<<16 | (g&0xFF)<<8 | (r&0xFF);
}

int getABGRPremultiply(int a, int b, int g, int r)
{
	float al = a/255.0f;
	r *= al;
	g *= al;
	b *= al;
	return (a&0xFF)<<24 | (b&0xFF)<<16 | (g&0xFF)<<8 | (r&0xFF);
}

int getARGB(int a, int r, int g, int b)
{
	return (a&0xFF)<<24 | (r&0xFF)<<16 | (g&0xFF)<<8 | (b&0xFF);
}
int getARGB(ColorRGBA color)
{
	int r = (int)(color.r*255);
	int g = (int)(color.g*255);
	int b = (int)(color.b*255);
	int a = (int)(color.a*255);
	return (a&0xFF)<<24 | (r&0xFF)<<16 | (g&0xFF)<<8 | (b&0xFF);
}

unsigned int BGRtoARGB(int color)
{
	unsigned char b = (color & 0x00FF0000) >> 16;
	unsigned char g = (color & 0x0000FF00) >> 8;
	unsigned char r = (color & 0x000000FF);
	return 0xFF000000 | r << 16 | g << 8 | b;
}

int ABGRtoRGB(int abgr)
{
	unsigned char b = (abgr & 0x00FF0000) >> 16;
	unsigned char g = (abgr & 0x0000FF00) >> 8;
	unsigned char r = (abgr & 0x000000FF);
	return r << 16 | g << 8 | b;
}
int ARGBtoBGR(int argb)
{
	unsigned char r = (argb & 0x00FF0000) >> 16;
	unsigned char g = (argb & 0x0000FF00) >> 8;
	unsigned char b = (argb & 0x000000FF);
	return b << 16 | g << 8 | r;
}

int clamp(int val, int a, int b)
{
	return MIN( MAX(val, a), b);
}

double clampd(double val, double a, double b)
{
	return mind( maxd(val, a), b);
}

void setRGBFillColor(CGContextRef ctx, int rgb)
{
	CGFloat r=(CGFloat)(((rgb>>16)&255))/255.0;
	CGFloat g=(CGFloat)(((rgb>>8)&255))/255.0;
	CGFloat b=(CGFloat)(rgb&255)/255.0;
	CGContextSetRGBFillColor(ctx, r, g, b, 1.0);
}
void setRGBStrokeColor(CGContextRef ctx, int rgb)
{
	CGFloat r=(CGFloat)(((rgb>>16)&255))/255.0;
	CGFloat g=(CGFloat)(((rgb>>8)&255))/255.0;
	CGFloat b=(CGFloat)(rgb&255)/255.0;
	CGContextSetRGBStrokeColor(ctx, r, g, b, 1.0);
}
UIColor* getUIColor(int rgb)
{
	CGFloat b=(CGFloat)(((rgb>>16)&255))/255.0;
	CGFloat g=(CGFloat)(((rgb>>8)&255))/255.0;
	CGFloat r=(CGFloat)(rgb&255)/255.0;
	return [UIColor colorWithRed:r green:g blue:b alpha:1.0];
}
void drawLine(CGContextRef context, int x1, int y1, int x2, int y2)
{
	CGContextMoveToPoint(context, x1, y1);
	CGContextAddLineToPoint(context, x2, y2);
	CGContextStrokePath(context);
}
int HIWORD(int ul)
{
	return (ul >> 16)&0x0000FFFF;
}
int LOWORD(int ul)
{
	return ul & 0x0000FFFF;
}

int POSX(int ul)
{
	return (ul << 16) >> 16;
}
int POSY(int ul)
{
	return ul >> 16;
}

int MAKELONG(int lo, int hi)
{
	return (hi << 16) | (lo & 0xFFFF);
}
int swapRGB(int rgb)
{
	int r=(rgb>>16)&0xFF;
	int g=(rgb>>8)&0xFF;
	int b=rgb&0xFF;
	return b<<16|g<<8|r;
}

int strUnicharLen(unichar* str)
{
	int index=0;
	unichar b;
	do{
		b = str[index++];
	} while (b != 0);
	return index-1;
}

@implementation CServices

+(int)drawText:(CBitmap*)bitmap withString:(NSString*)s andFlags:(short)flags andRect:(CRect)rc andColor:(int)rgb andFont:(CFont*)font andEffect:(int)effect andEffectParam:(int)effectParam
{
	// Empty string?
	if ([s length]==0)
		return 0;
    
	// Create font
	UIFont* f=[font createFont];
    
	CGContextRef context = nil;	//Was uninitialized
	if (bitmap!=nil && bitmap->context != nil)
	{
		UIGraphicsPushContext(bitmap->context);
		context=bitmap->context;
		setRGBFillColor(context, rgb);	//Was uninitialized before, could be random value
		setRGBStrokeColor(context, rgb);
	}
    
	//Input rect size
	int rectWidth = (int)rc.width();
	int rectHeight = (int)rc.height();

	CGSize size;
	CGSize rectSize;

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
#ifdef __IPHONE_8_0
	NSMutableParagraphStyle* paragraphStyle = [[[NSParagraphStyle defaultParagraphStyle] mutableCopy] autorelease];
	paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
	if ([s respondsToSelector:@selector(boundingRectWithSize:options:attributes:context:)])
	{
		NSString* space = @" ";
		if([space respondsToSelector:@selector(sizeWithAttributes:)])
			size = [space sizeWithAttributes:@{NSFontAttributeName:f}];
		else
			size = [s sizeWithFont:f constrainedToSize:CGSizeMake(rectWidth, CGFLOAT_MAX) lineBreakMode:0];

		rectSize = [s boundingRectWithSize:CGSizeMake(rectWidth, CGFLOAT_MAX) options:NSStringDrawingUsesLineFragmentOrigin attributes:@{NSFontAttributeName:f, NSParagraphStyleAttributeName:paragraphStyle} context:nil].size;
	}
	else {

		size=[@" " sizeWithFont:f];
		rectSize = [s sizeWithFont:f constrainedToSize:CGSizeMake(rectWidth, CGFLOAT_MAX) lineBreakMode:0];

	}
#else
	size=[@" " sizeWithFont:f];
	rectSize = [s sizeWithFont:f constrainedToSize:CGSizeMake(rectWidth, CGFLOAT_MAX) lineBreakMode:0];
#endif
#pragma clang diagnostic pop

	int hLine=size.height;
	int spaceWidth = size.width;
	if ([s length] == 0)
	{
        rc.right=rc.left+spaceWidth;
        rc.bottom=rc.top+hLine;
        return hLine;
	}
    
	//Horizontal alignment
	int hAlignment = 0;
	if ((flags & 0x0001) != 0)	//DT_CENTER
		hAlignment = 1;
	else if ((flags & 0x0002) != 0) //DT_RIGHT
		hAlignment = 2;


	//Vertical alignment
	int y = (int)rc.top;
	if ((flags & DT_VCENTER) != 0)
		y = (rc.bottom + rc.top) / 2 - rectSize.height / 2;
	else if ((flags & DT_BOTTOM) != 0)
		y = rc.bottom - rectSize.height;
    
	//Only draw if there is a destination bitmap
	if (bitmap!=nil)
	{
#ifdef __IPHONE_8_0
		paragraphStyle.alignment = hAlignment;
		UIColor* color = [UIColor colorWithRed:getR(rgb)/255.0f green:getG(rgb)/255.0f blue:getB(rgb)/255.0f alpha:1];

		if([s respondsToSelector:@selector(drawWithRect:options:attributes:context:)])
		{
			[s drawWithRect:CGRectMake(rc.left, y, rectWidth, MAX(rectHeight, rectSize.height))
					options:NSStringDrawingUsesDeviceMetrics|NSStringDrawingUsesLineFragmentOrigin
				 attributes:@{NSFontAttributeName:f, NSParagraphStyleAttributeName:paragraphStyle, NSForegroundColorAttributeName:color}
					context:nil];
		}
		else
		{
#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"
			[s drawInRect:CGRectMake(rc.left, y, rectWidth, MAX(rectHeight, rectSize.height)) withFont:f lineBreakMode:0 alignment:hAlignment];
#pragma clang diagnostic pop
		}
#else
		[s drawInRect:CGRectMake(rc.left, y, rectWidth, MAX(rectHeight, rectSize.height)) withFont:f lineBreakMode:0 alignment:hAlignment];
#endif
		UIGraphicsPopContext();
	}
    
	//Returns the bottom line of the text with the given vertical alignment.
	return y+rectSize.height;
}

+(int)indexOf:(NSString*)s withChar:(unichar)c startingAt:(int)start
{
	NSInteger l=[s length];
	int p;
	for (p=start; p<l; p++)
	{
		if ([s characterAtIndex:p]==c)
		{
			return p;
		}
	}
	return -1;			
}
+(NSString*)intToString:(int)v withFlags:(int)flags
{
	NSString* s=[NSString stringWithFormat:@"%i", v];
	if ((flags&CPTDISPFLAG_INTNDIGITS)==0)
	{
		[s retain];
		return s;
	}
	int nDigits=flags&CPTDISPFLAG_INTNDIGITS;
	if ([s length]>nDigits)
	{
		s=[s substringToIndex:nDigits];
		[s retain];
		return s;
	}
	while([s length]<nDigits)
	{
		s=[@"0" stringByAppendingString:s];
	}
	[s retain];
	return s;
}
+(NSString*)doubleToString:(double)v withFlags:(int)flags
{
	NSString* s;
	
	if ((flags&CPTDISPFLAG_FLOAT_FORMAT)==0)
	{
		s=[[NSString alloc] initWithFormat:@"%g", v];
	}
	else
	{
		BOOL bRemoveTrailingZeros=NO;
		int nDigits=((flags&CPTDISPFLAG_FLOATNDIGITS)>>CPTDISPFLAG_FLOATNDIGITS_SHIFT)+1;
		int nDecimals=-1;
		if ((flags&CPTDISPFLAG_FLOAT_USEDECIMALS)!=0)
			nDecimals=((flags&CPTDISPFLAG_FLOATNDECIMALS)>>CPTDISPFLAG_FLOATNDECIMALS_SHIFT);
		else if (v>-1.0 & v<1.0)
		{
			nDecimals=nDigits;
			bRemoveTrailingZeros=YES;
		}
		
		NSString* formatFlags = @"";
		NSString* formatWidth = @"";
		NSString* formatPrecision = @"";
		NSString* formatType = @"g";
		
		if ((flags&CPTDISPFLAG_FLOAT_PADD)!=0)
		{
			formatFlags = @"0";
			if(nDecimals > 0)
				++nDigits;
			formatWidth = [NSString stringWithFormat:@"%i", nDigits];
		}
		
		if (nDecimals>=0)
		{
			formatPrecision = [NSString stringWithFormat:@".%i", nDecimals];
			formatType = @"f";
		}
				
		NSString* format = [NSString stringWithFormat:@"%%%@%@%@%@", formatFlags, formatWidth, formatPrecision, formatType];
		s=[[NSString alloc] initWithFormat:format, v];
	}
	return s;
}

+(UIImage *)imageWithImage:(UIImage *)image scaledToSize:(CGSize)newSize
{
    UIGraphicsBeginImageContext(newSize);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    UIGraphicsEndImageContext();
    return newImage;
}

+(CGRect)CGRectFromSprite:(CSprite*)sprite
{
	return CGRectMake(sprite->sprX1, sprite->sprY1, sprite->sprX2 - sprite->sprX1, sprite->sprY2 - sprite->sprY1);
}

@end





@implementation TouchEventWrapper

-(id)initWithTouches:(NSSet*)touchSet andEvent:(UIEvent*)touchEvent
{
	self = [super init];
	if(self)
	{
		touches = [touchSet retain];
		event = [touchEvent retain];
	}
	return self;
}

-(void)dealloc
{
	[touches release];
	[event release];
	[super dealloc];
}

@end


