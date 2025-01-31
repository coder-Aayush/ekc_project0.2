import 'dart:io';
import 'package:ekc_project/Widgets/addUserDialog.dart';
import 'package:ekc_project/Widgets/myAppBar.dart';
import 'package:ekc_project/Widgets/myDrawers.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../myUtil.dart';
import 'usersPage.dart';

/*class FlyerChatOriginal extends StatefulWidget {
*//*  const FireBaseChatPage({
    Key? key,
    required this.room,
  }) : super(key: key);*//*

  final types.Room room;

  final GoogleSignInAccount? currentUser;

  // final UserCredential? currentUser;

  // final currentUser;

  const FlyerChatOriginal({this.currentUser, required this.room}) : super();

  @override
  _FlyerChatOriginalState createState() => _FlyerChatOriginalState();
}

class _FlyerChatOriginalState extends State<FlyerChatOriginal> {
  bool _isAttachmentUploading = false;
  var guestUser;
  // GoogleSignInAccount? guestUser;
  // UserCredential? guestUser;
  String? appBarTitle;
  List<String>? roomEmailUsers;

  @override
  void initState() {
    print('widget.room.type');
    print(widget.room.type.toString());
    print(widget.room.name);


    // RoomType.direct
    // RoomType.group
    if (widget.room.type.toString() == 'RoomType.direct') {
      widget.room.users.forEach((user) {
        if (widget.currentUser?.email != user.lastName) {
          // Lastname is MAIL!
          setState(() {
            guestUser = user;
            appBarTitle = '${guestUser.lastName}';
          });
        }
      });
    } else {
      setState(() {
        appBarTitle = widget.room.name;
      });
    }

    // Get all users:
    widget.room.users.forEach((user) {
      print('XXX user.lastName ${user.lastName}');
      // roomEmailUsers?.add(user.lastName.toString());
      roomEmailUsers = [...?roomEmailUsers, user.lastName.toString()];
    }
    );
    print('roomEmailUsers: ${roomEmailUsers?.length} ${roomEmailUsers.runtimeType} $roomEmailUsers');

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer:
          // true = Projects Drawer
          projectDrawer(context, widget.currentUser, true, widget.room.id),
      endDrawer:
          // false = Task Drawer
          taskDrawer(context, widget.currentUser, false, widget.room.id),
      //
      // appBar: myAppBar('Chat with ${widget.room.users.first.lastName}'),
      appBar: myAppBar(context, appBarTitle, actions: <Widget>[
        widget.room.type.toString() == 'RoomType.direct' ? Container() : Builder(
          // builder needed for Scaffold.of(context).openEndDrawer()
          builder: (context) => IconButton(
            icon: const Icon(Icons.group_add),
            onPressed: () async {
              showDialog(
                  context: context,
                  builder: (BuildContext dialogContext) {
                    return AddUserDialog(
                      currentUsers: roomEmailUsers,
                      contentFieldController: projectAddUserController,
                      currentUser: widget.currentUser,
                      room: widget.room,

                    );
                  });
            },
          ),
        ),
        Builder(
          // builder needed for Scaffold.of(context).openEndDrawer()
          builder: (context) => IconButton(
            icon: const Icon(Icons.list),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
            tooltip: MaterialLocalizations.of(context).openAppDrawerTooltip,
          ),
        ),
      ]),
      body: StreamBuilder<types.Room>(
        initialData: widget.room,
        stream: FirebaseChatCore.instance.room(widget.room.id),
        builder: (context, snapshot) {
          return StreamBuilder<List<types.Message>>(
            initialData: const [],
            stream: FirebaseChatCore.instance.messages(snapshot.data!, widget.),
            builder: (context, snapshot) {
              return SafeArea(
                bottom: false,
                child: Chat(
                  isAttachmentUploading: _isAttachmentUploading,
                  messages: snapshot.data ?? [],
                  // onAttachmentPressed: _handleAtachmentPressed,
                  // onMessageTap: _handleMessageTap,
                  onPreviewDataFetched: _handlePreviewDataFetched,
                  onSendPressed: _handleSendPressed,
                  user: types.User(
                    id: FirebaseChatCore.instance.firebaseUser?.uid ?? '',
                  ),

                ),
              );
            },
          );
        },
      ),
    );
  }

  void _handleAtachmentPressed() {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: SizedBox(
            height: 144,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleImageSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Photo'),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    Navigator.pop(context);
                    _handleFileSelection();
                  },
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('File'),
                  ),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Cancel'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _handleFileSelection() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.any,
    );

    if (result != null && result.files.single.path != null) {
      _setAttachmentUploading(true);
      final name = result.files.single.name;
      final filePath = result.files.single.path!;
      final file = File(filePath);

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialFile(
          mimeType: lookupMimeType(filePath),
          name: name,
          size: result.files.single.size,
          uri: uri,
        );

        FirebaseChatCore.instance.sendMessage(message, widget.room.id);
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleImageSelection() async {
    final result = await ImagePicker().pickImage(
      imageQuality: 70,
      maxWidth: 1440,
      source: ImageSource.gallery,
    );

    if (result != null) {
      _setAttachmentUploading(true);
      final file = File(result.path);
      final size = file.lengthSync();
      final bytes = await result.readAsBytes();
      final image = await decodeImageFromList(bytes);
      final name = result.name;

      try {
        final reference = FirebaseStorage.instance.ref(name);
        await reference.putFile(file);
        final uri = await reference.getDownloadURL();

        final message = types.PartialImage(
          height: image.height.toDouble(),
          name: name,
          size: size,
          uri: uri,
          width: image.width.toDouble(),
        );

        FirebaseChatCore.instance.sendMessage(
          message,
          widget.room.id,
        );
        _setAttachmentUploading(false);
      } finally {
        _setAttachmentUploading(false);
      }
    }
  }

  void _handleMessageTap(types.Message message) async {
    if (message is types.FileMessage) {
      var localPath = message.uri;

      if (message.uri.startsWith('http')) {
        final client = http.Client();
        final request = await client.get(Uri.parse(message.uri));
        final bytes = request.bodyBytes;
        final documentsDir = (await getApplicationDocumentsDirectory()).path;
        localPath = '$documentsDir/${message.name}';

        if (!File(localPath).existsSync()) {
          final file = File(localPath);
          await file.writeAsBytes(bytes);
        }
      }

      await OpenFile.open(localPath);
    }
  }

  void _handlePreviewDataFetched(
    types.TextMessage message,
    types.PreviewData previewData,
  ) {
    final updatedMessage = message.copyWith(previewData: previewData);

    FirebaseChatCore.instance.updateMessage(updatedMessage, widget.room.id);
  }

  void _handleSendPressed(types.PartialText message) {
    FirebaseChatCore.instance.sendMessage(
      message,
      widget.room.id,
    );
  }

  void _setAttachmentUploading(bool uploading) {
    setState(() {
      _isAttachmentUploading = uploading;
    });
  }
}*/
