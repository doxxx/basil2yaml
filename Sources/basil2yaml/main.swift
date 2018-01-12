import Foundation
import Yams
import Commander

func clean(_ s: String) -> String {
    return s.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
}

func extractName(_ obj: NSDictionary) -> String {
    return clean(obj["name"] as! String)
}

func extractIngredients(_ obj: NSDictionary) -> String {
    return (obj["Ingredient"] as! [[String:Any]])
        .sorted(by: { (a,b) in
            return (a["displayOrder"] as! Int) < (b["displayOrder"] as! Int)
        })
        .flatMap({ d in
            return d["text"] as? String
        })
        .joined(separator: "\n")
}

func extractDirections(_ obj: NSDictionary) -> String {
    var startOrder = 0
    return (obj["Direction"] as! [[String:Any]])
        .sorted(by: { (a,b) in
            return (a["displayOrder"] as! Int) < (b["displayOrder"] as! Int)
        })
        .map({ d in
            let order = d["displayOrder"] as! Int
            let text = d["text"] as! String
            if text.hasSuffix(":") {
                startOrder = order + 1
                return text
            } else {
                return "\(order-startOrder+1). \(text)"
            }
        })
        .joined(separator: "\n\n")
}

func extractSourceURL(_ obj: NSDictionary) -> URL? {
    guard let text = obj["source"] as? String else {
        return nil
    }
    return URL(string: text)
}

func extractSourceName(_ url: URL) -> String? {
    guard let host = url.host else {
        return nil
    }
    if host.starts(with: "www.") {
        let prefix = host.index(host.startIndex, offsetBy: 4)
        return String(host[prefix...])
    }
    return host
}

func extractServings(_ obj: NSDictionary) -> String? {
    return obj["servings"] as? String
}

func extractTime(_ obj: NSDictionary) -> Int? {
    guard let seconds = obj["time"] as? Int else {
        return nil
    }
    if seconds == 0 {
        return nil
    }

    return seconds
}

func secondsToTimeString(_ seconds: Int) -> String {
    var seconds = seconds
    let hours = seconds / 3600
    seconds -= hours * 3600
    let minutes = seconds / 60

    var text = "\(minutes) min"
    if hours > 0 {
        text = "\(hours) hr \(text)"
    }
    return text
}

func extractFavorite(_ obj: NSDictionary) -> Bool {
    guard let favorite = obj["favorite"] as? Int else {
        return false
    }
    return favorite != 0
}

func convertRecipe(filename: String) throws -> [String:Any] {
    let data = try Data(contentsOf: URL(fileURLWithPath: filename))
    let obj = NSKeyedUnarchiver.unarchiveObject(with: data) as! NSDictionary

    var recipe = [
        "name": extractName(obj),
        "ingredients": extractIngredients(obj),
        "directions": extractDirections(obj),
        ] as [String : Any]

    if let sourceURL = extractSourceURL(obj) {
        recipe["source_url"] = sourceURL.absoluteString
        if let source = extractSourceName(sourceURL) {
            recipe["source"] = source
        }
    }

    if let servings = extractServings(obj) {
        recipe["servings"] = servings
    }

    if let time = extractTime(obj) {
        recipe["total_time"] = secondsToTimeString(time)
    }

    if extractFavorite(obj) {
        recipe["on_favorites"] = "yes"
    }

    return recipe
}

let main = Group {
    $0.command("dump") { (filename:String) in
        let obj = NSKeyedUnarchiver.unarchiveObject(withFile: filename) as! NSDictionary
        print(obj.debugDescription)
    }

    $0.command(
        "convert",
        Option("output-dir", default: ".", description: "Output individual yml files in the specified directory."),
        Flag("use-recipe-name", description: "Use the recipe name for the yml file instead of the original filename."),
        Flag("combine", description: "Combine all recipes into a multi-recipe yml file written to stdout"),
        VariadicArgument("filenames", description: "One or more Basil .recipe files"),
        description: "Converts one or more Basilc .recipe files to .yml files")
    { (outputDir:String, useRecipeName:Bool, combine:Bool, filenames:[String]) in
        if combine {
            var recipes: [[String:Any]] = []
            for filename in filenames {
                let recipe = try convertRecipe(filename: filename)
                recipes.append(recipe)
            }
            print(try Yams.dump(object: recipes))
        } else {
            for filename in filenames {
                let recipe = try convertRecipe(filename: filename)
                let yaml = try Yams.dump(object: recipe)
                var outFilename: String
                if useRecipeName {
                    let name = recipe["name"]!
                    outFilename = "\(outputDir)/\(name).yml"
                } else {
                    let name = URL(fileURLWithPath: filename).lastPathComponent
                    outFilename = "\(outputDir)/\(name).yml"
                }
                print("Converting \(filename) to \(outFilename)...")
                try yaml.write(toFile: outFilename, atomically: true, encoding: String.Encoding.utf8)
            }
        }
    }
}

main.run()
