//
//  File.swift
//  ChessboardKit
//
//  Created by Stanley Pratama Teguh on 01/05/26.
//

import Foundation

// models
public enum MoveEvaluation: String, Sendable, Codable{
    case best =  "Best Move"
    case brilliant = "Brilliant"
    case blunder = "Blunder"
    case correct = "Correct"
    case good = "Good"
    case great = "Great"
    case mistake = "Mistake"
    
}

public struct PuzzleLevel: Sendable, Codable{
    public let id: Int
    public let objective: String
    public let initialFEN: String
    public let columns: Int
    public let rows: Int
    public let rootNode: PuzzleNode
    
    public init(id: Int, objective: String, initialFEN: String, columns: Int, rows: Int, rootNode: PuzzleNode) {
        self.id = id
        self.objective = objective
        self.initialFEN = initialFEN
        self.columns = columns
        self.rows = rows
        self.rootNode = rootNode
        
    }
    
}

public final class PuzzleNode: Sendable, Codable{
    // this will be a dict -> mapping player LAN
    public let expectedMoves: [String: MoveOutcome]
    public init(expectedMoves: [String : MoveOutcome]) {
        self.expectedMoves = expectedMoves
    }
}

public struct MoveOutcome: Sendable, Codable{
    public let evaluation: MoveEvaluation
    public let feedback: String
    public let cpuReplyLAN: String?
    public let nextNode: PuzzleNode?
    
    public init(evaluation: MoveEvaluation, feedback: String, cpuReplyLAN: String? = nil, nextNode: PuzzleNode? = nil) {
        self.evaluation = evaluation
        self.feedback = feedback
        self.cpuReplyLAN = cpuReplyLAN
        self.nextNode = nextNode
    }
    
}



// puzzle database yey :) -> will be on JSON parser and format

// decoder
extension PuzzleLevel{
    public static func load (fromBundle fileName: String) throws -> PuzzleLevel {
        guard let url = Bundle.main.url(forResource: fileName, withExtension: "json") else {
            throw NSError(domain: "PuzzleLevel", code: 404, userInfo: [NSLocalizedDescriptionKey: "File not found"])
        }
        
        let data = try Data(contentsOf: url)
        let decoder = JSONDecoder()
        return try decoder.decode(PuzzleLevel.self, from: data)
    }
    
}
