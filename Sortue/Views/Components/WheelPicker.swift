import SwiftUI

struct WheelPicker<Data, Content>: View where Data: RandomAccessCollection, Data.Element: Equatable, Data.Index == Int, Content: View {
    let items: Data
    let initialIndex: Int
    let visibleItemsCount: Int
    let itemHeight: CGFloat
    let onSelectionChanged: (Int) -> Void
    let itemContent: (Data.Element, Bool) -> Content
    
    // Multiplier to create the illusion of infinity
    private let multiplier = 1000
    
    @State private var centeredIndex: Int = 0
    @State private var scrollOffset: CGFloat = 0
    
    // Haptics
    private let hapticGenerator = UISelectionFeedbackGenerator()
    
    init(
        items: Data,
        initialIndex: Int = 0,
        visibleItemsCount: Int = 5,
        itemHeight: CGFloat = 60,
        onSelectionChanged: @escaping (Int) -> Void,
        @ViewBuilder itemContent: @escaping (Data.Element, Bool) -> Content
    ) {
        self.items = items
        self.initialIndex = initialIndex
        self.visibleItemsCount = visibleItemsCount
        self.itemHeight = itemHeight
        self.onSelectionChanged = onSelectionChanged
        self.itemContent = itemContent
        
        // Initialize state logic for "center"
        _centeredIndex = State(initialValue: (items.count * multiplier / 2) + initialIndex)
    }
    
    var body: some View {
        GeometryReader { geometry in
            let viewportHeight = geometry.size.height
            let centerY = viewportHeight / 2
            
            ScrollView(.vertical, showsIndicators: false) {
                LazyVStack(spacing: 0) {
                    ForEach(0..<(items.count * multiplier), id: \.self) { globalIndex in
                        let itemIndex = globalIndex % items.count
                        let item = items[itemIndex]
                        
                        GeometryReader { itemGeo in
                            let itemMidY = itemGeo.frame(in: .named("ScrollContainer")).midY
                            let distanceFromCenter = abs(centerY - itemMidY)
                            
                            // Visual Transform Logic based on Kotlin implementation
                            // Center (distance 0) -> Scale 1.2, Alpha 1.0
                            // Edge -> Scale 0.7, Alpha 0.3
                            
                            let maxDist = (CGFloat(visibleItemsCount) * itemHeight) / 2.0
                            let distFraction = min(distanceFromCenter / maxDist, 1.0)
                            
                            let scale = 1.2 - (0.5 * distFraction) // Lerp(1.2, 0.7)
                            let alpha = 1.0 - (0.7 * distFraction) // Lerp(1.0, 0.3)
                            
                            // 3D Rotation
                            // Rotation limit 25 degrees
                            let rotationLimit: Double = 25
                            let rotationDegrees = Double(distFraction) * rotationLimit * (itemMidY < centerY ? 1 : -1)

                            itemContent(item, globalIndex == centeredIndex)
                                .frame(width: itemGeo.size.width) // Force width to match container to ensure centering
                                .scaleEffect(scale)
                                .opacity(alpha)
                                .rotation3DEffect(
                                    .degrees(rotationDegrees),
                                    axis: (x: 1, y: 0, z: 0),
                                    perspective: 0.5
                                )
                                // Detect centering for logic
                                .onChange(of: itemGeo.frame(in: .named("ScrollContainer")).minY) { _ in
                                    // This runs frequently during scroll. 
                                    // We check if this item is the "closest" one now.
                                    // Optimization: Only check if within reasonable range.
                                    if distanceFromCenter < (itemHeight / 2) {
                                        // We avoid updating state during view update if possible, 
                                        // but onChange is safe.
                                        // However, `centeredIndex` drives scrollPosition too.
                                        // If we update `centeredIndex` here, it might fight with scrollPosition?
                                        // Actually `scrollPosition` modifier UPDATES the binding when scrolling stops (or during?).
                                        // We are using `scrollPosition` to READ the scroll position into centeredIndex.
                                        // But `scrollPosition` typically tracks the identity of the top/center item.
                                        // We don't need this manual GeometryReader logic if .scrollPosition works correctly!
                                        // But `scrollPosition` updates ONLY when scroll stops? No, it updates as you scroll if it's view aligned?
                                        // Let's rely on scrollPosition modifier and REMOVE manual calculation if possible.
                                        // BUT, we need `centeredIndex` for the visual transforms in real-time?
                                        // No, visual transforms use `distanceFromCenter` which is computed from GeometryReader.
                                        // So we only need `centeredIndex` for the logic `globalIndex == centeredIndex` and `onSelectionChanged`.
                                        
                                        // Let's let the `scrollPosition` modifier handle updating `centeredIndex`.
                                    }
                                }
                        }
                        .frame(height: itemHeight)
                    }
                }
                .scrollTargetLayout() // Metadata for scrollPosition
                // Padding to center the content initially if needed, 
                // but ScrollTargetBehavior solves snapping.
            }
            .coordinateSpace(name: "ScrollContainer")
            .scrollTargetBehavior(.viewAligned) // iOS 17 Snap
            .scrollPosition(id: scrollPositionBinding, anchor: .center)
            .frame(height: itemHeight * CGFloat(visibleItemsCount))
            .onAppear {
                // Prepare haptics
                hapticGenerator.prepare()
                
                // Initial Scroll Step
                // We need to set the initial scroll position.
                // Using scrollPosition(id:) with an Int binding corresponding to the ForEach ID data values.
                // Since ForEach uses Int range, we can bind to Int.
            }
            .onChange(of: centeredIndex) { newVal in
                let realIndex = newVal % items.count
                onSelectionChanged(realIndex)
                hapticGenerator.selectionChanged()
                
                // Reset logic for infinite loop illusion
                // If we get too far from true center, jump back.
                // Center of whole list is (count * multiplier / 2)
                // We do this check silently if possible, but SwiftUI scroll jump might be visible.
                // Given multiplier=1000, it's unlikely a user scrolls 500 sets.
                // We can skip the complex reset logic for now unless requested strictly.
                // The Kotlin one does it, but doing it in SwiftUI smoothly without jank is hard.
                // 1000 copies is usually enough for "infinite" feel.
            }
        }
    }
    
    // Binding helper for scrollPosition
    // scrollPosition takes a Binding<ID?>. Our IDs are Ints.
    private var scrollPositionBinding: Binding<Int?> {
        Binding<Int?>(
            get: { centeredIndex },
            set: { val in
                if let val = val {
                    centeredIndex = val
                }
            }
        )
    }
}
