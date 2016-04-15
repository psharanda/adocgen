//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import Foundation
import SwiftyJSON

class CellModel {
    
    func fromJson(json: JSON) {
        
    }
    
    required init() {
        
    }
}

/**
Simplest type of cell. Has optional title and icon. Corresponds to  cell of .Default style.
 */
class DefaultCellModel : CellModel  {
    
    /**
     The name of a book, chapter, poem, essay, picture, statue, piece of music, play, film, etc
     */
    var title: String?
    
    /**
     The name of icon
     */
    var iconName: String?
    
    override func fromJson(json: JSON) {
        self.title = json["title"].string
        self.iconName = json["iconName"].string
    }
}

/**
 More advance type of cell. Has optional subtitle addionally to title and icon. Corresponds to  cell of .Subtitle style.
 */
class SubtitleCellModel : DefaultCellModel  {
    
    /**
     A secondary or explanatory title, as of a book or play
    */
    var subtitle: String = "DEFAULT_SUBTITLE"
    
    override func fromJson(json: JSON) {
        super.fromJson(json)
        
        if let s = json["subtitle"].string {
            self.subtitle = s
        }
    }
}

/**
 Nice looking cell with title from the left and subtitle from the right. Corresponds to  cell of .Value1 style.
 */
class Value1CellModel: SubtitleCellModel {
    
}

/**
 Ugly looking cell with blue title. Corresponds to  cell of .Value2 style.
 */
class Value2CellModel: SubtitleCellModel {
    
}



