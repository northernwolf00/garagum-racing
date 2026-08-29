import 'package:get/get.dart';

/// Definition of a vehicle in Garagum Racing.
class VehicleConfig {
  final String id;
  final String name;
  final String bodyAsset;
  final String wheelAsset;
  final String? headlightAsset;
  final bool showDriver;
  final double engine;
  final double suspension;
  final double tires;
  final double fuel;
  final bool unlocked;
  final int unlockCost;

  const VehicleConfig({
    required this.id,
    required this.name,
    required this.bodyAsset,
    required this.wheelAsset,
    this.headlightAsset,
    this.showDriver = false,
    required this.engine,
    required this.suspension,
    required this.tires,
    required this.fuel,
    required this.unlocked,
    required this.unlockCost,
  });

  /// Localized display name. Falls back to the raw [name] if no translation
  /// exists for this vehicle id.
  String get displayName {
    const keyById = {
      'buggy': 'vehicle_buggy',
      'uaz': 'vehicle_uaz',
      'ak_ulag': 'vehicle_white',
      'pikap': 'vehicle_pickup',
    };
    final key = keyById[id];
    return key != null ? key.tr : name;
  }

  String get fullBodyAsset => bodyAsset.startsWith('assets/') ? bodyAsset : 'assets/images/$bodyAsset';
  String get fullWheelAsset => wheelAsset.startsWith('assets/') ? wheelAsset : 'assets/images/$wheelAsset';

  /// Ordered cheapest → most expensive so the garage reads as a progression.
  /// `unlocked` here means "owned for free from the start" — only the Buggy.
  /// The rest are bought with coins (persisted via GameProgressService).
  static const List<VehicleConfig> allVehicles = [
    VehicleConfig(
      id: 'buggy',
      name: 'Buggy',
      bodyAsset: 'vehicles/car_body.png',
      wheelAsset: 'vehicles/car_wheel.png',
      showDriver: true,
      engine: 0.35,
      suspension: 0.4,
      tires: 0.5,
      fuel: 0.45,
      unlocked: true,
      unlockCost: 0,
    ),
    VehicleConfig(
      id: 'uaz',
      name: 'UAZ',
      bodyAsset: 'images_derweze/vehicles/uaz_body.png',
      wheelAsset: 'images_derweze/vehicles/uaz_wheel.png',
      headlightAsset: 'images_derweze/vehicles/headlight_beam.png',
      showDriver: false,
      engine: 0.55,
      suspension: 0.6,
      tires: 0.5,
      fuel: 0.65,
      unlocked: false,
      unlockCost: 15000,
    ),
    VehicleConfig(
      id: 'ak_ulag',
      name: 'Ak ulag',
      bodyAsset: 'images_ashgabat/vehicles/ak_ulag_body.png',
      wheelAsset: 'images_ashgabat/vehicles/ak_ulag_wheel.png',
      showDriver: false,
      engine: 0.6,
      suspension: 0.5,
      tires: 0.55,
      fuel: 0.6,
      unlocked: false,
      unlockCost: 40000,
    ),
    VehicleConfig(
      id: 'pikap',
      name: 'Pikap',
      bodyAsset: 'images_yangykala/vehicles/pikap_body.png',
      wheelAsset: 'images_yangykala/vehicles/pikap_wheel.png',
      showDriver: false,
      engine: 0.7,
      suspension: 0.65,
      tires: 0.75,
      fuel: 0.7,
      unlocked: false,
      unlockCost: 90000,
    ),
  ];

  static VehicleConfig getById(String id) {
    return allVehicles.firstWhere(
      (v) => v.id == id,
      orElse: () => allVehicles.first,
    );
  }
}
