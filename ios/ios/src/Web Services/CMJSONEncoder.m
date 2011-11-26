//
//  CMJSONEncoder.m
//  cloudmine-ios
//
//  Copyright (c) 2011 CloudMine, LLC. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMJSONEncoder.h"
#import "CMSerializable.h"

@interface CMJSONEncoder (Private)
- (NSData *)jsonData;
- (NSArray *)encodeAllInList:(NSArray *)list;
- (NSDictionary *)encodeAllInDictionary:(NSDictionary *)dictionary;
- (NSDictionary *)serializeContentsOfObject:(id)obj;
@end

@implementation CMJSONEncoder

#pragma mark - Kickoff methods

+ (NSData *)serializeObjects:(id<NSFastEnumeration>)objects {
    NSMutableDictionary *topLevelObjectsDictionary = [NSMutableDictionary dictionary];
    for (id<NSObject,CMSerializable> object in objects) {
        if (![object conformsToProtocol:@protocol(CMSerializable)]) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"All objects to be serialized to JSON must conform to CMSerializable"
                                   userInfo:[NSDictionary dictionaryWithObject:object forKey:@"object"]]
             raise];
        }
        
        if (![object respondsToSelector:@selector(objectId)] || object.objectId == nil) {
            [[NSException exceptionWithName:NSInvalidArgumentException
                                     reason:@"All objects must supply their own unique, non-nil object identifier"
                                   userInfo:[NSDictionary dictionaryWithObject:object forKey:@"object"]] 
             raise];
        }
        
        // Each top-level object gets its own encoder, and the result of each serialization is stored
        // at the key specified by the object.
        CMJSONEncoder *objectEncoder = [[self alloc] init];
        [object encodeWithCoder:objectEncoder];
        [topLevelObjectsDictionary setObject:objectEncoder.jsonRepresentation forKey:object.objectId];
    }
    
    return [[topLevelObjectsDictionary yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (id)init {
    if (self = [super init]) {
        _encodedData = [NSMutableDictionary dictionary];
    }
    return self;
}

#pragma mark - Keyed archiving methods defined by NSCoder

- (BOOL)containsValueForKey:(NSString *)key {
    return ([_encodedData objectForKey:key] != nil);
}

- (void)encodeBool:(BOOL)boolv forKey:(NSString *)key {
    [_encodedData setObject:[NSNumber numberWithBool:boolv] forKey:key];
}

- (void)encodeDouble:(double)realv forKey:(NSString *)key {
    [_encodedData setObject:[NSNumber numberWithDouble:realv] forKey:key];
}

- (void)encodeFloat:(float)realv forKey:(NSString *)key {
    [_encodedData setObject:[NSNumber numberWithFloat:realv] forKey:key];
}

- (void)encodeInt:(int)intv forKey:(NSString *)key {
    [_encodedData setObject:[NSNumber numberWithInt:intv] forKey:key];
}

- (void)encodeInteger:(NSInteger)intv forKey:(NSString *)key {
    [_encodedData setObject:[NSNumber numberWithInteger:intv] forKey:key];
}

- (void)encodeInt32:(int32_t)intv forKey:(NSString *)key {
    [_encodedData setObject:[NSNumber numberWithInt:intv] forKey:key];
}

- (void)encodeObject:(id)objv forKey:(NSString *)key {
    [_encodedData setObject:[self serializeContentsOfObject:objv] forKey:key];
}

#pragma mark - Private encoding methods

- (NSArray *)encodeAllInList:(NSArray *)list {
    NSMutableArray *encodedArray = [NSMutableArray arrayWithCapacity:[list count]];
    for (id item in list) {
        [encodedArray addObject:[self serializeContentsOfObject:item]];
    }
    return encodedArray;
}

- (NSDictionary *)encodeAllInDictionary:(NSDictionary *)dictionary {
    NSMutableDictionary *encodedDictionary = [NSMutableDictionary dictionaryWithCapacity:[dictionary count]];
    for (id key in dictionary) {
        [encodedDictionary setObject:[self serializeContentsOfObject:[dictionary objectForKey:key]] forKey:key];
    }
    [encodedDictionary setObject:@"map" forKey:@"__type__"]; // to differentiate between a custom object and a dictionary.
    return encodedDictionary;
}

- (id)serializeContentsOfObject:(id)objv {
    if (objv == nil) {
        return [NSNull null];
    } else if ([objv isKindOfClass:[NSString class]] || [objv isKindOfClass:[NSNumber class]]) {
        // Strings and numbers are natively handled in JSON and need no further decomposition.
        return objv;
    } else if ([objv isKindOfClass:[NSArray class]]) {
        return [self encodeAllInList:objv];
    } else if ([objv isKindOfClass:[NSSet class]]) {
        return [self encodeAllInList:[objv allObjects]];
    } else if ([objv isKindOfClass:[NSDictionary class]]) {
        return [self encodeAllInDictionary:objv];
    } else {
        NSAssert([objv conformsToProtocol:@protocol(CMSerializable)],
                 @"Trying to serialize unknown object %@ (must be collection, scalar, or conform to CMSerializable)", 
                  objv);
        
        // A new encoder is needed as we are digging down further into a custom object
        // and we don't want to flatten the data in all the sub-objects.
        CMJSONEncoder *newEncoder = [[[self class] alloc] init];
        [objv encodeWithCoder:newEncoder];
        
        // Must encode the type of this object for decoding purposes.
        NSMutableDictionary *jsonRepresentation = [NSMutableDictionary dictionaryWithDictionary:newEncoder.jsonRepresentation];
        [jsonRepresentation setObject:[objv className] forKey:@"__type__"];
        return jsonRepresentation;
    }
}

#pragma mark - Required methods (metadata and base serialization methods)

- (BOOL)allowsKeyedCoding {
    return YES;
}

#pragma mark - Translation methods

- (NSData *)jsonData {
    return [[_encodedData yajl_JSONString] dataUsingEncoding:NSUTF8StringEncoding];
}

- (NSDictionary *)jsonRepresentation {
    return [_encodedData copy];
}

#pragma mark - Unimplemented methods

- (id)decodeObject {
    [[NSException exceptionWithName:NSInvalidArgumentException 
                             reason:@"Cannot call decode methods on an encoder" 
                           userInfo:nil] 
     raise];
    
    return nil;
}

- (void)encodeInt64:(int64_t)intv forKey:(NSString *)key {
    [[NSException exceptionWithName:NSInvalidArgumentException 
                             reason:@"JSON does not support 64-bit integers. Use 32-bit or a string instead." 
                           userInfo:nil] 
     raise];
}

@end
