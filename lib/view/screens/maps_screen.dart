// ignore_for_file: use_build_context_synchronously

import 'dart:async';
import 'dart:convert';
import 'package:animate_do/animate_do.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:user_app/helper/constants/api_keys.dart';
import 'package:user_app/helper/classes/modal_bottom_sheet_class.dart';
import 'package:user_app/model/active_agencies_location.dart';
import 'package:user_app/view_model/providers/device_location_provider.dart';
import 'package:geolocator/geolocator.dart' as geo;
import 'package:http/http.dart' as http;
import 'package:socket_io_client/socket_io_client.dart' as io;
import 'package:user_app/widget/buttons/custom_back_button.dart';
import 'package:user_app/widget/buttons/custom_elevated_button.dart';
import 'package:user_app/widget/text_widget/custom_text_widget.dart';
import 'package:user_app/widget/textfields/textfield_widget.dart';

class MapsScreen extends ConsumerStatefulWidget {
  const MapsScreen({super.key, required this.token});
  final String token;

  @override
  ConsumerState<MapsScreen> createState() => _MapsScreenState();
}

class _MapsScreenState extends ConsumerState<MapsScreen> {
  ModalBottomSheet modalBottomSheet = ModalBottomSheet();

  late io.Socket socket;

  late List<double> latLng;
  Widget? activeRescueMeButton;
  StreamSubscription<Position>? positionStreamSubscription;
  List<LiveAgencies> liveAgencies = [];
  bool? isRescueMeOnGoing;

  @override
  void initState() {
    super.initState();
    getInitialConnectAgenciesLocation();
  }

  @override
  void dispose() {
    super.dispose();
    if (positionStreamSubscription != null) {
      positionStreamSubscription!.cancel();
    }
    disconnectSocket();
  }

  // <------------------------ <Socket Implementation> ------------------------>

  void disconnectSocket() async {
    socket.disconnect();
    socket.onDisconnect((data) {
      debugPrint("Socket Dissconnected");
    });
    socket.dispose();
  }

  Future<void> getIsRescueOnGoing() async {
    var response = await http.get(
      Uri.parse(
        isRescueMeAlreadyClickedUrl,
      ),
      headers: {"Authorization": "Bearer ${widget.token}"},
    );
    try {
      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);
        isRescueMeOnGoing = jsonResponse["isAlreadyRescueMeStarted"];

        debugPrint("IsRescueMe ongoing: $isRescueMeOnGoing");
        if (isRescueMeOnGoing != null && isRescueMeOnGoing!) {
          await initialConnectSendLocation();
        }

        setState(() {
          initializeButtonValue();
        });
      }
    } catch (e) {
      debugPrint("Exception occurede is getIsRescueOnGoing: ${e.toString()}");
    }
  }

  void initializeButtonValue() {
    try {
      activeRescueMeButton = CustomTextWidget(
        text:
            (isRescueMeOnGoing! ? 'Stop Rescue Me' : "Rescue Me").toUpperCase(),
        color: Colors.white,
      );
    } catch (error) {
      debugPrint(
          "Exception occured in initializeButtonValue: ${error.toString()}");
    }
  }

  Future<void> initialConnectSendLocation() async {
    LocationPermission permission = await Geolocator.checkPermission();

    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        debugPrint("Location permission denied");
      }
    } else {
      Position currentPosition = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high);

      if (mounted) {
        ref.read(deviceLocationProvider.notifier).state = [
          currentPosition.latitude,
          currentPosition.longitude
        ];
        debugPrint(
            "Initial lat ${currentPosition.latitude} and lng: ${currentPosition.longitude}");
        emitLocationUpdate(currentPosition.latitude, currentPosition.longitude);
      }
    }
    return;
  }

  Future<void> getInitialConnectAgenciesLocation() async {
    final tempLatLng = ref.read(deviceLocationProvider);
    try {
      var response = await http.get(
        Uri.parse(
          "$baseUrl/api/rescueops/initialconnect/${tempLatLng[0]}/${tempLatLng[1]}",
        ),
        headers: {"Authorization": "Bearer ${widget.token}"},
      );

      if (response.statusCode == 200) {
        var jsonResponse = jsonDecode(response.body);

        final initialAgencies = jsonResponse["agencies"];

        debugPrint("Got initial connect agency: \n ${jsonResponse.toString()}");

        for (var liveAgency in initialAgencies) {
          liveAgencies.add(LiveAgencies.fromJson(liveAgency));
        }

        if (mounted) {
          setState(() {});
        }
      }
    } catch (error) {
      debugPrint(
          "Error while fetching intial connect agencies and user ${error.toString()}");
    }
    connectSocket();
    await getIsRescueOnGoing();
    startTrackingLocation();
    return;
  }

  void emitLocationUpdate(double latitude, double longitude) {
    socket.emit('userLocationUpdate', {'lat': latitude, 'lng': longitude});
  }

  void connectSocket() {
    socket = io.io(baseUrl, <String, dynamic>{
      'transports': ['websocket'],
      'autoConnect': false,
      'extraHeaders': {'Authorization': 'Bearer ${widget.token}'}
    });
    socket.connect();
    socket.onConnect((data) async {
      debugPrint("Socket Connected");
      listenSocketOn();
    });
  }

  void listenSocketOn() {
    socket.on("agencyLocationUpdate", (data) {
      if (mounted) {
        debugPrint("Got agency");
        debugPrint(data.toString());
        bool isPlotted = false;
        for (int i = 0; i < liveAgencies.length; i++) {
          if (liveAgencies[i].agencyId == data["agencyId"]) {
            liveAgencies[i].lat = data["lat"];
            liveAgencies[i].lng = data["lng"];
            liveAgencies[i].agencyName = data["agencyName"];
            liveAgencies[i].agencyId = data["agencyId"];
            liveAgencies[i].phoneNumber = data["phoneNumber"];
            liveAgencies[i].representativeName = data["representativeName"];
            liveAgencies[i].rescueOpsName = data["rescueOpsName"];
            liveAgencies[i].rescueOpsDescription = data["rescueOpsDescription"];
            liveAgencies[i].rescueTeamSize = data["rescueTeamSize"];
            debugPrint("Got agency update location");
            isPlotted = true;
            break;
          }
        }
        if (!isPlotted) {
          liveAgencies.add(LiveAgencies.fromJson(data));
        }
        setState(() {});
      }
    });

    socket.on("disconnected", (disconnectedAgencyId) {
      debugPrint("Agency id disconnected $disconnectedAgencyId");

      if (mounted) {
        for (int i = 0; i < liveAgencies.length; i++) {
          if (liveAgencies[i].agencyId == disconnectedAgencyId) {
            liveAgencies.remove(liveAgencies[i]);
            break;
          }
        }
        setState(() {});
      }
    });
  }

  void startTrackingLocation() async {
    LocationPermission permission = await geo.Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await geo.Geolocator.requestPermission();
    }

    if (permission == LocationPermission.always ||
        permission == LocationPermission.whileInUse) {
      geo.LocationSettings locationSettings = const geo.LocationSettings(
        accuracy: geo.LocationAccuracy.high,
        distanceFilter: 10,
      );
      positionStreamSubscription = geo.Geolocator.getPositionStream(
        locationSettings: locationSettings,
      ).listen((Position position) {
        if (mounted) {
          ref.read(deviceLocationProvider.notifier).state = [
            position.latitude,
            position.longitude
          ];
          if ((isRescueMeOnGoing) != null && (isRescueMeOnGoing!)) {
            emitLocationUpdate(position.latitude, position.longitude);
          }
        }
      });
    } else {
      debugPrint("Location permission denied - cannot track location.");
    }
  }

  // <------------------------ </Socket Implementation> ------------------------>

  // void initialEmitLocationUpdate(double latitude, double longitude) {
  //   socket.emit('initialConnect', {'lat': latitude, 'lng': longitude});
  // }

  // void onIntialConnectReceiveNearbyAgencies() {
  //   debugPrint("Listening to intial connect");
  //   socket.on("initialConnectReceiveNearbyAgencies", (initialConnectAgencies) {
  //     if (mounted) {
  //       debugPrint("Got initial connect agency");
  //       debugPrint(initialConnectAgencies.toString());
  //       for (var liveAgency in initialConnectAgencies) {
  //         liveAgencies.add(LiveAgencies.fromJson(liveAgency));
  //       }
  //       setState(() {});
  //     }
  //   });
  // }

  void openModalBottomSheet({required LiveAgencies liveAgency}) {
    modalBottomSheet.openModal(
      context: context,
      widget: markerPointDetails(liveAgency: liveAgency),
    );
  }

  Future<void> launchPhoneDial({required int phoneNo}) async {
    final Uri url = Uri(
      scheme: 'tel',
      path: phoneNo.toString(),
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      debugPrint("Cannot launch phoneCall url");
    }
  }

  Future<void> getPutRescueButtonOperations({
    required String apiUrl,
  }) async {
    TextEditingController rescueReasonText = TextEditingController();
    final GlobalKey<FormState> formKey = GlobalKey<FormState>();

    if (apiUrl == rescueMeUrl) {
      await showDialog(
        barrierDismissible: false,
        context: context,
        barrierColor: const Color.fromARGB(155, 0, 0, 0),
        builder: (context) => FadeInUp(
          duration: const Duration(milliseconds: 500),
          child: AlertDialog(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Theme.of(context).colorScheme.secondary,
            title: Text(
              "Give a reason, why you need help!",
              style: GoogleFonts.lato(
                fontWeight: FontWeight.bold,
                fontSize: 22,
              ),
            ),
            content: Form(
              key: formKey,
              child: TextFieldWidget(
                controllerText: rescueReasonText,
                textHint: "Enter reason",
                textfieldColor: Colors.transparent,
                checkValidation: (value) {
                  if (value!.trim().isEmpty) {
                    return "Please enter valid reason!";
                  }
                  return null;
                },
              ),
            ),
            actions: [
              Center(
                child: TextButton(
                  onPressed: () {
                    rescueReasonText.clear();
                    Navigator.of(context).pop(false);
                  },
                  child: const CustomTextWidget(
                    text: "Skip",
                    color: Colors.blue,
                    fontSize: 14,
                  ),
                ),
              ),
              Center(
                child: TextButton(
                  onPressed: () {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(context).pop();
                    }
                  },
                  child: const CustomTextWidget(
                    text: "Send",
                    color: Colors.green,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }
    // return;
    setState(() {
      activeRescueMeButton = const SizedBox(
        height: 25,
        width: 25,
        child: CircularProgressIndicator(
          color: Colors.white,
        ),
      );
    });

    var body = {
      "lat": latLng[0],
      "lng": latLng[1],
      "rescueReason": rescueReasonText.text.trim(),
    };

    debugPrint("Rescue reason body from user: ${body.toString()}");

    http.Response response;

    try {
      if (apiUrl == rescueMeUrl) {
        response = await http.post(
          Uri.parse(
            apiUrl,
          ),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${widget.token}"
          },
          body: jsonEncode(body),
        );
      } else {
        response = await http.put(
          Uri.parse(
            apiUrl,
          ),
          headers: {
            "Content-Type": "application/json",
            "Authorization": "Bearer ${widget.token}"
          },
          body: jsonEncode(body),
        );
      }

      if (response.statusCode == 200) {
        await getIsRescueOnGoing();
        if (isRescueMeOnGoing!) {
          initialConnectSendLocation();
        } else {
          Navigator.of(context).pop();
        }

        var jsonResponse = jsonDecode(response.body);

        String message = jsonResponse["message"];

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              message,
              textAlign: TextAlign.center,
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint(
          "Exception occured while putting rescue me user: ${e.toString()}");
    }

    setState(() {
      initializeButtonValue();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (mounted) {
      latLng = ref.watch(deviceLocationProvider);
    }
    return Scaffold(
      body: FadeInUp(
        delay: const Duration(milliseconds: 300),
        duration: const Duration(milliseconds: 500),
        child: Stack(
          children: [
            FlutterMap(
              options: MapOptions(
                center: LatLng(latLng[0], latLng[1]),
                zoom: 12,
                interactiveFlags: InteractiveFlag.all,
              ),
              children: [
                openStreetMapTileLayer,
                MarkerLayer(
                  markers: [
                    // Marker of this device
                    Marker(
                      point: LatLng(latLng[0], latLng[1]),
                      width: 60,
                      height: 60,
                      rotateAlignment: Alignment.centerLeft,
                      builder: (
                        context,
                      ) {
                        return Column(
                          children: [
                            Expanded(
                              child: Image.asset(
                                  "assets/logos/maps_screen_logos/selfposition.png"),
                            ),
                            const CustomTextWidget(
                              text: "Me",
                              fontSize: 12,
                              color: Colors.black,
                            ),
                          ],
                        );
                      },
                    ),

                    for (var liveAgency in liveAgencies)
                      Marker(
                        point: LatLng(liveAgency.lat!, liveAgency.lng!),
                        width: 60,
                        height: 60,
                        rotateAlignment: Alignment.centerLeft,
                        builder: (
                          context,
                        ) {
                          return GestureDetector(
                            onTap: () {
                              openModalBottomSheet(liveAgency: liveAgency);
                            },
                            child: Column(
                              children: [
                                Expanded(
                                  child: Image.asset(
                                    liveAgency.rescueOpsName == null
                                        ? "assets/logos/maps_screen_logos/agencySpying.PNG"
                                        : "assets/logos/maps_screen_logos/agencyRescuing.PNG",
                                  ),
                                ),
                                Flexible(
                                  child: CustomTextWidget(
                                    text: liveAgency.agencyName ?? "",
                                    fontSize: 12,
                                    color: Colors.black,
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                  ],
                ),
              ],
            ),
            if (isRescueMeOnGoing != null)
              Positioned(
                bottom: 10,
                left: 0,
                right: 0,
                child: CustomElevatedButton(
                  childWidget: activeRescueMeButton!,
                  onPressed: () {
                    getPutRescueButtonOperations(
                        apiUrl:
                            isRescueMeOnGoing! ? stopRescueMeUrl : rescueMeUrl);
                  },
                  onPressedEnabled: true,
                  backgroundColor: isRescueMeOnGoing!
                      ? Colors.green
                      : const Color.fromARGB(255, 180, 24, 13),
                ),
              ),
            const Positioned(
              top: 30,
              right: 10,
              child: CustomBackButton(
                text: "back",
                outlinedColor: Color.fromARGB(185, 30, 35, 44),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget markerPointDetails({required LiveAgencies liveAgency}) {
    return Padding(
      padding: const EdgeInsets.only(
        top: 15,
        left: 12,
        right: 12,
        bottom: 5,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            liveAgency.rescueOpsName == null
                ? 'Agency Details'
                : 'Rescue Operation Started',
            style: GoogleFonts.mulish().copyWith(
              fontWeight: FontWeight.bold,
              color:
                  liveAgency.rescueOpsName == null ? Colors.blue : Colors.green,
              fontSize: 21,
            ),
          ),
          const SizedBox(
            height: 10,
          ),
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Agency Name'.toUpperCase(),
                      style: GoogleFonts.mulish().copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      liveAgency.agencyName!,
                      style: GoogleFonts.mulish().copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Representative Name'.toUpperCase(),
                      style: GoogleFonts.mulish().copyWith(
                        fontWeight: FontWeight.w900,
                        fontSize: 15,
                      ),
                    ),
                    Text(
                      liveAgency.representativeName!,
                      style: GoogleFonts.mulish().copyWith(
                        fontWeight: FontWeight.w500,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(
                  height: 8,
                ),
                if (liveAgency.rescueOpsName != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rescue Operation Name'.toUpperCase(),
                        style: GoogleFonts.mulish().copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        liveAgency.rescueOpsName!,
                        style: GoogleFonts.mulish().copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                if (liveAgency.rescueOpsName != null)
                  const SizedBox(
                    height: 8,
                  ),
                if (liveAgency.rescueOpsDescription != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description'.toUpperCase(),
                        style: GoogleFonts.mulish().copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        liveAgency.rescueOpsDescription!,
                        style: GoogleFonts.mulish().copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                if (liveAgency.rescueOpsName != null)
                  const SizedBox(
                    height: 8,
                  ),
                if (liveAgency.rescueTeamSize != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Rescue Team Size'.toUpperCase(),
                        style: GoogleFonts.mulish().copyWith(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        liveAgency.rescueTeamSize!.toString(),
                        style: GoogleFonts.mulish().copyWith(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                if (liveAgency.rescueOpsName != null)
                  const SizedBox(
                    height: 8,
                  ),

                Row(
                  children: [
                    const Icon(
                      Icons.star_border_outlined,
                      size: 30,
                      color: Colors.blue,
                    ),
                    const SizedBox(
                      width: 11,
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Agency Phone'.toUpperCase(),
                          style: GoogleFonts.mulish().copyWith(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                          ),
                        ),
                        Text(
                          liveAgency.phoneNumber.toString(),
                          style: GoogleFonts.mulish().copyWith(
                            fontWeight: FontWeight.w500,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                // const Divider(thickness: 0.2),
                const SizedBox(
                  height: 50,
                ),
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 20, top: 10),
                    child: SizedBox(
                      width: 200,
                      height: 40,
                      child: ElevatedButton(
                        onPressed: () async {
                          await launchPhoneDial(
                            phoneNo: liveAgency.phoneNumber!,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          foregroundColor:
                              Theme.of(context).colorScheme.primary,
                          backgroundColor: const Color(0xff1E232C),
                        ),
                        child: Text(
                          'CALL',
                          style: TextStyle(
                            fontSize: 16,
                            color: Theme.of(context).colorScheme.onBackground,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

TileLayer get openStreetMapTileLayer => TileLayer(
      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
      userAgentPackageName: 'dev.fleaflet.flutter_map.example',
    );
