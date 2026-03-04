import 'package:get_it/get_it.dart';
import 'package:pulse_feed/application/home_cubit.dart';

var getIt = GetIt.instance;

class IoC {
  void initServices() {

  }

  IoC() {
    initServices();
    getIt.registerSingleton(
      HomeCubit(
      ),
    );

  }


}
