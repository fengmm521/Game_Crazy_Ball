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
// CDEF : DonnÈes d'un objet normal
//
//----------------------------------------------------------------------------------
#import "CDefValues.h"
#import "CFile.h"

@implementation CDefValues

-(id)init
{
	values=nil;
	return self;
}
-(void)dealloc
{
	if (values!=nil)
	{
		free(values);
	}
	[super dealloc];
}
-(void)load:(CFile*)file
{
	nValues=[file readAShort];
	if (nValues>0)
	{		
		values=(int*)malloc(nValues*sizeof(int));
		int n;
		for (n=0; n<nValues; n++)
		{
			values[n]=[file readAInt];
		}
    }
}

@end
