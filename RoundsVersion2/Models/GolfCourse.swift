import Foundation
import FirebaseFirestore

struct GolfCourse: Identifiable, Codable {
    let id: String
    let name: String
    let city: String
    let state: String
    let tees: [TeeSet]
    let holes: [Hole]
    let lastUpdated: Date
    
    struct TeeSet: Codable {
        let name: String // e.g., "Blue", "White", "Red"
        let rating: Double
        let slope: Int
        let yardages: [Int] // Array of 18 yardages
        
        var totalYardage: Int {
            yardages.reduce(0, +)
        }
    }
    
    struct Hole: Codable {
        let number: Int
        let par: Int
        let handicap: Int
    }
    
    var asDictionary: [String: Any] {
        [
            "id": id,
            "name": name,
            "city": city,
            "state": state,
            "tees": tees.map { tee in
                [
                    "name": tee.name,
                    "rating": tee.rating,
                    "slope": tee.slope,
                    "yardages": tee.yardages
                ]
            },
            "holes": holes.map { hole in
                [
                    "number": hole.number,
                    "par": hole.par,
                    "handicap": hole.handicap
                ]
            },
            "lastUpdated": Timestamp(date: lastUpdated)
        ]
    }
    
    static func from(_ document: DocumentSnapshot) -> GolfCourse? {
        guard 
            let data = document.data(),
            let name = data["name"] as? String,
            let city = data["city"] as? String,
            let state = data["state"] as? String,
            let teesData = data["tees"] as? [[String: Any]],
            let holesData = data["holes"] as? [[String: Any]],
            let lastUpdated = (data["lastUpdated"] as? Timestamp)?.dateValue()
        else { return nil }
        
        let tees = teesData.compactMap { teeData -> TeeSet? in
            guard
                let name = teeData["name"] as? String,
                let rating = teeData["rating"] as? Double,
                let slope = teeData["slope"] as? Int,
                let yardages = teeData["yardages"] as? [Int]
            else { return nil }
            
            return TeeSet(name: name, rating: rating, slope: slope, yardages: yardages)
        }
        
        let holes = holesData.compactMap { holeData -> Hole? in
            guard
                let number = holeData["number"] as? Int,
                let par = holeData["par"] as? Int,
                let handicap = holeData["handicap"] as? Int
            else { return nil }
            
            return Hole(number: number, par: par, handicap: handicap)
        }
        
        return GolfCourse(
            id: document.documentID,
            name: name,
            city: city,
            state: state,
            tees: tees,
            holes: holes,
            lastUpdated: lastUpdated
        )
    }
} 