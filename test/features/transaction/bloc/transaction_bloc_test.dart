import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:ta_client/features/transaction/bloc/transaction_bloc.dart';
import 'package:ta_client/features/transaction/models/account_type.dart';
import 'package:ta_client/features/transaction/models/category.dart';
import 'package:ta_client/features/transaction/models/subcategory.dart';
import 'package:ta_client/features/transaction/models/transaction.dart';
import 'package:ta_client/features/transaction/repositories/transaction_hierarchy_repository.dart';
import 'package:ta_client/features/transaction/repositories/transaction_repository.dart';
import 'package:ta_client/features/transaction/services/transaction_service.dart'
    show TransactionService, TransactionApiException;

// Mocks
class MockTransactionRepository extends Mock implements TransactionRepository {}

class MockTransactionHierarchyRepository extends Mock
    implements TransactionHierarchyRepository {}

class MockTransactionService extends Mock implements TransactionService {}

// Fallback values for complex types used with any()
class FakeTransaction extends Fake implements Transaction {}

void main() {
  late TransactionRepository mockTransactionRepository;
  late TransactionHierarchyRepository mockHierarchyRepository;
  late MockTransactionService mockTransactionService;
  late TransactionBloc transactionBloc;

  // Test Data
  final tAccountType1 = AccountType(id: 'at1', name: 'Pemasukan');
  final tAccountType2 = AccountType(id: 'at2', name: 'Pengeluaran');
  final tCategory1 = Category(id: 'cat1', name: 'Gaji', accountTypeId: 'at1');
  final tCategory2 = Category(
    id: 'cat2',
    name: 'Makanan',
    accountTypeId: 'at2',
  );
  final tCategory3 = Category(
    id: 'cat3',
    name: 'Transportasi',
    accountTypeId: 'at2',
  );
  final tSubcategory1 = Subcategory(
    id: 'sub1',
    name: 'Gaji Bulanan',
    categoryId: 'cat1',
  );
  final tSubcategory2 = Subcategory(
    id: 'sub2',
    name: 'Restoran',
    categoryId: 'cat2',
  );
  final tSubcategory3 = Subcategory(
    id: 'sub3',
    name: 'Bensin',
    categoryId: 'cat3',
  );

  final tTransactionInput = Transaction(
    id: '', // Empty for creation
    description: 'Makan siang',
    amount: 75.0,
    date: DateTime(2023, 10, 26, 12, 30),
    subcategoryId: 'sub2', // Will be filled
    // Denormalized fields will be filled by BLoC/Repo logic or from full subcategory object
  );

  final tCreatedTransaction = Transaction(
    id: 'tx-backend-123',
    description: 'Makan siang',
    amount: 75.0,
    date: DateTime(2023, 10, 26, 12, 30),
    subcategoryId: 'sub2',
    subcategoryName: 'Restoran',
    categoryId: 'cat2',
    categoryName: 'Makanan',
    accountTypeId: 'at2',
    accountTypeName: 'Pengeluaran',
    isBookmarked: false,
    isLocal: false,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  setUpAll(() {
    registerFallbackValue(FakeTransaction());
  });

  setUp(() {
    mockTransactionRepository = MockTransactionRepository();
    mockHierarchyRepository = MockTransactionHierarchyRepository();
    mockTransactionService = MockTransactionService();
    transactionBloc = TransactionBloc(
      repository: mockTransactionRepository,
      hierarchyRepository: mockHierarchyRepository,
      transactionService: mockTransactionService,
    );
  });

  tearDown(() {
    transactionBloc.close();
  });

  group('TransactionBloc', () {
    test('initial state is correct TransactionState()', () {
      expect(transactionBloc.state, const TransactionState());
    });

    group('CreateTransactionRequested', () {
      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, success with transaction] when repository createTransaction is successful',
        build: () {
          when(
            () => mockTransactionRepository.createTransaction(any()),
          ).thenAnswer((_) async => tCreatedTransaction);
          return transactionBloc;
        },
        act: (bloc) => bloc.add(CreateTransactionRequested(tTransactionInput)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.create,
            isSuccess: false,
          ),
          TransactionState(
            isLoading: false,
            isSuccess: true,
            operation: TransactionOperation.create,
            lastProcessedTransaction: tCreatedTransaction,
          ),
        ],
        verify: (_) {
          verify(
            () =>
                mockTransactionRepository.createTransaction(tTransactionInput),
          ).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, failure with error message] on TransactionApiException from repository',
        build: () {
          when(
            () => mockTransactionRepository.createTransaction(any()),
          ).thenThrow(TransactionApiException('Network error during create'));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(CreateTransactionRequested(tTransactionInput)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.create,
            isSuccess: false,
          ),
          const TransactionState(
            isLoading: false,
            isSuccess: false,
            operation: TransactionOperation.create,
            errorMessage: 'Network error during create',
          ),
        ],
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, failure with generic error message] on generic Exception from repository',
        build: () {
          when(
            () => mockTransactionRepository.createTransaction(any()),
          ).thenThrow(Exception('Some other error'));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(CreateTransactionRequested(tTransactionInput)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.create,
            isSuccess: false,
          ),
          const TransactionState(
            isLoading: false,
            isSuccess: false,
            operation: TransactionOperation.create,
            errorMessage:
                'Gagal membuat transaksi: Exception: Some other error',
          ),
        ],
      );
    });

    group('UpdateTransactionRequested', () {
      final tUpdatedTransaction = tCreatedTransaction.copyWith(
        description: "Makan malam enak",
      );
      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, success with updated transaction] when repository updateTransaction is successful',
        build: () {
          when(
            () => mockTransactionRepository.updateTransaction(any()),
          ).thenAnswer((_) async => tUpdatedTransaction);
          return transactionBloc;
        },
        act: (bloc) => bloc.add(
          UpdateTransactionRequested(tUpdatedTransaction),
        ), // Pass the transaction with its ID
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.update,
            isSuccess: false,
          ),
          TransactionState(
            isLoading: false,
            isSuccess: true,
            operation: TransactionOperation.update,
            lastProcessedTransaction: tUpdatedTransaction,
          ),
        ],
        verify: (_) {
          verify(
            () => mockTransactionRepository.updateTransaction(
              tUpdatedTransaction,
            ),
          ).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, failure with error message] on TransactionApiException from repository during update',
        build: () {
          when(
            () => mockTransactionRepository.updateTransaction(any()),
          ).thenThrow(TransactionApiException('Update failed server-side'));
          return transactionBloc;
        },
        act: (bloc) =>
            bloc.add(UpdateTransactionRequested(tUpdatedTransaction)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.update,
            isSuccess: false,
          ),
          const TransactionState(
            isLoading: false,
            isSuccess: false,
            operation: TransactionOperation.update,
            errorMessage: 'Update failed server-side',
          ),
        ],
      );
    });

    group('DeleteTransactionRequested', () {
      const transactionIdToDelete = 'tx-backend-123';
      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, success] when repository deleteTransaction is successful',
        build: () {
          when(
            () => mockTransactionRepository.deleteTransaction(any()),
          ).thenAnswer((_) async {});
          return transactionBloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteTransactionRequested(transactionIdToDelete)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.delete,
            isSuccess: false,
          ),
          const TransactionState(
            isLoading: false,
            isSuccess: true,
            operation: TransactionOperation.delete,
          ), // No lastProcessedTransaction for delete
        ],
        verify: (_) {
          verify(
            () => mockTransactionRepository.deleteTransaction(
              transactionIdToDelete,
            ),
          ).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, failure] on TransactionApiException from repository during delete',
        build: () {
          when(
            () => mockTransactionRepository.deleteTransaction(any()),
          ).thenThrow(TransactionApiException('Delete failed'));
          return transactionBloc;
        },
        act: (bloc) =>
            bloc.add(const DeleteTransactionRequested(transactionIdToDelete)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.delete,
            isSuccess: false,
          ),
          const TransactionState(
            isLoading: false,
            isSuccess: false,
            operation: TransactionOperation.delete,
            errorMessage: 'Delete failed',
          ),
        ],
      );
    });

    group('ClassifyTransactionRequested', () {
      const description = 'Beli Kopi Starbucks';
      final classificationResult = {
        'subcategoryId': 'sub-coffee-id',
        'subcategoryName': 'Kopi',
        'categoryId': 'cat-drinks-id',
        'categoryName': 'Minuman',
        'accountTypeId': 'at-expense-id',
        'accountTypeName': 'Pengeluaran',
        'confidence': 0.95,
      };

      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, result] when service classifyTransaction is successful',
        build: () {
          when(
            () => mockTransactionService.classifyTransaction(any()),
          ).thenAnswer((_) async => classificationResult);
          return transactionBloc;
        },
        act: (bloc) => bloc.add(ClassifyTransactionRequested(description)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.classify,
          ),
          TransactionState(
            isLoading: false,
            operation: TransactionOperation.classify,
            classifiedResult: classificationResult,
          ),
        ],
        verify: (_) {
          verify(
            () => mockTransactionService.classifyTransaction(description),
          ).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, error] on TransactionApiException from service during classification',
        build: () {
          when(
            () => mockTransactionService.classifyTransaction(any()),
          ).thenThrow(TransactionApiException('Classifier down'));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(ClassifyTransactionRequested(description)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.classify,
          ),
          const TransactionState(
            isLoading: false,
            operation: TransactionOperation.classify,
            errorMessage: 'Classifier down',
          ),
        ],
      );
    });

    group('ToggleBookmarkRequested', () {
      final tBookmarkedTransaction = tCreatedTransaction.copyWith(
        isBookmarked: true,
      );
      blocTest<TransactionBloc, TransactionState>(
        'emits [loading, success with bookmarked transaction] when repository toggleBookmark is successful',
        build: () {
          when(
            () => mockTransactionRepository.toggleBookmark(any()),
          ).thenAnswer((_) async => tBookmarkedTransaction);
          return transactionBloc;
        },
        act: (bloc) =>
            bloc.add(ToggleBookmarkRequested(tCreatedTransaction.id)),
        expect: () => [
          const TransactionState(
            isLoading: true,
            operation: TransactionOperation.bookmark,

            isSuccess: false,
          ),
          TransactionState(
            isLoading: false,
            isSuccess: true,
            operation: TransactionOperation.bookmark,
            lastProcessedTransaction: tBookmarkedTransaction,
          ),
        ],
        verify: (_) {
          verify(
            () => mockTransactionRepository.toggleBookmark(
              tCreatedTransaction.id,
            ),
          ).called(1);
        },
      );
    });

    group('LoadAccountTypesRequested', () {
      final accountTypes = [tAccountType1, tAccountType2];
      blocTest<TransactionBloc, TransactionState>(
        'emits [loadingHierarchy, success with account types]',
        build: () {
          when(
            () => mockHierarchyRepository.fetchAccountTypes(),
          ).thenAnswer((_) async => accountTypes);
          return transactionBloc;
        },
        act: (bloc) => bloc.add(LoadAccountTypesRequested()),
        expect: () => [
          const TransactionState(isLoadingHierarchy: true),
          TransactionState(
            isLoadingHierarchy: false,
            accountTypes: accountTypes,
          ),
        ],
      );
    });

    group('LoadCategoriesRequested', () {
      final categoriesForAT1 = [tCategory1];
      final subcategoriesForCat1 = [tSubcategory1];

      blocTest<TransactionBloc, TransactionState>(
        'emits [loadingHierarchy, clears previous, success with categories and their subcategories]',
        // Seed with some previous hierarchy data to ensure it gets cleared
        seed: () => TransactionState(
          categories: [tCategory2],
          subcategories: [tSubcategory2],
        ),
        build: () {
          when(
            () => mockHierarchyRepository.fetchCategories(tAccountType1.id),
          ).thenAnswer((_) async => categoriesForAT1);
          when(
            () => mockHierarchyRepository.fetchSubcategories(tCategory1.id),
          ).thenAnswer((_) async => subcategoriesForCat1);
          return transactionBloc;
        },
        act: (bloc) => bloc.add(LoadCategoriesRequested(tAccountType1.id)),
        expect: () => [
          // Initial state after event: loading, categories and subcategories cleared
          const TransactionState(
            isLoadingHierarchy: true,
            categories: [],
            subcategories: [],
          ),
          // Final state: not loading, new categories and subcategories loaded
          TransactionState(
            isLoadingHierarchy: false,
            categories: categoriesForAT1,
            subcategories: subcategoriesForCat1,
          ),
        ],
        verify: (_) {
          verify(
            () => mockHierarchyRepository.fetchCategories(tAccountType1.id),
          ).called(1);
          verify(
            () => mockHierarchyRepository.fetchSubcategories(tCategory1.id),
          ).called(1);
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loadingHierarchy, empty lists] if accountTypeId is empty string',
        build: () => transactionBloc,
        act: (bloc) => bloc.add(const LoadCategoriesRequested('')),
        expect: () => [
          const TransactionState(
            isLoadingHierarchy: true,
            categories: [],
            subcategories: [],
          ),
          const TransactionState(
            isLoadingHierarchy: false,
            categories: [],
            subcategories: [],
          ),
        ],
        verify: (_) {
          verifyNever(() => mockHierarchyRepository.fetchCategories(any()));
          verifyNever(() => mockHierarchyRepository.fetchSubcategories(any()));
        },
      );

      blocTest<TransactionBloc, TransactionState>(
        'emits [loadingHierarchy, error] if fetchCategories throws',
        build: () {
          when(
            () => mockHierarchyRepository.fetchCategories(any()),
          ).thenThrow(Exception('Fetch cat error'));
          return transactionBloc;
        },
        act: (bloc) => bloc.add(LoadCategoriesRequested(tAccountType1.id)),
        expect: () => [
          const TransactionState(
            isLoadingHierarchy: true,
            categories: [],
            subcategories: [],
          ),
          const TransactionState(
            isLoadingHierarchy: false,
            categories: [],
            subcategories: [],
            errorMessage: 'Exception: Fetch cat error',
          ),
        ],
      );
    });

    group('LoadSubcategoriesRequested', () {
      final subcategoriesForCat2 = [tSubcategory2];
      blocTest<TransactionBloc, TransactionState>(
        'emits [loadingHierarchy, clears previous subcategories, success with subcategories]',
        seed: () => TransactionState(
          subcategories: [tSubcategory1],
        ), // Seed with existing subcategories
        build: () {
          when(
            () => mockHierarchyRepository.fetchSubcategories(tCategory2.id),
          ).thenAnswer((_) async => subcategoriesForCat2);
          return transactionBloc;
        },
        act: (bloc) => bloc.add(LoadSubcategoriesRequested(tCategory2.id)),
        expect: () => [
          const TransactionState(isLoadingHierarchy: true, subcategories: []),
          TransactionState(
            isLoadingHierarchy: false,
            subcategories: subcategoriesForCat2,
          ),
        ],
      );
    });

    group('TransactionClearStatus', () {
      blocTest<TransactionBloc, TransactionState>(
        'emits state with isSuccess:false and null errorMessage and infoMessage',
        build: () => transactionBloc,
        seed: () => const TransactionState(
          isSuccess: true,
          errorMessage: 'Error',
          infoMessage: 'Info',
        ),
        act: (bloc) => bloc.add(TransactionClearStatus()),
        expect: () => [
          const TransactionState(
            isSuccess: false,
            errorMessage: null,
            infoMessage: null,
          ),
        ],
      );
    });
  });
}
