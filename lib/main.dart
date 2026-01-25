import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'home/home_page.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {

  @override
  Widget build(BuildContext context) {
    var panel = GestureDetector(
        onTap: () {
          FocusScopeNode currentFocus = FocusScope.of(context);
          if (!currentFocus.hasPrimaryFocus &&
              currentFocus.focusedChild != null) {
            FocusManager.instance.primaryFocus!.unfocus();
          }
        },
        child: ScreenUtilInit(
          designSize: const Size(390, 844),
          minTextAdapt: true,
          builder: (_, __) => MaterialApp(
            themeMode: ThemeMode.light,
            darkTheme: ThemeData.light(),
            debugShowCheckedModeBanner: false,
            // theme: theme,
            // color: AppColors.primary,
            builder: (context, child) {
              return child!;
            },
            home: const HomePage(title: '',),
            // navigatorObservers: <NavigatorObserver>[
            //   AnalyticsService().getAnalyticsObserver()
            // ],
            // scaffoldMessengerKey:
            // ScaffoldMessengerService.scaffoldMessengerKey,
          ),
        ));

    // if (isEligibleForSmartlook) {
    //   return SmartlookRecordingWidget(
    //     child: panel,
    //   );
    // }
    return panel;
  }
}


