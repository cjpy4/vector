import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:vector/home.dart';
import 'theme.dart';
import 'util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

//part 'main.g.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  final supabaseURL = dotenv.env['SUPABASE_OPS_URL'].toString();
  final supabaseKey = dotenv.env['SUPABASE_OPS_KEY'].toString();

  //print (supabaseURL);
  // print (supabaseKey);
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: supabaseURL,
    anonKey: supabaseKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  /* Future<String> getSecret(secretName) async {
    var res = await supabase
        .schema('vault')
        .from('decrypted_secrets')
        .select('decrypted_secret')
        .match({'name': secretName});
    print(res[0]['decrypted_secret']);
    return res[0]['decrypted_secret'];
    //print(openAIKey[0]['decrypted_secret']);
  }*/
//Future getRows() async {
  //final fut = await supabase.from('vusers').select('*');
  //print(fut);
//}

  @override
  Widget build(BuildContext context) {
    //final row = getRows();
    //final openAIKey = '14';//getSecret('OpenAPIKey');
    //print(openAIKey);
    final brightness = View.of(context).platformDispatcher.platformBrightness;
    TextTheme textTheme = createTextTheme(context, "Mukta Vaani", "Rubik");
    MaterialTheme theme = MaterialTheme(textTheme);
    //ThemeData lightTheme = MaterialTheme(textTheme).light();
    //ThemeData darkTheme = MaterialTheme(textTheme).dark();
    return MaterialApp(
        title: 'Vector.ai',
        home: const HomePage(),
        theme: brightness == Brightness.light ? theme.light() : theme.dark());
  }
}
