//import SwiftUI
//
//struct CustomTabStyle: ViewModifier {
//    let isSelected: Bool
//    let isEnvironments: Bool
//    
//    func body(content: Content) -> some View {
//        content
//            .padding(.vertical, 8)
//            .padding(.horizontal, 16)
//            .background(
//                RoundedRectangle(cornerRadius: 12)
//                    .fill(isSelected ? 
//                          (isEnvironments ? Color.blue.opacity(0.2) : Color.gray.opacity(0.2)) : 
//                          Color.clear)
//            )
//            .overlay(
//                RoundedRectangle(cornerRadius: 12)
//                    .stroke(isSelected ? 
//                           (isEnvironments ? Color.blue : Color.gray) : 
//                           Color.clear, 
//                           lineWidth: 1)
//            )
//    }
//}
//
//extension View {
//    func customTabStyle(isSelected: Bool, isEnvironments: Bool = false) -> some View {
//        modifier(CustomTabStyle(isSelected: isSelected, isEnvironments: isEnvironments))
//    }
//} 
