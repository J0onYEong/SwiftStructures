//
//  RBTreeError.swift
//  SwiftStructures
//
//  Created by choijunios on 10/10/24.
//

import Foundation

public enum RBTreeError: String, Error, LocalizedError {
    case emptyTree = "Tree is empty"
    case duplicatedElement = "BST node's values should be unique"
    case cantFindElementInTree = "Element not found in tree"
    
    public var errorDescription: String? {
        return self.rawValue
    }
}
