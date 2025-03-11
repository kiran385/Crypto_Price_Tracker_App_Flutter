import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Crypto Sphere',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF24293E),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
        cardTheme: CardTheme(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      home: const CryptoHomePage(title: 'Crypto Sphere'),
    );
  }
}

class CryptoHomePage extends StatefulWidget {
  const CryptoHomePage({super.key, required this.title});
  final String title;

  @override
  State<CryptoHomePage> createState() => _CryptoHomePageState();
}

class _CryptoHomePageState extends State<CryptoHomePage> {
  List<CryptoCoin> _coins = [];
  bool _isLoading = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _fetchCryptoData();
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _fetchCryptoData();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _fetchCryptoData() async {
    try {
      final response = await http.get(
        Uri.parse('https://api.coingecko.com/api/v3/coins/markets?vs_currency=usd&ids=bitcoin,ethereum,binancecoin,cardano,chainlink,basic-attention-token,litecoin,ripple,polkadot,dogecoin,solana,uniswap,shiba-inu&order=market_cap_desc&per_page=100&page=1&sparkline=true'),
        headers: {
          'Accept': 'application/json',
          'x-cg-demo-api-key': 'CG-31nmp9nDix6qwYR9tciG4mod',
        },
      );
      
      print('Status Code: ${response.statusCode}');
      print('Response: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        setState(() {
          List<CryptoCoin> newCoins = data.map((json) => CryptoCoin.fromJson(json)).toList();
          
          for (int i = 0; i < newCoins.length; i++) {
            if (_coins.isNotEmpty && i < _coins.length && 
                _coins[i].currentPrice != newCoins[i].currentPrice) {
              newCoins[i].blink = true;
              Future.delayed(const Duration(seconds: 1), () {
                if (mounted) {
                  setState(() {
                    newCoins[i].blink = false;
                  });
                }
              });
            }
          }
          
          _coins = newCoins;
          _isLoading = false;
        });
      } else {
        throw Exception('Failed to load data - ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error: $e');
    }
  }

  void _navigateToDetail(CryptoCoin coin) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CryptoDetailPage(coin: coin),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF24293E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 24,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _fetchCryptoData,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          : RefreshIndicator(
              onRefresh: _fetchCryptoData,
              color: Colors.white,
              backgroundColor: Color(0xFF24293E),
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _coins.length,
                itemBuilder: (context, index) {
                  final coin = _coins[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8.0),
                    child: Card(
                      color: Color(0xFF24293E),
                      child: InkWell(
                        onTap: () => _navigateToDetail(coin),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                backgroundColor: Colors.white12,
                                backgroundImage: NetworkImage(coin.image),
                                radius: 24,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          coin.name,
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                        Text(
                                          '\$${coin.currentPrice.toStringAsFixed(2)}',
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            color: Colors.white70,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        Icon(
                                          coin.priceChangePercentage24h >= 0
                                              ? Icons.trending_up
                                              : Icons.trending_down,
                                          size: 16,
                                          color: coin.priceChangePercentage24h >= 0
                                              ? Colors.greenAccent
                                              : Colors.redAccent,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          '${coin.priceChangePercentage24h.toStringAsFixed(2)}%',
                                          style: TextStyle(
                                            color: coin.priceChangePercentage24h >= 0
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                            fontSize: 14,
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        SizedBox(
                                          width: 100,
                                          height: 40,
                                          child: SparklineGraph(
                                            data: coin.sparkline7d,
                                            lineColor: coin.priceChangePercentage24h >= 0
                                                ? Colors.greenAccent
                                                : Colors.redAccent,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
    );
  }
}

class CryptoCoin {
  final String id;
  final String name;
  final String image;
  final double currentPrice;
  final double priceChangePercentage24h;
  final List<double> sparkline7d;
  bool blink;

  CryptoCoin({
    required this.id,
    required this.name,
    required this.image,
    required this.currentPrice,
    required this.priceChangePercentage24h,
    required this.sparkline7d,
    this.blink = false,
  });

  factory CryptoCoin.fromJson(Map<String, dynamic> json) {
    return CryptoCoin(
      id: json['id'] as String,
      name: json['name'] as String,
      image: json['image'] as String,
      currentPrice: (json['current_price'] as num).toDouble(),
      priceChangePercentage24h: (json['price_change_percentage_24h'] as num).toDouble(),
      sparkline7d: (json['sparkline_in_7d']['price'] as List)
          .map((price) => (price as num).toDouble())
          .toList(),
    );
  }
}

class CryptoDetailPage extends StatelessWidget {
  final CryptoCoin coin;

  const CryptoDetailPage({super.key, required this.coin});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFF24293E),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(coin.name),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Card(
              color: Color(0xFF24293E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundImage: NetworkImage(coin.image),
                      radius: 30,
                      backgroundColor: Colors.white12,
                    ),
                    const SizedBox(width: 16),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '\$${coin.currentPrice.toStringAsFixed(2)}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Row(
                          children: [
                            Icon(
                              coin.priceChangePercentage24h >= 0
                                  ? Icons.trending_up
                                  : Icons.trending_down,
                              color: coin.priceChangePercentage24h >= 0
                                  ? Colors.greenAccent
                                  : Colors.redAccent,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${coin.priceChangePercentage24h.toStringAsFixed(2)}% (24h)',
                              style: TextStyle(
                                fontSize: 16,
                                color: coin.priceChangePercentage24h >= 0
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Card(
              color: Color(0xFF24293E),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      '7-Day Price Trend',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    SizedBox(
                      height: 200,
                      child: SparklineGraph(
                        data: coin.sparkline7d,
                        lineColor: coin.priceChangePercentage24h >= 0
                            ? Colors.greenAccent
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SparklineGraph extends StatelessWidget {
  final List<double> data;
  final Color lineColor;

  const SparklineGraph({
    Key? key,
    required this.data,
    required this.lineColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: AspectRatio(
        aspectRatio: 3,
        child: CustomPaint(
          painter: SparklinePainter(data: data, lineColor: lineColor),
        ),
      ),
    );
  }
}

class SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color lineColor;

  SparklinePainter({required this.data, required this.lineColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty || data.length < 2) {
      return;
    }

    final paint = Paint()
      ..color = lineColor
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final path = Path();

    final double minValue = data.reduce((a, b) => a < b ? a : b);
    final double maxValue = data.reduce((a, b) => a > b ? a : b);
    final double range = maxValue - minValue;
    
    final double padding = 10.0;
    final double usableHeight = size.height - (2 * padding);
    final double usableWidth = size.width - (2 * padding);
    final double xStep = usableWidth / (data.length - 1);
    final double yScale = range == 0 ? 0 : usableHeight / range;

    for (int i = 0; i < data.length; i++) {
      final x = padding + (i * xStep);
      final y = padding + (usableHeight - ((data[i] - minValue) * yScale));
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant SparklinePainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.lineColor != lineColor;
  }
}