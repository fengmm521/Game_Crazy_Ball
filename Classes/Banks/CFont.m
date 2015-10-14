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
// CFONT : une fonte
//
//----------------------------------------------------------------------------------
#import "CFont.h"
#import "CFile.h"
#import "CFontInfo.h"

@implementation CFont

-(void)dealloc
{
	[lfFaceName release];
	if (font!=nil)
	{
		[font release];
	}
	[super dealloc];
}
-(void)loadHandle:(CFile*)file
{
	handle = (short)[file readAInt];
	if (file->bUnicode==false)
	{
		[file skipBytes:0x48];
	}
	else
	{
		[file skipBytes:0x68];
	}
}
-(void)load:(CFile*)file
{
	handle = (short)[file readAInt];
	[file skipBytes:12];		    // Trois DWORD d'entete
	
	NSUInteger debut = [file getFilePointer];
	lfHeight = [file readAInt];
	if (lfHeight < 0)
	{
		lfHeight = -lfHeight;
	}
	lfWidth = [file readAInt];
	lfEscapement = [file readAInt];
	lfOrientation = [file readAInt];
	lfWeight = [file readAInt];
	lfItalic = [file readAByte];
	lfUnderline = [file readAByte];
	lfStrikeOut = [file readAByte];
	lfCharSet = [file readAByte];
	lfOutPrecision = [file readAByte];
	lfClipPrecision = [file readAByte];
	lfQuality = [file readAByte];
	lfPitchAndFamily = [file readAByte];
	lfFaceName = [file readAString];
	
	// Positionne a la fin
	if (file->bUnicode==false)
	{
		[file seek:debut+0x3C];
	}
	else
	{
		[file seek:debut+0x5C];
	}
}
//public Font createFont() FRA:
-(CFontInfo*)getFontInfo
{
	CFontInfo* info = [[CFontInfo alloc] init];
	info->lfHeight = lfHeight;
	info->lfWeight = lfWeight;
	info->lfItalic = lfItalic;
	info->lfUnderline = lfUnderline;
	info->lfStrikeOut = lfStrikeOut;
	info->lfFaceName = [[NSString alloc] initWithString:lfFaceName];
	return info;
}
+(CFont*)createFromFontInfo:(CFontInfo*)info
{
	CFont* font = [[CFont alloc] init];
	font->lfHeight = info->lfHeight;
	font->lfWeight = info->lfWeight;
	font->lfItalic = info->lfItalic;
	font->lfUnderline = info->lfUnderline;
	font->lfStrikeOut = info->lfStrikeOut;
	font->lfFaceName = [[NSString alloc] initWithString:info->lfFaceName];
	return font;
}
-(void)createDefaultFont
{
	lfHeight = 12;
	lfWeight = 400;
	lfItalic = 0;
	lfUnderline = 0;
	lfStrikeOut = 0;
	lfFaceName = @"Arial";
}
-(UIFont*)createFont
{
	if (font!=nil)
	{
		return font;
	}

	if ([lfFaceName compare:@"Helvetica"]==0)
	{
		if (lfWeight>=600)
		{
			font=[UIFont boldSystemFontOfSize:lfHeight];
		}
		else if (lfItalic!=0)
		{
			font=[UIFont italicSystemFontOfSize:lfHeight];
		}
		else
		{
			font=[UIFont systemFontOfSize:lfHeight];
		}
		[font retain];
		return font;
	}
	
/*	NSArray* fNames=[UIFont familyNames];	
	NSString* ffName;
	int n;
	for (n=0; n<[fNames count]; n++)
	{
		NSString* fName=[fNames objectAtIndex:n];
		NSArray* ffNames=[UIFont fontNamesForFamilyName:fName];
		int m;
		for (m=0; m<[ffNames count]; m++)
		{
			ffName=[ffNames objectAtIndex:m];
		}
	}	
*/
	NSString* name;
	if (lfWeight>=600 && lfItalic!=0)
	{
		name=[lfFaceName stringByAppendingString:@"-BoldItalic"];
	}
	else if (lfWeight>=600)
	{
		name=[lfFaceName stringByAppendingString:@"-Bold"];
	}
	else if (lfItalic!=0)
	{
		name=[lfFaceName stringByAppendingString:@"-Italic"];
	}
	else 
	{
		name=[NSString stringWithString:lfFaceName];
	}
	font=[UIFont fontWithName:name size:lfHeight];
	if (font==nil)
	{
		if (lfWeight>=600)
		{
			font=[UIFont boldSystemFontOfSize:lfHeight];
		}
		else if (lfItalic!=0)
		{
			font=[UIFont italicSystemFontOfSize:lfHeight];
		}
		else
		{
			font=[UIFont systemFontOfSize:lfHeight];
		}
	}
	[font retain];
	return font;
}
@end
