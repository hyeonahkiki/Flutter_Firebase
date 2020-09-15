import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

void main(){
  runApp(MaterialApp(
    title: 'Google sign in',
    home: HomePage(),
  ));
}

class HomePage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Firebase')),
      body: ListView(
        children: [
          ListTile(
            title: Text("google sign in test"),
            subtitle: Text('plugin'),
            onTap: (){
              Navigator.push(context, MaterialPageRoute(builder: (context)=>GoogleSignInDemo()));
            },
          )
        ].map((child){
          return Card(
            child: child,
          );
        }).toList(),
      ),
    );
  }
}

GoogleSignInDemoState pageState;

GoogleSignIn _googleSignIn = GoogleSignIn(scopes: <String>[
  'email',
  'https://www.googleapis.com/auth/contacts.readonly'
]);

class GoogleSignInDemo extends StatefulWidget {
  @override
  GoogleSignInDemoState createState() {
    pageState = GoogleSignInDemoState();
    return pageState;
  }
}

class GoogleSignInDemoState extends State<GoogleSignInDemo> {
  GoogleSignInAccount _cureentUser;
  String _contactText;

  void initState(){
    super.initState();
    _googleSignIn.onCurrentUserChanged.listen((GoogleSignInAccount account) {
      setState(() {
        _cureentUser = account;
      });
      if (_cureentUser != null){
        _handleGetContact();
      }
      _googleSignIn.signInSilently();
    });
  }

  Future<void>_handleGetContact()async{
    setState(() {
      _contactText = "Loading contact info......";
    });
    final http.Response response = await http.get(
        'https://people.googleapis.com/v1/people/me/connections'
            '?requestMask.includeField=person.names',
      headers: await _cureentUser.authHeaders);

    if(response.statusCode != 200){
      setState(() {
        _contactText = '${response.statusCode}';
      });
      print("${response.statusCode}" + '랑' +'${response.body}');
      return;
    }

    final Map<String, dynamic> data = json.decode(response.body);
    final String nameContact = _pickFirstNameContact(data);
    setState(() {
      if(nameContact != null){
      _contactText = "${nameContact}";
      }else{
        _contactText = "No contact to display";
      }
    });
  }

  String _pickFirstNameContact(Map<String, dynamic> data) {
    final List<dynamic> connections = data['conntections'];
    final Map<String, dynamic> contact = connections?.firstWhere(
            (dynamic contact) => contact['names'] != null,
        orElse: ()=> null);
    if (contact != null){
      final Map<String, dynamic> name = contact['names'].firstWhere(
          (dynamic name)=> name['displayName'] != null,
        orElse: ()=> null
      );
      if (name != null){
        return name['displayName'];
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('test'),),
      body: ConstrainedBox(
        constraints: const BoxConstraints.expand(),
        child: _buildBody(),
      ),
    );
  }

  Widget _buildBody(){
    if(_cureentUser != null){
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          ListTile(
            leading: GoogleUserCircleAvatar(
              identity: _cureentUser,
            ),
            title: Text(_cureentUser.displayName ?? ""),
            subtitle: Text(_cureentUser.email ?? ""),
          ),
          const Text("signed in successfully"),
          Text(_contactText??""),
          RaisedButton(
            child: const Text('sign out'),
            onPressed: _handleSignout,
          ),
          RaisedButton(
            child: const Text('refresh'),
            onPressed: _handleGetContact,
          )
        ],
      );
    }else{
      return Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Text('you are currentlu sign in'),
          RaisedButton(
            child :Text('sign in'),
            onPressed: _handleSignIn,
          )
        ],
      );
    }
  }

  Future<void> _handleSignIn() async{
    try{
      await _googleSignIn.signIn();
    }catch(error){
      print(error);
    }
  }

  Future<void> _handleSignout() async{
    _googleSignIn.disconnect();
  }
}

