//
//  NodeView.m
//  DirectedGraphView
//
//  Created by Andy Qua on 08/03/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import "Node.h"

@interface Node ()
{

}

@end

@implementation Node
{
}

- (id)init
{
    self = [super init];
    if (self) {
        // Initialization code
        self.children = [NSMutableArray array];
        self.backRefs = [NSMutableArray array];
    }
    return self;
}

- (void) setNodeNr:(NSString *)nr
{
    _nodeNr = nr;
}

- (CGPoint) center
{
    CGPoint p = (CGPoint) {self.frame.origin.x + self.frame.size.width/2,
        self.frame.origin.y + self.frame.size.height/2};
    
    return p;
}
 
- (Node *) addNewChildWithName:(NSString *)name
{
    Node *nv = [Node new];
    nv.frame = (CGRect){{0,self.frame.origin.y + BLOCK_HEIGHT + 30}, {BLOCK_WIDTH,BLOCK_HEIGHT}};
    nv.parent = self;
    nv.nodeNr = name;
    nv.level = self.level+1;
    [self.children addObject:nv];

    return nv;
}

- (void) addChildNode:(Node *)node;
{
    [self.children addObject:node];
}


- (void) addNewChild
{
    Node *nv = [Node new];
    nv.frame = (CGRect){{0,self.frame.origin.y + BLOCK_HEIGHT + 50}, {BLOCK_WIDTH,BLOCK_HEIGHT}};
    nv.parent = self;
    
    [self.children addObject:nv];
    
    [self layoutTree];
}

- (CGSize) getSizeOfTree
{
    int maxNodeCount = [self getMaxNodeCount];

    CGFloat width = maxNodeCount * WIDTH_OF_ONE_BLOCK;
    CGFloat height = [self getHeightOfTree];
    
    return CGSizeMake( width, height );
}


- (CGFloat) getHeightOfTree
{
    CGFloat height = self.frame.origin.y + self.frame.size.height;
    for ( Node *nv in self.children )
    {
        CGFloat ch = [nv getHeightOfTree];
        if ( ch > height )
            height = ch;
    }
    
    return height;
}

- (void) layoutTree
{
    // This is the bit that does the heavy work
    // It needs to workout the positions of this and all children
    
    // First, we need to traverse all the children and get the maximum width for a node row
    int maxNodeCount = [self getMaxNodeCount];
    
    // get the total width
    
    int width = maxNodeCount * WIDTH_OF_ONE_BLOCK;
    
    // Our position is at the midpoint of this
    CGFloat pos = width/2;
    CGFloat x = pos;

    _frame.origin.x = x - BLOCK_WIDTH/2;

    x -=  width/2;
    [self layoutChildrenFromPosition:x];
}

- (void) layoutChildrenFromPosition:(CGFloat)x// inWidth:(CGFloat)width
{
    for ( Node *nv in self.children )
    {
        // Work out where the child position should be
        int count = [nv getMaxNodeCount];
        CGFloat size = count * WIDTH_OF_ONE_BLOCK;
        CGFloat pos = x + size/2;

        nv.frame = (CGRect){{pos - BLOCK_WIDTH/2,self.frame.origin.y + BLOCK_HEIGHT + 50}, {BLOCK_WIDTH,BLOCK_HEIGHT}};

        [nv layoutChildrenFromPosition:x];

        x += size;
    }
}

- (int) getMaxNodeCount
{
    // Get the maximum nod count of each child
    int maxCount = self.children.count;
    if ( maxCount == 0 )
        maxCount = 1;
    
    int totalChild = 0;
    for ( Node *nv in self.children )
    {
        int val = [nv getMaxNodeCount];
        totalChild += val;
    }

    if ( totalChild > maxCount )
        maxCount = totalChild;

    return maxCount;
}

- (BOOL) hasChildNodeWithName:(NSString *)name
{
    bool rc = NO;
    for ( Node *nv in self.children )
    {
        if ( [nv.nodeNr isEqualToString:name] || [nv hasChildNodeWithName:name] )
        {
            rc = YES;
            break;
        }
    }
    
    return rc;
}

@end
