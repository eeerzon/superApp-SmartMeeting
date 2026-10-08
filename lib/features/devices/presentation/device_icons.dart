import 'package:flutter/material.dart';

import '../domain/entities/device_options.dart';
import '../domain/entities/device_type.dart';

// Icon mapping for device types and options (domain stays Flutter-free).

extension DeviceTypeIcon on DeviceType {
  IconData get icon => switch (this) {
        DeviceType.ifp => Icons.cast_rounded,
        DeviceType.ac => Icons.ac_unit_rounded,
        DeviceType.light => Icons.lightbulb_outline_rounded,
        DeviceType.audio => Icons.speaker_outlined,
        DeviceType.camera => Icons.videocam_outlined,
        DeviceType.door => Icons.door_front_door_outlined,
      };
}

extension AcModeIcon on AcMode {
  IconData get icon => switch (this) {
        AcMode.cool => Icons.ac_unit_rounded,
        AcMode.heat => Icons.local_fire_department_outlined,
        AcMode.fan => Icons.air_rounded,
        AcMode.auto => Icons.auto_awesome_outlined,
        AcMode.dry => Icons.water_drop_outlined,
      };
}

extension IfpPowerIcon on IfpPower {
  IconData get icon => switch (this) {
        IfpPower.on => Icons.power_settings_new_rounded,
        IfpPower.hibernate => Icons.bedtime_outlined,
        IfpPower.off => Icons.power_off_outlined,
      };
}

extension DisplayModeIcon on DisplayMode {
  IconData get icon => switch (this) {
        DisplayMode.standard => Icons.radio_button_checked_rounded,
        DisplayMode.clear => Icons.contrast_rounded,
        DisplayMode.bright => Icons.wb_sunny_outlined,
        DisplayMode.custom => Icons.tune_rounded,
      };
}

extension InputSourceIcon on InputSource {
  IconData get icon => switch (this) {
        InputSource.hdmi1 || InputSource.hdmi2 => Icons.settings_input_hdmi_outlined,
        InputSource.vga => Icons.settings_input_component_outlined,
        InputSource.wireless => Icons.cast_rounded,
      };
}

extension AudioPresetIcon on AudioPreset {
  IconData get icon => switch (this) {
        AudioPreset.meeting => Icons.groups_outlined,
        AudioPreset.presentation => Icons.co_present_outlined,
        AudioPreset.videoCall => Icons.video_call_outlined,
        AudioPreset.music => Icons.music_note_outlined,
      };
}

extension CameraModeIcon on CameraMode {
  IconData get icon => switch (this) {
        CameraMode.autoFraming => Icons.center_focus_strong_outlined,
        CameraMode.speakerTracking => Icons.record_voice_over_outlined,
        CameraMode.manual => Icons.open_with_rounded,
      };
}

extension DoorAccessIcon on DoorAccessMethod {
  IconData get icon => switch (this) {
        DoorAccessMethod.card => Icons.badge_outlined,
        DoorAccessMethod.pin => Icons.dialpad_rounded,
        DoorAccessMethod.cardAndPin => Icons.verified_user_outlined,
      };
}
