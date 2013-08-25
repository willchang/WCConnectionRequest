WCConnectionRequest
===================

WCConnectionRequest is a convenience wrapper for NSURLConnection. It allows you to create network connections and handle responses using blocks (completion, failure and progress blocks). No delegates needed. The class itself is extremely subclassable and override-friendly. In fact, when used in a project with a web service/API, each API endpoint is meant to be its own subclass. This gives the ability to handle common responses and errors in a general superclass while keeping your subclasses nice and clean.

A sample project is included in this repository to give you an idea of how it's used.

Features
--------
* Easy to subclass and use -- no need to set delegates and clutter up your view controller with delegate methods to implement
* Included subclasses **WCBasicConnectionRequest** and **WCJSONConnectionRequest**
* Ability to query what connections are currently in use
* Cancelling connections of a certain class
* Saving data to a file
* Clean and informative debug output
* Automatic enabling and disabling of network activity indicator in status bar

Basic Usage Without Subclassing
-------------------------------

To create one-off connection requests, simply use the included subclass **WCBasicConnectionRequest** which adds a public property `NSURLRequest *request` to forego the need to subclass.

	// Create connection request
	WCBasicConnectionRequest *basicRequest = [[WCBasicConnectionRequest alloc] init];

	// Set its NSURLRequest
	basicRequest.request = [NSURLRequest requestWithURL:[NSURL URLWithString:@"http://www.google.com"]];
	
	// Set its completion handler
	basicRequest.completionHandler = ^(id object) {
		NSLog(@"%@", object);
	};
	
	// Start request
	[basicRequest start];
	
	// Release request as it is retained by an internal static dictionary which keeps track of all connection requests
	[basicRequest release];
	
Advanced Usage With Subclassing
-------------------------------

The full flexibility of **WCConnectionRequest** is seen when creating subclasses and overriding methods to customize behaviour for a specific web service. After subclassing, these connection requests would be used the same way as above (except without setting an `NSURLRequest *` property as the request is handled internally).

Example can be found in the project in this repository.

Implement `- (NSURL *)url` When Subclassing
-------------------------------------------

The `- (NSURL *)url` method is the only required method for a subclass to implement. Here's an example:

	@interface MyCustomConnectionRequest : WCConnectionRequest
	@end
	
	@implementation MyCustomConnectionRequest
	
	- (NSURL *)url {
		return [NSURL urlWithString:@"http://api.someWebService.com/some/data"];
	}

	@end
	
That's it. This connection request can now be used just like any other.
	
Optional Methods to Implement When Subclassing
----------------------------------------------

* `- (HTTPMethod)httpMethod;`
  * Implement to return the HTTP method of your choice. Default implementation returns `HTTPMethodGet`.

* `- (NSMutableURLRequest *)request;`
  * Implement to return a more customized `NSURLRequest *` if desired.

* `- (NSDictionary *)requestHeaderFields;`
  * Implement to return a dictionary with custom request header fields. Default is nil.

* `- (NSData *)bodyData;`
  * Implement to return `NSData *` that will be put into the body of the request if it is a POST. Default is nil.

* `- (id)parseCompletionData:(NSData *)data;`
  * See *Handling Completion* below.

* `- (void)handleResultObject:(id)resultObject;`
  * See *Handling Completion* below.

* `- (NSError *)parseError:(NSError *)error;`
  * See *Handling Failure* below.

* `- (void)handleConnectionError:(NSError *)error;`
  * See *Handling Failure* below.

* `- (NSInteger)errorCode;`
	* Return a custom error code for your subclass. At the moment this is not used anywhere internally.

**Handling Completion**

Implement `- (id)parseCompletionData:(NSData *)data;` in your subclass to *parse* the connection data and return a relevant `NSObject *` of your choice. The default implementation does not parse anything and simply returns the same data passed to it.

Implement `- (void)handleResultObject:(id)resultObject;` in your subclass to *handle* the parsed object and call your completion or failure handlers appropriately. The default implementation calls the failure handler with the parsed object if it is an `NSError *` and the completion handler otherwise. In most cases the default implementation will be sufficient.

**Handling Failure**

Similar to handling completion, handling failure occurs in two steps.

Implement `- (NSError *)parseError:(NSError *)error;` in your subclass to parse the `NSError *` object from the failed connection and return a more relevant, user-friendly `NSError *` if desired. The default implementation returns the same error passed to it.

Implement `- (void)handleConnectionError:(NSError *)error;` in your subclass to handle the parsed `NSError *`. The default implementation passes this error to the failure handler.
