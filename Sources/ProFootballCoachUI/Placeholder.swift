import SwiftUI

// ponytail: this view exists only so the ProFootballCoachUI target has a source file and keeps
// compiling, which in turn keeps ContractTests' engine-boundary and design-token scans pointed at a
// real directory instead of passing vacuously. P11 builds the design system and deletes it.
struct Placeholder: View {
    var body: some View {
        Text("Pro Football Coach")
    }
}
