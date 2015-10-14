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
// CDEFTEXTS : liste de textes
//
//----------------------------------------------------------------------------------
#import "CDefTexts.h"
#import "CFile.h"
#import "CDefText.h"

@implementation CDefTexts

-(void)dealloc
{
	int n;
	for (n=0; n<otNumberOfText; n++)
	{
		[otTexts[n] release];
	}
	free(otTexts);
	
	[super dealloc];
}
-(void)load:(CFile*)file
{
	NSUInteger debut = [file getFilePointer];
	[file skipBytes:4];          // Size
	otCx = [file readAInt];
	otCy = [file readAInt];
	otNumberOfText = [file readAInt];
	
	otTexts = (CDefText**)calloc(otNumberOfText, sizeof(CDefText*));
	int* offsets = (int*)malloc(otNumberOfText*sizeof(int));
	int n;
	for (n = 0; n < otNumberOfText; n++)
	{
		offsets[n] = [file readAInt];
	}
	for (n = 0; n < otNumberOfText; n++)
	{
		otTexts[n] = [[CDefText alloc] init];
		[file seek:debut + offsets[n]];
		[otTexts[n] load:file];
	}
	free(offsets);
}
-(void)enumElements:(id)enumImages withFont:(id)enumFonts
{
	int n;
	for (n = 0; n < otNumberOfText; n++)
	{
		[otTexts[n] enumElements:enumImages withFont:enumFonts];
	}
}

@end
