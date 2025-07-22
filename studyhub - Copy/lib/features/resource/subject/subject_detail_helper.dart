import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

List<Widget> buildSegmentButtons(int selectedTab, Function(int) onTap) {
  final tabs = ['Photos', 'PDFs', 'DOCX', 'PPTX', 'YouTube', 'Favorites'];
  return List.generate(tabs.length, (index) {
    final isSelected = selectedTab == index;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onTap(index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF6366F1) : Colors.white,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Text(
            tabs[index],
            style: TextStyle(
              color: isSelected ? Colors.white : Colors.black,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  });
}

Widget buildTabContent(
  List<DocumentSnapshot> files,
  int selectedTab,
  Function(String, bool) toggleFavorite,
  Function(String) launchURL,
) {
  final types = ['photo', 'pdf', 'docx', 'pptx', 'youtube', 'favorite'];
  final selectedType = selectedTab == 5 ? 'favorite' : types[selectedTab];

  final filtered = selectedType == 'favorite'
      ? files.where((e) => e['isFavorite'] == true).toList()
      : files.where((e) => e['type'] == selectedType).toList();

  if (filtered.isEmpty) {
    return const Center(child: Text('No files here'));
  }

  return ListView.builder(
    itemCount: filtered.length,
    itemBuilder: (_, i) {
      final f = filtered[i];
      return ListTile(
        leading: Icon(_iconForType(f['type'])),
        title: Text(f['name']),
        trailing: IconButton(
          icon: Icon(
            f['isFavorite'] ? Icons.star : Icons.star_border,
            color: f['isFavorite'] ? Colors.amber : Colors.grey,
          ),
          onPressed: () => toggleFavorite(f.id, f['isFavorite']),
        ),
        onTap: () => launchURL(f['url']),
      );
    },
  );
}

IconData _iconForType(String type) {
  switch (type) {
    case 'photo':
      return Icons.image;
    case 'pdf':
      return Icons.picture_as_pdf;
    case 'docx':
      return Icons.description;
    case 'pptx':
      return Icons.slideshow;
    case 'youtube':
      return Icons.link;
    default:
      return Icons.insert_drive_file;
  }
}
