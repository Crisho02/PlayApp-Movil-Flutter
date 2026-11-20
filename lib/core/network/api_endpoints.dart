class ApiEndpoints {
  static const String authLogin = '/api/auth/login';
  static const String authRegister = '/api/auth/register';
  static const String authProfile = '/api/auth/profile';

  static const String products = '/api/products';
  static String productDetail(String id) => '/api/products/$id';
  static String productImage(String id) => '/api/products/$id/image';

  static const String cart = '/api/cart';
  static const String cartAdd = '/api/cart/add';
  static const String cartUpdate = '/api/cart/update';
  static const String cartRemove = '/api/cart/remove';
  static const String cartClear = '/api/cart/clear';

  static const String ordersCreate = '/api/orders/create';
  static const String ordersUser = '/api/orders/user';
  static String orderDetail(String id) => '/api/orders/$id';

  static const String paymentWompiInit = '/api/payment/wompi/init';
  static const String paymentWompiVerify = '/api/payment/wompi/verify';

  static const String reviews = '/api/reviews';
  static const String contact = '/api/contact';

  static const String adminOrders = '/api/admin/orders';
  static String adminOrderStatus(String id) => '/api/admin/orders/$id/status';
  static String adminOrderMarkPaid(String id) => '/api/admin/orders/$id/mark-paid';
  static const String adminProducts = '/api/admin/products';
  static String adminProductDetail(String id) => '/api/admin/products/$id';
  static const String adminMetrics = '/api/admin/metrics';
  static const String adminReports = '/api/admin/reports';
  static const String adminPredictionSales = '/api/admin/prediction/sales';
  static const String adminCharts = '/api/admin/charts';
  static const String adminUsers = '/api/admin/users';
  static const String adminUsersCreate = '/api/admin/users/create';
  static const String adminReviews = '/api/admin/reviews';
  static String adminReviewDetail(String id) => '/api/admin/reviews/$id';
}
