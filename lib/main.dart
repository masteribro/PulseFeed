import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'application/home_cubit.dart';
import 'home/home_page.dart';
import 'ioc.dart';

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
    var panel = MultiBlocProvider(
        providers: [
        BlocProvider.value(
        value: getIt<HomeCubit>(),
    ),
    ],
    child: GestureDetector(
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
            builder: (context, child) {
              return child!;
            },
            home: const HomePage(),
          ),
        )));

    return panel;
  }
}


