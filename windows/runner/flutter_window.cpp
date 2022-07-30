#include "flutter_window.h"

#include "pigeon.hpp"

#include <optional>

#include <flutter/event_channel.h>
#include <flutter/event_sink.h>
#include <flutter/event_stream_handler_functions.h>

#include <flutter/standard_method_codec.h>
#include <windows.h>

#include <memory>

#include "flutter/generated_plugin_registrant.h"

FlutterWindow::FlutterWindow(const flutter::DartProject &project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());

  nativeToFlutter = std::make_unique<Native2Flutter>(flutter_controller_->engine()->messenger());

  SetChildContent(flutter_controller_->view()->GetNativeWindow());
  return true;
}

void FlutterWindow::OnDestroy() {
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  // std::cout
  //     << "Received " << message << std::endl;

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
      // FERN BACK/FORWARD MOUSE BUTTONS
    case 793: { // WM_XBUTTONUP
      int flag = GET_XBUTTON_WPARAM(lparam); // HIWORD(wparam);

      bool forward = flag & XBUTTON2;
      // bool backward = flag & XBUTTON2;

      // std::cout
      //     << "Forward pressed " << (forward ? "true" : "false")
      //     << " flag " << wparam << " " << lparam << std::endl;

      nativeToFlutter->onClick(forward, [](){});
      break;
    }
    }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}
