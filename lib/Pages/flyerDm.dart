import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:ekc_project/Pages/ril_gDashboard.dart';
import 'package:ekc_project/Widgets/addUserDialog.dart';
import 'package:ekc_project/Widgets/myAppBar.dart';
import 'package:ekc_project/Widgets/myDrawers.dart';
import 'package:ekc_project/theme/constants.dart';
import 'package:file_picker/file_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_chat_ui/flutter_chat_ui.dart';
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

import '../myUtil.dart';
import 'C_rilHomePage.dart';
import '../dump/usersPage.dart';

class FlyerDm extends StatefulWidget {
/*  const FireBaseChatPage({
    Key? key,
    required this.room,
  }) : super(key: key);*/

  final types.Room room;
  final String? otherUserName;

  final GoogleSignInAccount? currentUser;

  // final UserCredential? currentUser;

  // final currentUser;

  const FlyerDm({this.currentUser, required this.room, this.otherUserName}) : super();

  @override
  _FlyerDmState createState() => _FlyerDmState();
}

class _FlyerDmState extends State<FlyerDm> {
  bool _isAttachmentUploading = false;
  types.User? otherUser;
  User? authUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    otherUser = widget.room.users
        .firstWhere((user) => user.id != authUser?.uid);
    String unreadKey = 'unreadCountFrom_'
        '${otherUser?.id.substring(0, 5)}';

    // int unreadCount = widget.room.metadata?[unreadKey] ?? 0;
    FirebaseFirestore.instance
        .doc('rooms/${widget.room.id}').set({
      // 'metadata': {unreadKey: FieldValue.increment(0)}
      'metadata': {unreadKey: 0}
    }, SetOptions(merge:true),);

    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: myAppBar(context,
          widget.otherUserName ?? otherUser?.firstName,
          actions: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: CircleAvatar(
                radius: 40 / 2,
                backgroundColor: Colors.grey[300],
                child: IconButton(
                    onPressed: () => kPushNavigator(context,
                        GDashboard(homePage:
                        RilHomePage(
                            room: types.Room(
                                users: [types.User(id: '${authUser?.uid}')], // Adds the user to group
                                type: types.RoomType.group,
                                id: 'ClZEotxQ0ybSVlNykN0e'),
                            // currentUser: widget.userData,),
                            flyerUser: types.User(id: '${authUser?.uid}')),)
                        , replace: true),
                    icon:
                    SvgPicture.asset(
                      'assets/svg_icons/CleanLogo.svg',
                      height: 30,
                      color: Colors.grey[900],
                      // color: StreamChatTheme.of(context).colorTheme.accentPrimary,
                    ),),
              ),
            )



/*        widget.room.type.toString() == 'RoomType.direct' ? Container() : Builder(
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
        ),*/
      ]),
      body: StreamBuilder<types.Room>(
        initialData: widget.room,
        stream: FirebaseChatCore.instance.room(widget.room.id),
        builder: (context, snapshot) {
          return StreamBuilder<List<types.Message>>(
            initialData: const [],
            stream: FirebaseChatCore.instance.messages(snapshot.data!),
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
}
