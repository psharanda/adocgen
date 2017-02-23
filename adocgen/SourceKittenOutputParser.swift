//
//  Copyright © 2016 Pavel Sharanda. All rights reserved.
//

import Foundation
import SwiftyJSON

/* SAMPLE JSON

{
   "\/Users\/psharanda\/Work\/adocgen\/adocgen\/CellModel.swift":{
      "key.substructure":[
         {
            "key.kind":"source.lang.swift.decl.class",
            "key.doc.comment":"Simplest type of cell. Has optional title and icon. Corresponds to  cell of .Default style.",
            "key.name":"DefaultCellModel",
            "key.inheritedtypes":[
               {
                  "key.name":"CellModel"
               }
            ],
            "key.substructure":[
               {
                  "key.kind":"source.lang.swift.decl.var.instance",
                  "key.doc.comment":"The name of a book, chapter, poem, essay, picture, statue, piece of music, play, film, etc",
                  "key.typename":"String?",
                  "key.name":"title"
               }
            ]
         }
      ]
   }
}

*/

struct SKField {
    let comment: String?
    let typename: String?
    let name: String?
    
    static func makeFromDict(_ dict: [String: JSON]) -> SKField {
        return SKField(comment: dict["key.doc.comment"]?.string, typename: dict["key.typename"]?.string, name: dict["key.name"]?.string)
    }
}

struct SKType {
    let comment: String?
    let name: String?
    let inheritedTypes: [String]
    let fields: [SKField]
    
    static func makeFromDict(_ dict: [String: JSON]) -> SKType {
        
        var inheritedTypes = [String]()
        
        if let a = dict["key.inheritedtypes"]?.array {
            for d in a {
                if let t = d["key.name"].string {
                    inheritedTypes.append(t)
                }
            }
        }
        
        var fields = [SKField]()
        
        if let a = dict["key.substructure"]?.array {
            for d in a {
                if let dd = d.dictionary, dd["key.kind"] == "source.lang.swift.decl.var.instance" {
                    fields.append(SKField.makeFromDict(dd))
                }
            }
        }
        
        return SKType(comment: dict["key.doc.comment"]?.string, name: dict["key.name"]?.string, inheritedTypes: inheritedTypes, fields: fields)
    }
}

func parseSourceKittenOutput(_ jsonPath: String) throws -> [SKType] {
    var types = [SKType]()
    
    if let jsonData = try? Data(contentsOf: URL(fileURLWithPath: jsonPath)) {
        let jsonObject = try JSONSerialization.jsonObject(with: jsonData, options: .allowFragments)
        
        let json = JSON(jsonObject)
        
        if  let (_,jsonDict) = json.dictionary?.first,
            let structure = jsonDict["key.substructure"].array {
                
                for substr in structure {
                    
                    if let substrDict = substr.dictionary {
                        if substrDict["key.kind"] == "source.lang.swift.decl.class" {
                            types.append(SKType.makeFromDict(substrDict))
                        }
                    }                    
                }
        }
    }
    
    return types
}

