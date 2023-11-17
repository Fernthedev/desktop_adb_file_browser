// Autogenerated from Pigeon (v13.1.1), do not edit directly.
// See also: https://pub.dev/packages/pigeon

#ifndef PIGEON_PIGEON_HPP_
#define PIGEON_PIGEON_HPP_
#include <flutter/basic_message_channel.h>
#include <flutter/binary_messenger.h>
#include <flutter/encodable_value.h>
#include <flutter/standard_message_codec.h>

#include <map>
#include <optional>
#include <string>



// Generated class from Pigeon.
// Generated class from Pigeon that represents Flutter messages that can be called from C++.
class Native2Flutter {
 public:
  Native2Flutter(flutter::BinaryMessenger* binary_messenger);
  static const flutter::StandardMessageCodec& GetCodec();
  void OnClick(
    bool forward,
    std::function<void(void)>&& on_success,
    std::function<void(const FlutterError&)>&& on_error);

 private:
  flutter::BinaryMessenger* binary_messenger_;
};

#endif  // PIGEON_PIGEON_HPP_
