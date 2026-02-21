import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

class CartItem {
  final Product product;
  final int quantity;

  const CartItem({
    required this.product,
    required this.quantity,
  });

  double get total => product.sellingPrice * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

class CartState {
  final List<CartItem> items;
  
  const CartState({this.items = const []});

  double get totalAmount => items.fold(0, (sum, item) => sum + item.total);
  int get totalItems => items.fold(0, (sum, item) => sum + item.quantity);
  
  CartState copyWith({List<CartItem>? items}) {
    return CartState(items: items ?? this.items);
  }
}

final cartProvider = NotifierProvider<CartNotifier, CartState>(CartNotifier.new);

class CartNotifier extends Notifier<CartState> {
  @override
  CartState build() {
    return const CartState();
  }

  void addItem(Product product, {int quantity = 1}) {
    final existingIndex = state.items.indexWhere((item) => item.product.id == product.id);
    
    if (existingIndex >= 0) {
      final existingItem = state.items[existingIndex];
      final updatedItems = [...state.items];
      updatedItems[existingIndex] = existingItem.copyWith(
        quantity: existingItem.quantity + quantity,
      );
      state = state.copyWith(items: updatedItems);
    } else {
      state = state.copyWith(
        items: [...state.items, CartItem(product: product, quantity: quantity)],
      );
    }
  }

  void removeItem(String productId) {
    state = state.copyWith(
      items: state.items.where((item) => item.product.id != productId).toList(),
    );
  }

  void updateQuantity(String productId, int quantity) {
    if (quantity <= 0) {
      removeItem(productId);
      return;
    }

    final index = state.items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      final updatedItems = [...state.items];
      updatedItems[index] = updatedItems[index].copyWith(quantity: quantity);
      state = state.copyWith(items: updatedItems);
    }
  }

  void clear() {
    state = const CartState();
  }
}
