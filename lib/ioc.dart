import 'package:get_it/get_it.dart';
import 'package:pulse_feed/application/home_cubit.dart';

var getIt = GetIt.instance;

class IoC {
  void initServices() {
    // ============================================
    // STEP 1: REGISTER ALL CLIENTS AS SINGLETONS FIRST
    // This enables proper dependency injection and testability
    // ============================================


    // ============================================
    // STEP 2: REGISTER SERVICES WITH INJECTED CLIENTS
    // Services receive clients via constructor injection from GetIt
    // ============================================


  }

  IoC() {
    initServices();
    getIt.registerSingleton(
      HomeCubit(
      ),
    );

  }


}
