import 'package:bjj_dairy/providers/profile_provider.dart';
import 'package:bjj_dairy/utils/app_strings.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      Provider.of<ProfileProvider>(context, listen: false).getUserDetails();
    });
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = Provider.of<ProfileProvider>(context, listen: true);
    return WillPopScope(
      onWillPop: () async{
        return true;
      },
      child: SafeArea(
        child: Scaffold(
            backgroundColor: const Color(0xFFF9FAFB),
            body: Column(
              children: [
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border(
                      bottom: BorderSide(
                        color: Colors.grey.shade300,
                        width: 1.0,
                      ),
                    ),
                  ),
                  child: Row(
                    children: [
                      IconButton(
                        icon:
                        const Icon(Icons.arrow_back, color: Colors.black),
                        onPressed: () {
                          Navigator.pop(context);
                        },
                      ),
                      Expanded(
                        child: Text(
                          AppStrings.profileDetails,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      Row(
                        children: [
                        ],
                      )
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                    child: ListView(
                      children: [
                        ListTile(
                          title: Text(AppStrings.profileUsernameLabel,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                          subtitle: Text('${profileProvider.loggedUser?.username}'),
                        ),
                        Divider(height: 1,color: Colors.grey.shade300,),
                        ListTile(
                          title: Text(AppStrings.profileEmailLabel,style: TextStyle(color: Colors.black,fontWeight: FontWeight.bold),),
                          subtitle: Text('${profileProvider.loggedUser?.email}'),
                        )
                      ],
                    ),
                  ),
                )
              ],
            ),
        ),
      ),
    );
  }
}
