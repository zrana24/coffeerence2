import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'history_screen.dart';
import 'app_bottom_nav_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'login_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int campaignPage = 0;
  int productPage = 0;
  List<dynamic> products = [];
  List<dynamic> banners = [];
  bool isLoading = true;
  bool isBannerLoading = true;
  int coffeeCount = 0;

  @override
  void initState() {
    super.initState();
    fetchProducts();
    fetchBanners();
    fetchCoffeeCount();
  }

  Future<void> fetchCoffeeCount() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('token');

      if (token == null) {
        setState(() => coffeeCount = 0);
        return;
      }

      final response = await http.get(
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/coffeerence/coffe_count'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int rawCount = data['freecoffe'] is int
            ? data['freecoffe']
            : int.tryParse(data['freecoffe'].toString()) ?? 0;
        int displayCount = rawCount == 10 ? 0 : 10 - rawCount;

        setState(() => coffeeCount = displayCount);
      }
    }
    catch (e) {
      print('Kahve sayısı alınamadı: $e');
    }
  }

  Future<void> fetchProducts() async {
    setState(() => isLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/all_products'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          products = data is List ? data : [];
          isLoading = false;
        });
      }
      else {
        setState(() => isLoading = false);
      }
    }
    catch (e) {
      setState(() => isLoading = false);
      print('Ürünler alınamadı: $e');
    }
  }

  Future<void> fetchBanners() async {
    setState(() => isBannerLoading = true);

    try {
      final response = await http.get(
        Uri.parse('https://mobilapp.coffeerence.com.tr/api/all_banners'),
        headers: {
          'Accept': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          banners = data is List ? data : [];
        });
      }
      else {
        print('Banner isteği başarısız: ${response.statusCode}');
      }
    }
    catch (e) {
      print('Bannerlar alınamadı: $e');
    }
    finally {
      setState(() => isBannerLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final orientation = MediaQuery.of(context).orientation;
    final isLandscape = orientation == Orientation.landscape;
    final isTablet = screenSize.width > 600;

    return Scaffold(
      backgroundColor: const Color(0xFFFFFBF8),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomPadding = MediaQuery.of(context).padding.bottom;
            final navBarHeight = 60.0;

            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: _responsivePadding(screenSize.width)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(),
                      _buildPromoCard(screenSize, isLandscape, isTablet),
                      _buildCampaignsSection(screenSize, isLandscape, isTablet),
                      _buildProductsSection(screenSize, isLandscape, isTablet),
                      SizedBox(height: bottomPadding + navBarHeight + 20),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
      bottomNavigationBar: const CustomBottomNavBar(currentIndex: 0),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Align(
        alignment: Alignment.topRight,
        child: FutureBuilder(
          future: SharedPreferences.getInstance(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) return const SizedBox();
            final prefs = snapshot.data as SharedPreferences;
            final token = prefs.getString('token');

            if (token != null) {
              return ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  padding: const EdgeInsets.all(8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 4,
                  shadowColor: Colors.black.withOpacity(0.2),
                ),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const HistoryScreen()),
                  );
                },
                child: Icon(
                  Icons.receipt,
                  size: 24,
                  color: Colors.black,
                ),
              );
            }
            else{
              return GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                ),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: const [
                      Icon(Icons.login, color: Colors.brown, size: 20),
                      SizedBox(width: 6),
                      Text(
                        'Giriş Yap',
                        style: TextStyle(color: Colors.brown, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }


  Widget _buildPromoCard(Size screenSize, bool isLandscape, bool isTablet) {
    final double titleFontSize = isTablet ? 22.0 : 18.0;
    final double subtitleFontSize = isTablet ? 16.0 : 13.0;
    final double progressSize = isTablet ? 100.0 : 80.0;
    final double iconSize = isTablet ? 40.0 : 30.0;
    final double horizontalPadding = isTablet ? 24.0 : 16.0;
    final double verticalPadding = isTablet ? 20.0 : 16.0;

    return Container(
      width: double.infinity,
      margin: EdgeInsets.only(bottom: isTablet ? 20.0 : 16.0),
      decoration: BoxDecoration(
        color: Colors.brown[400],
        borderRadius: BorderRadius.circular(isTablet ? 22.0 : 18.0),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      padding: EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: verticalPadding),
      child: isLandscape && !isTablet
          ? Row(
        children: [
          Expanded(
            flex: 2,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('10 Kahve Senden 1 Kahve Bizden!',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFontSize, height: 1.2)),
                SizedBox(height: isTablet ? 12.0 : 8.0),
                Text('Kahve sayınızı takip edin ve ücretsiz kahve kazanın!',
                    style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize, height: 1.3)),
              ],
            ),
          ),
          SizedBox(width: isTablet ? 20.0 : 16.0),
          Expanded(
            flex: 1,
            child: Column(
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: progressSize,
                      height: progressSize,
                      child: CircularProgressIndicator(
                        value: coffeeCount / 10,
                        strokeWidth: isTablet ? 8.0 : 7.0,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                        backgroundColor: Colors.white,
                      ),
                    ),
                    Image.asset('assets/image/beans.png',
                        width: iconSize, height: iconSize,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(Icons.coffee_outlined, size: iconSize, color: Colors.white);
                        }),
                  ],
                ),
                SizedBox(height: isTablet ? 12.0 : 8.0),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                      color: Colors.brown[700],
                      borderRadius: BorderRadius.circular(6)
                  ),
                  child: Text('$coffeeCount/10',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: isTablet ? 16.0 : 14.0,
                          fontWeight: FontWeight.bold
                      )),
                ),
              ],
            ),
          ),
        ],
      )
          : Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('10 Kahve Senden 1 Kahve Bizden!',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: titleFontSize, height: 1.2)),
          SizedBox(height: isTablet ? 12.0 : 8.0),
          Row(
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: progressSize,
                    height: progressSize,
                    child: CircularProgressIndicator(
                      value: coffeeCount / 10,
                      strokeWidth: isTablet ? 8.0 : 7.0,
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.orange),
                      backgroundColor: Colors.white,
                    ),
                  ),
                  Image.asset('assets/image/beans.png',
                      width: iconSize, height: iconSize,
                      errorBuilder: (context, error, stackTrace) {
                        return Icon(Icons.coffee_outlined, size: iconSize, color: Colors.white);
                      }),
                ],
              ),
              SizedBox(width: isTablet ? 16.0 : 12.0),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                    color: Colors.brown[700],
                    borderRadius: BorderRadius.circular(6)
                ),
                child: Text('$coffeeCount/10',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: isTablet ? 16.0 : 14.0,
                        fontWeight: FontWeight.bold
                    )),
              ),
            ],
          ),
          SizedBox(height: isTablet ? 12.0 : 8.0),
          Text('Kahve sayınızı takip edin ve ücretsiz kahve kazanın!',
              style: TextStyle(color: Colors.white70, fontSize: subtitleFontSize, height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildCampaignsSection(Size screenSize, bool isLandscape, bool isTablet) {
    final double sectionHeight = isTablet
        ? screenSize.height * (isLandscape ? 0.3 : 0.25)
        : screenSize.height * (isLandscape ? 0.3 : 0.2);

    final double viewportFraction = isTablet ? 0.85 : 0.9;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 16.0 : 12.0),
            child: Text('Kampanyalar',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 22.0 : 18.0
                ))
        ),
        SizedBox(
          height: sectionHeight,
          child: isBannerLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.brown))
              : banners.isEmpty
              ? _buildEmptyView(
              'Henüz kampanya bulunmamaktadır',
              'Yakın zamanda kampanyalarımız sizlerle olacak',
              Icons.campaign_outlined,
              isTablet
          )
              : PageView.builder(
            onPageChanged: (index) => setState(() => campaignPage = index),
            controller: PageController(viewportFraction: viewportFraction),
            itemCount: banners.length,
            itemBuilder: (context, index) {
              return Container(
                margin: EdgeInsets.symmetric(horizontal: isTablet ? 8.0 : 4.0),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(isTablet ? 20.0 : 18.0),
                  child: Image.network(
                    banners[index]['image_url'] ?? '',
                    fit: BoxFit.cover,
                    width: double.infinity,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: Colors.grey[200],
                        child: Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
                      );
                    },
                  ),
                ),
              );
            },
          ),
        ),
        if (banners.isNotEmpty)
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 16.0 : 12.0),
            child: _buildPageIndicator(campaignPage, banners.length, isTablet),
          ),
        SizedBox(height: isTablet ? 24.0 : 20.0),
      ],
    );
  }

  Widget _buildProductsSection(Size screenSize, bool isLandscape, bool isTablet) {
    final double sectionHeight = isTablet
        ? screenSize.height * (isLandscape ? 0.4 : 0.35)
        : screenSize.height * (isLandscape ? 0.35 : 0.32);

    final double viewportFraction = isTablet ? 0.85 : 0.9;
    final int crossAxisCount = isLandscape
        ? (isTablet ? 3 : 2)
        : (isTablet ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
            padding: EdgeInsets.only(bottom: isTablet ? 16.0 : 12.0),
            child: Text('Ürünler',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isTablet ? 22.0 : 18.0
                ))
        ),
        SizedBox(
          height: sectionHeight,
          child: isLoading
              ? const Center(child: CircularProgressIndicator(color: Colors.brown))
              : products.isEmpty
              ? _buildEmptyView(
              'Henüz ürün bulunmamaktadır',
              'Yakın zamanda ürünlerimiz sizlerle olacak',
              Icons.coffee_outlined,
              isTablet
          )
              : isLandscape && !isTablet
              ? GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 1.2,
            ),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 16.0 : 12.0),
                child: _buildProductItem(products[index], isTablet),
              );
            },
          )
              : PageView.builder(
            onPageChanged: (index) => setState(() => productPage = index),
            controller: PageController(viewportFraction: viewportFraction),
            itemCount: products.length,
            itemBuilder: (context, index) {
              return Padding(
                padding: EdgeInsets.only(bottom: isTablet ? 16.0 : 12.0),
                child: _buildProductItem(products[index], isTablet),
              );
            },
          ),
        ),
        if (products.isNotEmpty && !(isLandscape && !isTablet))
          Padding(
            padding: EdgeInsets.only(top: isTablet ? 16.0 : 12.0),
            child: _buildPageIndicator(productPage, products.length, isTablet),
          ),
        SizedBox(height: isTablet ? 8.0 : 4.0),
      ],
    );
  }

  Widget _buildProductItem(dynamic product, bool isTablet) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: isTablet ? 8.0 : 4.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(isTablet ? 20.0 : 18.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(isTablet ? 20.0 : 18.0),
                topRight: Radius.circular(isTablet ? 20.0 : 18.0),
              ),
              child: Image.network(
                product['image_url'] ?? '',
                fit: BoxFit.cover,
                width: double.infinity,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    color: Colors.grey[200],
                    child: Icon(Icons.error_outline, color: Colors.grey[400], size: 40),
                  );
                },
              ),
            ),
          ),
          Expanded(
            flex: 2,
            child: Padding(
              padding: EdgeInsets.all(isTablet ? 12.0 : 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    product['name'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isTablet ? 16.0 : 14.0,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  SizedBox(height: isTablet ? 6.0 : 4.0),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        product['description'] ?? '',
                        style: TextStyle(
                          fontSize: isTablet ? 14.0 : 12.0,
                          color: Colors.grey[600],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int currentIndex, int length, bool isTablet) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        length,
            (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: EdgeInsets.symmetric(horizontal: isTablet ? 6.0 : 4.0),
          width: currentIndex == index ? (isTablet ? 20.0 : 16.0) : (isTablet ? 10.0 : 8.0),
          height: isTablet ? 10.0 : 8.0,
          decoration: BoxDecoration(
            color: currentIndex == index ? Colors.brown : Colors.brown[200],
            borderRadius: BorderRadius.circular(isTablet ? 5.0 : 4.0),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyView(String title, String subtitle, IconData icon, bool isTablet) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: isTablet ? 56.0 : 48.0, color: Colors.brown[200]),
          SizedBox(height: isTablet ? 12.0 : 8.0),
          Text(title,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: isTablet ? 18.0 : 16.0,
                  color: Colors.brown
              )),
          SizedBox(height: isTablet ? 8.0 : 4.0),
          Text(subtitle,
              style: TextStyle(
                  fontSize: isTablet ? 16.0 : 14.0,
                  color: Colors.brown
              )),
        ],
      ),
    );
  }

  double _responsivePadding(double width) {
    if (width > 1000) return 32;
    if (width > 600) return 24;
    return 16;
  }
}