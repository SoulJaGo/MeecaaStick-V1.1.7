//
//  NSString+MyCategory.h
//  Sangcp
//
//  Created by tealeaf on 13-7-21.
//
//

/*
 * decodeBase64
 * copy from http://stackoverflow.com/questions/392464/how-do-i-do-base64-encoding-on-iphone-sdk
 */

#import <Foundation/Foundation.h>

@interface NSString (MyCategory)

- (NSString *)encodeBase64UsingUTF8Encoding;
- (NSString *)decodeBase64UsingUTF8Encoding;

- (NSString *)encryptAES128WithKey:(NSString *)key;
- (NSString *)decryptAES128WithKey:(NSString *)key;

- (NSString *)encryptRSAWithKey:(SecKeyRef) key;

- (NSData *)decodeBase64;

- (NSString *)md5;

- (NSUInteger)indexOfCharacter:(unichar)character;
- (NSUInteger)indexOfCharacter:(unichar)character from:(NSUInteger)fromIndex;

@end
