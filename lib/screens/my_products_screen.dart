import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:io';
import 'edit_actual_product_screen.dart'; // Importamos la nueva pantalla

class MyProductsScreen extends StatelessWidget {
  const MyProductsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text("Gestión de Ventas", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: const Color(0xFFAF0303),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('products')
            .where('sellerId', isEqualTo: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFAF0303)));
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return _buildEmptyState(isDarkMode);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              var productDoc = snapshot.data!.docs[index];
              return _buildEstilosoCard(context, productDoc, isDarkMode);
            },
          );
        },
      ),
    );
  }

  Widget _buildEstilosoCard(BuildContext context, DocumentSnapshot doc, bool isDarkMode) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    bool isSold = data['isSold'] ?? false;

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.4 : 0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        width: 100,
                        height: 100,
                        child: data['localImagePath'] != null 
                          ? Image.file(File(data['localImagePath']), fit: BoxFit.cover)
                          : Container(color: Colors.grey[200], child: const Icon(Icons.image)),
                      ),
                    ),
                    if (isSold)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black45,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Icon(Icons.check_circle, color: Colors.white, size: 30),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(data['title'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Text("\$${data['price']}", style: const TextStyle(color: Color(0xFFAF0303), fontWeight: FontWeight.w900, fontSize: 18)),
                      const SizedBox(height: 8),
                      // Etiqueta de Sede
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(color: Colors.grey.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(data['universitySede'] ?? 'UA', style: const TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                ),
              ),
              PopupMenuButton(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                icon: const Icon(Icons.more_vert_rounded, color: Colors.grey),
                onSelected: (value) => _handleAction(context, value, doc),
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'sold',
                    child: ListTile(
                      leading: Icon(isSold ? Icons.storefront : Icons.done_all, color: Colors.green),
                      title: Text(isSold ? "Volver a poner a la venta" : "Marcar como vendido"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'edit',
                    child: ListTile(
                      leading: Icon(Icons.edit_outlined, color: Colors.blue),
                      title: Text("Editar información"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_sweep_outlined, color: Colors.red),
                      title: Text("Eliminar anuncio"),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _handleAction(BuildContext context, String action, DocumentSnapshot doc) async {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    if (action == 'sold') {
      bool currentStatus = data['isSold'] ?? false; 
      
      try {
        await FirebaseFirestore.instance.collection('products').doc(doc.id).update({
          'isSold': !currentStatus
        });
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(currentStatus ? "¡Producto de nuevo a la venta!" : "¡Felicidades por tu venta!"),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating, // Le da un toque estético extra al mensaje
          ));
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e"), backgroundColor: Colors.red));
        }
      }
    } else if (action == 'edit') {
      Navigator.push(context, MaterialPageRoute(builder: (context) => EditActualProductScreen(product: doc)));
    } else if (action == 'delete') {
      _showDeleteDialog(context, doc);
    }
  }

  void _showDeleteDialog(BuildContext context, DocumentSnapshot doc) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text("¿Borrar anuncio?"),
        content: const Text("Esto eliminará el producto del Marketplace de forma permanente."),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR")),
          TextButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection('products').doc(doc.id).delete();
              Navigator.pop(context);
            }, 
            child: const Text("BORRAR", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold))
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 100, color: Colors.grey.withOpacity(0.3)),
          const SizedBox(height: 20),
          Text("Tu inventario está vacío", style: TextStyle(fontSize: 18, color: isDarkMode ? Colors.white54 : Colors.grey, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}