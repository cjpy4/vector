import 'package:desktop_drop/desktop_drop.dart';
import 'package:flutter/material.dart';
import 'package:cross_file/cross_file.dart';
import 'package:langchain/langchain.dart';
import 'package:langchain_openai/langchain_openai.dart';
import 'package:langchain_supabase/langchain_supabase.dart' as sbv;
import 'package:flutter_gpt_tokenizer/flutter_gpt_tokenizer.dart';
import 'package:collection/collection.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vector/db.dart';
import 'package:langchain_community/langchain_community.dart';

class DragTarget extends ConsumerStatefulWidget {
  final void Function() uploadCallback;
  const DragTarget({
    Key? key,
    required this.uploadCallback,
  }) : super(key: key);

  @override
  DragTargetState createState() => DragTargetState();
}

class DragTargetState extends ConsumerState<DragTarget> {
  final List<XFile> _list = [];
  DragTargetState();
  bool _dragging = false;
  Offset? offset;
  Future<int> countTokens(String text) async {
    final int tokenCount = await Tokenizer().count(text, modelName: 'gpt-4-*');
    return tokenCount;
  }
  String supabaseURL;
  String supabaseKey;
  void uploadCallbackFunc() {
    widget.uploadCallback();
  }
Future<Map?> getCredsMap() async {
  final supabaseCreds = await ref.watch(supabaseCredsProvider);
  final map = await supabaseCreds.when(
      data: (supabaseCreds) {
        return supabaseCreds;
      },
      loading: () {},
      error: (error, stackTrace){}
  );
  return map;
}

  @override
  Widget build(BuildContext context) {
   final openAIKey = ref.watch(secretProvider('OpenAIKey')).toString();
   final supabaseCreds = ref.watch(supabaseCredsProvider);
    /*final map = supabaseCreds.when(
      data: (supabaseCreds) {
       return supabaseCreds;
      },
      loading: () {},
      error: (error, stackTrace){}
    ); */
    //String supabaseURL = supabaseCreds.valueOrNull.toString();
  // String supabaseKey = map!['key'];
   //print(supabaseKey);
   print(supabaseURL);
    final llm = ChatOpenAI(apiKey: openAIKey);
    final embeddings = OpenAIEmbeddings(apiKey: openAIKey);

    final vectorStore = sbv.Supabase(
      tableName: 'documents_vecs',
      embeddings: embeddings,
      supabaseUrl: 'https://dpurcsaehzohnppjzlxz.supabase.co',
      supabaseKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImRwdXJjc2FlaHpvaG5wcGp6bHh6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3MTE0OTkwNDIsImV4cCI6MjAyNzA3NTA0Mn0.MdwLosdYtk6ggKbDI2el0OwZr46A3RAiDdljkE0ZXfk',
    );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DropTarget(
          onDragDone: (detail) async {
            setState(() {
              _list.addAll(detail.files);
            });
            //List<Document> docs = [];
            debugPrint('onDragDone:');
            for (final file in detail.files) {
              final filePath = file.path;
              final loader = TextLoader(filePath);
              //final stream = loader.lazyLoad();
              final docs = await loader.load();
              //await for (var document in stream) {
              const textSplitter = RecursiveCharacterTextSplitter(
                chunkSize: 32000,
                chunkOverlap: 0,
              );
              print(docs);
              final texts = textSplitter.splitDocuments(docs);
              final textsWithSources = texts
                  .mapIndexed(
                    (final i, final d) => d.copyWith(
                      metadata: {
                        ...d.metadata,
                        'source': '$i-pl',
                      },
                    ),
                  )
                  .toList(growable: false);
              await vectorStore.addDocuments(
                documents: textsWithSources,
              );
            }
            widget.uploadCallback();
          },
          onDragUpdated: (details) {
            setState(() {
              offset = details.localPosition;
            });
          },
          onDragEntered: (detail) {
            setState(() {
              _dragging = true;
              offset = detail.localPosition;
            });
          },
          onDragExited: (detail) {
            setState(() {
              _dragging = false;
              offset = null;
            });
          },
          child: Container(
            height: 200,
            width: 200,
            decoration: ShapeDecoration(
              shape: const CircleBorder(),
            ),
            //color: _dragging ? Colors.blue.withOpacity(0.4) : Colors.black26,
            child: Stack(
              children: [
                if (_list.isEmpty)
                  const Center(child: Text("Upload Files"))
                else
                  Text(_list.map((e) => e.path).join("\n")),
                if (offset != null)
                  Align(
                    alignment: Alignment.topRight,
                    child: Text(
                      '$offset',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  )
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: IconButton(
            iconSize: 40.0,
            onPressed: widget.uploadCallback,
            icon: const Icon(Icons.cancel),
          ),
        ),
      ],
    );
  }
}
