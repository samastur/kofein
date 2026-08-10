import KofeinCore
import SwiftUI

/// Profile manager: list of profiles on the left, editor for the selected
/// profile on the right. Every option shows its help text as a caption and
/// as a tooltip.
struct ProfilesView: View {
    @Bindable var store: ProfileStoreBox
    @State private var selectedID: UUID?
    @State private var errorTitle: String?

    init(store: ProfileStore) {
        self.store = ProfileStoreBox(store: store)
        _selectedID = State(initialValue: store.defaultProfileID)
    }

    var body: some View {
        HStack(spacing: 0) {
            profileList
                .frame(width: 200)
            Divider()
            if let profile = store.profile(id: selectedID) {
                ProfileEditor(
                    profile: profile,
                    isDefault: profile.id == store.store.defaultProfileID,
                    onChange: { updated in perform { try store.store.update(updated) } },
                    onSetDefault: { perform { try store.store.setDefault(id: profile.id) } }
                )
                .id(profile.id)
            } else {
                Text("")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(minWidth: 640, minHeight: 440)
        .alert(errorTitle ?? "", isPresented: .init(
            get: { errorTitle != nil },
            set: { if !$0 { errorTitle = nil } }
        )) {
            Button("OK", role: .cancel) {}
        }
    }

    private var profileList: some View {
        VStack(spacing: 0) {
            List(selection: $selectedID) {
                ForEach(store.store.profiles) { profile in
                    HStack {
                        Text(profile.name)
                        Spacer()
                        if profile.id == store.store.defaultProfileID {
                            Text(L10n.string("editor.default.badge"))
                                .font(.caption)
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(.tint.opacity(0.2), in: Capsule())
                        }
                    }
                    .tag(profile.id)
                }
            }
            Divider()
            HStack {
                Button {
                    let profile = Profile(name: L10n.string("editor.newProfile.name"),
                                          options: CaffeinateOptions())
                    perform { try store.store.add(profile) }
                    selectedID = profile.id
                } label: {
                    Image(systemName: "plus")
                }
                .help(L10n.string("editor.add"))

                Button {
                    guard let id = selectedID else { return }
                    perform { try store.store.delete(id: id) }
                    selectedID = store.store.defaultProfileID
                } label: {
                    Image(systemName: "minus")
                }
                .help(L10n.string("editor.delete"))
                .disabled(selectedID == nil || store.store.profiles.count <= 1)

                Spacer()
            }
            .buttonStyle(.borderless)
            .padding(8)
        }
    }

    private func perform(_ action: () throws -> Void) {
        do {
            try action()
        } catch {
            errorTitle = L10n.string("alert.saveFailed.title")
        }
    }
}

/// `@Observable` box so SwiftUI observes the store through a `@Bindable`-friendly wrapper.
@Observable
final class ProfileStoreBox {
    let store: ProfileStore
    init(store: ProfileStore) { self.store = store }

    func profile(id: UUID?) -> Profile? {
        guard let id else { return nil }
        return store.profiles.first(where: { $0.id == id })
    }
}

/// Editor for a single profile. Owns a local copy and pushes every change up.
private struct ProfileEditor: View {
    @State var profile: Profile
    let isDefault: Bool
    let onChange: (Profile) -> Void
    let onSetDefault: () -> Void

    var body: some View {
        Form {
            Section {
                TextField(L10n.string("editor.name.label"), text: $profile.name)
            }
            Section {
                optionToggle("option.display", $profile.options.preventDisplaySleep)
                optionToggle("option.idle", $profile.options.preventIdleSleep)
                optionToggle("option.disk", $profile.options.preventDiskSleep)
                optionToggle("option.systemAC", $profile.options.preventSystemSleepOnAC)
                optionToggle("option.userActive", $profile.options.declareUserActive)
            }
            Section {
                labeled("option.pid") {
                    TextField("", value: $profile.options.waitForPID, format: .number)
                        .frame(width: 120)
                }
                labeled("option.command") {
                    TextField("", text: .init(
                        get: { profile.options.utilityCommand ?? "" },
                        set: { profile.options.utilityCommand = $0.isEmpty ? nil : $0 }
                    ))
                }
            }
            Section {
                Button(L10n.string("editor.setDefault"), action: onSetDefault)
                    .disabled(isDefault)
            }
        }
        .formStyle(.grouped)
        .onChange(of: profile) { _, updated in onChange(updated) }
    }

    private func optionToggle(_ keyPrefix: String, _ binding: Binding<Bool>) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Toggle(L10n.string("\(keyPrefix).label"), isOn: binding)
            helpCaption(keyPrefix)
        }
        .help(L10n.string("\(keyPrefix).help"))
    }

    private func labeled(_ keyPrefix: String, @ViewBuilder control: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            LabeledContent(L10n.string("\(keyPrefix).label")) { control() }
            helpCaption(keyPrefix)
        }
        .help(L10n.string("\(keyPrefix).help"))
    }

    private func helpCaption(_ keyPrefix: String) -> some View {
        Text(L10n.string("\(keyPrefix).help"))
            .font(.caption)
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: false, vertical: true)
    }
}
