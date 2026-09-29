import 'package:flutter/material.dart';

class AppSearchBar extends StatelessWidget {
  final TextEditingController controller;
  final ValueChanged<String>? onChanged;
  final String hint;

  const AppSearchBar({
    super.key,
    required this.controller,
    this.onChanged,
    this.hint = 'Cari barang...',
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search),
        suffixIcon: controller.text.isNotEmpty
            ? IconButton(
                onPressed: () {
                  controller.clear();

                  if (onChanged != null) {
                    onChanged!('');
                  }
                },
                icon: const Icon(Icons.clear),
              )
            : null,
      ),
    );
  }
}
