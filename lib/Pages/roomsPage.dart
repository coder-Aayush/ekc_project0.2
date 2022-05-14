import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_chat_types/flutter_chat_types.dart' as types;
import 'package:flutter_firebase_chat_core/flutter_firebase_chat_core.dart';

import '../Widgets/myAppBar.dart';
import '../theme/constants.dart';
import 'A_loginPage.dart';
import 'flyerDm.dart';

class RoomsPage extends StatelessWidget {
  const RoomsPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: myAppBar('Your chats',),
      body: StreamBuilder<List<types.Room>>(
        stream: FirebaseChatCore.instance.rooms(),
        initialData: const [],
        builder: (context, snapshot) {
          print('RoomsPage data Snapshot: ${snapshot.data}');
          if (snapshot.hasData && snapshot.data!.isNotEmpty) {
            return ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 10),
              itemCount: snapshot.data?.length ?? 0,
              itemBuilder: (context, i) {
                User? authUser = FirebaseAuth.instance.currentUser;
                bool isUserInRoom = false;
                var otherUser;
                print('snapshot.data?[i].users');
                print(snapshot.data?[i].users);

                snapshot.data?[i].users.forEach((user) {
                  print('users.forEach');

                  print(
                      'authUser: ${authUser?.uid} | ${authUser?.displayName}');
                  print('user: ${user.id} | ${user.firstName}');

                  try {
                    otherUser = snapshot.data?[i].users
                        .firstWhere((user) => user.id != authUser?.uid);
                  } catch (e) {
                    print('No otherUser, probably chat with yourself: $e');
                  }
                  print('otherUser');
                  print(otherUser);
                  // print(otherUser?.toJson());

                  if (user.id == authUser?.uid) isUserInRoom = true;
                });

                if (isUserInRoom && otherUser != null) {
                  return Column(
                    children: [
                      const SizedBox(height: 10),
                      Directionality(
                        textDirection: TextDirection.rtl,
                        child: Card(
                          margin: const EdgeInsets.symmetric(
                              horizontal: 8.0, vertical: 2.0),
                          shape: RoundedRectangleBorder(
                            side: BorderSide(
                                color: Colors.grey[200]!, width: 1.5),
                            borderRadius: BorderRadius.circular(6.0),
                          ),
                          elevation: 0,
                          shadowColor: Colors.black87,
                          color: Colors.grey[100]!,
                          child: Column(
                            children: [
                              const SizedBox(
                                height: 2,
                              ),
                              /*Container(
                              padding: const EdgeInsets.only(right: 10, left: 10),
                              alignment: Alignment.centerRight,
                              child:
                              InkWell(
                                child:
                                Icon(
                                  Icons.more_horiz,
                                  color: Colors.grey[200]!,
                                ),
                                onTap:() {},
                              ),
                            ),*/
/*                            Container(
                              padding: const EdgeInsets.only(right: 10, left: 10),
                              alignment: Alignment.topRight,
                              child: Text(text,
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontWeight: FontWeight.normal,
                                  fontSize: 16,
                                ),
                              ),
                            ),*/
                              Container(
                                height: 80,
                                padding: const EdgeInsets.only(right: 10),
                                // color: Colors.primaries[Random().nextInt(Colors.primaries.length)].shade300,
                                // color: cGrey100,
                                child: Row(
                                  children: [
                                    Flexible(
                                      child: ListTile(
                                        dense: true,
                                        visualDensity: VisualDensity.standard,
                                        title: Text(
                                          '${otherUser?.firstName}',
                                          style: TextStyle(
                                              // color: Colors.primaries[Random().nextInt(Colors.primaries.length)].shade600,
                                              // color: Colors.black
                                              color: Colors.grey[600]!,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14),
                                          // style: bodyText1Format(context)
                                        ),
                                        subtitle: Text(
                                          /*' · '*/
                                          '(${otherUser?.metadata?['age'].toString().substring(0, 2)})',
                                          textDirection: TextDirection.rtl,
                                          style: TextStyle(
                                              // color: Colors.primaries[Random().nextInt(Colors.primaries.length)].shade600,
                                              // color: Colors.black
                                              color: Colors.grey[600],
                                              fontWeight: FontWeight.normal,
                                              fontSize: 12),
                                          // style: bodyText1Format(context)
                                        ),
                                        contentPadding: EdgeInsets.zero,
                                        leading: /* CircleAvatar(
                                          backgroundImage: NetworkImage('${otherUser?.imageUrl}'),
                                          // backgroundImage: NetworkImage('https://bit.ly/3l64LIk'),
                                        )*/
                                            CircleAvatar(
                                                backgroundColor:
                                                    Colors.grey[400]!,
                                                radius: 44 / 2,
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      Colors.grey[400]!,
                                                  radius: 39 / 2,
                                                  backgroundImage: NetworkImage(
                                                      '${otherUser?.imageUrl}'),
                                                )),
                                      ),
                                    ),

                                    Builder(
                                        builder: (context) => Padding(
                                              padding: const EdgeInsets.only(
                                                  left: 10),
                                              child: Directionality(
                                                textDirection:
                                                    TextDirection.rtl,
                                                child: CircleAvatar(
                                                  backgroundColor:
                                                      Colors.grey[200],
                                                  radius: 20,
                                                  child: IconButton(
                                                      onPressed: () async {
                                                        final room =
                                                            await FirebaseChatCore
                                                                .instance
                                                                .createRoom(
                                                                    otherUser!);

                                                        kPushNavigator(
                                                            context,
                                                            FlyerDm(
                                                              room: room,
                                                            ));
                                                      },
                                                      icon: Icon(
                                                        Icons.send_rounded,
                                                        color: Colors.grey[500],
                                                        size: 20,
                                                      )),
                                                ),
                                              ),
                                            ))

                                    // const SizedBox(width: 10),
                                    // const Spacer(),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    ],
                  );
                } else {
                  return const Offstage();
                }
              },
            );
          } else {
            return const Center(
                child: Text(
              'התחל שיחה עם אנשים חדשים \n דרך רילטופיה!',
              textAlign: TextAlign.center,
              textDirection: TextDirection.rtl,
            ));
          }
        },
      ),
    );
  }
}
