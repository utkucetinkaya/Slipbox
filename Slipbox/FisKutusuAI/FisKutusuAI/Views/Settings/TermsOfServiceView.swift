import SwiftUI

struct TermsOfServiceView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("terms_title_full".localized)
                    .font(.headline)
                    .padding(.bottom, 8)
                
                Text("terms_section1_title".localized)
                    .font(.subheadline).bold()
                Text("terms_section1_body".localized)
                
                Text("terms_section2_title".localized)
                    .font(.subheadline).bold()
                Text("terms_section2_body".localized)
                
                Text("terms_section3_title".localized)
                    .font(.subheadline).bold()
                Text("terms_section3_body".localized)
                
                Text("terms_section4_title".localized)
                    .font(.subheadline).bold()
                Text("terms_section4_body".localized)
                
                Text("terms_section5_title".localized)
                    .font(.subheadline).bold()
                Text("terms_section5_body".localized)
            }
            .padding()
            .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("terms".localized)
    }
}
