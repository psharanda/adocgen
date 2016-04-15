//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import Foundation
import SwiftyJSON

protocol AbstractInstantiator {
    func make() -> CellModel
}

class Instantiator<T:CellModel> : AbstractInstantiator {
    func make() -> CellModel {
        return T.init()
    }
}

class CellModelFactory {
    
    static let sharedInstance = CellModelFactory()
    
    private var map = [String:AbstractInstantiator]()
    
    private init() {
        self.register("default", instantiator: Instantiator<DefaultCellModel>())
        self.register("subtitle", instantiator: Instantiator<SubtitleCellModel>())
        self.register("value1", instantiator: Instantiator<Value1CellModel>())
        self.register("value2", instantiator: Instantiator<Value2CellModel>())
    }
    
    func register(type: String, instantiator: AbstractInstantiator) {
        map[type] = instantiator
    }
    
    func create(json: JSON) -> CellModel? {
        
        if let type = json["type"].string {
            if let i = map[type] {
                
                let w = i.make()
                w.fromDict(json.dictionary!)
                return w
            }
        }
        return nil
    }
    
    func create(type: String) -> CellModel? {
        
        if let i = map[type] {
            
            let w = i.make()
            return w
        }
        return nil
    }
    
    func typeClassMap() -> [String:String] {
        
        var tcm = [String:String]()
        
        for (k,v) in map {
            tcm[k] = typeName(v.make())
        }
        
        return tcm
    }
    
    func classTypeMap() -> [String:String] {
        
        var ctm = [String:String]()
        
        for (k,v) in map {
            ctm[typeName(v.make())] = k
        }
        
        return ctm
    }
}
