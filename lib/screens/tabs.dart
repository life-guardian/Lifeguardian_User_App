// ignore_for_file: prefer_typing_uninitialized_variables, use_build_context_synchronously

import 'package:geolocator/geolocator.dart';
import 'package:user_app/api_urls/config.dart';
import 'package:user_app/screens/home_screen.dart';
import 'package:user_app/screens/login_screen.dart';
import 'package:user_app/screens/user_account_details.dart';
import 'package:user_app/screens/welcome_screen.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class TabsBottom extends StatefulWidget {
  const TabsBottom({super.key, required this.token});
  final token;

  @override
  State<TabsBottom> createState() => _TabsBottomState();
}

class _TabsBottomState extends State<TabsBottom> {
  int _currentIndx = 0;
  late String myToken;

  @override
  void initState() {
    super.initState();

    getToken();
    getLocation();
    globalToken = widget.token;
  }

  void getLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      print('Location Denied');
      LocationPermission ask = await Geolocator.requestPermission();
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.best);
      universalLat = currentPosition.latitude;
      universaLng = currentPosition.longitude;
      print(
          "Latitude: ${universalLat.toString()} , Longitude: ${universaLng.toString()}");
    }
    // Navigator.of(context).pop();
  }

  void getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    final myToken = prefs.getString('token');
  }

  void onSelectedTab(int index) {
    setState(
      () {
        _currentIndx = index;
      },
    );
  }

  void showCircularProgressBar() {
    showDialog(
      context: context,
      builder: (context) {
        return const Center(
          child: CircularProgressIndicator(
            color: Colors.grey,
          ),
        );
      },
    );
  }

  void _logoutUser() async {
    showCircularProgressBar();

    try {
      var response = await http.get(
        Uri.parse(loginUrl),
        headers: {
          "Content-Type": "application/json",
          'Authorization': 'Bearer ${widget.token}'
        },
      );
    } catch (error) {
      print("Logout user exception: ${error.toString()}");
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.remove('token');
    while (Navigator.canPop(context)) {
      Navigator.of(context).pop();
    }
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const WelcomeScreen(),
      ),
    );
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (ctx) => const LoginScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget activePage = HomeScreen(
      token: widget.token,
    );

    if (_currentIndx == 1) {
      activePage = UserAccountDetails(
        logoutUser: _logoutUser,
      );
    }
    return Scaffold(
      // backgroundColor: Colors.grey.shade200,
      backgroundColor: Theme.of(context).colorScheme.background,
      resizeToAvoidBottomInset: false,
      body: SafeArea(child: activePage),
      bottomNavigationBar: BottomNavigationBar(
        unselectedItemColor: const Color.fromARGB(175, 158, 158, 158),
        currentIndex: _currentIndx,
        iconSize: 25,
        onTap: onSelectedTab,
        selectedItemColor: const Color.fromARGB(255, 91, 32, 217),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.account_circle_outlined),
            activeIcon: Icon(Icons.account_circle_rounded),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}