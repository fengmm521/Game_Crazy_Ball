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
// CRunMTTandom: MT random object
// fin 3rd feb 2010
//
//----------------------------------------------------------------------------------
#import <Foundation/Foundation.h>
#import "CRunExtension.h"

@class CFile;
@class CCreateObjectInfo;
@class CValue;
@class CCndExtension;

#define MTRAND_N  624
#define MTRAND_M  397
#define MTRAND_MATRIX_A  0x9908b0df
#define UPPER_MASK 0x80000000
#define LOWER_MASK 0x7fffffff
#define TEMPERING_MASK_B 0x9d2c5680
#define TEMPERING_MASK_C  0xefc60000

@interface MTRandomMersenne : NSObject
{
	int mt[MTRAND_N]; // state
	int mti; // mti==N+1 means mt[N] is not initialized
	int mag01[2];
}
-(int)nextIntEx:(int)n;
-(int)next:(int)bits;
-(double)nextDouble:(double)min withMax:(double)max;
-(double)nextDouble;
-(void)setSeed:(int*)array length:(int)length;
-(void)setSeed:(int)seed ;

@end

@interface CRunMTRandom : CRunExtension
{
    MTRandomMersenne* rand;	
}

@end
