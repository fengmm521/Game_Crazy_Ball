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

#import "CRunWebView2.h"

#import "CFile.h"
#import "CRunApp.h"
#import "CCreateObjectInfo.h"
#import "CValue.h"
#import "CExtension.h"
#import "CRun.h"
#import "CCndExtension.h"
#import "CRunView.h"
#import "CServices.h"
#import "CImage.h"
#import "CRect.h"
#import "CRunView.h"
#import "CActExtension.h"

#define CND_ONLOADCOMPLETE	0
#define CND_ONSTATUSCHANGE	1
#define CND_STARTEDLOADING	2
#define CND_ONNAVIGATE		3
#define CND_ONWEBCLICK		4
#define CND_ONERROR			5
#define CND_ONPROGRESS		6
#define CND_LAST			7

#define ACT_LOADURL				0
#define ACT_BLOCKHTML			1
#define ACT_GOFORWARDWEB		2
#define ACT_GOBACKWEB			3
#define ACT_STOPWEB				4
#define ACT_REFRESHWEB			5
#define ACT_EXECUTESNIPPET		6
#define ACT_PUSHARGUMENT		7
#define ACT_CALLSCRIPTFUNCTION	8
#define ACT_HIDEWINDOW			9
#define ACT_SHOWWINDOW			10
#define ACT_XPOSITION			11
#define ACT_YPOSITION			12
#define ACT_WSIZE				13
#define ACT_HSIZE				14
#define ACT_RESIZETOFIT			15
#define ACT_INLINEHTML5			16
#define ACT_LOADDOCDOCUMENT		17
#define ACT_SCROLLWEBTOP		18
#define ACT_SCROLLWEBEND		19
#define ACT_SCROLLWEBXY			20
#define ACT_SETZOOMWEB			21
#define ACT_GRABWEBIMAGE		22
#define ACT_INSERTHTML			23
#define ACT_NAVMODE				24
#define ACT_SETUSERAGENT		25
#define ACT_DOURLTOFILE			26

#define EXP_GETERRORVAL				0
#define EXP_GETSTATUSSTR			1
#define EXP_GETCURRENTURL			2
#define EXP_GETNAVIGATEURL			3
#define EXP_GETCLICKEDLINK			4
#define EXP_GETHTMLSOURCE			5
#define EXP_GETEXECUTESNIPPET		6
#define EXP_GETCALLFUNCTIONINT		7
#define EXP_GETCALLFUNCTIONFLOAT	8
#define EXP_GETCALLFUNCTIONSTR		9
#define EXP_GETWEBPAGEWIDTH			10
#define EXP_GETWEBPAGEHEIGHT		11
#define EXP_GETWEBPAGEZOOM			12
#define EXP_GETFORMITEM				13
#define EXP_GETHTMLTAGID			14
#define EXP_GETDOMRETSTR			15
#define EXP_GETDOMCLSSTR			16
#define EXP_GETWEBPROGRESS			17
#define EXP_GETUSERAGENT			18




@implementation CRunWebView2

-(int)getNumberOfConditions
{
	return CND_LAST;
}
-(BOOL)createRunObject:(CFile*)file withCOB:(CCreateObjectInfo*)cob andVersion:(int)version
{
	ho->hoImgWidth=[file readAShort];
	ho->hoImgHeight=[file readAShort];

	CGRect frame = CGRectMake(ho->hoX - rh->rhWindowX, ho->hoY - rh->rhWindowY, ho->hoImgWidth, ho->hoImgHeight);
	webview = [[UIWebView alloc] initWithFrame:frame];
    webview.scalesPageToFit = YES;
	[rh->rhApp positionUIElement:webview withObject:ho];
	webview.delegate = self;	// let us be the delegate so we know when the keyboard's "Done" button is pressed
	[ho->hoAdRunHeader->rhApp->runView addSubview:webview];

	allowedURL = nil;
	errorString = @"";
	errorNumber = 0;
	allowAllURLS = YES;
	return YES;
}

//the next three functions are the self-delegation to set flags for starting,finishing, and failing a load attempt

-(void)webViewDidStartLoad:(UIWebView*)webview
{
	[ho pushEvent:CND_STARTEDLOADING withParam:0];
}

-(void)webViewDidFinishLoad:(UIWebView*)webview
{
	[ho pushEvent:CND_ONLOADCOMPLETE withParam:0];
}

-(void)webView:(UIWebView*)webview didFailLoadWithError:(NSError*)loadError
{
	errorString = [[loadError localizedDescription] retain];
	errorNumber = loadError.code;
	[ho pushEvent:CND_ONERROR withParam:0];
}


-(BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
	if(allowAllURLS)
		return YES;

	if(allowedURL == nil)
	{
		testedURL = [request.URL retain];
		[ho pushEvent:CND_STARTEDLOADING withParam:0];
		return NO;
	}
	else
	{
		if([request.URL isEqual:allowedURL])
		{
			[allowedURL release];
			return YES;
		}
		else
		{
			[testedURL release];
			testedURL = [request.URL retain];
			return NO;
		}
	}
}


-(void)displayRunObject:(CRenderer*)g2
{
	[rh->rhApp positionUIElement:webview withObject:ho];
}

-(void)destroyRunObject:(BOOL)bFast
{
	webview.delegate = nil;
	[webview removeFromSuperview];
	[webview release];

	if(testedURL != nil)
		[testedURL release];
	if(allowedURL != nil)
		[allowedURL release];
	if(errorString != nil)
		[errorString release];
}


// Conditions
// --------------------------------------------------
-(BOOL)condition:(int)num withCndExtension:(CCndExtension*)cnd
{
	switch (num)
	{
		case CND_ONLOADCOMPLETE:
		case CND_ONSTATUSCHANGE:
		case CND_STARTEDLOADING:
		case CND_ONNAVIGATE:
		case CND_ONWEBCLICK:
		case CND_ONERROR:
		case CND_ONPROGRESS:
			return true;
			break;
	}        
	return NO;
}


// Actions
// -------------------------------------------------
-(void)action:(int)num withActExtension:(CActExtension*)act
{
	switch (num)
	{        
		case ACT_LOADURL:
		{
			[webview stopLoading];

			NSURL* url = [NSURL URLWithString:[act getParamExpString:rh withNum:0]];
			NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url cachePolicy:NSURLRequestReloadRevalidatingCacheData timeoutInterval:5];
			[webview loadRequest:request];
			break;
		}
		case ACT_BLOCKHTML:
		{
			[webview loadHTMLString:@"" baseURL:[NSURL URLWithString:@"about:blank"]];
			break;
		}
		case ACT_GOFORWARDWEB:
		{
			[webview goForward];
			break;
		}
		case ACT_GOBACKWEB:
		{
			[webview goBack];
			break;
		}
		case ACT_STOPWEB:
		{
			[webview stopLoading];
			break;
		}
		case ACT_REFRESHWEB:
		{
			[webview reload];
			break;
		}
		case ACT_EXECUTESNIPPET:
		{
			NSString* function = [act getParamExpString:rh withNum:0];
			NSString* arguments = [act getParamExpString:rh withNum:1];

			if(arguments.length > 0)
				[webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@(%@)", function, arguments]];
			else
				[webview stringByEvaluatingJavaScriptFromString:function];
			break;
		}
		case ACT_HIDEWINDOW:
		{
			webview.hidden = YES;
			break;
		}
		case ACT_SHOWWINDOW:
		{
			webview.hidden = NO;
			break;
		}
		case ACT_XPOSITION:
		{
			[ho setX:[act getParamExpression:rh withNum:0]];
			break;
		}
		case ACT_YPOSITION:
		{
			[ho setY:[act getParamExpression:rh withNum:0]];
			break;
		}
		case ACT_WSIZE:
		{
			[ho setWidth:[act getParamExpression:rh withNum:0]];
			break;
		}
		case ACT_HSIZE:
		{
			[ho setHeight:[act getParamExpression:rh withNum:0]];
			break;
		}
		case ACT_RESIZETOFIT:
		{
			[webview setScalesPageToFit:YES];
			break;
		}
		case ACT_INLINEHTML5:
		{
			break;
		}
		case ACT_LOADDOCDOCUMENT:
		{
			NSData* doc = [rh->rhApp loadResourceData:[[ho getExpParam] getString]];
			[webview loadData:doc MIMEType:@"text/html" textEncodingName:@"HTML" baseURL:[NSURL URLWithString:@"about:empty"]];
			break;
		}
		case ACT_SCROLLWEBTOP:
		{
			[webview.scrollView setContentOffset:CGPointZero animated:YES];
			break;
		}
		case ACT_SCROLLWEBEND:
		{
			CGSize fittingSize = webview.scrollView.contentSize;	//TODO: Find proper offset for scrolling to the bottom
			[webview.scrollView setContentOffset:CGPointMake(0, fittingSize.height) animated:YES];
			break;
		}
		case ACT_SCROLLWEBXY:
		{
			CGPoint point = CGPointMake([act getParamExpression:rh withNum:0], [act getParamExpression:rh withNum:1]);
			[webview.scrollView setContentOffset:point animated:YES];
			break;
		}
		case ACT_SETZOOMWEB:
		{
			[webview.scrollView setZoomScale:[act getParamExpDouble:rh withNum:0]];
			break;
		}
		case ACT_GRABWEBIMAGE:
		{
			UIGraphicsBeginImageContextWithOptions(CGSizeMake(ho->hoImgWidth, ho->hoImgHeight), NO, [UIScreen mainScreen].scale);
			[webview.layer renderInContext:UIGraphicsGetCurrentContext()];
			UIImage* screenImage = UIGraphicsGetImageFromCurrentImageContext();
			UIGraphicsEndImageContext();

			NSString* path = [rh->rhApp getPathForWriting:[[ho getExpParam] getString]];
			NSData* data = nil;
			if([path hasSuffix:@".jpg"])
				data = UIImageJPEGRepresentation(screenImage, 0.8);
			else
				data = UIImagePNGRepresentation(screenImage);
			[data writeToFile:path atomically:NO];
			break;
		}
		case ACT_INSERTHTML:
		{
			NSLog(@"INSERT HMTL: Not implemented yet!");
			break;
		}
		case ACT_NAVMODE:
		{
			int mode = [act getParamExpression:rh withNum:0];
			allowAllURLS = (mode != 0);
			break;
		}
		case ACT_SETUSERAGENT:
		{
			NSString* userAgent = [act getParamExpString:rh withNum:0];
			NSDictionary* dictionary = [NSDictionary dictionaryWithObject:userAgent forKey:@"UserAgent"];
			[[NSUserDefaults standardUserDefaults] registerDefaults:dictionary];
			break;
		}
		case ACT_DOURLTOFILE:
		{
			NSLog(@"URL TO FILE: Not implemented yet!");
			break;
		}
	}
}


-(CValue*)expression:(int)num
{
	switch (num)
	{
		case EXP_GETERRORVAL:
			return [rh getTempValue:(int)errorNumber];
		case EXP_GETSTATUSSTR:
			return [rh getTempString:errorString];
		case EXP_GETCURRENTURL:
		{
			NSString* windowLocation = @"";

			if(webview.request != nil && webview.request.URL != nil)
				windowLocation = webview.request.URL.absoluteString;

			if([windowLocation isEqualToString:@""])
				windowLocation = [webview stringByEvaluatingJavaScriptFromString:@"window.location"];

			return [rh getTempString:windowLocation];
		}
		case EXP_GETNAVIGATEURL:
			return [rh getTempString:[testedURL absoluteString]];
		case EXP_GETCLICKEDLINK:
			return [rh getTempString:[testedURL absoluteString]];
		case EXP_GETHTMLSOURCE:
			return [rh getTempString:[webview stringByEvaluatingJavaScriptFromString:@"document.documentElement.outerHTML"]];
		case EXP_GETEXECUTESNIPPET:
			return [rh getTempString:[webview stringByEvaluatingJavaScriptFromString:[[ho getExpParam] getString]]];
		case EXP_GETCALLFUNCTIONINT:
		case EXP_GETCALLFUNCTIONFLOAT:
		case EXP_GETCALLFUNCTIONSTR:
		{
			NSString* function = [[ho getExpParam] getString];
			NSString* args = [[ho getExpParam] getString];

			if([args isEqualToString:@""])
				[webview stringByEvaluatingJavaScriptFromString:function];
			else
				[webview stringByEvaluatingJavaScriptFromString:[NSString stringWithFormat:@"%@(%@)", function, args]];
		}
		case EXP_GETWEBPAGEWIDTH:
			return [rh getTempValue:webview.scrollView.contentSize.width];
		case EXP_GETWEBPAGEHEIGHT:
			return [rh getTempValue:webview.scrollView.contentSize.height];
		case EXP_GETWEBPAGEZOOM:
			return [rh getTempDouble:webview.scrollView.zoomScale];
		case EXP_GETFORMITEM:
			return [rh getTempString:@"Not yet implemented"];
		case EXP_GETHTMLTAGID:
			return [rh getTempString:@"Not yet implemented"];
		case EXP_GETDOMRETSTR:
			return [rh getTempString:@"Not yet implemented"];
		case EXP_GETDOMCLSSTR:
			return [rh getTempString:@"Not yet implemented"];
		case EXP_GETWEBPROGRESS:
			return [rh getTempDouble:0];
			break;

		case EXP_GETUSERAGENT:
			return [rh getTempString:[[NSUserDefaults standardUserDefaults] objectForKey:@"UserAgent"]];
	}
	return [rh getTempString:@""];
}

@end

