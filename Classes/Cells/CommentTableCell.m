//
//  CommentTableCell.m
//  newsyc
//
//  Created by Grant Paul on 3/5/11.
//  Copyright 2011 Xuzz Productions, LLC. All rights reserved.
//

#import "HNKit.h"

#import "CommentTableCell.h"

#import "NSString+Tags.h"
#import "NSString+Entities.h"

#import "SharingController.h"

@implementation CommentTableCell
@synthesize comment, indentationLevel, delegate, expanded;

- (id)initWithReuseIdentifier:(NSString *)identifier {
    if ((self = [super initWithStyle:UITableViewCellStyleDefault reuseIdentifier:identifier])) {
        [contentView setBackgroundColor:[UIColor whiteColor]];
        [self setShowsDivider:NO];
        
        CALayer *layer = [contentView layer];
        [layer setContentsGravity:kCAGravityBottomLeft];
        [layer setNeedsDisplayOnBoundsChange:YES];
        
        toolbarView = [[EntryActionsView alloc] initWithFrame:CGRectZero];
        [toolbarView sizeToFit];
        [toolbarView setClipsToBounds:YES]; // hide shadow
        [toolbarView setStyle:kEntryActionsViewStyleLight];

        CGRect toolbarFrame = [toolbarView frame];
        toolbarFrame.origin.y = [self bounds].size.height;
        toolbarFrame.size.width = [self bounds].size.width;
        [toolbarView setFrame:toolbarFrame];
        [toolbarView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
        
        [self addSubview:toolbarView];
        [self setExpanded:NO];
        
        linkLongPressRecognizer = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(longPressFromRecognizer:)];
        [linkLongPressRecognizer setMinimumPressDuration:0.65f];
        [linkLongPressRecognizer setCancelsTouchesInView:NO];
        [contentView addGestureRecognizer:linkLongPressRecognizer];

        doubleTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapFromRecognizer:)];
        [doubleTapRecognizer setNumberOfTapsRequired:2];
        [contentView addGestureRecognizer:doubleTapRecognizer];

        tapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFromRecognizer:)];
        [tapRecognizer setNumberOfTapsRequired:1];
        [tapRecognizer setCancelsTouchesInView:NO];
        [tapRecognizer requireGestureRecognizerToFail:doubleTapRecognizer];
        [contentView addGestureRecognizer:tapRecognizer];

        [tapRecognizer setEnabled:YES];
        [doubleTapRecognizer setEnabled:YES];
    }
    
    return self;
}

- (void)dealloc {
    [comment release];
    [toolbarView release];
    [doubleTapRecognizer release];
    [linkLongPressRecognizer release];
    [tapRecognizer release];

    [super dealloc];
}

#pragma mark - Setters

- (void)setExpanded:(BOOL)expanded_ {
    expanded = expanded_;
    
    if (expanded) {
        CGRect toolbarFrame = [toolbarView frame];
        toolbarFrame.origin.y = [self bounds].size.height - toolbarFrame.size.height;
        toolbarFrame.size.width = [self bounds].size.width;
        [toolbarView setFrame:toolbarFrame];
    } else {
        CGRect toolbarFrame = [toolbarView frame];
        toolbarFrame.origin.y = [self bounds].size.height;
        toolbarFrame.size.width = [self bounds].size.width;
        [toolbarView setFrame:toolbarFrame];
    }
}

- (void)setDelegate:(id<CommentTableCellDelegate>)delegate_ {
    delegate = delegate_;
    
    [toolbarView setDelegate:delegate];
}

- (void)setComment:(HNEntry *)comment_ {
    [comment autorelease];
    comment = [comment_ retain];
    
    [toolbarView setEntry:comment_];
    
    [self setNeedsDisplay];
}

- (void)setIndentationLevel:(int)level {
    indentationLevel = level;
    
    [self setNeedsDisplay];
}

#pragma mark - Configuration

+ (UIEdgeInsets)margins {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return UIEdgeInsetsMake(26.0f, 32.0f, 36.0f, 32.0f);
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return UIEdgeInsetsMake(11.0f, 12.0f, 16.0f, 12.0);
    }
    
    return UIEdgeInsetsZero;
}

+ (CGSize)offsets {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return CGSizeMake(8.0f, 8.0f);
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return CGSizeMake(8.0f, 4.0f);
    }

    return CGSizeZero;
}

+ (CGFloat)indentationDepth {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return 30.0f;
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return 10.0f;
    }
    
    return 0.0f;
}

+ (UIFont *)userFont {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return [UIFont boldSystemFontOfSize:17.0f];
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return [UIFont boldSystemFontOfSize:14.0f];
    }

    return nil;
}

+ (UIFont *)dateFont {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return [UIFont systemFontOfSize:16.0f];
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return [UIFont systemFontOfSize:13.0f];
    }

    return nil;
}

+ (UIFont *)subtleFont {
    if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad) {
        return [UIFont systemFontOfSize:16.0f];
    } else if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
        return [UIFont systemFontOfSize:13.0f];
    }

    return nil;
}

+ (BOOL)entryShowsPoints:(HNEntry *)entry {
    // Re-enable this for everyone if comment score viewing is re-enabled.
    return [entry submitter] == [[entry session] user];
}

#pragma mark - Height Calculations

+ (CGFloat)bodyHeightForComment:(HNEntry *)comment withWidth:(CGFloat)width indentationLevel:(NSInteger)indentationLevel {
    width -= ([self margins].left + [self margins].right);
    width -= (indentationLevel * [self indentationDepth]);
    
    HNEntryBodyRenderer *renderer = [comment renderer];
    CGSize size = [renderer sizeForWidth:width];
    
    return size.height;
}

+ (CGFloat)heightForEntry:(HNEntry *)entry withWidth:(CGFloat)width expanded:(BOOL)expanded indentationLevel:(NSInteger)indentationLevel {
    UIEdgeInsets margins = [self margins];
    CGSize offsets = [self offsets];

    CGFloat height = margins.top;
    height += [[self userFont] lineHeight];
    height += [self bodyHeightForComment:entry withWidth:width indentationLevel:indentationLevel];
    if ([self entryShowsPoints:entry]) height += offsets.height + [[self subtleFont] lineHeight];
    height += margins.bottom;
    if (expanded) height += 44.0f;
    
    return height;
}

#pragma mark - Drawing

- (CGRect)drawingBounds {
    CGRect bounds = [self bounds];
    bounds.origin.x += (indentationLevel * [[self class] indentationDepth]);
    if (expanded) bounds.size.height -= [toolbarView bounds].size.height;

    return bounds;
}

- (CGRect)userFrame {
    CGRect bounds = [self drawingBounds];
    UIEdgeInsets margins = [[self class] margins];

    NSString *user = [[comment submitter] identifier];

    CGRect userrect;
    userrect.origin.x = bounds.origin.x + margins.left;
    userrect.origin.y = margins.top;
    userrect.size = [user sizeWithFont:[[self class] userFont]];

    return userrect;
}

- (CGRect)dateFrame {
    CGRect bounds = [self drawingBounds];
    UIEdgeInsets margins = [[self class] margins];

    NSString *date = [comment posted];

    CGRect daterect;
    daterect.size = [date sizeWithFont:[[self class] dateFont]];
    daterect.origin = CGPointMake(bounds.size.width - daterect.size.width - margins.right, margins.top);

    return daterect;
}

- (void)drawContentView:(CGRect)rect {
    CGRect bounds = [self drawingBounds];
    CGSize offsets = [[self class] offsets];
    UIEdgeInsets margins = [[self class] margins];

    NSString *user = [[comment submitter] identifier];
    NSString *date = [comment posted];
    NSString *points = [comment points] == 1 ? @"1 point" : [NSString stringWithFormat:@"%d points", [comment points]];
    NSString *comments = [comment children] == 0 ? @"" : [comment children] == 1 ? @"1 reply" : [NSString stringWithFormat:@"%d replies", [comment children]];

    // draw username
    [[UIColor blackColor] set];
    CGRect userrect = [self userFrame];
    [user drawInRect:userrect withFont:[[self class] userFont]];

    if (userHighlighted) {
        CGRect rect = CGRectInset(userrect, -4.0f, -4.0f);
        UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:3.0f];
        [[UIColor colorWithWhite:0.5f alpha:0.5f] set];
        [bezierPath fill];
    }

    // draw date
    [[UIColor lightGrayColor] set];
    CGRect daterect = [self dateFrame];
    [date drawInRect:daterect withFont:[[self class] dateFont]];
    
    // draw comment body
    if ([[comment body] length] > 0) {
        bodyrect.size.height = [[self class] bodyHeightForComment:comment withWidth:bounds.size.width indentationLevel:indentationLevel];
        bodyrect.size.width = bounds.size.width - bounds.origin.x - margins.left - margins.left;
        bodyrect.origin.x = bounds.origin.x + margins.left;
        bodyrect.origin.y = margins.top + daterect.size.height + offsets.height;

        HNEntryBodyRenderer *renderer = [comment renderer];
        [renderer renderInContext:UIGraphicsGetCurrentContext() rect:bodyrect];
    }
    
    // draw points
    [[UIColor grayColor] set];
    CGRect pointsrect;
    pointsrect.size.height = [points sizeWithFont:[[self class] subtleFont]].height;
    pointsrect.size.width = (bounds.size.width + bounds.origin.x) / 2 - margins.left - offsets.width;
    pointsrect.origin.x = bounds.origin.x + margins.left;
    pointsrect.origin.y = bounds.size.height - margins.bottom - pointsrect.size.height;
    if ([[self class] entryShowsPoints:comment]) {
          [points drawInRect:pointsrect withFont:[[self class] subtleFont] lineBreakMode:NSLineBreakByTruncatingTail alignment:NSTextAlignmentLeft];
    }
    
    // draw replies count
    [[UIColor grayColor] set];
    CGRect commentsrect;
    commentsrect.size.height = [comments sizeWithFont:[[self class] subtleFont]].height;
    commentsrect.size.width = (bounds.size.width - bounds.origin.x) / 2 - margins.right - offsets.width;
    commentsrect.origin.x = bounds.size.width - (bounds.size.width - bounds.origin.x) / 2 + offsets.width;
    commentsrect.origin.y = bounds.size.height - margins.bottom - commentsrect.size.height;
    
    // draw link highlight
    UIBezierPath *highlightBezierPath = [UIBezierPath bezierPath];
    for (NSValue *rect in highlightedRects) {
        CGRect highlightedRect = CGRectIntegral([rect CGRectValue]);
        
        if (highlightedRect.size.width != 0 && highlightedRect.size.height != 0) {            
            CGRect rect = CGRectInset(highlightedRect, -4.0f, -4.0f);
            rect.origin.x += bodyrect.origin.x;
            rect.origin.y += bodyrect.origin.y;
            
            UIBezierPath *bezierPath = [UIBezierPath bezierPathWithRoundedRect:rect cornerRadius:3.0f];
            [highlightBezierPath appendPath:bezierPath];
        }
    }
    [[UIColor colorWithWhite:0.5f alpha:0.5f] set];
    [highlightBezierPath fill];

    // draw divider line
    CGRect linerect;
    linerect.origin.x = 0;
    linerect.size.width = bounds.size.width;
    linerect.size.height = 1.0f / [[UIScreen mainScreen] scale];
    linerect.origin.y = bounds.size.height - linerect.size.height;
    [[UIColor colorWithWhite:0.85f alpha:1.0f] set];
    UIRectFill(linerect);
}

#pragma mark - Tap Handlers

- (void)singleTapped {
    if ([delegate respondsToSelector:@selector(commentTableCellTapped:)]) {
        [delegate commentTableCellTapped:self];
    }
}

- (void)doubleTapped {
    if ([delegate respondsToSelector:@selector(commentTableCellDoubleTapped:)]) {
        [delegate commentTableCellDoubleTapped:self];
    }
}

- (CGPoint)bodyPointForPoint:(CGPoint)point {
    CGPoint bodyPoint;
    bodyPoint.x = point.x - bodyrect.origin.x;
    bodyPoint.y = point.y - bodyrect.origin.y;
    return bodyPoint;
}

- (void)clearHighlights {
    BOOL wasHighlighted = NO;

    if (highlightedRects != nil) {
        [highlightedRects release];
        highlightedRects = nil;
        wasHighlighted = YES;
    } else if (userHighlighted) {
        userHighlighted = NO;
        wasHighlighted = YES;
    }

    navigationCancelled = NO;

    if (wasHighlighted) {
        [tapRecognizer setEnabled:YES];
        [doubleTapRecognizer setEnabled:YES];
    
        [self setNeedsDisplay];
    }
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
    [self clearHighlights];

    UITouch *touch = [touches anyObject];
    CGPoint location = [touch locationInView:self];

    CGPoint bodyPoint = [self bodyPointForPoint:location];
    [[comment renderer] linkURLAtPoint:bodyPoint forWidth:bodyrect.size.width rects:&highlightedRects];

    BOOL tapRecognized = NO;

    if (highlightedRects != nil) {
        [highlightedRects retain];
        tapRecognized = YES;
    } else if (CGRectContainsPoint([self userFrame], location)) {
        userHighlighted = YES;
        tapRecognized = YES;
    }

    if (tapRecognized) {
        [self setNeedsDisplay];

        [tapRecognizer setEnabled:NO];
        [doubleTapRecognizer setEnabled:NO];
    }
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
    if (highlightedRects != nil && !navigationCancelled) {
        UITouch *touch = [touches anyObject];
        CGPoint point = [self bodyPointForPoint:[touch locationInView:self]];
        
        NSURL *url = [[comment renderer] linkURLAtPoint:point forWidth:bodyrect.size.width rects:NULL];
        
        if (url != nil) {
            if ([delegate respondsToSelector:@selector(commentTableCell:selectedURL:)]) {
                [delegate commentTableCell:self selectedURL:url];
            }
        }
    } else if (userHighlighted) {
        if ([delegate respondsToSelector:@selector(commentTableCellTappedUser:)]) {
            [delegate commentTableCellTappedUser:self];
        }
    }

    [self clearHighlights];
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
    [self clearHighlights];
}

- (void)tapFromRecognizer:(UITapGestureRecognizer *)gesture {
    if (highlightedRects == nil && !userHighlighted) {
        CGPoint location = [gesture locationInView:self];

        if (!expanded || location.y < [toolbarView frame].origin.y) {
            [self singleTapped];
        }
    }
}

- (void)doubleTapFromRecognizer:(UITapGestureRecognizer *)gesture {
    if (highlightedRects == nil && !userHighlighted) {
        CGPoint location = [gesture locationInView:self];

        if (!expanded || location.y < [toolbarView frame].origin.y) {
            [self doubleTapped];
        }
    }
}

- (void)longPressFromRecognizer:(UILongPressGestureRecognizer *)gesture {
	if ([gesture state] == UIGestureRecognizerStateBegan) {
        CGPoint location = [gesture locationInView:self];
        CGPoint point = [self bodyPointForPoint:location];
        
        NSSet *rects;
        NSURL *url = [[comment renderer] linkURLAtPoint:point forWidth:bodyrect.size.width rects:&rects];
        
        if (url != nil && [rects count] > 0) {
            SharingController *sharingController = [[SharingController alloc] initWithURL:url title:nil fromController:nil];
            [sharingController showFromView:self atRect:CGRectInset(CGRectMake(location.x, location.y, 0, 0), -4.0f, -4.0f)];
            [sharingController release];

            navigationCancelled = YES;
        }
    }
}

@end
