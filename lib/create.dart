// ignore_for_file: prefer_const_constructors, use_build_context_synchronously, avoid_print, unused_local_variable

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CreateDiaryPage extends StatefulWidget {
  const CreateDiaryPage({super.key});

  @override
  State<CreateDiaryPage> createState() => _CreateDiaryPageState();
}

class _CreateDiaryPageState extends State<CreateDiaryPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final myController = TextEditingController();

  @override
  void dispose() {
    // Clean up the controller when the widget is disposed.
    myController.dispose();
    super.dispose();
  }

  Future<void> upload() async {
    final supabase = Supabase.instance.client;  
    final User? user = supabase.auth.currentUser;
    final userData = user?.userMetadata!;
    try {
      if(myController.text.isNotEmpty) {
        await supabase
        .from('posts')
        .insert({
          'uuid': userData!['provider_id'], 
          'cuid': '55be6834-4ad8-4af3-a35a-b0fe3d5907a5',
          'details': myController.text, 
          'allowReply': 'true', 
          'type': 'Diary'
        });
        Navigator.of(context).pushReplacementNamed('/home');
      }
    } catch (e) {
      print(e);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Create"),
      ),
      body: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(15.0),
          child: Column(
            children: <Widget>[
              TextField(
                autofocus: true,
                canRequestFocus: true,
                controller: myController,
                decoration: const InputDecoration(
                  hintText: 'Whats on your mind today?',
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: ElevatedButton(
                onPressed: () {
                  // Validate will return true if the form is valid, or false if
                  // the form is invalid.
                  if (_formKey.currentState!.validate()) {
                    // Process data.
                    upload();
                  }
                },
                child: const Text('Submit'),
              ),
            ),
            ],
          ),
        )),
    );
  }
}