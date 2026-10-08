import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/scene_repository_impl.dart';
import '../../domain/entities/scene.dart';
import '../../domain/repositories/scene_repository.dart';

final sceneRepositoryProvider = Provider<SceneRepository>((ref) => SceneRepositoryImpl());

final scenesProvider = Provider<List<Scene>>((ref) => ref.watch(sceneRepositoryProvider).presets());
