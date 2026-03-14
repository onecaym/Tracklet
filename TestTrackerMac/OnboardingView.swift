import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var store: AppStore
    @State private var currentPage = 0
    @State private var roleName: String = ""
    @State private var reportFieldLabels: [String] = []
    @State private var newFieldLabel: String = ""
    @State private var alertMessage: String?
    
    private let maxReportFields = 15
    
    var body: some View {
        VStack(spacing: 0) {
            if currentPage == 0 {
                welcomePage
            } else {
                rolePage
            }
            pageIndicator
            bottomButton
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Theme.backgroundGradient)
        .padding(Theme.spacingXL)
        .alert("Сообщение", isPresented: .init(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            if let m = alertMessage { Text(m) }
        }
    }
    
    private var welcomePage: some View {
        VStack(spacing: 24) {
            Spacer()
            Image(systemName: "chart.bar.doc.plain")
                .font(.custom("Avenir Next Heavy", size: 56))
                .foregroundStyle(Theme.accent)
            Text("Tracklet")
                .font(.custom("Avenir Next Heavy", size: 110))
                .foregroundStyle(Theme.textPrimary)
            Text("Создай свой формат отчетов")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 400)
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var rolePage: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: Theme.spacingL) {
                Text("Моя роль")
                    .font(Theme.titleFont)
                    .foregroundStyle(Theme.textPrimary)
                Text("Укажите роль и элементы отчёта (до \(maxReportFields)).")
                    .font(Theme.bodyFont)
                    .foregroundStyle(Theme.textSecondary)
                
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    Text("Роль")
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.textPrimary)
                    TextField("Например: QA, Developer, Designer", text: $roleName)
                        .textFieldStyle(.plain)
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 10)
                        .frame(maxWidth: .infinity)
                        .background(Theme.inputBackground)
                        .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
                        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                }
                
                VStack(alignment: .leading, spacing: Theme.spacingXS) {
                    HStack {
                        Text("Элементы отчёта")
                            .font(Theme.labelFont)
                            .foregroundStyle(Theme.textPrimary)
                        Spacer()
                        Text("\(reportFieldLabels.count) / \(maxReportFields)")
                            .font(Theme.smallFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    
                    VStack(spacing: 8) {
                        ForEach(Array(reportFieldLabels.enumerated()), id: \.offset) { index, label in
                            HStack(spacing: 12) {
                                TextField("Название поля", text: Binding(
                                    get: { reportFieldLabels.indices.contains(index) ? reportFieldLabels[index] : "" },
                                    set: { newVal in
                                        if reportFieldLabels.indices.contains(index) {
                                            reportFieldLabels[index] = newVal
                                        }
                                    }
                                ))
                                .textFieldStyle(.plain)
                                .font(Theme.bodyFont)
                                .foregroundStyle(Theme.textPrimary)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Theme.inputBackground)
                                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                                Button {
                                    reportFieldLabels.remove(at: index)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        
                        if reportFieldLabels.count < maxReportFields {
                            Button {
                                reportFieldLabels.append("")
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle.fill")
                                        .foregroundStyle(Theme.textPrimary)
                                    Text("Добавить элемент")
                                        .font(Theme.labelFont)
                                        .foregroundStyle(Theme.textPrimary)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 12)
                                .background(Theme.accentLight.opacity(0.5))
                                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(Theme.spacingS)
                    .background(Theme.cardBackground)
                    .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
                    .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadius).stroke(Theme.border, lineWidth: 1))
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, Theme.spacingL)
        }
    }
    
    private var pageIndicator: some View {
        HStack(spacing: 8) {
            Circle()
                .fill(currentPage == 0 ? Theme.accent : Theme.border)
                .frame(width: 8, height: 8)
            Circle()
                .fill(currentPage == 1 ? Theme.accent : Theme.border)
                .frame(width: 8, height: 8)
        }
        .padding(.top, Theme.spacingXL)
    }
    
    private var bottomButton: some View {
        Button {
            if currentPage == 0 {
                currentPage = 1
            } else {
                saveAndFinish()
            }
        } label: {
            Text(currentPage == 0 ? "Далее" : "Начать")
                .font(Theme.labelFont)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
        }
        .buttonStyle(FramedPrimaryButtonStyle())
        .frame(maxWidth: 280)
        .padding(.top, Theme.spacingL)
    }
    
    private func saveAndFinish() {
        let name = roleName.trimmingCharacters(in: .whitespacesAndNewlines)
        if name.isEmpty {
            alertMessage = "Введите название роли"
            return
        }
        let labels = reportFieldLabels.map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }.filter { !$0.isEmpty }
        if labels.isEmpty {
            alertMessage = "Добавьте хотя бы один элемент отчёта"
            return
        }
        store.db.setUserRole(name)
        if store.db.setReportFields(labels: labels) {
            store.db.setOnboardingDone(true)
            store.roleName = name
            store.reportFields = store.db.getReportFields()
            store.hasCompletedOnboarding = true
        } else {
            alertMessage = "Не удалось сохранить настройки"
        }
    }
}
