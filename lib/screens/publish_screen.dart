import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'dart:io';

class PublishScreen extends StatefulWidget {
  const PublishScreen({super.key});

  @override
  State<PublishScreen> createState() => _PublishScreenState();
}

class _PublishScreenState extends State<PublishScreen> {
  final _formKey = GlobalKey<FormState>();
  final nameController = TextEditingController();
  final priceController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedSede = 'Sede Talca';
  final List<String> sedes = ['Sede Talca', 'Sede Temuco', 'Sede Santiago'];

  // --- NUEVO: Opciones de Categoría ---
  String selectedCategory = 'Tecnología';
  final List<String> categories = ['Electrodomésticos', 'Tecnología', 'Muebles', 'Hogar', 'Ropa y Accesorios', 'Otros'];

  File? _image;
  final ImagePicker _picker = ImagePicker();
  bool isLoading = false;
  String? _detectedCity;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) return;
    }
    if (permission == LocationPermission.deniedForever) return;

    Position position = await Geolocator.getCurrentPosition();
    if (position.latitude < -35.0 && position.latitude > -36.0) {
      _detectedCity = 'Talca';
    } else if (position.latitude < -38.0 && position.latitude > -40.0) {
      _detectedCity = 'Temuco';
    } else {
      _detectedCity = 'Santiago';
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 50);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
    }
  }

  Future<void> _uploadProduct() async {
    if (!_formKey.currentState!.validate()) return;
    if (_image == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Por favor, selecciona una foto del producto")));
      return;
    }

    setState(() => isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw "No hay sesión iniciada";

      String localImagePath = _image!.path;

      await FirebaseFirestore.instance.collection('products').add({
        'title': nameController.text.trim(),
        'price': priceController.text.trim(),
        'description': descriptionController.text.trim(),
        'universitySede': selectedSede,
        'category': selectedCategory, // <-- Guardamos la categoría en Firebase
        'detectedCity': _detectedCity ?? 'Sede Principal',
        'localImagePath': localImagePath,
        'sellerId': user.uid,
        'sellerEmail': user.email,
        'isSold': false, // Lo inicializamos disponible por defecto
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("¡Producto publicado con éxito!"), backgroundColor: Colors.green));
        Navigator.pop(context); 
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text("Publicar Artículo", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFAF0303),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 180,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(color: Colors.grey.shade300, style: BorderStyle.solid),
                    image: _image != null ? DecorationImage(image: FileImage(_image!), fit: BoxFit.cover) : null,
                  ),
                  child: _image == null 
                    ? const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_a_photo, size: 50, color: Color(0xFFAF0303)),
                          SizedBox(height: 10),
                          Text("Sube una foto", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.bold)),
                        ],
                      )
                    : null,
                ),
              ),
              const SizedBox(height: 25),

              const Text("Detalles del Producto", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),

              _buildTextField(controller: nameController, label: "Nombre del artículo", icon: Icons.title, validator: (v) => v!.isEmpty ? "Falta el título" : null),
              const SizedBox(height: 15),
              
              _buildTextField(controller: priceController, label: "Precio del producto", icon: Icons.attach_money, isNumber: true, validator: (v) => v!.isEmpty ? "Falta el precio" : null),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedCategory,
                    isExpanded: true,
                    icon: const Icon(Icons.category, color: Color(0xFFAF0303)),
                    items: categories.map((String cat) {
                      return DropdownMenuItem(value: cat, child: Text(cat));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedCategory = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 5),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), border: Border.all(color: Colors.grey.shade300)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: selectedSede,
                    isExpanded: true,
                    icon: const Icon(Icons.location_city, color: Color(0xFFAF0303)),
                    items: sedes.map((String sede) {
                      return DropdownMenuItem(value: sede, child: Text(sede));
                    }).toList(),
                    onChanged: (String? newValue) {
                      setState(() {
                        selectedSede = newValue!;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 15),

              TextFormField(
                controller: descriptionController,
                maxLines: 4,
                decoration: InputDecoration(
                  hintText: "Descripción (opcional, detalles adicionales)",
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide(color: Colors.grey.shade300)),
                ),
              ),
              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _uploadProduct,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFAF0303),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  ),
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("PUBLICAR PRODUCTO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({required TextEditingController controller, required String label, required IconData icon, bool isNumber = false, required String? Function(String?) validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: isNumber ? TextInputType.number : TextInputType.text,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: const Color(0xFFAF0303)),
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(15), borderSide: BorderSide.none),
      ),
    );
  }
}