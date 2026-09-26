#include <flutter/dart_project.h>
#include <flutter/flutter_view_controller.h>
#include <windows.h>

#include "flutter_window.h"
#include "utils.h"

namespace {

// Unique across machines/apps so it never collides with another
// application's mutex. Ties the single-instance check to this app only.
constexpr wchar_t kSingleInstanceMutexName[] =
    L"CaisseDZ-SingleInstance-8F2E1A3C-6B4E-4C9A-9C3E-7B1D2F5A9E10";

// The window class/title used by Win32Window::Create(L"caisse_dz", ...) in
// this same executable; see win32_window.cpp (kWindowClassName).
constexpr wchar_t kWindowClassName[] = L"FLUTTER_RUNNER_WIN32_WINDOW";
constexpr wchar_t kWindowTitle[] = L"caisse_dz";

// If another instance is already running, brings its window to the
// foreground and returns true so the caller can exit without creating a
// second window.
bool FocusExistingInstanceIfAny(HANDLE instance_mutex) {
  if (instance_mutex == nullptr || ::GetLastError() != ERROR_ALREADY_EXISTS) {
    return false;
  }

  HWND existing_window = ::FindWindowW(kWindowClassName, kWindowTitle);
  if (existing_window != nullptr) {
    if (::IsIconic(existing_window)) {
      ::ShowWindow(existing_window, SW_RESTORE);
    }
    ::SetForegroundWindow(existing_window);
  }
  return true;
}

}  // namespace

int APIENTRY wWinMain(_In_ HINSTANCE instance, _In_opt_ HINSTANCE prev,
                      _In_ wchar_t *command_line, _In_ int show_command) {
  // Only one instance of the app may run at a time: if a previous instance
  // already holds this mutex, focus its window instead of opening another.
  // The handle is intentionally kept open (not closed) for the lifetime of
  // the process so it is released automatically on exit.
  HANDLE instance_mutex = ::CreateMutexW(nullptr, TRUE, kSingleInstanceMutexName);
  if (FocusExistingInstanceIfAny(instance_mutex)) {
    return EXIT_SUCCESS;
  }

  // Attach to console when present (e.g., 'flutter run') or create a
  // new console when running with a debugger.
  if (!::AttachConsole(ATTACH_PARENT_PROCESS) && ::IsDebuggerPresent()) {
    CreateAndAttachConsole();
  }

  // Initialize COM, so that it is available for use in the library and/or
  // plugins.
  ::CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);

  flutter::DartProject project(L"data");

  std::vector<std::string> command_line_arguments =
      GetCommandLineArguments();

  project.set_dart_entrypoint_arguments(std::move(command_line_arguments));

  FlutterWindow window(project);
  Win32Window::Point origin(10, 10);
  Win32Window::Size size(1280, 720);
  if (!window.Create(L"caisse_dz", origin, size)) {
    return EXIT_FAILURE;
  }
  window.SetQuitOnClose(true);

  ::MSG msg;
  while (::GetMessage(&msg, nullptr, 0, 0)) {
    ::TranslateMessage(&msg);
    ::DispatchMessage(&msg);
  }

  ::CoUninitialize();
  return EXIT_SUCCESS;
}
