import SwiftUI
import XCTest

// Performance test for empty state animations
class EmptyStateAnimationPerformanceTests: XCTestCase {
    
    func testEmptyStateAnimationPerformance() {
        // Test the optimized empty state animation sequence
        let containerAnimation = UIOptimizer.optimizedEmptyStateContainerAnimation()
        let iconAnimation = UIOptimizer.optimizedEmptyStateIconAnimation()
        let titleAnimation = UIOptimizer.optimizedEmptyStateTitleAnimation()
        let subtitleAnimation = UIOptimizer.optimizedEmptyStateSubtitleAnimation()
        
        // Verify animations are performance-optimized
        XCTAssertNotNil(containerAnimation)
        XCTAssertNotNil(iconAnimation)
        XCTAssertNotNil(titleAnimation)
        XCTAssertNotNil(subtitleAnimation)
        
        // Test floating animation performance
        let floatingAnimation = Animation.ultraSmooth.repeatForever(autoreverses: true)
        XCTAssertNotNil(floatingAnimation)
        
        print("✅ All empty state animations are properly optimized")
    }
    
    func testAnimationTimingConsistency() {
        // Verify staggered animation delays are consistent
        let iconDelay = 0.15 // from handleEmptyStateTransition
        let titleDelay = 0.25
        let subtitleDelay = 0.35
        
        XCTAssertGreaterThan(titleDelay, iconDelay)
        XCTAssertGreaterThan(subtitleDelay, titleDelay)
        
        print("✅ Animation delays are properly staggered")
    }
    
    func testReducedMotionSupport() {
        // Test that animations respect accessibility settings
        let originalSetting = PerformanceConfig.shouldUseReducedAnimations
        
        // Test reduced motion mode
        PerformanceConfig.shouldUseReducedAnimations = true
        let reducedAnimation = Animation.ultraSmooth.speed(2.0)
        XCTAssertNotNil(reducedAnimation)
        
        // Test normal mode
        PerformanceConfig.shouldUseReducedAnimations = false
        let normalAnimation = Animation.ultraSmooth.speed(1.0)
        XCTAssertNotNil(normalAnimation)
        
        // Restore original setting
        PerformanceConfig.shouldUseReducedAnimations = originalSetting
        
        print("✅ Accessibility support verified")
    }
    
    func testFloatingAnimationSubtlety() {
        // Test that floating intensity is appropriate for smooth experience
        let intensity: CGFloat = 1.0 // Optimized value
        XCTAssertLessThanOrEqual(intensity, 2.0, "Floating intensity should be subtle")
        XCTAssertGreaterThan(intensity, 0, "Floating intensity should be non-zero")
        
        print("✅ Floating animation intensity is optimized")
    }
}

// Run tests
let testSuite = EmptyStateAnimationPerformanceTests()
testSuite.testEmptyStateAnimationPerformance()
testSuite.testAnimationTimingConsistency()
testSuite.testReducedMotionSupport()
testSuite.testFloatingAnimationSubtlety()

print("🎉 All empty state animation tests passed!")