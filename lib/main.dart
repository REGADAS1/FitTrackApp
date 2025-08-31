import 'package:firebase_core/firebase_core.dart';
import 'package:fit_track_app/data/core/configs/theme/app_theme.dart';
import 'package:fit_track_app/firebase_options.dart';
import 'package:fit_track_app/presentation/splash/choose_mode/pages/bloc/theme_cubit.dart';
import 'package:fit_track_app/presentation/splash/pages/splash.dart';
import 'package:fit_track_app/service_locator.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:path_provider/path_provider.dart';

// (Opcional) Se vieres a usar componentes Syncfusion e quiseres PT:
// import 'package:syncfusion_localizations/syncfusion_localizations.dart';
// import 'package:syncfusion_flutter_core/core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await initializeDependencies();

  // Carrega símbolos de data para PT antes de arrancar a app
  await initializeDateFormatting('pt');
  await initializeDateFormatting('pt_PT');

  // (Opcional) Registar licença da Syncfusion se tiveres:
  // SyncfusionLicense.registerLicense('A_TUA_CHAVE');

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory:
        kIsWeb
            ? HydratedStorageDirectory.web
            : HydratedStorageDirectory((await getTemporaryDirectory()).path),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [BlocProvider(create: (_) => ThemeCubit())],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: mode,

            // Locale por defeito PT-PT
            locale: const Locale('pt', 'PT'),
            supportedLocales: const [
              Locale('pt', 'PT'),
              Locale('pt'),
              Locale('en'),
            ],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
              // (Opcional) Se vieres a usar Syncfusion:
              // SfGlobalLocalizations.delegate,
            ],

            home: const SplashPage(),
          );
        },
      ),
    );
  }
}

// (Opcional) Exemplo de página — podes remover se não usares
class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() => setState(() => _counter++);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            const Text('You have pushed the button this many times:'),
            Text(
              '$_counter',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
