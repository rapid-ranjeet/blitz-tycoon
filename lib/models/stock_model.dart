import 'dart:math';

class StockModel {
  final String symbol;
  final String companyName;
  final String sector;
  int price;
  int previousPrice;
  final List<int> history;

  // Ornstein-Uhlenbeck Continuous Stochastic Parameters
  static const double mu = 130.0; // Long-term equilibrium value
  static const double kappa = 0.15; // Mean-reversion speed
  static const double sigma = 0.08; // Diffusion volatility
  static const double lambdaJump = 0.05; // 5% probability of earnings jump shock
  static const double bidAskSpreadRate = 0.03; // 3% brokerage friction

  double _logPrice;
  final Random _rng = Random();

  StockModel({
    required this.symbol,
    required this.companyName,
    required this.sector,
    required this.price,
    required this.previousPrice,
    List<int>? history,
  })  : history = history ?? [price],
        _logPrice = log(price.toDouble());

  bool get isBullish => price >= previousPrice;

  double get changePercent {
    if (previousPrice == 0) return 0.0;
    return ((price - previousPrice) / previousPrice) * 100.0;
  }

  /// Bid price when a player sells shares to the market (3% below spot)
  int get bidPrice => max(1, (price * (1.0 - bidAskSpreadRate)).floor());

  /// Ask price when a player buys shares from the market (3% above spot)
  int get askPrice => (price * (1.0 + bidAskSpreadRate)).ceil();

  /// Executes an exact discrete Ornstein-Uhlenbeck mean-reverting jump step
  int tick() {
    previousPrice = price;

    // Standard Normal Z via Box-Muller transform
    double u1 = _rng.nextDouble().clamp(1e-7, 1.0);
    double u2 = _rng.nextDouble();
    double z = sqrt(-2.0 * log(u1)) * cos(2.0 * pi * u2);

    // Poisson Jump Shock
    double jump = 0.0;
    if (_rng.nextDouble() < lambdaJump) {
      double u3 = _rng.nextDouble().clamp(1e-7, 1.0);
      double u4 = _rng.nextDouble();
      double zJump = sqrt(-2.0 * log(u3)) * sin(2.0 * pi * u4);
      jump = zJump * 0.20; // 20% jump shock
    }

    // Discrete Euler-Maruyama step on log-price
    double expK = exp(-kappa);
    double varFactor = sqrt((1.0 - exp(-2.0 * kappa)) / (2.0 * kappa));
    _logPrice = _logPrice * expK + log(mu) * (1.0 - expK) + sigma * varFactor * z + jump;

    // Strict boundary clamping between ₹40 and ₹480
    double boundedPrice = exp(_logPrice).clamp(40.0, 480.0);
    _logPrice = log(boundedPrice);
    price = boundedPrice.round();

    history.add(price);
    if (history.length > 20) history.removeAt(0);

    return price;
  }
}
