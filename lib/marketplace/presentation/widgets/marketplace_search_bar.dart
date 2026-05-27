import 'dart:async';
import 'package:flutter/material.dart';

import '../../config/theme/marketplace_theme.dart';

/// MarketplaceSearchBar - Barra de búsqueda con debounce
/// Inspirado en: Amazon search, eBay search bar
class MarketplaceSearchBar extends StatefulWidget {
  const MarketplaceSearchBar({
    super.key,
    required this.onSearch,
    this.onClear,
    this.initialQuery,
    this.debounceDuration = 300,
    this.hintText = 'Buscar productos...',
  });
  final Function(String) onSearch;
  final VoidCallback? onClear;
  final String? initialQuery;
  final int debounceDuration; // en milisegundos
  final String hintText;

  @override
  State<MarketplaceSearchBar> createState() => _MarketplaceSearchBarState();
}

class _MarketplaceSearchBarState extends State<MarketplaceSearchBar> {
  final TextEditingController _controller = TextEditingController();
  Timer? _debounceTimer;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialQuery != null) {
      _controller.text = widget.initialQuery!;
      _hasText = widget.initialQuery!.isNotEmpty;
    }
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    setState(() {
      _hasText = _controller.text.isNotEmpty;
    });

    // Cancelar timer anterior
    _debounceTimer?.cancel();

    // Crear nuevo timer con debounce
    _debounceTimer = Timer(Duration(milliseconds: widget.debounceDuration), () {
      widget.onSearch(_controller.text);
    });
  }

  void _clearSearch() {
    _controller.clear();
    setState(() {
      _hasText = false;
    });
    widget.onClear?.call();
    widget.onSearch('');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 15),
          prefixIcon: const Icon(
            Icons.search,
            color: MarketplaceTheme.primary,
            size: 22,
          ),
          suffixIcon: _hasText
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    color: Colors.grey.shade600,
                    size: 20,
                  ),
                  onPressed: _clearSearch,
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 14,
          ),
        ),
        style: const TextStyle(fontSize: 15, color: Colors.black87),
      ),
    );
  }
}
