import 'package:faker/faker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  bool _loggingIn = false;
  late TextEditingController _usernameController;

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController(
      text: '',
    );
  }

  @override
  void dispose() {
    _usernameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          systemOverlayStyle: SystemUiOverlayStyle.light,
          title: const Text('Login'),
        ),
        body: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.only(top: 80, left: 24, right: 24),
            child: Column(
              children: [
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    border: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(
                        Radius.circular(8),
                      ),
                    ),
                    labelText: 'Token',
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.cancel),
                      onPressed: () => _usernameController.clear(),
                    ),
                  ),
                  keyboardType: TextInputType.text,
                  onEditingComplete: _loggingIn ? null : _login,
                  readOnly: _loggingIn,
                  minLines: 4,
                  maxLines: 15,
                  textCapitalization: TextCapitalization.none,
                  textInputAction: TextInputAction.done,
                ),
                TextButton(
                  onPressed: _loggingIn ? null : _login,
                  child: const Text('Login'),
                ),
              ],
            ),
          ),
        ),
      );

  void _login() async {
    if (['', null].contains(_usernameController.text)) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _loggingIn = true;
    });

    try {
      final userCredential = await FirebaseAuth.instance.signInWithCustomToken(
        _usernameController.text,
      );

      final faker = Faker();
      final firstName = faker.person.firstName();
      final lastName = faker.person.lastName();
      final email =
          '${firstName.toLowerCase()}.${lastName.toLowerCase()}@${faker.internet.domainName()}';

      final user = FirebaseChatCore.instance
          .getFirebaseFirestore()
          .collection('users')
          .doc(userCredential.user!.uid);

      if (!(await user.get()).exists) {
        await FirebaseChatCore.instance.createUserInFirestore(
          types.User(
            firstName: firstName,
            id: userCredential.user!.uid,
            imageUrl: 'https://i.pravatar.cc/300?u=$email',
            lastName: lastName,
          ),
        );
      } else {
        await user.update({
          'firstName': firstName,
          'lastName': lastName,
          'updatedAt': DateTime.now(),
        });
      }

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (e) {
      setState(() {
        _loggingIn = false;
      });

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('OK'),
            ),
          ],
          content: Text(
            e.toString(),
          ),
          title: const Text('Error'),
        ),
      );
    }
  }
}
