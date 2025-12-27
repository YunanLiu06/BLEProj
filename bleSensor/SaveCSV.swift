//
//  SaveCSV.swift
//  bleSensor
//
//  Created by Louis Lew on 12/26/25.
//

import Foundation

struct CSVExporter {
    
    static func savePressureSamples(
        _ samples: [PressureSample]
    ) throws -> URL {
        
        var csv = "Time,UTC Time,Oil Pressure,Oil Temperature\n"
        
        for s in samples {
            csv += String(format: "%.3f,%d,%.3f,%.3f\n",
                          s.elapsedTime,
                          s.utcTimestamp,
                          s.pressure,
                          s.temperature)
        }
        
        let fileURL = try makeFileURL()
        try csv.write(to: fileURL, atomically: true, encoding: .utf8)
        
        return fileURL
    }
    
    private static func makeFileURL() throws -> URL {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmmss"
        
        let fileName = "PressureLog_\(formatter.string(from: Date())).csv"
        
        let docs = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask)
            .first!
        
        return docs.appendingPathComponent(fileName)
    }
}
