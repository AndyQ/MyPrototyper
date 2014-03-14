//
//  NodeView.h
//  DirectedGraphView
//
//  Created by Andy Qua on 08/03/2014.
//  Copyright (c) 2014 Andy Qua. All rights reserved.
//

#import <UIKit/UIKit.h>

#define BLOCK_WIDTH 94.0
#define BLOCK_HEIGHT 136.0
#define GAP_BETWEEN_BLOCKS 30.0
#define WIDTH_OF_ONE_BLOCK (BLOCK_WIDTH + GAP_BETWEEN_BLOCKS)

@interface Node : NSObject

@property (nonatomic, assign) int level;
@property (nonatomic, assign) CGRect frame;
@property (nonatomic, strong) NSString *nodeNr;
@property (nonatomic, strong) Node *parent;
@property (nonatomic, strong) NSMutableArray *children;
@property (nonatomic, strong) NSMutableArray *backRefs;

- (Node *) addNewChildWithName:(NSString *)name;
- (void) addChildNode:(Node *)node;
- (void) layoutTree;
- (CGSize) getSizeOfTree;
- (CGPoint) center;

- (BOOL) hasChildNodeWithName:(NSString *)name;
@end
