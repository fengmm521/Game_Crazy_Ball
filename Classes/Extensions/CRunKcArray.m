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
// CRunKcArray: array object
//
//----------------------------------------------------------------------------------
#import "CRunKcArray.h"
#import "CFile.h"
#import "CRun.h"
#import "CBitmap.h"
#import "CServices.h"
#import "CArrayList.h"
#import "CObject.h"
#import "CExtension.h"
#import "COIList.h"
#import "CObjInfo.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CValue.h"
#import "MediaPlayer/MediaPlayer.h"
#import "CRunApp.h"
#import "MainViewController.h"

@implementation CRunKcArray

-(int)getNumberOfConditions
{
	return 3;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	CRun* rhPtr = ho->hoAdRunHeader;       
	
 	int lDimensionX = [file readAInt];
	int lDimensionY = [file readAInt];
	int lDimensionZ = [file readAInt];
	int lFlags = [file readAInt];
	
	KcArrayCGlobalDataList* pData = nil;
	if ((lFlags & ARRAY_GLOBAL) != 0)
	{
		CExtStorage* pExtData = [rhPtr getStorage:ho->hoIdentifier];
		if (pExtData == nil) //first global object of this type
		{
			pArray = [[KcArrayData alloc] initWithFlags:lFlags withX:lDimensionX andY:lDimensionY andZ:lDimensionZ];
			pData = [[KcArrayCGlobalDataList alloc] init];
			[pData AddObject:self];
			[rhPtr addStorage:pData withID:ho->hoIdentifier];
		}
		else
		{
			pData = (KcArrayCGlobalDataList*)pExtData;
			KcArrayData* found = [pData FindObject:ho->hoOiList->oilName];
			if (found != nil) //found array object of same name
			{
				pArray = found; //share data
			}
			else
			{
				pArray = [[KcArrayData alloc] initWithFlags:lFlags withX:lDimensionX andY:lDimensionY andZ:lDimensionZ];
				[pData AddObject:self];
			}
		}             
	}       
	else
	{
		pArray = [[KcArrayData alloc] initWithFlags:lFlags withX:lDimensionX andY:lDimensionY andZ:lDimensionZ];
	}
    
	return YES;
}
-(int)handleRunObject
{
	return REFLAG_ONESHOT;  
}

-(void)destroyRunObject:(BOOL)bFast
{
	if ((pArray->lFlags&ARRAY_GLOBAL)==0)
	{
		[pArray release];
		pArray=nil;
	}
}

// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_INDEXAEND:
			return [self EndIndexA];
		case CND_INDEXBEND:
			return [self EndIndexB];
		case CND_INDEXCEND:
			return [self EndIndexC];
	}        
	return NO;
}
-(BOOL)EndIndexA
{
	if (pArray->lIndexA >= pArray->lDimensionX - 1)
	{
		return YES;
	}
	return NO;
}

-(BOOL)EndIndexB
{
	if (pArray->lIndexB >= pArray->lDimensionY - 1)
	{
		return YES;
	}
	return NO;
}        
-(BOOL)EndIndexC
{        
	if (pArray->lIndexC >= pArray->lDimensionZ - 1)
	{
		return YES;
	}
	return NO;
}   


// Actions
// -------------------------------------------------
-(void)loadArray:(NSString*)fileName
{
	NSData* myData = [rh->rhApp loadResourceData:fileName];
    
    if (myData != nil && [myData length]!=0)
    {
        do 
        {
            CFile* file=[[CFile alloc] initWithNSDataNoRelease:myData];
            NSString* header=[file readAString];
            short version=[file readAShort];
            short revision=[file readAShort];
            int dimX=[file readAInt];
            int dimY=[file readAInt];
            int dimZ=[file readAInt];
            int flags=[file readAInt];

			bool isDefault = [header caseInsensitiveCompare:@"CNC ARRAY"] == 0;
			bool isUnicode = [header caseInsensitiveCompare:@"MFU ARRAY"] == 0;

            if (!(isDefault || isUnicode))
                break;
            if (version!=1 && version!=2)
                break;
            if (revision!=0)
                break;

			[file setUnicode:isUnicode];

			CRun* rhPtr = ho->hoAdRunHeader;
			KcArrayCGlobalDataList* pData = nil;
			
			//Update global array information
            int global=pArray->lFlags&ARRAY_GLOBAL;
			if ((pArray->lFlags&ARRAY_GLOBAL)!=0)
			{
				CExtStorage* pExtData = [rhPtr getStorage:ho->hoIdentifier];
				if (pExtData != nil)
				{
					pData = (KcArrayCGlobalDataList*)pExtData;
					[pData RemoveObject:self];
				}
			}
			
            // Expand if required
			if(pArray != nil){
				[pArray release];
			}
            pArray = [[KcArrayData alloc] initWithFlags:flags|global withX:dimX andY:dimY andZ:dimZ];
			
			//Re-add the array to global data after load
			if(pData != nil)
				[pData AddObject:self];

            int x, y, z;
            if (flags&ARRAY_TYPENUM)
            {
                for (z=0; z<dimZ; z++)
                {
                    for (y=0; y<dimY; y++)
                    {
                        for (x=0; x<dimX; x++)
                        {
                            pArray->numberArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)]=[file readAInt];
                        }
                    }
                }
            }
            else
            {
                if (version==2)
                {
                    for (z=0; z<dimZ; z++)
                    {
                        for (y=0; y<dimY; y++)
                        {
                            for (x=0; x<dimX; x++)
                            {
                                int l=[file readAInt];
                                if (l!=0)
                                {
									NSString* string = [file readAStringWithSize:l];
									int index = x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX);
                                    pArray->stringArray[index]=string;
                                }
                            }
                        }
                    }                    
                }
                else
                {
                    for (z=0; z<dimZ; z++)
                    {
                        for (y=0; y<dimY; y++)
                        {
                            for (x=0; x<dimX; x++)
                            {
                                pArray->stringArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)]=[file readAStringWithSize:80];
                            }
                        }
                    }                    
                }
            }
        }while (FALSE);
    }
}

#pragma pack(push, _pack_array)
#pragma pack(2)
typedef struct tagHeader
{
    char identifier[10];
    short version;
    short revision;
    int dimensionX;
    int dimensionY;
    int dimensionZ;
    int flags;
}header;
#pragma pack(pop, _pack_array)

-(void)saveArray:(NSString*)fileName
{ 
    int length=sizeof(header);
    int x, y, z;
    NSString* s;
    if (pArray->lFlags&ARRAY_TYPENUM)
    {
        length+=pArray->lDimensionX*pArray->lDimensionY*pArray->lDimensionZ*sizeof(int);
    }
    else
    {
        for (z=0; z<pArray->lDimensionZ; z++)
        {
            for (y=0; y<pArray->lDimensionY; y++)
            {
                for (x=0; x<pArray->lDimensionX; x++)
                {
                    s=pArray->stringArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)];
                    if (s!=nil)
                    {
                        length+=[s length];
                    }              
                    length+=4;
                }
            }
        }                    
    }
    
    header* pHeader=(header*)malloc(length);
    strcpy(pHeader->identifier, "CNC ARRAY");
    pHeader->version=2;
    pHeader->revision=0;
    pHeader->dimensionX=pArray->lDimensionX;
    pHeader->dimensionY=pArray->lDimensionY;
    pHeader->dimensionZ=pArray->lDimensionZ;
    pHeader->flags=pArray->lFlags;
    if (pArray->lFlags&ARRAY_TYPENUM)
    {
        for (z=0; z<pArray->lDimensionZ; z++)
        {
            for (y=0; y<pArray->lDimensionY; y++)
            {
                for (x=0; x<pArray->lDimensionX; x++)
                {
                    int* pSource=&pArray->numberArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)];
                    int* pDest=(int*)((char*)pHeader+sizeof(header)+(x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX))*sizeof(int));
                    *pDest=*pSource;
                }
            }
        }
    }
    else
    {
        size_t l;
        char* ptr=(char*)pHeader+sizeof(header);
        for (z=0; z<pArray->lDimensionZ; z++)
        {
            for (y=0; y<pArray->lDimensionY; y++)
            {
                for (x=0; x<pArray->lDimensionX; x++)
                {
                    s=pArray->stringArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)];
                    if (s!=nil)
                    {
                        [s getCString:ptr+4 maxLength:[s length]*2+1 encoding:NSWindowsCP1252StringEncoding];
                        l=strlen(ptr+4);
                        *(ptr++)=l&0xFF;
                        *(ptr++)=(l>>8)&0xFF;
                        *(ptr++)=(l>>16)&0xFF;
                        *(ptr++)=(l>>24)&0xFF;
                        ptr+=l;
                    }
                    else
                    {
                        *(ptr++)=0;
                        *(ptr++)=0;
                        *(ptr++)=0;
                        *(ptr++)=0;                        
                    }
                }
            }
        }
    }
    NSData* data=[[NSData alloc] initWithBytes:pHeader length:length];
    [data writeToFile:[rh->rhApp getPathForWriting:fileName] atomically:NO];
    [data release];
    free(pHeader);
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{        
		case ACT_SETINDEXA:
			[self SetIndexA:[act getParamExpression:rh withNum:0]];
			break;        
		case ACT_SETINDEXB:       
			[self SetIndexB:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_SETINDEXC:       
			[self SetIndexC:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_ADDINDEXA:
			[self IncIndexA];
			break;
		case ACT_ADDINDEXB:
			[self IncIndexB];
			break;
		case ACT_ADDINDEXC:
			[self IncIndexC];
			break;
		case ACT_WRITEVALUE:
			[self WriteValue:[act getParamExpression:rh withNum:0]];
			break;
		case ACT_WRITESTRING:
			[self WriteString:[act getParamExpString:rh withNum:0]];
			break;
		case ACT_CLEARARRAY:
			[self ClearArray];
			break;
		case ACT_LOAD:
			[self loadArray:[act getParamFilename:rh withNum:0]];
			break;
		case ACT_LOADSELECTOR:
			//LoadSelector(thisObject);
			break;
		case ACT_SAVE:
			[self saveArray:[act getParamFilename:rh withNum:0]];
			break;
		case ACT_SAVESELECTOR:
			//SaveSelector(thisObject);
			break;
		case ACT_WRITEVALUE_X:
			[self WriteValue_X:[act getParamExpression:rh withNum:0] withX:[act getParamExpression:rh withNum:1]];
			break;
		case ACT_WRITEVALUE_XY:
			[self WriteValue_XY:[act getParamExpression:rh withNum:0] withX:[act getParamExpression:rh withNum:1] andY:[act getParamExpression:rh withNum:2]];
			break;
		case ACT_WRITEVALUE_XYZ:
			[self WriteValue_XYZ:[act getParamExpression:rh withNum:0] withX:[act getParamExpression:rh withNum:1] andY:[act getParamExpression:rh withNum:2] andZ:[act getParamExpression:rh withNum:3]];
			break;
		case ACT_WRITESTRING_X:
			[self WriteString_X:[act getParamExpString:rh withNum:0] withX:[act getParamExpression:rh withNum:1]];
			break;
		case ACT_WRITESTRING_XY:
			[self WriteString_XY:[act getParamExpString:rh withNum:0] withX:[act getParamExpression:rh withNum:1] andY:[act getParamExpression:rh withNum:2]];
			break; 
		case ACT_WRITESTRING_XYZ:
			[self WriteString_XYZ:[act getParamExpString:rh withNum:0] withX:[act getParamExpression:rh withNum:1] andY:[act getParamExpression:rh withNum:2] andZ:[act getParamExpression:rh withNum:3]];
			break;
		default:
			NSLog(@"No action found!");
			break;
	}
}

-(void)SetIndexA:(int)i
{
	if ((pArray->lFlags & INDEX_BASE1) != 0)
	{
		pArray->lIndexA = i - 1;
	}
	else
	{
		pArray->lIndexA = i;
	}
}
-(void)SetIndexB:(int)i
{
	if ((pArray->lFlags & INDEX_BASE1) != 0)
	{
		pArray->lIndexB = i - 1;
	}
	else
	{
		pArray->lIndexB = i;
	}
}
-(void)SetIndexC:(int)i
{
	if ((pArray->lFlags & INDEX_BASE1) != 0)
	{
		pArray->lIndexC = i - 1;
	}
	else
	{
		pArray->lIndexC = i;
	}
}
-(void)IncIndexA
{
	pArray->lIndexA++;
}

-(void)IncIndexB
{
	pArray->lIndexB++;
}
-(void)IncIndexC
{
	pArray->lIndexC++;
}
-(void)WriteValue:(int)value
{
	[self WriteValueXYZ:value withX:pArray->lIndexA andY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(void)WriteString:(NSString*)value
{
	[self WriteStringXYZ:value withX:pArray->lIndexA andY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(void)ClearArray
{
	[pArray Clean];
}

-(void)WriteValue_X:(int)value withX:(int)x
{
	x -= [pArray oneBased];
	[self WriteValueXYZ:value withX:x andY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(void)WriteValue_XY:(int)value withX:(int)x andY:(int)y
{
	x -= [pArray oneBased];
	y -= [pArray oneBased];
	[self WriteValueXYZ:value withX:x andY:y andZ:pArray->lIndexC];
}
-(void)WriteValue_XYZ:(int)value withX:(int)x andY:(int)y andZ:(int)z
{
	x -= [pArray oneBased];
	y -= [pArray oneBased];
	z -= [pArray oneBased];
	[self WriteValueXYZ:value withX:x andY:y andZ:z];
}
-(void)WriteValueXYZ:(int)value withX:(int)x andY:(int)y andZ:(int)z
{
	//x,y,z should be fixed for 1-based index if used before this function
	if ((x < 0) || (y < 0) || (z < 0))
	{
		return;
	}
	if ((pArray->lFlags & ARRAY_TYPENUM) != 0)
	{
		// Expand if required
		if ((x >= pArray->lDimensionX) || (y >= pArray->lDimensionY) || (z >= pArray->lDimensionZ))
		{
			int newDimX = MAX(pArray->lDimensionX, x+1);
			int newDimY = MAX(pArray->lDimensionY, y+1);
			int newDimZ = MAX(pArray->lDimensionZ, z+1);
			[pArray Expand:newDimX withY:newDimY andZ:newDimZ];
		}
		//write
		pArray->lIndexA = x;
		pArray->lIndexB = y;
		pArray->lIndexC = z;
		pArray->numberArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)]=value;
	}
}

-(void)WriteString_X:(NSString*)value withX:(int)x
{
	x -= [pArray oneBased];
	[self WriteStringXYZ:value withX:x andY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(void)WriteString_XY:(NSString*)value withX:(int)x andY:(int)y
{
	x -= [pArray oneBased];
	y -= [pArray oneBased];
	[self WriteStringXYZ:value withX:x andY:y andZ:pArray->lIndexC];
}
-(void)WriteString_XYZ:(NSString*)value withX:(int)x andY:(int)y andZ:(int)z
{
	x -= [pArray oneBased];
	y -= [pArray oneBased];
	z -= [pArray oneBased];
	[self WriteStringXYZ:value withX:x andY:y andZ:z];
}
-(void)WriteStringXYZ:(NSString*)value withX:(int)x andY:(int)y andZ:(int)z
{
	//x,y,z should be fixed for 1-based index if used before this function
	if ((x < 0) || (y < 0) || (z < 0))
	{
		return;
	}
	if ((pArray->lFlags & ARRAY_TYPETXT) != 0)
	{
		// Expand if required
		if ((x >= pArray->lDimensionX) || (y >= pArray->lDimensionY) || (z >= pArray->lDimensionZ))
		{
			int newDimX = MAX(pArray->lDimensionX, x+1);
			int newDimY = MAX(pArray->lDimensionY, y+1);
			int newDimZ = MAX(pArray->lDimensionZ, z+1);
			[pArray Expand:newDimX withY:newDimY andZ:newDimZ];
		}
		//write
		pArray->lIndexA = x;
		pArray->lIndexB = y;
		pArray->lIndexC = z;
		NSString** pString=&pArray->stringArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)];
		if (*pString!=nil)
		{
			[*pString release];
		}
		*pString=[[NSString alloc] initWithString:value];
	}
}

// Expressions
// --------------------------------------------
-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_INDEXA:
			return [self IndexA];
		case EXP_INDEXB:  
			return [self IndexB];
		case EXP_INDEXC:
			return [self IndexC];
		case EXP_READVALUE:
			return [self ReadValue];
		case EXP_READSTRING:
			return [self ReadString];
		case EXP_READVALUE_X:
			return [self ReadValue_X];
		case EXP_READVALUE_XY:
			return [self ReadValue_XY];
		case EXP_READVALUE_XYZ:
			return [self ReadValue_XYZ];
		case EXP_READSTRING_X:
			return [self ReadString_X];
		case EXP_READSTRING_XY:
			return [self ReadString_XY];
		case EXP_READSTRING_XYZ:
			return [self ReadString_XYZ];
		case EXP_DIMX:
			return [self Exp_DimX];
		case EXP_DIMY:
			return [self Exp_DimY];
		case EXP_DIMZ:
			return [self Exp_DimZ];
	}
	return [rh getTempValue:0];
}

-(CValue*)IndexA 
{
	if ((pArray->lFlags & INDEX_BASE1) != 0)
	{
		return [rh getTempValue:pArray->lIndexA + 1];
	}
	else
	{
		return [rh getTempValue:pArray->lIndexA];
	}
}
-(CValue*)IndexB
{
	if ((pArray->lFlags & INDEX_BASE1) != 0)
	{
		return [rh getTempValue:pArray->lIndexB + 1];
	}
	else
	{
		return [rh getTempValue:pArray->lIndexB];
	}
}
-(CValue*)IndexC
{
	if ((pArray->lFlags & INDEX_BASE1) != 0)
	{
		return [rh getTempValue:pArray->lIndexC + 1];
	}
	else
	{
		return [rh getTempValue:pArray->lIndexC];
	}
}
-(CValue*)ReadValue
{
	return [self ReadValueXYZ:pArray->lIndexA withY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(CValue*)ReadString
{
	return [self ReadStringXYZ:pArray->lIndexA withY:pArray->lIndexB andZ:pArray->lIndexC];
}

-(CValue*)ReadValue_X
{
	int x=[[ho getExpParam] getInt];	
	return [self ReadValueXYZ:x - [pArray oneBased] withY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(CValue*)ReadValue_XY
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	return [self ReadValueXYZ:x - [pArray oneBased] withY:y - [pArray oneBased] andZ:pArray->lIndexC];
}
-(CValue*)ReadValue_XYZ
{	
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	int z=[[ho getExpParam] getInt];
	return [self ReadValueXYZ:x - [pArray oneBased] withY:y - [pArray oneBased] andZ:z - [pArray oneBased]];
}
-(CValue*)ReadValueXYZ:(int)x withY:(int)y andZ:(int)z
{	
	//x y z should be fixed for 1-based, if so
	if (( x < 0) || (y < 0) || (z < 0 ))
	{
		return [rh getTempValue:0];
	}
	if ((pArray->lFlags & ARRAY_TYPENUM) != 0)
	{
		if ((x < pArray->lDimensionX) && (y < pArray->lDimensionY) && (z < pArray->lDimensionZ))
		{
			return [rh getTempValue:pArray->numberArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)]];
		}
	}
	return [rh getTempValue:0];
}
-(CValue*)ReadString_X
{
	int x=[[ho getExpParam] getInt];
	return [self ReadStringXYZ:x - [pArray oneBased] withY:pArray->lIndexB andZ:pArray->lIndexC];
}
-(CValue*)ReadString_XY
{
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	return [self ReadStringXYZ:x - [pArray oneBased] withY:y - [pArray oneBased] andZ:pArray->lIndexC];
}
-(CValue*)ReadString_XYZ
{	
	int x=[[ho getExpParam] getInt];
	int y=[[ho getExpParam] getInt];
	int z=[[ho getExpParam] getInt];
	return [self ReadStringXYZ:x - [pArray oneBased] withY:y-[pArray oneBased] andZ:z - [pArray oneBased]];
}
-(CValue*)ReadStringXYZ:(int)x withY:(int)y andZ:(int)z
{	
	//x y z should be fixed for 1-based, if so
	if (( x < 0) || (y < 0) || (z < 0 ))
	{
		return [rh getTempString:@""];
	}
	if ((pArray->lFlags & ARRAY_TYPETXT) != 0)
	{
		if ((x < pArray->lDimensionX) && (y < pArray->lDimensionY) && (z < pArray->lDimensionZ))
		{
			NSString* r = pArray->stringArray[x+(y*pArray->lDimensionX)+(z*pArray->lDimensionY*pArray->lDimensionX)];
			if (r != nil)
			{
				return [rh getTempString:r];
			}
		}          
	}
	return [rh getTempString:@""];
}
-(CValue*)Exp_DimX
{
	return [rh getTempValue:pArray->lDimensionX];
}
-(CValue*)Exp_DimY
{
	return [rh getTempValue:pArray->lDimensionY];
}
-(CValue*)Exp_DimZ
{
	return [rh getTempValue:pArray->lDimensionZ];
}

@end


@implementation KcArrayData

-(void)dealloc
{
    [self Clean];
	if (numberArray!=nil)
	{
		free(numberArray);
	}
	if (stringArray!=nil)
	{
		free(stringArray);
	}
	[super dealloc];
}

-(id)initWithFlags:(int)flags withX:(int)dimX andY:(int)dimY andZ:(int)dimZ 
{
	dimX = MAX(1, dimX);
	dimY = MAX(1, dimY);
	dimZ = MAX(1, dimZ);
	
	lFlags = flags;
	lDimensionX = dimX;
	lDimensionY = dimY;
	lDimensionZ = dimZ;
	if ((flags & ARRAY_TYPENUM) != 0)
	{
		numberArray = (int*)calloc(dimZ*lDimensionY*lDimensionX+dimY*lDimensionX+dimX, sizeof(int));
	}
	else if ((flags & ARRAY_TYPETXT) != 0)
	{
		stringArray = (NSString**)calloc(dimZ*lDimensionY*lDimensionX+dimY*lDimensionX+dimX, sizeof(NSString*));
	}
//    [self Reset];
	return self;
} 

-(int)oneBased
{
	if ((lFlags & INDEX_BASE1) != 0)
	{
		return 1;
	}
	return 0;
}

-(void)Expand:(int)newX withY:(int)newY andZ:(int)newZ
{
	int x, y, z;
	//inputs should always be equal or larger than current dimensions
	if ((lFlags & ARRAY_TYPENUM) != 0)
	{
		int* temp = (int*)calloc(newZ*newY*newX, sizeof(int));
		for (z = 0; z < lDimensionZ; z++)
		{
			for (y = 0; y < lDimensionY; y++)
			{
				for (x = 0; x < lDimensionX; x++)
				{
					temp[x+(y*newX)+(z*newY*newX)]=numberArray[x+(y*lDimensionX)+(z*lDimensionY*lDimensionX)];
				}
			}
		}
		free(numberArray);
		numberArray=temp;
	}
	else if ((lFlags & ARRAY_TYPETXT) != 0)
	{
		NSString** tempS = (NSString**)calloc(newZ*newY*newX, sizeof(NSString*));
		for (z = 0; z < lDimensionZ; z++)
		{
			for (y = 0; y < lDimensionY; y++)
			{
				for (x = 0; x < lDimensionX; x++)
				{
					tempS[x+(y*newX)+(z*newY*newX)]=stringArray[x+(y*lDimensionX)+(z*lDimensionY*lDimensionX)];
				}
			}
		}
		free(stringArray);
		stringArray=tempS;
	}
	lDimensionX = newX;
	lDimensionY = newY;
	lDimensionZ = newZ;
}

-(void)Clean
{
	int x, y, z;
	if ((lFlags & ARRAY_TYPENUM) != 0)
	{
		for (z = 0; z < lDimensionZ; z++)
		{
			for (y = 0; y < lDimensionY; y++)
			{
				for (x = 0; x < lDimensionX; x++)
				{
					numberArray[x+(y*lDimensionX)+(z*lDimensionY*lDimensionX)] = 0;
				}
			}
		}
	}
	else if ((lFlags & ARRAY_TYPETXT) != 0)
	{
		for (z = 0; z < lDimensionZ; z++)
		{
			for (y = 0; y < lDimensionY; y++)
			{
				for (x = 0; x < lDimensionX; x++)
				{
					NSString** pString=&stringArray[x+(y*lDimensionX)+(z*lDimensionY*lDimensionX)];
					if (*pString!=nil)
					{
						[*pString release];
					}
					*pString=nil;
				}
			}
		}           
	}
}

@end

@implementation KcArrayCGlobalDataList

-(void)dealloc
{
	[dataList clearRelease];
	[dataList release];
	[names clearRelease];
	[names release];
	[super dealloc];
}
-(id)init 
{
	if(self = [super init])
	{
		dataList = [[CArrayList alloc] init];
		names = [[CArrayList alloc] init];
	}
	return self;
}
-(KcArrayData*)FindObject:(NSString*)objectName
{
	for (int i = 0; i < [names size]; i++)
	{
		NSString* pName=(NSString*)[names get:i];
		if ([pName compare:objectName]==0)
		{
			return (KcArrayData*)[dataList get:i];
		}
	}
	return nil;
}
-(void)AddObject:(CRunKcArray*)o
{
	[dataList add:o->pArray];
	[names add:[[NSString alloc] initWithString:o->ho->hoOiList->oilName]];
}
-(void)RemoveObject:(CRunKcArray*)o
{
	[dataList removeObject:o->pArray];
	for(int i=0; i<[names size]; ++i)
	{
		NSString* nameToRemove = (NSString*)[names get:i];
		if([nameToRemove isEqualToString:o->ho->hoOiList->oilName])
		{
			[names removeIndexRelease:i];
			break;
		}
	}
}

@end

