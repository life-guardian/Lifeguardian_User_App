// ignore_for_file: prefer_typing_uninitialized_variables

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:user_app/view/animations/listview_shimmer_effect.dart';
import 'package:user_app/helper/constants/api_keys.dart';
import 'package:http/http.dart' as http;
import 'package:user_app/model/agencies_details.dart';
import 'package:user_app/widget/listview/agencies_list_listview.dart';

class SearchAgencyWidget extends StatefulWidget {
  const SearchAgencyWidget({
    super.key,
    required this.token,
    required this.userName,
  });
  final token;
  final String userName;

  @override
  State<SearchAgencyWidget> createState() => _SearchAgencyScreenState();
}

class _SearchAgencyScreenState extends State<SearchAgencyWidget> {
  var scrollController = ScrollController();
  List<Agencies> agencies = [];
  int pageIndex = 1;
  bool isLoadingMore = false;
  String searchTextToString = '';
  TextEditingController searchText = TextEditingController();

  Widget activeScreen = const ListviewShimmerEffect();

  @override
  void dispose() {
    super.dispose();
    searchText.dispose();
  }

  @override
  void initState() {
    super.initState();
    fetchAgencies().then((value) => {
          agencies.addAll(value),
          setState(() {
            activeScreen = AgenciesListListview(
              list: agencies,
              userName: widget.userName,
              scrollController: scrollController,
              isLoadingMore: isLoadingMore,
              token: widget.token,
            );
          })
        });
    scrollController.addListener(() {
      _scrollListener();
    });
  }

  Future<List<Agencies>> fetchAgencies() async {
    var response = await http.get(
      Uri.parse('$agenciesDataurl$searchTextToString&page=$pageIndex&limit=7'),
      headers: {
        "Content-Type": "application/json",
        'Authorization': 'Bearer ${widget.token}'
      },
    );
    List<Agencies> data = [];

    if (response.statusCode == 200) {
      var jsonResponse = jsonDecode(response.body);

      List<dynamic> agenciesList = jsonResponse['agencies'];

      for (var jsonData in agenciesList) {
        data.add(Agencies.fromJson(jsonData));
      }
    }

    return data;
  }

  Future<void> _scrollListener() async {
    if (isLoadingMore) {
      return;
    }
    // hits the condition whenever the list is scrolled to the end
    if (scrollController.position.pixels ==
        scrollController.position.maxScrollExtent) {
      pageIndex++;
      setState(() {
        isLoadingMore = true;
        activeScreen = AgenciesListListview(
          userName: widget.userName,
          list: agencies,
          scrollController: scrollController,
          isLoadingMore: isLoadingMore,
          token: widget.token,
        );
      });
      await fetchAgencies().then((value) => {
            setState(() {
              agencies.addAll(value);
            })
          });
      setState(() {
        isLoadingMore = false;
        activeScreen = AgenciesListListview(
          list: agencies,
          scrollController: scrollController,
          userName: widget.userName,
          isLoadingMore: isLoadingMore,
          token: widget.token,
        );
      });
    }
  }

  void searchAgency() {
    searchTextToString = searchText.text;

    fetchAgencies().then((value) => {
          setState(() {
            agencies = [];
            agencies.addAll(value);
            activeScreen = AgenciesListListview(
              userName: widget.userName,
              list: agencies,
              scrollController: scrollController,
              isLoadingMore: isLoadingMore,
              token: widget.token,
            );
          })
        });
  }

  @override
  Widget build(BuildContext context) {
    ThemeData themeData = Theme.of(context);
    return Column(
      children: [
        const SizedBox(
          height: 21,
        ),
        TextField(
          controller: searchText,
          onChanged: (value) {
            pageIndex = 1;
            searchAgency();
          },
          decoration: InputDecoration(
            filled: true,
            fillColor: (themeData.brightness == Brightness.light)
                ? const Color.fromARGB(161, 255, 255, 255)
                : Theme.of(context).colorScheme.primary,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Color.fromARGB(156, 158, 158, 158)),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            focusedBorder: const OutlineInputBorder(
              borderSide: BorderSide(color: Colors.grey),
              borderRadius: BorderRadius.all(
                Radius.circular(10),
              ),
            ),
            labelText: 'Search Agency',
            labelStyle:
                TextStyle(color: Theme.of(context).colorScheme.onBackground),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () {
                  searchAgency();
                },
                icon: const Icon(
                  Icons.search_outlined,
                  size: 30,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(
          height: 11,
        ),
        Expanded(
          child: activeScreen,
        ),
      ],
    );
  }
}
