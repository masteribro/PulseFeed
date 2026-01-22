import 'package:get_it/get_it.dart';

var getIt = GetIt.instance;

class IoC {
  void initServices() {
    // ============================================
    // STEP 1: REGISTER ALL CLIENTS AS SINGLETONS FIRST
    // This enables proper dependency injection and testability
    // ============================================
    // getIt.registerSingleton<AuthenticationClient>(AuthenticationClient());


    // ============================================
    // STEP 2: REGISTER SERVICES WITH INJECTED CLIENTS
    // Services receive clients via constructor injection from GetIt
    // ============================================
    // getIt.registerSingleton(
    //   AuthenticationService(
    //     authenticationClient: getIt<AuthenticationClient>(),
    //   ),
    // );

  }

  IoC() {
    initServices();
    // getIt.registerSingleton(
    //   AuthenticationCubit(
    //     getIt(),
    //   ),
    // );

  }


}
