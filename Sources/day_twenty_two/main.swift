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

enum Direction: String {
    case left = "L"
    case right = "R"
    case forward
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

    var toInt: Int {
        switch self {
        case .up:
            return 3
        case .down:
            return 1
        case .left:
            return 2
        case .right:
            return 0
        }
    }

    func rotated(to direction: Direction) -> Heading {
        switch direction {
        case .left:
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
        case .right:
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
        case .forward:
            return self
        }
    }
    
    func rotated(from character: Character) -> Heading {
        let direction = Direction(rawValue: String(character))!
        return rotated(to: direction)
    }
}

struct Position: Hashable, CustomStringConvertible {
    var x: Int
    var y: Int
    
    static var zero: Position = Position(x: 0, y: 0)
    
    static func from(row: Int, col: Int) -> Position {
        Position(x: col, y: row)
    }

    var description: String {
        "(\(x), \(y))"
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
    let turnDirection: Direction
    
    var description: String {
        "\(count)\(turnDirection)"
    }
}

class Player {
    var position: Position = .zero
    var heading: Heading = .right
}

enum Edge: Hashable {
    case row(row: Int, cols: ClosedRange<Int>)
    case col(col: Int, rows: ClosedRange<Int>)
}

// 2d map, (0, 0) top left
class Map {
    var tiles = [[Tile]]()

    func at(position: Position) -> Tile {
        guard !isOutOfBounds(position) else {
            fatalError()
        }

        let index = position.toRowCol()
        return tiles[index.row][index.col]
    }
    
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
                return
            }
        }
    }
    
    func simulate(player: inout Player, instruction: Instruction) {

        // First do the movement, with current heading
        var currentCount = 0
        while currentCount < instruction.count {
            print("Doing a move")
            let move = canMove(from: player.position, heading: player.heading)
            if !move.canMove {
                print("Can't hit a wall, will stay here")
                // we're done! we hit a wall
                break
            }

            player.position = move.newPosition
            player.heading = move.heading
            currentCount += 1
        }

        // Then affect the heading
        player.heading = player.heading.rotated(to: instruction.turnDirection)
    }
    
    private func canMove(from position: Position, heading: Heading) -> (canMove: Bool, newPosition: Position, heading: Heading) {
        let toPosition = position.moved(to: heading)
        print("cm: potential position=\(toPosition)")
        if isOutOfBounds(toPosition) || at(position: toPosition) == .invalid {
            print("cm: Would go out of bounds or invalid, find wrap around")
            let valid = findNextValid(from: position, heading: heading)
            print("cm: got=\(valid)")
            if valid.position == position {
                print("cm: We hit a wall")
                return (canMove: false, newPosition: position, heading: heading)
            }

            return (canMove: true, newPosition: valid.position, heading: valid.heading)

//        } else if at(position: toPosition) == .invalid {
//            print("cm: Would go to invalid, find wrap around")
//            let valid = findNextValid(from: position, heading: heading)
//            print("cm: got=\(valid)")
//            if valid.position == position {
//                print("cm: We hit a wall")
//                return (canMove: false, newPosition: position, heading: heading)
//            }
//
//            return (canMove: true, newPosition: valid.position, heading: valid.heading)

        } else if at(position: toPosition) == .wall {
            print("cm: We hit a wall")
            return (canMove: false, newPosition: position, heading: heading)
        }

        print("cm: good to go")
        return (canMove: true, newPosition: toPosition, heading: heading)
    }
    
    private func isOutOfBounds(_ position: Position) -> Bool {
        if position.x < 0 || position.x >= tiles[0].count {
            return true
        }
        
        if position.y < 0 || position.y >= tiles.count {
            return true
        }
        
        return false
    }
    
    private func findNextValid(from position: Position, heading: Heading) -> (position: Position, heading: Heading) {
        let wrapped = MapWrapper.input[position]!

        if at(position: wrapped.position) == .valid {
            return wrapped
        }

        if at(position: wrapped.position) == .wall {
            return (position: position, heading: heading)
        }

        fatalError()

        // PT 1
//        let startIndex = position.toRowCol()
//        var currentIndex = 0
//        while true {
//            let row: Int
//            let col: Int
//
//            switch heading {
//            case .up:
//                row = tiles.count - currentIndex - 1
//                col = startIndex.col
//
//            case .down:
//                row = currentIndex
//                col = startIndex.col
//
//            case .left:
//                row = startIndex.row
//                col = tiles[0].count - currentIndex - 1
//
//            case .right:
//                row = startIndex.row
//                col = currentIndex
//            }
//
//            if tiles[row][col] == .valid {
//                return Position.from(row: row, col: col)
//            }
//
//            if tiles[row][col] == .wall {
//                return position
//            }
//
//            currentIndex += 1
//        }
    }
    
    private func expandRows(to newSize: Int) {
        for i in 0..<tiles.count {
            for _ in tiles[i].count..<newSize {
                tiles[i].append(.invalid)
            }
        }
    }
}

var instructions = [Instruction]()

var map = Map()

var currentMapRow = 0

let filePath = "/Users/graysonsmith/code/advent_of_code/2022/aoc22_day_twenty_two/input.txt"
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
                let turnDirection = Direction(rawValue: String(character))!
                let instruction = Instruction(count: number, turnDirection: turnDirection)
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

        let turnDirection = Direction.forward
        let instruction = Instruction(count: number, turnDirection: turnDirection)
        instructions.append(instruction)
        
    } else {
        map.add(row: lineArray.map({ Tile(from: $0) }))
        
        currentMapRow += 1
    }
}

for i in 0..<map.tiles[0].count {
    print(i, terminator: "")
}
print()
for row in map.tiles {
    for elem in row {
        print(elem, terminator: "")
    }
    print()
}
print(instructions)

var player = Player()
map.placePlayerAtStart(&player)
for instruction in instructions {
    print("running \(instruction)")
    map.simulate(player: &player, instruction: instruction)
    print("  position=\(player.position)")
    print("  heading=\(player.heading)")
}

print(1000*(player.position.y + 1) + 4*(player.position.x + 1) + player.heading.toInt)

struct MapWrapper {
    static let test: [Position: (position: Position, heading: Heading)] = {
        var lookup = [Position: (position: Position, heading: Heading)]()
        // top 0 to top 1
        for col in 8...11 {
            let position = Position(x: col, y: 0)
            let newPosition = Position(x: 3 - (col - 8), y: 4)
            let newHeading = Heading.down
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 0 to right 5
        for row in 0...3 {
            let position = Position(x: 11, y: row)
            let newPosition = Position(x: 15, y: 11 - row)
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 3 to top 5
        for row in 4...7 {
            let position = Position(x: 11, y: row)
            let newPosition = Position(x: 15 - (row - 4), y: 8)
            let newHeading = Heading.down
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // top 5 to right 3
        for col in 12...15 {
            let position = Position(x: col, y: 8)
            let newPosition = Position(x: 15, y: 4 + (col - 12))
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 5 to right 0
        for row in 8...11 {
            let position = Position(x: 15, y: row)
            let newPosition = Position(x: 11, y: 3 - (row - 8))
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 5 to left 1
        for col in 12...15 {
            let position = Position(x: col, y: 11)
            let newPosition = Position(x: 0, y: 8 - (col - 12))
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 4 to bottom 1
        for col in 8...11 {
            let position = Position(x: col, y: 11)
            let newPosition = Position(x: 3 - (col - 8), y: 7)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // left 4 to bottom 2
        for row in 8...11 {
            let position = Position(x: 8, y: row)
            let newPosition = Position(x: 7 - (row - 8), y: 7)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 2 to left 4
        for col in 4...7 {
            let position = Position(x: col, y: 7)
            let newPosition = Position(x: 8, y: 11 - (col - 4))
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 1 to bottom 4
        for col in 0...3 {
            let position = Position(x: col, y: 7)
            let newPosition = Position(x: 11 - col, y: 11)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // left 1 to bottom 5
        for row in 4...7 {
            let position = Position(x: 0, y: row)
            let newPosition = Position(x: 15 - (row - 4), y: 11)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // top 1 to top 0
        for col in 0...3 {
            let position = Position(x: col, y: 4)
            let newPosition = Position(x: 11 - col, y: 0)
            let newHeading = Heading.down
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // top 2 to left 0
        for col in 4...7 {
            let position = Position(x: col, y: 4)
            let newPosition = Position(x: 8, y: 7 - (col - 4))
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }
        return lookup
    }()

    static let input: [Position: (position: Position, heading: Heading)] = {
        var lookup = [Position: (position: Position, heading: Heading)]()

        // top 0 to left 5
        for col in 50...99 {
            let position = Position(x: col, y: 0)
            let newPosition = Position(x: 0, y: 150 + (col - 50))
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // top 1 to bottom 5
        for col in 100...149 {
            let position = Position(x: col, y: 0)
            let newPosition = Position(x: (col - 100), y: 199)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 1 to right 3
        for row in 0...49 {
            let position = Position(x: 149, y: row)
            let newPosition = Position(x: 99, y: 149 - row)
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 1 to right 2
        for col in 100...149 {
            let position = Position(x: col, y: 49)
            let newPosition = Position(x: 99, y: 50 + (col - 100))
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 2 to bottom 1
        for row in 50...99 {
            let position = Position(x: 99, y: row)
            let newPosition = Position(x: 100 + (row - 50), y: 49)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 3 to right 1
        for row in 100...149 {
            let position = Position(x: 99, y: row)
            let newPosition = Position(x: 149, y: 49 - (row - 100))
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 3 to right 5
        for col in 50...99 {
            let position = Position(x: col, y: 149)
            let newPosition = Position(x: 49, y: 150 + (col - 50))
            let newHeading = Heading.left
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // right 5 to bottom 3
        for row in 150...199 {
            let position = Position(x: 49, y: row)
            let newPosition = Position(x: 50 + (row - 150), y: 149)
            let newHeading = Heading.up
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // bottom 5 to top 1
        for col in 0...49 {
            let position = Position(x: col, y: 199)
            let newPosition = Position(x: 100 + col, y: 0)
            let newHeading = Heading.down
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // left 5 to top 0
        for row in 150...199 {
            let position = Position(x: 0, y: row)
            let newPosition = Position(x: 50 + (row - 150), y: 0)
            let newHeading = Heading.down
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // left 4 to left 0
        for row in 100...149 {
            let position = Position(x: 0, y: row)
            let newPosition = Position(x: 50, y: 49 - (row - 100))
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // top 4 to left 2
        for col in 0...49 {
            let position = Position(x: col, y: 100)
            let newPosition = Position(x: 50, y: 50 + col)
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // left 2 to top 4
        for row in 50...99 {
            let position = Position(x: 50, y: row)
            let newPosition = Position(x: row - 50, y: 100)
            let newHeading = Heading.down
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        // left 0 to left 4
        for row in 0...49 {
            let position = Position(x: 50, y: row)
            let newPosition = Position(x: 0, y: 149 - row)
            let newHeading = Heading.right
            lookup[position] = (position: newPosition, heading: newHeading)
        }

        return lookup
    }()
}
