import SwiftUI

struct ReportFormView: View {
    @EnvironmentObject var store: AppStore
    @State private var date = Date()
    @State private var showDatePicker = false
    @State private var selectedBrandId: Int64?
    @State private var currentValues: [Int] = []
    @State private var combinedEntries: [CombinedReportEntry] = []
    @State private var alertMessage: String?
    
    private var fieldCount: Int { store.reportFields.count }
    
    private var summaryTotal: Int {
        let current = currentValues.prefix(fieldCount).reduce(0, +)
        let fromEntries = combinedEntries.reduce(0) { sum, e in sum + e.values.prefix(fieldCount).reduce(0, +) }
        return current + fromEntries
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 16) {
                Text("Создание отчёта")
                    .font(Theme.sectionFont)
                    .foregroundStyle(Theme.textPrimary)
                
                if store.reportFields.isEmpty {
                    Text("Элементы отчёта не настроены. Пройдите онбординг при первом запуске или добавьте роль в настройках.")
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textSecondary)
                        .padding(20)
                } else {
                    mainForm
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(20)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Сообщение", isPresented: .init(get: { alertMessage != nil }, set: { if !$0 { alertMessage = nil } })) {
            Button("OK", role: .cancel) { alertMessage = nil }
        } message: {
            if let m = alertMessage { Text(m) }
        }
        .onAppear {
            if let draft = store.reportFormDraft {
                date = draft.date
                selectedBrandId = draft.selectedBrandId
                currentValues = draft.currentValues
                combinedEntries = draft.combinedEntries
            }
            syncCurrentValues()
        }
        .onDisappear {
            store.reportFormDraft = ReportFormDraft(
                date: date,
                selectedBrandId: selectedBrandId,
                currentValues: currentValues,
                combinedEntries: combinedEntries
            )
        }
        .onChange(of: fieldCount) { _ in syncCurrentValues() }
    }
    
    private func syncCurrentValues() {
        if fieldCount == 0 { return }
        if currentValues.count != fieldCount {
            currentValues = (0..<fieldCount).map { currentValues.indices.contains($0) ? currentValues[$0] : 0 }
        }
    }
    
    private var mainForm: some View {
        VStack(alignment: .leading, spacing: 16) {
            GroupBox("Данные отчёта") {
                VStack(alignment: .leading, spacing: 14) {
                    dateRow
                    brandRow
                    ForEach(Array(store.reportFields.enumerated()), id: \.element.id) { index, field in
                        StepperRow(
                            label: field.label + ":",
                            value: Binding(
                                get: { currentValues.indices.contains(index) ? currentValues[index] : 0 },
                                set: { newVal in
                                    var v = currentValues
                                    while v.count <= index { v.append(0) }
                                    if index < v.count { v[index] = newVal }
                                    currentValues = v
                                }
                            )
                        )
                    }
                    HStack(spacing: 12) {
                        Button("Добавить в отчёт") { addToCombined() }
                            .buttonStyle(FramedSuccessButtonStyle())
                            .font(Theme.labelFont)
                        Button("Очистить список") { combinedEntries.removeAll() }
                            .buttonStyle(FramedDangerButtonStyle())
                            .font(Theme.labelFont)
                    }
                }
                .padding(12)
            }
            .groupBoxStyle(ThemeGroupBoxStyle())
            
            GroupBox("Добавленные бренды в отчёт") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Список брендов на выбранную дату:")
                        .font(Theme.smallFont)
                        .foregroundStyle(Theme.textPrimary)
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(combinedEntries) { entry in
                                HStack(alignment: .center, spacing: 12) {
                                    Text(brandName(entry.brandId))
                                        .font(Theme.bodyFont)
                                        .foregroundStyle(Theme.textPrimary)
                                    Spacer()
                                    Text(entryValuesSummary(entry))
                                        .font(Theme.smallFont)
                                        .foregroundStyle(Theme.textPrimary)
                                    Button("Удалить") { deleteEntry(entry) }
                                        .buttonStyle(FramedDangerButtonStyle())
                                        .font(Theme.smallFont)
                                }
                                .padding(.horizontal, 12)
                                .padding(.vertical, 10)
                                .background(Theme.rowBackground)
                                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
                                .cornerRadius(Theme.cornerRadiusSmall)
                                .padding(.vertical, 2)
                            }
                        }
                        .padding(2)
                    }
                    .frame(maxHeight: 200)
                }
                .padding(12)
            }
            .groupBoxStyle(ThemeGroupBoxStyle())
            
            HStack(spacing: 12) {
                Button("Сохранить отчёт") { saveReport() }
                    .buttonStyle(FramedPrimaryButtonStyle())
                    .font(Theme.labelFont)
                Button("Копировать в буфер") { copyToClipboard() }
                    .buttonStyle(FramedSecondaryButtonStyle())
                    .font(Theme.labelFont)
            }
            
            Text("Брендов в отчёте: \(combinedEntries.count)  ·  Всего: \(summaryTotal.formatted(.number.grouping(.automatic)))")
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Theme.accentLight.opacity(0.4))
                .cornerRadius(8)
        }
    }
    
    private func entryValuesSummary(_ entry: CombinedReportEntry) -> String {
        store.reportFields.enumerated().map { i, f in "\(f.label): \(entry.value(at: i))" }.joined(separator: "  ")
    }
    
    private func brandName(_ id: Int64) -> String {
        store.brands.first { $0.id == id }?.name ?? "ID:\(id)"
    }
    
    private func addToCombined() {
        guard let bid = selectedBrandId else {
            alertMessage = "Выберите бренд"
            return
        }
        let values = (0..<fieldCount).map { currentValues.indices.contains($0) ? currentValues[$0] : 0 }
        if values.allSatisfy({ $0 == 0 }) {
            alertMessage = "Заполните хотя бы одно поле"
            return
        }
        let padded = (0..<15).map { values.indices.contains($0) ? values[$0] : 0 }
        if let idx = combinedEntries.firstIndex(where: { $0.brandId == bid }) {
            combinedEntries[idx] = CombinedReportEntry(brandId: bid, values: padded)
        } else {
            combinedEntries.append(CombinedReportEntry(brandId: bid, values: padded))
        }
        currentValues = Array(repeating: 0, count: fieldCount)
    }
    
    private func deleteEntry(_ entry: CombinedReportEntry) {
        combinedEntries.removeAll { $0.id == entry.id }
    }
    
    private func saveReport() {
        guard !combinedEntries.isEmpty else {
            alertMessage = "Добавьте хотя бы один бренд в отчёт"
            return
        }
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: date)
        if store.db.addCombinedReport(date: startOfDay, entries: combinedEntries) {
            store.refresh()
            store.reportFormDraft = nil
            let total = combinedEntries.reduce(0) { $0 + $1.values.prefix(fieldCount).reduce(0, +) }
            alertMessage = "Отчёт сохранён.\nДата: \(formatDate(date))\nБрендов: \(combinedEntries.count)\nВсего: \(total.formatted(.number.grouping(.automatic)))"
            combinedEntries.removeAll()
        } else {
            alertMessage = "Не удалось сохранить отчёт"
        }
    }
    
    private func copyToClipboard() {
        if combinedEntries.isEmpty && (currentValues.isEmpty || currentValues.allSatisfy { $0 == 0 }) {
            alertMessage = "Нет данных для копирования"
            return
        }
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        var text = "\(df.string(from: date))\n\n"
        if !combinedEntries.isEmpty {
            for e in combinedEntries {
                text += "\(brandName(e.brandId))\n"
                for (i, f) in store.reportFields.enumerated() {
                    text += "\(f.label): \(e.value(at: i))\n"
                }
                text += "\n"
            }
        } else if let bid = selectedBrandId {
            text += "\(brandName(bid))\n"
            for (i, f) in store.reportFields.enumerated() {
                text += "\(f.label): \(currentValues.indices.contains(i) ? currentValues[i] : 0)\n"
            }
        }
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(text, forType: .string)
        alertMessage = "Отчёт скопирован в буфер обмена"
    }
    
    private func formatDate(_ d: Date) -> String {
        let df = DateFormatter()
        df.dateFormat = "dd.MM.yyyy"
        return df.string(from: d)
    }
    
    private func formatDateLong(_ d: Date) -> String {
        let df = DateFormatter()
        df.locale = Locale(identifier: "ru_RU")
        df.dateFormat = "d MMMM yyyy"
        return df.string(from: d)
    }
    
    private var dateRow: some View {
        HStack(alignment: .center, spacing: Theme.spacingS) {
            Text("Дата:")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Theme.formLabelWidth, alignment: .leading)
            Button {
                showDatePicker = true
            } label: {
                HStack(spacing: Theme.spacingM) {
                    Image(systemName: "calendar.circle.fill")
                        .font(.system(size: 24))
                        .foregroundStyle(.white)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(formatDateLong(date))
                            .font(Theme.bodyFont)
                            .foregroundStyle(Theme.textPrimary)
                        Text(formatDate(date))
                            .font(Theme.smallFont)
                            .foregroundStyle(Theme.textSecondary)
                    }
                    Spacer()
                    Image(systemName: "chevron.down.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(.white)
                }
                .padding(.horizontal, Theme.spacingL)
                .padding(.vertical, Theme.spacingM)
                .frame(maxWidth: .infinity, minHeight: 56)
                .background {
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                                .fill(Theme.inputBackground)
                                .blendMode(.plusLighter)
                        )
                }
                .overlay(
                    RoundedRectangle(cornerRadius: Theme.cornerRadius)
                        .stroke(Theme.glassBorder, lineWidth: 1)
                )
                .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
            }
            .buttonStyle(.plain)
            .popover(isPresented: $showDatePicker, arrowEdge: .bottom) {
                datePickerPopover
            }
        }
    }
    
    private var datePickerPopover: some View {
        let calendarSize: CGFloat = 180
        let scale: CGFloat = 2.25
        return ZStack {
            Color.clear
                .frame(width: calendarSize * scale, height: calendarSize * scale)
            DatePicker("", selection: $date, in: ...Date(), displayedComponents: .date)
                .datePickerStyle(.graphical)
                .labelsHidden()
                .tint(Theme.accent)
                .frame(width: calendarSize, height: calendarSize)
                .scaleEffect(scale)
        }
        .frame(width: calendarSize * scale, height: calendarSize * scale)
        .clipped()
        .padding(Theme.spacingM)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: Theme.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: Theme.cornerRadius)
                .stroke(Theme.glassBorder, lineWidth: 1)
        )
    }
    
    private var brandRow: some View {
        HStack(alignment: .center, spacing: 12) {
            Text("Бренд:")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Theme.formLabelWidth, alignment: .leading)
            Menu {
                Button("— Выберите бренд —") { selectedBrandId = nil }
                Divider()
                ForEach(store.brands) { b in
                    Button(b.name) { selectedBrandId = b.id }
                }
            } label: {
                HStack {
                    Text(selectedBrandId == nil ? "— Выберите бренд —" : (store.brands.first(where: { $0.id == selectedBrandId })?.name ?? "—"))
                        .font(Theme.bodyFont)
                        .foregroundStyle(Theme.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption.bold())
                        .foregroundStyle(Theme.textSecondary)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .frame(maxWidth: .infinity)
                .background(Theme.inputBackground)
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
            }
            .menuStyle(.borderlessButton)
            .frame(maxWidth: .infinity)
        }
    }
}

struct StepperRow: View {
    let label: String
    @Binding var value: Int
    
    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Text(label)
                .font(Theme.labelFont)
                .foregroundStyle(Theme.textPrimary)
                .frame(width: Theme.formLabelWidth, alignment: .leading)
            TextField("", value: $value, format: .number)
                .textFieldStyle(.plain)
                .font(Theme.bodyFont)
                .foregroundStyle(Theme.textPrimary)
                .padding(.horizontal, 10)
                .padding(.vertical, 8)
                .frame(maxWidth: .infinity)
                .background(Theme.inputBackground)
                .overlay(RoundedRectangle(cornerRadius: Theme.cornerRadiusSmall).stroke(Theme.border, lineWidth: 1))
                .cornerRadius(Theme.cornerRadiusSmall)
            Stepper("", value: $value, in: 0...1_000_000)
                .labelsHidden()
        }
    }
}

