import SwiftUI

struct PrivacyPolicyView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Group {
                    Text("privacy_title_full".localized)
                        .font(.headline)
                        .padding(.bottom, 8)
                    
                    Text("privacy_section1_title".localized)
                        .font(.subheadline).bold()
                    Text("privacy_section1_body".localized)
                    
                    Text("privacy_section2_title".localized)
                        .font(.subheadline).bold()
                    Text("privacy_section2_body".localized)
                    
                    Text("privacy_section3_title".localized)
                        .font(.subheadline).bold()
                    Text("privacy_section3_body".localized)
                    
                    Text("privacy_section4_title".localized)
                        .font(.subheadline).bold()
                    Text("privacy_section4_body".localized)
                }
                
                Group {
                    Text("privacy_section5_title".localized)
                        .font(.subheadline).bold()
                    Text("privacy_section5_body".localized)
                    
                    Text("privacy_contact_title".localized)
                        .font(.subheadline).bold()
                    Text("privacy_contact_body".localized)
                }
            }
            .padding()
            .foregroundColor(DesignSystem.Colors.textPrimary)
        }
        .background(DesignSystem.Colors.background)
        .navigationTitle("privacy".localized)
    }
}
