import 'package:flutter/material.dart';
import '../core/network/api_client.dart';
import '../core/network/api_endpoints.dart';
import '../data/models/product_model.dart';

class ProductProvider extends ChangeNotifier {
  List<ProductModel> _allProducts = [];
  bool _isLoading = false;
  String? _errorMessage;

  int _selectedCategory = 0; // 0 = Todos, 1 = Comidas, 2 = Bebidas, 3 = Servicios
  String _searchQuery = '';
  String _sortBy = 'default';

  List<ProductModel> get allProducts => _allProducts;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  int get selectedCategory => _selectedCategory;
  String get searchQuery => _searchQuery;
  String get sortBy => _sortBy;

  ProductProvider() {
    fetchProducts();
  }

  Future<void> fetchProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiClient.get<dynamic>(
        ApiEndpoints.products,
      );

      if (res.success && res.data != null) {
        List<dynamic> itemsList = [];
        if (res.data is Map && (res.data as Map).containsKey('productos')) {
          itemsList = res.data['productos'] as List<dynamic>;
        } else if (res.data is List) {
          itemsList = res.data as List<dynamic>;
        }

        _allProducts = itemsList
            .map((item) => ProductModel.fromJson(item as Map<String, dynamic>))
            .toList();
      } else {
        _errorMessage = res.message;
        if (_allProducts.isEmpty) {
          _allProducts = _getFallbackProducts();
        }
      }
    } catch (_) {
      if (_allProducts.isEmpty) {
        _allProducts = _getFallbackProducts();
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setCategory(int categoryId) {
    _selectedCategory = categoryId;
    notifyListeners();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setSortBy(String sort) {
    _sortBy = sort;
    notifyListeners();
  }

  List<ProductModel> get filteredProducts {
    var list = _allProducts.where((p) {
      final matchesCategory = _selectedCategory == 0 || p.categoriaId == _selectedCategory;
      final matchesSearch = _searchQuery.isEmpty ||
          p.nombre.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          p.descripcion.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    switch (_sortBy) {
      case 'price_asc':
        list.sort((a, b) => a.precio.compareTo(b.precio));
        break;
      case 'price_desc':
        list.sort((a, b) => b.precio.compareTo(a.precio));
        break;
      case 'name_asc':
        list.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
        break;
      default:
        break;
    }

    return list;
  }

  List<ProductModel> _getFallbackProducts() {
    return [
      ProductModel(
        id: '1',
        nombre: 'Hamburguesa de la casa',
        descripcion: 'Carne artesanal, queso fundido y vegetales frescos servidos directamente en tu carpa o toalla.',
        precio: 25000.0,
        cantidadDisponible: 20,
        categoriaId: 1,
        categoriaNombre: 'Comida',
      ),
      ProductModel(
        id: '2',
        nombre: 'Pescado frito con patacón',
        descripcion: 'Mojarra roja fresca acompañada de patacones crocantes, ensalada caribeña y arroz con coco.',
        precio: 35000.0,
        cantidadDisponible: 15,
        categoriaId: 1,
        categoriaNombre: 'Comida',
      ),
      ProductModel(
        id: '3',
        nombre: 'Cerveza nacional fría',
        descripcion: 'Club Colombia, Águila o Poker bien helada para calmar el calor de la playa.',
        precio: 7000.0,
        cantidadDisponible: 60,
        categoriaId: 2,
        categoriaNombre: 'Bebida',
      ),
      ProductModel(
        id: '4',
        nombre: 'Limonada de coco',
        descripcion: 'Deliciosa limonada cremosa preparada con leche de coco natural y hielo frappé.',
        precio: 14000.0,
        cantidadDisponible: 25,
        categoriaId: 2,
        categoriaNombre: 'Bebida',
      ),
      ProductModel(
        id: '5',
        nombre: 'Arepa de huevo costeña',
        descripcion: 'Típica arepa cartagenera rellena de huevo fresco frita al punto.',
        precio: 9000.0,
        cantidadDisponible: 30,
        categoriaId: 1,
        categoriaNombre: 'Comida',
      ),
      ProductModel(
        id: '6',
        nombre: 'Alquiler de Carpa & Sillas',
        descripcion: 'Servicio diario de carpa de sombra con dos sillas reclinables en la orilla de Bocagrande.',
        precio: 30000.0,
        cantidadDisponible: 10,
        categoriaId: 3,
        categoriaNombre: 'Servicio',
      ),
    ];
  }
}
