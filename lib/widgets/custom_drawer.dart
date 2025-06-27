import 'package:flutter/material.dart';

class CustomDrawer extends StatelessWidget {
  final Function(String action) onItemTap;

  const CustomDrawer({super.key, required this.onItemTap});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo Section
          Container(
            width: MediaQuery.of(context).size.width,
            child: DrawerHeader(
              decoration:  BoxDecoration(color: Theme.of(context).primaryColor),
              child: Icon(Icons.task, size: 60, color: Colors.white),
            ),
          ),
          const SizedBox(height: 16),
          ListTile(
            leading: const Icon(Icons.account_box),
            title: const Text('Profile'),
            onTap: () => onItemTap('profile'),
          ),
          const SizedBox(height: 16),
          // ListTile(
          //   leading: const Icon(Icons.search_rounded),
          //   title: const Text('Search Folder'),
          //   onTap: () => onItemTap('search_folder'),
          // ),
          // const SizedBox(height: 16),
          // Contacts Section Title
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Contacts',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Contact Items with callback
          ListTile(
            leading: const Icon(Icons.star_border),
            title: const Text('Rate us'),
            onTap: () => onItemTap('rate'),
          ),
          ListTile(
            leading: const Icon(Icons.share),
            title: const Text('Recommend to friends'),
            onTap: () => onItemTap('recommend'),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: const Text('Contact Support'),
            onTap: () => onItemTap('support'),
          ),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => onItemTap('logout'),
          ),

          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 16),
            child: GestureDetector(
              onTap: () => onItemTap('privacy'),
              child: Text(
                'Privacy Policy',
                style: TextStyle(
                  color: Colors.grey.shade600,
                  decoration: TextDecoration.underline,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
