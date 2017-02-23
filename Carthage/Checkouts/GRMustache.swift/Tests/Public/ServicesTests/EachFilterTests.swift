// The MIT License
//
// Copyright (c) 2015 Gwendal Roué
//
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
//
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.


import XCTest
import Mustache

class EachFilterTests: XCTestCase {
    
    func testEachFilterEnumeratesSet() {
        let set = Set(["a", "b"])
        let template = try! Template(string: "{{#each(set)}}({{@index}},{{.}}){{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        let rendering = try! template.render(["set": set])
        XCTAssertTrue(["(0,a)(1,b)", "(0,b)(1,a)"].index(of: rendering) != nil)
    }
    
    func testEachFilterEnumeratesNSSet() {
        let set = NSSet(objects: "a", "b")
        let template = try! Template(string: "{{#each(set)}}({{@index}},{{.}}){{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        let rendering = try! template.render(["set": set])
        XCTAssertTrue(["(0,a)(1,b)", "(0,b)(1,a)"].index(of: rendering) != nil)
    }
    
    func testEachFilterTriggersRenderFunctionsInArray() {
        let render = { (info: RenderingInfo) -> Rendering in
            let rendering = try! info.tag.render(info.context)
            return Rendering("<\(rendering.string)>", rendering.contentType)
        }
        let value = ["array": [render]]
        let template = try! Template(string: "{{#each(array)}}{{@index}}{{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        let rendering = try! template.render(value)
        XCTAssertEqual(rendering, "<0>")
    }

    func testEachFilterTriggersRenderFunctionsInDictionary() {
        let render = { (info: RenderingInfo) -> Rendering in
            let rendering = try! info.tag.render(info.context)
            return Rendering("<\(rendering.string)>", rendering.contentType)
        }
        let value = ["dictionary": ["a": render]]
        let template = try! Template(string: "{{#each(dictionary)}}{{@key}}{{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        let rendering = try! template.render(value)
        XCTAssertEqual(rendering, "<a>")
    }
    
    func testEachFilterDoesNotMessWithItemValues() {
        let increment = Filter { (int: Int?) -> Any? in
            return int! + 1
        }
        let items = [1,2,3]
        let template = try! Template(string: "{{#each(items)}}({{@index}},{{increment(.)}}){{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        template.register(increment, forKey: "increment")
        let rendering = try! template.render(["items": items])
        XCTAssertEqual(rendering, "(0,2)(1,3)(2,4)")
    }
    
    func testEachFilterDoesNotMessWithItemKeyedSubscriptFunction() {
        let items = ["a","bb","ccc"]
        let template = try! Template(string: "{{#each(items)}}({{@index}},{{length}}){{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        let rendering = try! template.render(["items": items])
        XCTAssertEqual(rendering, "(0,1)(1,2)(2,3)")
    }
    
    func testEachFilterDoesNotMessWithItemRenderFunction() {
        let item = Lambda { "foo" }
        let items = [item]
        let template = try! Template(string: "{{#each(items)}}({{@index}},{{.}}){{/}}")
        template.register(StandardLibrary.each, forKey: "each")
        let rendering = try! template.render(["items": items])
        XCTAssertEqual(rendering, "(0,foo)")
    }
}
