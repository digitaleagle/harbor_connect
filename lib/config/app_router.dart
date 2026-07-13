import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:google_sign_in_platform_interface/google_sign_in_platform_interface.dart';
import 'package:lbc_harbor_connect/models/user_profile.dart';
import 'package:lbc_harbor_connect/models/services_setup.dart';
import 'package:lbc_harbor_connect/screens/settings_screens.dart';
import 'package:lbc_harbor_connect/services/database_service.dart';
import 'package:riverpod/riverpod.dart';
import 'package:lbc_harbor_connect/screens/profile_screen.dart';
import 'package:lbc_harbor_connect/screens/schedule_service_screen.dart';
import 'package:lbc_harbor_connect/screens/scheduled_services_list_screen.dart';
import '../../screens/home_screen.dart';
import '../../screens/people_screens.dart';
import '../models/service.dart';
import '../screens/login_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';

class HarborUser {
  final User? firebaseUser;

  HarborUser({this.firebaseUser});
}

class AuthNotifier extends Notifier<HarborUser?> {
  @override
  HarborUser? build() {
    // Keep it synced with the stream
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      state = HarborUser(firebaseUser: user);
    });

    // This is for the sign in button for the web. Things are a little different for the web
    //    The AI said to put this on the login screen, but I think it might make better sense here
    // Listen for login changes (triggered automatically when the web button is clicked)
    GoogleSignIn.instance.authenticationEvents.listen((GoogleSignInAuthenticationEvent event) {
      print("Event received: $event");
      if (event is GoogleSignInAuthenticationEventSignIn) {
        // Handle successful sign-in
        var signInEvent = event as GoogleSignInAuthenticationEventSignIn;
        final GoogleSignInAccount user = signInEvent.user;
        finishGoogleSignin(user);
        print("User logged in: ${user?.email}");
      } else if (event is AuthenticationEventSignOut) {
        // Handle sign-out
        print("User logged out");
      }
    }).onError((error) {
      // Handle authentication errors
    });

    // Synchronously return the current user state wrapped in HarborUser
    final user = FirebaseAuth.instance.currentUser;
    return user != null ? HarborUser(firebaseUser: user) : null;
  }

  // Handle Firebase Sign In
  Future<void> signInWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: password);
      state = HarborUser(firebaseUser: FirebaseAuth.instance.currentUser);
    } catch (e) {
      state = HarborUser(firebaseUser: FirebaseAuth.instance.currentUser);
      rethrow;
    }
  }

  // Handle Firebase Sign Up
  Future<void> signUpWithEmail(String email, String password) async {
    try {
      await FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: password);
      
      final User? user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userProfile = UserProfile(
          uid: user.uid,
          email: user.email ?? '',
          displayName: user.displayName ?? 'New User',
          photoUrl: user.photoURL ?? '',
          createdAt: DateTime.now(),
        );
        await ref.read(databaseServiceProvider).saveUserProfile(userProfile);
      }
      
      state = HarborUser(firebaseUser: user);
    } catch (e) {
      state = HarborUser(firebaseUser: FirebaseAuth.instance.currentUser);
      rethrow;
    }
  }

  Future<void> signInWithGoogle() async {
    try {
      // 1. Initialize and trigger the base account identity picker
      final GoogleSignIn googleSignIn = GoogleSignIn.instance;
      final GoogleSignInAccount? googleUser = await googleSignIn.authenticate();

      if (googleUser == null) {
        throw Exception('User canceled the Google Sign-In process.');
      }

      // This was moved out to a separate method so that we could reuse it with the version from the web
      var userCredential = await finishGoogleSignin(googleUser);

    } catch (e) {
      print("Failed $e");
      state = null;
      rethrow;
    }
  }


  Future<UserCredential>  finishGoogleSignin(GoogleSignInAccount googleUser) async {
    // 2. GET THE ID TOKEN (Lives directly on the account's authentication getter)
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;
    final String? idToken = googleAuth.idToken;

    // 3. GET THE ACCESS TOKEN (Lives inside the separate authorization client)
    const List<String> scopes = <String>['email', 'profile'];
    final authClient = googleUser.authorizationClient;

    GoogleSignInClientAuthorization? authorization =
    await authClient.authorizationForScopes(scopes);

    authorization ??= await authClient.authorizeScopes(scopes);
    final String? accessToken = authorization.accessToken;

    // 4. Validate before passing payload to Firebase
    if (accessToken == null || idToken == null) {
      throw Exception('Failed to retrieve full authentication tokens from Google.');
    }

    /* 5. Complete Handshake with Firebase Auth */
    final AuthCredential credential = GoogleAuthProvider.credential(
      accessToken: accessToken,
      idToken: idToken,
    );
    var userCredential = await FirebaseAuth.instance.signInWithCredential(credential);

    state = HarborUser(firebaseUser: FirebaseAuth.instance.currentUser); // Globally updates GoRouter configuration parameters

    // Create a user profile using the authenticated session metadata
    final userProfile = UserProfile(
      // uid: googleUser.id, // Or firebaseUser.uid if using FirebaseAuth
      uid: userCredential.user!.uid,
      email: googleUser.email,
      displayName: googleUser.displayName ?? 'New User',
      photoUrl: googleUser.photoUrl ?? '',
      createdAt: DateTime.now(),
    );
    // Read the service from the Riverpod container container and write the data
    await ref.read(databaseServiceProvider).saveUserProfile(userProfile);


    return userCredential;
  }

  void logout() => state = null;
}

final authProvider = NotifierProvider<AuthNotifier, HarborUser?>(AuthNotifier.new);

// --- RIVERPOD ROUTER PROVIDER ---
// We wrap GoRouter in a provider so it can watch the auth state reactively
final routerProvider = Provider<GoRouter>((ref) {
  // We turn the Riverpod state into a standard ValueNotifier so GoRouter can listen to it
  final listenable = ValueNotifier<HarborUser?>(ref.watch(authProvider));

  // Keep the notifier updated when the provider changes
  ref.listen<HarborUser?>(authProvider, (_, next) {
    listenable.value = next;
  });

  return GoRouter(
    initialLocation: '/',
    refreshListenable: listenable,

    // 1. AUTHENTICATION GUARD
    redirect: (BuildContext context, GoRouterState state) {
      final HarborUser? user = ref.read(authProvider);
      final bool isLoggedIn = user != null && user.firebaseUser != null;
      final bool isLoggingIn = state.matchedLocation == '/login';

      if (!isLoggedIn && !isLoggingIn) return '/login';
      if (isLoggedIn && isLoggingIn) return '/';

      return null; // No redirection needed
    },

    routes: <RouteBase>[
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        builder: (BuildContext context, GoRouterState state) {
          return const MyHomePage();
        },
      ),
      GoRoute(
        path: '/profile',
        builder: (BuildContext context, GoRouterState state) {
          return const ProfileScreen();
        },
      ),
      GoRoute(
        path: '/schedule',
        builder: (BuildContext context, GoRouterState state) {
          final serviceInstance = state.extra as ServiceInstance?;
          return ScheduleServiceScreen(serviceInstance: serviceInstance);
        },
      ),
      GoRoute(
        path: '/scheduled-list',
        builder: (BuildContext context, GoRouterState state) {
          return const ScheduledServicesListScreen();
        },
      ),
      GoRoute(
        path: '/settings',
        builder: (BuildContext context, GoRouterState state) {
          return const SettingsHomePage();
        },
        routes: [
          GoRoute(
            path: 'services',
            builder: (context, state) => const ServiceTypeSetupScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) {
                  final serviceType = state.extra as ServiceType?;
                  return ServiceTypeDetailsScreen(serviceType: serviceType);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'positions',
            builder: (context, state) => const PositionSetupScreen(),
            routes: [
              GoRoute(
                path: 'add',
                builder: (context, state) {
                  final position = state.extra as Position?;
                  return AddPositionScreen(position: position);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'roles',
            builder: (context, state) => const RolesScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) {
                  final role = state.extra as Role?;
                  return RoleDetailScreen(role: role);
                },
              ),
            ],
          ),
          GoRoute(
            path: 'teams',
            builder: (context, state) => const TeamsScreen(),
            routes: [
              GoRoute(
                path: 'detail',
                builder: (context, state) {
                  final team = state.extra as Team?;
                  return TeamDetailScreen(team: team);
                },
              ),
            ],
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => ScaffoldWithNavBar(child: child),
        routes: [
          GoRoute(
            path: '/people/search',
            builder: (context, state) => const PeopleSearchPage(),
          ),
          GoRoute(
            path: '/people/import',
            builder: (context, state) => const ImportPeopleScreen(),
          ),
          GoRoute(
            path: '/people/details',
            builder: (context, state) {
              final member = state.extra as Member?;
              return MemberDetailsScreen(member: member);
            },
          ),
          // // 2. PASSING COMPLEX ARGUMENTS
          // GoRoute(
          //   path: '/profile-details',
          //   builder: (context, state) {
          //     final user = state.extra as UserDetail;
          //     return ProfileDetailsScreen(user: user);
          //   },
          // ),
        ],
      ),
    ],
  );
});
