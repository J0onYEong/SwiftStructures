//
//  RBTreeNode.swift
//  SwiftStructures
//
//  Created by choijunios on 10/10/24.
//

import Foundation

public class RBTreeNode<Value> where Value: Comparable {
    
    typealias Node = RBTreeNode<Value>
    
    public enum NodeColor {
        case red
        case black
    }
    
    // Node information
    public private(set) var value: Value?
    var color: NodeColor
    var isEmptyNode: Bool { value == nil }
    
    // Parent node
    var parent: Node? = nil
    
    // Children nodes
    var leftChild: Node? = nil
    var rightChild: Node? = nil
    
    
    init(value: Value?, color: NodeColor, parent: Node? = nil) {
        self.value = value
        self.color = color
        self.parent = parent
        if value != nil {
            self.leftChild = makeEmptyLeafNode()
            self.rightChild = makeEmptyLeafNode()
        }
    }
    
    
    /// Set a node to child
    func setToChild(_ node: Node) {
        
        // set node's parent as self
        node.parent = self
        
        if node > self {
            self.rightChild = node
        } else if node < self {
            self.leftChild = node
        } else {
            fatalError("BST node's values should be unique")
        }
    }
    
    
    /// Find sibiling node
    func getSibilingNode(_ node: Node) -> Node {
        
        if leftChild === node {
            return rightChild!
            
        } else if rightChild === node {
            return leftChild!
            
        } else {
            fatalError("\(#function) this isn't child of current node")
        }
    }
    
    
    /// Release node from this node's child and set parent node to nil
    func removeChild(_ node: Node) {
        if leftChild === node {
            leftChild = makeEmptyLeafNode()
            node.parent = nil
            
        } else if rightChild === node {
            rightChild = makeEmptyLeafNode()
            node.parent = nil
            
        } else {
            fatalError("\(#function) this isn't child of current node")
        }
    }
    
    
    /// change value for replacing
    func changeValue(_ value: Value) {
        self.value = value
    }
}


// MARK: About subtree
extension RBTreeNode {
    
    /// Return the biggest node in right subtree except for empty node.
    func findTheBiggestNodeInSubtree() -> (Node, Int) {
        
        var depth: Int = 0
        
        var biggestNode: Node = self
        
        while(!biggestNode.rightChild!.isEmptyNode) {
            biggestNode = biggestNode.rightChild!
            
            // count up
            depth += 1
        }
        
        return (biggestNode, depth)
    }
    
    /// Return the smallest node in right subtree except for empty node.
    func findTheSmallestNodeInSubtree() -> (Node, Int) {
        
        var depth: Int = 0
        
        var smallestNode: Node = self
        
        while(!smallestNode.leftChild!.isEmptyNode) {
            smallestNode = smallestNode.leftChild!
            
            // count up
            depth += 1
        }
        
        return (smallestNode, depth)
    }
}


// MARK: Empty leaf node
private extension RBTreeNode {
    
    /// A basic leaf node with no value and a default black color.
    func makeEmptyLeafNode() -> Node {
        let leafNode: Node = .init(value: nil, color: .black)
        leafNode.parent = self
        return leafNode
    }
}


// MARK: Comparable
extension RBTreeNode: Comparable {
    
    public static func == (lhs: RBTreeNode<Value>, rhs: RBTreeNode<Value>) -> Bool {
        lhs.value! == rhs.value!
    }
    
    public static func < (lhs: RBTreeNode<Value>, rhs: RBTreeNode<Value>) -> Bool {
        lhs.value! < rhs.value!
    }
}


// MARK: Children state
extension RBTreeNode {
    
    enum NodeChildrenState {
        case noChildren
        case twins
        case leftOnly
        case rightOnly
    }
    
    /// returns children state of node
    var childrenState: NodeChildrenState? {
        guard let leftChild, let rightChild else {
            // this node is empty leaf node
            return nil
        }
        if !leftChild.isEmptyNode && !rightChild.isEmptyNode {
            return .twins
        } else if !leftChild.isEmptyNode {
            return .leftOnly
        } else if !rightChild.isEmptyNode {
            return .rightOnly
        } else {
            return .noChildren
        }
    }
}
