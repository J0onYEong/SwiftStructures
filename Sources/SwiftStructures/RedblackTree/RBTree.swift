//
//  RBTree.swift
//  SwiftStructures
//
//  Created by choijunios on 10/10/24.
//

import Foundation

/// A Red-Black Tree implementation.
/// - Note: This type is **not thread-safe** for append and remove operations.
/// - All values in the tree must be unique. Attempting to insert a duplicate value will result in an error.
public class RBTree<Element> where Element: Comparable {
    
    public typealias Node = RBTreeNode<Element>
    
    private(set) var rootNode: Node?
    
    public init(value: Element? = nil) {
        
        if let value {
            createRoot(value)
        }
    }
    
    /// height is starting from 1
    var height: Int {
        
        guard let rootNode else { return 0 }
        
        var currentNodes = [rootNode]
        var currentHeight = 0
        
        while !currentNodes.isEmpty {
            
            currentHeight += 1
            
            var newLayer: [Node] = []
            
            currentNodes.forEach { node in
                if !node.leftChild!.isEmptyNode {
                    newLayer.append(node.leftChild!)
                }
                if !node.rightChild!.isEmptyNode {
                    newLayer.append(node.rightChild!)
                }
            }
            
            currentNodes = newLayer
        }
        
        return currentHeight
    }
    
    private func createRoot(_ value: Element) {
        // Root node is always black
        self.rootNode = .init(value: value, color: .black)
    }
}

// MARK: Appending element
public extension RBTree {
    
    /// Append elements to tree
    func append(_ values: [Element]) throws {
        for value in values {
            try append(value)
        }
    }
    
    
    /// Append element to tree
    func append(_ value: Element) throws {
        
        guard let rootNode else {
            // Root node is empty
            createRoot(value)
            return
        }
        
        // new node is always red
        let newNode: RBTreeNode = .init(value: value, color: .red)
        
        // append new node
        try append(newNode, to: rootNode)
    }
    
    private func append(_ node: Node, to: Node) throws {
        
        var currentParentNode: RBTreeNode! = to
        
        while(true) {
            
            if currentParentNode.isEmptyNode {
                // CurrentNode is empty leaf node
                currentParentNode.parent?.setToChild(node)
                break
            }
            
            if currentParentNode > node {
                // go left
                currentParentNode = currentParentNode.leftChild
            } else if currentParentNode < node {
                // go right
                currentParentNode = currentParentNode.rightChild
            } else {
                throw RBTreeError.duplicatedElement
            }
        }
        
        // start checking double red
        resolveDoubleRed(node)
    }
}


// MARK: Find node
public extension RBTree {
    
    func findNode(_ value: Element) -> Node? {
        
        guard let rootNode else { return nil }
        
        var currentNode: Node = rootNode
        
        while(currentNode.value != value) {
            
            if currentNode.value! > value {
                
                if currentNode.leftChild!.isEmptyNode {
                    return nil
                }
                currentNode = currentNode.leftChild!
            } else if currentNode.value! < value {
                
                if currentNode.rightChild!.isEmptyNode {
                    return nil
                }
                currentNode = currentNode.rightChild!
            }
        }
        
        return currentNode
    }
}


// MARK: Removing elements
public extension RBTree {
    
    func remove(_ value: Element) throws {
        
        guard let node = findNode(value) else {
            throw RBTreeError.cantFindElementInTree
        }
        
        remove(node)
    }
    
    private func remove(_ node: Node) {
        
        switch node.childrenState! {
        case .noChildren:
            whenNoChild(node)
        case .leftOnly:
            whenLeftOnly(node)
        case .rightOnly:
            whenRightOnly(node)
        case .twins:
            whenTwins(node)
        }
    }
    
    private func whenNoChild(_ node: Node) {
        // remove only this node
        node.parent?.removeChild(node)
    }
    
    private func whenLeftOnly(_ node: Node) {
        // 1. find the most biggest node in left subtree of this node
        let (biggestNodeInLeft, _): (Node, Int) = node.leftChild!.findTheBiggestNodeInSubtree()
        
        node.changeValue(biggestNodeInLeft.value!)
        
        // 2. removing recursively
        remove(biggestNodeInLeft)
    }
    
    private func whenRightOnly(_ node: Node) {
        // 1. find the most Smallest node in right subtree of this node
        let (smallestNodeInRight, _): (Node, Int) = node.rightChild!.findTheSmallestNodeInSubtree()
        
        node.changeValue(smallestNodeInRight.value!)
        
        // 2. removing recursively
        remove(smallestNodeInRight)
    }
    
    private func whenTwins(_ node: Node) {
        // 1. find biggest in left and smallest in right
        let (biggestNodeInLeft, leftDepth): (Node, Int) = node.leftChild!.findTheBiggestNodeInSubtree()
        let (smallestNodeInRight, rightDepth): (Node, Int) = node.rightChild!.findTheSmallestNodeInSubtree()
        
        // 2. compare depth of both side and choose bigger one
        let choosenNode = leftDepth > rightDepth ? biggestNodeInLeft : smallestNodeInRight
        
        // 3. removing recursively
        remove(choosenNode)
    }
}



// MARK: Resolving dobule red
private extension RBTree {
    
    func resolveDoubleRed(_ newNode: Node) {
        
        // check double red
        let parentNode = newNode.parent!
        
        if parentNode.color == .red {
            // double red condition
            
            // parent isn't root so it must has parent
            let grandNode = parentNode.parent!
            let uncleNode = grandNode.getSibilingNode(parentNode)
            
            if uncleNode.color == .red {
                
                // start recoloring
                recoloring(
                    newNode: newNode,
                    parentNode: parentNode,
                    grandNode: grandNode,
                    uncleNode: uncleNode
                )
                
            } else {
                
                // start reconstructing
                restructuring(
                    newNode: newNode,
                    parentNode: parentNode,
                    grandNode: grandNode,
                    uncleNode: uncleNode
                )
            }
        }
    }
    
    /// restructuring
    /// 1. sort newNode, parentNode, grandNode
    /// 2. make middle node to parent and the others its children.
    /// 3. make middle node to black and the others to red
    func restructuring(newNode: Node, parentNode: Node, grandNode: Node, uncleNode: Node) {
        
        // great grand node
        let greatGrandNode: Node? = grandNode === rootNode ? nil : grandNode.parent
        
        // break all relationship
        if let greatGrandNode {
            greatGrandNode.removeChild(grandNode)
        }
        grandNode.removeChild(parentNode)
        parentNode.removeChild(newNode)
    
        var sortedList = [newNode, parentNode, grandNode].sorted()
        let middleNode = sortedList.remove(at: 1)
        
        // set middle node to black
        middleNode.color = .black
        
        // save middle node's oringinal children
        let originalLeftNode: Node? = middleNode.leftChild!.isEmptyNode ? nil : middleNode.leftChild!
        if let originalLeftNode {
            middleNode.removeChild(originalLeftNode)
        }
        let originalRightNode: Node? = middleNode.rightChild!.isEmptyNode ? nil : middleNode.rightChild!
        if let originalRightNode {
            middleNode.removeChild(originalRightNode)
        }
        
        // set new children
        sortedList.forEach {
            $0.color = .red
            middleNode.setToChild($0)
        }
        
        // connect to upper layer
        if let greatGrandNode {
            greatGrandNode.setToChild(middleNode)
        } else {
            // middle node becomes root
            middleNode.parent = nil
            rootNode = middleNode
        }
        
        // relocation original children
        [originalLeftNode, originalRightNode]
            .compactMap { $0 }
            .forEach { relocatingNode in
                // this insertion not related to duplication
                try! append(relocatingNode, to: middleNode)
            }
    }
    
    
    /// recoloring
    /// 1. make parent and uncle to black
    /// 2. make grandNode to red
    /// 3. if grandNode is root, make it black
    func recoloring(newNode: Node, parentNode: Node, grandNode: Node, uncleNode: Node) {
        
        // make parent and uncle to black
        parentNode.color = .black
        uncleNode.color = .black
        
        // make grand to black whether it isn't root
        grandNode.color = .red
        
        if grandNode === rootNode {
            grandNode.color = .black
            return
        } else {
            
            // check whether grand node makes double red again
            resolveDoubleRed(grandNode)
        }
    }
}


// MARK: Get sorted array
public extension RBTree {
    
    /// if tree is empty, it throws error
    func getTheBiggestElement() throws -> Element {
        
        guard let rootNode else {
            throw RBTreeError.emptyTree
        }
        
        let (biggestNode, _) = rootNode.findTheBiggestNodeInSubtree()
        return biggestNode.value!
    }
    
    /// if tree is empty, it throws error
    func getTheSmallestElement() throws -> Element {
        
        guard let rootNode else {
            throw RBTreeError.emptyTree
        }
        
        let (smallestNode, _) = rootNode.findTheSmallestNodeInSubtree()
        return smallestNode.value!
    }
}


// MARK: Sorted list
public extension RBTree {
    
    enum SortType {
        case ASC
        case DESC
    }
    
    
    /// Return sorted elements array (O(N))
    func sortedList(type: SortType = .ASC) -> [Element] {
        
        guard let rootNode else { return [] }
        
        var elements: [Element] = []
        switch type {
        case .ASC:
            LMRTraversal(node: rootNode, elements: &elements)
        case .DESC:
            RMLTraversal(node: rootNode, elements: &elements)
        }
        
        return elements
    }
    
    
    internal func LMRTraversal(node: Node, elements: inout [Element]) {
        
        // 1. left
        if !node.leftChild!.isEmptyNode {
            
            LMRTraversal(node: node.leftChild!, elements: &elements)
        }
        
        // 2. middle
        elements.append(node.value!)
        
        
        // 3. right
        if !node.rightChild!.isEmptyNode {
            
            LMRTraversal(node: node.rightChild!, elements: &elements)
        }
    }
    
    internal func RMLTraversal(node: Node, elements: inout [Element]) {
        
        // 1. right
        if !node.rightChild!.isEmptyNode {
            
            RMLTraversal(node: node.rightChild!, elements: &elements)
        }
        
        // 2. middle
        elements.append(node.value!)
        
        // 3. left
        if !node.leftChild!.isEmptyNode {
            
            RMLTraversal(node: node.leftChild!, elements: &elements)
        }
    }
    
    // MARK: count limit traversal
    
    /// returns elements list in O(N) but, it is proportional to count
    func sortedList(type: SortType = .ASC, count: Int) -> [Element] {
        
        guard let rootNode else { return [] }
        
        var elements: [Element] = []
        var elementCount = 0
        switch type {
        case .ASC:
            let (smallestNode, _) = rootNode.findTheSmallestNodeInSubtree()
            
            reverseLMRTraversalWithCount(
                node: smallestNode,
                elements: &elements,
                currentCount: &elementCount,
                maxCount: count
            )
        case .DESC:
            let (biggestNode, _) = rootNode.findTheBiggestNodeInSubtree()
            reverseRMLTraversalWithCount(
                node: biggestNode,
                elements: &elements,
                currentCount: &elementCount,
                maxCount: count
            )
        }
        
        return elements
    }
    
    internal func LMRTraversalWithCount(node: Node, elements: inout [Element], currentCount: inout Int, maxCount: Int) {
        
        // 1. left
        if !node.leftChild!.isEmptyNode {
            
            LMRTraversalWithCount(
                node: node.leftChild!,
                elements: &elements,
                currentCount: &currentCount,
                maxCount: maxCount
            )
        }
        
        // 2. middle
        if currentCount < maxCount {
            elements.append(node.value!)
            currentCount+=1
        } else {
            return
        }
        
        
        // 3. right
        if !node.rightChild!.isEmptyNode {
            
            LMRTraversalWithCount(
                node: node.rightChild!,
                elements: &elements,
                currentCount: &currentCount,
                maxCount: maxCount
            )
        }
    }
    
    internal func RMLTraversalWithCount(node: Node, elements: inout [Element], currentCount: inout Int, maxCount: Int) {
        
        // 1. right
        if !node.rightChild!.isEmptyNode {
            
            RMLTraversalWithCount(
                node: node.rightChild!,
                elements: &elements,
                currentCount: &currentCount,
                maxCount: maxCount
            )
        }
        
        // 2. middle
        if currentCount < maxCount {
            elements.append(node.value!)
            currentCount+=1
        } else {
            return
        }
        
        // 3. left
        if !node.leftChild!.isEmptyNode {
            
            RMLTraversalWithCount(
                node: node.leftChild!,
                elements: &elements,
                currentCount: &currentCount,
                maxCount: maxCount
            )
        }
    }
    
    /// this method starts from smallest node
    internal func reverseLMRTraversalWithCount(node: Node, elements: inout [Element], currentCount: inout Int, maxCount: Int) {
        
        // 1. middle
        if currentCount < maxCount {
            elements.append(node.value!)
            currentCount+=1
        } else {
            return
        }
        
        // 2. Right
        if !node.rightChild!.isEmptyNode {
            
            LMRTraversalWithCount(
                node: node.rightChild!,
                elements: &elements,
                currentCount: &currentCount,
                maxCount: maxCount
            )
        }
        
        // 3. parent
        guard let parentNode = node.parent else { return }
        
        reverseLMRTraversalWithCount(
            node: parentNode,
            elements: &elements,
            currentCount: &currentCount,
            maxCount: maxCount
        )
    }
    
    /// this method starts from biggest node
    internal func reverseRMLTraversalWithCount(node: Node, elements: inout [Element], currentCount: inout Int, maxCount: Int) {
        
        // 1. middle
        if currentCount < maxCount {
            elements.append(node.value!)
            currentCount+=1
        } else {
            return
        }
        
        // 2. left
        if !node.leftChild!.isEmptyNode {
            
            RMLTraversalWithCount(
                node: node.leftChild!,
                elements: &elements,
                currentCount: &currentCount,
                maxCount: maxCount
            )
        }
        
        // 3. parent
        guard let parentNode = node.parent else { return }
        
        reverseRMLTraversalWithCount(
            node: parentNode,
            elements: &elements,
            currentCount: &currentCount,
            maxCount: maxCount
        )
    }
}


// MARK: for test
extension RBTree where Element == Int {
    
    /**
     You can print your tree.
     Printed node consists of 3 components:
     
     - `color`: 🟥 or ⬛️
     - `p`: parent node's value
     - `v`: node's value
    */
    public func printTree() {
        
        var printLayer: [Int: [RBTreeNode<Int>]] = [0: [rootNode!]]
        
        var currentLayerIndex = 0
        
        while(!printLayer[currentLayerIndex]!.isEmpty) {
            
            printLayer[currentLayerIndex+1] = []
            
            printLayer[currentLayerIndex]!.forEach { node in
                if !node.leftChild!.isEmptyNode {
                    printLayer[currentLayerIndex+1]!.append(node.leftChild!)
                }
                
                if !node.rightChild!.isEmptyNode {
                    printLayer[currentLayerIndex+1]!.append(node.rightChild!)
                }
            }
            
            currentLayerIndex += 1
        }
    
        
        for key in 0..<currentLayerIndex {
            
            for node in printLayer[key]! {
                
                let colorMark = node.color == .red ? "🟥" : "⬛️"
                print("\(colorMark)p:\(node.parent?.value ?? -1)v:\(node.value!)", terminator: " ")
            }
            print("\n", terminator: "")
        }
    }
}
