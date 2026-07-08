import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';


class SeleccionarUbicacionScreen extends StatefulWidget {

  final double latitudInicial;
  final double longitudInicial;


  const SeleccionarUbicacionScreen({
    super.key,
    required this.latitudInicial,
    required this.longitudInicial,
  });


  @override
  State<SeleccionarUbicacionScreen> createState() =>
      _SeleccionarUbicacionScreenState();

}



class _SeleccionarUbicacionScreenState
    extends State<SeleccionarUbicacionScreen> {


  late LatLng posicionSeleccionada;

  late GoogleMapController mapaController;



  @override
  void initState() {
    super.initState();

    posicionSeleccionada = LatLng(
      widget.latitudInicial,
      widget.longitudInicial,
    );

  }



  Future<void> obtenerUbicacionActual() async {


    bool servicioActivo =
        await Geolocator.isLocationServiceEnabled();


    if (!servicioActivo) {
      return;
    }



    LocationPermission permiso =
        await Geolocator.checkPermission();



    if (permiso == LocationPermission.denied) {

      permiso =
          await Geolocator.requestPermission();

    }



    if (permiso == LocationPermission.deniedForever) {
      return;
    }



    Position posicion =
        await Geolocator.getCurrentPosition();



    final nuevaPosicion = LatLng(
      posicion.latitude,
      posicion.longitude,
    );



    setState(() {

      posicionSeleccionada = nuevaPosicion;

    });



    mapaController.animateCamera(

      CameraUpdate.newLatLngZoom(
        nuevaPosicion,
        16,
      ),

    );


  }



  @override
  Widget build(BuildContext context) {


    return Scaffold(

      appBar: AppBar(
        title: const Text(
          "Seleccionar ubicación",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.white,
          ),
        ),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
      ),



      body: GoogleMap(


        initialCameraPosition: CameraPosition(

          target: posicionSeleccionada,

          zoom: 16,

        ),



        onMapCreated: (controller){

          mapaController = controller;

        },



        markers: {

          Marker(

            markerId:
                const MarkerId("ubicacion"),

            position:
                posicionSeleccionada,

          )

        },



        onTap: (LatLng nuevaPosicion){


          setState(() {

            posicionSeleccionada =
                nuevaPosicion;

          });


        },



      ),




      floatingActionButton: Column(

        mainAxisAlignment:
            MainAxisAlignment.end,


        children: [


          FloatingActionButton(

            heroTag: "gps",

            backgroundColor: Colors.green.shade700,

            onPressed:
                obtenerUbicacionActual,


            child:
                const Icon(Icons.my_location),


          ),



          const SizedBox(height: 10),



          FloatingActionButton.extended(


            heroTag: "guardar",

            backgroundColor:
                Colors.green.shade700,



            onPressed: (){


              Navigator.pop(

                context,

                {

                  'lat':
                      posicionSeleccionada.latitude,


                  'lng':
                      posicionSeleccionada.longitude,

                },

              );


            },



            icon:
                const Icon(Icons.check),



            label:
                const Text("Seleccionar"),


          ),


        ],

      ),

    );


  }


}