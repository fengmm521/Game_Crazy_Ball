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
// CEXTLOADER: Chargement des extensions
//
//----------------------------------------------------------------------------------
#import "CExtLoader.h"
#import "CRunApp.h"
#import "CRunExtension.h"
#import "CExtLoad.h"
#import "CFile.h"

@implementation CExtLoader

-(id)initWithApp:(CRunApp*)app
{
	runApp=app;
	return self;
}
-(void)dealloc
{
	if (extensions!=nil)
	{
		free(extensions);
	}
	if (numOfConditions!=nil)
	{
		free(numOfConditions);
	}
	[super dealloc];
}
-(void)loadList 
{
	int extCount=[runApp->file readAShort];
	extMaxHandles=[runApp->file readAShort];
	
	extensions=(CExtLoad**)calloc(extMaxHandles, sizeof(CExtLoad*));
	numOfConditions=(short*)calloc(extMaxHandles, sizeof(short));
	int n;
	
	for (n=0; n<extCount; n++)
	{
	    CExtLoad* e=[[CExtLoad alloc] init];
	    [e loadInfo:runApp->file];
	    extensions[e->handle]=nil;
        
        CRunExtension* ext=[e loadRunObject];
        if (ext!=nil)
        {
            extensions[e->handle]=e;	    
            numOfConditions[e->handle]=(short)[ext getNumberOfConditions];
            [ext release];
        }
	}
}
-(CRunExtension*)loadRunObject:(int)type
{
	type-=KPX_BASE;
	CRunExtension* ext=nil;
    if (type >= 0 && type<extMaxHandles && extensions[type]!=nil)
    {
        ext=[extensions[type] loadRunObject];
    }
	return ext;
}  
-(int)getNumberOfConditions:(int)type
{
	type-=KPX_BASE;
    if (type<extMaxHandles)
    {
        return numOfConditions[type];
    }
    return 0;
}

@end
