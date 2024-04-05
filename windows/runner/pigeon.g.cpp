// Autogenerated from Pigeon (v18.0.0), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#undef _HAS_EXCEPTIONS

#include "pigeon.g.h"

#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>

namespace pigeon {
using flutter::BasicMessageChannel;
using flutter::CustomEncodableValue;
using flutter::EncodableList;
using flutter::EncodableMap;
using flutter::EncodableValue;

FlutterError CreateConnectionError(const std::string channel_name) {
    return FlutterError(
        "channel-error",
        "Unable to establish connection on channel: '" + channel_name + "'.",
        EncodableValue(""));
}

// Generated class from Pigeon that represents Flutter messages that can be called from C++.
Native2Flutter::Native2Flutter(flutter::BinaryMessenger* binary_messenger)
 : binary_messenger_(binary_messenger),
    message_channel_suffix_("") {}

Native2Flutter::Native2Flutter(
  flutter::BinaryMessenger* binary_messenger,
  const std::string& message_channel_suffix)
 : binary_messenger_(binary_messenger),
    message_channel_suffix_(message_channel_suffix.length() > 0 ? std::string(".") + message_channel_suffix : "") {}

const flutter::StandardMessageCodec& Native2Flutter::GetCodec() {
  return flutter::StandardMessageCodec::GetInstance(&flutter::StandardCodecSerializer::GetInstance());
}

void Native2Flutter::OnClick(
  bool forward_arg,
  std::function<void(void)>&& on_success,
  std::function<void(const FlutterError&)>&& on_error) {
  const std::string channel_name = "dev.flutter.pigeon.desktop_adb_file_browser.Native2Flutter.onClick" + message_channel_suffix_;
  BasicMessageChannel<> channel(binary_messenger_, channel_name, &GetCodec());
  EncodableValue encoded_api_arguments = EncodableValue(EncodableList{
    EncodableValue(forward_arg),
  });
  channel.Send(encoded_api_arguments, [channel_name, on_success = std::move(on_success), on_error = std::move(on_error)](const uint8_t* reply, size_t reply_size) {
    std::unique_ptr<EncodableValue> response = GetCodec().DecodeMessage(reply, reply_size);
    const auto& encodable_return_value = *response;
    const auto* list_return_value = std::get_if<EncodableList>(&encodable_return_value);
    if (list_return_value) {
      if (list_return_value->size() > 1) {
        on_error(FlutterError(std::get<std::string>(list_return_value->at(0)), std::get<std::string>(list_return_value->at(1)), list_return_value->at(2)));
      } else {
        on_success();
      }
    } else {
      on_error(CreateConnectionError(channel_name));
    } 
  });
}

}  // namespace pigeon
