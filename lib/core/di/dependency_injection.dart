import 'package:get_it/get_it.dart';
import 'package:loyalty_app/core/services/notification_service.dart';
import 'package:loyalty_app/features/auth/api/auth_api.dart';
import 'package:loyalty_app/features/auth/api/wordpress_auth_api.dart';
import 'package:loyalty_app/features/auth/bloc/auth_bloc.dart';
import 'package:loyalty_app/features/auth/data/repositories/auth_repository.dart';
import 'package:loyalty_app/features/auth/data/services/auth_service_impl.dart';
import 'package:loyalty_app/features/auth/domain/services/auth_service.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_client.dart';
import 'package:loyalty_app/features/loyalty/api/woocommerce_sync_service.dart';
import 'package:loyalty_app/features/loyalty/bloc/loyalty_bloc.dart';
import 'package:loyalty_app/features/loyalty/data/repositories/loyalty_repository.dart';
import 'package:loyalty_app/features/loyalty/data/services/loyalty_service_impl.dart';
import 'package:loyalty_app/features/loyalty/domain/services/loyalty_service.dart';

final GetIt getIt = GetIt.instance;

/// Initialize service locator
void setupDependencies() {
  // Repositories
  getIt.registerLazySingleton<LoyaltyRepository>(() => LoyaltyRepository());
  getIt.registerLazySingleton<AuthRepository>(
    () => AuthRepository(authApi: getIt<AuthApi>()),
  );

  // API Clients
  getIt.registerLazySingleton<AuthApi>(() => WordPressAuthApi());
  getIt.registerLazySingleton<WooCommerceClient>(() => WooCommerceClient());

  // Services
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());
  getIt.registerLazySingleton<AuthService>(
    () => AuthServiceImpl(repository: getIt<AuthRepository>()),
  );
  getIt.registerLazySingleton<LoyaltyService>(
    () => LoyaltyServiceImpl(repository: getIt<LoyaltyRepository>()),
  );
  getIt.registerLazySingleton<WooCommerceSyncService>(
    () => WooCommerceSyncService(
      wooCommerceClient: getIt<WooCommerceClient>(),
      loyaltyService: getIt<LoyaltyService>(),
    ),
  );

  // Blocs
  getIt.registerFactory<AuthBloc>(
    () => AuthBloc(authService: getIt<AuthService>()),
  );
  getIt.registerFactory<LoyaltyBloc>(
    () => LoyaltyBloc(
      loyaltyService: getIt<LoyaltyService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
}
