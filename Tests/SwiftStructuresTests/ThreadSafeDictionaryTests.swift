//
//  ThreadSafeDictionary.swift
//  SwiftStructuresTests
//
//  Created by choijunios on 10/11/24.
//

import XCTest
@testable import SwiftStructures

final class ThreadSafeDictionary: XCTestCase {

    func testThreadSaftyForLockedDictionary() {
        let dictionary = LockedDictionary<Int, String>()
        let expectation = XCTestExpectation(description: "Multiple threads access LockedDictionary safely")
        expectation.expectedFulfillmentCount = 90 // 300개의 완료되기를 기다림
        
        DispatchQueue.concurrentPerform(iterations: 30) { index in
            
            let key = index
            let testValue = "Value \(index)"
            
            DispatchQueue.global().async {
                
                dictionary[key] = testValue // 쓰기 작업
                
                expectation.fulfill() // 스레드 작업 완료
            }
            
            DispatchQueue.global().async {
                let _ = dictionary[key] // 읽기 작업(실패가능, 런타임 에러만 아니면 통과)
                
                expectation.fulfill() // 스레드 작업 완료
            }
            
            DispatchQueue.global().async {
                dictionary.remove(key: key) // 삭제 작업
                XCTAssertNil(dictionary[key]) // 삭제후 값이 없어야함
                
                expectation.fulfill() // 스레드 작업 완료
            }
        }
        
        wait(for: [expectation], timeout: 10.0) // 5초 내에 모든 스레드가 완료되기를 기대
    }
}
