//
//  CMGenericSerializableObject.m
//  cloudmine-iosTests
//
//  Copyright (c) 2015 CloudMine, Inc. All rights reserved.
//  See LICENSE file included with SDK for details.
//

#import "CMGenericSerializableObject.h"
#import "CMDate.h"

@implementation CMGenericSerializableObject
@synthesize string1, string2, simpleInt, arrayOfBooleans, nestedObject, date, dictionary;

- (void)fillPropertiesWithDefaults {
    self.string1 = @"Hello World";
    self.string2 = @"Apple Macintosh";
    self.simpleInt = 42;
    self.arrayOfBooleans = [NSArray arrayWithObjects:[NSNumber numberWithBool:YES],
                            [NSNumber numberWithBool:NO],
                            [NSNumber numberWithBool:YES],
                            [NSNumber numberWithBool:YES],
                            [NSNumber numberWithBool:NO], nil];
    self.date = [[CMDate alloc] initWithDate:[NSDate date]];
    self.dictionary = [NSMutableDictionary dictionary];
    self.uuid = [NSUUID UUID];

    //TODO: Uncomment when server-side support for object relationships is done.

//    self.nestedObject = [[[self class] alloc] init];
//    self.nestedObject.string1 = @"Nested 1";
//    self.nestedObject.string2 = @"Nested 2";
//    self.nestedObject.simpleInt = 999;
//    self.nestedObject.arrayOfBooleans = nil;
//    self.nestedObject.nestedObject = nil;
}

- (BOOL)isEqual:(CMGenericSerializableObject *)object {
    //TODO: Uncomment last line when server-side support for object relationships is done.

    return (((!self.string1 && !object.string1) || [self.string1 isEqualToString:object.string1]) &&
            ((!self.string2 && !object.string2) || [self.string2 isEqualToString:object.string2]) &&
            self.simpleInt == object.simpleInt &&
            ((!self.arrayOfBooleans && !object.arrayOfBooleans) || [self.arrayOfBooleans isEqualToArray:object.arrayOfBooleans]) &&
            [self.date isEqual:object.date] && [self.dictionary isEqual:object.dictionary]
            /*((!self.nestedObject && !self.nestedObject) || [self.nestedObject isEqual:object.nestedObject])*/);
}

- (void)encodeWithCoder:(NSCoder *)aCoder {
    [super encodeWithCoder:aCoder];
    [aCoder encodeObject:self.string1 forKey:@"string1"];
    [aCoder encodeObject:self.string2 forKey:@"string2"];
    [aCoder encodeInt:self.simpleInt forKey:@"simpleInt"];
    [aCoder encodeObject:self.arrayOfBooleans forKey:@"arrayOfBooleans"];
    [aCoder encodeObject:self.date forKey:@"date"];
    [aCoder encodeObject:self.dictionary forKey:@"dictionary"];
    
    uuid_t uuid;
    [self.uuid getUUIDBytes:uuid];
    [aCoder encodeBytes:uuid length:16 forKey:@"uuid"];

    //TODO: Uncomment when server-side support for object relationships is done.
    if (self.nestedObject)
        [aCoder encodeObject:self.nestedObject forKey:@"nestedObject"];
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    if (self = [super initWithCoder:aDecoder]) {
        self.string1 = [aDecoder decodeObjectForKey:@"string1"];
        self.string2 = [aDecoder decodeObjectForKey:@"string2"];
        self.simpleInt = [aDecoder decodeIntForKey:@"simpleInt"];
        self.arrayOfBooleans = [aDecoder decodeObjectForKey:@"arrayOfBooleans"];
        self.date = [aDecoder decodeObjectForKey:@"date"];
        self.dictionary = [aDecoder decodeObjectForKey:@"dictionary"];
        
        NSUInteger blockSize;
        const void* bytes = [aDecoder decodeBytesForKey:@"uuid" returnedLength:&blockSize];
        self.uuid = [[NSUUID alloc] initWithUUIDBytes:bytes];

        //TODO: Uncomment when server-side support for object relationships is done.
//        self.nestedObject = [aDecoder decodeObjectForKey:@"nestedObject"];
    }
    return self;
}

@end
