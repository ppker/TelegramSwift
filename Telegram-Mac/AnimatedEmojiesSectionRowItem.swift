//
//  AnimatedEmojiesSectionRowItem.swift
//  Telegram
//
//  Created by Mike Renoir on 30.05.2022.
//  Copyright © 2022 Telegram. All rights reserved.
//

import Foundation
import TGUIKit
import TelegramCore

final class AnimatedEmojiesSectionRowItem : GeneralRowItem {
    
    let items: [[StickerPackItem]]
    let context: AccountContext
    let callback:(StickerPackItem)->Void
    let itemSize: NSSize
    init(_ initialSize: NSSize, stableId: AnyHashable, context: AccountContext, items: [StickerPackItem], callback:@escaping(StickerPackItem)->Void ) {
        self.items = items.chunks(8)
        self.context = context
        self.callback = callback
        self.itemSize = NSMakeSize(floor(initialSize.width / 8.0), floor(initialSize.width / 8.0))
        super.init(initialSize, stableId: stableId)
    }
    
    override func viewClass() -> AnyClass {
        return AnimatedEmojiesSectionRowView.self
    }
    
    override var height: CGFloat {
        return self.itemSize.height * CGFloat(items.count)
    }
}



private final class AnimatedEmojiesSectionRowView : TableRowView {
    
    private class Emoji : Control {
        private var item: StickerPackItem?
        private var callback:((StickerPackItem)->Void)?
        private let view = MediaAnimatedStickerView(frame: .zero)
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
            addSubview(view)
            view.playOnHover = true
            layer?.cornerRadius = 4
            
            view.userInteractionEnabled = false
            
            self.scaleOnClick = true
            
            
            self.set(handler: { [weak self] _ in
                self?.click()
            }, for: .Click)
            
            self.set(handler: { [weak self] _ in
                self?.view.play()
            }, for: .Hover)
        }
        
        private func click() {
            if let item = self.item {
                self.callback?(item)
            }
        }
        
        func update(_ item: StickerPackItem, itemSize: NSSize, context: AccountContext, callback:@escaping(StickerPackItem)->Void) {
            var itemSize = itemSize
            itemSize.width -= 13
            itemSize.height -= 13
            let size = item.file.dimensions?.size.aspectFitted(itemSize) ?? itemSize
            
            self.item = item
            self.callback = callback
                        
            view.frame = focus(size)
            view.update(with: item.file, size: size, context: context, table: nil, animated: false)
        }
        
        override func layout() {
            super.layout()
            view.center()
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private final class LineView : View {
        required init(frame frameRect: NSRect) {
            super.init(frame: frameRect)
        }
        
        func update(_ items: [StickerPackItem], itemSize: NSSize, context: AccountContext, callback:@escaping(StickerPackItem)->Void) {
            while subviews.count > items.count {
                self.subviews.last?.removeFromSuperview()
            }
            while subviews.count < items.count {
                self.addSubview(Emoji(frame: CGRect(origin: .zero, size: itemSize)))
            }
            for (i, view) in self.subviews.enumerated() {
                let view = view as! Emoji
                view.update(items[i], itemSize: itemSize, context: context, callback: callback)
            }
        }
        
        override func layout() {
            super.layout()
            for (i, subview) in subviews.enumerated() {
                subview.frame = NSMakeRect(CGFloat(i) * subview.frame.width, 0, subview.frame.width, subview.frame.height)
            }
        }
        
        required init?(coder: NSCoder) {
            fatalError("init(coder:) has not been implemented")
        }
    }
    
    private let lines = View()
    required init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        addSubview(lines)
    }
    
    override func layout() {
        super.layout()
        lines.frame = bounds

        for (i, line) in lines.subviews.enumerated() {
            line.setFrameSize(NSMakeSize(frame.width, line.frame.height))
            line.centerX(y: CGFloat(i) * line.frame.height)
        }
    }

    
    override func set(item: TableRowItem, animated: Bool = false) {
        super.set(item: item, animated: animated)
        
        guard let item = item as? AnimatedEmojiesSectionRowItem else {
            return
        }
        
        while lines.subviews.count > item.items.count {
            lines.subviews.last?.removeFromSuperview()
        }
        while lines.subviews.count < item.items.count {
            lines.addSubview(LineView(frame: NSMakeSize(frame.width, item.itemSize.height).bounds))
        }
        
        for (i, lineView) in lines.subviews.enumerated() {
            let line = lineView as! LineView
            line.update(item.items[i], itemSize: item.itemSize, context: item.context, callback: item.callback)
        }
        
        needsLayout = true
    }
    
    
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}