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
// CMOVEDEFPATH : donnÈes du mouvement path
//
//----------------------------------------------------------------------------------
#import "CMoveDefPath.h"
#import "CFile.h"
#import "CPathStep.h"

@implementation CMoveDefPath

-(void)dealloc
{
	for (int n=0; n<mtNumber; n++)
		[steps[n] release];
	
	free(steps);	
	[super dealloc];
}
-(void)load:(CFile*)file withLength:(int)length
{
	mtNumber=[file readAShort];
	mtMinSpeed=[file readAShort];
	mtMaxSpeed=[file readAShort];
	mtLoop=[file readAByte];	
	mtRepos=[file readAByte];
	mtReverse=[file readAByte];
	[file skipBytes:1];
	
	steps=(CPathStep**)malloc(mtNumber*sizeof(CPathStep*));
	int n, next;
	NSUInteger debut;
	for (n=0; n<mtNumber; n++)
	{
		debut=[file getFilePointer];
		steps[n]=[[CPathStep alloc] init];
		[file skipBytes:1];		// prev
		next=[file readUnsignedByte];
		[steps[n] load:file];
		[file seek:debut+next];
	}
}

@end
