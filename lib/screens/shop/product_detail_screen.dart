import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:fixy_home_service/models/product_model.dart';
import 'package:fixy_home_service/providers/cart_provider.dart';
import 'package:fixy_home_service/providers/favorites_provider.dart';
import 'package:fixy_home_service/screens/shop/cart_screen.dart';
import 'package:fixy_home_service/theme/app_theme.dart';
import 'package:fixy_home_service/widgets/cart_badge.dart';
import 'package:fixy_home_service/utils/page_transitions.dart';

class ProductDetailScreen extends StatefulWidget {
  final ProductModel product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with TickerProviderStateMixin {
  int _currentImageIndex = 0;
  int _quantity = 1;
  final GlobalKey _cartIconKey = GlobalKey();
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _showImageZoom(String imageUrl) {
    showDialog(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: EdgeInsets.zero,
        child: Stack(
          children: [
            Center(
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.image_not_supported,
                    size: 100,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            Positioned(
              top: 40,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _animateToCart(BuildContext context) {
    final cartIcon =
        _cartIconKey.currentContext?.findRenderObject() as RenderBox?;
    if (cartIcon == null) return;

    final cartPosition = cartIcon.localToGlobal(Offset.zero);
    final overlay = Overlay.of(context);
    final renderBox = context.findRenderObject() as RenderBox;
    final size = renderBox.size;

    final animController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    final animation = Tween<Offset>(
      begin: Offset(size.width / 2, size.height - 100),
      end: Offset(cartPosition.dx + 20, cartPosition.dy + 20),
    ).animate(CurvedAnimation(parent: animController, curve: Curves.easeInOut));

    final overlayEntry = OverlayEntry(
      builder: (context) => AnimatedBuilder(
        animation: animation,
        builder: (context, child) {
          return Positioned(
            left: animation.value.dx,
            top: animation.value.dy,
            child: Opacity(
              opacity: 1 - animController.value * 0.5,
              child: Transform.scale(
                scale: 1 - animController.value * 0.5,
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.shopping_cart,
                      color: Colors.white, size: 30),
                ),
              ),
            ),
          );
        },
      ),
    );

    overlay.insert(overlayEntry);
    animController.forward().then((_) {
      overlayEntry.remove();
      animController.dispose();
    });
  }

  void _buyNow(BuildContext context) {
    context.read<CartProvider>().addToCart(widget.product, quantity: _quantity);
    Navigator.push(
      context,
      SlideUpRoute(page: const CartScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE8ECF3),
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 350,
            floating: false,
            pinned: true,
            backgroundColor: const Color(0xFFE8ECF3),
            elevation: 0,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFE8ECF3),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  const BoxShadow(
                    color: Color(0xFFFFFFFF),
                    offset: Offset(-2, -2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                  BoxShadow(
                    color: const Color(0xFF2D3748).withValues(alpha: 0.15),
                    offset: const Offset(2, 2),
                    blurRadius: 4,
                    spreadRadius: 0,
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back,
                    color: Color(0xFF2D3748), size: 20),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Consumer<FavoritesProvider>(
                builder: (context, favProvider, _) {
                  final isFavorite = favProvider.isFavorite(widget.product.id);
                  return IconButton(
                    icon: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8ECF3),
                        shape: BoxShape.circle,
                        boxShadow: [
                          const BoxShadow(
                            color: Color(0xFFFFFFFF),
                            offset: Offset(-2, -2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                          BoxShadow(
                            color:
                                const Color(0xFF2D3748).withValues(alpha: 0.15),
                            offset: const Offset(2, 2),
                            blurRadius: 4,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite ? Colors.red : Color(0xFF2D3748),
                        size: 20,
                      ),
                    ),
                    onPressed: () =>
                        favProvider.toggleFavorite(widget.product.id),
                  );
                },
              ),
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: CartBadge(
                  key: _cartIconKey,
                  onTap: () {
                    Navigator.push(
                      context,
                      SlideUpRoute(page: const CartScreen()),
                    );
                  },
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                color: const Color(0xFFE8ECF3),
                child: Stack(
                  children: [
                    PageView.builder(
                      itemCount: widget.product.images.length,
                      onPageChanged: (index) {
                        setState(() => _currentImageIndex = index);
                      },
                      itemBuilder: (context, index) {
                        final imageUrl = widget.product.images[index];
                        return GestureDetector(
                          onTap: () => _showImageZoom(imageUrl),
                          child: Hero(
                            tag: index == 0
                                ? 'product-${widget.product.id}'
                                : 'product-${widget.product.id}-$index',
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Container(
                                color: Colors.grey[200],
                                child: const Icon(Icons.image_not_supported,
                                    size: 80),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                    if (widget.product.images.length > 1)
                      Positioned(
                        bottom: 16,
                        left: 0,
                        right: 0,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            widget.product.images.length,
                            (index) => Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _currentImageIndex == index
                                    ? Colors.white
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          ),
                        ),
                      ),
                    if (widget.product.isOnSale)
                      Positioned(
                        top: 60,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFF3B30),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${widget.product.discountPercentage.toStringAsFixed(0)}% OFF',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Product details
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Brand and rating
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color:
                                  AppTheme.primaryColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              widget.product.brand,
                              style: TextStyle(
                                color: AppTheme.primaryColor,
                                fontWeight: FontWeight.w600,
                                fontSize: 13,
                              ),
                            ),
                          ),
                          Row(
                            children: [
                              Icon(Icons.star,
                                  size: 18, color: Colors.amber[700]),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.product.rating}',
                                style: TextStyle(
                                  color: AppTheme.textPrimary,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                ' (${widget.product.reviewCount} reseñas)',
                                style: TextStyle(
                                  color: AppTheme.textSecondary,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Product name
                      Text(
                        widget.product.name,
                        style: AppTheme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textPrimary,
                          height: 1.3,
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Price
                      Row(
                        children: [
                          if (widget.product.originalPrice != null) ...[
                            Text(
                              'S/ ${widget.product.originalPrice!.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: AppTheme.textSecondary,
                                fontSize: 16,
                                decoration: TextDecoration.lineThrough,
                              ),
                            ),
                            const SizedBox(width: 12),
                          ],
                          Text(
                            'S/ ${widget.product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: AppTheme.primaryColor,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 8),

                      // Stock status
                      Row(
                        children: [
                          Icon(
                            widget.product.isInStock
                                ? Icons.check_circle
                                : Icons.cancel,
                            size: 18,
                            color: widget.product.isInStock
                                ? Colors.green
                                : Colors.red,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            widget.product.isInStock
                                ? '${widget.product.stock} disponibles'
                                : 'Agotado',
                            style: TextStyle(
                              color: widget.product.isInStock
                                  ? Colors.green
                                  : Colors.red,
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),
                      Divider(color: Colors.grey.withValues(alpha: 0.2)),
                      const SizedBox(height: 20),

                      // Description
                      Text(
                        'Descripción',
                        style: AppTheme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        widget.product.description,
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 15,
                          height: 1.6,
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Specifications
                      if (widget.product.specifications.isNotEmpty) ...[
                        Text(
                          'Especificaciones',
                          style: AppTheme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 12),
                        ...widget.product.specifications.map(
                          (spec) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(Icons.check,
                                    size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    spec,
                                    style: TextStyle(
                                      color: AppTheme.textSecondary,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 150),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: widget.product.isInStock
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: 20,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        // Quantity selector
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(
                                color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.remove),
                                onPressed: _quantity > 1
                                    ? () => setState(() => _quantity--)
                                    : null,
                              ),
                              Text(
                                '$_quantity',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.add),
                                onPressed: _quantity < widget.product.stock
                                    ? () => setState(() => _quantity++)
                                    : null,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(width: 12),

                        // Add to cart button
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              _animateToCart(context);
                              context.read<CartProvider>().addToCart(
                                    widget.product,
                                    quantity: _quantity,
                                  );
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Row(
                                    children: [
                                      Icon(Icons.check_circle,
                                          color: Colors.white),
                                      SizedBox(width: 12),
                                      Expanded(
                                          child: Text('Agregado al carrito')),
                                    ],
                                  ),
                                  backgroundColor: Colors.green,
                                  behavior: SnackBarBehavior.floating,
                                  duration: const Duration(seconds: 2),
                                ),
                              );
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: AppTheme.primaryColor,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              side: BorderSide(
                                  color: AppTheme.primaryColor, width: 2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_shopping_cart,
                                    color: AppTheme.primaryColor, size: 20),
                                const SizedBox(width: 8),
                                const Text(
                                  'Agregar',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Buy now button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => _buyNow(context),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text(
                          'Comprar Ahora',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            )
          : null,
    );
  }
}
