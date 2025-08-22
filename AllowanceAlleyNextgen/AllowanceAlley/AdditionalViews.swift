import SwiftUI

struct ApprovalsView: View { var body: some View { Text("Approvals") } }
struct ReportsView: View { var body: some View { Text("Reports") } }
struct ParentSettingsView: View { var body: some View { Text("Parent Settings") } }
struct ChildDashboardView: View { let childId: String; var body: some View { Text("Child Dashboard for \\(childId)") } }
struct ChildChoresView: View { let childId: String; var body: some View { Text("Child Chores for \\(childId)") } }
struct RewardsView: View { let childId: String; var body: some View { Text("Rewards for \\(childId)") } }
struct ChildSettingsView: View { let childId: String; var body: some View { Text("Child Settings for \\(childId)") } }