import 'package:get_it/get_it.dart';
import 'package:loyalty_app/core/services/notification_service.dart';
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

  // Services
  getIt.registerLazySingleton<NotificationService>(() => NotificationService());

  getIt.registerLazySingleton<LoyaltyService>(
    () => LoyaltyServiceImpl(repository: getIt<LoyaltyRepository>()),
  );

  getIt.registerLazySingleton<WooCommerceClient>(() => WooCommerceClient());

  getIt.registerLazySingleton<WooCommerceSyncService>(
    () => WooCommerceSyncService(
      woocommerceClient: getIt<WooCommerceClient>(),
      loyaltyService: getIt<LoyaltyService>(),
    ),
  );

  // Blocs
  getIt.registerFactory<LoyaltyBloc>(
    () => LoyaltyBloc(
      loyaltyService: getIt<LoyaltyService>(),
      notificationService: getIt<NotificationService>(),
    ),
  );
}
