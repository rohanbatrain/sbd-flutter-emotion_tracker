import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:emotion_tracker/providers/family/family_provider.dart';

// Workspace types
enum WorkspaceType { personal, family, team }

// Workspace model
class Workspace {
  final WorkspaceType type;
  final String id;
  final String name;
  final String? description;

  const Workspace({
    required this.type,
    required this.id,
    required this.name,
    this.description,
  });

  // Personal workspace (default)
  static const personal = Workspace(
    type: WorkspaceType.personal,
    id: 'personal',
    name: 'Personal',
    description: 'Your personal workspace',
  );

  // Factory for family workspace
  factory Workspace.family(String familyId, String familyName) {
    return Workspace(
      type: WorkspaceType.family,
      id: familyId,
      name: familyName,
      description: 'Family workspace',
    );
  }

  // Factory for team workspace
  factory Workspace.team(String teamId, String teamName) {
    return Workspace(
      type: WorkspaceType.team,
      id: teamId,
      name: teamName,
      description: 'Team workspace',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Workspace && other.type == type && other.id == id;
  }

  @override
  int get hashCode => Object.hash(type, id);

  @override
  String toString() => 'Workspace(type: $type, id: $id, name: $name)';
}

// Workspace state
class WorkspaceState {
  final Workspace currentWorkspace;
  final List<Workspace> availableWorkspaces;
  final bool isLoading;
  final String? error;

  const WorkspaceState({
    required this.currentWorkspace,
    required this.availableWorkspaces,
    required this.isLoading,
    this.error,
  });

  WorkspaceState copyWith({
    Workspace? currentWorkspace,
    List<Workspace>? availableWorkspaces,
    bool? isLoading,
    String? error,
  }) {
    return WorkspaceState(
      currentWorkspace: currentWorkspace ?? this.currentWorkspace,
      availableWorkspaces: availableWorkspaces ?? this.availableWorkspaces,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  // Get families from available workspaces
  List<Workspace> get families =>
      availableWorkspaces.where((w) => w.type == WorkspaceType.family).toList();

  // Get teams from available workspaces
  List<Workspace> get teams =>
      availableWorkspaces.where((w) => w.type == WorkspaceType.team).toList();
}

// Workspace notifier
class WorkspaceNotifier extends StateNotifier<WorkspaceState> {
  WorkspaceNotifier()
    : super(
        const WorkspaceState(
          currentWorkspace: Workspace.personal,
          availableWorkspaces: [Workspace.personal],
          isLoading: false,
        ),
      );

  // Switch to a workspace
  void switchWorkspace(Workspace workspace) {
    state = state.copyWith(currentWorkspace: workspace);
  }

  // Add a family workspace
  void addFamilyWorkspace(String familyId, String familyName) {
    final familyWorkspace = Workspace.family(familyId, familyName);
    final updatedWorkspaces = [...state.availableWorkspaces];
    // Remove existing family with same id if exists
    updatedWorkspaces.removeWhere(
      (w) => w.id == familyId && w.type == WorkspaceType.family,
    );
    updatedWorkspaces.add(familyWorkspace);
    state = state.copyWith(availableWorkspaces: updatedWorkspaces);
  }

  // Add a team workspace
  void addTeamWorkspace(String teamId, String teamName) {
    final teamWorkspace = Workspace.team(teamId, teamName);
    final updatedWorkspaces = [...state.availableWorkspaces];
    // Remove existing team with same id if exists
    updatedWorkspaces.removeWhere(
      (w) => w.id == teamId && w.type == WorkspaceType.team,
    );
    updatedWorkspaces.add(teamWorkspace);
    state = state.copyWith(availableWorkspaces: updatedWorkspaces);
  }

  // Remove a workspace
  void removeWorkspace(String workspaceId) {
    if (workspaceId == 'personal') return; // Can't remove personal workspace

    final updatedWorkspaces = state.availableWorkspaces
        .where((w) => w.id != workspaceId)
        .toList();

    // If current workspace is being removed, switch to personal
    Workspace newCurrentWorkspace = state.currentWorkspace;
    if (state.currentWorkspace.id == workspaceId) {
      newCurrentWorkspace = Workspace.personal;
    }

    state = state.copyWith(
      currentWorkspace: newCurrentWorkspace,
      availableWorkspaces: updatedWorkspaces,
    );
  }

  // Load workspaces from external sources (families, teams)
  Future<void> loadWorkspaces({
    List<Map<String, dynamic>>? families,
    List<Map<String, dynamic>>? teams,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final updatedWorkspaces = [Workspace.personal]; // Always include personal

      // Add families
      if (families != null) {
        for (final family in families) {
          final familyId =
              family['family_id'] as String? ?? family['id'] as String?;
          final familyName = family['name'] as String? ?? 'Unnamed Family';
          if (familyId != null) {
            updatedWorkspaces.add(Workspace.family(familyId, familyName));
          }
        }
      }

      // Add teams (when teams are implemented)
      if (teams != null) {
        for (final team in teams) {
          final teamId = team['team_id'] as String? ?? team['id'] as String?;
          final teamName = team['name'] as String? ?? 'Unnamed Team';
          if (teamId != null) {
            updatedWorkspaces.add(Workspace.team(teamId, teamName));
          }
        }
      }

      state = state.copyWith(
        availableWorkspaces: updatedWorkspaces,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void clearError() {
    state = state.copyWith(error: null);
  }
}

// Workspace provider
final workspaceProvider =
    StateNotifierProvider<WorkspaceNotifier, WorkspaceState>((ref) {
      final notifier = WorkspaceNotifier();

      // Watch family list provider and sync families to workspaces
      ref.listen(familyListProvider, (previous, next) {
        if (next.families.isNotEmpty) {
          // Convert family models to workspace format
          final families = next.families.map((family) {
            return {'family_id': family.familyId, 'name': family.name};
          }).toList();

          // Load families into workspace provider
          notifier.loadWorkspaces(families: families);
        }
      }, fireImmediately: true);

      // Automatically load families when workspace provider is created
      Future.microtask(() {
        ref.read(familyListProvider.notifier).loadFamilies();
      });

      return notifier;
    });

// Current workspace provider (convenience)
final currentWorkspaceProvider = Provider<Workspace>((ref) {
  return ref.watch(workspaceProvider).currentWorkspace;
});

// Available workspaces provider
final availableWorkspacesProvider = Provider<List<Workspace>>((ref) {
  return ref.watch(workspaceProvider).availableWorkspaces;
});

// Family workspaces provider
final familyWorkspacesProvider = Provider<List<Workspace>>((ref) {
  return ref.watch(workspaceProvider).families;
});

// Team workspaces provider
final teamWorkspacesProvider = Provider<List<Workspace>>((ref) {
  return ref.watch(workspaceProvider).teams;
});
