import Darwin
import Foundation

enum Tile: CustomStringConvertible {
    case valid
    case wall
    case invalid
    
    init(from character: Character) {
        if character == " " {
            self = .invalid
        } else if character == "." {
            self = .valid
        } else if character == "#" {
            self = .wall
        } else {
            fatalError()
        }
    }
    
    var description: String {
        switch self {
        case .valid:
            return "."
        case .wall:
            return "#"
        case .invalid:
            return " "
        }
    }
}

enum Heading: CustomStringConvertible {
    case up
    case down
    case left
    case right
    
    var description: String {
        switch self {
        case .up:
            return "^"
        case .down:
            return "v"
        case .left:
            return "<"
        case .right:
            return ">"
        }
    }
    
    func rotated(from character: Character) -> Heading {
        if character == "L" {
            switch self {
            case .up:
                return .left
            case .down:
                return .right
            case .left:
                return .down
            case .right:
                return .up
            }
            
        } else if character == "R" {
            switch self {
            case .up:
                return .right
            case .down:
                return .left
            case .left:
                return .up
            case .right:
                return .down
            }
            
        } else {
            fatalError()
        }
    }
}

struct Position {
    var x: Int
    var y: Int
    
    static var zero: Position = Position(x: 0, y: 0)
    
    static func from(row: Int, col: Int) -> Position {
        Position(x: col, y: row)
    }
    
    func toRowCol() -> (row: Int, col: Int) {
        (row: self.y, col: self.x)
    }
    
    func moved(to heading: Heading) -> Position {
        switch heading {
        case .up:
            return Position(x: x, y: y - 1)
        case .down:
            return Position(x: x, y: y + 1)
        case .left:
            return Position(x: x - 1, y: y)
        case .right:
            return Position(x: x + 1, y: y)
        }
    }
}

struct Instruction: CustomStringConvertible {
    let count: Int
    let heading: Heading
    
    var description: String {
        "\(count)\(heading)"
    }
}

class Player {
    var position: Position = .zero
    var heading: Heading = .right
}

// 2d map, (0, 0) top left
class Map {
    var tiles = [[Tile]]()
    
    func add(row: [Tile]) {
        // if we're first, just append
        if tiles.count == 0 {
            tiles.append(row)
            return
        }
        
        // need to handle resizing for later rows, though
        // first check if we need to resize existing tiles
        if row.count > tiles[0].count {
            expandRows(to: row.count)
        }
        
        tiles.append([Tile](repeating: .invalid, count: tiles[0].count))
        let index = tiles.count - 1
        
        for i in 0..<row.count {
            tiles[index][i] = row[i]
        }
    }
    
    func placePlayerAtStart(_ player: inout Player) {
        for i in 0..<tiles[0].count {
            if tiles[0][i] == .valid {
                player.position = .from(row: 0, col: i)
            }
        }
    }
    
    func simulate(player: Player, instruction: Instruction) {
        var currentCount = 0
        while currentCount < instruction.count {
            
        }
    }
    
    private func canMove(from position: Position, heading: Heading) -> (canMove: Bool, actualPosition: Position) {
        let index = position.toRowCol()
        var toPosition = position.moved(to: heading)
        if isOutOfBounds(toPosition) { // OR toPosition is invalid??
            toPosition = findNextValid(from: position, heading: heading)
        }
        
        if tiles[index.row][index.col] == .invalid {
            
        }
    }
    
    private func isOutOfBounds(_ positiion: Position) -> Bool {
        if positiion.x < 0 || positiion.x > tiles[0].count {
            return false
        }
        
        if positiion.y < 0 || positiion.y > tiles.count {
            return false
        }
        
        return true
    }
    
    private func findNextValid(from position: Position, heading: Heading) -> Position {
        let startIndex = position.toRowCol()
        var currentIndex = 0
        while true {
            let row: Int
            let col: Int
            
            switch heading {
            case .up:
                row = tiles.count - currentIndex - 1
                col = startIndex.col

            case .down:
                row = currentIndex
                col = startIndex.col
                
            case .left:
                row = startIndex.row
                col = currentIndex
                
            case .right:
                row = startIndex.row
                col = tiles[0].count - currentIndex - 1
            }
            
            if tiles[row][col] == .valid {
                return Position.from(row: row, col: col)
            }
            
            if tiles[row][col] == .wall {
                return position
            }
            
            currentIndex += 1
        }
    }
    
    private func expandRows(to newSize: Int) {
        for i in 0..<tiles.count {
            for _ in tiles[i].count..<newSize {
                tiles[i].append(.invalid)
            }
        }
    }
}

var instructions = [Instruction(count: 0, heading: .right)]

var map = Map()

var currentMapRow = 0

let filePath = "/Users/grayson/code/advent_of_code/2022/day_twenty_two/test.txt"
guard let filePointer = fopen(filePath, "r") else {
    preconditionFailure("Could not open file at \(filePath)")
}
var lineByteArrayPointer: UnsafeMutablePointer<CChar>?
defer {
    fclose(filePointer)
    lineByteArrayPointer?.deallocate()
}
var lineCap: Int = 0
while getline(&lineByteArrayPointer, &lineCap, filePointer) > 0 {
    let line = String(cString: lineByteArrayPointer!)
    let lineArray = Array(line).dropLast(1)
    
    if lineArray.isEmpty {
        continue
    }
    
    if lineArray[0].isNumber {
        var number = 0
        var index = 0
        var numberIndex = 0
        while index < lineArray.count {
            let character = lineArray[index]
            if character.isLetter {
                let heading = instructions.last!.heading.rotated(from: character)
                let instruction = Instruction(count: number, heading: heading)
                instructions.append(instruction)
                
                number = 0
                numberIndex = 0
                index += 1
                continue
            }
            
            number = number * (10 * numberIndex) + Int(String(character))!
            
            numberIndex += 1
            index += 1
        }
        
    } else {
        map.add(row: lineArray.map({ Tile(from: $0) }))
        
        currentMapRow += 1
    }
}

for row in map.tiles {
    print(row)
}
print(instructions)
