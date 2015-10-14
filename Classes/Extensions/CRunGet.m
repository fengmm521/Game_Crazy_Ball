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
#import "CRunExtension.h"
#import "CExtension.h"
#import "CRun.h"
#import "CRunApp.h"
#import "CFile.h"
#import "CCreateObjectInfo.h"
#import "CBitmap.h"
#import "CMask.h"
#import "CActExtension.h"
#import "CCndExtension.h"
#import "CFontInfo.h"
#import "CRect.h"
#import "CImage.h"
#import "CValue.h"
#import "NSExtensions.h"

#import "CRunGet.h"

@implementation CRunGet


-(int)getNumberOfConditions
{
	return 2;
}

-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	getPending = NO;
	usePost = NO;
	postData = [[NSMutableDictionary alloc] init];
	conn=nil;
	return true;
}

//Connection delegates:
-(void)destroyRunObject:(BOOL)bFast
{
	if (conn!=nil)
	{
		[conn cancel];
	}
	
	if(receivedData != nil)
		[receivedData release];
	
	if(conn != nil)
		[conn autorelease];
	
	receivedData = nil;
	conn = nil;
	
	[postData release];
}

-(int)handleRunObject
{
	return REFLAG_ONESHOT;
}

-(void)getURL:(NSString*)url
{
	if(getPending)
		return;

	NSRange range = [url rangeOfString:@"@"];
	if(range.location == NSNotFound)
	{
		url = [url stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
	}
	else
	{
		//Only URL encode whatever comes after the @ sign if it exists (so it doesn't URL encode any usernames and passwords again - since they must be URL-encoded beforehand).
		NSString* postAt = [[url substringFromIndex:range.location+1] stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
		url = [NSString stringWithFormat:@"%@@%@", [url substringToIndex:range.location], postAt];
	}

	NSURL* nsURL = [NSURL URLWithString:url];
	NSMutableURLRequest* request = [[NSMutableURLRequest alloc] initWithURL:nsURL];
	
	//If it should prepare the POST string and send it.
	if(usePost)
	{
		NSString* postString =  [NSString string];
		int count = 0;
		for (NSString* key in [postData allKeys])
		{			
			NSString* escaped = [[postData objectForKey:key] urlEncode];
			
			if(count != 0)
				postString = [NSString stringWithFormat:@"%@&%@=%@", postString, key, escaped];
			else
				postString = [NSString stringWithFormat:@"%@=%@", key, escaped];
			count++;
		}
		
		NSData* rawPostData = [postString dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
		NSString* contentLength = [NSString stringWithFormat:@"%d", (int)[rawPostData length]];
		
		[request setHTTPMethod:@"POST"];
		[request setValue:@"application/x-www-form-urlencoded; charset=UTF-8;" forHTTPHeaderField:@"Content-Type"];
		[request setValue:contentLength forHTTPHeaderField:@"Content-Length"];
		[request setHTTPBody:rawPostData];
		
		usePost = NO;
		[postData removeAllObjects];
	}
	else
		[request setHTTPMethod:@"GET"];
	
	//Establish the connection
	conn = [[NSURLConnection alloc] initWithRequest:request delegate:self];
	if(conn)
	{
		getPending = YES;
	}
	else
	{
		getPending = NO;
	}

}

-(void)setPOSTdata:(NSString*)data forHeader:(NSString*)header
{
	usePost = YES;
	[postData setValue:data forKey:header];
}

-(void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
	if(receivedData != nil)
		[receivedData release];
		
	receivedData = [[NSMutableData alloc] init];
	[receivedData setLength:0];
}

-(void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
	if(receivedData != nil)
		[receivedData appendData:data];
}

-(void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
	NSLog(@"%@", error);
	getPending = NO;
	[conn autorelease];	//Postpone the release of this connection
	conn = nil;
}

-(void)connectionDidFinishLoading:(NSURLConnection *)connection
{
	getPending = NO;
	[conn autorelease];	//Postpone the release of this connection
	conn = nil;
	[ho pushEvent:0 withParam:0];
}




-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch(num)
	{
		case 0:
			return YES;
		case 1:
			return getPending;
	}
	return NO;
}

-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch(num)
	{
		case 0:
			[self getURL:[act getParamExpString:rh withNum:0]];
			break;
		case 1:
		{
			usePost = YES;
			NSString* header = [act getParamExpString:rh withNum:0];
			NSString* data = [act getParamExpString:rh withNum:1];
			[self setPOSTdata:data forHeader:header];
			break;
		}
	}
}

-(CValue*)expression:(int)num
{
	CValue* value = [rh getTempString:@""];
	
	switch(num)
	{
		case 0:
			[value forceString:[rh->rhApp stringGuessingEncoding:receivedData]];
			break;
		case 1:
		{
			NSString* escaped = [[[ho getExpParam] getString] urlEncode];
			[value forceString:escaped];
			break;
		}
	}
	
	return value;
}




@end
