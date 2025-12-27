import 'package:shelf/shelf.dart';
import 'package:shelf_router/shelf_router.dart';
import '../controllers/auth_controller.dart';
import '../controllers/customer_controller.dart';
import '../controllers/product_controller.dart';
import '../controllers/order_controller.dart';
import '../middleware/auth_middleware.dart';
import '../middleware/role_middleware.dart';

class ApiRouter {
  Router get router {
    final router = Router();

    // --- KHỞI TẠO CÁC CONTROLLER ---
    final authController = AuthController();
    final customerController = CustomerController();
    final productController = ProductController();
    final orderController = OrderController();

    // --- THIẾT LẬP MIDDLEWARE PIPELINES ---
    // authPipe: Dành cho người dùng đã đăng nhập (Customer hoặc Admin)
    final authPipe = Pipeline().addMiddleware(authMiddleware());

    // adminPipe: Chỉ dành cho người dùng có quyền Admin
    final adminPipe = Pipeline()
        .addMiddleware(authMiddleware())
        .addMiddleware(adminMiddleware());

    // ============================================================
    // PHẦN 2 & 3: AUTH & CUSTOMER
    // ============================================================
    router.post('/api/auth/register', authController.register);
    router.post('/api/auth/login', authController.login);

    // API lấy thông tin cá nhân (Cần đăng nhập)
    router.get('/api/auth/me', authPipe.addHandler(authController.me));

    // Admin lấy danh sách tất cả khách hàng
    router.get('/api/customers', adminPipe.addHandler(customerController.getAll));

    // Lấy thông tin khách hàng cụ thể hoặc cập nhật (Cần đăng nhập)
    router.get('/api/customers/<id>', (Request req, String id) {
      return authPipe.addHandler((Request r) => customerController.getById(r, id))(req);
    });

    router.put('/api/customers/<id>', (Request req, String id) {
      return authPipe.addHandler((Request r) => customerController.update(r, id))(req);
    });

    // ============================================================
    // PHẦN 4: PRODUCT MANAGEMENT
    // ============================================================
    // Xem sản phẩm: Công khai (Không cần đăng nhập để test nhanh)
    router.get('/api/products', productController.getAll);
    router.get('/api/products/search', productController.getAll); // Có thể dùng chung logic getAll kèm query params
    router.get('/api/products/<id>', (Request req, String id) => productController.getById(req, id));

    // Quản lý sản phẩm: Chỉ Admin mới có quyền
    router.post('/api/products', adminPipe.addHandler(productController.create));

    router.put('/api/products/<id>', (Request req, String id) {
      return adminPipe.addHandler((Request r) => productController.update(r, id))(req);
    });

    router.delete('/api/products/<id>', (Request req, String id) {
      return adminPipe.addHandler((Request r) => productController.delete(r, id))(req);
    });

    // ============================================================
    // PHẦN 5: ORDER MANAGEMENT
    // ============================================================
    // Đặt hàng (Cần đăng nhập)
    router.post('/api/orders', authPipe.addHandler(orderController.create));

    // Admin xem danh sách đơn hàng
    router.get('/api/orders', adminPipe.addHandler(orderController.getOrdersAdmin));

    // Xem chi tiết đơn hàng (Cần đăng nhập)
    router.get('/api/orders/<id>', (Request req, String id) {
      return authPipe.addHandler((Request r) => orderController.getById(r, id))(req);
    });

    // Cập nhật trạng thái đơn hàng (Thường là Admin)
    router.put('/api/orders/<id>/status', (Request req, String id) {
      return authPipe.addHandler((Request r) => orderController.updateStatus(r, id))(req);
    });

    // Thanh toán đơn hàng
    router.post('/api/orders/<id>/pay', (Request req, String id) {
      return authPipe.addHandler((Request r) => orderController.pay(r, id))(req);
    });

    // Xem lịch sử mua hàng của khách hàng
    router.get('/api/customers/<id>/orders', (Request req, String id) {
      return authPipe.addHandler((Request r) => orderController.getOrdersByCustomer(r, id))(req);
    });

    return router;
  }
}